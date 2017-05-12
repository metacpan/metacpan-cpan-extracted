# -*- perl -*-

# Copyright (c) 2008 by AdCopy
# Author: Jeff Weisberg
# Created: 2008-Dec-18 10:37 (EST)
# Function: miscellanea
#
# $Id$

package AC::Misc;
use AC::Import;
use Socket;
use POSIX;
use MIME::Base64;
use Sys::Hostname;

use strict;

our @EXPORT = qw(inet_atoi inet_ntoi inet_iton inet_itoa inet_lton inet_ntoa inet_aton
                 inet_valid inet_normalize
		 random_text random_bytes unique
                 url_encode url_decode
		 encode_base64_safe decode_base64_safe
		 hex_dump shuffle);

# network length => packed netmask
sub inet_lton {
    my $l = shift;

    pack 'N', (0xFFFFFFFF << (32-$l));
}

# ascii => integer
sub inet_atoi {
    my $a = shift;
    return inet_ntoi(inet_aton($a));
}

# packed => integer
sub inet_ntoi {
    my $n = shift;
    return unpack('N', $n);
}

# integer => packed
sub inet_iton {
    my $i = shift;
    return pack('N', $i);
}

# integer => ascii
sub inet_itoa {
    my $i = shift;
    return inet_ntoa(inet_iton($i));
}

sub inet_valid {
    my $ip = shift;

    return 1 if $ip =~ /^\d+\.\d+\.\d+\.\d+$/;
    return 1 if $ip =~ /^[0-9a-f]*:[0-9a-f:.]+$/i;
    return ;
}

sub inet_normalize {
    my $ip = shift;

    # ipv4
    return $ip if $ip =~ /^\d+\.\d+\.\d+\.\d+$/;

    # ipv6: expand ::
    my($l, $r) = split /::/, lc($ip);
    my @ln = split /:/, $l;
    my @rn = split /:/, $r;
    my @mn = ('0') x (8 - @ln - @rn);

    return join(':', @ln, @mn, @rn);
}

################################################################

sub hex_dump {
    my $s = shift;
    my $r;
    my $off = 0;

    while( my $l = substr($s,0, 16, '') ){
	(my $t = $l) =~ s/\W/\./g;
	my $h = unpack('H*', $l) . ('  ' x (16 - length($l)));
	$h =~ s/(..)/$1 /g;
	$h =~ s/(.{24})/$1 /;

	$r .= sprintf('%04X: ', $off) . "$h $t\n";
	$off += 16;
    }

    $r;
}

################################################################

sub encode_base64_safe {
    my $t = shift;

    my $u = encode_base64( $t );
    $u =~ tr/\r\n//d;
    $u =~ s/=*$//;
    $u =~ tr%+/=%-._%;

    return $u;
}

sub decode_base64_safe {
    my $u = shift;

    $u  =~ tr%-._%+/=%;
    $u  =~ tr%\r\n\t %%d;	# remove white

    # re-add final =s
    my $l = length($u) %4;
    $u .= '=' x (4-$l) if $l;

    return decode_base64($u);
}

################################################################

sub url_encode {
    my $txt = shift;

    $txt =~ s/([^a-z0-9_\.\-])/sprintf('%%%02x',ord($1))/gei;
    return $txt;
}

sub url_decode {
    my $txt = shift;

    $txt =~ s/%(..)/chr(hex $1)/ge;
    return $txt;
}

################################################################

my $rndbuf;
sub random_bytes {
    my $len = shift;

    unless( length($rndbuf) >= $len ){
	if( open(RND, "/dev/urandom") ){
            my $buf;
            my $rl = $len > 512 ? $len : 512;
            sysread(RND, $buf, $rl);
            $rndbuf .= $buf;
            close RND;
        }else{
            # QQQ - complain?
            $rndbuf .= pack('N', rand(0xffffffff)) while(length($rndbuf) < $len);
        }
    }

    return substr($rndbuf, 0, $len, '');
}

sub random_text {
    my $len = shift;

    return substr( encode_base64_safe( random_bytes( ($len * 3 + 3) >> 2 )),
		   0, $len);
}

################################################################

my $unique_n;
my $myip;

# a unique identifier
sub unique {
    my $len = shift;
    my $tag = shift;

    $unique_n ||= rand(256);
    _init_myip();

    my $u = encode_base64_safe( pack('Vna4n', time(), $$, $myip, $unique_n++)
                               ^ "\xDE\xAD\xDE\xAD\xD0\x0D\xA5\xC3\xCA\x53\xC3\xA3" );
    $u .= random_text($len - length($u)) if $len > length($u);

    return $tag . $u;
}

################################################################

sub _init_myip {
    $myip ||= gethostbyname( hostname() );
    die "cannot determine my IP!\n" unless $myip;
}


# fisher yates - cut+paste from perl-faq-4
sub shuffle {
    my $deck = shift;
    return unless $deck;
    my $i = @$deck;
    while (--$i > 0) {
        my $j = int rand ($i+1);
        @$deck[$i,$j] = @$deck[$j,$i];
    }
    return $deck;
}

1;
