package App::Actions::Util;

use strict;
use warnings;
use utf8;
use autodie qw(:all);

use Exporter qw(import);
use JSON::PP ();
use Readonly;
use YAML::PP;
use YAML::PP::Common qw(PRESERVE_ORDER);

use App::Actions::I18N qw(throw validate_args);

use Sub::Private ();

use App::Actions::Access;

our $VERSION = '0.001.0';

our @EXPORT_OK = qw(load_yaml_mapping mapping normalize_step stringify trim);

# A failure in a helper is the caller's mistake, not the helper's, so Carp
# reports it from the module that asked for the helper (and, through their own
# @CARP_NOT, from that module's caller).
our @CARP_NOT = qw(App::Actions App::Actions::Workflow App::Actions::Action);

# The step fields that must be plain strings when present.  A mapping or a
# list in one of these is a YAML indentation mistake, and catching it here
# gives a message about the step rather than a crash deep inside the run.
Readonly::Array my @STRING_STEP_FIELDS => qw(run uses shell working-directory name id if);

# The step fields that hold mappings of their own and are copied, so a caller
# can change a step's env or with without changing the parsed document.
Readonly::Array my @MAPPING_STEP_FIELDS => qw(env with);

# The kinds of YAML document load_yaml_mapping knows the messages for.  Each
# names the prefix of its keys in the catalogue.
Readonly::Hash my %DOCUMENT_KINDS => (workflow => 1, action => 1);

# One canonical encoder, so equal structures always stringify identically and
# the encoder is not rebuilt for every value.
my $CANONICAL_JSON = JSON::PP->new->canonical;

=encoding utf-8

=head1 NAME

App::Actions::Util - helpers shared by the App::Actions document readers

=head1 SYNOPSIS

Read a workflow file and check that it is a mapping:

	use App::Actions::Util qw(load_yaml_mapping mapping);

	my $data = load_yaml_mapping('.github/workflows/ci.yml', 'workflow');
	my $env  = mapping($data->{env}, ['where.workflow_env']);

Check one step of a job:

	use App::Actions::Util qw(normalize_step);

	my $step = normalize_step($raw_step, ['where.job', { job => 'test' }]);
	print $step->{run} // $step->{uses}, "\n";

Turn a YAML value into the text a workflow would see:

	use App::Actions::Util qw(stringify);

	stringify(JSON::PP::true);        # 'true'
	stringify([1, 2]);                # '[1,2]'
	stringify(undef);                 # ''

Remove spaces from both ends:

	use App::Actions::Util qw(trim);

	trim("  hello \n");               # 'hello'

=head1 DESCRIPTION

Two modules read YAML files: L<App::Actions::Workflow> (workflow files) and
L<App::Actions::Action> (action files).  They check the files with the same
rules:

=over 4

=item * the file must exist, be valid YAML, and hold a mapping (key: value
pairs) at the top;

=item * C<env> and C<with> must be mappings;

=item * a step must have C<run> or C<uses>.

=back

This module holds those rules, so both readers apply them in exactly the
same way.  It also holds L</stringify>, which turns any YAML value into the
text a workflow sees, and L</trim>.

These functions are for the distribution's own use.  They are public only
because more than one module calls them.  Their interface may change between
releases.

B<About places.>  When a check fails, the error must say I<where> the bad
value was, for example "env of job 'test'".  So the functions that check
take a I<place>: an array reference holding a message key and its
arguments, such as C<< ['where.job_env', { job => 'test' }] >>.  The words
are only made when there is an error, so a check that passes costs nothing.
They are made in the user's language.  A place may also be a plain string.

=head1 FUNCTIONS

=head2 load_yaml_mapping

Reads a YAML file that must hold a mapping.

=head3 ARGUMENTS

=over 4

=item * C<$file> - the path of the file.

=item * C<$kind> - C<workflow> or C<action>; chooses the wording of the
errors.

=back

=head3 RETURNS

A hash reference of the document, with its keys in file order.

=head3 SIDE EFFECTS

Reads the file.

=head3 EXAMPLE

	my $workflow = load_yaml_mapping('.github/workflows/ci.yml', 'workflow');
	print join(', ', keys %{ $workflow->{jobs} }), "\n";

=head3 API SPECIFICATION

=head4 INPUT

	{
		file => { type => 'string', optional => 1 },
		kind => { type => 'string', memberof => [ 'workflow', 'action' ] },
	}

=head4 OUTPUT

	{ type => 'hashref' }

