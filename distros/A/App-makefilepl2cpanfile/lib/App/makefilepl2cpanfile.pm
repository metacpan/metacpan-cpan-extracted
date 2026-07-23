package App::makefilepl2cpanfile;

use strict;
use warnings;
use autodie qw(:all);
use Carp qw(croak carp);
use Readonly;
use List::Util    qw(any);
use Scalar::Util  qw(looks_like_number);
use Path::Tiny;
use Params::Get;
use YAML::Tiny;
use File::HomeDir;

=head1 NAME

App::makefilepl2cpanfile - Convert Makefile.PL to a cpanfile automatically

=head1 VERSION

=cut

our $VERSION = '0.03';

# -----------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------

# Default author/developer tools added to the 'develop' phase when
# with_develop is true and no user config file overrides them.
Readonly my %DEFAULT_DEVELOP => (
	'Devel::Cover'        => 0,
	'Perl::Critic'        => 0,
	'Test::Pod'           => 0,
	'Test::Pod::Coverage' => 0,
);

# Maps each Makefile.PL simple-dependency key to its cpanfile phase name.
# All of these are treated as 'requires' relationships.
Readonly my %PHASE_MAP => (
	BUILD_REQUIRES     => 'build',
	CONFIGURE_REQUIRES => 'configure',
	PREREQ_PM          => 'runtime',
	TEST_REQUIRES      => 'test',
);

# Valid cpanfile phase names recognised inside 'prereqs => { ... }' blocks.
Readonly my %VALID_PHASE => map { $_ => 1 }
	qw(runtime configure build test develop);

# Valid cpanfile relationship keywords inside each phase block.
Readonly my %VALID_REL => map { $_ => 1 }
	qw(requires recommends suggests);

# Canonical emit order for non-runtime phases (runtime is special-cased at
# the top level per cpanfile convention).
Readonly my @PHASE_ORDER => qw(configure build test develop);

# Within each phase block, emit relationships in this order.
Readonly my @REL_ORDER => qw(requires recommends suggests);

=head1 SYNOPSIS

	use App::makefilepl2cpanfile;

	my $cpanfile_text = App::makefilepl2cpanfile::generate(
		makefile     => 'Makefile.PL',
		existing     => '',   # optional: existing cpanfile text to merge
		with_develop => 1,    # include author/developer dependencies
	);

	path('cpanfile')->spew_utf8($cpanfile_text);

=encoding utf-8

=head1 DESCRIPTION

Parses a C<Makefile.PL> file B<without evaluating it> and produces a
C<cpanfile> string containing:

=over 4

=item * Runtime dependencies (C<PREREQ_PM>)

=item * Build, test, and configure requirements (C<BUILD_REQUIRES>,
C<TEST_REQUIRES>, C<CONFIGURE_REQUIRES>)

=item * Structured C<prereqs =E<gt> { phase =E<gt> { rel =E<gt> { ... } } }>
blocks (CPAN Meta Spec format), including C<recommends> and C<suggests>
relationships

=item * Inline comments attached to dependency entries

=item * Optional author/development dependencies in a C<develop> block

=back

=head1 CONFIGURATION

An optional YAML file at C<~/.config/makefilepl2cpanfile.yml> overrides
the default develop-phase tools:

	develop:
	  Perl::Critic: 0
	  Devel::Cover: 0
	  My::Extra::Tool: '1.00'

=head1 DATA STRUCTURE

C<parse_prereqs()> and the internal pipeline use a three-level hashref:

	{
	  phase_name => {
	    relationship => {
	      'Module::Name' => { version => '1.0', comment => 'why it is needed' },
	    },
	  },
	}

C<phase_name> ∈ { runtime, configure, build, test, develop }.
C<relationship> ∈ { requires, recommends, suggests }.
C<version> is C<0> when no minimum is declared.
C<comment> is C<undef> when no inline comment was present.

=head1 METHODS

=head2 generate(%args)

Parses a C<Makefile.PL> and returns a complete C<cpanfile> string.

