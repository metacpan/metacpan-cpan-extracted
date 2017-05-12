#!/usr/bin/perl -w

BEGIN { $ENV{CATALYST_ENGINE} ||= 'FastCGI' }

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use MyApp;

MyApp->run;

1;
