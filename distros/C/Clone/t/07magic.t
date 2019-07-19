# $Id: 07magic.t,v 1.8 2019/07/16 15:32:45 ray Exp $

use strict;

use Clone;
use Test::More tests => 10;

SKIP: {
  eval "use Data::Dumper";
  skip "Data::Dumper not installed", 1 if $@;

  SKIP: {
    eval "use Scalar::Util qw( weaken )";
    skip "Scalar::Util not installed", 1 if $@;
  
    my $x = { a => "worked\n" }; 
    my $y = $x;
    weaken($y);
    my $z = Clone::clone($x);
    ok( Dumper($x) eq Dumper($z), "Cloned weak reference");
  }

  ## RT 21859: Clone segfault (isolated example)
  SKIP: {
    my $string = "HDDR-WD-250JS";
    eval {
      use utf8;
      utf8::upgrade($string);
    };
    skip $@, 1 if $@;
    $string = sprintf ('<<bg_color=%s>>%s<</bg_color>>%s',
          '#EA0',
          substr ($string, 0, 4),
          substr ($string, 4),
        );
    my $z = Clone::clone($string);
    ok( Dumper($string) eq Dumper($z), "Cloned magic utf8");
  }
}

SKIP: {
  eval "use Taint::Runtime qw(enable taint_env)";
  skip "Taint::Runtime not installed", 1 if $@;
  taint_env();
  my $x = "";
  for (keys %ENV)
  {
    $x = $ENV{$_};
    last if ( $x && length($x) > 0 );
  }
  my $y = Clone::clone($x);
  ## ok(Clone::clone($tainted), "Tainted input");
  ok( Dumper($x) eq Dumper($y), "Tainted input");
}

SKIP: {
  eval q{require Devel::Peek; require B; 1 } or skip "Devel::Peek or B missing", 7;

  my $clone_ref;

  {
      # one utf8 string
      my $content = "a\r\n";
      utf8::upgrade($content);

      # set the PERL_MAGIC_utf8
      index($content, "\n");

      my $pv = B::svref_2object( \$content );
      is ref($pv), 'B::PVMG', "got a PV";
      ok $pv->MAGIC, "PV as a magic set";
      is $pv->MAGIC->TYPE, 'w', 'PERL_MAGIC_utf8';
      Devel::Peek::Dump(  $content );

      # Now clone it
      $clone_ref = Clone::clone(\$content);
      #is svref_2object( $clone_ref )->MAGIC->PTR, undef, 'undef ptr';
      # And inspect it with Devel::Peek.
      $pv = B::svref_2object( $clone_ref );
      is ref($pv), 'B::PVMG', "clone - got a PV";
      ok $pv->MAGIC, "clone - PV as a magic set";
      is $pv->MAGIC->TYPE, 'w', 'clone - PERL_MAGIC_utf8';

      Devel::Peek::Dump(  $$clone_ref );

      ok 1, "Dump without segfault";
  }
}

