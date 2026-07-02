package App::Project::Doctor::Fixer;

# The Fixer presents a numbered menu of auto-fixable findings, reads the
# user's answer from STDIN, and calls each selected fix coderef with the
# current Context.  In non-interactive mode (--fix flag) it applies all
# fixes immediately without prompting.

use strict;
use warnings;
use autodie qw(:all);

# croak dies at the caller's location; carp warns there.
use Carp qw(croak carp);
# Params::Get normalises @_ into a hashref before validate_strict sees it.
use Params::Get;
# validate_strict enforces parameter schemas and throws immediately on failure.
use Params::Validate::Strict qw(validate_strict);
# blessed() checks whether a reference is a blessed object.
use Scalar::Util qw(blessed);

our $VERSION = '0.02';

# ---------------------------------------------------------------------------
# Constructor
# ---------------------------------------------------------------------------

sub new {
	my $class = shift;

	# validate_strict with type => 'object' guarantees that report and context
	# are blessed references before we reach the isa() checks below.
	# The redundant blessed() call was removed; isa() alone is sufficient.
	my $args = validate_strict(
		schema => {
			report          => { type => 'object'                              },
			context         => { type => 'object'                              },
			non_interactive => { type => 'scalar', optional => 1, default => 0 },
		},
		args => Params::Get::get_params(undef, \@_) || {},
	);

	# isa() confirms the exact class; validate_strict only checked 'blessed'.
	croak 'report must be an App::Project::Doctor::Report'
		unless $args->{report}->isa('App::Project::Doctor::Report');
	croak 'context must be an App::Project::Doctor::Context'
		unless $args->{context}->isa('App::Project::Doctor::Context');

	# Store the validated args and return the new Fixer object.
	return bless $args, $class;
}

# ---------------------------------------------------------------------------
# Accessors  (read-only after construction)
# ---------------------------------------------------------------------------

# The Report whose fixable findings will be presented to the user.
sub report          { $_[0]->{report}          }
# The Context passed to each fix coderef so it can find files.
sub context         { $_[0]->{context}         }
# When true, all fixes are applied immediately without user prompting.
sub non_interactive { $_[0]->{non_interactive} }

# ---------------------------------------------------------------------------
# Public interface
# ---------------------------------------------------------------------------

=head2 run

Presents fixable findings, prompts (or auto-applies in non-interactive mode),
and calls each selected C<fix> coderef.  Returns the count of fixes applied.

=cut

sub run {
	my $self    = shift;
	# Collect only the findings that have an associated fix coderef.
	my @fixable = $self->report->fixable;
	# Nothing to do if no fixable findings were found.
	return 0 unless @fixable;
	# Choose the right mode: silent auto-apply vs. interactive prompt.
	return $self->non_interactive
		? $self->_apply_all(\@fixable)
		: $self->_interactive_loop(\@fixable);
}

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

# Purpose:    Print a numbered list of fixes to STDOUT.
# Entry:      $fixable is a non-empty arrayref of Finding objects.
# Exit:       Returns nothing; side-effect is printed output only.
# Side effects: Writes to STDOUT.
sub _print_fix_list {
	my $fixable = shift;
	print "\nSuggested fixes:\n";
	# Number each finding starting at 1 so the user can reference them by number.
	my $i = 0;
	printf "  [%d] %s\n", ++$i, $_->message for @{$fixable};
	return;
}

