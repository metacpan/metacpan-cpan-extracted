#!perl
#
# This file is part of Audio-MPD-Common
#
# This software is copyright (c) 2007 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

use strict;
use warnings;

use Audio::MPD::Common::Time;
use Test::More tests => 14;

#
# formatted output
my $time = Audio::MPD::Common::Time->new( time => '126:225' );
is( $time->sofar,   '2:06', 'sofar() formats time so far' );
is( $time->left,    '1:39', 'left() formats remaining time' );
is( $time->total,   '3:45', 'sofar() formats time so far' );
is( $time->percent, '56.0', 'percent() gives percentage elapsed' );


#
# so far
is( $time->sofar_secs,    6,   'sofar_secs() gives seconds so far' );
is( $time->sofar_mins,    2,   'sofar_mins() gives minutes so far' );
is( $time->seconds_sofar, 126, 'seconds_sofar() gives time so far in secs' );

#
# left details
is( $time->left_secs,    39, 'left_secs() gives seconds left' );
is( $time->left_mins,    1,  'left_mins() gives minutes left' );
is( $time->seconds_left, 99, 'seconds_left() gives time left in secs' );

#
# total details
is( $time->total_secs,    45,  'total_secs() gives seconds total' );
is( $time->total_mins,    3,   'total_mins() gives minutes total' );
is( $time->seconds_total, 225, 'seconds_total() gives time total in secs' );

#
# testing null time
$time = Audio::MPD::Common::Time->new( time => '126:0' );
is( $time->percent, '0.0', 'percent() defaults to 0' );
