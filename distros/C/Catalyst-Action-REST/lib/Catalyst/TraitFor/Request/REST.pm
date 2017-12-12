package Catalyst::TraitFor::Request::REST;
$Catalyst::TraitFor::Request::REST::VERSION = '1.21';
use Moose::Role;
use HTTP::Headers::Util qw(split_header_words);
use namespace::autoclean;

has [qw/ data accept_only /] => ( is => 'rw' );

has accepted_content_types => (
    is       => 'ro',
    isa      => 'ArrayRef',
    lazy     => 1,
    builder  => '_build_accepted_content_types',
    clearer  => 'clear_accepted_cache',
    init_arg => undef,
);

has preferred_content_type => (
    is       => 'ro',
    isa      => 'Str',
    lazy     => 1,
    builder  => '_build_preferred_content_type',
    init_arg => undef,
);

#
# By default the module looks at both Content-Type and
# Accept and uses the selected content type for both
# deserializing received data and serializing the response.
# However according to RFC 7231, Content-Type should be
# used to specify the payload type of the data sent by
# the requester and Accept should be used to negotiate
# the content type the requester would like back from
# the server. Compliance mode adds support so the method
# described in the RFC is more closely model.
#
# Using a bitmask to represent the the two content type
# header schemes.
# 0x1 for Accept
# 0x2 for Content-Type

has 'compliance_mode' => (
    is       => 'ro',
    isa      => 'Int',
    lazy     => 1,
    writer   => '_set_compliance_mode',
    default  => 0x3,
);

# Set request object to only use the Accept header when building
# accepted_content_types
sub set_accept_only {
    my $self = shift;

    # Clear the accepted_content_types cache if we've changed
    # allowed headers
    $self->clear_accepted_cache();
    $self->_set_compliance_mode(0x1);
}

# Set request object to only use the Content-Type header when building
# accepted_content_types
sub set_content_type_only {
    my $self = shift;

    $self->clear_accepted_cache();
    $self->_set_compliance_mode(0x2);
}

# Clear serialize/deserialize compliance mode, allow all headers
# in both situations
sub clear_compliance_mode {
    my $self = shift;

    $self->clear_accepted_cache();
    $self->_set_compliance_mode(0x3);
}

# Return true if bit set to examine Accept header
sub accept_allowed {
    my $self = shift;

    return $self->compliance_mode & 0x1;
}

# Return true if bit set to examine Content-Type header
sub content_type_allowed {
    my $self = shift;

    return $self->compliance_mode & 0x2;
}

# Private writer to set if we're looking at Accept or Content-Type headers
sub _set_compliance_mode {
    my $self = shift;
    my $mode_bits = shift;

    $self->compliance_mode($mode_bits);
}

sub _build_accepted_content_types {
    my $self = shift;

    my %types;

    # First, we use the content type in the HTTP Request.  It wins all.
    # But only examine it if we're not in compliance mode or if we're
    # in deserializing mode
    $types{ $self->content_type } = 3
        if $self->content_type && $self->content_type_allowed();

    # Seems backwards, but users are used to adding &content-type= to the uri to
    # define what content type they want to recieve back, in the equivalent Accept
    # header. Let the users do what they're used to, it's outside the RFC
    # specifications anyhow.
    if ($self->method eq "GET" && $self->param('content-type') && $self->accept_allowed()) {
        $types{ $self->param('content-type') } = 2;
    }

    # Third, we parse the Accept header, and see if the client
    # takes a format we understand.
    # But only examine it if we're not in compliance mode or if we're
    # in serializing mode
    #
    # This is taken from chansen's Apache2::UploadProgress.
    if ( $self->header('Accept') && $self->accept_allowed() ) {
        $self->accept_only(1) unless keys %types;

        my $accept_header = $self->header('Accept');
        my $counter       = 0;

        foreach my $pair ( split_header_words($accept_header) ) {
            my ( $type, $qvalue ) = @{$pair}[ 0, 3 ];
            next if $types{$type};

            # cope with invalid (missing required q parameter) header like:
            # application/json; charset="utf-8"
            # http://tools.ietf.org/html/rfc2616#section-14.1
            unless ( defined $pair->[2] && lc $pair->[2] eq 'q' ) {
                $qvalue = undef;
            }

            unless ( defined $qvalue ) {
                $qvalue = 1 - ( ++$counter / 1000 );
            }

            $types{$type} = sprintf( '%.3f', $qvalue );
        }
    }

    [ sort { $types{$b} <=> $types{$a} } keys %types ];
}

sub _build_preferred_content_type { $_[0]->accepted_content_types->[0] }

sub accepts {
    my $self = shift;
    my $type = shift;

    return grep { $_ eq $type } @{ $self->accepted_content_types };
}

1;
__END__

=head1 NAME

Catalyst::TraitFor::Request::REST - A role to apply to Catalyst::Request giving it REST methods and attributes.

=head1 SYNOPSIS

     if ( $c->request->accepts('application/json') ) {
         ...
     }

     my $types = $c->request->accepted_content_types();

=head1 DESCRIPTION

This is a L<Moose::Role> applied to L<Catalyst::Request> that adds a few
methods to the request object to facilitate writing REST-y code.
Currently, these methods are all related to the content types accepted by
the client and the content type sent in the request.

=head1 METHODS

=over

=item data

If the request went through the Deserializer action, this method will
return the deserialized data structure.

=item accepted_content_types

Returns an array reference of content types accepted by the
client.

The list of types is created by looking at the following sources:

=over 8

=item * Content-type header

If this exists, this will always be the first type in the list.

=item * content-type parameter

If the request is a GET request and there is a "content-type"
parameter in the query string, this will come before any types in the
Accept header.

=item * Accept header

This will be parsed and the types found will be ordered by the
relative quality specified for each type.

=back

If a type appears in more than one of these places, it is ordered based on
where it is first found.

=item preferred_content_type

This returns the first content type found. It is shorthand for:

  $request->accepted_content_types->[0]

=item accepts($type)

Given a content type, this returns true if the type is accepted.

Note that this does not do any wildcard expansion of types.

=back

=head1 AUTHORS

See L<Catalyst::Action::REST> for authors.

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut

