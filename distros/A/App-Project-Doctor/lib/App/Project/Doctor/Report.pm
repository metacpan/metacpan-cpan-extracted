package App::Project::Doctor::Report;

# A Report aggregates all Finding objects produced by check plugins and
# renders them as human-readable text, machine-readable JSON, or TAP output
# for CI pipelines.  It also tracks the overall pass/fail exit code.

use strict;
use warnings;
use autodie qw(:all);

# croak dies at the caller's location; carp warns there.
use Carp qw(croak carp);
# Readonly prevents accidental mutation of constants after they are defined.
use Readonly;
# blessed() lets us confirm that add_findings() received real Finding objects.
use Scalar::Util qw(blessed);
# validate_strict enforces parameter schemas; not used by new() (takes no args).
use Params::Validate::Strict qw(validate_strict);

our $VERSION = '0.02';

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

# The icons shown at the start of each text-report line, keyed by severity.
Readonly::Hash my %ICON => (
	pass    => '[v]',    # Healthy -- no action needed
	error   => '[X]',    # Broken -- must be fixed
	warning => '[!]',    # Suspicious -- should be reviewed
	info    => '[i]',    # Informational -- no action needed
);

# Numeric rank used to pick the "worst" severity in a group of findings.
# Higher number = more severe; error is always the worst.
Readonly::Hash my %SEV_RANK => (error => 3, warning => 2, info => 1, pass => 0);

# The column width reserved for the check name in the text report.
# Chosen to accommodate the longest default check name ('CpanReadiness' = 13 chars).
Readonly::Scalar my $LABEL_WIDTH => 18;

# ---------------------------------------------------------------------------
# Constructor
# ---------------------------------------------------------------------------

sub new {
	# Report takes no constructor arguments; start with an empty findings list.
	my ($class, %args) = @_;
	return bless { _findings => [] }, $class;
}

# ---------------------------------------------------------------------------
# Mutator
# ---------------------------------------------------------------------------

=head2 add_findings( @findings )

Appends one or more L<App::Project::Doctor::Finding> objects.
Croaks on non-Finding arguments.

=cut

sub add_findings {
	my ($self, @findings) = @_;
	for my $f (@findings) {
		# Validate each element to catch bugs where a check returns a string
		# or undef instead of a real Finding object.
		croak 'Expected an App::Project::Doctor::Finding'
			unless blessed($f) && $f->isa('App::Project::Doctor::Finding');
		push @{ $self->{_findings} }, $f;
	}
	# Return $self so callers can chain: $report->add_findings(...)->render_text.
	return $self;
}

# ---------------------------------------------------------------------------
# Accessors / filters
# ---------------------------------------------------------------------------

# Return every finding in insertion order (used by render_* methods).
sub all_findings { @{ $_[0]->{_findings} } }
# Return only the findings with severity 'error'.
sub errors       { grep { $_->severity eq 'error'   } @{ $_[0]->{_findings} } }
# Return only the findings with severity 'warning'.
sub warnings     { grep { $_->severity eq 'warning' } @{ $_[0]->{_findings} } }
# Return only the findings with severity 'pass'.
sub passes       { grep { $_->severity eq 'pass'    } @{ $_[0]->{_findings} } }
# Return only the findings that carry an automated fix coderef.
sub fixable      { grep { $_->is_fixable             } @{ $_[0]->{_findings} } }

# has_errors returns 1/0 (not just truthy) for type-safe callers.
sub has_errors   { (scalar($_[0]->errors)   > 0) ? 1 : 0 }
sub has_warnings { (scalar($_[0]->warnings) > 0) ? 1 : 0 }

=head2 exit_code

Returns 0 (clean) or 1 (errors present).

=cut

# The process should exit 1 if any finding is an error, 0 otherwise.
sub exit_code { $_[0]->has_errors ? 1 : 0 }

# ---------------------------------------------------------------------------
# Rendering
# ---------------------------------------------------------------------------

=head2 render_text( %opts )

