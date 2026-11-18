package App::Test::Generator::Mutation::Feedback;

use strict;
use warnings;
use Carp qw(croak carp);
use File::Spec;
use JSON::MaybeXS qw(decode_json);

our $VERSION = '0.50';

=head1 NAME

App::Test::Generator::Mutation::Feedback - Turn surviving mutants into boundary
cases and schema constraints

=head1 VERSION

Version 0.50

=head1 SYNOPSIS

    use App::Test::Generator::Mutation::Feedback;

    my $feedback = App::Test::Generator::Mutation::Feedback->new(
        mutation_results => 'mutation.json',
        module           => 'My::Module',
    );

    my $applied = $feedback->apply_to_schema($schema);
    printf "added %s = %s to %s\n",
        $_->{constraint}, $_->{value}, $_->{field} for @{$applied};

=head1 DESCRIPTION

A mutation survivor is a mutant the test suite did not notice.  Until now a
survivor was only counted and printed; this module reads the survivors from
the JSON written by C<test-generator-mutate --json> and proposes concrete
inputs that would have killed them.

For a surviving numeric-boundary mutant the source line is read back and the
comparison it mutated is recovered, for example C<< $count > 10 >>.  That
comparison is then translated into a schema constraint:

    source comparison     proposed constraint
    $x >  N               min => N + 1
    $x >= N               min => N
    $x <  N               max => N - 1
    $x <= N               max => N

Integer literals only.  The constraint makes L<App::Test::Generator::Template>
generate values on both sides of the boundary, which is what the survivor
showed was missing.

Constraints are only applied to a field of the schema's C<input> section
whose name matches the variable in the source comparison, after normalising
case and punctuation.  An existing constraint is never replaced: a bound the
POD or the code already declares wins over a proposed one.

Survivors that do not describe a numeric comparison - conditional inversions,
boolean negations and so on - produce a C<manual> proposal instead of an
automatic change, because no single data value is known to distinguish them.
They are still returned by L</proposals> so a reviewer can see what survived.

Only survivors belonging to C<module>'s own file are used when C<module> is
given, so a mutation run over a whole C<lib> directory feeds only the matching
module's schema.

=head2 new

Construct a feedback object.

    my $feedback = App::Test::Generator::Mutation::Feedback->new(
        mutation_results => 'mutation.json',
        module           => 'My::Module',
        source_root      => '.',
    );

=head3 Arguments

=over 4

=item * C<mutation_results>

Required.  Either the path to a mutation results JSON file or an already
decoded hashref with the same shape.  The file must contain a C<survived>
arrayref whose entries have C<id>, C<file> and C<line> keys; entries with a
C<status> other than C<Survived> are ignored.

=item * C<module>

Optional module name, e.g. C<My::Module>.  When given, only survivors whose
C<file> names that module's file (C<My/Module.pm>) are proposed, so results
from a whole-directory mutation run can be fed to one schema safely.

=item * C<source_root>

Optional directory used to resolve the relative C<file> paths in the results.
Defaults to the current directory.

=back

=head3 Returns

A blessed hashref.  Croaks when C<mutation_results> is missing, unreadable or
not valid JSON, and when no module file can be matched but C<module> is set.

=head3 API SPECIFICATION

=head4 input

    {
        mutation_results => { type => 'any' },
        module           => { type => 'string', optional => 1 },
        source_root      => { type => 'string', optional => 1 },
    }

C<mutation_results> is a file name or a hashref, so no single type is
declared for it.

=head4 output

    { type => OBJECT, isa => 'App::Test::Generator::Mutation::Feedback' }

=head2 survivors

Return the survivors from the results, filtered to the configured module.

    my $survivors = $feedback->survivors;

=head3 Returns

An arrayref of survivor hashrefs, in the order they appear in the results.

=head3 API SPECIFICATION

=head4 input

    { self => { type => OBJECT, isa => 'App::Test::Generator::Mutation::Feedback' } }

=head4 output

    { type => ARRAYREF, items => { type => HASHREF } }

=head2 proposals

Return one proposal per survivor.

    my $proposals = $feedback->proposals;

=head3 Returns

An arrayref of hashrefs with these keys:

=over 4

=item * C<kind> - C<constraint> for a numeric comparison that yields an
automatic schema constraint, or C<manual> when a test has to be written by
hand.

=item * C<survivor_id>, C<file>, C<line>, C<description> - copied from the
survivor, so the proposal can be traced back to the mutation report.

