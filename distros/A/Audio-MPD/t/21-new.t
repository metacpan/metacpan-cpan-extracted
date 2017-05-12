#!perl
#
# This file is part of Audio-MPD
#
# This software is copyright (c) 2007 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

use strict;
use warnings;

use Audio::MPD;
use Test::More;

# are we able to test module?
eval 'use Test::Corpus::Audio::MPD';
plan skip_all => $@ if $@ =~ s/\n+Compilation failed.*//s;

plan tests => 16;
my $mpd;

#
# testing constructor defaults.
$mpd = Audio::MPD->new;
is( $mpd->host,     'localhost', 'host defaults to localhost' );
is( $mpd->port,     6600,        'port defaults to 6600' );
is( $mpd->password, '',          'password default to empty string' );
isa_ok( $mpd, 'Audio::MPD', 'object creation' );


#
# changing fake mpd config to test constructor.
my $port = 16600;
stop_test_mpd();
customize_test_mpd_configuration($port);
start_test_mpd();


#
# testing constructor params.
$mpd = Audio::MPD->new( host=>'127.0.0.1', port=>$port, password=>'foobar' );
is( $mpd->host,     '127.0.0.1', 'host set to param' );
is( $mpd->port,     $port,       'port set to param' );
is( $mpd->password, 'foobar',    'password set to param' );

#
# testing constructor environment defaults...
$ENV{MPD_HOST}     = '127.0.0.1';
$ENV{MPD_PORT}     = $port;
$ENV{MPD_PASSWORD} = 'foobar';
$mpd = Audio::MPD->new;
is( $mpd->host,     $ENV{MPD_HOST},     'host default to $ENV{MPD_HOST}' );
is( $mpd->port,     $ENV{MPD_PORT},     'port default to $ENV{MPD_PORT}' );
is( $mpd->password, $ENV{MPD_PASSWORD}, 'password default to $ENV{MPD_PASSWORD}' );

delete $ENV{MPD_HOST};
delete $ENV{MPD_PASSWORD};
$ENV{MPD_HOST} = 'foobar@127.0.0.1';
is( $mpd->host,     '127.0.0.1', 'host detected when $ENV{MPD_HOST} is passwd@host' );
is( $mpd->password, 'foobar',    'password detected when $ENV{MPD_HOST} is passwd@host' );

$ENV{MPD_HOST} = 'foobar@127.0.0.1:16600';
is( $mpd->host,     '127.0.0.1', 'host detected when $ENV{MPD_HOST} is passwd@host:port' );
is( $mpd->port,     16600,       'port detected when $ENV{MPD_HOST} is passwd@host:port' );
is( $mpd->password, 'foobar',    'password detected when $ENV{MPD_HOST} is passwd@host:port' );

$mpd = Audio::MPD->new;

delete $ENV{MPD_HOST};
delete $ENV{MPD_PORT};


#
# testing connection type
$mpd = Audio::MPD->new( port=>16600, conntype=>'reuse' );
$mpd->ping;
$mpd->ping;
$mpd->ping;
isa_ok( $mpd->_socket, 'IO::Socket', 'socket is created and retained' );