=head3 MESSAGES

	+--------------------------------+--------------------------------+------------------------------+
	| Message (kind = workflow)      | Meaning                        | Resolution                   |
	+--------------------------------+--------------------------------+------------------------------+
	| No workflow file given         | The path was undef or empty    | Pass a path                  |
	| Workflow file 'F' does not     | No regular file at the path    | Check the path               |
	| exist                          |                                |                              |
	| Unable to parse workflow 'F':  | The YAML is malformed          | Fix the YAML at the position |
	| E                              |                                | E names                      |
	| Workflow 'F' is empty          | The file has no document       | Add the workflow             |
	| Workflow 'F' must contain a    | The document is a list or a    | Make the top level a mapping |
	| YAML mapping                   | scalar                         |                              |
	+--------------------------------+--------------------------------+------------------------------+

The C<action> kind reports the same conditions as C<No action metadata file
given>, C<Action metadata file 'F' does not exist>, C<Unable to parse action
metadata 'F': E>, C<Action metadata 'F' is empty> and C<Action metadata 'F'
must contain a YAML mapping>.

=head3 PSEUDOCODE

	refuse an unknown kind
	refuse a missing path, then a path that is not a file
	parse the file, keeping key order, and refuse a parse error
	refuse an empty document, then one that is not a mapping
	return the mapping

=cut

sub load_yaml_mapping {
	my $params = validate_args(__PACKAGE__ . '::load_yaml_mapping', \@_, {
		file => { type => 'string', optional => 1 },
		kind => { type => 'string', memberof => [ sort keys %DOCUMENT_KINDS ] },
	}, ['file', 'kind']);
	my ($file, $kind) = @{$params}{qw(file kind)};

	throw(__PACKAGE__, "$kind.file_required") unless defined $file && length $file;
	throw(__PACKAGE__, "$kind.file_missing", { file => $file }) unless -f $file;

	# Key order is preserved because job order and step order are what the
	# user wrote, and a report that reorders them is harder to follow.
	my $data = eval { YAML::PP->new(preserve => PRESERVE_ORDER)->load_file($file) };
	if (my $error = $@) {
		throw(__PACKAGE__, "$kind.parse_failed", { file => $file, error => trim($error) });
	}

	throw(__PACKAGE__, "$kind.empty", { file => $file }) unless defined $data;
	throw(__PACKAGE__, "$kind.not_mapping", { file => $file }) unless ref $data eq 'HASH';

	return $data;
}

=head2 mapping

Returns a shallow copy of a value that must be a mapping, or an empty hash
when it is absent.

=head3 ARGUMENTS

=over 4

=item * C<$value> - the value from the document, possibly undef.

=item * C<$place> - C<[ $key, \%args ]>, the catalogue key that names where
the value came from.

=back

=head3 RETURNS

A new hash reference.

=head3 SIDE EFFECTS

None.

=head3 EXAMPLE

	my $env = mapping($job->{env}, ['where.job_env', { job => 'test' }]);
	$env->{EXTRA} = 1;    # $job->{env} is unchanged

=head3 API SPECIFICATION

=head4 INPUT

	{
		value => { type => 'hashref', optional => 1 },
		place => { type => 'arrayref', min => 1 },
	}

=head4 OUTPUT

	{ type => 'hashref' }

=head3 MESSAGES

	+--------------------------+-------------------------------+--------------------------------+
	| Message                  | Meaning                       | Resolution                     |
	+--------------------------+-------------------------------+--------------------------------+
	| PLACE must be a mapping  | The value is a list or scalar | Indent it as KEY: VALUE pairs  |
	+--------------------------+-------------------------------+--------------------------------+

=cut

sub mapping {
	my ($value, $place) = @_;

	# Not run through validate_args: this is called once per step field on
	# the success path, and the check below is the whole of the contract.
	throw(__PACKAGE__, 'mapping.invalid', { where => _place_text($place) })
		if defined $value && ref $value ne 'HASH';

	return defined $value ? { %{$value} } : {};
}

=head2 normalize_step

Checks one step of a job or a composite action and returns a copy whose
C<env> and C<with> are always hashes.

=head3 ARGUMENTS

=over 4

=item * C<$step> - the step as parsed.

=item * C<$place> - C<[ $key, \%args ]> naming the job or file the step is
in, such as C<< ['where.job', { job => 'test' }] >>.

=back

=head3 RETURNS

A new hash reference.

=head3 SIDE EFFECTS

None.

=head3 EXAMPLE

	my $step = normalize_step({ run => 'make test' }, ['where.job', { job => 'build' }]);
	print scalar keys %{ $step->{env} }, "\n";    # 0

=head3 API SPECIFICATION

