package CPAN::Mirror::Tiny::Util;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(WIN32 safe_system);

use constant WIN32 => $^O eq 'MSWin32';

use Capture::Tiny ();

if (WIN32) {
    require Win32::ShellQuote;
    *shell_quote = \&Win32::ShellQuote::quote_native;
} else {
    require String::ShellQuote;
    *shell_quote = \&String::ShellQuote::shell_quote_best_effort;
}

sub safe_system {
    my @arg = @_;
    my $sub;
    if (!WIN32 && @arg == 1 && ref $arg[0]) {
        $sub = sub { system { $arg[0][0] } @{$arg[0]} };
    } else {
        my $cmd = join ' ', map { ref $_ ? shell_quote(@$_) : $_ } @arg;
        $sub = sub { system $cmd };
    }
    &Capture::Tiny::capture($sub);
}

1;
