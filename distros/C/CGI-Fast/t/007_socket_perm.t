#!perl
use warnings;
use strict;
use Test::More;
use CGI::Fast;
use File::Temp;

my $OS;

unless ($OS = $^O) {
	require Config;
	$OS = $Config::Config{'osname'};
}

if ( $OS =~ /mswin|cygwin/i ) {
	plan skip_all => "valid on unix-y servers only";
}

{ no warnings 'redefine'; sub FCGI::Accept ($) {} }

my $fh = File::Temp->new;
my $f  = $fh->filename;
undef( $fh );

import CGI::Fast socket_path => $f;
ok( !-e $f, 'socket not exists' );
CGI::Fast->new();
ok( -e $f, 'socket was created' );
is( 0777 & (stat $f)[2], 0777 & ~umask, 'socket has default perms' );
unlink $f;
undef $CGI::Fast::Ext_Request;

import CGI::Fast socket_perm => 0777;
ok( !-e $f, 'socket not exists' );
CGI::Fast->new();
ok( -e $f, 'socket was created' );
is( 0777 & (stat $f)[2], 0777, 'socket has given perms' );
unlink $f;
undef $CGI::Fast::Ext_Request;

import CGI::Fast socket_perm => 0777;
ok( !-e $f, 'socket not exists' );
$ENV{FCGI_SOCKET_PERM} = 0666;
CGI::Fast->new();
ok( -e $f, 'socket was created' );
is( 0777 & (stat $f)[2], 0666, '$FCGI_SOCKET_PERM has higher priority' );
unlink $f;
undef $CGI::Fast::Ext_Request;

done_testing();
