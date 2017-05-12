package Amazon::SimpleDB::Response;
use strict;
use warnings;

use XML::Simple;
use Carp qw( croak );

our %SPECIALS = (
                 'ErrorResponse'         => 1,
                 'ListDomainsResponse'   => 1,
                 'GetAttributesResponse' => 1,
                 'QueryResponse'         => 1,
);

sub new {
    my $class = shift;
    my $args = shift || {};
    croak "No account" unless $args->{account};
    my $r = $args->{http_response};
    croak 'No HTTP::Response object in http_response'
      unless ref $r && $r->isa('HTTP::Response');
    my $tree;
    eval {
        my $content = $r->content;
        $tree =
          XMLin(
                $content,
                'ForceArray' => ['Attribute', 'DomainName', 'ItemName'],
                'KeepRoot'   => 1
          );
    };
    croak $@ if $@;
    my ($type) = keys %$tree;
    if ($r->is_error) {
        require Amazon::SimpleDB::ErrorResponse;
        $class = 'Amazon::SimpleDB::ErrorResponse';
    } elsif ($SPECIALS{$type}) {
        $class = "Amazon::SimpleDB::${type}";
        eval "use $class";
        croak $@ if $@;
    }
    my $self = bless {}, $class;
    $self->{'account'}       = $args->{account};
    $self->{'http_response'} = $r;
    $self->{'http_status'}   = $r->code;
    $self->{'content'}       = $tree;
    $self->{'response_type'} = $type;
    if ($r->is_success) {    # errors are stored differently
        $self->{'request_id'} = $tree->{$type}{ResponseMetadata}{RequestId};
        $self->{'box_usage'}  = $tree->{$type}{ResponseMetadata}{BoxUsage};
    }
    return $self;
}

sub type          { return $_[0]->{'response_type'} }
sub http_response { return $_[0]->{'http_response'} }
sub http_status   { return $_[0]->{'http_status'} }
sub content       { return $_[0]->{'content'} }
sub request_id    { return $_[0]->{'request_id'} }
sub box_usage     { return $_[0]->{'box_usage'} }
sub is_success    { return $_[0]->{'http_response'}->is_success }
sub is_error      { return $_[0]->{'http_response'}->is_error }

1;

__END__

=head1 NAME

Amazon::SimpleDB::Response - a class representing a generic
response from the SimpleDB service.

=head1 DESCRIPTION

B<This is code is in the early stages of development. Do not
consider it stable. Feedback and patches welcome.>

This is a generic response class for the results of any
request that does not require special handling. The class is
the base class to specialized response classes such as
L<Amazon::ErrorResponse> and L<Amazon::QueryResponse>.

=head1 METHODS

=head2 Amazon::SimpleDB::Response->new($args)

Constructs an appropriate SimpleDB response object based on
the L<HTTP::Response> object provided. This method takes a
required HASHREF with two required keys:

=over

=item http_response

A L<HTTP::Response> object or subclass this response from a
request to the service.

=item account

A reference to the L<Amazon::SimpleDB> account object this
response is associated to.

=back

=head2 $res->type

A string defining the response type that is determined by
the root element of the XML document that was returned.

=head2 $res->http_response

Returns the L<HTTP::Response> object used to construct this
response object.

=head2 $res->http_status

Returns the HTTP status code for the underlying response.

=head2 $res->content

The parsed XML contents of the response.

=head2 $res->request_id

=head2 $res->box_usage

=head2 $res->is_success

=head2 $res->is_error

=head1 SEE ALSO

L<Amazon::SimpleDB::ErrorResponse>,
L<Amazon::SimpleDB::GetAttributesResponse>,
L<Amazon::SimpleDB::ListDomainsResponse>,
L<Amazon::SimpleDB::QueryResponse>

=head1 AUTHOR & COPYRIGHT

Please see the L<Amazon::SimpleDB> manpage for author, copyright, and
license information.


