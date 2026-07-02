package App::Project::Doctor;

# This is the top-level orchestrator for the project health-check tool.
# It finds the distribution root, loads check plugins, runs them in order,
# and returns a Report containing all of the resulting findings.

use strict;
use warnings;
use autodie qw(:all);

# croak dies with the caller's file/line; carp warns at the caller's location.
use Carp qw(croak carp);
# Readonly makes constants truly immutable at runtime.
use Readonly;
# File::Spec builds OS-portable paths (handles Windows backslashes, etc.).
use File::Spec;
# dirname() extracts the parent directory from a path when walking up the tree.
use File::Basename qw(dirname);
# Params::Get normalises @_ so both hash and hashref calling styles work.
use Params::Get;
# validate_strict enforces parameter schemas and throws immediately on failure.
use Params::Validate::Strict qw(validate_strict);
use Object::Configure;	# Allow the object to be configured at runtime

our $VERSION = '0.02';

=head1 NAME

App::Project::Doctor - Unified pre-release health check for Perl CPAN distributions

=head1 VERSION

0.02

=head1 SYNOPSIS

  # Command line
  project-doctor [--check=Tests,CI] [--skip=Meta] [--fix] [PATH]

  # Programmatic
  use App::Project::Doctor;

  my $doctor = App::Project::Doctor->new(path => '/path/to/my-dist');
  my $report = $doctor->run;
  print $report->render_text;
  exit $report->exit_code;

=head1 DESCRIPTION

Orchestrates a suite of diagnostic checks against a Perl CPAN distribution,
combining L<App::Workflow::Lint>, L<App::GHGen::Generator>, L<App::makefilepl2cpanfile>
into a single interactive pre-upload tool.

Each enabled C<App::Project::Doctor::Check::*> plugin receives an
L<App::Project::Doctor::Context> and returns a list of
L<App::Project::Doctor::Finding> objects which are collected into an
L<App::Project::Doctor::Report>.

=head1 CONSTRUCTOR

=head2 new( %args )

=head3 API SPECIFICATION

=head4 Input

  path    : String    -- start path for root detection    default '.'
  checks  : ArrayRef  -- check name suffixes to run       default all
  skip    : ArrayRef  -- check names to exclude           default []
  verbose : Bool                                          default 0

=head4 Output

Blessed hashref of type C<App::Project::Doctor>.

=head1 ACCESSORS

C<path>, C<checks>, C<skip>, C<verbose> -- read-only.

=head1 METHODS

=head2 run

=head3 API SPECIFICATION

=head4 Input

None.

=head4 Output

L<App::Project::Doctor::Report>.

=head3 MESSAGES

  Code | Trigger                         | Resolution
  -----|----------------------------------|----------------------------------------
  DR01 | Cannot detect distribution root  | Run from within a distribution directory
  DR02 | A check class cannot be loaded   | Install the check's prerequisites

=head1 CHECKS

In default execution order:

  Tests           t/ exists, .t files present, prove passes
  CI              At least one CI configuration present
  GitHubActions   Workflow YAML validates via App::Workflow::Lint
  Meta            META.yml/json parsed and complete
  Pod             All .pm files have valid POD
  Dependencies    Used modules declared as prerequisites
  License         LICENSE file present and consistent with META
  Security        strict/warnings everywhere; no hardcoded secrets
  CpanReadiness   Version format, Changes, MANIFEST, README

=cut

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

# The default set of checks run when the user does not pass --check=...
# Listed in the order they run (each check has an 'order' method too).
Readonly::Array my @DEFAULT_CHECKS => qw(
	Tests
	CI
	GitHubActions
	Meta
	Pod
	Dependencies
	License
	Security
	CpanReadiness
);

# Files whose presence marks the root directory of a Perl distribution.
# Doctor walks up the directory tree looking for any of these.
Readonly::Array my @ROOT_MARKERS => qw(
	Makefile.PL
	Build.PL
	dist.ini
	cpanfile
);

# ---------------------------------------------------------------------------
# Constructor
# ---------------------------------------------------------------------------

sub new {
	my $class = shift;
	# Protect the caller's $@ from Object::Configure::configure and validate_strict,
	# both of which use eval internally and set $@ = '' on success.
	local $@;
	# validate_strict parses arguments, applies defaults, and throws on bad input.
	# It never returns undef -- failure always throws.
	my $args = validate_strict(
		args => Params::Get::get_params(undef, \@_) || {},
		schema => {
			# path: the directory to start searching from (need not be the root).
			path    => { type => 'scalar',   optional => 1, default => '.'               },
			# checks: which check plugins to run; defaults to all nine.
			checks  => { type => 'arrayref', optional => 1, default => [@DEFAULT_CHECKS] },
			# skip: check names to exclude from the run.
			skip    => { type => 'arrayref', optional => 1, default => []                },
			verbose => { type => 'scalar',   optional => 1, default => 0                 },
		},
	);
	$args = Object::Configure::configure($class, $args);
	# Wrap the validated args in a blessed reference and return it.
	return bless $args, $class;
}

# ---------------------------------------------------------------------------
# Accessors  (all read-only after construction)
# ---------------------------------------------------------------------------

# The start path passed by the caller; used by _detect_root to walk upward.
sub path    { $_[0]->{path}    }
# Arrayref of check names to run (short names like 'Tests', not full class names).
sub checks  { $_[0]->{checks}  }
# Arrayref of check names to skip.
sub skip    { $_[0]->{skip}    }
# When true, print "Running: <name>..." to STDOUT as each check starts.
sub verbose { $_[0]->{verbose} }

# ---------------------------------------------------------------------------
# Public interface
# ---------------------------------------------------------------------------

