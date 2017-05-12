use strict;
use warnings;

use Test::More;
use t::BaseSite;
use t::ExtSite;

can_ok('t::BaseSite', 'root');
can_ok('t::ExtSite',  'root');

my $ext_root  = t::ExtSite->root;
my $base_root = t::BaseSite->root;

is_deeply( [ $base_root->get_service_list ], [ 'created_by' ], "There is only one service in base Root");
is_deeply( [ $base_root->fetch('Database')->get_service_list ], [ 'created_by' ], "There is only one service in base Database");

is_deeply( [ sort { $a cmp $b } $ext_root->get_service_list ], [ 'created_by', 'modified_by' ], "The root container was extended in t::ExtSite");
is_deeply( [ $ext_root->fetch('Database')->get_service_list ], [ 'modified_by' ], "The Database container was replaced in t::ExtSite");

# checking second level
is( $base_root->fetch('First/Second/tag')->get, 'created by BaseSite' );
is( $ext_root->fetch('First/Second/tag')->get,
    'created by BaseSite, modified by ExtSite'
);


# tests where the containers were created
my %root_for = (
    Base => $base_root,
    Ext  => $ext_root,
);

sub _test_service {
    my ($site, $service, $file) = @_;

    like( $root_for{$site}->fetch($service)->get,
        qr{\Q$file\E$},
        "The '$service' service of '$site' site was created in file '$file'" );
}

_test_service( 'Base', 'created_by', 't/BaseSite/Root.ioc');
_test_service( 'Base', 'Database/created_by', 't/BaseSite/Database.ioc');

_test_service( 'Ext', 'created_by', 't/BaseSite/Root.ioc');
_test_service( 'Ext', 'modified_by', 't/ExtSite/Root.bb');

_test_service( 'Ext', 'created_by', 't/BaseSite/Root.ioc');
_test_service( 'Ext', 'Database/modified_by', 't/ExtSite/Database.bb');


done_testing();

# vim: expandtab:shiftwidth=4:tabstop=4:softtabstop=0:textwidth=78:
