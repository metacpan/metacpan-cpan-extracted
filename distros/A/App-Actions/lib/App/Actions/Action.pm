package App::Actions::Action;

use strict;
use warnings;
use utf8;
use autodie qw(:all);

use File::Basename qw(dirname);
use File::Spec;
use JSON::PP ();
use Readonly;

use App::Actions::I18N qw(throw validate_args);
use App::Actions::Util qw(load_yaml_mapping normalize_step stringify);

use Sub::Private ();

use App::Actions::Access;

our $VERSION = '0.002.1';

# An error in an action's metadata is reported where the action was asked
# for, which is the runner step that uses it.
our @CARP_NOT = qw(App::Actions::Runner);

# The names GitHub looks for, in the order it looks for them.
Readonly::Array my @METADATA_FILES => qw(action.yml action.yaml);

# runs.using values for which a kind is named.  node12, node16, node20 and
# whatever comes next are all JavaScript.
Readonly::Scalar my $NODE_RUNTIME => qr/\Anode\d+\z/;
Readonly::Scalar my $KIND_COMPOSITE => 'composite';
Readonly::Scalar my $KIND_JAVASCRIPT => 'javascript';
Readonly::Scalar my $KIND_DOCKER => 'docker';

# The YAML words a required: input may be written with to mean true.
Readonly::Scalar my $TRUE_WORD => qr/\A(?:true|yes|1)\z/i;

# The fields of a declared input and output, with what an absent or scalar
# declaration means.  An input written as "who: world" is an optional input
# whose default is "world"; an output written as "name: value" has that value.
Readonly::Hash my %DECLARATION => (
	inputs => { scalar_field => 'default', error_key => 'action.input_invalid', list_error_key => 'action.inputs_invalid' },
	outputs => { scalar_field => 'value', error_key => 'action.output_invalid', list_error_key => 'action.outputs_invalid' },
);

=encoding utf-8

=head1 NAME

App::Actions::Action - read the metadata of a local GitHub action

=head1 SYNOPSIS

Read an action from its directory, and find out what kind it is:

	use App::Actions::Action;

	my $action = App::Actions::Action->load_from_dir('.github/actions/setup');
	print $action->kind, "\n";    # composite, javascript, docker, ...

List its inputs, and which are required:

	for my $name (sort keys %{ $action->inputs }) {
		my $input = $action->inputs->{$name};
		printf "%-10s %s default '%s'\n", $name,
			$input->{required} ? 'required' : 'optional', $input->{default};
	}

Read the steps of a composite action:

	if ($action->is_composite) {
		print $_->{run} // $_->{uses}, "\n" for @{ $action->steps };
	}

Read a metadata file by its name:

	my $action = App::Actions::Action->load('.github/actions/setup/action.yml');

=head1 DESCRIPTION

A GitHub I<action> is a reusable piece of a workflow.  A I<local> action is
one kept in the same repository, used with C<uses: ./path/to/action>.  Its
directory holds a metadata file, F<action.yml> (or F<action.yaml>), which
says:

=over 4

=item * its C<name> and C<description>;

=item * its C<inputs> (values the calling step passes with C<with:>) and
C<outputs>;

=item * how it runs (C<runs:>): as a I<composite> action (a list of steps,
like a job), as a I<JavaScript> action (a Node.js program), or as a
I<Docker> action.

=back

This module reads that file, checks its shape, and gives you the parts.  The
steps of a composite action are checked by the same code as a workflow's
steps (L<App::Actions::Util/normalize_step>), so the two follow the same
rules.

It only reads the file.  Running the action is the job of
L<App::Actions::Runner::Steps>.

=head1 METHODS

=head2 load_from_dir

Finds and parses the metadata file in an action's directory.

=head3 ARGUMENTS

=over 4

=item * C<$dir> - the action's directory.

=back

=head3 RETURNS

An C<App::Actions::Action> object.

=head3 SIDE EFFECTS

Reads the directory and the metadata file.

=head3 EXAMPLE

	my $action = App::Actions::Action->load_from_dir('.github/actions/setup');
	print $action->name, ': ', $action->description, "\n";

=head3 API SPECIFICATION

=head4 INPUT

	{ dir => { type => 'string', min => 1 } }

=head4 OUTPUT

	{ type => 'object', isa => 'App::Actions::Action' }

=head3 MESSAGES

	+-----------------------------------+------------------------------+-------------------------------+
	| Message                           | Meaning                      | Resolution                    |
	+-----------------------------------+------------------------------+-------------------------------+
	| No action directory given         | The path was undef or empty  | Pass the directory            |
	| Action directory 'D' does not     | No directory at the path     | Check the uses: path          |
	| exist                             |                              |                               |
	| No action.yml or action.yaml      | The directory has no         | Add the metadata file         |
	| found in 'D'                      | metadata                     |                               |
	+-----------------------------------+------------------------------+-------------------------------+

The messages of L</load> apply to the file that is found.

=cut

sub load_from_dir {
	my $class = shift;

	my $dir = validate_args(__PACKAGE__ . '::load_from_dir', [ { dir => $_[0] } ], {
		dir => { type => 'string', optional => 1 },
	})->{dir};

	$class->throw('action.dir_required') unless defined $dir && length $dir;
	$class->throw('action.dir_missing', { dir => $dir }) unless -d $dir;

	# GitHub prefers action.yml when both exist, so the first match wins.
	my ($file) = grep { -f } map { File::Spec->catfile($dir, $_) } @METADATA_FILES;
	$class->throw('action.no_metadata', { dir => $dir }) unless defined $file;

	return $class->load($file);
}

=head2 load

Parses a single metadata file.

=head3 ARGUMENTS

=over 4

=item * C<$file> - the path of C<action.yml> or C<action.yaml>.

=back

=head3 RETURNS

An C<App::Actions::Action> object.

=head3 SIDE EFFECTS

Reads the file.

=head3 EXAMPLE

	my $action = App::Actions::Action->load('greet/action.yml');
	if ($action->is_composite) {
		print scalar @{ $action->steps }, " steps\n";
	}

=head3 API SPECIFICATION

=head4 INPUT

	{ file => { type => 'string', min => 1 } }

=head4 OUTPUT

	{ type => 'object', isa => 'App::Actions::Action' }

=head3 MESSAGES

	+-----------------------------------+------------------------------+-------------------------------+
	| Message                           | Meaning                      | Resolution                    |
	+-----------------------------------+------------------------------+-------------------------------+
	| No action metadata file given     | The path was undef or empty  | Pass a path                   |
	| Action metadata file 'F' does not | No file at the path          | Check the path                |
	| exist                             |                              |                               |
	| Unable to parse action metadata   | The YAML is malformed        | Fix the YAML                  |
	| 'F': E                            |                              |                               |
	| Action metadata 'F' is empty      | No document in the file      | Add the metadata              |
	| Action metadata 'F' must contain  | The top level is not a       | Make it a mapping             |
	| a YAML mapping                    | mapping                      |                               |
	| Action metadata 'F' has no 'runs' | runs is missing              | Add a runs: mapping           |
	| mapping                           |                              |                               |
	| Action metadata 'F' has no        | runs.using is missing        | Add using: composite (or      |
	| 'runs.using'                      |                              | node20, docker)               |
	| Composite action 'F' has no       | A composite with no steps    | Add runs.steps                |
	| 'runs.steps' list                 |                              |                               |
	| JavaScript action 'F' has no      | A node action with no entry  | Add runs.main                 |
	| 'runs.main'                       | point                        |                               |
	| The 'inputs' of 'F' must be a     | inputs is a list or a scalar | Name each input               |
	| mapping                           |                              |                               |
	| Input 'N' of 'F' must be a        | An input is a list           | Give it description, default  |
	| mapping                           |                              | and required keys             |
	| The 'outputs' of 'F' must be a    | outputs is a list or a       | Name each output              |
	| mapping                           | scalar                       |                               |
	| Output 'N' of 'F' must be a       | An output is a list          | Give it a value key           |
	| mapping                           |                              |                               |
	+-----------------------------------+------------------------------+-------------------------------+

The step messages of L<App::Actions::Util/normalize_step> apply to every
composite step.

=head3 PSEUDOCODE

	read the file as a YAML mapping
	refuse metadata without runs, or without runs.using
	decide the kind from runs.using:
		composite needs runs.steps, which are normalised like workflow steps
		nodeN needs runs.main
		docker and anything else are recorded as given
	read the declared inputs and outputs
	return the action with its directory, names, kind and declarations

=cut

sub load {
	my $class = shift;

	my $file = validate_args(__PACKAGE__ . '::load', [ { file => $_[0] } ], {
		file => { type => 'string', optional => 1 },
	})->{file};

	my $data = load_yaml_mapping($file, 'action');

	my $runs = $data->{runs};
	$class->throw('action.no_runs', { file => $file }) unless ref $runs eq 'HASH';

	my $using = defined $runs->{using} ? lc "$runs->{using}" : '';
	$class->throw('action.no_using', { file => $file }) unless length $using;

	my ($kind, $steps) = $class->_kind_and_steps($using, $runs, $file);

	return bless {
		file => $file,
		# dirname is '.' for a bare file name, which is the directory such a
		# file is in; the action's scripts are found relative to it.
		dir => dirname($file),
		name => defined $data->{name} ? "$data->{name}" : '',
		description => defined $data->{description} ? "$data->{description}" : '',
		using => $using,
		kind => $kind,
		inputs => $class->_declarations('inputs', $data->{inputs}, $file),
		outputs => $class->_declarations('outputs', $data->{outputs}, $file),
		runs => { %{$runs} },
		steps => $steps,
	}, $class;
}

=head2 file, dir, name, description, using, kind, inputs, outputs, runs, steps

	my $kind   = $action->kind;      # composite, javascript, docker, or runs.using
	my $inputs = $action->inputs;    # { NAME => { description, required, default } }
	my $steps  = $action->steps;     # [] unless the action is composite

Read-only accessors.  C<file> is the metadata file and C<dir> the directory
it is in.  C<name> and C<description> are C<''> when the metadata has none.
C<using> is C<runs.using> in lower case.  C<inputs> maps each input to
C<description> (or undef), C<required> (0 or 1) and C<default> (a string);
C<outputs> maps each output to C<description> and C<value>.

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	file, dir, name, description, using, kind: { type => 'string' }
	inputs, outputs, runs:                     { type => 'hashref' }
	steps:                                     { type => 'arrayref' }

=head3 MESSAGES

None.

=head3 EXAMPLE

	for my $name (sort keys %{ $action->inputs }) {
		my $input = $action->inputs->{$name};
		printf "%s%s\n", $name, $input->{required} ? ' (required)' : '';
	}

=cut

sub file        { return $_[0]->{file} }
sub dir         { return $_[0]->{dir} }
sub name        { return $_[0]->{name} }
sub description { return $_[0]->{description} }
sub using       { return $_[0]->{using} }
sub kind        { return $_[0]->{kind} }
sub inputs      { return $_[0]->{inputs} }
sub outputs     { return $_[0]->{outputs} }
sub runs        { return $_[0]->{runs} }
sub steps       { return $_[0]->{steps} }

=head2 is_composite, is_javascript

	print "composite\n" if $action->is_composite;

Return 1 when the action is of that kind, else 0.

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'integer', memberof => [ 0, 1 ] }

=head3 MESSAGES

None.

=head3 EXAMPLE

	my $runner = $action->is_javascript ? 'node' : 'sh';

=cut

sub is_composite  { return $_[0]->{kind} eq $KIND_COMPOSITE ? 1 : 0 }
sub is_javascript { return $_[0]->{kind} eq $KIND_JAVASCRIPT ? 1 : 0 }

# _kind_and_steps
# Purpose:     Classify an action by runs.using and check what that kind needs.
# Entry:       $class - the invocant; $using - runs.using in lower case;
#              $runs - the runs mapping; $file - the metadata path, for messages.
# Exit status: Returns (kind, steps arrayref); throws when a composite has no
#              steps or a JavaScript action has no main.
# Side effects: None.
sub _kind_and_steps {
	my ($class, $using, $runs, $file) = @_;

	if ($using eq $KIND_COMPOSITE) {
		$class->throw('action.no_steps', { file => $file }) unless ref $runs->{steps} eq 'ARRAY';
		return ($KIND_COMPOSITE, [ map { normalize_step($_, ['where.file', { file => $file }]) } @{ $runs->{steps} } ]);
	}

	if ($using =~ $NODE_RUNTIME) {
		# main must be a non-empty plain string: it is the script node runs.
		my $main = $runs->{main};
		$class->throw('action.no_main', { file => $file }) unless defined $main && !ref $main && length $main;
		return ($KIND_JAVASCRIPT, []);
	}

	# docker, and anything GitHub may add, is recorded as given; the runner
	# decides what it can do with it.
	return ($using eq $KIND_DOCKER ? $KIND_DOCKER : $using, []);
}

