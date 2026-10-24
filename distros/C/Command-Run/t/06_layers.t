use strict;
use warnings;
use utf8;
use Test::More;

use Command::Run;

# Encoding layers pushed on STDIN/STDOUT during nofork execution must
# not accumulate across executions.
# cf. https://github.com/kaz-utashiro/perl-perlio-leak-bench

sub layers { scalar(() = PerlIO::get_layers(shift)) }

my %handle = (STDOUT => \*STDOUT, STDIN => \*STDIN);

for my $raw (0, 1) {
    my %before = map { $_ => layers($handle{$_}) } keys %handle;
    my $data;
    for (1 .. 10) {
        my $result = Command::Run->new(
            command => [sub { print "j: ", scalar <STDIN> }],
            stdin   => "\x{3042}\n",
            nofork  => 1,
            raw     => $raw,
        )->run;
        $data = $result->{data};
    }
    is $data, "j: \x{3042}\n", "nofork raw=$raw: data correct after repeated runs";
    for my $h (sort keys %handle) {
        is layers($handle{$h}), $before{$h},
            "nofork raw=$raw: $h layer count unchanged";
    }
}

# The caller's own layers must come back exactly as they were -- as a
# list, not merely the same count.  This is the case that would break
# if perl ever made binmode ':encoding' idempotent (perl/perl5#10454),
# or made re-opening over a dup reset the layer stack: an
# unconditional ':pop' would then take away a layer the caller set, or
# the restore would drop it.  See perl/perl5 and perl-perlio-leak-bench.
for my $raw (0, 1) {
    binmode STDOUT, ':encoding(utf8)';
    binmode STDIN,  ':encoding(utf8)';
    my %before = map { $_ => [ PerlIO::get_layers($handle{$_}) ] } keys %handle;
    for (1 .. 3) {
        Command::Run->new(
            command => [sub { print "k: ", scalar <STDIN> }],
            stdin   => "\x{3042}\n",
            nofork  => 1,
            raw     => $raw,
        )->run;
    }
    for my $h (sort keys %handle) {
        is_deeply [ PerlIO::get_layers($handle{$h}) ], $before{$h},
            "nofork raw=$raw: $h keeps the caller's layer list";
    }
    binmode STDOUT, ':pop';
    binmode STDIN,  ':pop';
}

# When STDOUT is a character device (a terminal, /dev/null), re-opening
# it over a dup gives it a fresh output-side PerlIO with no layers, so
# the caller's :encoding would be silently dropped from the side that
# print() uses -- while PerlIO::get_layers(STDOUT) (the input side)
# still reports it.  The restore must leave the output side intact.
# cf. perl-perlio-leak-bench, "Where the output side actually goes"
SKIP: {
    skip "/dev/null is not a character device here", 6 unless -c '/dev/null';
    open my $orig_stdout, '>&', \*STDOUT or die "dup STDOUT: $!";
    open my $orig_stderr, '>&', \*STDERR or die "dup STDERR: $!";
    open STDOUT, '>', '/dev/null' or die "open /dev/null: $!";
    open STDERR, '>', '/dev/null' or die "open /dev/null: $!";
    binmode STDOUT, ':encoding(utf8)';
    binmode STDERR, ':encoding(utf8)';
    my @out_before = PerlIO::get_layers(\*STDOUT, output => 1);
    my @err_before = PerlIO::get_layers(\*STDERR, output => 1);
    for my $raw (0, 1) {
        Command::Run->new(
            command => [sub { print "m: ", scalar <STDIN>; warn "w\n" }],
            stdin   => "\x{3042}\n",
            nofork  => 1,
            raw     => $raw,
            stderr  => 'capture',
        )->run;
        is_deeply [ PerlIO::get_layers(\*STDOUT, output => 1) ], \@out_before,
            "nofork raw=$raw: STDOUT output side keeps its layers on a character device";
        is_deeply [ PerlIO::get_layers(\*STDERR, output => 1) ], \@err_before,
            "nofork raw=$raw: STDERR output side keeps its layers on a character device";
        my $warned = '';
        {
            local $SIG{__WARN__} = sub { $warned .= $_[0] };
            print STDOUT "\x{3042}\n";
        }
        unlike $warned, qr/Wide character/,
            "nofork raw=$raw: printing a wide character afterwards does not warn";
    }
    binmode STDOUT, ':pop';
    binmode STDERR, ':pop';
    open STDOUT, '>&', $orig_stdout or die "restore STDOUT: $!";
    open STDERR, '>&', $orig_stderr or die "restore STDERR: $!";
}

done_testing;
