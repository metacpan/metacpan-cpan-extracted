package App::Test::Generator::Model::Method;

use strict;
use warnings;

use Carp qw(croak);
use Readonly;

Readonly my $HIGH_CONFIDENCE_THRESHOLD   => 40;
Readonly my $MEDIUM_CONFIDENCE_THRESHOLD => 20;

our $VERSION = '0.42';

=head1 NAME

App::Test::Generator::Model::Method - Evidence-based model of a single method under test

=head1 VERSION

Version 0.42

=head1 DESCRIPTION

Accumulates weighted evidence about a single method's return behaviour,
gathered independently by several analysers
(L<App::Test::Generator::Analyzer::Return> and friends), then resolves
that evidence into a best-guess return type, test classification, and
confidence level. This lets multiple independent heuristics contribute
to one final judgement instead of the first heuristic to run winning
outright.

=head2 new

Construct a new Method model.

    my $method = App::Test::Generator::Model::Method->new(
        name   => 'get_name',
        source => 'sub get_name { return $_[0]->{name}; }',
    );

=head3 Arguments

=over 4

=item * C<name>

The method's name. Required.

=item * C<source>

The method's raw Perl source text. Required.

=back

=head3 Returns

A blessed hashref with C<evidence> initialised to an empty arrayref
and C<return_type>, C<classification>, and C<confidence> initialised
to C<undef>. Croaks with C<"name required"> or C<"source required">
if either argument is missing.

=head3 API specification

=head4 input

    {
        name   => { type => SCALAR },
        source => { type => SCALAR },
    }

=head4 output

    { type => OBJECT, isa => 'App::Test::Generator::Model::Method' }

=cut

sub new {
	my ($class, %args) = @_;
	croak 'name required'   unless defined $args{name};
	croak 'source required' unless defined $args{source};

	my $self = {
		name          => $args{name},
		source        => $args{source},
		# parameters    => [],
		evidence      => [],
		return_type   => undef,
		classification => undef,
		confidence    => undef,
	};

	return bless $self, $class;
}

=head2 name

Return the method's name.

    my $name = $method->name;

=head3 Arguments

None beyond C<$self>.

=head3 Returns

The name string supplied to C<new>. Read-only — there is no setter;
C<name> ignores any extra arguments passed to it.

=head3 API specification

=head4 input

    { self => { type => OBJECT, isa => 'App::Test::Generator::Model::Method' } }

=head4 output

    { type => SCALAR }

=cut

sub name   { $_[0]->{name}   }

=head2 source

Return the method's raw source text.

    my $source = $method->source;

=head3 Arguments

None beyond C<$self>.

=head3 Returns

The source string supplied to C<new>. Read-only — there is no setter;
C<source> ignores any extra arguments passed to it.

=head3 API specification

=head4 input

    { self => { type => OBJECT, isa => 'App::Test::Generator::Model::Method' } }

=head4 output

    { type => SCALAR }

=cut

sub source { $_[0]->{source} }

=head2 return_type

Read/write accessor for the resolved return type.

    $method->return_type('object');
    my $type = $method->return_type;

=head3 Arguments

=over 4

=item * C<$val>

Optional. If supplied (including C<undef>), stores it as the new
return type.

=back

=head3 Returns

The current return type string, or C<undef> if not yet resolved (or
explicitly set back to C<undef>).

=head3 Side effects

Overwrites the stored return type when called with an argument.

=head3 API specification

=head4 input

    {
        self => { type => OBJECT, isa => 'App::Test::Generator::Model::Method' },
        val  => { type => SCALAR, optional => 1 },
    }

=head4 output

    { type => SCALAR, optional => 1 }

=cut

sub return_type {
	my ($self, $val) = @_;
	$self->{return_type} = $val if @_ > 1;
	return $self->{return_type};
}

=head2 classification

Read/write accessor for the resolved test classification.

    $method->classification('getter');
    my $class = $method->classification;

=head3 Arguments

=over 4

=item * C<$val>

Optional. If supplied (including C<undef>), stores it as the new
classification.

=back

=head3 Returns

The current classification string, or C<undef> if not yet resolved.

=head3 Side effects

Overwrites the stored classification when called with an argument.

=head3 API specification

=head4 input

    {
        self => { type => OBJECT, isa => 'App::Test::Generator::Model::Method' },
        val  => { type => SCALAR, optional => 1 },
    }

=head4 output

    { type => SCALAR, optional => 1 }

=cut

