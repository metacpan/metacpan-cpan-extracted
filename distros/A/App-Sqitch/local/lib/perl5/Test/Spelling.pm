package Test::Spelling;

use strict;
use warnings;

use Exporter qw(import);
use Pod::Spell;
use Test::Builder;
use Text::Wrap;
use File::Spec;
use IPC::Run3;
use Symbol 'gensym';

our $VERSION = '0.25';

our @EXPORT = qw(
    pod_file_spelling_ok
    all_pod_files_spelling_ok
    add_stopwords
    set_spell_cmd
    all_pod_files
    set_pod_file_filter
    has_working_spellchecker
    set_pod_parser
);

my $TEST = Test::Builder->new;

my $SPELLCHECKER;
my $FILE_FILTER = sub { 1 };
my $POD_PARSER;
our %ALL_WORDS;

sub spellchecker_candidates {
    # if they've specified a spellchecker, use only that one
    return $SPELLCHECKER if $SPELLCHECKER;

    return (
        'hunspell -l', # hunspell is now the most common spell checker
        'spell', # for back-compat, this is the top candidate ...
        'aspell list -l en -p /dev/null', # ... but this should become first soon
        'ispell -l',
    );
}

sub has_working_spellchecker {
    my $dryrun_results = _get_spellcheck_results("dry run", 1);

    if (ref $dryrun_results) {
        return;
    }

    return $SPELLCHECKER;
}

sub _get_spellcheck_results {
    my $document = shift;
    my $dryrun = shift;

    my @errors;

    for my $spellchecker (spellchecker_candidates()) {
        my @words;
        my $ok = eval {

            my ($spellcheck_results, $errors);
            IPC::Run3::run3($spellchecker, \$document, \$spellcheck_results, \$errors);

            @words = split /\n/, $spellcheck_results;

            die "spellchecker had errors: $errors" if length $errors;

            1;
        };

        if ($ok) {
            # remember the one we used, so that it's consistent for all the files
            # this run, and we don't keep retrying the same spellcheckers that will
            # never work. also we need to expose the spellchecker we're using in
            # has_working_spellchecker
            set_spell_cmd($spellchecker)
                if !$SPELLCHECKER;
            return @words;
        }

        push @errors, "Unable to run '$spellchecker': $@";
    }

    # no working spellcheckers during a dry run
    return \"no spellchecker" if $dryrun;

    # no working spellcheckers; report all the errors
    require Carp;
    Carp::croak
        "Unable to find a working spellchecker:\n"
        . join("\n", map { "    $_\n" } @errors)
}

sub invalid_words_in {
    my $file = shift;

    my $document = '';
    open my $handle, '>', \$document;
    # the UTF-8 parsing seems to have broken many tests
    #open my $infile, '<:encoding(UTF-8)', $file;

    # save digested POD to the string $document
    #get_pod_parser()->parse_from_filehandle($infile, $handle);
    get_pod_parser()->parse_from_file($file, $handle);
    my @words = _get_spellcheck_results($document);

    chomp for @words;
    return @words;
}

sub pod_file_spelling_ok {
    my $file = shift;
    my $name = shift || "POD spelling for $file";

    if (!-r $file) {
        $TEST->ok(0, $name);
        $TEST->diag("$file does not exist or is unreadable");
        return;
    }

    my @words = invalid_words_in($file);

    # remove stopwords, select unique errors
    my $WL = \%Pod::Wordlist::Wordlist;
    @words = grep { !$WL->{$_} && !$WL->{lc $_} } @words;
    $ALL_WORDS{$_}++ for @words;
    my %seen;
    @seen{@words} = ();
    @words = sort keys %seen;

    # emit output
    my $ok = @words == 0;
    $TEST->ok($ok, "$name");
    if (!$ok) {
        $TEST->diag("Errors:\n" . join '', map { "    $_\n" } @words);
    }

    return $ok;
}

