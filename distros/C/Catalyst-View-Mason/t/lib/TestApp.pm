package TestApp;

use strict;
use warnings;
use Scalar::Util qw/blessed/;
use Catalyst;

our $VERSION = '0.01';

__PACKAGE__->config(
        name                     => 'TestApp',
        default_view             => 'Mason::Appconfig',
        default_message          => 'hi',
        'View::Mason::Appconfig' => {
            default_escape_flags => ['h'],
            use_match            => 0,
        },
);

if ($::use_root_string) {
    __PACKAGE__->config(root => __PACKAGE__->config->{root}->stringify);
}

__PACKAGE__->config(
        setup_components => {
            except => [
                'TestApp::View::Mason::CompRootRef',
                ($::setup_match ? () : 'TestApp::View::Mason::Match'),
            ],
        },
);

__PACKAGE__->log( $::fake_log || Catalyst::Log->new(qw/debug info error fatal/) );

__PACKAGE__->setup;


1;
