package Amazon::SimpleDB::Domain;
use strict;
use warnings;

use Amazon::SimpleDB::Response;
use Carp qw( croak );

sub new {
    my $class = shift;
    my $args  = shift || {};
    my $self  = bless $args, $class;
    croak "No account"       unless $self->{account};
    croak "No (domain) name" unless $self->{name};
    return $self;
}

sub account { return $_[0]->{account} }
sub name    { return $_[0]->{name} }
sub delete  { return $_[0]->{account}->delete_domain($_[0]->{name}) }

# note: limit can be between 1 and 250. default is 100.
# note: cannot run longer then 5 seconds or times out.
sub query {
    my $self   = shift;
    my $args   = shift || {};
    my $params = {DomainName => $self->{'name'}};
    $params->{MaxNumberOfItems} = $args->{'limit'} if $args->{'limit'};
    $params->{NextToken}        = $args->{'next'}  if $args->{'next'};
    $params->{QueryExpression}  = $args->{'query'} if $args->{'query'};
    my $account = $self->{account};
    return
      Amazon::SimpleDB::Response->new(
                           http_response => $account->request('Query', $params),
                           domain        => $self,
                           account       => $self->{account},
      );
}

1;

__END__

=head1 NAME

Amazon::SimpleDB::Domain - a class representing a domain in SimpleDB

=head1 DESCRIPTION

B<This is code is in the early stages of development. Do not
consider it stable. Feedback and patches welcome.>

=head1 METHODS

=head2 Amazon::SimpleDB::Domain->new($args)

Constructor for a domain. Takes a required HASHREF with two required keys:

=over

=item account

An L<Amazon::SimpleDB> account object the item is to be associated.

=item name

The name of the domain for the constructed object.

=back

Typically this method will not be called directly by a
developer, but rather other parts of the L<Amazon::SimpleDB>
package.

This method does not check if an domain exists and is accessible.

=head2 $domain->account

Returns a reference to the L<Amazon::SimpleDB> account object.

=head2 $domain->name

Returns the domain name of the object.

=head2 $domain->delete

Deletes the domain from SimpleDB that this object represents.

This is an alias C<$domain->account->delete_bucket($domain->name)>.

=head2 $domain->query([$args])

Queries the item in the domain and returns matching items
according to the optional arguments HASHREF. If nothing is
passed in all items in the domain are returned. 

The arguments HASHREF can have these three keys:

=over

=item query

A SimpleDB query expression string.

=item limit

A number between 1 and 250 that defines the maximum number
of items to return in a single request. The SimpleDB default
is 100.

=item next

A "next token" from a previous request that can be used to
retrieve more items when the results of a query exceeds the
limit.

=back

=head1 SEE ALSO

L<Amazon::SimpleDB>, L<Amazon::SimpleDB::ListDomainsResponse>

=head1 AUTHOR & COPYRIGHT

Please see the L<Amazon::SimpleDB> manpage for author, copyright, and
license information.
