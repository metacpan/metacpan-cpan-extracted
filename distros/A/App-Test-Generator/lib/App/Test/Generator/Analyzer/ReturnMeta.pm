package App::Test::Generator::Analyzer::ReturnMeta;

use strict;
use warnings;

our $VERSION = '0.31';

=head1 VERSION

Version 0.31

=cut

sub new { bless {}, shift }

sub analyze {
	my ($self, $schema) = @_;

	my $output = $schema->{output} || {};
	my @risk;
	my $stability = 100;
	my $consistency = 100;

	# -----------------------------------
	# Context sensitivity
	# -----------------------------------
	if ($output->{_context_aware}) {
		push @risk, 'context_sensitive';
		$stability -= 25;
		$consistency -= 15;
	}

	# -----------------------------------
	# Mixed return types
	# -----------------------------------
	if ($output->{_returns_self} && $output->{type} ne 'object') {
		push @risk, 'mixed_return_types';
		$consistency -= 30;
	}

	# -----------------------------------
	# Implicit undef returns
	# -----------------------------------
	if ($output->{_error_handling}{implicit_undef}) {
		push @risk, 'implicit_error_return';
		$stability -= 20;
	}

	# -----------------------------------
	# Explicit undef on error
	# -----------------------------------
	if ($output->{_error_return} && $output->{_error_return} eq 'undef') {
		push @risk, 'undef_on_error';
		$stability -= 10;
	}

	# -----------------------------------
	# Empty list error pattern
	# -----------------------------------
	if ($output->{_error_handling}{empty_list}) {
		push @risk, 'empty_list_error';
		$consistency -= 15;
	}

	# -----------------------------------
	# Exception handling without rethrow
	# -----------------------------------
	if ($output->{_error_handling}{exception_handling}) {
		push @risk, 'exception_swallowing';
		$stability -= 20;
	}

	# -----------------------------------
	# Boolean consistency boost
	# -----------------------------------
	if ($output->{type} && $output->{type} eq 'boolean') {
		$stability += 5;
	}

	# Clamp scores
	$stability = 0 if $stability < 0;
	$consistency = 0 if $consistency < 0;
	$stability = 100 if $stability > 100;
	$consistency = 100 if $consistency > 100;

	return {
		stability_score => $stability,
		consistency_score => $consistency,
		risk_flags => \@risk,
	};
}

1;
