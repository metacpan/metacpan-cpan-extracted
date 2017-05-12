package Courriel::Role::Part;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.44';

use Courriel::Header::ContentType;
use Courriel::Header::Disposition;
use Courriel::Types qw( NonEmptyStr );

use Moose::Role;

with 'Courriel::Role::Streams';

requires qw( _stream_content );

has headers => (
    is       => 'rw',
    writer   => '_set_headers',
    does     => 'Courriel::Headers',
    required => 1,
);

has container => (
    is       => 'rw',
    writer   => '_set_container',
    isa      => 'Courriel::Part::Multipart',
    weak_ref => 1,
);

has content_type => (
    is        => 'ro',
    isa       => 'Courriel::Header::ContentType',
    lazy      => 1,
    builder   => '_build_content_type',
    predicate => '_has_content_type',
    handles   => [qw( mime_type charset has_charset )],
);

after BUILD => sub {
    my $self = shift;

    $self->_maybe_set_content_type_in_headers;

    return;
};

after _set_headers => sub {
    my $self = shift;

    $self->_maybe_set_content_type_in_headers;

    return;
};

sub _maybe_set_content_type_in_headers {
    my $self = shift;

    return unless $self->_has_content_type;

    $self->headers->replace( 'Content-Type' => $self->content_type );
}

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _stream_to {
    my $self   = shift;
    my $output = shift;

    $self->headers->stream_to( output => $output );
    $output->($Courriel::Helpers::CRLF);
    $self->_stream_content($output);

    return;
}
## use critic;

{
    my $fake_ct = Courriel::Header::ContentType->new_from_value(
        name  => 'Content-Type',
        value => 'text/plain'
    );

    sub _build_content_type {
        my $self = shift;

        my @ct = $self->headers->get('Content-Type');
        if ( @ct > 1 ) {
            die 'This part defines more than one Content-Type header.';
        }

        return $ct[0] // $fake_ct;
    }
}

1;
