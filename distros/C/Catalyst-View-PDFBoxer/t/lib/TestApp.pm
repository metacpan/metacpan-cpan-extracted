package TestApp;

use strict;
use warnings;

use Catalyst; # qw/-Debug/;
use Path::Class;

our $VERSION = '0.01';

__PACKAGE__->config(
    name                  => 'TestApp',
    default_message       => 'helloo',
    default_view          => 'PDFBoxer',
    'View::PDFBoxer' => {
        PRE_CHOMP          => 1,
        POST_CHOMP         => 1,
        TEMPLATE_EXTENSION => '.tt',
        render_die         => 1,
    },
);

__PACKAGE__->setup;

