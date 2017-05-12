#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 2;
use Test::LongString;

use_ok("CSS::Squish");

my $expected_result = <<'EOT';


/**
  * From 07-basic-extra-roots.css: @import "07-basic-extra-roots2.css";
  */

foobar

/** End of 07-basic-extra-roots2.css */


/**
  * From 07-basic-extra-roots.css: @import "07-basic-extra-roots3.css";
  */

foobaz

/** End of 07-basic-extra-roots3.css */


/**
  * From 07-basic-extra-roots.css: @import "07-basic-extra-roots4.css";
  */

fallback

/** End of 07-basic-extra-roots4.css */

blam

EOT

CSS::Squish->roots( 't/css2/', 't/css3/', 't/css/' );
my $result = CSS::Squish->concatenate('07-basic-extra-roots.css');

is_string($result, $expected_result, "Basic extra roots");

