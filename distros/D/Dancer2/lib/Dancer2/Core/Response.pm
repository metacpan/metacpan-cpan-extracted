# ABSTRACT: Response object for Dancer2

package Dancer2::Core::Response;
$Dancer2::Core::Response::VERSION = '0.400000';
use Moo;

use Encode;
use Dancer2::Core::Types;

use Dancer2 ();
use Dancer2::Core::HTTP;

use HTTP::Headers::Fast;
use Scalar::Util qw(blessed);
use Plack::Util;
use Safe::Isa;
use Sub::Quote ();

use overload
  '@{}' => sub { $_[0]->to_psgi },
  '""'  => sub { $_[0] };

has headers => (
    is     => 'ro',
    isa => InstanceOf['HTTP::Headers'],
    lazy   => 1,
    coerce => sub {
        my ($value) = @_;
        # HTTP::Headers::Fast reports that it isa 'HTTP::Headers',
        # but there is no actual inheritance.
        $value->$_isa('HTTP::Headers')
          ? $value
          : HTTP::Headers::Fast->new(@{$value});
    },
    default => sub {
        HTTP::Headers::Fast->new();
    },
    handles => [qw<header push_header>],
);

sub headers_to_array {
    my $self    = shift;
    my $headers = shift || $self->headers;

    my @hdrs;
    $headers->scan( sub {
        my ( $k, $v ) = @_;
         $v =~ s/\015\012[\040|\011]+/chr(32)/ge; # replace LWS with a single SP
         $v =~ s/\015|\012//g; # remove CR and LF since the char is invalid here
        push @hdrs, $k => $v;
    });

    return \@hdrs;
}

# boolean to tell if the route passes or not
has has_passed => (
    is      => 'rw',
    isa     => Bool,
    default => sub {0},
);

sub pass { shift->has_passed(1) }

has serializer => (
    is  => 'ro',
    isa => ConsumerOf ['Dancer2::Core::Role::Serializer'],
);

has is_encoded => (
    is      => 'rw',
    isa     => Bool,
    default => sub {0},
);

has is_halted => (
    is      => 'rw',
    isa     => Bool,
    default => sub {0},
);

sub halt {
    my ( $self, $content ) = @_;
    $self->content( $content ) if @_ > 1;
    $self->is_halted(1);
}

has status => (
    is      => 'rw',
    isa     => Num,
    default => sub {200},
    lazy    => 1,
    coerce  => sub { Dancer2::Core::HTTP->status(shift) },
);

has content => (
    is        => 'rw',
    isa       => Str,
    predicate => 'has_content',
    clearer   => 'clear_content',
);

has server_tokens => (
    is      => 'ro',
    isa     => Bool,
    default => sub {1},
);

around content => sub {
    my ( $orig, $self ) = ( shift, shift );

    # called as getter?
    @_ or return $self->$orig;

    # No serializer defined; encode content
    $self->serializer
        or return $self->$orig( $self->encode_content(@_) );

    # serialize content
    my $serialized = $self->serialize(@_);
    $self->is_encoded(1); # All serializers return byte strings
    return $self->$orig( defined $serialized ? $serialized : '' );
};

has default_content_type => (
    is      => 'rw',
    isa     => Str,
    default => sub {'text/html'},
);

sub encode_content {
    my ( $self, $content ) = @_;

    return $content if $self->is_encoded;

    # Apply default content type if none set.
    my $ct = $self->content_type ||
             $self->content_type( $self->default_content_type );

    return $content if $ct !~ /^text/;

    # we don't want to encode an empty string, it will break the output
    $content or return $content;

    $self->content_type("$ct; charset=UTF-8")
      if $ct !~ /charset/;

    $self->is_encoded(1);
    return Encode::encode( 'UTF-8', $content );
}

sub new_from_plack {
    my ($self, $psgi_res) = @_;

    return Dancer2::Core::Response->new(
        status  => $psgi_res->status,
        headers => $psgi_res->headers,
        content => $psgi_res->body,
    );
}

sub new_from_array {
    my ($self, $arrayref) = @_;

    return Dancer2::Core::Response->new(
        status  => $arrayref->[0],
        headers => $arrayref->[1],
        content => $arrayref->[2][0],
    );
}

