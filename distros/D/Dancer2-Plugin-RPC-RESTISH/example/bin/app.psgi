#! /usr/bin/env perl -w
use strict;

use FindBin;

use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../local/lib/perl5";
use lib "$FindBin::Bin/../../lib";

use Example;

Example->to_app();
