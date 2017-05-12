package # Hide from PAUSE
Upload::Digest::C::Upload;
our $VERSION = '0.03';

use strict;
use base qw< Catalyst::Base >;

=head1 NAME

Upload::Digest::C::Upload - Upload::Digest F</upload> controller

=head1 METHODS

=cut

=head1 index

Display the upload form which is also the location the POST request
comes to.

=cut

my @algo = sort qw<
                 MD4 MD5 SHA-1 SHA-256 SHA-384 SHA-512 Whirlpool MD2
                 Adler-32 CRC-16 CRC-32 SHA-2 CRC-CCITT Haval256 CMAC
                 MultiHash HMAC JHash Hashcash Tiger FNV DJB
                 ManberHash Pearson EMAC DMAC SV1 Haval256 Nilsimsa Elf

>;

sub index : Default {
    my ( $self, $c ) = @_;

    # Someone uploaded a file
    if ( my $upload = $c->req->upload( 'file' ) ) {
        $c->stash->{ filename } = $upload->filename;
		$c->stash->{ digest } = {};

        for ( @algo ) {
            local $@;
            eval {
                $c->stash->{ digest }->{ $_ } = $upload->digest( $_ );
            };
            $c->stash->{ digest }->{ $_ } = $@ if $@;
        }
    }

    $c->stash->{ template } = 'upload.tt';
}

1;