sub classification {
	my ($self, $val) = @_;
	$self->{classification} = $val if @_ > 1;
	return $self->{classification};
}

=head2 confidence

Read/write accessor for the resolved confidence hashref.

    $method->confidence({ score => 45, level => 'medium' });
    my $conf = $method->confidence;

=head3 Arguments

=over 4

=item * C<$val>

Optional. If supplied (including C<undef>), stores it as the new
confidence value.

=back

=head3 Returns

The current confidence hashref (with C<score> and C<level> keys), or
C<undef> if not yet resolved.

=head3 Side effects

Overwrites the stored confidence value when called with an argument.

=head3 API specification

=head4 input

    {
        self => { type => OBJECT, isa => 'App::Test::Generator::Model::Method' },
        val  => { type => HASHREF, optional => 1 },
    }

=head4 output

    { type => HASHREF, optional => 1 }

=cut

sub confidence {
	my ($self, $val) = @_;
	$self->{confidence} = $val if @_ > 1;
	return $self->{confidence};
}

=head2 add_evidence

Record one piece of weighted evidence about the method's behaviour.

    $method->add_evidence(
        category => 'return',
        signal   => 'returns_property',
        value    => 'name',
        weight   => 20,
    );

=head3 Arguments

=over 4

=item * C<category>

One of C<return>, C<input>, or C<effect>. Required. Croaks
C<"Invalid evidence category '...'"> for any other value, including a
missing category.

=item * C<signal>

A recognised signal name (see L</Notes>). Required. Croaks
C<"Invalid evidence signal '...'"> for any other value, including a
missing signal.

=item * C<value>

Optional. An arbitrary value associated with the signal (e.g. the
property name for C<returns_property>).

=item * C<weight>

Optional. A numeric weight. Defaults to 1.

=back

=head3 Returns

Nothing (undef).

=head3 Side effects

Appends an evidence hashref (with keys C<category>, C<signal>,
C<value>, C<weight>) to the object's internal evidence list.

=head3 Notes

Recognised signals are C<returns_property>, C<returns_constant>,
C<returns_self>, C<legacy_type>, C<context_aware>, C<error_pattern>
(intended for category C<return>); C<input_validated>, C<input_typed>,
C<input_optional> (category C<input>); and C<has_side_effect>,
C<no_side_effect> (category C<effect>). Signal validity is checked
against the full set regardless of category — passing a return-only
signal with C<category =E<gt> 'input'> does not croak.

=head3 API specification

=head4 input

    {
        self     => { type => OBJECT, isa => 'App::Test::Generator::Model::Method' },
        category => { type => SCALAR },
        signal   => { type => SCALAR },
        value    => { type => SCALAR, optional => 1 },
        weight   => { type => SCALAR, optional => 1 },
    }

=head4 output

    { type => UNDEF }

=cut

sub add_evidence {
	my ($self, %args) = @_;

	# Validate category — must be one of the three recognised kinds
	my %valid_categories = map { $_ => 1 } qw(return input effect);

	my $cat = $args{category} // '';
	croak "Invalid evidence category '$cat'" unless $valid_categories{$cat};

	# Validate signal — must be a known signal name to catch typos early.
	# Signals are per-category; we validate the full set across all categories.
	my %valid_signals = map { $_ => 1 } qw(
		returns_property returns_constant returns_self
		legacy_type context_aware error_pattern
		input_validated input_typed input_optional
		has_side_effect no_side_effect
	);

	my $sig = $args{signal} // '';
	croak "Invalid evidence signal '$sig'" unless $valid_signals{$sig};

	push @{ $self->{evidence} }, {
		category => $args{category},
		signal   => $args{signal},
		value    => $args{value},
		weight   => defined $args{weight} ? $args{weight} : 1,
	};

	return;
}

=head2 evidence

Return all recorded evidence entries.

    my @evidence = $method->evidence;
    for my $entry (@evidence) {
        print "$entry->{category}/$entry->{signal}: $entry->{weight}\n";
    }

=head3 Arguments

None beyond C<$self>.

=head3 Returns

A list of evidence hashrefs (each with keys C<category>, C<signal>,
C<value>, C<weight>), in the order they were added via
C<add_evidence>. Empty list if no evidence has been recorded. Called
in scalar context, returns the count of evidence entries.

=head3 API specification

=head4 input

    { self => { type => OBJECT, isa => 'App::Test::Generator::Model::Method' } }