Returns the full text report.  Accepted options: C<verbose> (bool).

=cut

sub render_text {
	my ($self, %opts) = @_;
	# verbose mode adds per-finding detail lines under each check summary.
	my $verbose = $opts{verbose} // 0;

	# Group findings by check name while preserving the insertion order of
	# the first finding seen for each check.  This keeps the output stable.
	my (%by_check, @order);
	for my $f ($self->all_findings) {
		my $name = $f->check_name;
		unless (exists $by_check{$name}) {
			# First time we see this check name -- record its position.
			push @order, $name;
			$by_check{$name} = [];
		}
		push @{ $by_check{$name} }, $f;
	}

	# Build the output one line at a time and join at the end.
	my @lines;
	for my $name (@order) {
		my @group = @{ $by_check{$name} };
		# Choose the worst severity in this group to pick the icon.
		my $sev   = _worst_severity(\@group);
		my $icon  = $ICON{$sev};    # Severity is always valid; no fallback needed.

		# Use the first non-pass finding as the summary line for mixed groups.
		my ($lead) = grep { $_->severity ne 'pass' } @group;
		my $summary = $lead ? $lead->message : $group[0]->message;

		# Format: icon  check-name (padded)  summary message
		push @lines, sprintf('  %-4s  %-*s  %s', $icon, $LABEL_WIDTH, $name, $summary);

		if ($verbose) {
			# In verbose mode, print each non-pass finding with its detail.
			for my $f (@group) {
				# Skip pass findings in verbose mode -- they have no useful detail.
				next if $f->severity eq 'pass';
				push @lines, sprintf('        -> %s', $f->message);
				# Only print the detail line when there is something to show.
				push @lines, sprintf('           %s', $f->detail) if $f->detail;
			}
		}
	}

	# Print a one-line summary of error/warning counts below the check table.
	my $ec = scalar($self->errors);
	my $wc = scalar($self->warnings);
	push @lines, '';    # Blank line before the summary.
	push @lines, $ec || $wc
		? join(' - ', ($ec ? "$ec error(s)" : ()), ($wc ? "$wc warning(s)" : ()))
		: 'No errors or warnings.';

	# If there are fixable findings, show them and hint that the user can apply them.
	my @fixable = $self->fixable;
	if (@fixable) {
		push @lines, '';
		push @lines, 'Suggested fixes:';
		my $i = 0;
		# Number each fix starting at 1 for the interactive prompt that follows.
		push @lines, sprintf('  [%d] %s', ++$i, $_->message) for @fixable;
		push @lines, '';
		push @lines, 'Would you like me to apply them? [Y/n]';
	}

	# Join with newlines and add a trailing newline for clean shell output.
	return join("\n", @lines) . "\n";
}

=head2 render_json

Returns findings as a pretty-printed JSON string (requires L<JSON::MaybeXS>).

=cut

sub render_json {
	my $self = shift;
	# JSON::MaybeXS is loaded lazily so it is only required when --format=json.
	require JSON::MaybeXS;
	# canonical => 1 sorts keys so the output is diff-friendly.
	return JSON::MaybeXS->new(utf8 => 1, pretty => 1, canonical => 1)
	                    ->encode([ map { $_->to_hash } $self->all_findings ]);
}

=head2 render_tap

Returns a TAP-format string for CI pipeline consumption.

=cut

sub render_tap {
	my $self     = shift;
	my @findings = $self->all_findings;
	# TAP header declares how many tests will follow.
	my @lines    = ('1..' . scalar @findings);
	my $n        = 0;
	for my $f (@findings) {
		$n++;
		# pass and info severities are "ok"; error and warning are "not ok".
		my $ok = $f->severity =~ /^(?:pass|info)$/ ? 'ok' : 'not ok';
		push @lines, sprintf('%s %d - [%s] %s', $ok, $n, $f->check_name, $f->message);
	}
	return join("\n", @lines) . "\n";
}

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

