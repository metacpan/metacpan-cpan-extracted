#
# This file is part of App-Milter-Limit-Plugin-SQLite
#
# This software is copyright (c) 2010 by Michael Schout.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

package My::Test::Util;

# ABSTRACT: Internal Test Utility Functions

use strict;
use warnings;
use base 'Test::Builder::Module';

use Time::HiRes qw(usleep);
use Fatal qw(open);
use Text::Template qw(fill_in_string);

my $Test = __PACKAGE__->builder;

sub start_milter {
    my ($self, $milter, $socket_path) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $pid = fork();

    unless (defined $pid) {
        die "unable to fork(): $!\n";
    }
    if ($pid == 0) {
        $milter->register;
        $milter->main;
        exit;
    }

    $Test->note("Milter process started at pid $pid");

    # wait for the milter socket to appear
    for (my $tries = 0; $tries < 50; $tries++) {
        if (-e $socket_path) {
            $Test->ok("Milter socket is ready at $socket_path");
            return $pid;
        }

        # wait a short time
        usleep 100_000;
    }

    die "The socket at $socket_path never appeared\n";
}

sub stop_milter {
    my ($self, $pid) = @_;

    unless ($pid) {
        return;
    }

    $Test->note("Stopping milter process at $pid");
    kill TERM => $pid;

    waitpid $pid, 0;

    return;
}

sub generate_config {
    my ($self, $tmpl, $outfile, $hash) = @_;

    my $config = fill_in_string($$tmpl, HASH => $hash);

    open my $fh, '>', $outfile;

    print $fh $config;

    close $fh;
}

1;
