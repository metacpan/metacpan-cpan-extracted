package App::TLSMe::Pool;

use strict;
use warnings;

use App::TLSMe::Connection::raw;
use App::TLSMe::Connection::http;

sub new {
    my $class = shift;

    my $self = {@_};
    bless $self, $class;

    $self->{connections} = {};

    return $self;
}

sub add_connection {
    my $self = shift;
    my (%args) = @_;

    my $connection_class = 'App::TLSMe::Connection::' . $args{protocol};

    $self->{connections}->{$args{fh}} = $connection_class->new(%args);
}

sub remove_connection {
    my $self = shift;
    my ($fh) = @_;

    delete $self->{connections}->{$fh};
}

1;
__END__

=head1 NAME

App::TLSMe::Pool - Connection pool

=head1 SYNOPSIS

    my $pool = App::TLSMe::Pool->new;

    $pool->add_connection(...);

    $pool->remove_connection(...);

=head1 DESCRIPTION

Singleton connection pool.

=head1 METHODS

=head2 C<new>

    App::TLSMe::Pool->new;

Return new object.

=head2 C<add_connection>

    $pool->add_connection(...);

Add new connection.

=head2 C<remove_connection>

    $pool->remove_connection(...);

Remove connection.

=cut
