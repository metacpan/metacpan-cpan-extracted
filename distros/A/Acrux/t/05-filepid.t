#!/usr/bin/perl -w
#########################################################################
#
# Serż Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2024 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#########################################################################
use strict;
use Test::More;

use_ok qw/Acrux::FilePid/;

# Regular mode
{
    my $fp = Acrux::FilePid->new(file => "test05.pid");
    is $fp->pid, $$, "$$ current process by default";
    ok $fp->save, "$$ writing file";
    is $fp->running, $$, "$$ we are running";
    ok $fp->remove, "$$ deleted file";
    #note explain $fp;
}

# Autoremove mode
{
    my $fp = Acrux::FilePid->new(file => "test05.tmp", autoremove => 1);
    ok $fp->save, "$$ writing file";
    is $fp->running, $$, "$$ we are running";
}

# Autosave and Autoremove mode
{
    my $fp = Acrux::FilePid->new(file => "test05.tmp", auto => 1);
    is $fp->running, $$, "$$ we are running";
}

# Fork mode
my $file = 'child05.tmp';
unlink $file if -e $file;
if (my $child = fork) { # Parent PID
    sleep 1;
    my $p = Acrux::FilePid->new(file => $file, autoremove => 1);
    note sprintf "Parent PID: %s; Parent Owner: %s", $p->pid, $p->owner;
    $p->save unless $p->running;
    ok $p->running, 'child process is running';
    #note explain $p;
    waitpid $child, 0;
    done_testing;
} else { # child process
    my $p = Acrux::FilePid->new(file => $file, autoremove => 1); # hope for the best
    unless ($p->running) {
       $p->save;
       note sprintf "Start child process (Child PID: %s; Child Owner: %s)", $p->pid, $p->owner;
       sleep 3;
       note sprintf "Finish child process (Child PID: %s; Child Owner: %s)", $p->pid, $p->owner;
    }
    #note 'parent is running' if $p->running;
}

__END__

prove -lv t/05-filepid.t
