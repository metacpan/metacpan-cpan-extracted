#!/usr/bin/env perl
use strict;
use warnings;
use Catalyst::ScriptRunner;
use Catalyst::Blinker;

Catalyst::Blinker->start;
Catalyst::ScriptRunner->run('MyApp', 'Server');

