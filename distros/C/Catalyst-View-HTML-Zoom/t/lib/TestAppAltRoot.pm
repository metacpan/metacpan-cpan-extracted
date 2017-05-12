package TestAppAltRoot;
use Moose;
use File::Spec;
use namespace::autoclean;
use FindBin qw($Bin);

use Catalyst;
extends 'Catalyst';

__PACKAGE__->config(
    default_view => 'HTML',
    'View::HTML' => {
        root => File::Spec->catdir($Bin, ,'lib', __PACKAGE__, 'altroot'),
    },
    'View::HTML::Foo' => {
        test_arg => 111,
    },
);

__PACKAGE__->setup;

1;
