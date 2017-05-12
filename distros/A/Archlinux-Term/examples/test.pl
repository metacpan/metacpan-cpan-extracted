#!/usr/bin/perl

use warnings;
use strict;

use Archlinux::Term;

status 'Starting to test messages';
substatus 'Engaging our test any day now...';
msg 'Okay looks good';

warning q{Wait, we're going too fast!};
error 'Oh boy an error happened!';