=head3 PSEUDOCODE

	1. Validate and normalise arguments; croak if makefile is unreadable.
	2. Slurp makefile content; extract MIN_PERL_VERSION.
	3. Call parse_prereqs() to build the phase/rel/module/entry structure.
	4. If an existing cpanfile string was supplied, merge its 'develop'
	   block (all relationships) without overwriting freshly-parsed entries.
	5. If with_develop: load user config (or built-in defaults) and inject
	   missing 'requires' develop tools — never overwrite explicit entries.
	6. Delegate to _emit() and return the formatted string.

=head3 API SPECIFICATION

	Arguments (named hash or single hashref):
	  makefile     Str   Path to Makefile.PL.  Default: 'Makefile.PL'
	  existing     Str   Existing cpanfile text to merge.  Default: ''
	  with_develop Bool  Inject default dev tools.  Default: 1 (true)

	Returns: Str — complete cpanfile text, terminated with a single newline.

=head3 EXAMPLE

	# Minimal usage — generate from the project's own Makefile.PL
	my $out = App::makefilepl2cpanfile::generate();
	path('cpanfile')->spew_utf8($out);

	# Preserve hand-curated develop entries from an existing cpanfile
	my $out = App::makefilepl2cpanfile::generate(
		makefile => 'dist/Makefile.PL',
		existing => path('cpanfile')->slurp_utf8,
	);

=head3 MESSAGES

	"Cannot read '$makefile'"
	    The supplied path does not exist, is a directory, or is not readable.
	    Resolution: verify the path and filesystem permissions.

	"Failed to parse $cfg_file: ..."
	    The user config file exists but contains invalid YAML.
	    Resolution: validate the YAML syntax; or delete the file to use defaults.

	"No 'develop' key found in $cfg_file; using defaults"
	    The config file exists but lacks a 'develop' section.
	    Resolution: add a develop: block, or delete the file to use defaults.

=cut

