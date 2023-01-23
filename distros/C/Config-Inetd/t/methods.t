#!/usr/bin/perl

use strict;
use warnings;

use Config::Inetd;
use File::Temp ':POSIX';
use Test::More tests => 11;

my $tmpfile = tmpnam();
open(my $fh, '>', $tmpfile) or die "Cannot open `$tmpfile': $!\n";
print {$fh} do { local $/; <DATA> };
close($fh);

my $inetd = Config::Inetd->new($tmpfile);

my ($enabled, $disabled) = (8, 41);

is($inetd->dump_enabled,  $enabled,  '$inetd->dump_enabled()');
is($inetd->dump_disabled, $disabled, '$inetd->dump_disabled()');

my $count = sub
{
    my ($conf, $regex) = @_;
    return scalar grep { $_ =~ $regex } @$conf;
};

is($count->($inetd->config, qr/^\#/), $disabled, 'disabled entries before');
ok($inetd->disable(daytime => 'tcp'), '$inetd->disable()');
ok(!$inetd->is_enabled(daytime => 'tcp'), 'service is disabled');
is($count->($inetd->config, qr/^\#/), $disabled + 1, 'disabled entries after');

is($count->($inetd->config, qr/^[^\#]/), $enabled - 1, 'enabled entries before');
ok($inetd->enable(daytime => 'tcp'), '$inetd->enable()');
ok($inetd->is_enabled(daytime => 'tcp'), 'service is enabled');
is($count->($inetd->config, qr/^[^\#]/), $enabled, 'enabled entries after');

my $entry = qr{
    ^   \#?[\w\Q/.:-[]\E]+
    \s+ (?:stream|dgram)
    \s+ (?:tcp|udp|rpc/udp)6?
    \s+ (?:no)?wait
    \s+ (?:root|_fingerd|_identd)
    \s+ (?:/\w+/\w+/[\w\.]+|internal)
    \s* (?:[\w\.]+)?
}x;

my $matches = scalar grep { $_ =~ $entry } @{$inetd->config};
is($matches, $enabled + $disabled, 'config instance data');

unlink $tmpfile;

__DATA__
#	$OpenBSD: inetd.conf,v 1.55 2004/06/29 20:05:04 matthieu Exp $
#
# Internet server configuration database
#
# define *both* IPv4 and IPv6 entries for dual-stack support.
#
#ftp		stream	tcp	nowait	root	/usr/libexec/ftpd	ftpd -US
#ftp		stream	tcp6	nowait	root	/usr/libexec/ftpd	ftpd -US
#127.0.0.1:8021 stream tcp	nowait	root	/usr/libexec/ftp-proxy ftp-proxy
#telnet		stream	tcp	nowait	root	/usr/libexec/telnetd	telnetd -k
#telnet		stream	tcp6	nowait	root	/usr/libexec/telnetd	telnetd -k
#shell		stream	tcp	nowait	root	/usr/libexec/rshd	rshd -L
#shell		stream	tcp6	nowait	root	/usr/libexec/rshd	rshd -L
#uucpd		stream	tcp	nowait	root	/usr/libexec/uucpd	uucpd
#uucpd		stream	tcp6	nowait	root	/usr/libexec/uucpd	uucpd
#finger		stream	tcp	nowait	_fingerd /usr/libexec/fingerd	fingerd -lsm
#finger		stream	tcp6	nowait	_fingerd /usr/libexec/fingerd	fingerd -lsm
ident		stream	tcp	nowait	_identd	/usr/libexec/identd	identd -el
ident		stream	tcp6	nowait	_identd	/usr/libexec/identd	identd -el
#tftp		dgram	udp	wait	root	/usr/libexec/tftpd	tftpd -s /tftpboot
#tftp		dgram	udp6	wait	root	/usr/libexec/tftpd	tftpd -s /tftpboot
127.0.0.1:comsat dgram	udp	wait	root	/usr/libexec/comsat	comsat
[::1]:comsat	dgram	udp6	wait	root	/usr/libexec/comsat	comsat
#ntalk		dgram	udp	wait	root	/usr/libexec/ntalkd	ntalkd
#pop3		stream	tcp	nowait	root	/usr/sbin/popa3d	popa3d
#pop3		stream	tcp6	nowait	root	/usr/sbin/popa3d	popa3d
# Internal services
#echo		stream	tcp	nowait	root	internal
#echo		stream	tcp6	nowait	root	internal
#discard	stream	tcp	nowait	root	internal
#discard	stream	tcp6	nowait	root	internal
#chargen	stream	tcp	nowait	root	internal
#chargen	stream	tcp6	nowait	root	internal
daytime		stream	tcp	nowait	root	internal
daytime		stream	tcp6	nowait	root	internal
time		stream	tcp	nowait	root	internal
time		stream	tcp6	nowait	root	internal
#echo		dgram	udp	wait	root	internal
#echo		dgram	udp6	wait	root	internal
#discard	dgram	udp	wait	root	internal
#discard	dgram	udp6	wait	root	internal
#chargen	dgram	udp	wait	root	internal
#chargen	dgram	udp6	wait	root	internal
#daytime	dgram	udp	wait	root	internal
#daytime	dgram	udp6	wait	root	internal
#time		dgram	udp	wait	root	internal
#time		dgram	udp6	wait	root	internal
# Kerberos authenticated services
#kshell		stream	tcp	nowait	root	/usr/libexec/rshd	rshd -k
#ekshell	stream	tcp	nowait	root	/usr/libexec/rshd	rshd -Lk
#ekshell2	stream	tcp	nowait	root	/usr/libexec/rshd	rshd -Lk
#kauth		stream	tcp	nowait	root	/usr/libexec/kauthd	kauthd
# RPC based services
#rstatd/1-3	dgram	rpc/udp	wait	root	/usr/libexec/rpc.rstatd	rpc.rstatd
#rusersd/1-3	dgram	rpc/udp	wait	root	/usr/libexec/rpc.rusersd rpc.rusersd
#walld/1	dgram	rpc/udp	wait	root	/usr/libexec/rpc.rwalld	rpc.rwalld
#sprayd/1	dgram	rpc/udp	wait	root	/usr/libexec/rpc.sprayd	rpc.sprayd
#rquotad/1	dgram	rpc/udp	wait	root	/usr/libexec/rpc.rquotad rpc.rquotad
