package DBIx::QueryByName::Result::HashIterator;
use utf8;
use strict;
use warnings;
use Data::Dumper;
use DBIx::QueryByName::Logger qw(get_logger);
use base qw( DBIx::QueryByName::Result::Iterator );

sub next {
    my $self = shift;

    my @columns = @_;

    return undef
        if (!defined $self->{sth});

    if (my $hash = $self->{sth}->fetchrow_hashref()) {

        return $hash
            if (scalar @columns == 0);

        my @values;
        foreach my $c (@columns) {
            if (exists $hash->{$c}) {
                push @values, $hash->{$c};
            } else {
                $self->_finish_and_croak("query ".$self->{query}." does not return any value named $c");
            }
        }

        return @values;
    }

    # no more rows to fetch.
    # TODO: handle specially if it was an error?
    $self->{sth}->finish();
    $self->{sth} = undef;
    return undef;
}

1;

__END__

=head1 NAME

DBIx::QueryByName::Result::HashIterator - A hash iterator around a statement handle

=head1 DESCRIPTION

Provides an iterator-like api to a DBI statement handle that is expected
to return one or more columns upon each call to fetchrow_array().

DO NOT USE DIRECTLY!

=head1 INTERFACE

=over 4

=item C<< my $i = new($query,$sth); >>

Return a hash iterator wrapped around this statement handle.

=item C<< my $result = $i->next(); >>

or

=item C<< my $result = $i->next($col1, $col2...); >>

If C<next> is called with no arguments, it returns the query's
result as a hashref (just as C<fetchrow_hash> would) or undef
if there are no more rows to fetch.

Example:

    # call query GetJobs that returns an iterator on which
    # we call next directly. The query returns a hash with
    # two keys 'id' and 'name'
    my $v = $dbh->GetJobs->next;
    my $id = $v->{id};
    my $name = $v->{name};

If C<next> is called a list of column names in arguments, it returns
the query's result as a list of the corresponding hashref's values for
those columns, or undef if there are no more rows to fetch.

Example:

    # same as previous example, just more concise:
    my ($id,$name) = $dbh->GetJobs->next('id','name');

=back

=cut