sub generate {
	# Accept both flat hash and single-hashref calling styles.
	my $args = Params::Get::get_params(undef, \@_);

	my $makefile = $args->{makefile}     // 'Makefile.PL';
	my $existing = $args->{existing}     // '';
	my $with_dev = $args->{with_develop} // 1;

	croak "Cannot read '$makefile'" unless -f $makefile && -r _;

	my $content  = path($makefile)->slurp_utf8;
	my $min_perl = _parse_min_perl($content);
	my $deps     = parse_prereqs($content);

	# Merge the develop block from a pre-existing cpanfile so that
	# hand-curated entries (all relationship types) survive regeneration.
	# The closing '}; ' is anchored to the start of a line (/m) so that
	# an inline comment containing '}; ' does not terminate the match early,
	# silently dropping any module entries that follow the comment.
	if ($existing =~ /on\s+["']develop["']\s*=>\s*sub\s*\{(.*?)^[ \t]*};/ms) {
		my $dev_block = $1;
		for my $rel (@REL_ORDER) {
			# \Q$rel\E: quote metacharacters defensively (rel is a constant word,
			# but interpolation without quoting is a static-analysis red flag).
			# [^'"\n]++ possessive: never cross a line boundary when capturing a
			# module name or version, and commit immediately — no backtracking into
			# individual chars needed once the quote is closed.
			while ($dev_block =~ /\b\Q$rel\E\s+['"]([^'"\n]++)['"](?:\s*,\s*['"]([^'"\n]*+)['"])?/g) {
				# Save immediately: the inner validation regex below has no capturing
				# groups, so running it directly against $1 would reset $1/$2 to
				# undef — the classic "inner match clobbers outer capture vars" bug.
				my ($mod, $ver) = ($1, $2);
				next unless $mod =~ /\A[A-Za-z_]\w*+(?:::\w++)*+\z/;
				$deps->{develop}{$rel}{$mod} //= { version => $ver // 0, comment => undef };
			}
		}
	}

	if ($with_dev) {
		my $config = _load_develop_config();

		# Only inject tools not already listed under any relationship.
		for my $mod (keys %{$config}) {
			my $already_present = any {
				exists $deps->{develop}{$_}{$mod}
			} @REL_ORDER;

			unless ($already_present) {
				$deps->{develop}{requires}{$mod} = {
					version => $config->{$mod},
					comment => undef,
				};
			}
		}
	}

	return _emit($deps, $min_perl);
}

=head2 parse_prereqs($content)

Extracts all dependency declarations from a C<Makefile.PL> string and
returns them structured by cpanfile phase and relationship type.  Exposed
as a public function so callers (e.g. C<bin/makefilepl2cpanfile --check>)
can reuse the parsing logic without duplicating regexes.

Both the simple C<PREREQ_PM =E<gt> { ... }> form and the structured
C<prereqs =E<gt> { phase =E<gt> { rel =E<gt> { ... } } }> form (including
those nested under C<META_MERGE>) are parsed.  Inline comments attached to
module entries are captured and preserved for round-trip fidelity.

=head3 API SPECIFICATION

	Arguments:
	  $content   Str   Raw text of a Makefile.PL

	Returns: HashRef (see L</DATA STRUCTURE>)
	  {
	    phase => {
	      rel => {
	        'Module::Name' => { version => version_str, comment => str_or_undef },
	      },
	    },
	  }
	  Absent phases/relationships are not present in the hashref.
	  version is 0 when no minimum is declared.
	  comment is undef when no inline comment was present.

=head3 EXAMPLE

	my $deps = App::makefilepl2cpanfile::parse_prereqs(
	    path('Makefile.PL')->slurp_utf8
	);

	# Iterate over all phases and relationships
	for my $phase (sort keys %{$deps}) {
	    for my $rel (sort keys %{ $deps->{$phase} }) {
	        for my $mod (sort keys %{ $deps->{$phase}{$rel} }) {
	            my $e = $deps->{$phase}{$rel}{$mod};
	            printf "%s %s %s => %s\n", $phase, $rel, $mod, $e->{version};
	        }
	    }
	}

=head3 MESSAGES

	No errors or warnings — unrecognised content is silently ignored.

=cut

sub parse_prereqs {
	my $content = $_[0];

	# The POD contract is "no errors or warnings — unrecognised content is
	# silently ignored."  Undef and references are not valid Str inputs; return
	# {} immediately to avoid "uninitialized value" and "reference used as
	# string" warnings from the pattern-match operators below.
	return {} unless defined $content && !ref $content;

	my %deps;

	# ---- Simple dependency keys (PREREQ_PM, BUILD_REQUIRES, etc.) ----
	# These always map to the 'requires' relationship in their phase.
	for my $mf_key (keys %PHASE_MAP) {
		my $phase = $PHASE_MAP{$mf_key};

		# The regex allows up to four levels of brace nesting so that unusual
		# Makefile.PL constructs (e.g. version objects) don't terminate the
		# block match prematurely.
		while ($content =~ /
			\b $mf_key \s*=>\s* \{
				( (?: [^{}]++
				    | \{ (?: [^{}]++ | \{ (?: [^{}]++ | \{ [^}]*+ \} )* \} )* \}
				  )*
				)
			\}
		/gsx) {
			_extract_pairs($1, \%deps, $phase, 'requires');
		}
	}

	# ---- Structured 'prereqs' blocks (CPAN Meta Spec style) ----
	# These can appear at the top level of WriteMakefile() or nested inside
	# META_MERGE; both are covered by searching the full content for 'prereqs'.
	while ($content =~ /
		\b prereqs \s*=>\s* \{
			( (?: [^{}]++
			    | \{ (?: [^{}]++
			         | \{ (?: [^{}]++ | \{ (?: [^{}]++ | \{ [^}]*+ \} )* \} )* \}
			      )* \}
			  )*
			)
		\}
	/gsx) {
		my $prereqs_block = $1;

		# Each direct child is a phase name mapping to a relationship hash.
		while ($prereqs_block =~ /
			\b (\w+) \s*=>\s* \{
				( (?: [^{}]++ | \{ (?: [^{}]++ | \{ [^}]*+ \} )* \} )* )
			\}
		/gsx) {
			my ($phase_name, $phase_block) = ($1, $2);
			next unless $VALID_PHASE{$phase_name};

			# Each child of the phase block is a relationship name.
			while ($phase_block =~ /
				\b (\w+) \s*=>\s* \{
					( (?: [^{}]++ | \{ [^}]*+ \} )* )
				\}
			/gsx) {
				my ($rel, $rel_block) = ($1, $2);
				next unless $VALID_REL{$rel};

				_extract_pairs($rel_block, \%deps, $phase_name, $rel);
			}
		}
	}

	return \%deps;
}

