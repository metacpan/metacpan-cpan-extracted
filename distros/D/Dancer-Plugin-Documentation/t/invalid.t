#!/usr/bin/env perl

use strict;
use warnings;

use FindBin ();
use lib "$FindBin::Bin/lib";

use Test::Most tests => 1;

eval "use BadApp";
like $@, qr{^Invalid argument where Dancer::Route expected\b}, 'Keyword "document_route" does not work with keyowrd "any"';
