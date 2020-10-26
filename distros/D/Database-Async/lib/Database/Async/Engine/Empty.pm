package Database::Async::Engine::Empty;

use strict;
use warnings;

our $VERSION = '0.012'; # VERSION

use parent qw(Database::Async::Engine);

=head1 NAME

Database::Async::Engine::Empty - a database engine that does nothing useful

=head1 DESCRIPTION

=cut

Database::Async::Engine->register_class(
    empty      => 'Database::Async::Engine::Empty',
);

my %queries = (
    q{select 1} => {
        fields => [ '?column?' ],
        rows => [
            [ '1' ]
        ],
    },
);

sub new {
    my ($class, %args) = @_;
    bless \%args, $class
}

1;

