#!/usr/bin/perl

use strict;
use warnings;

use Test;
BEGIN { plan tests => 1 }

use ExtUtils::testlib;
use Dancer::Plugin::Captcha::SecurityImage;
ok eval "require Dancer::Plugin::Captcha::SecurityImage";

1;
