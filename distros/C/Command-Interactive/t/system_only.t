#!/usr/bin/perl -I../../../lib
use strict;
use warnings;

use lib 'lib';
use Test::More tests => 3;
use Test::NoWarnings;
use Test::Exception;
use Command::Interactive;
use POSIX qw(locale_h);
use locale;

setlocale(LC_ALL, 'en');


my $command = Command::Interactive->new;

is($command->run("echo yes"), undef, "Run command successfully");
like($command->run("asdfasdf"), qr/Could not execute asdfasdf/, "Bogus command");

1;
