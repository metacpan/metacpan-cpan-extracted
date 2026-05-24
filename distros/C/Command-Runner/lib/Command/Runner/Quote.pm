package Command::Runner::Quote;
use v5.24;
use warnings;
use experimental qw(lexical_subs signatures);

use Win32::ShellQuote ();
use String::ShellQuote ();

use Exporter 'import';
our @EXPORT_OK = qw(quote quote_win32 quote_unix);

sub quote_win32 ($str) {
    Win32::ShellQuote::quote_literal($str, 1);
}

sub quote_unix ($str) {
    String::ShellQuote::shell_quote_best_effort($str);
}

if ($^O eq 'MSWin32') {
    *quote = \&quote_win32;
} else {
    *quote = \&quote_unix;
}

1;
