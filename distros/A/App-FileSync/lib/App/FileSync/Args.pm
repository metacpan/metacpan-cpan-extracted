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
use Readonly;
use Scalar::Util qw(looks_like_number);
use Sub::Private { mode => 'enforce' };

use App::FileSync::I18N qw(message throw strip_location);

use version; our $VERSION = version->declare('0.002.2');

our @EXPORT_OK = qw(named positional with_options);

# The schema types whose min and max bound a value; true for whole numbers.
Readonly my %NUMERIC => (integer => 1, number => 0);

# The schema types whose min and max bound a size, and how to measure it.
# A value of the wrong kind has no size: the validator's own text explains it.
Readonly my %SIZE_OF => (
	string   => sub { ref $_[0] ? undef : length $_[0] },
	arrayref => sub { ref $_[0] eq 'ARRAY' ? scalar @{ $_[0] } : undef },
	hashref  => sub { ref $_[0] eq 'HASH' ? scalar keys %{ $_[0] } : undef },
);

# A whole number as the validator accepts one.
Readonly my $INTEGER => qr/\A[-+]?\d+\z/;

# Parameter name => the command-line option it came from, while
# with_options() is running.  Not part of the API: set it through
# with_options, which restores it.
our %OPTION;

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

Side Effects: raises a catalogued C<args.*> message naming the parameter
(with the routine, or as the command-line option given to L</with_options>)
and the problem.

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

	Key               Meaning                                  Resolution
	args.unknown      an argument the schema does not name     remove it
	args.missing      a required argument is absent            supply it
	args.not_number   a number argument is not numeric         pass a number
	args.not_integer  an integer argument is not whole         pass a whole number
	args.too_small    a number below the schema's min          raise it
	args.too_large    a number above the schema's max          lower it
	args.too_short    a string shorter than min characters     lengthen it
	args.too_long     a string longer than max characters      shorten it
	args.too_few      a list or hash with fewer than min       add entries
	args.too_many     a list or hash with more than max        remove entries
	args.not_one_of   a value outside memberof                 use a listed value
	args.bad_form     a string that fails matches              fix its form
	args.invalid      any other failure, in the validator's    fix the call
	                  own words

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

=head2 with_options

Purpose: run code with argument errors naming command-line options.

Args: C<\%options> (parameter name =E<gt> option, such as
C<max_delete_percent =E<gt> '--max-delete-percent'>), C<$code>.

Returns: whatever C<$code> returns.

Side Effects: while C<$code> runs, an invalid argument with one of these
names is reported by its option (C<--max-delete-percent must be no more
than 100, not 150>) instead of by the routine and parameter
(C<Admin::repo_create: 'max_delete_percent' must be ...>).  The mapping is
restored when C<$code> returns or dies.

Usage:

	my $made = with_options({ trash_days => '--trash-days' }, sub {
		$admin->repo_create(name => $name, trash_days => $days);
	});

=head3 EXAMPLE

	with_options({ role => '--role' }, sub { $admin->client_allow(%args) });

=head3 API SPECIFICATION

=head4 INPUT

	[
		{ name => 'options', type => 'hashref' },
		{ name => 'code',    type => 'coderef' },
	]

=head4 OUTPUT

	{ type => 'any' }

=head3 MESSAGES

None of its own; see L</named>.

=head3 FORMAL SPECIFICATION

	with_options(o, c) = c()  where during c, label(p) = o(p) for p ∈ dom o
	post OPTION' = OPTION

=cut

sub with_options {
	my ($options, $code) = @_;

	local %OPTION = (%OPTION, %{$options});
	return $code->();
}

