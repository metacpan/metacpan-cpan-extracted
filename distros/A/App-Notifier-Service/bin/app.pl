#!/usr/bin/env perl

use strict;
use warnings;


use Dancer;
use App::Notifier::Service;

{
    # Exit gracefully on Ctrl+C - Konsole warns about it.
    local $SIG{INT} = sub {
        exit(0);
    };
    local $SIG{CHLD} = 'IGNORE';
    dance;
}
