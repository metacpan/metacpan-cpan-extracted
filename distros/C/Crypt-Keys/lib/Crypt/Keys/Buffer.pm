# $Id: Buffer.pm,v 1.1 2001/07/11 03:28:36 btrott Exp $

package Crypt::Keys::Buffer;
use strict;

use Data::Buffer;
use base qw( Data::Buffer );

use Crypt::Keys::Util qw( mp2bin bin2mp bitsize );

{
    my %MP_MAP = (
        'SSH1'    => [ \&_get_mp_int_ssh1,    \&_put_mp_int_ssh1 ],
        'SSH2'    => [ \&_get_mp_int_ssh2,    \&_put_mp_int_ssh2 ],
        'OpenSSH' => [ \&_get_mp_int_openssh, \&_put_mp_int_openssh ],
    );

    sub new {
        my $class = shift;
        my $buffer = $class->SUPER::new;
        my %param = @_;
        my $mp = $param{MP} || 'OpenSSH';
        $buffer->{_get_mp_int} = $MP_MAP{$mp}->[0];
        $buffer->{_put_mp_int} = $MP_MAP{$mp}->[1];
        $buffer;
    }
}

sub get_mp_int { $_[0]->{_get_mp_int}->(@_) }
sub put_mp_int { $_[0]->{_put_mp_int}->(@_) }

sub _get_mp_int_ssh1 {
    my $buf = shift;
    my $off = $buf->{offset};
    my $bits = unpack "n", $buf->bytes($off, 2);
    my $bytes = int(($bits+7)/8);
    my $p = bin2mp( $buf->bytes($off+2, $bytes) );
    $buf->{offset} += 2 + $bytes;
    $p;
}

sub _put_mp_int_ssh1 {
    my $buf = shift;
    my $int = shift;
    my $bits = bitsize($int);
    $buf->put_int16($bits);
    $buf->put_chars( mp2bin($int) );
}

sub _get_mp_int_ssh2 {
    my $buf = shift;
    my $bits = $buf->get_int32;
    my $off = $buf->{offset};
    my $bytes = int(($bits+7) / 8);
    my $int = bin2mp( $buf->bytes($off, $bytes) );
    $buf->{offset} += $bytes;
    $int;
}

sub _put_mp_int_ssh2 {
    my $buf = shift;
    my($int) = @_;
    my $bits = bitsize($int);
    $buf->put_int32($bits);
    $buf->put_chars( mp2bin($int) );
}

sub _get_mp_int_openssh {
    my $buf = shift;
    my $bits = $buf->get_str;
    bin2mp($bits);
}

sub _put_mp_int_openssh {
    my $buf = shift;
    my $int = shift;
    my $bytes = (bitsize($int) / 8) + 1;
    my $bin = mp2bin($int);
    my $hasnohigh = (vec($bin, 0, 8) & 0x80) ? 0 : 1;
    $bin = "\0" . $bin unless $hasnohigh;
    $buf->put_str($bin);
}

1;
