package Data::AnyXfer::JSON;

use v5.10.1;

use utf8;

use strict;
use warnings;

use base 'Cpanel::JSON::XS';

use Encode ();
use Path::Class ();
use Exporter qw/ import /;

our $VERSION = '0.07';

our @EXPORT    = qw/
  encode_json
  encode_json_pretty
  decode_json
  decode_json_file
  decode_json_handle
/;

our @EXPORT_OK = @EXPORT;

=head1 NAME

=encoding utf8

Data::AnyXfer::JSON - functions for encoding/decoding JSON

=head1 SYNOPSIS

  use utf8; # source code contains UTF-8

  use Data::AnyXfer::JSON qw/ decode_json /;

  my $json = encode_json( { price => '£185pcm' } );

  my $hash = decode_json( $json );

=head1 DESCRIPTION

This module provides simple wrappers around L<Cpanel::JSON::XS> that
ensure JSON strings are encoded as UTF-8 before decoding them.

=head1 EXPORTS

=head2 C<encode_json>

  my $json = encode_json( { price => '£185pcm' } );

Return UTF-8 encoded JSON.

=cut

sub encode_json {
    return Cpanel::JSON::XS->new->encode( $_[0] );
}

=head2 C<encode_json_pretty>

  my $json = encode_json_pretty( { price => '£185pcm' } );

Return UTF-8 encoded I<multi-line formatted / pretty> JSON.

=cut

sub encode_json_pretty {
    return Cpanel::JSON::XS->new->utf8->pretty->encode( $_[0] );
}

=head2 C<decode_json>

  my $hash = decode_json( $json );

Decode a JSON string. Automatically encodes it to UTF-8.

=cut

sub decode_json {
    my $json = shift;

    $json = Encode::encode( 'UTF-8', $json )
        if ( defined $json ) && utf8::is_utf8($json);

    return Cpanel::JSON::XS::decode_json($json);
}

=head2 C<decode_json_file>

  my $hash = decode_json_file( $json_file );

Decode the contents of a file as a JSON string.

Automatically encodes it to UTF-8.

=cut

sub decode_json_file {
    my $json_file = shift;

    my $json = Path::Class::file($json_file)
      ->slurp( iomode => '<:encoding(UTF-8)' );

    return decode_json($json);
}

=head2 C<decode_json_handle>

  my $hash = decode_json_handle( $json_fh );

Decode the contents of a file handle as a JSON string.

Automatically encodes it to UTF-8.

=cut

sub decode_json_handle {
    my $json_handle = shift;

    my $json = do { local $/; <$json_handle> };
    return decode_json($json);
}

=head2 C<is_bool>

=head2 C<true>

=head2 C<false>

See L<Cpanel::JSON::XS>.


=cut

# This creates aliases to special functions so that this behaves
# exactly as Cpanel::JSON::XS does w.r.t. upstream tests.

*is_bool = *Cpanel::JSON::XS::is_bool;

*true = *Cpanel::JSON::XS::true;

*false = *Cpanel::JSON::XS::false;

1;


=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut
