package Crypt::OpenToken::KeyGenerator;

use strict;
use warnings;
use POSIX qw();
use Digest::HMAC_SHA1 qw(hmac_sha1);
use namespace::autoclean;

sub generate {
    my ($password, $keysize) = @_;
    my $key        = '';
    my $offset     = 0;
    my $salt       = "\0" x 8;
    my $iters      = 1000;
    my $blocksize  = 20;

    my $num_blocks = POSIX::ceil($keysize / $blocksize);
    my $digest = Digest::HMAC_SHA1->new($password);
    foreach my $idx (1 .. $num_blocks) {
        $digest->reset();
        $digest->add($salt);
        $digest->add(pack('N', $idx));
        my $sha = $digest->digest;

        # generate the next block, and grab up to "$blocksize" chars out of it
        my $block    = _generate_block($password, $sha, $iters);
        my $need     = $keysize - $offset;
        my $grabbing = $need < $blocksize ? $need : $blocksize;
        $key .= substr($block, 0, $grabbing);
        $offset += $grabbing;
    }
    return $key;
}

sub _generate_block {
    my ($password, $sha, $iters) = @_;
    my $result  = $sha;
    my $current = $sha;

    for (2 .. $iters) {
        $current = hmac_sha1($current, $password);
        $result  = $result ^ $current;
    }
    return $result;
}

1;

=head1 NAME

Crypt::OpenToken::KeyGenerator - Generates keys based on shared passwords

=head1 SYNOPSIS

  use Crypt::OpenToken::KeyGenerator;

  my $keysize  = 16;          # Key size, in Bytes
  my $password = 'abc123';    # shared password
  my $key      = Crypt::OpenToken::KeyGenerator::generate($password, $keysize);

=head1 DESCRIPTION

This module implements a key generation function.

=head1 METHODS

=over

=item generate($password, $keysize)

Generates an OpenToken key using the provided C<$password>.  They generated
key will C<$keysize> bytes in length.

=back

=head1 AUTHOR

Graham TerMarsch (cpan@howlingfrog.com)

=head1 COPYRIGHT & LICENSE

C<Crypt::OpenToken> is Copyright (C) 2010, Socialtext, and is released under
the Artistic-2.0 license.

=cut