sub all_pod_files_spelling_ok {
    my @files = all_pod_files(@_);
    local %ALL_WORDS;
    if (!has_working_spellchecker()) {
        return $TEST->plan(skip_all => "no working spellchecker found");
    }

    $TEST->plan(tests => scalar @files);

    my $ok = 1;
    for my $file (@files) {
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        pod_file_spelling_ok($file) or undef $ok;
    }
    if ( keys %ALL_WORDS ) {
        # Invert k => v to v => [ k ]
        my %values;
        push @{ $values{ $ALL_WORDS{$_} } }, $_ for keys %ALL_WORDS;

        my $labelformat = q[%6s: ];
        my $indent      = q[ ] x 10;

        $TEST->diag(qq[\nAll incorrect words, by number of occurrences:\n] .
          join qq[\n], map { wrap( ( sprintf $labelformat, $_ ), $indent, join q[, ], sort @{ $values{$_} } ) }
          sort { $a <=> $b } keys %values
        );
    }
    return $ok;
}

sub all_pod_files {
    my @queue = @_ ? @_ : _starting_points();
    my @pod;

    while (@queue) {
        my $file = shift @queue;

        # recurse into subdirectories
        if (-d $file) {
            opendir(my $dirhandle, $file) or next;
            my @newfiles = readdir($dirhandle);
            closedir $dirhandle;

            @newfiles = File::Spec->no_upwards(@newfiles);
            @newfiles = grep { $_ ne "CVS" && $_ ne ".svn" } @newfiles;

            push @queue, map "$file/$_", @newfiles;
        }

        # add the file if it meets our criteria
        if (-f $file) {
            next unless _is_perl($file);
            next unless $FILE_FILTER->($file);
            push @pod, $file;
        }
    }

    return @pod;
}

sub _starting_points {
    return 'blib' if -d 'blib';
    return 'lib';
}