=head4 output

    { type => ARRAYREF, items => { type => HASHREF } }

=cut

sub evidence {
	my $self = $_[0];
	return @{ $self->{evidence} };
}

=head2 evidence_ref

Return all recorded evidence entries as an arrayref.

    my $ref = $method->evidence_ref;
    print "count: ", scalar(@$ref), "\n";

=head3 Arguments

None beyond C<$self>.

=head3 Returns

An arrayref of the same evidence hashrefs returned by C<evidence>.
This is the live internal arrayref, not a copy — modifying it
modifies the object's evidence list.

=head3 API specification

=head4 input

    { self => { type => OBJECT, isa => 'App::Test::Generator::Model::Method' } }

=head4 output

    { type => ARRAYREF, items => { type => HASHREF } }

=cut

sub evidence_ref {
	my $self = $_[0];
	return $self->{evidence};
}

=head2 resolve_return_type

Derive a return type from the accumulated C<return>-category evidence
and store it.

    $method->add_evidence(category => 'return', signal => 'returns_self', weight => 20);
    my $type = $method->resolve_return_type;   # 'object'

=head3 Arguments

None beyond C<$self>.

=head3 Returns

One of C<object>, C<property>, or C<constant>, chosen by summing the
weight of all C<return>-category evidence into three buckets
(C<returns_self> -> object; C<returns_property>, C<context_aware>,
C<error_pattern> -> property; C<returns_constant> -> constant;
C<legacy_type> -> object or property depending on its C<value>) and
picking the highest-scoring bucket. Ties are broken alphabetically
among the tied bucket names (C<constant> E<lt> C<object> E<lt>
C<property>). With no C<return>-category evidence at all, all three
buckets score 0 and C<constant> wins the alphabetical tie-break.

=head3 Side effects

Sets C<return_type> to the resolved value.

=head3 Notes

Evidence outside the C<return> category is ignored. Evidence with an
unrecognised signal name is also ignored (this can only happen if a
caller other than C<add_evidence> populated the evidence list
directly, since C<add_evidence> itself rejects unrecognised signals).

=head3 API specification

=head4 input

    { self => { type => OBJECT, isa => 'App::Test::Generator::Model::Method' } }

=head4 output

    { type => SCALAR }

=cut

sub resolve_return_type {
	my $self = $_[0];
	my %score = (property => 0, constant => 0, object => 0);

	for my $ev (@{ $self->{evidence} }) {
		next unless $ev->{category} eq 'return';
		if($ev->{signal} eq 'returns_property') {
			$score{property} += $ev->{weight};
		} elsif($ev->{signal} eq 'returns_constant') {
			$score{constant} += $ev->{weight};
		} elsif($ev->{signal} eq 'returns_self') {
			$score{object} += $ev->{weight};
		} elsif($ev->{signal} eq 'legacy_type') {
			# Legacy type hint — map to nearest score bucket if recognisable
			my $t = $ev->{value} // '';
			if($t eq 'object')   { $score{object}   += $ev->{weight} }
			elsif($t eq 'self')  { $score{object}   += $ev->{weight} }
			else                 { $score{property} += $ev->{weight} }
		} elsif($ev->{signal} eq 'context_aware') {
			# Context-aware return suggests getter behaviour
			$score{property} += $ev->{weight};
		} elsif($ev->{signal} eq 'error_pattern') {
			# Error pattern return doesn't strongly imply a type —
			# give a small nudge toward property (scalar return)
			$score{property} += $ev->{weight};
		}
		# Unknown signals are ignored — they may be used by external consumers
	}

	# Tie-break alphabetically — deterministic but arbitrary
	my ($winner) = sort { ($score{$b} || 0) <=> ($score{$a} || 0) || $a cmp $b } keys %score;

	$self->{return_type} = $winner || 'unknown';
	return $self->{return_type};
}

=head2 resolve_confidence

Derive a confidence level from the total weight of all accumulated
evidence (every category, not just C<return>) and store it.

    $method->add_evidence(category => 'return', signal => 'returns_self', weight => 50);
    my $conf = $method->resolve_confidence;   # { score => 50, level => 'high' }

=head3 Arguments

None beyond C<$self>.

=head3 Returns

A hashref with keys C<score> (the sum of every evidence entry's
C<weight>) and C<level>, which is C<low> if C<score> is below
C<$MEDIUM_CONFIDENCE_THRESHOLD> (20), C<medium> if at least 20 but
below C<$HIGH_CONFIDENCE_THRESHOLD> (40), or C<high> if 40 or above.
With no evidence at all, C<score> is 0 and C<level> is C<low>.

