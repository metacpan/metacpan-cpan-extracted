use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use File::Spec qw();
use File::Temp qw(tempdir);

# Run the examples in docs/HOWTO.md, as one program, so they can't drift
# from the code. They share a database, set up by the first, and follow
# on from each other: the first runs as it is, and each after it in a
# block of its own, so their names don't clash. An example marked
# <!-- not run -->, needing a server or driver the tests don't have, is
# left out.

my $HOWTO = 'docs/HOWTO.md';
skip_all "$HOWTO isn't here" unless -e $HOWTO;

# Return the Perl examples in a Markdown file, each as the line it starts
# at and its code.
sub examples ($file) {
    open my $in, '<', $file or die "Can't read $file: $!";
    my @lines = <$in>;
    close $in;
    my(@examples, $code, $start, $skip);
    for my $n (1 .. @lines) {
        my $line = $lines[$n - 1];
        if (defined $code && $line =~ m( \A ``` \s* \z )x) {
            push @examples, [$start, $code] unless $skip;
            ($code, $skip) = (undef, 0);
        }
        elsif (defined $code) {
            $code .= $line;
        }
        elsif ($line =~ m( \A ```perl \s* \z )x) {
            ($code, $start) = ('', $n + 1);
        }
        else {
            # The marker counts for the next example, if nothing else
            # comes between them.
            $skip = $line =~ m( \A <!--\ not\ run\ --> )x
                if $line =~ m( \S )x;
        }
    }
    return @examples;
}

my($first, @rest) = examples($HOWTO);
ok $first, 'the how-to has examples' or done_testing, exit;

# Each example's lines are numbered as they are in the how-to, so an
# error names the how-to's line.
my $program = join '',
    qq{#line $first->[0] "$HOWTO"\n$first->[1]},
    map { qq({\n#line $_->[0] "$HOWTO"\n$_->[1]}\n) } @rest;

# Run it in a directory of its own, where it makes its database, with
# what it writes to STDERR kept apart.
my $lib = File::Spec->rel2abs('lib');
my $dir = tempdir(CLEANUP => 1);
open my $out, '>', "$dir/howto.pl" or die "Can't write $dir/howto.pl: $!";
print { $out } $program;
close $out or die "Can't write $dir/howto.pl: $!";
my $printed = qx(cd "$dir" && "$^X" "-I$lib" howto.pl 2>stderr);

is $?, 0, sprintf 'the %d examples run', 1 + @rest;
open my $err, '<', "$dir/stderr" or die "Can't read $dir/stderr: $!";
is do { local $/; <$err> }, '', 'without warnings or errors';
ok length $printed, 'and print what they show';

done_testing;
