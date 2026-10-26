package App::FileSync::Args;

# One place that turns a routine's @_ into a validated hashref, so every public
# entry point reads its arguments the same way and reports a bad one with a
# catalogued message instead of the validator's own text.

use App::FileSync::Platform;

use strict;
use warnings;
use autodie qw(:all);

use Exporter qw(import);
use Params::Get qw(get_params);
use Params::Validate::Strict qw(validate_strict);
use Sub::Private { mode => 'enforce' };

use App::FileSync::I18N qw(throw strip_location);

use version; our $VERSION = version->declare('0.001.5');

our @EXPORT_OK = qw(named positional);

# Errors should point at the caller of the routine whose arguments were bad.
$Carp::Internal{ (__PACKAGE__) }++;

=encoding utf8

=head1 NAME

App::FileSync::Args - validated arguments for App::FileSync's public routines

=head1 SYNOPSIS

	use App::FileSync::Args qw(named positional);

	sub repo_create {
		my $self = shift;
		my $args = named(\@_, {
			name       => { type => 'string', min => 1 },
			trash_days => { type => 'integer', min => 0, optional => 1 },
		}, 'repo_create');
		...
	}

	sub load_repo {
		my $args = positional(\@_, [qw(root repo)], {
			root => { type => 'string', min => 1 },
			repo => { type => 'string', min => 1 },
		}, 'load_repo');
	}

=head1 FUNCTIONS

=head2 named

Purpose: validate C<key =E<gt> value> arguments (or a single hashref).

Args: C<\@args>, C<\%schema> (L<Params::Validate::Strict> format), C<$routine>
(the name used in an error).

Returns: a hashref of validated (and coerced) arguments.  An empty argument
list is an empty hash.

Side Effects: raises C<args.invalid> naming the routine and the problem.

Usage:

	my $args = named(\@_, $SCHEMA, 'verify');

=head3 EXAMPLE

	my $args = named([ deep => 1 ], { deep => { type => 'boolean', optional => 1 } }, 'verify');

=head3 API SPECIFICATION

=head4 INPUT

	[
		{ name => 'args',    type => 'arrayref' },
		{ name => 'schema',  type => 'hashref' },
		{ name => 'routine', type => 'string', min => 1 },
	]

=head4 OUTPUT

	{ type => 'hashref' }

=head3 MESSAGES

	Key            Meaning                                     Resolution
	args.invalid   an argument is missing, unknown or invalid  fix the call

=head3 FORMAL SPECIFICATION

	named : seq VALUE × SCHEMA × NAME ↛ (KEY ⇸ VALUE)
	pre  pairs(args) satisfies schema
	post result = coerce(pairs(args))

=cut

sub named {
	my ($args, $schema, $routine) = @_;

	my $input = @{$args} ? get_params(undef, $args) : {};
	return _validate($input, $schema, $routine);
}

=head2 positional

Purpose: validate positional arguments by naming them.

Args: C<\@args>, C<\@names> (one per position), C<\%schema>, C<$routine>.

Returns: a hashref keyed by C<@names>; missing trailing arguments are
C<undef> and must be C<optional> in the schema.

Side Effects: raises C<args.invalid>.

Usage:

	my $args = positional(\@_, [qw(root repo)], $SCHEMA, 'load_repo');

=head3 EXAMPLE

	my $args = positional([ '/srv', 'docs' ], [qw(root repo)],
		{ root => { type => 'string' }, repo => { type => 'string' } }, 'load_repo');

=head3 API SPECIFICATION

=head4 INPUT

	[
		{ name => 'args',    type => 'arrayref' },
		{ name => 'names',   type => 'arrayref', min => 1 },
		{ name => 'schema',  type => 'hashref' },
		{ name => 'routine', type => 'string', min => 1 },
	]

=head4 OUTPUT

	{ type => 'hashref' }

=head3 MESSAGES

	Key            Meaning                                     Resolution
	args.invalid   an argument is missing or invalid           fix the call

=head3 FORMAL SPECIFICATION

	positional(a, n, s, r) = named(zip(n, a), s, r)
	pre #a ≤ #n

=cut

sub positional {
	my ($args, $names, $schema, $routine) = @_;

	# Map by position directly: get_params treats a lone hashref argument as
	# named pairs, which is wrong for a positional routine that takes one.
	my %input;
	@input{ @{$names} } = @{$args};
	delete @input{ grep { !defined $input{$_} } keys %input };

	return _validate(\%input, $schema, $routine);
}

# _validate
# Purpose:     run Params::Validate::Strict and translate its failure.
# Entry:       $input is a hashref; $schema a Params::Validate::Strict schema.
# Exit:        returns the validated hashref, or raises args.invalid.
# Side effects: none beyond the raise.
sub _validate :Private {
	my ($input, $schema, $routine) = @_;

	my $valid = eval { validate_strict(schema => $schema, input => $input) };
	unless ($valid) {
		# Drop the validator's own prefix and location; the routine name says
		# where, and the rest says what.
		my $reason = strip_location($@);
		$reason =~ s/\AParams::Validate::Strict line \d+: (?:validate_strict: )?//;
		$reason =~ s/ at \S+ line \d+\.?\z//;
		throw('args.invalid', { routine => $routine, reason => $reason });
	}

	return $valid;
}

1;

__END__

=head1 LIMITATIONS

Validation costs about 11 microseconds per call, so it is used at entry points
that run a few times per command, not per file or per protocol frame.  The
validator's reason text is English whatever the catalogue language.

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
