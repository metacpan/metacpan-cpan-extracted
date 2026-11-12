package App::Test::Generator::PodExampleExtractor;

use 5.036;
use Carp qw(croak);
use File::Slurp qw(read_file);
use Readonly;

our $VERSION = '0.48';

Readonly my $ANNOTATION_RE => qr/\#\s*(?:=>|returns?)\s*(.+?)\s*$/;
Readonly my $VERBATIM_RE   => qr/^[ \t]/;

=encoding utf8

=head1 NAME

App::Test::Generator::PodExampleExtractor - Extract runnable code examples from a Perl module's POD

=head1 VERSION

Version 0.48

=head1 SYNOPSIS

Pattern 1: list every example found in a module.

    use App::Test::Generator::PodExampleExtractor;

    my $ex = App::Test::Generator::PodExampleExtractor->new(
        file => 'lib/My/Module.pm',
    );
    my $examples = $ex->extract();

    for my $e (@$examples) {
        printf "%-30s  %s\n", $e->{label}, $e->{code};
    }

Pattern 2: keep only the examples that say what they return.
These are the ones that can be checked automatically.

    my @checkable = grep { defined $_->{expected} } @{ $ex->extract() };

    for my $e (@checkable) {
        print "Run:    $e->{annotated_line}\n";
        print "Expect: $e->{expected}\n";
    }

Pattern 3: count the examples in each documentation section.

    my %count;
    $count{ $_->{section} }++ for @{ $ex->extract() };
    printf "%-20s %d\n", $_, $count{$_} for sort keys %count;

Pattern 4: handle a missing file without stopping the program.

    my $ex2 = eval {
        App::Test::Generator::PodExampleExtractor->new(file => $path);
    };
    warn "Skipping $path: $@" unless $ex2;

=head1 DESCRIPTION

Parses the POD of a Perl module and returns a structured list of
runnable code examples.  Three sources are collected:

=over 4

=item * Verbatim blocks inside C<=head1 SYNOPSIS> and C<=head2 SYNOPSIS>

=item * C<=for example begin> ... C<=for example end> blocks

