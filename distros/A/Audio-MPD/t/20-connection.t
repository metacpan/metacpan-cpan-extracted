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

plan tests => 20;

my $mpd = Audio::MPD->new;
isa_ok($mpd, 'Audio::MPD');


#
# testing error during socket creation.
eval { Audio::MPD->new(port=>16600) };
like($@, qr/^Could not create socket/, 'error during socket creation');


#
# testing connection to a non-mpd server - here, we'll try to connect
# to a sendmail server.
my $sendmail_running = grep { /:25\s.*LISTEN/ } qx[ netstat -an ];
SKIP: {
    skip 'need some sendmail server running', 1 unless $sendmail_running;
    eval { Audio::MPD->new(port=>25) };
    like($@, qr/^Not a mpd server - welcome string was:/, 'wrong server');
};


#
# testing ipv6 connection
my $mpd6 = Audio::MPD->new( host => "::1" );
isa_ok($mpd6, 'Audio::MPD');


#
# testing password sending.
eval { $mpd->set_password( 'wrong-password' ) };
like($@, qr/\{password\} incorrect password/, 'wrong password');

eval { $mpd->set_password('fulladmin') };
is($@, '', 'correct password sent');
$mpd->set_password('');


#
# testing command.
eval { $mpd->_send_command( "bad command\n" ); };
like($@, qr/unknown command "bad"/, 'unknown command');

my @output = $mpd->_send_command( "status\n" );
isnt(scalar @output, 0, 'commands return stuff');


#
# testing _cooked_command_as_items
my @items = $mpd->_cooked_command_as_items( "lsinfo\n" );
isa_ok( $_, 'Audio::MPD::Common::Item', '_cooked_command_as_items return items' ) for @items;


#
# testing _cooked_command_strip_first_field
my @list = $mpd->_cooked_command_strip_first_field( "stats\n" );
unlike( $_, qr/\D/, '_cooked_command_strip_first_field return only 2nd field' ) for @list;
# stats return numerical data as second field.