=head2 run

Detects the distro root, instantiates all enabled checks, runs them in order,
and returns an L<App::Project::Doctor::Report>.

=cut

sub run {
	my $self = shift;
	# Protect the caller's $@ from being clobbered by our internal eval blocks.
	local $@;

	# Walk up from the user-supplied path to find the distribution root.
	my $root = $self->_detect_root($self->path)
		or croak "Cannot detect a distribution root from '" . $self->path . "'";

	# Build the Context (filesystem helper) and an empty Report to fill.
	my $ctx    = $self->_build_context($root);
	my $report = $self->_build_report;

	# Run each check plugin in order and collect its findings.
	for my $check ($self->_build_checks) {
		# Show progress to the user when --verbose is on.
		printf "  Running: %s ...\n", $check->name if $self->verbose;
		my @findings;
		{
			# Isolate $@ so a check that dies doesn't corrupt the outer $@.
			local $@;
			@findings = eval { $check->check($ctx) };
			if ($@) {
				# A check that throws is carped and skipped; the run continues.
				carp sprintf("Check '%s' threw: %s", $check->name, $@);
				next;
			}
		}
		# Add whatever findings this check produced to the accumulating report.
		$report->add_findings(@findings);
	}

	# Return the completed report; the caller decides how to render/exit.
	return $report;
}

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

# Purpose:    Walk up from $start until a distribution root marker is found.
# Entry:      $start is any path (relative or absolute) inside the distribution.
# Exit:       Absolute path string of the root directory, or undef if not found.
# Side effects: None (read-only filesystem checks).
sub _detect_root {
	my ($self, $start) = @_;
	# Convert to an absolute path so dirname() terminates at the filesystem root.
	my $dir = File::Spec->rel2abs($start);
	while (1) {
		# Check each marker in the current directory.
		for my $marker (@ROOT_MARKERS) {
			return $dir if -e File::Spec->catfile($dir, $marker);
		}
		# Move one level up; stop when we reach the filesystem root (parent == dir).
		my $parent = dirname($dir);
		last if $parent eq $dir;
		$dir = $parent;
	}
	return undef;    # Searched all the way to the filesystem root, found nothing.
}

# Purpose:    Create the Context object that check plugins use for file I/O.
# Entry:      $root is the absolute path to the distribution root directory.
# Exit:       App::Project::Doctor::Context object.
# Side effects: Loads Context module if not already in memory.
sub _build_context {
	my ($self, $root) = @_;
	require App::Project::Doctor::Context;
	return App::Project::Doctor::Context->new(root => $root, verbose => $self->verbose);
}

# Purpose:    Create an empty Report to accumulate findings into.
# Entry:      None.
# Exit:       App::Project::Doctor::Report object.
# Side effects: Loads Report module if not already in memory.
sub _build_report {
	require App::Project::Doctor::Report;
	return App::Project::Doctor::Report->new;
}

# Purpose:    Load, instantiate, and sort the enabled check plugins.
# Entry:      self->checks and self->skip are already validated lists.
# Exit:       List of check objects sorted ascending by their ->order value.
# Side effects: Loads Check::Base and each check module; carps on load failure.
sub _build_checks {
	my $self  = shift;
	# Build a set of lower-cased names to skip for case-insensitive matching.
	my %skip  = map { lc($_) => 1 } @{ $self->skip };
	my @built;

	# Check::Base must be loaded before calling ->new on any check subclass
	# because the subclasses use 'use parent -norequire' which suppresses auto-load.
	require App::Project::Doctor::Check::Base;

	for my $name (@{ $self->checks }) {
		# Honour the skip list before doing any expensive loading.
		next if $skip{ lc($name) };
		# Security guard: only allow names matching the safe identifier pattern.
		# This prevents check names like '../Exploit' from reaching the string eval.
		unless ($name =~ /\A[A-Za-z][A-Za-z0-9]*\z/) {
			carp "Check name '$name' contains invalid characters -- skipping";
			next;
		}
		# Build the full class name from the short name and load it dynamically.
		my $class = "App::Project::Doctor::Check::$name";
		eval "require $class";    ## no critic (ProhibitStringyEval)
		if ($@) {
			# Missing or broken check module: warn and skip rather than aborting the run.
			carp "Could not load '$class': $@";
			next;
		}
		push @built, $class->new;
	}

	# Sort by the numeric 'order' value so checks run in the intended sequence.
	return sort { $a->order <=> $b->order } @built;
}

1;

__END__

=head1 LIMITATIONS

Checks run sequentially; no parallelism.

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 SEE ALSO

=over 4

=item * L<Configure an Object at Runtime|Object::Configure>

=item * L<Test Dashboard|https://nigelhorne.github.io/App-Project-Doctor/coverage/>

=back

=head1 REPOSITORY

L<https://github.com/nigelhorne/App-Project-Doctor>

=head1 SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to C<bug-cgi-info at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Project-Doctor>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc App::Project::Doctor

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/dist/App-Project-Doctor>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Project-Doctor>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=App-Project-Doctor>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=App::Project::Doctor>

=back

=head1 FORMAL SPECIFICATION

=head2 doctor

  Doctor == { path : Path, checks : [Name], skip : [Name], verbose : Bool }

  run : Doctor -> Report
  run d ==
    let root    = detect_root (path d)
        ctx     = Context { root, verbose = verbose d }
        enabled = sort_by_order (checks d \\ skip d)
    in  Report { concat [ check c ctx | c <- enabled ] }

  detect_root : Path -> Path | undefined
  detect_root p == nearest ancestor of p containing a ROOT_MARKER

=head1 LICENSE

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
