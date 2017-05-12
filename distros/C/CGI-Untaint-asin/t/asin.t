#!/usr/bin/perl -w

use strict;

use Test::More tests => 4;
use Test::CGI::Untaint;

is_extractable("6302508754", "6302508754", "asin");
is_extractable("078322608X", "078322608X", "asin");
is_extractable("B000AQ68RI", "B000AQ68RI", "asin");
unextractable("0B8322608X", "asin");
