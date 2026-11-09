use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use Pod::Checker qw();

# The POD manuals scripts/manuals makes from the Markdown in docs/
# (roadmap 2026-0001): how it converts each construct the docs use, that
# the committed manuals are what the Markdown makes now, and that they're
# sound POD, every link resolving.

my $SCRIPT = 'scripts/manuals';
skip_all "$SCRIPT isn't here" unless -e $SCRIPT;
require "./$SCRIPT";    ## no critic (Modules::RequireBarewordIncludes) a script, not a module

my %sections = (
    'REFERENCE.md' =>
        {'the-pipeline' => 'The pipeline', 'pipe-and-tap' => 'pipe and tap'},
    'HOWTO.md' => {'stop-early' => 'Stop early'},
);

# The POD made from Markdown in the reference, without what's put around
# it: NAME, DESCRIPTION and the footer.
sub body ($markdown) {
    my $pod
        = Manuals::convert("# A title\n\n$markdown", \%sections, 'REFERENCE.md');
    $pod =~ s( \A .*? =head1\ DESCRIPTION\n\n )()xs;
    $pod =~ s( =head1\ SEE\ ALSO .* \z )()xs;
    return $pod;
}

subtest 'what goes around a manual' => sub {
    my $pod = Manuals::convert(
        "# DBIx::Squirrel how-to\n\nText.\n", \%sections,
        'HOWTO.md',
    );
    like $pod, qr( \A =encoding\ utf8\n )x, 'its encoding';
    like $pod, qr( ^ =for\ comment\ Made\ from\ docs/HOWTO\.md )xm,
        'where it comes from';
    like $pod,
        qr( ^ =head1\ NAME\n\nDBIx::Squirrel::Manual::HowTo\ -\ DBIx::Squirrel\ how-to\n )xm,
        'its NAME, from its module and its title';
    like $pod, qr( =head1\ DESCRIPTION\n\nText\.\n )x,
        'what comes before the first section';
    like $pod, qr( =head1\ AUTHOR .* =cut\n \z )xs, 'and the footer';
};

