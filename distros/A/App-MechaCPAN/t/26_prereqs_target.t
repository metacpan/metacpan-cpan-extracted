use strict;
use Test::More;

use App::MechaCPAN;

require q[./t/helper.pm];

# Make sure the caching and cycle detection of _target_prereqs_were_installed
# operate as intended.


# Wrap _target_prereqs_were_installed to count number of times called.
my $orig_tpwi = \&App::MechaCPAN::Install::_target_prereqs_were_installed;
my $count = 0;
no warnings 'redefine';
local *App::MechaCPAN::Install::_target_prereqs_were_installed = sub
{
  $count++;
  $orig_tpwi->(@_);
};

# Skip the real call to _target_prereqs to control what is returned during
# testing
local *App::MechaCPAN::Install::_target_prereqs = sub
{
  my $target = shift;
  return @{ $target->{prereq_targets} || [] };
};

my %targets;

# Generate a linear list of modules that each depend on the previous
my @prereq_key;
foreach my $key ( qw/E D C B A/ )
{
  $targets{$key} = {
    key            => $key,
    name           => $key,
    was_installed  => 1,
    prereq_targets => [@prereq_key],
  };
  @prereq_key = ( $targets{$key} );
}

sub fake_target {}

# --- Memoization: repeated top-level calls must not re-walk the subtree ---
subtest 'Cache responses' => sub
{
  $count = 0;
  App::MechaCPAN::Install::_target_prereqs_were_installed( $targets{A}, {} );
  is( $count, 5, 'First walk visits every node in the chain once' );

  # Second call: A's answer is already cached in A->{prereqs_was_installed}.
  # A memoized impl short-circuits at the top — exactly one entry (the
  # wrapper call itself), no recursion.
  # After the first call is done, prereqs_was_installed should be the cached result of each target
  foreach my $target ( values %targets )
  {
    $count = 0;
    App::MechaCPAN::Install::_target_prereqs_were_installed( $target, {} );
    is( $count, 1, "Second call returns cached prereqs_was_installed for $target->{key}" );
  }
};

# --- Cycle guard: A -> B -> A must not infinite-recurse ---
# Perl warns "Deep recursion on subroutine" at depth 100; without the
# cycle guard the recursion blows past that and eventually segfaults.
# Convert the warning into a die so this test fails loudly instead of
# crashing the harness.
{
  my $a = fake_target('A');
  my $b = fake_target( 'B', $a );
  push @{ $a->{prereq_targets} }, $b;

  my $returned;
  my $died = '';
  eval {
    local $SIG{__WARN__} = sub {
      die "DEEP_RECURSION\n" if $_[0] =~ /Deep recursion/;
      warn @_;
    };
    local $SIG{ALRM} = sub { die "TIMEOUT\n" };
    alarm 5;
    $returned = App::MechaCPAN::Install::_target_prereqs_were_installed( $a, {} );
    alarm 0;
    1;
  } or do {
    alarm 0;
    $died = $@;
  };

  is( $died, '', 'Cyclic prereq graph does not hang or deep-recurse' )
    or diag("died with: $died");
  ok( defined $returned, 'Cyclic prereq graph returns a defined answer' );
}

done_testing;
