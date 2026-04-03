package App::Test::Generator::Analyzer::SideEffect;

use strict;
use warnings;

our $VERSION = '0.30';

=head1 VERSION

Version 0.30

=cut

sub new { bless {}, shift }

sub analyze {
	my ($self, $method) = @_;

	my $body = $method->{body} || '';

	my %result = (
		mutates_self	=> 0,
		mutates_globals => 0,
		performs_io	 => 0,
		calls_external => 0,
		mutation_fields => [],
	);

	# ---------------------------------
	# Detect $self->{field} assignment
	# ---------------------------------
	while ($body =~ /\$self->\{(\w+)\}\s*=/g) {
		$result{mutates_self} = 1;
		push @{ $result{mutation_fields} }, $1;
	}

	# ---------------------------------
	# Detect global variable mutation
	# ---------------------------------
	if ($body =~ /\$(?:GLOBAL|ENV|SIG)\b/) {
		$result{mutates_globals} = 1;
	}

	# ---------------------------------
	# Detect IO operations
	# ---------------------------------
	if ($body =~ /\b(print|warn|open|close|syswrite|readline)\b/) {
		$result{performs_io} = 1;
	}

	# ---------------------------------
	# Detect external command execution
	# ---------------------------------
	if ($body =~ /\b(system|exec|qx\(|`)/) {
		$result{calls_external} = 1;
	}

	# ---------------------------------
	# Purity classification
	# ---------------------------------
	if (!$result{mutates_self} && !$result{mutates_globals} && !$result{performs_io} && !$result{calls_external}) {
		$result{purity_level} = 'pure';
	} elsif ($result{mutates_self} && !$result{mutates_globals} && !$result{performs_io} && !$result{calls_external}) {
		$result{purity_level} = 'self_mutating';
	} else {
		$result{purity_level} = 'impure';
	}

	return \%result;
}

1;
