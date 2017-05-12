package Armadito::Agent::Patterns::Matcher;

use strict;
use warnings;
use UNIVERSAL::require;
require Exporter;

sub new {
	my ( $class, %params ) = @_;

	my %patterns;
	my $self = {
		patterns           => \%patterns,
		logger             => $params{logger},
		exclusion_patterns => [],
		hooks              => []
	};

	bless $self, $class;
	return $self;
}

sub getResults {
	my ($self) = @_;

	my $results  = {};
	my %patterns = %{ $self->{patterns} };

	foreach my $name ( keys(%patterns) ) {
		$results->{$name} = $self->getResultsForPattern( $patterns{$name}, $name );
	}

	return $results;
}

sub getResultsForPattern {
	my ( $self, $pattern, $name ) = @_;

	my $i = 0;
	my $j = 0;

	my $pattern_results = [];

	foreach my $match ( @{ $pattern->{matches} } ) {

		my $match_results = {};

		if ( $pattern->{labels} eq "" ) {
			$match_results = $pattern->{matches}[$i][0];
		}
		else {
			foreach my $label ( @{ $pattern->{labels} } ) {
				$match_results->{$label} = $pattern->{matches}[$i][$j];
				$match_results->{$label} = $self->runHooksForLabel( $label, $match_results->{$label} );
				$j++;
			}
		}

		$i++;
		$j = 0;
		push( @{$pattern_results}, $match_results );
	}

	return $pattern_results;
}

sub addPattern {
	my ( $self, $name, $regex, $labels ) = @_;

	if ( !defined($labels) ) {
		$labels = "";
	}

	my $pattern = {
		regex   => $regex,
		matches => [],
		labels  => $labels,
	};

	${ $self->{patterns} }{$name} = $pattern;
}

sub addExclusionPattern {
	my ( $self, $pattern ) = @_;

	push( @{ $self->{exclusion_patterns} }, $pattern );
}

sub addExclusionPatterns {
	my ( $self, $patterns ) = @_;

	$self->{exclusion_patterns} = $patterns;
}

sub addHookForLabel {
	my ( $self, $label, $funcref ) = @_;

	my $hook = {
		label    => $label,
		function => $funcref
	};

	push( @{ $self->{hooks} }, $hook );
}

sub runHooksForLabel {
	my ( $self, $label, $match ) = @_;

	foreach my $hook ( @{ $self->{hooks} } ) {
		if ( $hook->{label} eq $label ) {
			return $hook->{function}->($match);
		}
	}

	return $match;
}

sub run {
	my ( $self, $input, $separator ) = @_;

	my @substrings = split( /$separator/, $input );

	foreach my $substring (@substrings) {
		if ( !$self->_isExcluded($substring) ) {
			$self->_parseSubString($substring);
		}
	}
}

sub _isExcluded {
	my ( $self, $substring ) = @_;

	foreach my $pattern ( @{ $self->{exclusion_patterns} } ) {
		if ( $substring =~ m/$pattern/ms ) {
			return 1;
		}
	}

	return 0;
}

sub _parseSubString {
	my ( $self, $substring ) = @_;

	my %patterns = %{ $self->{patterns} };
	my $matches  = ();

	foreach my $name ( keys(%patterns) ) {
		$matches = $self->_checkPattern( $substring, ${ $self->{patterns} }{$name} );
		if ($matches) {
			push( @{ ${ $self->{patterns} }{$name}->{matches} }, $matches );
		}
	}
}

sub _checkPattern {
	my ( $self, $substring, $pattern ) = @_;

	if ( my @matches = ( $substring =~ m/$pattern->{regex}/ms ) ) {
		return \@matches;
	}
}

1;

__END__

=head1 NAME

Armadito::Agent::Patterns::Matcher - Parses an input string with multiple regular expressions.

=head1 DESCRIPTION

Given plain text content is parsed with multiple patterns. Each pattern should have capturing parentheses.

=head1 METHODS

=head2 $parser->new(%params)

New parser instanciation.

=head2 $parser->addPattern()

Add new pattern for parsing.

=head2 $parser->run()

Run parser on input given.

