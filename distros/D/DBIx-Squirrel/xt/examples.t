use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use File::Spec qw();
use File::Temp qw(tempdir);

# Run the examples in docs/HOWTO.md and docs/REFERENCE.md, each document
# as one program, so they can't drift from the code, and check that each
# prints what its comments say. A document's examples share a database,
# set up by its first, and follow on from each other: the first runs as
# it is, and each after it in a block of its own, so their names don't
# clash. An example marked <!-- not run -->, such as a usage synopsis, or
# one needing a server or driver the tests don't have, is left out.
#
# What an example prints is in its comments:
#
# - a comment at the end of a line that prints, with say or print, is
#   what that line prints;
# - comment lines straight after a line that prints, with no comment of
#   its own, or after the end of a block that prints, are what it
#   prints, a line each.
#
# In either, ... stands for any text, such as a file's path or a line
# number.

my @DOCS = grep { -e } qw(docs/HOWTO.md docs/REFERENCE.md);
skip_all "the docs aren't here" unless @DOCS;

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


# Return what an example's comments say it prints, a line each.
sub expected ($code) {
    my(@lines, $after, $pending);
    for my $line (split m( \n )x, $code) {
        if ($line !~ m( \S )x) {
            ($after, $pending) = (0, 0);
        }
        elsif ($line =~ m( \A \s* \# \  ?(.*) \z )x) {
            push @lines, $1 if $after;
        }
        else {
            my $prints = $line =~ m( \b (?: say | print ) \b )x;
            my($said) = $line =~ m( ;? \s{2,} \# \  (.*) \z )x;
            if ($prints && defined $said) {
                push @lines, $said;
                $after = 0;
            }
            elsif ($prints) {
                ($after, $pending) = (1, 1);
            }
            else {
                # The end of a block that prints.
                $after = $pending && $line =~ m( \A \s* [\}\)] )x;
            }
        }
    }
    return @lines;
}


# Return true if a line printed is what a comment says, where ... stands
# for any text.
sub matches ($printed, $said) {
    my $pattern = join '.*', map { quotemeta } split m( \.\.\. )x, $said, -1;
    return $printed =~ m( \A $pattern \z )xs;
}

for my $doc (@DOCS) {
    subtest $doc => sub {
        my($first, @rest) = examples($doc);
        ok $first, 'it has examples' or return;

        # Each example's lines are numbered as they are in the document, so
        # an error names its line. Before each, a line marks where its
        # output starts.
        my $MARK    = "\x{1E}";
        my $program = join '',
            qq{print "$MARK$first->[0]\\n";\n#line $first->[0] "$doc"\n$first->[1]},
            map { qq(print "$MARK$_->[0]\\n";\n{\n#line $_->[0] "$doc"\n$_->[1]}\n) }
            @rest;

        # Run it in a directory of its own, where it makes its database, with
        # what it writes to STDERR kept apart.
        my $lib = File::Spec->rel2abs('lib');
        my $dir = tempdir(CLEANUP => 1);
        open my $out, '>', "$dir/examples.pl"
            or die "Can't write $dir/examples.pl: $!";
        print { $out } $program;
        close $out or die "Can't write $dir/examples.pl: $!";
        my $printed = qx(cd "$dir" && "$^X" "-I$lib" examples.pl 2>stderr);

        is $?, 0, sprintf 'the %d examples run', 1 + @rest;
        open my $err, '<', "$dir/stderr" or die "Can't read $dir/stderr: $!";
        is do { local $/; <$err> }, '', 'without warnings or errors';

        my %printed;
        for my $part (split m( $MARK )x, $printed) {
            my($line, @lines) = split m( \n )x, $part;
            $printed{$line} = [map { s( \s+ \z )()xr } @lines] if defined $line;
        }
        for my $example ($first, @rest) {
            my($line, $code) = @$example;
            my @said = expected($code);
            my @got  = @{ $printed{$line} // [] };
            my $ok
                = @got == @said && !grep { !matches($got[$_], $said[$_]) } 0 .. $#said;
            ok $ok, "the example at line $line prints what its comments say"
                or diag "printed:\n", map({ "    $_\n" } @got), "its comments say:\n",
                map { "    $_\n" } @said;
        }
    };
}

done_testing;
