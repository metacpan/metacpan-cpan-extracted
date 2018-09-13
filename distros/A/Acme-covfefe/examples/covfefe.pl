#!/usr/bin/env perl

use strict;
use warnings;

use Acme::covfefe;

for(1..10) {
    print covfefe(), "\n";
}
