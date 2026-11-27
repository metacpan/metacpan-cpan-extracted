use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use File::Find qw(find);

# Each document comes in two parts: Part 1 is DBIx::Squirrel, complete,
# and Part 2 is Ekorn::Pipeline, by choice (roadmap 2026-0052). This
# keeps the line between them (its D5): each of the README, the guide
# and the reference has a "Part 2: With Ekorn::Pipeline" heading, and a
# "Part 1: DBIx::Squirrel" heading before it, and nothing before the Part 2 heading names Ekorn, in
# code or in text, or DBIx::Squirrel::Tooling, or one of Ekorn's names,
# in code or as code in the text. So a reader learns Ekorn::Pipeline
# exists only after Part 1.
#
# Ekorn's names are those DBIx::Squirrel::Tooling exports that none of
# DBIx::Squirrel's own modules does, as it imports them from Ekorn's
# (its D2), worked out here, so a name Ekorn adds is caught with no
# change to this file. The attributes named ekorn_, such as ekorn_slice,
# are DBIx::Squirrel's own, as is the word "stage" or "pipeline" in
# the text: 1.x had both. A name with an underscore, such as
# count_items, is never a plain word, so it counts anywhere in the
# text; one that is a plain word counts there only as code of its own,
# alone or called, not as a word in a message quoted as code. Only
# Perl is code: a diagram in a fenced block of another kind is text. The
# Part 2 heading's own words, which Contents gives, are allowed.

my @DOCS = grep { -e } qw(README.pod docs/HOWTO.md docs/REFERENCE.md);

my $PART_1 = qr( \A (?: =head2 | \#\# ) \s+ Part\ 1:\ DBIx::Squirrel \s* \z )x;
my $PART_2
    = qr( \A (?: =head2 | \#\# ) \s+ Part\ 2:\ With\ Ekorn::Pipeline \s* \z )x;

# Return the names DBIx::Squirrel::Tooling exports from Ekorn's modules.
sub ekorn_names () {
    my @own;
    find(
        {
            no_chdir => 1,
            wanted   => sub {
                return unless m( \.pm \z )x;
                my $module = s( \A lib/ )()xr =~ s( \.pm \z )()xr =~ s( / )(::)xgr;
                push @own, $module unless $module eq 'DBIx::Squirrel::Tooling';
            },
        },
        'lib/DBIx/Squirrel',
    );
    my %ours  = map { $_ => 1 } map { exports($_) } @own;
    my @names = sort grep { !$ours{$_} } exports('DBIx::Squirrel::Tooling');
    return @names;
}

# Return the names a module exports, by default or on request.
sub exports ($module) {
    eval "require $module; 1" or die $@;    ## no critic (BuiltinFunctions::ProhibitStringyEval)
    no strict 'refs';                       ## no critic (TestingAndDebugging::ProhibitNoStrict)
    return @{ "${module}::EXPORT" }, @{ "${module}::EXPORT_OK" };
}

# Return a document's Part 1, as paragraphs, each the line it starts at,
# whether it's code, and its text; or nothing, if it has no Part 2.
sub part_one ($file) {
    open my $in, '<:encoding(UTF-8)', $file or die "Can't read $file: $!";
    my @lines = <$in>;
    close $in;
    chomp @lines;
    my $pod = $file =~ m( \.pod \z )x;
    my(@paragraphs, $fenced, $perl);
    for my $n (1 .. @lines) {
        my $line = $lines[$n - 1];
        return @paragraphs if $line =~ $PART_2;
        if (!$pod && $line =~ m( \A ``` (\w*) )x) {
            ($fenced, $perl) = (!$fenced, ($1 // '') =~ m( \A (?: perl )? \z )x);
            push @paragraphs, [$n + 1, $perl ? 1 : 0, ''] if $fenced;
            next;
        }
        if ($line !~ m( \S )x) {
            push @paragraphs, [$n + 1, 0, '']
                unless $fenced || (@paragraphs && $paragraphs[-1][2] eq '');
            next;
        }
        my $code = ($fenced && $perl) || ($pod && $line =~ m( \A \s )x) ? 1 : 0;
        push @paragraphs, [$n, $code, '']
            if !@paragraphs || $paragraphs[-1][1] != $code;
        $paragraphs[-1][2] .= "$line\n";
    }
    return;
}

# Return what a paragraph names of Ekorn's.
sub named ($code, $text, $names) {
    $text =~ s( Part\ 2:\ With\ Ekorn::Pipeline )()xg;    # the divider's name, as Contents gives it
    my @named;
    push @named, 'Ekorn' if $text =~ m( \b Ekorn \b )x;
    push @named, 'DBIx::Squirrel::Tooling'
        if $text =~ m( DBIx::Squirrel::Tooling )x;
    if ($code) {
        my @code = map { s( (?: \A | \s ) \# \s .* \z )()xr } split m( \n )x, $text;
        for my $name (@$names) {
            push @named, $name
                if grep { m( (?<! [\$\@\%\w>:-] ) \b \Q$name\E \b (?! \s* => ) )x } @code;
        }
        return @named;
    }

    # In the text, a name with an underscore, such as count_items, is never
    # a plain word, so it counts wherever it appears. One that is a plain
    # word, such as stage or keep, counts only as code of its own, alone or
    # called, as `keep(3)`, not as a word in a message quoted as code.
    my @spans = (
        $text =~ m( C <{2,} \s+ (.*?) \s+ >{2,} )xgs,
        $text =~ m( C < ([^<>]*) > )xg,
        $text =~ m( ` ([^`]+) ` )xg,
    );
    my %words = map { $_ => 1 } split m( [^\w:] )x, $text;
    for my $name (@$names) {
        if ($name =~ m( _ )x) {
            push @named, $name if $words{$name};
        }
        else {
            push @named, $name
                if grep { m( \A \s* \Q$name\E \b (?: \s* [\(\{] .* )? \s* \z )xs } @spans;
        }
    }
    return @named;
}

skip_all "the documents aren't here" unless @DOCS;

my @names = ekorn_names();
ok scalar @names, "Ekorn's names are known: @names";

for my $doc (@DOCS) {
    my @paragraphs = part_one($doc);
    subtest $doc => sub {
        ok scalar @paragraphs, 'it has a Part 2 heading' or return;
        ok + (grep { $_->[2] =~ $PART_1 } @paragraphs), 'Part 1 has its heading';
        my @found;
        for my $paragraph (@paragraphs) {
            my($line, $code, $text) = @$paragraph;
            push @found, map { "line $line: $_" } named($code, $text, \@names);
        }
        is \@found, [], "Part 1 names nothing of Ekorn's";
    };
}

done_testing;