# Purpose:    Find the most severe severity string in a group of findings.
# Entry:      $group is a non-empty arrayref of Finding objects.
# Exit:       String -- one of 'error', 'warning', 'info', 'pass'.
# Side effects: None.
sub _worst_severity {
	my $group = shift;
	# Sort by numeric rank (descending) and take the first (= highest) value.
	return (sort { $SEV_RANK{$b} <=> $SEV_RANK{$a} } map { $_->severity } @{$group})[0];
}

1;

__END__

=head1 NAME

App::Project::Doctor::Report - Aggregate and render diagnostic findings

=head1 VERSION

0.02

=head1 SYNOPSIS

  use App::Project::Doctor::Report;

  my $report = App::Project::Doctor::Report->new;
  $report->add_findings(@findings);
  print $report->render_text(verbose => 1);
  exit $report->exit_code;

=head1 DESCRIPTION

Collects L<App::Project::Doctor::Finding> objects from all checks and renders
them as text, JSON, or TAP.

=head1 CONSTRUCTOR

=head2 new

Creates an empty report ready to receive findings.

=head3 API SPECIFICATION

=head4 Input

None.

=head4 Output

Blessed hashref of type C<App::Project::Doctor::Report>.

=head3 FORMAL SPECIFICATION

  new : () -> Report
  new () == { findings : [] }

=head1 METHODS

=head2 add_findings( @findings )

=head3 API SPECIFICATION

=head4 Input

  @findings : List of App::Project::Doctor::Finding

=head4 Output

Returns C<$self> for chaining.  Croaks if any element is not an
C<App::Project::Doctor::Finding>.

=head2 all_findings

Returns every accumulated Finding in insertion order.

=head3 API SPECIFICATION

=head4 Input

None.

=head4 Output

List of C<App::Project::Doctor::Finding>.

=head2 errors / warnings / passes

Return the subset of accumulated findings with the matching severity.

=head3 API SPECIFICATION

=head4 Input

None.

=head4 Output

List of C<App::Project::Doctor::Finding>.

=head2 fixable

Returns findings that carry an automated fix coderef.

=head3 API SPECIFICATION

=head4 Input

None.

=head4 Output

List of C<App::Project::Doctor::Finding>.

=head2 has_errors

Returns 1 when the report contains at least one error-severity finding, 0 otherwise.

=head3 API SPECIFICATION

=head4 Input

None.

=head4 Output

Integer 1 or 0.

=head2 has_warnings

Returns 1 when the report contains at least one warning-severity finding, 0 otherwise.

=head3 API SPECIFICATION

=head4 Input

None.

=head4 Output

Integer 1 or 0.

=head2 exit_code

=head3 API SPECIFICATION

=head4 Input

None.

=head4 Output

Integer 0 or 1.

=head2 render_text( %opts )

=head3 API SPECIFICATION

=head4 Input

  verbose : Bool  default 0

=head4 Output

String.

=head2 render_json

=head3 API SPECIFICATION

=head4 Input

None.

=head4 Output

UTF-8 JSON string.

=head2 render_tap

=head3 API SPECIFICATION

=head4 Input

None.

=head4 Output

TAP string.

=head3 MESSAGES

  Code | Trigger | Resolution
  -----|---------|----------
  (none currently defined)

=head3 FORMAL SPECIFICATION

  Report == { findings : [Finding] }

  all_findings : Report -> [Finding]
  all_findings r == findings r

  errors : Report -> [Finding]
  errors r == { f in findings r | severity f = error }

  warnings : Report -> [Finding]
  warnings r == { f in findings r | severity f = warning }

  passes : Report -> [Finding]
  passes r == { f in findings r | severity f = pass }

  fixable : Report -> [Finding]
  fixable r == { f in findings r | is_fixable f }

  has_errors : Report -> Bool
  has_errors r == |errors r| > 0

  has_warnings : Report -> Bool
  has_warnings r == |warnings r| > 0

  exit_code : Report -> {0,1}
  exit_code r == if has_errors r then 1 else 0

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 LICENSE

Copyright (C) 2026 Nigel Horne.
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
