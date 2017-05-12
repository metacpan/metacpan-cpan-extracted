#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok 'Dancer::Plugin::Locale::Detect';
    use_ok 'Dancer::Plugin::Locale::TextDomain';
}

require_ok 'Dancer::Plugin::Locale::Detect';
require_ok 'Dancer::Plugin::Locale::TextDomain';

done_testing 4;
