use Test::More;

use strict;
use warnings;

use lib qw(t/lib);
use DDP;
use Test::DBIx::Class -config_path => [[qw/t etc schema /], [qw/t etc schema1 schema1/]], 'User';


isa_ok Schema, 'Schema1'
  => 'Got Correct Schema';

fixtures_ok 'core', "loading core fixtures from file";

my @users = ResultSet('User')->all;
ok( @users, "got users: " . scalar(@users) );

my $flash = User->find( {first_name => 'Flash'} );
ok($flash, "got flash");

done_testing;
