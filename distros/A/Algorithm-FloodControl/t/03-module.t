#
#===============================================================================
#
#         FILE:  03-module.t
#
#  DESCRIPTION:  Test for Algorithm::FloodControl
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Andrey Kostenko (http://kostenko.name), <andrey@kostenko.name>
#      COMPANY:  Rambler Internet Holding
#      VERSION:  1.0
#      CREATED:  01.11.2008 17:29:02 MSK
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use Cache::FastMmap;
use File::Temp;

use Test::More tests => 5;


use Algorithm::FloodControl;
my $control = Algorithm::FloodControl->new(
        storage => new Cache::FastMmap ( { share_file => File::Temp->new->filename }),
        limits => {
            check_auth_data => [
                {
                    period => 60,
                    attempts => 5
                }, {
                    period => 3600,
                    attempts => 30
                }
            ]
        }
);
ok( $control );
ok( ! $control->is_user_overrated( check_auth_data => "test_$$") );
$control->register_attempt( check_auth_data => "test_$$" );
my $attempts = $control->get_attempt_count( check_auth_data => "test_$$" );
is( $attempts->{60}, 1 );
is( $attempts->{3600}, 1 );
foreach ( 1 .. 4 ) {
    $control->register_attempt( check_auth_data => "test_$$" );
}
$attempts = $control->get_attempt_count( check_auth_data => "test_$$" );
ok( $control->is_user_overrated( check_auth_data => "test_$$") );

