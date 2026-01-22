#!/usr/bin/perl -w
#########################################################################
#
# Serż Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2026 D&D Corporation
#
# This program is distributed under the terms of the Artistic License 2.0
#
#########################################################################
use strict;
use utf8;
use Test::More;

use_ok qw/Acme::Ghost::Log/;

# Error message with debug loglevel
{
    my $log = Acme::Ghost::Log->new();
    is $log->level, 'debug', "Debug LogLevel";
    ok $log->error("My test error message"), 'Error message';
}

# Info and fatal message with eror loglevel
{
    my $log = Acme::Ghost::Log->new(level => 'error');
    is $log->level, 'error', "Error LogLevel";
    ok !$log->info("My test info message"), 'Info message not allowed';
    ok $log->fatal("My test fatal message"), 'Fatal message';
    #note explain $log;
}

# Fake Logger
{
    my $fake = FakeLogger->new;
    my $log = Acme::Ghost::Log->new(logger => $fake);
    $log->error("Test error message") and ok 1, "Test error message to STDOUT";
    #ok $log->debug("Test debug message");
    $log->info("Test info message") and ok 1, "Test info message to STDOUT";
    #note explain $log;
}

# File
{
    my $log = Acme::Ghost::Log->new(file => 'log.tmp');
    $log->error("Test error message") and ok 1, "Test error message to file";
    $log->warn("Тестовое сообщение") and ok 1, "Test error message to file (RU)";
    $log->info("Test info message") and ok 1, "Test info message to file";
}

done_testing;

1;

package FakeLogger;

sub new { bless {}, shift }
sub info { printf "# Info[$$] %s\n", pop @_ }
sub error { printf "# Error[$$] %s\n", pop @_ }

1;

__END__

prove -lv t/04-log.t
