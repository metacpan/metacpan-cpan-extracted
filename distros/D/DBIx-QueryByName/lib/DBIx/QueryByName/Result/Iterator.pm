package DBIx::QueryByName::Result::Iterator;
use utf8;
use strict;
use warnings;
use Data::Dumper;
use DBIx::QueryByName::Logger qw(get_logger);

sub new {
    my ($class,$query,$sth) = @_;
    get_logger->logcroak("undefined query name")
        if (!defined $query);
    get_logger->logcroak("undefined sth or not a sth")
        if (!defined $sth || ref $sth ne 'DBI::st');
    return bless( { query => $query, sth => $sth }, $class);
}

sub next { die "BUG: not implemented" }

sub to_list {
    my $self = shift;

    my @r;
    while (1) {
        my $v = $self->next;

        # Abort when sth is gone, we can't check for undef
        # value in $v because NULL is a valid return from a
        # query
        last unless $self->{sth};

        push @r, $v;
    }

    return @r;
}

sub _finish_and_croak {
    my ($self,$msg) = @_;
    $self->{sth}->finish;
    get_logger->logcroak($msg);
}

1;

__END__

=head1 NAME

DBIx::QueryByName::Result::Iterator - Parent class to all iterators

=head1 DESCRIPTION

Provides an iterator-like api to a DBI statement handle. DO NOT USE DIRECTLY!

=head1 INTERFACE

=over 4

=item C<< new($query,$sth) >>

=item C<< $i->next() >>

Returns the next row fetched by this iterator, of undef if no more
rows are to be fetched.

=item C<< $i->to_list() >>

Returns all items from the iterator as a list

=back

=cut