sub _is_perl {
    my $file = shift;

    return 1 if $file =~ /\.PL$/;
    return 1 if $file =~ /\.p(l|lx|m|od)$/;
    return 1 if $file =~ /\.t$/;

    open my $handle, '<', $file or return;
    my $first = <$handle>;

    return 1 if defined $first && ($first =~ /^#!.*perl/);

    return 0;
}

sub add_stopwords {
    for (@_) {
        # explicit copy so we don't modify constants as in add_stopwords("SQLite")
        my $word = $_;

        # XXX: the processing this performs is to support "perl t/spell.t 2>>
        # t/spell.t" which is bunk. in the near future the processing here will
        # become more modern
        $word =~ s/^#?\s*//;
        $word =~ s/\s+$//;
        next if $word =~ /\s/ or $word =~ /:/;
        $Pod::Wordlist::Wordlist{$word} = 1;
    }
}

sub set_spell_cmd {
    $SPELLCHECKER = shift;
}

sub set_pod_file_filter {
    $FILE_FILTER = shift;
}

# A new Pod::Spell object should be used for every file; people
# providing custom pod parsers will have to do this themselves
sub get_pod_parser {
    return $POD_PARSER || Pod::Spell->new;
}

sub set_pod_parser {
    $POD_PARSER = shift;
}

1;

__END__

=head1 NAME

Test::Spelling - Check for spelling errors in POD files

=head1 SYNOPSIS

Place a file, C<pod-spell.t> in your distribution's C<xt/author> directory:

    use strict;
    use warnings;
    use Test::More;

    use Test::Spelling;
    use Pod::Wordlist;

    add_stopwords(<DATA>);
    all_pod_files_spelling_ok( qw( bin lib ) );

    __DATA__
    SomeBizarreWord
    YetAnotherBIzarreWord

Or, you can gate the spelling test with the environment variable C<AUTHOR_TESTING>:

    use strict;
    use warnings;
    use Test::More;

    BEGIN {
        plan skip_all => "Spelling tests only for authors"
            unless $ENV{AUTHOR_TESTING};
    }

    use Test::Spelling;
    use Pod::Wordlist;

    all_pod_files_spelling_ok();

=head1 DESCRIPTION

L<Test::Spelling> lets you check the spelling of a C<POD> file, and report
its results in standard L<Test::More> fashion. This module requires a
spellcheck program such as L<Hunspell|http://hunspell.github.io/>,
F<aspell>, F<spell>, or, F<ispell>. We suggest using Hunspell.

    use Test::Spelling;
    pod_file_spelling_ok('lib/Foo/Bar.pm', 'POD file spelling OK');

Note that it is a bad idea to run spelling tests during an ordinary CPAN
distribution install, or in a package that will run in an uncontrolled
environment. There is no way of predicting whether the word list or spellcheck
program used will give the same results. You B<can> include the test in your
distribution, but be sure to run it only for authors of the module by guarding
it in a C<skip_all unless $ENV{AUTHOR_TESTING}> clause, or by putting the test in
your distribution's F<xt/author> directory. Anyway, people installing your module
really do not need to run such tests, as it is unlikely that the documentation
will acquire typos while in transit.

You can add your own stop words, which are words that should be ignored by the
spell check, like so:

    add_stopwords(qw(asdf thiswordiscorrect));

Adding stop words in this fashion affects all files checked for the remainder of
the test script. See L<Pod::Spell> (which this module is built upon) for a
variety of ways to add per-file stop words to each .pm file.

If you have a lot of stop words, it's useful to put them in your test file's
C<DATA> section like so:

    use strict;
    use warnings;
    use Test::More;

    use Test::Spelling;
    use Pod::Wordlist;

    add_stopwords(<DATA>);
    all_pod_files_spelling_ok();

    __DATA__
    folksonomy
    Jifty
    Zakirov

To maintain backwards compatibility, comment markers and some whitespace are
ignored. In the near future, the preprocessing we do on the arguments to
L<Test::Spelling/"add_stopwords"> will be changed and documented properly.

=head1 FUNCTIONS

L<Test::Spelling> makes the following methods available.

=head2 add_stopwords

  add_stopwords(@words);
  add_stopwords(<DATA>); # pull in stop words from the DATA section

Add words that should be skipped by the spell checker. Note that L<Pod::Spell>
already skips words believed to be code, such as everything in verbatim
(indented) blocks and code marked up with C<< C<...> >>, as well as some common
Perl jargon.

=head2 all_pod_files

  all_pod_files();
  all_pod_files(@list_of_directories);

Returns a list of all the Perl files in each directory and its subdirectories,
recursively. If no directories are passed, it defaults to F<blib> if F<blib>
exists, or else F<lib> if not. Skips any files in F<CVS> or F<.svn> directories.

A Perl file is:

=over 4

=item * Any file that ends in F<.PL>, F<.pl>, F<.plx>, F<.pm>, F<.pod> or F<.t>.

=item * Any file that has a first line with a shebang and "perl" on it.

=back

Furthermore, files for which the filter set by L</set_pod_file_filter> return
false are skipped. By default, this filter passes everything through.

The order of the files returned is machine-dependent.  If you want them
sorted, you'll have to sort them yourself.

=head2 all_pod_files_spelling_ok

  all_pod_files_spelling_ok(@list_of_files);
  all_pod_files_spelling_ok(@list_of_directories);

Checks all the files for C<POD> spelling. It gathers
L<Test::Spelling/"all_pod_files"> on each file/directory, and
declares a L<Test::More/plan> for you (one test for each file), so you
must not call C<plan> yourself.

If C<@files> is empty, the function finds all C<POD> files in the F<blib>
directory if it exists, or the F<lib> directory if it does not. A C<POD> file is
one that ends with F<.pod>, F<.pl>, F<.plx>, or F<.pm>; or any file where the
first line looks like a perl shebang line.

If there is no working spellchecker (determined by
L<Test:Spelling/"has_working_spellchecker">), this test will issue a
C<skip all> directive.

If you're testing a distribution, just create an F<xt/author/pod-spell.t> with the code
in the L</SYNOPSIS>.

Returns true if every C<POD> file has correct spelling, or false if any of them fail.
This function will show any spelling errors as diagnostics.

* B<NOTE:> This only tests using bytes. This is not decoded content, etc. Do
not expect this to work with Unicode content, for example. This uses an open
with no layers and no decoding.

=head2 get_pod_parser

  # a Pod::Spell -like object
  my $object = get_pod_parser();

Get the object we're using to parse the C<POD>. A new L<Pod::Spell> object
should be used for every file. People providing custom parsers will have
to do this themselves.

=head2 has_working_spellchecker

  my $cmd = has_working_spellchecker;

C<has_working_spellchecker> will return C<undef> if there is no working
spellchecker, or a true value (the spellchecker command itself) if there is.
The module performs a dry-run to determine whether any of the spellcheckers it
can will use work on the current system. You can use this to skip tests if
there is no spellchecker. Note that L</all_pod_files_spelling_ok> will do this
for you.

A full list of spellcheckers which this method might test can be found in the
source of the C<spellchecker_candidates> method.

=head2 pod_file_spelling_ok

  pod_file_spelling_ok('/path/to/Foo.pm');
  pod_file_spelling_ok('/path/to/Foo.pm', 'Foo is well spelled!');

C<pod_file_spelling_ok> will test that the given C<POD> file has no spelling
errors.

When it fails, C<pod_file_spelling_ok> will show any spelling errors as
diagnostics.

The optional second argument is the name of the test.  If it is
omitted, C<pod_file_spelling_ok> chooses a default test name
C<< POD spelling for $filename >>.

* B<NOTE:> This only tests using bytes. This is not decoded content, etc. Do
not expect this to work with Unicode content, for example. This uses an open
with no layers and no decoding.

=head2 set_pod_file_filter

    # code ref
    set_pod_file_filter(sub {
        my $filename = shift;
        return 0 if $filename =~ /_ja.pod$/; # skip Japanese translations
        return 1;
    });

If your project has C<POD> documents written in languages other than English, then
obviously you don't want to be running a spellchecker on every Perl file.
C<set_pod_file_filter> lets you filter out files returned from
L</all_pod_files> (and hence, the documents tested by
L</all_pod_files_spelling_ok>).

=head2 set_pod_parser

  my $object = Pod::Spell->new();
  set_pod_parser($object);

By default L<Pod::Spell> is used to generate text suitable for spellchecking
from the input POD.  If you want to use a different parser, perhaps a
customized subclass of L<Pod::Spell>, call C<set_pod_parser> with an object
that is-a L<Pod::Parser>.  Be sure to create a fresh parser object for
each file (don't use this with L</all_pod_files_spelling_ok>).

=head2 set_spell_cmd

  set_spell_cmd('hunspell -l'); # current preferred
  set_spell_cmd('aspell list');
  set_spell_cmd('spell');
  set_spell_cmd('ispell -l');

If you want to force this module to use a particular spellchecker, then you can
specify which one with C<set_spell_cmd>. This is useful to ensure a more
consistent lexicon between developers, or if you have an unusual environment.
Any command that takes text from standard input and prints a list of misspelled
words, one per line, to standard output will do.

=head1 SEE ALSO

L<Pod::Spell>

=head1 AUTHOR

Ivan Tubert-Brohman C<< <itub@cpan.org> >>

Heavily based on L<Test::Pod> by Andy Lester and brian d foy.

=head1 COPYRIGHT & LICENSE

Copyright 2005, Ivan Tubert-Brohman, All Rights Reserved.

You may use, modify, and distribute this package under the
same terms as Perl itself.

=cut
