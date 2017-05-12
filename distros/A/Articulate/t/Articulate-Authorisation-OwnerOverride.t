use Test::More;
use strict;
use warnings;
use Articulate::Authorisation::OwnerOverride;
use Articulate::Permission qw(new_permission);

my $rule = Articulate::Authorisation::OwnerOverride->new;

subtest "For some given user who is not owner..." => sub {
  my $nobody_result =
    $rule->permitted( new_permission 'nobody', read => 'data' );
  isa_ok( $nobody_result, 'Articulate::Permission' );
  ok( !$nobody_result, 'Result should be false' );
  ok( !$nobody_result->denied,
    'Permission should not have been explicitly denied' )
    ; # necessary because false also includes "not yet permitted or denied"
};

subtest "For the owner..." => sub {
  my $owner_result = $rule->permitted( new_permission 'owner', read => 'data' );
  isa_ok( $owner_result, 'Articulate::Permission' );
  ok( $owner_result,          'Result should be true' );
  ok( $owner_result->granted, 'Result should be that permission was granted' )
    ; # this is probably overkill
};

done_testing();