# _declarations
# Purpose:     Normalise the inputs: or outputs: mapping of an action.
# Entry:       $class - the invocant; $section - 'inputs' or 'outputs';
#              $declared - the mapping as parsed (may be undef); $file - the
#              metadata path, for messages.
# Exit status: Returns a hash reference of name to normalised declaration;
#              throws when the section or an entry is not a mapping.
# Side effects: None.
sub _declarations {
	my ($class, $section, $declared, $file) = @_;

	my $rules = $DECLARATION{$section};
	return {} unless defined $declared;
	$class->throw($rules->{list_error_key}, { file => $file }) unless ref $declared eq 'HASH';

	my %normalised;
	for my $name (keys %{$declared}) {
		my $entry = $declared->{$name};

		# "name:" and "name: text" are shorthand: no declaration at all, and
		# a bare default (for an input) or value (for an output).
		if (!ref $entry) {
			$normalised{$name} = { $rules->{scalar_field} => defined $entry ? "$entry" : '' };
			$normalised{$name}{required} = 0 if $section eq 'inputs';
			next;
		}
		$class->throw($rules->{error_key}, { name => $name, file => $file }) unless ref $entry eq 'HASH';

		$normalised{$name} = {
			description => defined $entry->{description} ? "$entry->{description}" : undef,
			$rules->{scalar_field} => defined $entry->{ $rules->{scalar_field} } ? stringify($entry->{ $rules->{scalar_field} }) : '',
		};
		$normalised{$name}{required} = _boolean($entry->{required}) if $section eq 'inputs';
	}

	return \%normalised;
}

