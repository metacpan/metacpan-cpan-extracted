################################################################################
#
# Copyright (c) 2002-2024 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

use Test::More tests => 54;
use Convert::Binary::C @ARGV;

my @stdname = qw( __STDC_HOSTED__ __STDC_VERSION__ );
my @stddef  = qw( __STDC_HOSTED__=1 __STDC_VERSION__=199901L );

my $c = Convert::Binary::C->new;

eval {
  $c->parse('');
};

is($@, '', 'parse an empty string');
is(scalar $c->macro_names, scalar @stdname, 'STDC macro name count');
is(join(',', sort $c->macro_names), join(',', sort @stdname), 'STDC macro names');
is(scalar $c->macro, scalar @stddef, 'STDC macro count');
is(scalar $c->macro('FOO', 'BAR', 'BAZ'), 3, 'macro count');
is(join(',', sort map { trim_macro($_) } $c->macro),
   join(',', sort @stddef), 'STDC macro definitions');
is(join(',', map { trim_macro($_) } $c->macro(@stdname)),
   join(',', @stddef), 'STDC macro definitions (arg)');
is(trim_macro(scalar $c->macro('__STDC_HOSTED__')),
   '__STDC_HOSTED__=1', 'STDC macro definition (scalar context)');
is_deeply([map { defined $_ ? trim_macro($_) : undef } $c->macro('FOOBAR', @stdname)],
          [undef, @stddef], 'STDC macro definitions (arg)');
for my $m ($c->macro_names) {
  ok($c->defined($m), "$m defined");
}
ok(!$c->defined('FOOBAR'), 'FOOBAR not defined');

my @name = qw{ DEFINED MULTIPLY };
my @def  = ('DEFINED', 'MULTIPLY(x,y)=((x)*(y))');

eval {
  $c->parse(<<ENDC);

#define MULTIPLY(x, y) ((x) * (y))

#if 0
# define NOT_DEFINED
#else
# define DEFINED
#endif

ENDC
};

is($@, '', 'parse some defines');
is(scalar $c->macro_names, @stdname + @name, 'macro name count');
is(join(',', sort $c->macro_names),
   join(',', sort @stdname, @name), 'macro names');
is(scalar $c->macro, 4, 'macro count');
is(join(',', sort map { trim_macro($_) } $c->macro),
   join(',', sort @stddef, @def), 'macro definitions');
is(join(',', map { trim_macro($_) } $c->macro(@name)),
   join(',', @def), 'macro definitions (arg)');
is(trim_macro(scalar $c->macro('DEFINED')),
   'DEFINED', 'macro definition (scalar context)');
is_deeply([map { defined $_ ? trim_macro($_) : undef } $c->macro('NOT_DEFINED', @name)],
          [undef, @def], 'STDC macro definitions (arg)');
for my $m ($c->macro_names) {
  ok($c->defined($m), "$m defined");
}
ok(!$c->defined('NOT_DEFINED'), 'NOT_DEFINED not defined');

my $src = $c->sourcify({ Defines => 1 });
my @srcdef = $src =~ /^#define\s+(.*)$/gm;

is(join(',', sort map { trim_macro($_) } @srcdef),
   join(',', sort @def), 'sourcify');

my @cfg = (
  { does_reset => 1, config => [ HasCPPComments => 1 ] },
  { does_reset => 0, config => [ PointerSize    => 2 ] },
  { does_reset => 1, config => [ HasMacroVAARGS => 1 ] },
  { does_reset => 0, config => [ Warnings       => 1 ] },
  { does_reset => 1, config => [ Include => ['a']    ] },
  { does_reset => 1, config => [ Define  => ['b']    ] },
  { does_reset => 1, config => [ Assert  => ['a(b)'] ] },
);

$c->configure(HasCPPComments => 0,
              PointerSize    => 4,
              HasMacroVAARGS => 0,
              Warnings       => 0,
              Include        => [],
              Define         => [],
              Assert         => []);

my $d = $c->clone;

for my $t (@cfg) {
  $c->clean->parse("#define DEFINED\n");
  ok($c->defined('DEFINED'), 'DEFINED defined');
  $c->configure(@{$t->{config}});
  if ($t->{does_reset}) {
    ok(!$c->defined('DEFINED'), "DEFINED not defined after $t->{config}[0]");
  }
  else {
    ok($c->defined('DEFINED'), "DEFINED still defined after $t->{config}[0]");
  }

  my($meth, @arg) = map { ref $_ ? @$_ : $_ } @{$t->{config}};

  $d->clean->parse("#define DEFINED\n");
  ok($d->defined('DEFINED'), 'DEFINED defined');
  $d->$meth(@arg);
  if ($t->{does_reset}) {
    ok(!$d->defined('DEFINED'), "DEFINED not defined after $meth");
  }
  else {
    ok($d->defined('DEFINED'), "DEFINED still defined after $meth");
  }
}

sub trim_macro
{
  my $m = shift;
  my @p;

  if ($m =~ /^(\w+\([^)]+\))(?:\s+(.*))?$/) {
    push @p, $1;
    defined $2 and push @p, $2;
  }
  elsif ($m =~ /^(\w+)(?:\s+(.*))?$/) {
    push @p, $1;
    defined $2 and push @p, $2;
  }
  else {
    die "unexpected macro format in [$m]\n";
  }

  for (@p) { s/\s+//g }

  return join '=', @p;
}
