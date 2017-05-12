package Pod::Snippets;

use warnings;
use strict;

=head1 NAME

Pod::Snippets - Extract and reformat snippets of POD so as to use them
in a unit test (or other Perl code)

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.11';

=head1 SYNOPSIS

=for metatests "synopsis test script" begin

    use Pod::Snippets;

    my $snips = load Pod::Snippets($file_or_handle,
            -markup => "test");

    my $code_snippet = $snips->named("synopsis")->as_code;

    # ... Maybe borg $code_snippet with regexes or something...

    my $result = eval $code_snippet; die $@ if $@;

    like($result->what_happen(), qr/bomb/);

=for metatests "synopsis test script" end

The Perl code that we want to extract snippets from might look like
this:

=for metatests "synopsis POD" begin

    package Zero::Wing;

    =head1 NAME

    Zero::Wing - For great justice!

    =head1 SYNOPSIS

    =for test "synopsis" begin

       use Zero::Wing;

       my $capitain = Zero::Wing->capitain;

    =for test "synopsis" end

    =cut

    # ...

    1;

=for metatests "synopsis POD" end

=head1 DESCRIPTION

This class is a very simple extension of L<Pod::Parser> that extracts
POD snippets from Perl code, and pretty-prints it so as to make it
useable from other Perl code.  As demonstrated above, B<Pod::Snipets>
is immediately useful to test-driven-development nutcases who want to
put every single line of Perl code under test, including code that is
in the POD (typically a SYNOPSIS section).  There are other uses, such
as storing a piece of information that is both human- and
machine-readable (eg an XML schema) simultaneously as documentation
and code.

=head2 Using Pod::Snippets for unit testing

The L</SYNOPSIS> demonstrates how to use B<Pod::Snippets> to grab a
piece of POD and execute it with L<perlfunc/eval>.  This can readily
be done using your usual unit testing methodology, without too much
ajusting if any.  This approach has some advantages over other
code-in-POD devices such as L<Pod::Tested> and L<Test::Inline>:

=over

=item *

There is no preprocessing step involved, hence no temp files and no
loss of hair in the debugger due to line renumbering.

=item *

Speaking of which, L</as_code> prepends an appropriate C<#line> if
possible, so you can single-step through your POD (yow!).

=back

The Pod-Snippets CPAN distribution consists of a single Perl file, and
has no dependencies besides what comes with a standard Perl 5.8.x.  It
is therefore easy to embed into your own module so that your users
won't need to install B<Pod::Snippets> by themselves before running
your test suite.  All that remains to do is to select the right
options to pass to L</load> as part of an appropriately named wrapper
function in your test library.

=head2 Snippet Syntax

