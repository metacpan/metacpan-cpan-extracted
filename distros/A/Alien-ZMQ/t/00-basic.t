#!perl

use warnings FATAL => 'all';
use strict;

use Test::More tests => 11;

BEGIN {
    use_ok 'Alien::ZMQ';
}

ok Alien::ZMQ::inc_version, "include version number";
ok Alien::ZMQ::lib_version, "library version number";
ok Alien::ZMQ::inc_dir,     "include directory path";
ok Alien::ZMQ::inc_dir,     "library directory path";

ok grep(/-I\S+/, Alien::ZMQ::cflags), "cflags array has -I";
ok grep(/-L\S+/, Alien::ZMQ::libs),   "libs array has -L";
ok grep(/-lzmq/, Alien::ZMQ::libs),   "libs array has -lzmq";

like Alien::ZMQ::cflags, qr/-I\S+/, "cflags string has -I";
like Alien::ZMQ::libs,   qr/-L\S+/, "libs string has -L";
like Alien::ZMQ::libs,   qr/-lzmq/, "libs string has -lzmq";
