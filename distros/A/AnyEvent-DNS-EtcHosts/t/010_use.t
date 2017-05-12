#!/usr/bin/perl

use strict;
use warnings;

use Carp 'verbose';

$SIG{__WARN__} = sub { local $Carp::CarpLevel = 1; Carp::confess("Warning: ", @_) };

use Test::More tests => 1;

BEGIN { use_ok 'AnyEvent::DNS::EtcHosts' };
