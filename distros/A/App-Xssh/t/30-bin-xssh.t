use strict;
use warnings;

use Test::More;
use File::Temp;

eval "use Test::Command";
plan skip_all => "Test::Command required for testing command line" if $@;

use App::Xssh;

# Arrange for a safe place to play
$ENV{HOME} = File::Temp::tempdir( CLEANUP => 1 );

exit_isnt_num("$^X bin/xssh --crazy",0);

exit_isnt_num("$^X bin/xssh --setprofileopt testprofile attribute",0);
exit_is_num("$^X bin/xssh --setprofileopt testprofile attribute red",0);

exit_isnt_num("$^X bin/xssh --sethostopt testhost foreground",0);
exit_is_num("$^X bin/xssh --sethostopt testhost foreground red",0);

exit_is_num("$^X bin/xssh --showconfig",0);
exit_is_num("$^X bin/xssh --version",0);

done_testing();