# -----------------------------------------------------------------------
# Private helpers
# -----------------------------------------------------------------------

# _extract_pairs
#
# Purpose:  Parse a raw block of text (the content between the outermost
#           braces of a dependency hash) into module/version/comment triples
#           and store them in the deps structure.  Processes line-by-line
#           so that trailing inline comments can be captured before the
#           comment text is discarded.
# Entry:    $_[0] — raw block text (between the outer braces).
#           $_[1] — hashref to populate (the top-level %deps).
#           $_[2] — phase name string (e.g. 'runtime').
#           $_[3] — relationship string (e.g. 'requires').
# Exit:     Returns nothing — mutates $_[1] in place.
# Effects:  Modifies the deps hashref; no I/O.
#
# First-occurrence-wins: if the same module appears multiple times (e.g.
# once in PREREQ_PM and once in a prereqs block), the first parsed entry
# is kept.
sub _extract_pairs {
	my ($block, $deps, $phase, $rel) = @_;

	for my $line (split /\n/, $block) {
		# Capture any trailing inline comment before stripping it.
		# (.*\S) is O(N): greedy .* scans to end, then gives back trailing
		# spaces one by one until \S anchors on the last non-space char.
		# Avoids the super-linear behaviour of (.+?)\s*$ which re-evaluates
		# \s*$ at every expanded position of the lazy quantifier.
		my ($comment) = ($line =~ /#\s*(.*\S)/);
		$line =~ s/#.*$//;

		next unless $line =~ /\S/;		# skip blank / formerly comment-only lines

		if ($line =~ /['"]([^'"]+)['"]\s*=>\s*['"]?([\d._]+)?['"]?/) {
			my ($mod, $ver) = ($1, $2);
			# Defense-in-depth: [^'"]+ already excludes quote characters, but
			# it also matches \n.  A newline in a module name produces a
			# multi-line string literal in the cpanfile.  Restrict to valid
			# Perl identifier paths to make the output unambiguously well-formed.
			next unless $mod =~ /\A[A-Za-z_]\w*+(?:::\w++)*+\z/;
			# First occurrence wins — do not overwrite already-parsed entries.
			$deps->{$phase}{$rel}{$mod} //= {
				version => $ver // 0,
				comment => $comment,
			};
		}
	}

	return;
}

# _parse_min_perl
#
# Purpose:  Extract the MIN_PERL_VERSION value from Makefile.PL text.
# Entry:    $_[0] — raw Makefile.PL content string.
# Exit:     The version string (e.g. '5.010'), or undef if not declared.
sub _parse_min_perl {
	my $content = $_[0];
	return ($content =~ /\bMIN_PERL_VERSION\b\s*=>\s*['"]?([\d._]++)['"]?/)
		? $1
		: undef;
}

# _load_develop_config
#
# Return the develop-tools hash from the user's YAML config file,
#   or %DEFAULT_DEVELOP when no config file exists.
# Entry:    None — reads from the filesystem at a well-known path.
# Exit:     HashRef { Module::Name => minimum_version_or_0 }.
# Effects:  Reads from disk. Croaks on YAML parse failure. Carps when the
#           config file lacks a 'develop' key.
sub _load_develop_config {
	my $home = File::HomeDir->my_home;

	# Guard against environments with no home directory (containers, chroots,
	# or CI systems where getpwuid returns no directory).  path(undef) would
	# croak from Path::Tiny with a confusing message; return defaults instead.
	return {%DEFAULT_DEVELOP} unless defined $home;

	my $cfg_path = path($home)
		->child('.config', 'makefilepl2cpanfile.yml');

	if ($cfg_path->is_file) {
		my $yaml = YAML::Tiny->read("$cfg_path")
			or croak "Failed to parse $cfg_path: " . YAML::Tiny->errstr();

		if (ref $yaml->[0]{develop} eq 'HASH') {
			# SECURITY: validate every key (module name) and value (version)
			# before use.  YAML config keys are arbitrary strings; without
			# this guard a key such as "Safe'; system('evil'); requires 'X"
			# closes the single-quoted literal in _fmt_dep and injects
			# executable Perl into the generated cpanfile, which cpanm eval's.
			my %clean;
			for my $mod (keys %{ $yaml->[0]{develop} }) {
				my $ver = $yaml->[0]{develop}{$mod};
				unless ($mod =~ /\A[A-Za-z_]\w*+(?:::\w++)*+\z/) {
					carp "Skipping invalid module name in $cfg_path: '$mod'";
					next;
				}
				my $v = defined $ver ? "$ver" : 0;
				unless ($v eq '0' || $v eq '' || $v =~ /\Av?[\d._]++\z/) {
					carp "Skipping invalid version for '$mod' in $cfg_path: '$v'";
					$v = 0;
				}
				$clean{$mod} = $v;
			}
			return \%clean;
		}
		carp "No 'develop' key found in $cfg_path; using defaults";
	}

	# Return a copy so callers cannot mutate the constant.
	return {%DEFAULT_DEVELOP};
}

# _emit
#
# Purpose:  Pure formatter — converts the structured dependency hash and an
#           optional minimum Perl version into a valid cpanfile string.
# Entry:    $_[0] — HashRef (see DATA STRUCTURE section in POD)
#           $_[1] — optional Str minimum Perl version (e.g. '5.010')
# Exit:     Scalar string; always terminated with exactly one newline.
#           Never returns undef.
#
# Runtime deps are emitted at the top level (no 'on' block) per cpanfile
# convention. All other phases get 'on phase => sub { ... }' blocks.
# Within each phase, relationships are emitted in @REL_ORDER order;
# modules within each relationship are sorted alphabetically.
# Inline comments are re-emitted after the semicolon on the same line.
# A version of 0 or '' means "any version" and is omitted.
sub _emit {
	my ($deps, $min_perl) = @_;

	# Build the output as a list of sections joined by blank lines.  This
	# avoids the trailing-double-newline bug that arises when a runtime-only
	# output adds a separator newline with no following phase blocks.
	my @sections;

	push @sections, '# Generated from Makefile.PL using makefilepl2cpanfile';
	push @sections, "requires 'perl', '$min_perl';" if $min_perl;

	# Runtime: emitted at the top level, not inside an 'on' block.
	if (my $rt = $deps->{runtime}) {
		my @lines;
		for my $rel (@REL_ORDER) {
			my $h = $rt->{$rel} or next;
			for my $m (sort keys %{$h}) {
				push @lines, _fmt_dep($rel, $m, $h->{$m}, '');
			}
		}
		# join without an extra newline; _fmt_dep already appends \n per line.
		push @sections, join('', @lines) if @lines;
	}

	# All other phases each get a named 'on' block.
	for my $phase (@PHASE_ORDER) {
		my $p = $deps->{$phase} or next;

		my @lines;
		for my $rel (@REL_ORDER) {
			my $h = $p->{$rel} or next;
			for my $m (sort keys %{$h}) {
				push @lines, _fmt_dep($rel, $m, $h->{$m}, "\t");
			}
		}
		next unless @lines;

		push @sections, "on '$phase' => sub {\n" . join('', @lines) . "};";
	}

	# _fmt_dep appends \n to each line, so strip trailing newlines from
	# sections before joining so the blank-line separator is exactly one \n\n.
	s/\n+$// for @sections;
	return join("\n\n", @sections) . "\n";
}

# _fmt_dep
#
# Purpose:  Format a single dependency line for cpanfile output, including
#           the optional version constraint and inline comment.
# Entry:    $_[0] — relationship keyword (e.g. 'requires', 'recommends').
#           $_[1] — module name string.
#           $_[2] — entry hashref { version => ..., comment => ... }.
#           $_[3] — indentation prefix ('' for runtime, "\t" for phase blocks).
# Exit:     A complete formatted line, including trailing newline.
sub _fmt_dep {
	my ($rel, $mod, $entry, $indent) = @_;

	my $line = "${indent}$rel '$mod'";
	$line .= ", '$entry->{version}'" if _has_version($entry->{version});

	if (defined $entry->{comment} && $entry->{comment} ne '') {
		$line .= ";   # $entry->{comment}\n";
	} else {
		$line .= ";\n";
	}

	return $line;
}

# _has_version
#
# Decide whether a version value represents a real minimum version
#	constraint that should be written into the cpanfile output.
# Entry:    $_[0] — version value (scalar, possibly undef or numeric '0').
# Exit:     Boolean: true if the version should be emitted; false if it
#           means "any version" (undef, empty string, or numeric zero).
sub _has_version {
	my $ver = $_[0];

	return 0 unless defined $ver && $ver ne '' && $ver ne '0';

	# Use looks_like_number to avoid spurious non-numeric warnings when
	# comparing against 0 — version strings are always numeric, but be safe.
	return looks_like_number($ver) ? ($ver != 0) : 1;
}

1;

__END__

=head1 LIMITATIONS

=over 4

=item * Because parsing is regex-based and the C<Makefile.PL> is never
C<eval>'d, dynamically generated dependency lists (e.g. those produced by
C<if>/C<unless> branches or subroutine calls) cannot be detected.

=item * Encapsulation enforcement (C<Sub::Private> in C<enforce> mode) is not
applied; the C<_> prefix convention is used instead.  A future release may
add C<Sub::Private> once its C<enforce>-mode API is verified.

=back

=head1 SUPPORT

This module is provided as-is without any warranty.

Bugs and feature requests:
L<https://github.com/nigelhorne/App-makefilepl2cpanfile/issues>

=head1 AUTHOR

Nigel Horne E<lt>njh@nigelhorne.comE<gt>

=head1 FORMAL SPECIFICATION

=head2 generate

	-- generate maps named arguments to a cpanfile string
	generate : Args → Str
	where
	  Args ≙ [makefile : Path; existing : Str; with_develop : 𝔹]

	generate(a) ≙
	  let content ≙ slurp(a.makefile)
	      deps    ≙ parse_prereqs(content)
	      merged  ≙ deps ⊕ {develop ↦
	                   deps.develop ∪ extract_develop(a.existing)}
	      final   ≙ if a.with_develop
	                then merged ⊕ {develop ↦
	                       {requires ↦ load_config() ▷ merged.develop.requires}}
	                else merged
	  in _emit(final, min_perl(content))
	-- (▷) right-biases toward the right operand: existing entries win.

=head2 parse_prereqs

	parse_prereqs : Str → DepMap
	where
	  DepMap    ≙ Phase ↦ (Rel ↦ (ModName ↦ Entry))
	  Entry     ≙ [version : VersionStr; comment : Str ∪ {⊥}]
	  Phase     ∈ {runtime, configure, build, test, develop}
	  Rel       ∈ {requires, recommends, suggests}

	parse_prereqs(s) ≙
	  simple_deps(s) ⊕ structured_deps(s)
	where
	  simple_deps(s)     ≙ ⋃ { extract_simple(k, s) | k ∈ dom(PHASE_MAP) }
	  structured_deps(s) ≙ ⋃ { extract_prereqs_block(b) | b ∈ prereqs_blocks(s) }

=head1 LICENCE AND COPYRIGHT

Copyright 2025-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