=head4 INPUT

	{
		step  => { type => 'hashref' },
		place => { type => 'arrayref', min => 1 },
	}

=head4 OUTPUT

	{ type => 'hashref' }

=head3 MESSAGES

	+--------------------------------+--------------------------------+------------------------------+
	| Message                        | Meaning                        | Resolution                   |
	+--------------------------------+--------------------------------+------------------------------+
	| A step in PLACE is not a       | The step is a scalar or a list | Start the step with "- run:" |
	| mapping                        |                                | or "- uses:"                 |
	| env/with of a step in PLACE    | env or with is not a mapping   | Indent it as KEY: VALUE      |
	| must be a mapping              |                                |                              |
	| Step field 'F' in PLACE must   | run, uses, shell, name, id, if | Quote the value or fix the   |
	| be a string                    | or working-directory is nested | indentation                  |
	| A step in PLACE has neither    | The step does nothing          | Add run or uses              |
	| 'run' nor 'uses'               |                                |                              |
	+--------------------------------+--------------------------------+------------------------------+

=head3 PSEUDOCODE

	refuse a step that is not a mapping
	copy it, replacing env and with by checked copies
	refuse any string field that holds a reference
	refuse a step with neither run nor uses
	return the copy

=cut

sub normalize_step {
	my ($step, $place) = @_;

	# Like mapping(), this runs for every step of every job, so the checks
	# are the contract and no general validator is run first.
	throw(__PACKAGE__, 'step.not_mapping', { where => _place_text($place) }) unless ref $step eq 'HASH';

	my %copy = %{$step};
	for my $field (@MAPPING_STEP_FIELDS) {
		# The place is nested rather than rendered, so the words are only
		# built when there is an error to put them in.
		$copy{$field} = mapping($copy{$field}, ["where.step_$field", { where => $place }]);
	}

	# A reference where a string belongs is almost always YAML indentation
	# that turned a command into a nested mapping.
	for my $field (@STRING_STEP_FIELDS) {
		next unless defined $copy{$field} && ref $copy{$field};
		throw(__PACKAGE__, 'step.field_not_string', { field => $field, where => _place_text($place) });
	}

	throw(__PACKAGE__, 'step.no_command', { where => _place_text($place) })
		unless defined $copy{run} || defined $copy{uses};

	return \%copy;
}

=head2 stringify

Converts a YAML or JSON value to the string a workflow sees for it.

=head3 ARGUMENTS

=over 4

=item * C<$value> - any value.

=back

=head3 RETURNS

C<''> for undef; C<'true'> or C<'false'> for a boolean (a JSON::PP boolean,
or on Perl 5.36 and later a core boolean, which is what YAML::PP produces
for C<true> and C<false>); the value itself for any other scalar; and
canonical JSON for a reference.

=head3 SIDE EFFECTS

None.

=head3 EXAMPLE

	stringify(undef);              # ''
	stringify(1 == 0);             # 'false' on Perl 5.36+, '' before
	stringify(JSON::PP::true);     # 'true'
	stringify([ 1, 'a' ]);         # '[1,"a"]'
	stringify({ b => 1, a => 2 }); # '{"a":2,"b":1}'

=head3 API SPECIFICATION

=head4 INPUT

	{ value => { type => 'string|arrayref|hashref|object', optional => 1 } }

=head4 OUTPUT

	{ type => 'string' }

=head3 MESSAGES

None.

=cut

sub stringify {
	my ($value) = @_;

	# Booleans first: a JSON::PP boolean is a reference and a core boolean
	# stringifies as '' when false, and GitHub writes both as true/false.
	my $text = !defined $value ? ''
		: JSON::PP::is_bool($value) ? ($value ? 'true' : 'false')
		: !ref $value ? "$value"
		: $CANONICAL_JSON->encode($value);

	return $text;
}

=head2 trim

Removes leading and trailing white space.

=head3 ARGUMENTS

=over 4

=item * C<$text> - a string, possibly undef.

=back

=head3 RETURNS

The trimmed string; C<''> for undef.

=head3 SIDE EFFECTS

None; the argument is not modified.

=head3 EXAMPLE

	trim("  error at line 3\n");    # 'error at line 3'

=head3 API SPECIFICATION

=head4 INPUT

	{ text => { type => 'string', optional => 1 } }

=head4 OUTPUT

	{ type => 'string' }

=head3 MESSAGES

None.

=cut

