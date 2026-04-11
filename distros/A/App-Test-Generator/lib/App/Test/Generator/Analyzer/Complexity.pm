package App::Test::Generator::Analyzer::Complexity;

use strict;
use warnings;

our $VERSION = '0.31';

=head1 VERSION

Version 0.31

=cut

sub new { bless {}, shift }

sub analyze {
	my ($self, $method) = @_;

	my $body = $method->{body} || '';

	my %result = (
		cyclomatic_score => 1,	# base
		branching_points => 0,
		early_returns	=> 0,
		exception_paths => 0,
		nesting_depth	=> 0,
	);

	# -----------------------------------
	# Branching keywords
	# -----------------------------------
	my @branch_tokens = qw(
		if elsif unless for foreach while until given when
	);

	for my $token (@branch_tokens) {
		my $count = () = $body =~ /\b$token\b/g;
		$result{branching_points} += $count;
		$result{cyclomatic_score} += $count;
	}

	# Logical operators
	my $logic_count = () = $body =~ /&&|\|\||\?/g;
	$result{cyclomatic_score} += $logic_count;

	# -----------------------------------
	# Early returns
	# -----------------------------------
	my $return_count = () = $body =~ /\breturn\b/g;
	$result{early_returns} = $return_count > 1 ? $return_count - 1 : 0;
	$result{cyclomatic_score} += $result{early_returns};

	# -----------------------------------
	# Exception paths
	# -----------------------------------
	my @exception_tokens = qw(die croak confess try catch eval);
	for my $token (@exception_tokens) {
		my $count = () = $body =~ /\b$token\b/g;
		$result{exception_paths} += $count;
		$result{cyclomatic_score} += $count;
	}

	# -----------------------------------
	# Nesting depth calculation
	# -----------------------------------
	my $depth = 0;
	my $max_depth = 0;

	foreach my $char (split //, $body) {
		if ($char eq '{') {
			$depth++;
			$max_depth = $depth if $depth > $max_depth;
		} elsif ($char eq '}') {
			$depth-- if $depth > 0;
		}
	}

	$result{nesting_depth} = $max_depth;

	# -----------------------------------
	# Complexity Level Classification
	# -----------------------------------
	my $score = $result{cyclomatic_score};

	if ($score <= 3) {
		$result{complexity_level} = 'low';
	} elsif ($score <= 7) {
		$result{complexity_level} = 'moderate';
	} else {
		$result{complexity_level} = 'high';
	}

	return \%result;
}

1;