=head3 Side effects

Sets C<confidence> to the resolved hashref.

=head3 API specification

=head4 input

    { self => { type => OBJECT, isa => 'App::Test::Generator::Model::Method' } }

=head4 output

    {
        type => HASHREF,
        keys => {
            score => { type => SCALAR },
            level => { type => SCALAR },
        },
    }

=cut

sub resolve_confidence {
	my $self = $_[0];

	my $total = 0;
	$total += $_->{weight} for @{ $self->{evidence} };

	my $level = $total >= $HIGH_CONFIDENCE_THRESHOLD ? 'high' : $total >= $MEDIUM_CONFIDENCE_THRESHOLD ? 'medium' : 'low';

	$self->{confidence} = { score => $total, level => $level };

	return $self->{confidence};
}

=head2 resolve_classification

Derive a test classification from the resolved return type and store
it.

    $method->add_evidence(category => 'return', signal => 'returns_self', weight => 20);
    my $class = $method->resolve_classification;   # 'chainable'

=head3 Arguments

None beyond C<$self>.

=head3 Returns

C<chainable> if C<return_type> is C<object>, C<getter> if
C<property>, C<constant> if C<constant>, or C<unknown> for any other
value.

=head3 Side effects

Calls C<resolve_return_type> first (and so also sets C<return_type>)
if C<return_type> has not already been resolved. Sets
C<classification> to the resolved value.

=head3 API specification

=head4 input

    { self => { type => OBJECT, isa => 'App::Test::Generator::Model::Method' } }

=head4 output

    { type => SCALAR }

=cut

sub resolve_classification {
	my $self = $_[0];

	# Return_type must be resolved before classification can be determined
	$self->resolve_return_type() unless defined $self->{return_type};

	if($self->{return_type} eq 'object') {
		$self->{classification} = 'chainable';
	} elsif ($self->{return_type} eq 'property') {
		$self->{classification} = 'getter';
	} elsif ($self->{return_type} eq 'constant') {
		$self->{classification} = 'constant';
	} else {
		$self->{classification} = 'unknown';
	}

	return $self->{classification};
}

=head2 absorb_legacy_output

Convert a legacy schema output hashref (the pre-evidence-model output
descriptor format) into one or more C<return>-category evidence
entries.

    $method->absorb_legacy_output({
        type          => 'object',
        _returns_self => 1,
    });

=head3 Arguments

=over 4

=item * C<$output>

A hashref of legacy output hints, or C<undef>.

=back

=head3 Returns

Nothing (undef).

=head3 Side effects

For each recognised key present and true in C<$output>, calls
C<add_evidence> once:

=over 4

=item * C<type> -> C<legacy_type> evidence, C<value> set to
C<$output-E<gt>{type}>, weight 20.

=item * C<_returns_self> -> C<returns_self> evidence, weight 25.

=item * C<_context_aware> -> C<context_aware> evidence, weight 15.

=item * C<_error_return> -> C<error_pattern> evidence, C<value> set to
C<$output-E<gt>{_error_return}>, weight 15.

=back

=head3 Notes

C<$output> being C<undef> or any non-hashref value is silently
ignored — no evidence is added and no exception is raised. A hashref
with none of the four recognised keys set to a true value also adds
no evidence.

=head3 API specification

=head4 input

    {
        self   => { type => OBJECT, isa => 'App::Test::Generator::Model::Method' },
        output => { type => HASHREF, optional => 1 },
    }

=head4 output

    { type => UNDEF }

=cut

sub absorb_legacy_output {
	my ($self, $output) = @_;

	return unless $output && ref $output eq 'HASH';

	if ($output->{type}) {
		$self->add_evidence(
			category => 'return',
			signal   => 'legacy_type',
			value    => $output->{type},
			weight   => 20,
		);
	}

	if ($output->{_returns_self}) {
		$self->add_evidence(
			category => 'return',
			signal   => 'returns_self',
			weight   => 25,
		);
	}

	if ($output->{_context_aware}) {
		$self->add_evidence(
			category => 'return',
			signal   => 'context_aware',
			weight   => 15,
		);
	}

	if ($output->{_error_return}) {
		$self->add_evidence(
			category => 'return',
			signal   => 'error_pattern',
			value    => $output->{_error_return},
			weight   => 15,
		);
	}
}

1;
