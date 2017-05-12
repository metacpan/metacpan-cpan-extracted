package Mail::IMAP::Util;
use strict;
use warnings;
use utf8;

use parent qw/Exporter/;

our @EXPORT = qw(imap_string_quote imap_parse_tokens);

sub imap_string_quote {
    local $_ = shift;
    s/\\/\\\\/g;
    s/\"/\\\"/g;
    "\"$_\"";
}

##### parse imap response #####
#
# This is probably the simplest/dumbest way to parse the IMAP output.
# Nevertheless it seems to be very stable and fast.
#
# $input is an array ref containing IMAP output.  Normally it will
# contain only one entry -- a line of text -- but when IMAP sends
# literal data, we read it separately (see _read_literal) and store it
# as a scalar reference, therefore it can be like this:
#
#    [ '* 11 FETCH (RFC822.TEXT ', \$DATA, ')' ]
#
# so that's why the routine looks a bit more complicated.
#
# It returns an array of tokens.  Literal strings are dereferenced so
# for the above text, the output will be:
#
#    [ '*', '11', 'FETCH', [ 'RFC822.TEXT', $DATA ] ]
#
# note that lists are represented as arrays.
#
sub imap_parse_tokens {
    my ($input, $no_deref) = @_;

    my @tokens = ();
    my @stack = (\@tokens);

    while (my $text = shift @$input) {
        if (ref $text) {
            push @{$stack[-1]}, ($no_deref ? $text : $$text);
            next;
        }
        while (1) {
            $text =~ m/\G\s+/gc;
            if ($text =~ m/\G[([]/gc) {
                my $sub = [];
                push @{$stack[-1]}, $sub;
                push @stack, $sub;
            } elsif ($text =~ m/\G(BODY\[[a-zA-Z0-9._() -]*\])/gc) {
                push @{$stack[-1]}, $1; # let's consider this an atom too
            } elsif ($text =~ m/\G[])]/gc) {
                pop @stack;
            } elsif ($text =~ m/\G\"((?:\\.|[^\"\\])*)\"/gc) {
                my $str = $1;
                # unescape
                $str =~ s/\\\"/\"/g;
                $str =~ s/\\\\/\\/g;
                push @{$stack[-1]}, $str; # found string
            } elsif ($text =~ m/\G(\d+)/gc) {
                push @{$stack[-1]}, $1 + 0; # found numeric
            } elsif ($text =~ m/\G([a-zA-Z0-9_\$\\.+\/*&-]+)/gc) {
                my $atom = $1;
                if (lc $atom eq 'nil') {
                    $atom = undef;
                }
                push @{$stack[-1]}, $atom; # found atom
            } else {
                last;
            }
        }
    }

    return \@tokens;
}

1;

