use strict;
use warnings;

use Test::More;
use File::Temp qw(tempdir);

use DBIO::Util qw(file_path write_file);

# Claim (karr k225): `use DBIO::Moo` and `use DBIO::Moose` switch strict and
# warnings on in the file that says it -- as plain `use Moo` / `use Moose` do,
# and as DBIO::Cake and DBIO::Candy do. A result class that writes only
# `use DBIO::Moo;` must not silently compile non-strict code.
#
# Each probe is a real file loaded with `do`, which compiles it with no
# lexical hints inherited from this test. The control probe pins that down: if
# this test's own `use strict` / `use warnings` ever leaked into a probe, the
# control would stop compiling or start warning, and the assertions below it
# could no longer tell DBIO::Moo apart from the harness.

my $dir = tempdir( CLEANUP => 1 );
my $n   = 0;

# Load a file containing $body in a package of its own. Returns whether it
# loaded, the compile/run error, and the warnings it emitted. $^W is pinned to
# 0 so a -w harness cannot supply the warnings the probe is meant to prove.
sub load_probe {
  my ($body) = @_;
  $n++;
  my $file = file_path( $dir, "Probe$n.pm" );
  write_file( $file, "package DBIO::Test::StricturesProbe$n;\n$body\n1;\n" );
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  local $^W = 0;
  local $@;
  my $ok = do $file;
  return ( $ok, $@, \@warnings );
}

my $undeclared = '$undeclared_global = 1;';
my $uninit     = 'my $maybe; my $sum = $maybe + 1;';

subtest 'control: a probe file starts without strict and warnings' => sub {
  my ( $ok, $err, $warns ) = load_probe("$undeclared\n$uninit");
  ok( $ok, 'undeclared global compiles without a strictures import' )
    or diag $err;
  is_deeply( $warns, [], 'no uninitialized warning without a warnings import' );
};

my %needs = (
  'DBIO::Moo'   => [qw( Moo )],
  'DBIO::Moose' => [qw( Moose MooseX::NonMoose )],
);

for my $mod ( sort keys %needs ) {
  subtest "use $mod enables strict and warnings in the calling file" => sub {
    for my $dep ( @{ $needs{$mod} } ) {
      plan skip_all => "$dep not installed"
        unless eval "require $dep; 1";  ## no critic
    }

    my ( $ok, $err ) = load_probe("use $mod;\n$undeclared");
    ok( !$ok, "an undeclared global no longer compiles after use $mod" );
    like(
      $err,
      qr/Global symbol "\$undeclared_global" requires explicit package name/,
      'it fails on strict vars, not on something else',
    );

    my ( $ok2, $err2, $warns ) = load_probe("use $mod;\n$uninit");
    ok( $ok2, "the warnings probe compiles and runs under use $mod" )
      or diag $err2;
    is( scalar @$warns, 1, 'exactly one warning' );
    like(
      $warns->[0] // '',
      qr/Use of uninitialized value \$maybe in addition/,
      'it is the uninitialized warning from the file itself',
    );
  };
}

done_testing;
