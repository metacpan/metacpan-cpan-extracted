use Test::More;
use strict;
use warnings;
use Articulate::Authorisation::AlwaysAllow;
use Articulate::Permission qw(new_permission);

my $rule = Articulate::Authorisation::AlwaysAllow->new;

my $result = $rule->permitted( new_permission 'anybody', read => 'data' );
isa_ok( $result, 'Articulate::Permission' );
ok( $result,          'Result should be true' );
ok( $result->granted, 'Result should be that permission was granted' )
  ; # this is probably overkill

done_testing();
