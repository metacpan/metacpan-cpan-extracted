package Test::App;
use Moose;
use Path::Class;

use Catalyst::Runtime 5.80;
use Catalyst qw[
    Bread::Board
];

use Test::App::Container;

extends 'Catalyst';

my $app_root = __PACKAGE__->path_to('..', '..', '..');

__PACKAGE__->config(
    'Plugin::Bread::Board' => {
        container => Test::App::Container->new(
            name     => 'Test::App',
            app_root => $app_root
        )
    }
);

__PACKAGE__->setup();

1;
