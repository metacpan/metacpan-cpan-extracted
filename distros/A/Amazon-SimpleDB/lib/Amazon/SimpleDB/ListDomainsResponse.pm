package Amazon::SimpleDB::ListDomainsResponse;
use strict;
use warnings;

use base 'Amazon::SimpleDB::Response';

use Amazon::SimpleDB::Domain;

sub results {
    my $self    = shift;
    my $results =
      $self->{content}->{ListDomainsResponse}{ListDomainsResult}{DomainName};
    $self->{next} =
      $self->{content}->{ListDomainsResponse}{ListDomainsResult}{NextToken};
    my @domains = map {
        Amazon::SimpleDB::Domain->new({name => $_, account => $self->{account}})
    } @$results;
    return wantarray ? @domains : $domains[0];
}

sub next { return $_[0]->{next} }

1;

__END__

=head1 NAME

Amazon::SimpleDB::ListDomainsResponse - a class
representing the response to a successful ListDomains
request.

=head1 DESCRIPTION

B<This is code is in the early stages of development. Do not
consider it stable. Feedback and patches welcome.>

This is a subclass L<Amazon::SimpleDB::Response>. See its
manpage for more.

=head1 METHODS

=head2 Amazon::SimpleDB::ListDomainsResponse->new($args)

Constructor. It is recommended that you use
C<Amazon::SimpleDB::Response->new($http_response)> instead
of calling this directly. It will determine if this
specialized response class is appropriate and will call this
constructor for you.

=head2 $res->results

Returns an ARRAY of L<Amazon::SimpleDB::Domain> objects for
the account.

=head2 $res->next

Returns a string representing the NextToken value returned
from the service. Returned undefined if nothing was
returned.

=head1 SEE ALSO

L<Amazon::SimpleDB::Response>

=head1 AUTHOR & COPYRIGHT

Please see the L<Amazon::SimpleDB> manpage for author, copyright, and
license information.