# _boolean
# Purpose:     Read a YAML required: value as 0 or 1.
# Entry:       $value - undef, a boolean, a reference, or a word.
# Exit status: Returns 1 for a true boolean, a reference, or true/yes/1 in any
#              case; otherwise 0.
# Side effects: None.
sub _boolean {
	my ($value) = @_;

	# stringify turns a YAML or JSON boolean into true/false, so one pattern
	# covers booleans and the words people write.
	return (defined $value && (ref $value && !JSON::PP::is_bool($value) || stringify($value) =~ $TRUE_WORD)) ? 1 : 0;
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

=item * Only the metadata is read.  Whether a composite step's C<uses> can be
run, or a JavaScript action's C<main> exists, is the runner's question.

=item * C<runs.pre>, C<runs.post> and their conditions are kept in C<runs>
but not interpreted here.

=item * Input names are not validated against the characters GitHub allows,
and a declared input's C<deprecationMessage> is ignored.

=item * The C<required> word list is C<true>, C<yes> and C<1>; YAML 1.1
spellings such as C<on> and C<y> are read as false.

=back

=head1 COMMON PITFALLS

=over 4

=item * B<Give the directory to L</load_from_dir>, the file to L</load>.>

=item * B<An input written as a plain value is optional.>  C<who: world>
means an optional input whose default is C<world>, not a required one.

=item * B<C<required> is true only for C<true>, C<yes> and C<1>> (in any case).  YAML 1.1
words such as C<on> and C<y> count as false.

=item * B<Defaults are always strings.>  A YAML default of C<true> is the
string C<true>, and C<3> is C<3>, as GitHub passes them.  A missing default
is the empty string, not C<undef>.

=item * B<A description may be C<undef>>, but C<name> and the action's own
C<description> are C<''> when missing.

=item * B<C<kind> may be an unknown word.>  It is C<composite>,
C<javascript> or C<docker> for those kinds, and otherwise whatever
C<runs.using> said, in lower case.  Check C<is_composite> and
C<is_javascript> rather than comparing strings.

=item * B<The returned hashes are the object's own.>  Do not change what
C<inputs>, C<outputs>, C<runs> or C<steps> return.

=back

=head1 ENCODING

The metadata file is read as UTF-8 (see L<App::Actions::Util/ENCODING>).
Names, descriptions, defaults and step commands may contain any Unicode
text, including non-ASCII characters and emoji, and are returned as Perl
character strings.  Input names should be ASCII, because they become
environment variable names (C<INPUT_NAME>) when the action runs.  The path
you pass is used as bytes.

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

=head2 load_from_dir

	┌─ LoadFromDir ─────────────────────────────────────
	│ ΞFileSystem
	│ dir?    : optional PATH
	│ action! : Action
	├───────────────────────────────────────────────────
	│ dir? ∈ {⊥, ⟨⟩} ⇒ raises DirRequired
	│ dir? ∉ directories ⇒ raises DirMissing(dir?)
	│ let found == ⟨ n : ⟨action.yml, action.yaml⟩ | dir?/n ∈ regularFiles ⟩
	│ found = ⟨⟩ ⇒ raises NoMetadata(dir?)
	│ found ≠ ⟨⟩ ⇒ action! = Load(dir?/head found)
	└───────────────────────────────────────────────────

=head2 load

	KIND ::= composite | javascript | docker | other⟨⟨STRING⟩⟩

	┌─ Load ────────────────────────────────────────────
	│ file?   : PATH
	│ action! : Action
	├───────────────────────────────────────────────────
	│ let doc == LoadYamlMapping(file?, action)
	│ doc.runs ∉ MAPPING ⇒ raises NoRuns(file?)
	│ doc.runs.using ∈ {⊥, ⟨⟩} ⇒ raises NoUsing(file?)
	│ let u == lower(doc.runs.using)
	│ u = composite ⇒ action!.kind = composite ∧ doc.runs.steps ∈ seq VALUE
	│ u ∈ node⁀DIGITS ⇒ action!.kind = javascript ∧ doc.runs.main ∈ STRING \ {⟨⟩}
	│ u = docker ⇒ action!.kind = docker
	│ otherwise action!.kind = u
	│ action!.dir = dirname(file?)
	│ action!.kind ≠ composite ⇒ action!.steps = ⟨⟩
	└───────────────────────────────────────────────────

=head2 file, dir, name, description, using, kind, inputs, outputs, runs, steps

	┌─ Accessor ────────────────────────────────────────
	│ ΞAction
	│ field? : {file, dir, name, description, using, kind, inputs, outputs, runs, steps}
	│ value! : VALUE
	├───────────────────────────────────────────────────
	│ value! = θAction.field?
	└───────────────────────────────────────────────────

=head2 is_composite, is_javascript

	┌─ IsKind ──────────────────────────────────────────
	│ ΞAction
	│ k?   : {composite, javascript}
	│ yes! : {0, 1}
	├───────────────────────────────────────────────────
	│ yes! = 1 ⇔ kind = k?
	└───────────────────────────────────────────────────

=head1 STATE DIAGRAM

An action object never changes after it is made.  Loading goes through
these steps; each check that fails throws an L<App::Actions::Error> with
the code shown:

	 load_from_dir($dir)
	        |
	        v
	+------------------+  no $dir -> action.dir_required
	| FIND METADATA    |  not a directory -> action.dir_missing
	| action.yml, then |  neither file -> action.no_metadata
	| action.yaml      |
	+------------------+
	        |
	        v   load($file)
	+------------------+  missing / bad YAML / empty / not a mapping
	| READ YAML        |  -> action.file_* , action.parse_failed, ...
	+------------------+
	        |
	        v
	+------------------+  no runs, or runs.using missing
	| READ runs.using  |  -> action.no_runs / action.no_using
	+------------------+
	        |
	        +-- composite ----> steps must be a list; each step checked
	        |                   (normalize_step)       -> action.no_steps
	        +-- nodeN -------> runs.main must be set  -> action.no_main
	        |   (javascript)
	        +-- docker -------> kept as it is
	        +-- anything else -> kind = that word
	        |
	        v
	+------------------+  inputs/outputs not a mapping, or an entry
	| READ inputs and  |  that is neither text nor a mapping
	| outputs          |  -> action.inputs_invalid, action.input_invalid, ...
	+------------------+
	        |
	        v
	+------------------+
	|   LOADED         |  read-only: file, dir, name, description, using,
	|   (immutable)    |  kind, inputs, outputs, runs, steps,
	+------------------+  is_composite, is_javascript

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Nigel Horne.

This program is released under the GNU General Public License, version 2.
See the F<LICENSE> file that comes with this distribution.
If you use it, please let me know.

=cut
