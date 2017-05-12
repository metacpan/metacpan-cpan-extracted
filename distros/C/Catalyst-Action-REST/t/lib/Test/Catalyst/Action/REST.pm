package Test::Catalyst::Action::REST;

use Moose;
use namespace::autoclean;

use Catalyst::Runtime '5.70';

use Catalyst;
use FindBin;
use Test::Catalyst::Log;

__PACKAGE__->config(
    name => 'Test::Catalyst::Action::REST',
    # RT#43840 -- this was ignored in 0.66 and earlier
    'Controller::Serialize' => {
        content_type_stash_key => 'serialize_content_type',
    },
);
__PACKAGE__->request_class($ENV{CAR_TEST_REQUEST_CLASS})
    if $ENV{CAR_TEST_REQUEST_CLASS};
__PACKAGE__->setup;
__PACKAGE__->log( Test::Catalyst::Log->new )
    unless __PACKAGE__->debug;

1;