=item * Annotated single-line call examples inside per-method docstrings
(lines matching C<$obj-E<gt>method(...)  # returns value> or
C<method(...)  # => value>)

=back

Return-value annotations of the form C<# returns value> or C<< # => value >>
are parsed and exposed as C<expected> in the result hashref, enabling
downstream test generators to emit C<is()> assertions.

=head2 new

Construct a new extractor for the given source file.

    my $ex = App::Test::Generator::PodExampleExtractor->new(
        file => 'lib/My/Module.pm',
    );

=head3 Arguments

=over 4

=item * C<file>

Path to the Perl module to extract examples from.  Required.
The file must exist on disk.

=back

=head3 Returns

A blessed C<App::Test::Generator::PodExampleExtractor> object.
Croaks if C<file> is missing or does not exist.

The file is not opened by C<new>.  It is read each time you call C<extract>.

=head3 EXAMPLE

    use App::Test::Generator::PodExampleExtractor;

    my $ex = App::Test::Generator::PodExampleExtractor->new(
        file => 'lib/Acme/Widget.pm',
    );
    printf "Extracting examples from %s\n", 'lib/Acme/Widget.pm';

=head3 MESSAGES

=over 4

=item C<file is required>

C<file> was not supplied.

=item C<File not found: $path>

C<file> was supplied but the path does not exist on disk.

=back

=head3 API SPECIFICATION

=head4 input

    { file => { type => SCALAR } }

=head4 output

    { type => OBJECT, isa => 'App::Test::Generator::PodExampleExtractor' }

The mathematical description is in L</FORMAL SPECIFICATION>.

=cut

sub new {
	my ($class, %args) = @_;
	croak 'file is required'          unless defined $args{file};
	croak "File not found: $args{file}" unless -f $args{file};
	return bless { file => $args{file} }, $class;
}

=head2 extract

Extract all runnable examples from the module's POD.

    my $examples = $ex->extract();

=head3 Arguments

None beyond C<$self>.

=head3 Returns

An arrayref of example hashrefs, deduplicated by C<code> text.  Each hashref
has the following keys:

=over 4

=item * C<label> - human-readable name for use as a test label (e.g. C<"SYNOPSIS example 1">)

=item * C<section> - the POD section heading (C<=head1>/C<=head2> text) where the example was found

=item * C<code> - the raw code text, dedented.  May be multi-line for verbatim blocks.

=item * C<expected> - the expected return value string from a C<# returns value> or C<< # => value >> annotation; C<undef> if not annotated.

=item * C<annotated_line> - for annotated single-line examples, the bare expression with the annotation stripped; C<undef> for verbatim blocks.

=back

=head3 EXAMPLE

    my $examples = $ex->extract();
    for my $e (@{$examples}) {
        printf "[%s] %s\n", $e->{label}, $e->{code};
        if(defined $e->{expected}) {
            printf "  expects: %s\n", $e->{expected};
        }
    }

    # Count examples without a declared return value
    my @unannotated = grep { !defined $_->{expected} } @{$examples};
    printf "%d unannotated examples\n", scalar @unannotated;

=head3 MESSAGES

=over 4

=item C<read_file 'PATH' - ...> (raised by C<File::Slurp::read_file>)

The source file was removed, or became unreadable, between the call to
C<new> and the call to C<extract>.  The rest of the message is the reason
given by the operating system.

=back

=head3 API SPECIFICATION

=head4 input

    { self => { type => OBJECT, isa => 'App::Test::Generator::PodExampleExtractor' } }

=head4 output

    { type => ARRAYREF }

The mathematical description is in L</FORMAL SPECIFICATION>.

=cut

sub extract {
	my $self = $_[0];

	my $text = read_file($self->{file}, err_mode => 'croak');

	my @raw;
	push @raw, _extract_synopsis_blocks($text);
	push @raw, _extract_for_example_blocks($text);
	push @raw, _extract_annotated_lines($text);

	# deduplicate by code text
	my %seen;
	my @unique = grep { !$seen{ $_->{code} }++ } @raw;

	# assign numbered labels within each section
	my %section_count;
	for my $e (@unique) {
		my $n = ++$section_count{ $e->{section} };
		$e->{label} = "$e->{section} example $n";
	}

	return \@unique;
}

# --------------------------------------------------
# _extract_synopsis_blocks
#
# Purpose:    Extract verbatim (indented) paragraphs from
#             =head1 SYNOPSIS and =head2 SYNOPSIS sections.
#
# Entry:      $text - full module source including POD
#
# Exit:       Returns a list of example hashrefs.
# --------------------------------------------------
sub _extract_synopsis_blocks {
	my $text = $_[0];

	my @examples;
	while($text =~ /=head[12]\s+SYNOPSIS\s*\n(.*?)(?=\n=head|\n=cut|\z)/sg) {
		my $block = $1;
		push @examples, _verbatim_paragraphs($block, 'SYNOPSIS');
	}
	return @examples;
}

# --------------------------------------------------
# _extract_for_example_blocks
#
# Purpose:    Extract code inside =for example begin / =for example end pairs.
#
# Entry:      $text - full module source including POD
#
# Exit:       Returns a list of example hashrefs.
# --------------------------------------------------
sub _extract_for_example_blocks {
	my $text = $_[0];

	my @examples;
	my $n = 0;
	while($text =~ /=for\s+example\s+begin\s*\n(.*?)=for\s+example\s+end/sg) {
		my $block = $1;
		push @examples, _verbatim_paragraphs($block, '=for example ' . ++$n);
	}
	return @examples;
}

# --------------------------------------------------
# _extract_annotated_lines
#
# Purpose:    Find individual lines inside per-method docstrings that
#             carry a # returns / # => annotation.  These are single-
#             call examples where the expected value is documented inline.
#
# Entry:      $text - full module source including POD
#
# Exit:       Returns a list of example hashrefs (each wrapping the
#             annotated line plus the leading context, if any).
# --------------------------------------------------
sub _extract_annotated_lines {
	my $text = $_[0];

	my @examples;
	my $section = 'UNKNOWN';

	for my $line (split /\n/, $text) {
		# Track current POD section heading
		if($line =~ /^=head\d+\s+(.+)/) {
			$section = $1;
			$section =~ s/\s+$//;
			next;
		}

		# Annotated verbatim line inside POD
		next unless $line =~ $VERBATIM_RE;
		next unless $line =~ $ANNOTATION_RE;

		my $expected = $1;
		$expected    =~ s/\s+$//;

		# Strip leading whitespace from code text
		(my $code = $line) =~ s/^[ \t]+//;

		# Strip the annotation comment from the code
		(my $code_only = $code) =~ s/\s*\#\s*(?:=>|returns?)\s*.+$//;
		$code_only =~ s/\s+$//;

		next unless length $code_only;

		push @examples, {
			section        => $section,
			code           => $code_only,
			expected       => $expected,
			annotated_line => $code_only,
		};
	}

	return @examples;
}

# --------------------------------------------------
# _verbatim_paragraphs
#
# Purpose:    Split a POD text block into its indented
#             (verbatim) paragraphs and return example hashrefs.
#             Paragraphs that contain no Perl-looking syntax
#             (e.g. shell commands like "prove -l t/foo.t") are
#             silently dropped — they would cause compile errors
#             under "use strict" in the generated test file.
#
# Entry:      $block   - text block to scan
#             $section - label string for the containing section
#
# Exit:       Returns a list of example hashrefs with no expected value.
# --------------------------------------------------
sub _verbatim_paragraphs {
	my ($block, $section) = @_;

	my @examples;
	my @current;

	for my $line (split /\n/, $block) {
		if($line =~ $VERBATIM_RE || ($line =~ /\S/ && @current)) {
			push @current, $line;
		} else {
			if(@current) {
				my $code = _dedent(join("\n", @current));
				push @examples, {
					section        => $section,
					code           => $code,
					expected       => undef,
					annotated_line => undef,
				} if length($code) && _looks_like_perl($code);
				@current = ();
			}
		}
	}

	if(@current) {
		my $code = _dedent(join("\n", @current));
		push @examples, {
			section        => $section,
			code           => $code,
			expected       => undef,
			annotated_line => undef,
		} if length($code) && _looks_like_perl($code);
	}

	return @examples;
}

# --------------------------------------------------
# _dedent
#
# Purpose:    Remove the common leading whitespace from every line
#             of a verbatim block so relative indentation is kept
#             (like Python's textwrap.dedent).
#
# Entry:      $text - multi-line string
#
# Exit:       Returns the dedented string with trailing whitespace removed.
# --------------------------------------------------
sub _dedent {
	my $text = $_[0];
	my @lines = split /\n/, $text;
	my @non_empty = grep { /\S/ } @lines;
	return '' unless @non_empty;
	my ($min) = sort { $a <=> $b }
	            map  { /^([ \t]*)/ ? length($1) : 0 } @non_empty;
	s/^[ \t]{0,$min}// for @lines;
	my $out = join("\n", @lines);
	$out =~ s/\s+$//;
	return $out;
}

# --------------------------------------------------
# _looks_like_perl
#
# Purpose:    Return true when a verbatim block contains at least one
#             line that is recognisably Perl syntax.  Used to skip
#             blocks of shell commands (e.g. "prove -l t/foo.t") that
#             would cause compile errors under "use strict".
#
# Entry:      $code - dedented block text
#
# Exit:       Returns 1 (Perl) or '' (not Perl).
# --------------------------------------------------
sub _looks_like_perl {
	my $code = $_[0];
	for my $line (split /\n/, $code) {
		next unless $line =~ /\S/;    # skip blank lines
		next if $line =~ /^\s*#/;     # skip comment-only lines
		# Perl sigils
		return 1 if $line =~ /[\$\@\%]/;
		# Perl keywords at start of statement
		return 1 if $line =~ /^\s*(?:my|our|local|use|require|no|package|sub|for(?:each)?|if|unless|while|until|return|die|croak|warn|print|say|eval|BEGIN|END|push|pop|shift|unshift|keys|values|grep|map|sort)\b/;
		# Method call or package separator
		return 1 if $line =~ /(?:->|::)/;
		# Fat comma — a hash or argument list
		return 1 if $line =~ /=>/;
	}
	return '';
}

=head1 COMMON PITFALLS

=over 4

=item Shell-command blocks are silently dropped

Verbatim paragraphs that contain only shell commands (e.g. C<prove -l t/> or
C<extract-schemas lib/My/Module.pm>) are filtered out by C<_looks_like_perl>.
They would cause compile errors under C<use strict> in a generated test file.
If you want a shell command to appear as an example, put it in a POD comment
block, not a verbatim paragraph.

=item Annotations must be on the B<same line> as the call expression

The C<# returns> / C<< # => >> annotation is parsed as a line-level suffix.
Multi-line calls spread across multiple lines will not pick up an annotation on
the last line.  Only the last line is examined, and the call expression on
earlier lines is lost.

=item C<expected> is always a raw string

The C<expected> field is the literal text captured after C<# returns> or
C<< # => >>.  It is not evaluated or type-converted.  Downstream code that
emits C<is($result, $expected)> must handle quoting appropriately.

=item SYNOPSIS blocks from C<=head3> and deeper are not collected

Only C<=head1 SYNOPSIS> and C<=head2 SYNOPSIS> sections are scanned for
verbatim blocks.  Deeper heading levels are ignored.

=item C<new> takes a list of pairs, not a hashref

Write C<< new(file => $path) >>.  If you write C<< new({ file => $path }) >>
the file name is not seen, and C<new> croaks with C<file is required>.
Any argument other than C<file> is ignored without a warning.

=item How C<undef> is handled

=over 4

=item * C<< file => undef >> makes C<new> croak with C<file is required>.

=item * C<expected> and C<annotated_line> are C<undef> for every example
that came from a whole block.  Always test them with C<defined> before
you use them.

=item * C<label>, C<section> and C<code> are never C<undef>.

=item * A file with no examples gives an empty arrayref (C<[]>), never
C<undef>.

=back

=item Annotated lines are searched for in the whole file, not only in POD

Every indented line of the file is checked for a C<# returns ...> or
C<< # => ... >> comment.  This includes indented lines of ordinary Perl
code.  A code line such as

        return $total;    # returns the sum

is reported as an example with C<expected> set to C<the sum>.  The
C<section> of such an example is the last POD heading seen above it, or
C<UNKNOWN> if there was none.  Use a different wording in code comments
if you do not want this.

=item An annotated line inside a block is reported twice

A line with an annotation that sits inside a SYNOPSIS block appears once
as part of the whole block and once more by itself.  The two entries have
different C<code> text, so the duplicate check does not join them.

=item Each call to C<extract> reads the file again

The result is not stored in the object.  Two calls give two separate
arrayrefs.  Changing one result does not change the other.  If the file
changed on disk between the calls, the results can be different.

=back

=head1 ENCODING

The file is read as raw bytes.  Nothing is decoded.

=over 4

=item * The C<file> argument

The path is passed to the operating system unchanged.  ASCII paths
always work.  For a path with non-ASCII characters, pass it as bytes in
the encoding your file system uses (normally UTF-8).

=item * File contents

Any byte values are accepted.  UTF-8 text, other non-ASCII text and
emojis do not cause errors and are not damaged.  All the markers this
module looks for (C<=head1>, C<=for example>, C<#>, C<< => >>,
C<returns>) are ASCII, so they are found correctly in a UTF-8 file.

=item * Returned strings

C<section>, C<label>, C<code>, C<expected> and C<annotated_line> are
B<byte> strings.  If the file is UTF-8, each non-ASCII character or emoji
is still several separate bytes in the result.  Call
C<Encode::decode('UTF-8', $string)> if you need Perl character strings,
for example before you measure a length or print through a UTF-8 handle.

=item * The C<=encoding> line

It is ignored.  The module does not use it to convert anything.

=item * Line endings

Only C<\n> ends a line.  A file with Windows line endings keeps a C<\r>
inside multi-line C<code> values.

=back

=head1 LIMITATIONS

=over 4

=item No evaluation of verbatim blocks

Verbatim blocks are returned as raw code strings.  The module does not evaluate
them or check that they are syntactically valid Perl.  Blocks that are
syntactically broken will cause the downstream test file to fail to compile.

=item Deduplication is by exact C<code> text

Two examples with identical C<code> strings are deduplicated even if they come
from different sections.  If the same one-liner appears in both SYNOPSIS and a
method docstring, only the first occurrence is kept.

=back

=head1 SEE ALSO

=over 4

=item C<bin/pod-example-tester>

=item L<App::Test::Generator>

=item L<Pod::Simple>

=back

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 FORMAL SPECIFICATION

This section describes each method in Z notation.  It is for readers who
want an exact, mathematical statement.  You do not need it to use the module.

How to read it: a name ending in C<?> is an input, a name ending in C<!> is
an output, and a name ending in C<'> is the value after the call.
The symbol E<0x039E> before the state name means "this call does not change
the object".

The state of an object is one value, the path given to C<new>:

    ┌─ PodExampleExtractor ─────────────────────────────
    │ file : PATH
    ├───────────────────────────────────────────────────
    │ file ≠ undef
    └───────────────────────────────────────────────────

    ┌─ Example ─────────────────────────────────────────
    │ section, label, code : STRING
    │ expected, annotated_line : STRING ∪ { undef }
    ├───────────────────────────────────────────────────
    │ code ≠ ''
    │ expected = undef ⇔ annotated_line = undef
    │ annotated_line ≠ undef ⇒ annotated_line = code
    └───────────────────────────────────────────────────

=head2 new

    ┌─ New ─────────────────────────────────────────────
    │ PodExampleExtractor′
    │ file? : VALUE
    │ result! : PodExampleExtractor
    ├───────────────────────────────────────────────────
    │ pre   file? ≠ undef ∧ file? names an existing plain file
    │ post  file′ = file?
    │       result! = θ PodExampleExtractor′
    └───────────────────────────────────────────────────

    file? = undef                  ⇒ croak 'file is required'
    file? is not an existing file  ⇒ croak 'File not found: ' ⁀ file?

=head2 extract

    ┌─ Extract ─────────────────────────────────────────
    │ Ξ PodExampleExtractor
    │ result! : seq Example
    ├───────────────────────────────────────────────────
    │ pre   file can be read
    │ post  result! = synopsis blocks ⁀ 'for example' blocks
    │                 ⁀ annotated lines, with later copies of
    │                 the same code removed
    │       ∀ i, j : dom result! •
    │           i ≠ j ⇒ result!(i).code ≠ result!(j).code
    │       ∀ e : ran result! • ∃ n : ℕ₁ •
    │           e.label = e.section ⁀ ' example ' ⁀ n
    │       ∀ i, j : dom result! •
    │           i ≠ j ⇒ result!(i).label ≠ result!(j).label
    └───────────────────────────────────────────────────

    file cannot be read  ⇒ croak (message from File::Slurp)

=head1 STATE DIAGRAM

An object of this class has only one working state.  It is created ready
to use and it never changes afterwards.

                         new(file => undef)
                         new(file => path that does not exist)
                       +------------------------------+
                       |  action: croak, no object    |
                       v                              |
                +-------------+                       |
                |  NO OBJECT  |-----------------------+
                +-------------+
                       |
                       | new(file => existing file)
                       | action: remember the path (file is not read)
                       v
                +-------------+   extract()  [file can be read]
                |             |---------------------------------+
                |    READY    |   action: read the file,        |
                |             |   return a new list of examples |
                |             |<--------------------------------+
                |             |
                |             |   extract()  [file removed or
                |             |               not readable]
                |             |---------------------------------+
                |             |   action: croak, nothing changes|
                |             |<--------------------------------+
                +-------------+
                       |
                       | last reference goes away
                       | action: Perl frees the object
                       v
                +-------------+
                |    GONE     |
                +-------------+

Side effects: C<extract> opens the file for reading and closes it again
before it returns.  No method writes to disk or prints anything.

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the terms of GPL2.
If you use it,
please let me know.

=cut

1;
