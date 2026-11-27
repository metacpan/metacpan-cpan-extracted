use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use File::Spec qw();
use File::Temp qw(tempdir);

# Run the examples in docs/HOWTO.md and docs/REFERENCE.md, each document
# as one program, so they can't drift from the code, and check that each
# prints what its comments say; those in README.pod are compiled, as the
# end of this file says. A document's examples share a database, set up by its
# first, and follow on from each other: the first runs as it is, and
# each after it in a block of its own, so their names don't clash. An
# example marked <!-- not run -->, such as a usage synopsis, or one
# needing a server or driver the tests don't have, is left out.
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

# Return the code examples in a POD file, each as the line it starts at
# and its code: its indented paragraphs, those between blank lines joined
# with them, unless =for not-run comes before.
sub pod_examples ($file) {
    open my $in, '<', $file or die "Can't read $file: $!";
    my @lines = <$in>;
    close $in;
    my(@examples, $code, $start, $blanks, $skip);
    for my $n (1 .. @lines) {
        my $line = $lines[$n - 1];
        if ($line =~ m( \A [\ \t]+ \S )x) {
            ($code, $start, $blanks) = ('', $n, 0) unless defined $code;
            $code   .= ("\n" x $blanks) . $line;
            $blanks  = 0;
        }
        elsif ($line !~ m( \S )x) {
            $blanks++ if defined $code;
        }
        else {
            push @examples, [$start, $code] if defined $code && !$skip;
            $skip = 0 if defined $code;
            undef $code;
            $skip = 1 if $line =~ m( \A =for \s+ not-run \s* \z )x;
        }
    }
    push @examples, [$start, $code] if defined $code && !$skip;
    return @examples;
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

# The README's examples use stand-ins, such as $dbh and %on_my_phone, and
# follow on from each other, so each is compiled, not run, with every
# name DBIx::Squirrel::Tooling exports, as Ekorn-Pipeline compiles its
# README's (roadmap 2026-0049). One that isn't Perl is marked
# =for not-run.
for my $README (grep { -e } qw(README.pod)) {
    subtest $README => sub {
        my @examples = pod_examples($README);
        ok @examples, 'it has examples' or return;
        my $lib = File::Spec->rel2abs('lib');
        my $dir = tempdir(CLEANUP => 1);
        for my $example (@examples) {
            my($line, $code) = @$example;
            open my $out, '>', "$dir/example.pl"
                or die "Can't write $dir/example.pl: $!";
            print { $out } "use v5.36;\nuse DBIx::Squirrel;\n",
                "use DBIx::Squirrel::Tooling qw(:all);\n",
                "use Ekorn::Pipeline::Operators;\n",
                "no strict qw(vars subs);\nno warnings;\n",
                "sub {\n#line $line \"$README\"\n$code};\n";
            close $out or die "Can't write $dir/example.pl: $!";
            my $said = qx(cd "$dir" && "$^X" "-I$lib" -c example.pl 2>&1);
            is [$?, $said =~ s( ^ example\.pl\ syntax\ OK \n )()xmr], [0, ''],
                "the example at line $line compiles";
        }
    };
}

# In the documents, each example imports what it calls, so it works
# when copied (2026-0054 and 2026-0055, What
# happened). Running the examples can't show that, as an import in one
# reaches every one after it, nor compiling them, where a bareword is
# a string. So each example's calls of the functions DBIx::Squirrel's
# modules export, Ekorn's through Tooling among them, are checked
# against what its own use lines import.

# Return the names DBIx::Squirrel's and Ekorn's modules export, as they
# may be called in an example.
sub exported_names () {
    require DBIx::Squirrel::Tooling;
    require DBIx::Squirrel::Errors;
    no warnings 'once';
    return (
        @DBIx::Squirrel::Tooling::EXPORT_OK,
        @DBIx::Squirrel::Errors::EXPORT_OK,
    );
}

# Return the names a use line imports from a module, given its list.
sub imported ($module, $list) {
    return unless eval "require $module; 1";    ## no critic (BuiltinFunctions::ProhibitStringyEval)
    no strict 'refs';                           ## no critic (TestingAndDebugging::ProhibitNoStrict)
    my @default = @{ "${module}::EXPORT" };
    return @default unless defined $list;
    my %tags = %{ "${module}::EXPORT_TAGS" };
    return map {
              $_ eq ':DEFAULT' ? @default
            : m( \A : (\w+) )x ? @{ $tags{$1} // [] }
            : $_
    } split ' ', $list;
}

# Return what an example calls that it doesn't import.
sub not_imported ($code, $names) {
    my %have;
    while ($code
        =~ m{ ^ \s* use \s+ ([\w:]+) (?: \s+ qw\( ([^)]*) \) | \s* \(\) )? }xmg)
    {
        my($module, $list) = ($1, $2);
        $list = '' if !defined $list && $& =~ m{ \(\) \z }x;
        $have{$_} = 1 for imported($module, $list);
    }
    my $calls = join "\n", map { s( (?: \A | \s ) \# \s .* \z )()xr }
        grep { !m{ \A \s* use \s+ [\w:]+ \s+ qw\( }x } split m( \n )x, $code;
    $calls =~ s( ' (?: [^'\\] | \\. )* ' | " (?: [^"\\] | \\. )* " )('')xg;    # strings
    return grep {
        !$have{$_} && $calls =~ m( (?<! [\$\@\%\w>:-] ) \b \Q$_\E \b (?! \s* => ) )x
    } @$names;
}

my @IMPORTING = grep { -e } qw(docs/HOWTO.md docs/REFERENCE.md README.pod);
if (@IMPORTING) {
    my @names = exported_names();
    for my $doc (@IMPORTING) {
        subtest "$doc: each example imports what it calls" => sub {
            my @found;
            for
                my $example ($doc =~ m( \.pod \z )x ? pod_examples($doc) : examples($doc))
            {
                my($line, $code) = @$example;
                my @missing = not_imported($code, \@names);
                push @found, "line $line: @missing" if @missing;
            }
            is \@found, [], 'none calls a function it leaves unimported';
        };
    }
}

done_testing;
