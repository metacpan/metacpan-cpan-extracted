#!/usr/bin/perl

use strict;
use warnings;

exec qw(perl -Mlib::glob=/home/salva/g/perl/p5-*/lib
        /home/salva/g/perl/p5-AnyEvent-PacketForwarder/examples/N-slave.pl
        /usr/lib/openssh/sftp-server);
