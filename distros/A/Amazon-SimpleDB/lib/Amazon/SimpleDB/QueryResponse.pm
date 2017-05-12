package Amazon::SimpleDB::QueryResponse;
use strict;
use warnings;

use base 'Amazon::SimpleDB::Response';

use Amazon::SimpleDB::Item;
use Carp qw( croak );

sub new {
    my $class = shift;
    my $args = shift || {};
    croak "No domain" unless $args->{domain};
    return $class->SUPER::new($args);
}

sub results {
    my $self    = shift;
    my $results = $self->{content}->{QueryResponse}{QueryResult}{ItemName};
    $self->{next} = $self->{content}->{QueryResponse}{QueryResult}{NextToken};
    my @items = map {
        Amazon::SimpleDB::Item->new(
                                    {
                                     name    => $_,
                                     domain  => $self->{domain},
                                     account => $self->{account}
                                    }
        );
    } @$results;
    return wantarray ? @items : $items[0];
}

sub next { return $_[0]->{next} }

1;

__END__

=head1 NAME

Amazon::SimpleDB::QueryResponse - a class
representing the response to a successful Query
request.

=head1 DESCRIPTION

B<This is code is in the early stages of development. Do not
consider it stable. Feedback and patches welcome.>

This is a subclass L<Amazon::SimpleDB::Response>. See its
manpage for more.

=head1 METHODS

=head2 Amazon::SimpleDB::QueryResponse->new($args)

Constructor. It is recommended that you use
C<Amazon::SimpleDB::Response->new($http_response)> instead
of calling this directly. It will will determine if this
specialized response class is appropriate and will call this
constructor for you.

=head2 $res->results

Returns an ARRAY of matching L<Amazon::SimpleDB::Item>
objects for the associated domain.

=head2 $res->next

Returns a string representing the NextToken value returned
from the service. Returned undefined if nothing was
returned.

=head1 SEE ALSO

L<Amazon::SimpleDB::Response>

=head1 AUTHOR & COPYRIGHT

Please see the L<Amazon::SimpleDB> manpage for author, copyright, and
license information.
