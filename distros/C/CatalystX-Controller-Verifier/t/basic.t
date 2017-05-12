package SimpleController;

use Moose;

extends 'Catalyst::Controller';

with 'CatalystX::Controller::Verifier';

1;

package main;

use Test::More;

my $basic = SimpleController->new(
    verifiers => {
        'search' => {
            filters => [ 'trim' ],
            profile => {
                page => {
                    type => 'Int',
                    post_check => sub { shift->get_value('page') > 0 }
                },
                query => {
                    type     => 'Str',
                    required => 1,
                }
            }
        }
    }
);

my $dm = $basic->_build_data_manager;
isa_ok($dm, 'Data::Manager', 'built data manager');
isa_ok($dm->get_verifier('search'), 'Data::Verifier', 'Verifier for search scope');

done_testing;
