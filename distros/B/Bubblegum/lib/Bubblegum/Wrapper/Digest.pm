# ABSTRACT: Bubblegum Wrapper around Hashing Algorithms
package Bubblegum::Wrapper::Digest;

use 5.10.0;
use Bubblegum::Class;

use Digest::MD5 ();
use Digest::SHA ();

use Bubblegum::Exception;

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

sub encode {
    my $self = shift;
    my $type = shift // 'md5_hex';

    my $encoder;
    my $md5 = [qw(md5 md5_hex)];
    my $sha = [qw(sha1_base64 sha1 sha1_hex)];
    my $hmc = [qw(hmac_sha1 hmac_sha1_hex)];

    $encoder = 'Digest::MD5' if $md5->one('$a eq $b', $type);
    $encoder = 'Digest::SHA' if $sha->one('$a eq $b', $type);
    $encoder = 'Digest::SHA' if $hmc->one('$a eq $b', $type);

    return undef unless $encoder;
    return $encoder->can($type)->($self->data);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bubblegum::Wrapper::Digest - Bubblegum Wrapper around Hashing Algorithms

=head1 VERSION

version 0.45

=head1 SYNOPSIS

    use Bubblegum;

    my $data = '...';
    $data->digest->encode;

=head1 DESCRIPTION

L<Bubblegum::Wrapper::Digest> is a Bubblegum wrapper which provides access to
various hashing algorithms to encode/decode messages. It is not necessary to use
this module as it is loaded automatically by the L<Bubblegum> class.

=head1 METHODS

=head2 encode

The encode method encodes the subject using the hashing algorithm specified,
the default hashing algorithm is md5_hex;

    my $data = '...';
    $data->digest->encode;
    $data->digest->encode('md5_hex'); #same
    $data->digest->encode('md5');
    $data->digest->encode('sha1');
    $data->digest->encode('sha1_base64');
    $data->digest->encode('sha1_hex');
    $data->digest->encode('hmac_sha1');
    $data->digest->encode('hmac_sha1_hex');

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