=item * C<parameter> - the input field the source comparison constrains,
derived from the variable in the comparison.  Only present for
C<constraint> proposals.

=item * C<values> - the boundary values a test should exercise, one either
side of the literal.  Only present for C<constraint> proposals.

=item * C<constraint> - a hashref such as C<< { min => 11 } >>, suitable for
merging into a schema input field.  Only present for C<constraint>
proposals.

=item * C<hint> - human-readable advice for C<manual> proposals.

=back

=head3 API SPECIFICATION

=head4 input

    { self => { type => OBJECT, isa => 'App::Test::Generator::Mutation::Feedback' } }

=head4 output

    { type => ARRAYREF, items => { type => HASHREF } }

=head2 apply_to_schema

Merge constraint proposals into a schema.

    my $applied = $feedback->apply_to_schema($schema);

=head3 Arguments

=over 4

=item * C<$schema>

A schema hashref as loaded from YAML.  Its C<input> section is modified in
place.

=back

=head3 Returns

An arrayref of change hashrefs, one per constraint added, each with C<field>,
C<constraint>, C<value>, C<survivor_id>, C<file> and C<line>.  An empty
arrayref means nothing could be applied; the C<proposals> are still available
for reporting.

Constraints already present on the field are left alone, as are proposals
whose parameter has no matching input field.

=head3 API SPECIFICATION

=head4 input

    {
        self   => { type => OBJECT, isa => 'App::Test::Generator::Mutation::Feedback' },
        schema => { type => HASHREF },
    }

=head4 output

    { type => ARRAYREF, items => { type => HASHREF } }

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the terms of GPL2.
If you use it,
please let me know.

=cut

# --------------------------------------------------
# A variable on the left of a comparison: $name,
# $self->{name}, $self->{name}[0] and so on.  The
# last identifier is the parameter name.
# --------------------------------------------------
my $COMPARISON_RE = qr{
	(?<var>\$[A-Za-z_]\w*
		(?:\s*(?:->\s*\{?\s*[A-Za-z_]\w*\s*\}?|\[\s*-?\d+\s*\])*)
	)
	\s*(?<op>>=|<=|==|!=|>|<)\s*
	(?<num>-?\d+(?:\.\d+)?)
}x;

sub new {
	my ($class, %args) = @_;

	croak 'mutation_results is required'
		unless defined($args{mutation_results});

	my $results = $args{mutation_results};
	if(!ref($results)) {
		croak "mutation_results '$results' does not exist"
			unless -f $results;

		open(my $fh, '<', $results)
			or croak "Cannot read mutation_results '$results': $!";
		my $raw = do { local $/; <$fh> };
		close($fh);

		$results = eval { decode_json($raw) };
		croak "mutation_results '$args{mutation_results}' is not valid JSON: $@"
			if $@;
	}

	croak 'mutation_results must decode to a hashref'
		unless ref($results) eq 'HASH';

	return bless {
		results     => $results,
		module      => $args{module},
		source_root => $args{source_root} // '.',
	}, $class;
}