# _validate
# Purpose:     run Params::Validate::Strict and translate its failure.
# Entry:       $input is a hashref; $schema a Params::Validate::Strict schema.
# Exit:        returns the validated hashref, or raises a catalogued args.*
#              message (args.invalid with the validator's text when the cause
#              cannot be named).
# Side effects: none beyond the raise.
sub _validate :Private {
	my ($input, $schema, $routine) = @_;

	my $valid = eval { validate_strict(schema => $schema, input => $input) };
	unless ($valid) {
		my $error = $@;
		_explain($input, $schema, $routine);

		# Drop the validator's own prefix and location; the routine name says
		# where, and the rest says what.
		my $reason = strip_location($error);
		$reason =~ s/\AParams::Validate::Strict line \d+: (?:validate_strict: )?//;
		$reason =~ s/ at \S+ line \d+\.?\z//;
		throw('args.invalid', { routine => $routine, reason => $reason });
	}

	return $valid;
}

# _explain
# Purpose:     name the cause of a validation failure in catalogue terms.
# Entry:       the input, schema and routine name of a call the validator
#              refused.  The validator reports only English text, so the cause
#              is found again from the schema rather than parsed from it.
# Exit:        raises args.unknown, args.missing, args.not_number,
#              args.not_integer, args.too_small, args.too_large,
#              args.too_short, args.too_long, args.too_few, args.too_many,
#              args.not_one_of or args.bad_form; returns when none applies
#              (a rule this does not check, such as isa).
# Side effects: none beyond the raise.
sub _explain :Private {
	my ($input, $schema, $routine) = @_;

	my $what = sub {
		my $param = shift;
		return $OPTION{$param} // message('args.param', { routine => $routine, param => $param });
	};

	for my $param (sort keys %{$input}) {
		throw('args.unknown', { what => $what->($param) }) unless exists $schema->{$param};
	}

	for my $param (sort keys %{$schema}) {
		my $rule = $schema->{$param};
		next unless ref $rule eq 'HASH';
		if (!exists $input->{$param}) {
			throw('args.missing', { what => $what->($param) }) unless $rule->{optional};
			next;
		}

		my $value = $input->{$param};
		next unless defined $value;
		my $type = $rule->{type} // '';
		my %args = (what => $what->($param), value => ref $value ? ref $value : $value);

		if (exists $NUMERIC{$type}) {
			throw('args.not_integer', \%args) if $NUMERIC{$type} && (ref $value || $value !~ $INTEGER);
			throw('args.not_number', \%args) if ref $value || !looks_like_number($value);
			throw('args.too_small', { %args, min => $rule->{min} }) if defined $rule->{min} && $value < $rule->{min};
			throw('args.too_large', { %args, max => $rule->{max} }) if defined $rule->{max} && $value > $rule->{max};
		} elsif (exists $SIZE_OF{$type} && defined(my $size = $SIZE_OF{$type}->($value))) {
			my $string = !ref $value;
			if (defined $rule->{min} && $size < $rule->{min}) {
				throw('args.too_short', { %args, count => $rule->{min} }) if $string;
				throw('args.too_few', { %args, count => $rule->{min} });
			}
			if (defined $rule->{max} && $size > $rule->{max}) {
				throw('args.too_long', { %args, count => $rule->{max} }) if $string;
				throw('args.too_many', { %args, count => $rule->{max} });
			}
		}

		if (ref $rule->{memberof} eq 'ARRAY' && !ref $value && !grep { $_ eq $value } @{ $rule->{memberof} }) {
			throw('args.not_one_of', { %args, list => join(', ', @{ $rule->{memberof} }) });
		}
		if (defined $rule->{matches} && !ref $value && $value !~ $rule->{matches}) {
			throw('args.bad_form', \%args);
		}
	}

	return;
}

1;

__END__

=head1 LIMITATIONS

Validation costs about 11 microseconds per call, so it is used at entry points
that run a few times per command, not per file or per protocol frame.

Params::Validate::Strict reports a failure only as English text, so the cause
is worked out again from the schema and the input to choose a catalogue
message.  That covers C<type> (integer and number), C<min>, C<max>,
C<optional>, C<memberof> and C<matches>, and unknown arguments; anything else
(a wrong reference type, C<isa>, C<can>) falls back to C<args.invalid> with
the validator's English text.

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