sub trim {
	my ($text) = @_;

	# A copy is trimmed so a caller's variable is never changed behind it.
	# The two ends are separate substitutions: as one alternation,
	# s/\A\s+|\s+\z//g, the second branch is tried at every position of
	# every inner run of white space and rescans the run each time, which is
	# quadratic in its length; on its own Perl anchors it at the end.
	my $copy = defined $text ? $text : '';
	$copy =~ s/\A\s+//;
	$copy =~ s/\s+\z//;

	return $copy;
}

# _place_text
# Purpose:     Render a place ([key, args]) into the words of an error message.
# Entry:       $place - an array reference of a catalogue key and its
#              arguments, or a plain string (rendered as itself).  An
#              argument that is itself a place is rendered first, which is
#              how "env of a step in job 'test'" is built from two keys.
# Exit status: Returns the rendered string.
# Side effects: None.
sub _place_text {
	my ($place) = @_;

	# A string is accepted too, so a caller that already has the words can
	# pass them without inventing a catalogue key.
	my $text = defined $place ? "$place" : '';

	if (ref $place eq 'ARRAY') {
		my ($key, $args) = @{$place};
		my %rendered = map { $_ => (ref $args->{$_} eq 'ARRAY' ? _place_text($args->{$_}) : $args->{$_}) }
			keys %{ $args || {} };
		$text = App::Actions::I18N->shared->message($key, \%rendered);
	}

	return $text;
}

# Every _name routine above may be called only from this package.
# Sub::Private's mode is process-wide, so it is set to enforce for this one
# call rather than for good, which would change how other modules' :Private
# routines behave.
BEGIN {
	local $Sub::Private::config{mode} = 'enforce';
	Sub::Private->import(@{ App::Actions::Access->private_names(__PACKAGE__) });
}

1;

__END__

=head1 LIMITATIONS

=over 4

=item * On Perl older than 5.36, YAML::PP loads C<true> and C<false> as
C<1> and C<''>, which are indistinguishable from the number and the empty
string, so L</stringify> cannot write them as C<true> and C<false> there.
That is the reason the distribution recommends 5.36 for workflows that use
boolean matrix values.

=item * L</normalize_step> checks shape, not meaning: an unknown key, or a
C<uses> that names no real action, is reported later by the run.

=item * L</load_yaml_mapping> reads the whole file into memory; workflow and
action files are small, and streaming would buy nothing.

=back

=head1 COMMON PITFALLS

=over 4

=item * B<A place is not a sentence.>  Pass C<['where.job', { job =E<gt>
'test' }]>, not C<"in job test">.  A plain string works, but it is not
translated.

=item * B<C<mapping> returns a I<shallow> copy.>  Changing a value inside
it that is itself a reference changes the original too.

=item * B<Booleans need Perl 5.36 or later.>  On older Perls, YAML C<true>
and C<false> are read as C<1> and C<''>, so L</stringify> writes C<1> and
the empty string.

=item * B<C<stringify> writes arrays and hashes as JSON>, with keys sorted,
not as Perl would (C<ARRAY(0x...)>).

=item * B<C<normalize_step> checks the shape only.>  A misspelt key, or a
C<uses> that names no real action, is not reported here.

=item * B<C<trim> never changes its argument.>  Use the return value:
C<$text = trim($text)>.

=back

=head1 ENCODING

L</load_yaml_mapping> reads the file as UTF-8, so every string in the
returned data is a Perl character string.  Any Unicode text is allowed in
values, including non-ASCII characters and emoji.  Keys are usually ASCII,
but need not be.  L</stringify> and L</trim> work on characters.  L</trim> always removes
ASCII white space; whether it also removes a non-ASCII space (such as a
no-break space) depends on how Perl stores the string, so do not rely on it.
A file in another encoding (such as Latin-1) is likely to fail to parse.

=head1 AUTHOR

Nigel Horne, C<njh@nigelhorne.com>

=head1 FORMAL SPECIFICATION

This section describes each routine in the Z notation, a precise
mathematical language for describing programs.  You do not need to read it
to use the module: everything here is also said in plain words in the
sections above.  It is for readers who want to check exactly what a routine
promises.

How to read it: a box names a routine.  The lines above the middle rule
declare the values it works with.  A name ending in C<?> is an input, and a
name ending in C<!> is an output.  C<ΞState> means the routine changes
nothing, and C<ΔState> means it can change the state.  The lines below the
rule are the conditions that are always true when the routine returns.