sub to_psgi {
    my ($self) = @_;

    $self->server_tokens
        and $self->header( 'Server' => "Perl Dancer2 " . Dancer2->VERSION );

    my $headers = $self->headers;
    my $status  = $self->status;

    Plack::Util::status_with_no_entity_body($status)
        and return [ $status, $self->headers_to_array($headers), [] ];

    my $content = $self->content;
    # It is possible to have no content and/or no content type set
    # e.g. if all routes 'pass'. Set the default value for the content
    # (an empty string), allowing serializer hooks to be triggered
    # as they may change the content..
    $content = $self->content('') if ! defined $content;

    if ( !$headers->header('Content-Length')    &&
         !$headers->header('Transfer-Encoding') &&
         defined( my $content_length = length $content ) ) {
         $headers->push_header( 'Content-Length' => $content_length );
    }

    # More defaults
    $self->content_type or $self->content_type($self->default_content_type);
    return [ $status, $self->headers_to_array($headers), [ $content ], ];
}

# sugar for accessing the content_type header, with mimetype care
sub content_type {
    my $self = shift;

    if ( scalar @_ > 0 ) {
        my $runner   = Dancer2::runner();
        my $mimetype = $runner->mime_type->name_or_type(shift);
        $self->header( 'Content-Type' => $mimetype );
        return $mimetype;
    }
    else {
        return $self->header('Content-Type');
    }
}

has _forward => (
    is  => 'rw',
    isa => HashRef,
);

sub forward {
    my ( $self, $uri, $params, $opts ) = @_;
    $self->_forward( { to_url => $uri, params => $params, options => $opts } );
}

sub is_forwarded {
    my $self = shift;
    $self->_forward;
}

sub redirect {
    my ( $self, $destination, $status ) = @_;
    $self->status( $status || 302 );

    # we want to stringify the $destination object (URI object)
    $self->header( 'Location' => "$destination" );
}

sub error {
    my $self = shift;

    my $error = Dancer2::Core::Error->new(
        response => $self,
        @_,
    );

    $error->throw;
    return $error;
}

sub serialize {
    my ($self, $content) = @_;

    my $serializer = $self->serializer
        or return;

    $content = $serializer->serialize($content)
        or return;

    $self->content_type( $serializer->content_type );
    return $content;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Core::Response - Response object for Dancer2

=head1 VERSION

version 0.400000

=head1 ATTRIBUTES

=head2 is_encoded

Flag to tell if the content has already been encoded.

=head2 is_halted

Flag to tell whether or not the response should continue to be processed.

=head2 status

The HTTP status for the response.

=head2 content

The content for the response, stored as a string.  If a reference is passed, the
response will try coerce it to a string via double quote interpolation.

=head2 default_content_type

Default mime type to use for the response Content-Type header
if nothing was specified

=head2 headers

The attribute that store the headers in a L<HTTP::Headers::Fast> object.

That attribute coerces from ArrayRef and defaults to an empty L<HTTP::Headers::Fast>
instance.

=head1 METHODS

=head2 pass

Set has_passed to true.

=head2 serializer()

Returns the optional serializer object used to deserialize request parameters

=head2 halt

Shortcut to halt the current response by setting the is_halted flag.

=head2 encode_content

Encodes the stored content according to the stored L<content_type>.  If the content_type
is a text format C<^text>, then no encoding will take place.

Internally, it uses the L<is_encoded> flag to make sure that content is not encoded twice.

If it encodes the content, then it will return the encoded content.  In all other
cases it returns C<false>.

=head2 new_from_plack

Creates a new response object from a L<Plack::Response> object.

=head2 new_from_array

Creates a new response object from a PSGI arrayref.

=head2 to_psgi

Converts the response object to a PSGI array.

=head2 content_type($type)

A little sugar for setting or accessing the content_type of the response, via the headers.

=head2 redirect ($destination, $status)

Sets a header in this response to give a redirect to $destination, and sets the
status to $status.  If $status is omitted, or false, then it defaults to a status of
302.

=head2 error( @args )

    $response->error( message => "oops" );

Creates a L<Dancer2::Core::Error> object with the given I<@args> and I<throw()>
it against the response object. Returns the error object.

=head2 serialize( $content )

    $response->serialize( $content );

Serialize and return $content with the response's serializer.
set content-type accordingly.

=head2 header($name)

Return the value of the given header, if present. If the header has multiple
values, returns the list of values if called in list context, the first one
if in scalar context.

=head2 push_header

Add the header no matter if it already exists or not.

    $self->push_header( 'X-Wing' => '1' );

It can also be called with multiple values to add many times the same header
with different values:

    $self->push_header( 'X-Wing' => 1, 2, 3 );

=head2 headers_to_array($headers)

Convert the C<$headers> to a PSGI ArrayRef.

If no C<$headers> are provided, it will use the current response headers.

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
