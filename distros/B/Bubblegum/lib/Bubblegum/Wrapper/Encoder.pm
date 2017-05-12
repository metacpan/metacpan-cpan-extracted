# ABSTRACT: Bubblegum Wrapper around Content Encoding
package Bubblegum::Wrapper::Encoder;

use 5.10.0;
use namespace::autoclean;
use Bubblegum::Class;
use Bubblegum::Exception;

use Encode 'find_encoding';

extends 'Bubblegum::Object::Instance';

our $VERSION = '0.45'; # VERSION

sub BUILD {
    my $self = shift;
    $self->data->typeof('str')
        or Bubblegum::Exception->throw(
            verbose => 1,
            message => ref($self)->format(
                'Wrapper package "%s" requires string data'
            ),
        );
}

sub decode {
    my $self = shift;
    my $type = shift // 'utf-8';
    my $decoder = find_encoding $type;

    return undef unless $decoder;
    return $decoder->decode($self->data);
}

sub encode {
    my $self = shift;
    my $type = shift // 'utf-8';
    my $encoder = find_encoding $type;

    return undef unless $encoder;
    return $encoder->encode($self->data);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bubblegum::Wrapper::Encoder - Bubblegum Wrapper around Content Encoding

=head1 VERSION

version 0.45

=head1 SYNOPSIS

    use Bubblegum;

    my $data = '...';
    $data->encoder->encode;

=head1 DESCRIPTION

L<Bubblegum::Wrapper::Encoder> is a Bubblegum wrapper which provides access to
content encoding using the encode/decode methods. It is not necessary to use
this module as it is loaded automatically by the L<Bubblegum> class.

=head1 METHODS

=head2 decode

The decode method decodes the encoded string data using the encoding specified.
The default is utf-8 is no encoding is supplied.

=head2 encode

The encode method encodes the raw string data using the encoding specified.
The default is utf-8 is no encoding is supplied.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