=head2 load_yaml_mapping

	KIND ::= workflow | action

	┌─ LoadYamlMapping ─────────────────────────────────
	│ ΞFileSystem
	│ file? : optional PATH
	│ kind? : KIND
	│ doc!  : KEY ⇸ VALUE
	├───────────────────────────────────────────────────
	│ file? = ⊥ ∨ file? = ⟨⟩ ⇒ raises FileRequired(kind?)
	│ file? ∉ regularFiles ⇒ raises FileMissing(kind?, file?)
	│ ¬ parses(contents(file?)) ⇒ raises ParseFailed(kind?, file?)
	│ parse(contents(file?)) = ⊥ ⇒ raises Empty(kind?, file?)
	│ parse(contents(file?)) ∉ MAPPING ⇒ raises NotMapping(kind?, file?)
	│ otherwise doc! = parse(contents(file?))
	└───────────────────────────────────────────────────

=head2 mapping

	┌─ Mapping ─────────────────────────────────────────
	│ value? : optional VALUE
	│ place? : KEY × (NAME ⇸ VALUE)
	│ copy!  : KEY ⇸ VALUE
	├───────────────────────────────────────────────────
	│ value? = ⊥ ⇒ copy! = ∅
	│ value? ∈ MAPPING ⇒ copy! = value? ∧ copy! is a new object
	│ value? ∉ MAPPING ∪ {⊥} ⇒ raises MappingInvalid(place?)
	└───────────────────────────────────────────────────

=head2 normalize_step

	STRINGFIELD == {run, uses, shell, working-directory, name, id, if}

	┌─ NormalizeStep ───────────────────────────────────
	│ step?  : VALUE
	│ place? : KEY × (NAME ⇸ VALUE)
	│ step!  : KEY ⇸ VALUE
	├───────────────────────────────────────────────────
	│ step? ∉ MAPPING ⇒ raises StepNotMapping(place?)
	│ ∃ f : STRINGFIELD | f ∈ dom step? ∧ step?(f) ≠ ⊥ • step?(f) ∈ REF
	│     ⇒ raises FieldNotString(f, place?)
	│ run ∉ dom step? ∧ uses ∉ dom step? ⇒ raises NoCommand(place?)
	│ otherwise step! = step? ⊕ {env ↦ Mapping(step?.env), with ↦ Mapping(step?.with)}
	└───────────────────────────────────────────────────

=head2 stringify

	┌─ Stringify ───────────────────────────────────────
	│ value? : optional VALUE
	│ text!  : seq CHAR
	├───────────────────────────────────────────────────
	│ value? = ⊥ ⇒ text! = ⟨⟩
	│ value? ∈ BOOLEAN ⇒ (value? ⇒ text! = "true") ∧ (¬ value? ⇒ text! = "false")
	│ value? ∈ SCALAR \ BOOLEAN ⇒ text! = value?
	│ value? ∈ REF \ BOOLEAN ⇒ text! = canonicalJSON(value?)
	└───────────────────────────────────────────────────

=head2 trim

	┌─ Trim ────────────────────────────────────────────
	│ text?  : optional seq CHAR
	│ text!  : seq CHAR
	├───────────────────────────────────────────────────
	│ text? = ⊥ ⇒ text! = ⟨⟩
	│ text? ≠ ⊥ ⇒ text! is the longest infix of text? that neither
	│             begins nor ends with white space
	└───────────────────────────────────────────────────

=head1 STATE DIAGRAM

The functions keep no state.  This is the path a document takes through
them:

	 load_yaml_mapping($file, $kind)
	          |
	          v
	+---------------------+  no name          -> KIND.file_required
	| FILE CHECKS         |  not a file       -> KIND.file_missing
	+---------------------+
	          |
	          v
	+---------------------+  not valid YAML   -> KIND.parse_failed
	| PARSE (UTF-8, keys  |  empty document   -> KIND.empty
	| kept in order)      |  not a mapping    -> KIND.not_mapping
	+---------------------+
	          |
	          v
	+---------------------+  mapping($value, $place) for env, with, ...:
	| MAPPING (top level) |  undef -> {}; a mapping -> a copy;
	+---------------------+  anything else -> mapping.invalid at $place
	          |
	          | for each step of each job
	          v
	+---------------------+  not a mapping            -> step.not_mapping
	| normalize_step      |  env/with not mappings    -> mapping.invalid
	+---------------------+  run/uses/... not strings -> step.field_not_string
	          |              neither run nor uses     -> step.no_command
	          v
	+---------------------+
	| CHECKED STEP (copy) |  values later shown with stringify / trim
	+---------------------+

	Every arrow to the right throws an App::Actions::Error with that code;
	its message names the place, in the user's language.

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Nigel Horne.

This program is released under the GNU General Public License, version 2.
See the F<LICENSE> file that comes with this distribution.
If you use it, please let me know.

=cut
