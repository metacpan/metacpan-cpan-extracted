package Amazon::SimpleDB::GetAttributesResponse;
use strict;
use warnings;

use base 'Amazon::SimpleDB::Response';

sub results {
    my $self    = shift;
    my $results =
      $self->{content}->{GetAttributesResponse}{GetAttributesResult}{Attribute};
    my $attr = {};
    for my $a (@$results) {
        $attr->{$a->{'Name'}} ||= [];
        push @{$attr->{$a->{'Name'}}}, $a->{'Value'};
    }
    return $attr;
}

1;

__END__

=head1 NAME

Amazon::SimpleDB::GetAttributesResponse - a class
representing the response to a successful GetAttributes
request.

=head1 DESCRIPTION

B<This is code is in the early stages of development. Do not
consider it stable. Feedback and patches welcome.>

This is a subclass L<Amazon::SimpleDB::Response>. See its
manpage for more.

=head1 METHODS

=head2 Amazon::SimpleDB::GetAttributesResponse->new($args)

Constructor. It is recommended that you use
C<Amazon::SimpleDB::Response->new($http_response)> instead
of calling this directly. It will will determine if this
specialized response class is appropriate and will call this
constructor for you.

=head2 $res->results

Returns a HASHREF of the attributes of an item as requested.
An attribute name is the HASH key. All attribute values are
ARRAYREFs regardless of value count.

=head1 SEE ALSO

L<Amazon::SimpleDB::Response>

=head1 AUTHOR & COPYRIGHT

Please see the L<Amazon::SimpleDB> manpage for author, copyright, and
license information.
