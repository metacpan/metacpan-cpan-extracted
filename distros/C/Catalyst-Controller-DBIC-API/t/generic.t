use strict;
use warnings;
use lib 't/lib';
use Test::More;

{
    eval "use Catalyst::Test 'TestAppCheckHasCol'";
    like($@, qr/Couldn't instantiate component "TestAppCheckHasCol::Controller::InvalidColumn", "Column 'foo' does not exist in ResultSet 'TestAppDB::Artist'/, 'check_has_column ok');
}

done_testing();
