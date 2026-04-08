package Chandra::Test::Display;

use strict;
use warnings;
use Test::More;

sub skip_unless_display {
    my ($class, %opts) = @_;

    my $env_var = $opts{env_skip} || 'CHANDRA_SKIP_WINDOW';
    my $module  = $opts{module}   || 'Chandra::Window';
    my $label   = $opts{label}    || 'display';

    if ($ENV{$env_var}) {
        plan skip_all => "$env_var set";
    }

    if ($^O ne 'darwin' && $^O ne 'MSWin32'
        && !$ENV{DISPLAY} && !$ENV{WAYLAND_DISPLAY}) {
        plan skip_all => 'No display server available';
    }

    # GTK g_error() aborts the process — eval can't catch it.
    # Fork a child to probe display connectivity safely.
    # Always probe with Chandra::Window — some modules (e.g. Splash)
    # defer GTK init until show(), so probing with $module->new is
    # not reliable.
    my $pid = fork;
    if (!defined $pid) {
        plan skip_all => "fork failed: $!";
    } elsif ($pid == 0) {
        close STDOUT; close STDERR;
        require Chandra::Window;
        my $obj = eval { Chandra::Window->new };
        if ($obj && $obj->can('close')) { $obj->close }
        exit($obj ? 0 : 1);
    }
    waitpid($pid, 0);
    if ($?) {
        plan skip_all => "$label not supported (display unavailable)";
    }
}

sub skip_unless_clipboard {
    my ($class, %opts) = @_;

    my $env_var = $opts{env_skip} || 'CHANDRA_SKIP_CLIPBOARD';

    if ($ENV{$env_var}) {
        plan skip_all => "$env_var set";
    }

    require Chandra::Clipboard;
    Chandra::Clipboard->set_text('__probe__');
    my $got = Chandra::Clipboard->get_text;
    unless (defined $got && $got eq '__probe__') {
        plan skip_all => 'clipboard not available (no display?)';
    }
    Chandra::Clipboard->clear;
}

1;
