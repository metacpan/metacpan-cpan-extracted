package App::Test::Generator::Model::Method;

use strict;
use warnings;

use Carp qw(croak);
use Readonly;

Readonly my $HIGH_CONFIDENCE_THRESHOLD   => 40;
Readonly my $MEDIUM_CONFIDENCE_THRESHOLD => 20;

our $VERSION = '0.33';

=head1 VERSION

Version 0.33

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

# Read-only accessors — name and source are immutable after construction
sub name   { $_[0]->{name}   }
sub source { $_[0]->{source} }

sub return_type {
	my ($self, $val) = @_;
	$self->{return_type} = $val if @_ > 1;
	return $self->{return_type};
}

sub classification {
	my ($self, $val) = @_;
	$self->{classification} = $val if @_ > 1;
	return $self->{classification};
}

sub confidence {
	my ($self, $val) = @_;
	$self->{confidence} = $val if @_ > 1;
	return $self->{confidence};
}

sub add_evidence {
	my ($self, %args) = @_;

	# Validate category — must be one of the three recognised kinds
	my %valid_categories = map { $_ => 1 } qw(return input effect);
	croak "Invalid evidence category '$args{category}'"
		unless $valid_categories{ $args{category} // '' };

	# Validate signal — must be a known signal name to catch typos early.
	# Signals are per-category; we validate the full set across all categories.
	my %valid_signals = map { $_ => 1 } qw(
		returns_property returns_constant returns_self
		legacy_type context_aware error_pattern
		input_validated input_typed input_optional
		has_side_effect no_side_effect
	);
	croak "Invalid evidence signal '$args{signal}'"
		unless $valid_signals{ $args{signal} // '' };

	push @{ $self->{evidence} }, {
		category => $args{category},
		signal   => $args{signal},
		value    => $args{value},
		weight   => defined $args{weight} ? $args{weight} : 1,
	};
}

sub evidence {
	my $self = $_[0];
	return @{ $self->{evidence} };
}

sub evidence_ref {
	my $self = $_[0];
	return $self->{evidence};
}

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

sub resolve_confidence {
	my $self = $_[0];

	my $total = 0;
	$total += $_->{weight} for @{ $self->{evidence} };

	my $level = $total >= $HIGH_CONFIDENCE_THRESHOLD ? 'high' : $total >= $MEDIUM_CONFIDENCE_THRESHOLD ? 'medium' : 'low';

	$self->{confidence} = { score => $total, level => $level };

	return $self->{confidence};
}

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
