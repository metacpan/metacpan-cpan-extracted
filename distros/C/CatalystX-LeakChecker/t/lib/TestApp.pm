package TestApp;
our $VERSION = '0.06';

use Moose;
use MooseX::Types::Moose qw/ArrayRef/;
use namespace::autoclean;

extends 'Catalyst';
with 'CatalystX::LeakChecker';

has leaks => (
    traits  => [qw(Array)],
    is      => 'ro',
    isa     => ArrayRef,
    default => sub { [] },
    handles => {
        add_leaks   => 'push',
        count_leaks => 'count',
        first_leak  => ['first', sub { 1 }],
    },
);

sub found_leaks {
    my ($ctx, @leaks) = @_;
    $ctx->add_leaks(@leaks);
}

__PACKAGE__->setup;

1;