subtest 'headings, paragraphs and code' => sub {
    is body("## A section\n\n### A `part`\n\n#### Detail\n"),
        "=head1 A section\n\n=head2 A C<part>\n\n=head3 Detail\n\n",
        'headings, one level up';
    is body("One line,\nand another.\n"), "One line,\nand another.\n\n",
        'a paragraph, as it is';
    is body("```perl\nmy \$x = 1;\n\nsay \$x;\n```\n"),
        "    my \$x = 1;\n\n    say \$x;\n\n",
        'code, as verbatim paragraphs';
    is body("<!-- not run -->\n```perl\n1;\n```\n"), "    1;\n\n",
        'a comment, left out';
    like Manuals::convert(
        "# T\n\n<!-- stopwords: flatMap jsonb's -->\n",
        \%sections, 'REFERENCE.md',
        ),
        qr( \A =encoding\ utf8\n\n=for\ stopwords\ flatMap\ jsonb's\n )x,
        'stopwords, for the spelling test';
};

subtest 'inline' => sub {
    is body("A `code` and **bold** word.\n"),
        "A C<code> and B<bold> word.\n\n", 'code and bold';
    is body("Each is a *run*, or an *end\nfunction*.\n"),
        "Each is a I<run>, or an I<end\nfunction>.\n\n",
        'italics, across lines too';
    is body("Two **bold** and *italic*, a * b * c.\n"),
        "Two B<bold> and I<italic>, a * b * c.\n\n",
        'bold and italics apart, a lone * left as it is';
    is body("Use `\$x->y` or `<\$fh>`.\n"),
        "Use C<< \$x->y >> or C<< <\$fh> >>.\n\n",
        'code with a < or >, with more brackets';
    is body("If a < b > c.\n"), "If a E<lt> b E<gt> c.\n\n",
        'a < or > in text, escaped';
    is body("=cut, as a word\n"), "Z<>=cut, as a word\n\n",
        'a line starting =, not a command';
};

subtest 'links' => sub {
    is body("See [it](#the-pipeline).\n"), qq{See L<it|/"The pipeline">.\n\n},
        'to a section here';
    is body("See [the how-to](HOWTO.md).\n"),
        "See L<the how-to|DBIx::Squirrel::Manual::HowTo>.\n\n",
        'to the other manual';
    is body("See [it](HOWTO.md#stop-early).\n"),
        qq{See L<it|DBIx::Squirrel::Manual::HowTo/"Stop early">.\n\n},
        'to a section there';
    is body("See [the\nsite](https://example.org/a).\n"),
        "See L<the\nsite|https://example.org/a>.\n\n",
        'to a URL, the text across lines';
    is body("[`pipe` and `tap`](#pipe-and-tap)\n"),
        qq{L<C<pipe> and C<tap>|/"pipe and tap">\n\n},
        'with code in its text';
    is body("[a/b|c](#the-pipeline)\n"),
        qq{L<aE<sol>bE<verbar>c|/"The pipeline">\n\n},
        'with / and | in its text, escaped';
    is body("[Changes](../Changes) says.\n"),
        "L<Changes|https://metacpan.org/dist/DBIx-Squirrel/changes> says.\n\n",
        'to another file, where it is instead';
};

subtest 'lists and tables' => sub {
    is body("- One,\n  and on.\n- Two.\n"),
        "=over 4\n\n=item *\n\nOne,\nand on.\n\n=item *\n\nTwo.\n\n=back\n\n",
        'a list';
    is body("1. First.\n\n2. Second.\n"),
        "=over 4\n\n=item 1.\n\nFirst.\n\n=item 2.\n\nSecond.\n\n=back\n\n",
        'a numbered list, with a line between';
    is body("| Name | What |\n|---|---|\n| `a` | The a. |\n"),
        "=over 4\n\n=item C<a>\n\nThe a.\n\n=back\n\n", 'a table of two columns';
    is body("| A | B | C |\n|---|---|---|\n| x | `y|z` | |\n"),
        "=over 4\n\n=item x\n\nB<B:> C<y|z>\n\n=back\n\n",
        'of three, an empty cell left out, a | in code kept';
};

subtest 'quotes' => sub {
    is body("> **Note:** one,\n> and on.\n"),
        "=over 4\n\nB<Note:> one,\nand on.\n\n=back\n\n", 'a quote, indented';
    is body("> One.\n>\n> Two.\n"),
        "=over 4\n\nOne.\n\nTwo.\n\n=back\n\n", 'of two paragraphs';
    is body("Text,\n> quoted.\n"),
        "Text,\n\n=over 4\n\nquoted.\n\n=back\n\n", 'after a paragraph';
};

subtest 'what it refuses' => sub {
    like dies { body("> - A list.\n") },
        qr( \A Markdown\ this\ doesn't\ convert\ in\ a\ quote )x,
        'anything but paragraphs in a quote';
    like dies { body(">A quote.\n") },
        qr( \A Markdown\ this\ doesn't\ convert )x, 'a quote with no space';
    like dies { body("- One.\n  - Two.\n") }, qr( \A A\ list\ in\ a\ list )x,
        'a list in a list';
    like dies { body("    indented\n") },
        qr( \A Markdown\ this\ doesn't\ convert )x, 'indented code';
    like dies { body("```perl\nunclosed\n") },
        qr( \A A\ code\ block\ isn't\ closed )x, 'an open block';
    like dies { body("[x](#nowhere)\n") }, qr( has\ no\ such\ heading )x,
        'a link to nowhere';
    like dies { body("[x](CHANGES.md)\n") }, qr( isn't\ a\ manual )x,
        'or to another file';
    like dies { body("| a | b |\n|---|---|\n| 1 |\n") },
        qr( \A A\ table\ row\ with\ 1\ cells )x,
        'a short row';
};

subtest 'the anchors, as GitHub makes them' => sub {
    is Manuals::anchor("pipe and tap on handles"), 'pipe-and-tap-on-handles',
        'spaces';
    is Manuals::anchor("Gathering: stages, an `end`"),
        'gathering-stages-an-end', 'punctuation and code';
    is Manuals::anchor("Upgrading from 1.x"), 'upgrading-from-1x', 'a dot';
    is Manuals::sections("## Pipelines\n\n### Pipelines\n"),
        {pipelines => 'Pipelines', 'pipelines-1' => ''},
        'a second heading of the same name, as GitHub numbers it';
};

subtest 'the manuals are current, and sound' => sub {
    my $out = qx("$^X" "$SCRIPT" --check);    ## no critic (InputOutput::ProhibitBacktickOperators) its output is the diagnosis
    is $?, 0, "they're what docs/ makes" or diag $out;
    for my $file (sort map { $_->[1] } values %Manuals::MANUAL) {
        my $checker = Pod::Checker->new(-warnings => 2, -quiet => 1);
        $checker->parse_from_file($file, \my $report);
        is $checker->num_errors, 0, "$file has no errors";
        my @warnings = grep { !m( multiple\ occurrences )x }
            grep { m( WARNING )x } split m( \n )x, $report // '';
        is \@warnings, [], "nor warnings, but for a repeated link target";
    }
};

subtest 'each link between the manuals finds its section' => sub {
    my %heads;
    for my $pair (values %Manuals::MANUAL) {
        my($module, $file) = @$pair;
        my $pod = Manuals::slurp($file);
        $heads{$module} = {map { (s( [A-Z]<<? \s? | \s? >?> )()xgr => 1) }
            $pod =~ m( ^ =head\d \  (.+) $ )xmg};
        $heads{$module}{pod} = $pod;
    }
    for my $module (sort keys %heads) {
        for my $link ($heads{$module}{pod}
            =~ m( L< [^|>]+ \| (DBIx::Squirrel::Manual::\w+ / "[^"]+") > )xg)
        {
            my($to, $section) = $link =~ m( \A ([\w:]+) / "(.+)" \z )x;
            ok $heads{$to}{$section}, "$module: $to has $section";
        }
    }
};

done_testing;
