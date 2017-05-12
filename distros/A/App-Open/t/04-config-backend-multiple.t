#
#===============================================================================
#
#         FILE:  11-backend-multiple.t
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Erik Hollensbe (), <erik@hollensbe.org>
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  07/04/2008 01:52:12 PM PDT
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use constant CLASS => "App::Open::Config";

BEGIN {
    require Test::More;

    if (eval { require Mail::Cap; require MIME::Types }) {
        Test::More->import('no_plan');
        use_ok(CLASS);
    } else {
        Test::More->import('skip_all' => 'Mail::Cap or MIME::Types is not installed');
    }
};

sub test_backend_order {
    my ( $backend_order, $package_list ) = @_;

    is_deeply( [ map { ref($_) } @{$backend_order} ],
        $package_list, 'testing backend_order' );
}

use Test::Exception;

my $tmp;
my $config_file = "t/resource/configs/multiple_backend.yaml";

lives_ok { $tmp = CLASS->new($config_file) };
lives_ok { $tmp->load_backends }; 

test_backend_order( $tmp->backend_order,
    [ "App::Open::Backend::YAML", "App::Open::Backend::MailCap" ] );
