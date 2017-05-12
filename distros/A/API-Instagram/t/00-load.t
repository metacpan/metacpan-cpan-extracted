#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 7;

BEGIN { use_ok 'API::Instagram'; }
BEGIN { use_ok 'API::Instagram::Media'; }
BEGIN { use_ok 'API::Instagram::Media::Comment'; }
BEGIN { use_ok 'API::Instagram::User'; }
BEGIN { use_ok 'API::Instagram::Tag'; }
BEGIN { use_ok 'API::Instagram::Location'; }
BEGIN { use_ok 'API::Instagram::Search'; }