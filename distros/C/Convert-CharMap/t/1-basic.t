#!/usr/bin/perl
use strict;
use Test;
BEGIN { plan tests => 1 }
ok (eval { require Convert::CharMap; 1 });
