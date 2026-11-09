use strict;
use warnings;
use Test::More;

use lib 't/lib';
use DBIO::Extension;
use DBIO::Extension::List;
use DBIO::Extension::Protocol;

# ADR 0077 (karr k391): extension names, the schema option and the names an
# activation hands to the driver are identifiers. ';', a line break, CR and NUL
# are refused in core with a DBIO::Exception that names what was given (the
# key or option), never the value. Quote, blank and backslash are the
# driver's to quote or refuse.

sub plain_list {
  return DBIO::Extension::List->new(
    declaration => $_[0],
    class_table => sub { return },
    plain_class => 'TestDBIO::Extension::Plain',
  );
}

my %bad = (semicolon => "a;b", newline => "a\nb", cr => "a\rb", nul => "a\0b");

for my $label (sort keys %bad) {
  my $err = do { local $@; eval { plain_list([ $bad{$label} ]); 1 } ? undef : $@ };
  isa_ok $err, 'DBIO::Exception', "extension name with $label";
  like "$err", qr/extension name/i, '... names what was given';
  unlike "$err", qr/\Q$bad{$label}\E/, '... never quotes the value';

  $err = do { local $@; eval { plain_list([ ok => { schema => $bad{$label} } ]); 1 } ? undef : $@ };
  isa_ok $err, 'DBIO::Exception', "schema option with $label";
  like "$err", qr/option 'schema'/, '... names the option';
  unlike "$err", qr/\Q$bad{$label}\E/, '... never quotes the value';
}

for my $name ('a"b', 'a b', 'a\\b') {
  my $list = eval { plain_list([ $name ]) };
  ok $list, "extension name $name passes core" or diag $@;
}

# activation: load libraries and search_path names
our $n;
sub mk {
  my (%activation) = @_;
  my $class = "T::Name::E" . ++$n;
  no strict 'refs';
  @{"${class}::ISA"} = ('DBIO::Extension');
  *{"${class}::extension_interface"} = sub { 1 };
  *{"${class}::name"} = sub { 'x' };
  *{"${class}::activation"} = sub { \%activation };
  return { name => 'x', class => $class, options => {}, installed => 1, version => '1', schema => 'public' };
}

for my $label (sort keys %bad) {
  for my $key (qw(load search_path)) {
    my $p = DBIO::Extension::Protocol->new(entries => [ mk($key => [ $bad{$label} ]) ], driver => {});
    my $err = do { local $@; eval { $p->activation; 1 } ? undef : $@ };
    isa_ok $err, 'DBIO::Exception', "activation $key with $label";
    like "$err", qr/activation \Q$key\E/, '... names the key';
    unlike "$err", qr/\Q$bad{$label}\E/, '... never quotes the value';
  }
}

my $p = DBIO::Extension::Protocol->new(
  entries => [ mk(load => ['a"b'], search_path => ['a b', 'a\\b']) ], driver => {},
);
is_deeply $p->activation, { load => ['a"b'], search_path => ['a b', 'a\\b'] },
  'quote, blank and backslash go through to the driver';

done_testing;
