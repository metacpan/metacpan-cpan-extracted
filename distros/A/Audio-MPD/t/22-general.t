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

plan tests => 7;
my $mpd = Audio::MPD->new;


#
# testing mpd version.
SKIP: {
    my $output = qx{echo | nc -w1 localhost 6600 2>/dev/null};
    skip 'need netcat installed', 1 unless $output =~ /^OK .* ([\d.]+)\n/;
    is( $mpd->version, $1, 'mpd version grabbed during connection' );
}


#
# testing kill.
$mpd->ping;
$mpd->kill;
sleep 1; # let mpd shut down the socket cleanly
eval { $mpd->ping };
like( $@, qr/^Could not create socket:/, 'kill shuts mpd down' );
start_test_mpd();


#
# testing password changing.
eval { $mpd->set_password('b0rken') };
like( $@, qr/\{password\} incorrect password/, 'changing password' );
eval { $mpd->set_password() }; # default to empty string.
is( $@, '', 'no password = empty password' );


#
# testing database updating.
# uh - what are we supposed to test? that there was no error?
eval { $mpd->updatedb };
is( $@, '', 'updating whole collection' );
sleep 1; # let the first update finish.
eval { $mpd->updatedb('dir1') };
is( $@, '', 'updating part of collection' );


#
# testing urlhandlers.
my @handlers = $mpd->urlhandlers;
ok( scalar @handlers >= 1, 'at least one url handler supported' );