sub survivors {
	my ($self) = @_;

	my %seen;
	my @survivors = grep {
		(my $status = $_->{status} // 'Survived') eq 'Survived'
			&& !$seen{ $_->{id} // '' }++
	} @{ $self->{results}{survived} || [] };

	return [ grep { $self->_matches_module($_) } @survivors ];
}

sub proposals {
	my ($self) = @_;

	$self->{proposals} //= [ map { $self->_proposal_for($_) } @{ $self->survivors } ];

	return $self->{proposals};
}

sub apply_to_schema {
	my ($self, $schema) = @_;

	croak 'apply_to_schema needs a schema hashref'
		unless ref($schema) eq 'HASH';
	return [] unless ref($schema->{input}) eq 'HASH';

	my %field_for;
	foreach my $field (keys %{ $schema->{input} }) {
		$field_for{ _normalise($field) } //= $field;
	}

	my @applied;
	my %already;
	foreach my $proposal (@{ $self->proposals }) {
		next unless $proposal->{kind} eq 'constraint';

		my $field = $field_for{ _normalise($proposal->{parameter}) };
		next unless defined($field);

		my $spec = $schema->{input}{$field};
		next unless ref($spec) eq 'HASH';

		foreach my $constraint (sort keys %{ $proposal->{constraint} }) {
			my $value = $proposal->{constraint}{$constraint};
			next if exists($spec->{$constraint}) && defined($spec->{$constraint});
			next if $already{"$field\0$constraint"}++;

			$spec->{$constraint} = $value;
			$spec->{_constraint_source} = {
				%{ $spec->{_constraint_source} || {} },
				$constraint => 'mutation',
			};

			push @applied, {
				field       => $field,
				constraint  => $constraint,
				value       => $value,
				survivor_id => $proposal->{survivor_id},
				file        => $proposal->{file},
				line        => $proposal->{line},
			};
		}
	}

	return \@applied;
}

sub _matches_module {
	my ($self, $survivor) = @_;

	return 1 unless defined($self->{module}) && length($self->{module});

	my $expected = $self->{module};
	$expected =~ s{::}{/}g;
	$expected .= '.pm';

	my $file = $survivor->{file} // '';
	$file =~ s{^\./}{};

	return ($file eq $expected) || ($file =~ m{(?:^|/)\Q$expected\E$}) ? 1 : 0;
}

sub _proposal_for {
	my ($self, $survivor) = @_;

	my %proposal = (
		kind        => 'manual',
		survivor_id => $survivor->{id},
		file        => $survivor->{file},
		line        => $survivor->{line},
		description => $survivor->{description},
		hint        => $survivor->{hint}
			// 'Review the surviving mutant and add a test that tells it apart',
	);

	my $id = $survivor->{id} // '';
	my ($line, $column) = $id =~ /^NUM_BOUNDARY_(\d+)_(\d+)_/;
	my ($original) = ($survivor->{description} // '')
		=~ /Numeric boundary flip\s+(\S+)\s+to\s+\S+/;

	return \%proposal unless defined($line) && defined($original);

	my ($var, $literal) = $self->_numeric_comparison(
		$survivor->{file}, $line, $column, $original,
	);
	return \%proposal unless defined($var) && defined($literal);

	my $constraint = _constraint_for($original, $literal);
	return \%proposal unless $constraint;

	$proposal{kind}       = 'constraint';
	$proposal{parameter}  = _parameter_name($var);
	$proposal{values}     = [ $literal - 1, $literal, $literal + 1 ];
	$proposal{constraint} = $constraint;
	$proposal{hint}       = "Add cases at the boundary of $original $literal";

	return \%proposal;
}

# Read the line a mutant targets and find the comparison it mutated.  When a
# line holds several comparisons, the one nearest the mutant's column wins.
sub _numeric_comparison {
	my ($self, $file, $line_number, $column, $original) = @_;

	my $source = $self->_source_line($file, $line_number);
	return unless defined($source);

	my ($best_var, $best_literal, $best_distance);
	while($source =~ /$COMPARISON_RE/g) {
		next unless $+{op} eq $original;

		my $distance = (defined($column) && length($column))
			? abs(($-[0] + index($&, $+{op}) + 1) - $column)
			: 0;

		next if defined($best_distance) && ($distance >= $best_distance);

		($best_var, $best_literal, $best_distance) = ($+{var}, $+{num}, $distance);
	}

	return ($best_var, $best_literal);
}

sub _source_line {
	my ($self, $file, $line_number) = @_;

	return unless defined($file) && defined($line_number);

	my $path = File::Spec->file_name_is_absolute($file)
		? $file
		: File::Spec->catfile($self->{source_root}, $file);
	return unless -f $path;

	open(my $fh, '<', $path) or return;
	my $current = 0;
	while(my $line = <$fh>) {
		if(++$current == $line_number) {
			close($fh);
			chomp($line);
			return $line;
		}
	}
	close($fh);

	return;
}

# Integer literals only: one step either side of a float is not a boundary
# in the same sense, so those survivors stay manual proposals.
sub _constraint_for {
	my ($operator, $literal) = @_;

	return unless defined($literal) && ($literal =~ /^-?\d+$/);

	return { min => $literal + 1 } if $operator eq '>';
	return { min => $literal     } if $operator eq '>=';
	return { max => $literal - 1 } if $operator eq '<';
	return { max => $literal     } if $operator eq '<=';
	return;
}

sub _parameter_name {
	my ($var) = @_;

	my @identifiers = $var =~ /([A-Za-z_]\w*)/g;

	return $identifiers[-1];
}

sub _normalise {
	my ($name) = @_;

	$name = '' unless defined($name);
	$name = lc($name);
	$name =~ s/[^a-z0-9]//g;

	return $name;
}

1;