# Purpose:    Read the user's choice from STDIN and apply the selected fixes.
# Entry:      $fixable is a non-empty arrayref of Finding objects.
# Exit:       Integer count of fixes successfully applied.
# Side effects: Reads STDIN, writes STDOUT, may modify the filesystem via fix coderefs.
sub _interactive_loop {
	my ($self, $fixable) = @_;

	# Show the numbered list so the user knows what choices are available.
	_print_fix_list($fixable);
	print "\nWould you like me to apply them? [Y/n/1,3] ";

	# Read one line from the user; return 0 cleanly if STDIN is closed (e.g. in a pipe).
	my $answer = <STDIN>;
	return 0 unless defined $answer;
	chomp $answer;    # Remove the trailing newline before comparing.

	# Empty input or "yes" means apply everything.
	return $self->_apply_all($fixable)
		if $answer eq '' || $answer =~ /^y(?:es)?$/i;

	# Explicit "no" -- tell the user we skipped and return.
	if ($answer =~ /^n(?:o)?$/i) {
		print "No fixes applied.\n";
		return 0;
	}

	# A comma/space-separated list of numbers selects individual fixes.
	if ($answer =~ /^[\d,\s]+$/) {
		my $max = scalar @{$fixable};    # The highest valid index.
		my %seen;
		# Parse the numbers, clamp to valid range, and deduplicate.
		my @indices  = grep { $_ >= 1 && $_ <= $max && !$seen{$_}++ }
		               map  { int($_) }
		               split /[\s,]+/, $answer;
		# Convert 1-based user indices to 0-based array indices.
		my @selected = map { $fixable->[$_ - 1] } @indices;
		return $self->_apply_all(\@selected);
	}

	# Anything else is unrecognised; be explicit rather than guessing.
	print "Unrecognised input -- no fixes applied.\n";
	return 0;
}

# Purpose:    Call every fix coderef in the list and count the successes.
# Entry:      $fixable is an arrayref of Finding objects (may be empty).
# Exit:       Integer count of fixes that ran without throwing.
# Side effects: Calls fix coderefs (may create/modify files), writes to STDOUT on
#               success, calls carp for each failing fix.
sub _apply_all {
	my ($self, $fixable) = @_;
	my $count = 0;
	for my $f (@{$fixable}) {
		# Wrap the fix in eval so a single failure doesn't abort all remaining fixes.
		my $ok = eval { $f->fix->($self->context); 1 };
		if ($ok) {
			# Print confirmation so the user can see what changed.
			printf "  Applied: %s\n", $f->message;
			$count++;
		} else {
			# Report the failure but continue with the next fix.
			carp "Fix failed for '" . $f->message . "': $@";
		}
	}
	# Summary line always prints, even when count is 0.
	printf "\n%d fix(es) applied.\n", $count;
	return $count;
}

1;

__END__

=head1 NAME

App::Project::Doctor::Fixer - Interactive fix application loop

=head1 VERSION

0.02

=head1 SYNOPSIS

  use App::Project::Doctor::Fixer;

  my $fixer = App::Project::Doctor::Fixer->new(
      report  => $report,
      context => $ctx,
  );
  my $count = $fixer->run;

=head1 DESCRIPTION

Presents fixable findings from a report, reads the user's choice from STDIN
(C<Y> all, C<n> none, or C<1,3> index list), and calls each selected
finding's C<fix> coderef with the current context.

Set C<non_interactive =E<gt> 1> to apply all fixes without prompting
(C<--fix> mode).

=head1 CONSTRUCTOR

=head2 new( %args )

=head3 API SPECIFICATION

=head4 Input

  report          : App::Project::Doctor::Report   required (blessed, isa Report)
  context         : App::Project::Doctor::Context  required (blessed, isa Context)
  non_interactive : Bool                           default 0

=head4 Output

Blessed hashref of type C<App::Project::Doctor::Fixer>.

=head1 ACCESSORS

C<report>, C<context>, C<non_interactive> -- read-only.

=head1 METHODS

=head2 run

=head3 API SPECIFICATION

=head4 Input

None.

=head4 Output

Integer -- number of fixes successfully applied.

=head3 MESSAGES

  Code | Trigger               | Resolution
  -----|-----------------------|---------------------------------------
  F001 | A fix coderef throws  | Fix skipped; error logged via carp

=head3 FORMAL SPECIFICATION

  run : Fixer -> N
  run fixer ==
    let fixable = { f in findings (report fixer) | is_fixable f }
    in  if non_interactive fixer
        then apply_all fixable
        else apply_chosen fixable (prompt fixable)

=head1 LIMITATIONS

Reads from STDIN; use C<non_interactive =E<gt> 1> in automated pipelines.

Encapsulation of C<_interactive_loop>, C<_apply_all>, and C<_print_fix_list>
is enforced by convention only; a future migration to C<Sub::Private> in
enforce mode is tracked as a TODO.

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 LICENSE

Copyright (C) 2026 Nigel Horne.
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
