package DBIx::DataStore::Debug;
$DBIx::DataStore::Debug::VERSION = '0.097';
use strict;
use warnings;

sub import {
    my ($pkg, $debug_level) = @_;

    $debug_level = 0 unless defined $debug_level && $debug_level =~ /^\d+$/o && $debug_level > 0;

    unless (eval "defined DBIx::DataStore::DEBUG();") {
        eval("sub DEBUG () { return $debug_level; }"); # give ourselves an easy-to-reference local copy
        eval("sub DBIx::DataStore::DEBUG () { return $debug_level; }");
        eval("sub DBIx::DataStore::dslog { DBIx::DataStore::Debug::_logger(\@_) }");
    }

    _logger(q{Debug mode enabled at level}, $debug_level) if $debug_level > 0;
}

sub _logger {
    my @args = scalar(@_) > 0 ? @_ : ();

    my @c = caller(1);

    my $out = sprintf("[%s] %s,%d", scalar(localtime()), $c[1], $c[2]);

    # at debugging level 5 and higher we dump the full stack (and abandon single-line output)
    if (DEBUG() >= 5) {
        $out .= "\n";
        my $i = 0;
        my (@stack);
        while (@c = caller($i)) {
            push(@stack, [@c]);
            $i++;
        }
        if (scalar(@stack) > 0) {
            # drop in some column headings, just so output is unambiguous (at the end, since we reverse the stack
            # prior to printing it out)
            push(@stack, [qw( Package Filename Line Subroutine Hasargs Wantarray Evaltext Isrequire Hints Bitmask )]);
            # get column widths
            my @w = (0) x scalar(@{$stack[0]});
            for ($i = 0; $i < scalar(@w); $i++) {
                for (my $j = 0; $j < scalar(@stack); $j++) {
                    my $l = defined $stack[$j]->[$i] ? length($stack[$j]->[$i]) : 0;
                    $w[$i] = $l if $l > $w[$i];
                }
            }

            $out .= " ** STACK TRACE\n";

            foreach (reverse @stack) {
                @c = @{$_};
                $out .= sprintf("  + %-$w[0]s  %-$w[1]s  %$w[2]s  %-$w[3]s\n", @c[0..3]);
            }

            $out .= " ** MESSAGE\n";
        }
    } else {
        $out .= ": ";
    }

    $out .= scalar(@args) > 0 ? qq{@args\n} : qq{ -- NO MESSAGE -- \n};

    $out .= " ** END\n" if DEBUG() >= 5;

    print STDERR $out;

    return;
}

1;