B<Pod::Snippets> only deals with verbatim portions of the POD (that
is, as per L<perlpod>, paragraphs that start with whitespace at the
right) and custom markup starting with C<=for test>, C<=begin test> or
C<=end test>; it discards the rest (block text, actual Perl code,
character markup such as BE<lt>E<gt>, =head's and so on).  The keyword
"test" in C<=for test> and C<=begin test> can be replaced with
whatever one wants, using the C<-markup> argument to L</load>.
Actually the default value is not even "test"; nonetheless let's
assume you are using "test" yourself for the remainder of this
discussion.  The following metadata markup is recognized:

=over

=item B<=for test ignore>

Starts ignoring all POD whatsoever.  Verbatim portions of the POD are
no longer stashed by B<Pod::Snippets> until remanded by a subsequent
C<=for test>.

=item B<=for test>

Cancels the effect of an ongoing C<=for test ignore> directive.

=item B<=for test "foo" begin>

=item B<=for test "foo" end>

These signal the start and end of a I<named> POD snippet, that can
later be fetched by name using L</named>.  Unless countermanded by
appropriate parser options (see L</load>), named POD snippets can
nest freely (even badly).

=item B<=begin test>

=item B<=end test>

The POD between these markers will be seen by B<Pod::Snippets>, but
not by other POD formatters.  Otherwise has no effect on the naming or
ignoring of snippets; in particular, if the contents of the section is
not in POD verbatim style, it still gets ignored.

=item B<=begin test "foo">

=item B<=end test "foo">

These have the exact same effect as C<=for test "foo" begin> and
C<=for test "foo" end>, except that other POD formatters will not see
the contents of the block.

=back

=head1 CONSTRUCTORS

=head2 load ($source, -opt1 => $val1, ...)

Parses the POD from $source and returns an object of class
B<Pod::Snippets> that holds the snippets found therein.  $source may
be the name of a file, a file descriptor (glob reference) or any
object that has a I<getline> method.

Available named options are:

=over

=item B<< -filename => $filename >>

The value to set for L</filename>, that is, the name of the file to
use for C<#line> lines in L</as_code>.  The default behavior is to use
the filename passed as the $source argument, or if it was not a
filename, use the string "pod snippet" instead.

=item B<< -line => $line >>

The line number to start counting lines from, eg in case the $source
got a few lines chopped off it before being passed to I<load>.
Default is 1.

=item B<< -markup => $name >>

The markup (aka "format name" in L<perlpod>) to use as the first token
after C<=for>, C<=begin> or C<=end> to indicate that the directive is
to be processed by B<Pod::Snippets> (see L</Snippet Syntax>.  Default
is "Pod::Snippets".

=item B<< -report_errors => $sub >>

Invokes $sub like so to deal with warnings and errors:

  $sub->($severity, $text, $file, $line);

where $severity is either "WARNING" or "ERROR".  By default the
standard Perl L<perlfunc/warn> is used.

Regardless of the number of errors, the constructor tries to load the
whole file; see below.

=item B<< -named_snippets => "warn_impure" >>

Raises an error upon encountering this kind of construct:

=for metatests "named_snippets impure error" begin

  =for test "foobar" begin

     my $foobar = foobar();

  =head1 And now something completely different...

  =for test "foobar" end

=for metatests "named_snippets impure error" end

In other words, only verbatim blocks may intervene between the B<=for
test "foobar" begin> and B<=for test "foobar" end> markups.

=item B<< -named_snippets => "warn_multiple" >>

Raises a warning upon encountering this kind of construct:

=for metatests "named_snippets multiple error" begin

  =for test "foobar" begin

     my $foobar = foobar();

  =for test "foobar" end

  =for test "foobar" begin

     $foobar->quux_some_more();

  =for test "foobar" end

=for metatests "named_snippets multiple error" end

=item B<< -named_snippets => "warn_overlap" >>

Raises a warning if named snippets overlap in any way.

=item B<< -named_snippets => "warn_bad_pairing" >>

Raises a warning if opening and closing markup for named snippets is
improperly paired (eg opening or closing twice, or forgetting to close
before the end of the file).

=item B<< -named_snippets => "error_impure" >>

=item B<< -named_snippets => "error_multiple" >>

=item B<< -named_snippets => "error_overlap" >>

=item B<< -named_snippets => "error_bad_pairing" >>

Same as the C<warn_> counterparts above, but cause errors instead of
warnings.

=item B<< -named_snippets => "ignore_impure" >>

=item B<< -named_snippets => "ignore_multiple" >>

=item B<< -named_snippets => "ignore_overlap" >>

=item B<< -named_snippets => "ignore_bad_pairing" >>

Ignores the corresponding dubious constructs described above.  The
default behavior is C<< -named_snippets => "warn_bad_pairing" >> and
ignore the rest.

=item B<< -named_snippets => "strict" >>

Equivalent to C<< (-named_snippets => "error_overlap", -named_snippets
=> "error_impure", -named_snippets => "error_multiple",
-named_snippets => "error_bad_pairing") >>.

=back

Note that the correctness of the POD to be parsed is a prerequisite;
in other words, I<Pod::Snippets> won't touch the error management
knobs of the underlying L<Pod::Parser> object.

Also, note that the parser strictness options such as
B<-named_snippets> have no effect on the semantics; they merely alter
its response (ignore, warning or error) to the aforementioned dubious
constructs.  In any case, the parser will soldier on until the end of
the file regardless of the number of errors seen; however, it will
disallow further processing of the snippets if there were any errors
(see L</errors>).

=cut

sub load {
    my ($class, $source, @opts) = @_;

    my $self = bless {}, $class;
    $self->{start_line} = 1;
    $self->{filename} = "$source" unless (ref($source) eq "GLOB" ||
                                          eval { $source->can("getline") });
    undef $@;

    # Grind the syntactic sugar to dust:
    my %opts = (-line => 1, -filename => $self->filename,
                -report_errors => sub {
                    my ($severity, $text, $file, $line) = @_;
                    warn <<"MESSAGE";
$severity: $text
in $file line $line
MESSAGE
                }, -markup => "Pod::Snippets",
                -bad_pairing => "warning");
    while(my ($k, $v) = splice @opts, 0, 2) {
        if ($k eq "-named_snippets") {
            if ($v eq "strict") {
                $opts{"-$_"} = "error" foreach
                    (qw(overlap impure multiple bad_pairing));
            } elsif ($v =~ m|^ignore_(.*)|) {
                $opts{"-$1"} = "ignore";
            } elsif ($v =~ m|^error_(.*)|) {
                $opts{"-$1"} = "error";
            } elsif ($v =~ m|^warn(ing)?_(.*)|) {
                $opts{"-$2"} = "warning";
            }
        } elsif ($k eq "-line") {
            $self->{start_line} = $v;
            $opts{$k} = $v;
        } else {
            $opts{$k} = $v;
        }
    }

    # Run the parser:
    my $parser = "${class}::_Parser"->new_for_pod_snippets(%opts);
    if ($self->{filename}) {
        $parser->parse_from_file($self->{filename}, undef);
    } else {
        $parser->parse_from_filehandle($source, undef);
    }
    $parser->finalize_pod_snippets();

    # Extract the relevant bits from it:
    $self->{unmerged_snippets} = $parser->pod_snippets;
    $self->{warnings} = $parser->pod_snippets_warnings;
    $self->{errors} = $parser->pod_snippets_errors;
    return $self;
}

=head2 parse ($string, -opt1 => $val1, ...)

Same as L</load>, but works from a Perl string instead of a file
descriptor.  The named options are the same as in I<load()>, but
consider using C<< -filename >> as I<parse()> is in no position to
guess it.

=cut

sub parse {
    my ($class, $string, @args) = @_;
    return $class->load(Pod::Snippets::LineFeeder->new($string), @args);

    package Pod::Snippets::LineFeeder;

    sub new {
        my ($class, $string) = @_;
        my $nl = $/; # Foils smarter-than-thou regex parser
        return bless { lines => [ $string =~ m{(.*(?:$nl|$))}g ] };
    }
    sub getline { shift @{shift->{lines}} }
}

=head1 ACCESSORS

=head2 filename ()

Returns the name of the file to use for C<#line> lines in L</as_code>.
The default behavior is to use the filename passed as the $source
argument, or if it was not a filename, use the string "pod snippet"
instead.

=cut

sub filename { shift->{filename} || "pod snippet" }

=head2 warnings ()

Returns the number of warnings that occured during the parsing of the
POD.

=head2 errors ()

Returns the number of errors that occured during the parsing of the
POD.  If that number is non-zero, then all accessors described below
will throw an exception instead of performing.

=cut

sub warnings { shift->{warnings} }
sub errors { shift->{errors} }

=head2 as_data ()

Returns the snippets in "data" format: that is, the return value is
ragged to the left by suppressing a constant number of space
characters at the beginning of each snippet.  (If tabs are present in
the POD, they are treated as being of infinite length; that is, the
ragging algorithm does not eat them or replace them with spaces.)

A snippet is defined as a series of subsequent verbatim POD paragraphs
with only B<Pod::Snippets> markup, if anything, intervening in
between.  That is, I<as_data()>, given the following POD in input:

=for metatests "as_data multiple blocks input" begin

    my $a = new The::Brain;

  =begin test

      # Just kidding. We can't do that, it's too dangerous.
      $a = new Pinky;

  =end test

  =for test ignore

    system("/sbin/reboot");

  and all of a sudden, we have:

  =for test

        if ($a->has_enough_cookies()) {
          $a->conquer_world();
        }

=for metatests "as_data multiple blocks input" end

would return (in list context)

=for metatests "as_data multiple blocks return" begin

  (<<'FIRST_SNIPPET', <<'SECOND_SNIPPET');
  my $a = new The::Brain;



    # Just kidding. We can't do that, it's too dangerous.
    $a = new Pinky;
  FIRST_SNIPPET
  if ($a->has_enough_cookies()) {
    $a->conquer_world();
  }
  SECOND_SNIPPET

=for metatests "as_data multiple blocks return" end

Notice how the indentation is respected snippet-by-snippet; also,
notice that the FIRST_SNIPPET has been padded with an appropriate
number of carriage returns to replace the B<Pod::Snippets> markup, so
that the return value is line-synchronized with the original POD.
However, leading and trailing whitespace is trimmed, leaving only
strings that starts with a nonblank line and end with a single
newline.

In scalar context, returns the blocks joined with a single newline
character ("\n"), thus resulting in a single piece of text where the
blocks are joined by exactly one empty line (and which as a whole is
no longer line-synchronized with the source code, of course).

=cut

sub as_data {
    my ($self) = @_;
    $self->_block_access_if_errors();

    my @retval = map {
        # This may be a pedestrian and sub-optimal way of doing the
        # ragging, but it sure is concise:
        until (m/^\S/m) { s/^ //gm or last; };
        "$_";
    } ($self->_merged_snippets);

    return wantarray ? @retval : join("\n", @retval);
}

=head2 as_code ()

Returns the snippets formatted as code, that is, like L</as_data>,
except that each block is prepended with an appropriate C<#line>
statement that Perl can interpret to renumber lines.  For instance,
these statements would cause Perl to Do The Right Thing if one
compiles the snippets as code with L<perlfunc/eval> and then runs it
under the Perl debugger.

=cut

sub as_code {
    my ($self) = @_;
    $self->_block_access_if_errors();
    my @retval = $self->as_data;

    foreach my $i (0..$#retval) {
        my $file = $self->filename;
        my $line = ($self->_merged_snippets)[$i]->line() +
            $self->{start_line} - 1;
        $retval[$i] = <<"LINE_MARKUP" . $retval[$i];
#line $line "$file"
LINE_MARKUP
    }
    return wantarray ? @retval : join("\n", @retval);
}

=head2 named ($name)

Returns a clone of this B<Pod::Snippet> object, except that it only
knows about the snippet (or snippets) that are named $name.  In the
most lax settings for the parser, this means: any and all snippets
where an C<=for test "$name" begin> (or C<=begin test "$name">) had
been open, but not yet closed with C<=for test "$name" end> (or C<=end
test "$name">).  Returns undef if no snippet named $name was seen at
all.

=cut

sub named {
    my ($self, $name) = @_;
    $self->_block_access_if_errors();
    my @snippets_with_this_name = grep {
             !defined($_) || $_->names_set->{$name}
         } (@{$self->{unmerged_snippets}});
    return if ! grep { defined } @snippets_with_this_name;
    return bless
        {
         unmerged_snippets => \@snippets_with_this_name,
         map { exists $self->{$_} ? ($_ => $self->{$_}) : () }
         (qw(warnings errors filename start_line) )
         # Purposefully do not transfer other fields such as
         # ->{merged_snippets}
        }, ref($self);
}

=begin internals

=head2 _block_access_if_errors ()

Throws an exception if L</errors> returns a nonzero value.  Called by
every read accessor except L</warnings> and I<errors()>.

=cut

sub _block_access_if_errors {
    die <<"MESSAGE" if shift->errors;
Cannot fetch parse results from Pod::Snippets with errors.
MESSAGE
}

=head2 _merged_snippets ()

Returns roughly the same thing as L</pod_snippets> in
L</Pod::Snippets::_Parser>, except that leading and trailing
whitespace is trimmed (updating the line counters appropriately),
names are discarded and snippets are merged together (with appropriate
padding using $/) according to the semantics set forth in L</as_data>.
This method has a cache.

=cut

sub _merged_snippets {
    my ($self) = @_;

    $self->{merged_snippets} ||= do {
        my @snippets;
        foreach my $snip (@{$self->{unmerged_snippets}}) {
            if (! defined($snip)) {
                push @snippets, undef if defined $snippets[-1];
            } elsif (! @snippets) {
                push @snippets, $snip;
            } elsif (! defined($snippets[-1])) {
                $snippets[-1] = $snip;
            } else {
                # The merger case.
                my $prevstartline = $snippets[-1]->line();
                my $newlines_to_add = $snip->line - $prevstartline
                    - _number_of_newlines_in($snippets[-1]);
                if ($newlines_to_add < 0) {
                    my $filename = $self->filename();
                    warn <<"ASSERTION_FAILED" ;
Pod::Snippets: problem counting newlines at $filename
near line $prevstartline (trying to skip $newlines_to_add lines)
Output will be desynchronized.
ASSERTION_FAILED
                    $newlines_to_add = 0;
                }
                $snippets[-1] = $snippets[-1] . $/ x $newlines_to_add .
                    $snip;
            }
        }

        pop @snippets if ! defined $snippets[-1];

        # Trim leading and trailing whitespace.
        foreach my $i (0..$#snippets) {
            my $text = "$snippets[$i]";
            my $line = $snippets[$i]->line();
            my $nl = $/; # Foils smarter-than-thou regex parser
            while($text =~ s|^\s*$nl||) { $line++ };
            # This is disturbingly asymetric.
            $text =~ s|(^\s*$nl)*\Z||m;
            $snippets[$i] = Pod::Snippets::_Snippet->new
                ($line, $text, $snippets[$i]->names_set);
        }

        \@snippets;
    };

    return @{$self->{merged_snippets}};
}

=head2 _number_of_newlines_in($string)

This function (B<not> a method) returns the number of times $/ is
found in $string.

=cut

sub _number_of_newlines_in {
    my @occurences = shift =~ m|($/)|gs;
    return scalar @occurences;
}

=head1 Pod::Snippets::_Parser

This class is a subclass to L<Pod::Parser>, that builds appropriate
state on behalf of a I<Pod::Snippets> object.

=cut

package Pod::Snippets::_Parser;

use base "Pod::Parser";

=head2 new_for_pod_snippets (-opt1 => $val1, ...)

An alternate constructor with a different syntax suited for calling
from I<Pod::Snippets>.  Available named options are:

=over

=item B<< -markup => $string >>

=item B<< -report_errors => $sub >>

=item B<< -filename => $filename >>

=item B<< -line => $line >>

Same as in L</load>, except that all these options are mandatory and
therefore caller should substitute appropriate default values if need
be.

=item B<< -impure => "ignore" >>

=item B<< -impure => "warn" >>

=item B<< -impure => "error" >>

=item B<< -overlap => "ignore" >> and so on

The parse flags to use for handling errors, properly decoded from the
B<-named_snippets> named argument to L</load>.

=back

=cut

sub new_for_pod_snippets {
    my ($class, %opts) = @_;

    my $self = $class->new;
    while(my ($k, $v) = each %opts) {
        $k =~ s/^(-?)(.*)$/$1pod_snippets_$2/;
        $self->{$k} = $v;
    }
    return $self;
}

=head2 finalize_pod_snippets ()

Called after parsing is done; must raise any and all errors that occur
at the end of the file (eg snippets without a closing tag).

=cut

sub finalize_pod_snippets {
    my ($self) = @_;
    foreach my $snipname ($self->in_named_pod_snippet) {
        $self->maybe_raise_pod_snippets_bad_pairing($snipname);
    }
}

=head2 command ()

Overloaded so as to catch the I<Pod::Snippets> markup and keep state
accordingly.

=cut

sub command {
    my ($self, $command, $paragraph, $line_num) = @_;

    $self->pod_snippets_source_line_number($line_num);

    $self->break_current_pod_snippet, return unless
        ($command =~ m/^(for|begin|end)/);

    $self->break_current_pod_snippet, return unless
            (my ($details) = $paragraph =~
             m/\A\s*$self->{-pod_snippets_markup}(.*)$/m);

    # Accept "=begin test" and "=end test" and do nothing...
    if (! $details) {
        $self->ignoring_pod_snippets(0) if ($command eq "for");
        return;
    }

    # ... But moan about "=begin test ignore".
    if ($command eq "for" && $details =~ m/\s+ignore\s*$/) {
        $self->ignoring_pod_snippets(1);
        return;
    }

    if (my ($snipname, $subcommand) =
        $details =~ m/^ \s+ (?: "(.*?)" )  \s* (begin|end)?/x) {
        $command = $subcommand if ($subcommand && $command eq "for");
        if ($command eq "begin") {
            $self->in_named_pod_snippet($snipname, 1);
            return;
        } elsif ($command eq "end") {
            $self->in_named_pod_snippet($snipname, 0);
            return;
        }
    }

    my $equals = "="; # Foils smarter-than-thou Pod::Checker.  Sigh.
    $self->raise_pod_snippets_incident("warning", <<"MESSAGE");
Cannot interpret command, ignoring.

$equals$command $paragraph

MESSAGE
}

=head2 verbatim ()

Overloaded so as to catch and store the verbatim sections.

=cut

sub verbatim {
    my ($self, $paragraph, $line_num) = @_;

    $self->pod_snippets_source_line_number($line_num);

    return if $self->ignoring_pod_snippets;
    push(@{$self->{pod_snippets}},
         Pod::Snippets::_Snippet->new($line_num, $paragraph,
                                      $self->pod_snippets_names()));
}

=head2 textblock ()

=head2 interior_sequence ()

These methods are overloaded so as discard the corresponding pieces of
POD and to call L</break_current_pod_snippet> instead.

=cut

sub textblock {
    my ($self, $paragraph, $line_num) = @_;
    $self->pod_snippets_source_line_number($line_num);
    $self->break_current_pod_snippet;
}

sub interior_sequence { shift->break_current_pod_snippet }

=head2 break_current_pod_snippet ()

Called by L</command>, L</textblock> and L</interior_sequence>
whenever a piece of POD that is ignored by B<Pod::Snippets> is seen in
the parse stream.  Causes the parser to record the break, pursuant to
the snippet aggregation feature set forth in L</as_data>.

=cut

sub break_current_pod_snippet {
    my ($self) = @_;
    $self->maybe_raise_pod_snippets_impure() if
        $self->in_named_pod_snippet;
    push(@{$self->{pod_snippets}}, undef)
         unless (! defined $self->{pod_snippets}->[-1]);
}

=head2 pod_snippets_source_line_number ()

=head2 pod_snippets_source_line_number ($value)

Gets or sets the line number that the parser reached, to be used in
error messages (after offsetting it by the appropriate amount
depending on the setting of the C<-line> named option to
L</new_for_pod_snippets>).  The setter form is to be called as soon as
possible by parser callbacks L</command>, L</verbatim>, L</textblock>
so as to keep in sync with the POD flow.

=cut

sub pod_snippets_source_line_number {
    my ($self, @value) = @_;
    $self->{pod_snippets_source_line_number} = $value[0] if @value;
    return $self->{pod_snippets_source_line_number};
}

=head3 maybe_raise_pod_snippets_multiple ($name)

=head3 maybe_raise_pod_snippets_overlap ($name)

=head3 maybe_raise_pod_snippets_impure ()

=head3 maybe_raise_pod_snippets_bad_pairing ($name)

Maybe passes an error of the respective class to the user-supplied C<<
-report_errors >> sub (see L</load>), if the warning and error
settings so dictate (as described in the documentation for the C<<
-named_snippets >> constructor argument).  The $name argument is the
name of the snippet that is in scope at the point of error.

All these methods are implemented in terms of exactly one call to
L</maybe_raise_named_pod_snippets_incident>.

=cut

sub maybe_raise_pod_snippets_multiple {
    my ($self, $name) = @_;
    $self->maybe_raise_named_pod_snippets_incident
        ("multiple", <<"MESSAGE");
Snippet "$name" is defined multiple times.
MESSAGE
}

sub maybe_raise_pod_snippets_overlap {
    my ($self, $name) = @_;
    $self->maybe_raise_named_pod_snippets_incident
        ("overlap", <<"MESSAGE");
Snippet "$name" is defined multiple times.
MESSAGE
}

sub maybe_raise_pod_snippets_impure {
    my ($self) = @_;
    my @names_in_scope = map { qq'"$_"' }
        ($self->in_named_pod_snippet);
    if (@names_in_scope > 1) {
        my $names_in_scope = join(", ", @names_in_scope);
        $self->maybe_raise_named_pod_snippets_incident
        ("impure", <<"MESSAGE");
Snippets $names_in_scope are impure (ie they
contain intervening non-verbatim POD)
MESSAGE
    } else {
        $self->maybe_raise_named_pod_snippets_incident
        ("impure", <<"MESSAGE");
Snippet $names_in_scope[0] is impure (ie it
contains intervening non-verbatim POD)
MESSAGE
    }
}

sub maybe_raise_pod_snippets_bad_pairing {
    my ($self, $name) = @_;
    $self->maybe_raise_named_pod_snippets_incident
        ("bad_pairing", <<"MESSAGE");
Snippet "$name" has mismatched or missing opening and closing markers.
MESSAGE
}

=head3 maybe_raise_named_pod_snippets_incident ($errclass, $message)

Calls L</raise_pod_snippets_incident> with $message if appropriate
given the parser warning and error level settings for C<$errclass>
(one of "impure", "overlap", "bad_pairing" or "multiple").  See the
C<-named_snippets> argument to L</load> for details.

=cut

sub maybe_raise_named_pod_snippets_incident {
    my ($self, $errclass, $message) = @_;

    my $severity = $self->{"-pod_snippets_$errclass"};
    if ((! defined $severity) || ($severity eq "ignore")) {
        return;
    } else {
        $self->raise_pod_snippets_incident($severity, $message);
    }
}

=head2 Fancy accessors

Yes, we want them even in a totally private class: they are so helpful
in making the code easier to understand, debug and refactor.

=head3 in_named_pod_snippet ($name, $boolean)

Tells the parser state machine that we are entering ($boolean true) or
leaving ($boolean false) a POD snippet named $name.  This operation
can cause L</maybe_raise_pod_snippets_overlap> and/or
L</maybe_raise_pod_snippets_bad_pairing> to be invoked as a side effect.

=head3 in_named_pod_snippet ($name)

Returns true iff the parser is currently in the middle of a POD snippet
named $name.

=head3 in_named_pod_snippet ()

Returns true iff the parser is currently in the middle of any named
POD snippet, regardless of the name.  (In array context, returns the
list of all snippet names the parser is in).

=cut

sub in_named_pod_snippet {
    my ($self, @args) = @_;
    $self->{pod_snippets_names_in_scope} ||= {};
    if (@args >= 2) {
        my ($snipname, $bool) = @args;
        if ($bool) { # Entering
            $self->maybe_raise_pod_snippets_multiple($snipname) if
                exists $self->{pod_snippets_names_in_scope}->{$snipname};
            $self->maybe_raise_pod_snippets_overlap($snipname) if
                $self->in_named_pod_snippet;
            $self->maybe_raise_pod_snippets_bad_pairing($snipname) if
                $self->in_named_pod_snippet($snipname);
            $self->{pod_snippets_names_in_scope}->{$snipname} = 1;
        } else { # Leaving
            $self->maybe_raise_pod_snippets_bad_pairing($snipname) if
                ! $self->in_named_pod_snippet($snipname);
            $self->{pod_snippets_names_in_scope}->{$snipname} = 0;
        }
    } elsif (@args == 1) {
        return !!$self->{pod_snippets_names_in_scope}->{$args[0]};
    } else {
        return grep { $self->{pod_snippets_names_in_scope}->{$_} }
            (keys %{$self->{pod_snippets_names_in_scope}});
    }
}

=head3 pod_snippets_names ()

Returns a reference to a newly-constructed (thus unshared) hash whose
keys are the POD snippet names that have been seen by the parser so
far, and the values are true iff we are currently inside a POD snippet
of the corresponding name.

=cut

sub pod_snippets_names {
    return {%{shift->{pod_snippets_names_in_scope} || {}}}
}

=head3 ignoring_pod_snippets ()

=head3 ignoring_pod_snippets ($value)

Gets or sets the "ignoring snippets" flag in the parser state.

=cut

sub ignoring_pod_snippets {
    my ($self, @value) = @_;
    $self->{ignoring_pod_snippets} = $value[0] if @value;
    return $self->{ignoring_pod_snippets};
}

=head3 pod_snippets ()

Returns the parsed snippets as a list that contains undef values and
references to instances of L<Pod::Snippets::_Snippet>.  The undef
values indicate that some non-snippet block or markup was seen at that
point, and that snippets should not be merged by L</as_data> over such
a boundary.

=cut

sub pod_snippets { shift->{pod_snippets} }

=head3 pod_snippets_warnings ()

=head3 pod_snippets_errors ()

Returns the number of times L</pod_snippets_warning>
(resp. L</pod_snippets_error>) was called during the parsing of this
Perl module.  These do B<not> account for warnings and/or errors due
to malformed POD that may be emitted by L<Pod::Parser>.

=head3 raise_pod_snippets_incident ($kind, $message)

Called whenever the parser issues a warning, resp. an error; calls the
user-supplied C<< -report_errors >> sub (see L</load>) or a default
surrogate thereof.  Also increments the relevant warning and error
counters.  $kind is either "warning" or "error" (in lowercase);
$message is the message to print (I18N be screwed).

=cut

# And now for some awesome metaprogramming goodness.
foreach my $property (qw(warnings errors)) {
    my $fieldname = "pod_snippets_$property";
    my $accessor = sub { shift->{$fieldname} || 0 };
    no strict "refs";
    *{$fieldname} = $accessor;
}

sub raise_pod_snippets_incident {
    my ($self, $incident, $message) = @_;
    $self->{-pod_snippets_report_errors}->
        (uc($incident), $message, $self->{-pod_snippets_filename},
         $self->pod_snippets_source_line_number +
         $self->{-pod_snippets_line} - 1);
    $self->{"pod_snippets_${incident}s"}++;
}

=head2 Pod::Snippets::_Snippet

An instance of this class represents one snippet in the POD.
Instances are immutable, and stringifiable for added goodness.

=cut

package Pod::Snippets::_Snippet;

=head3 new ($lineno, $rawtext, $names_set)

Creates and returns a B<Pod::Snippets::_Snippet> object.  $lineno is
the line number where the snippet starts in the original file.
$rawtext is the text of the snippet without any formatting applied:
there may be extraneous whitespace at the beginning and end, and the
ragging is not performed.  $names_set is a reference to a set (that
is, a hash where only the boolean status of the values matter) of all
snippet names that are in scope for this snippet.

=cut

sub new {
    my ($class, $lineno, $rawtext, $names_set) = @_;

    return bless {
                  line => $lineno,
                  text => $rawtext,
                  names => $names_set,
                 }, $class;
}

=head3 stringify ()

Returns the snippet text.  This is also what happens when one
evaluatess the snippet object as a string.

=cut

use overload '""' => "stringify";
sub stringify { shift->{text} }

=head3 is_named ($name)

Returns true iff $name is in scope at this snippet's text location.

=cut

sub is_named { !! shift->{names}->{shift()} }

=head3 line ()

Returns this snippet's line number.

=cut

sub line { shift->{line} }

=head3 append_text ($text)

Computes and returns a new snippet that has extra $text appended at
the end.  This is also what happens when one uses the L<perlop/.>
operator on a snippet.

=cut

use overload '.' => "append_text";
sub append_text {
    my ($self, $text) = @_;
    return bless {
                  text => "$self->{text}" . "$text",
                  map { ($_ => $self->{$_}) } (qw(line names)),
                 }, ref($self);
}

=head3 names_set ()

Returns the $names_set parameter to L</new>.

=cut

sub names_set { shift->{names} }

=end internals

=head1 SEE ALSO

L<Test::Pod::Snippets>

=head1 AUTHOR

Dominique QUATRAVAUX, C<< <domq@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-pod-snippet@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Pod-Snippet>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

Yanick Champoux <yanick@CPAN.org> is the author of
L<Test::Pod::Snippets> which grandfathers this module.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Dominique QUATRAVAUX, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Pod::Snippets

