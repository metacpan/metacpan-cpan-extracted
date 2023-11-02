package App::HL7::Compare::Exception;
$App::HL7::Compare::Exception::VERSION = '0.003';
use v5.10;
use strict;
use warnings;

use Moo;
use Mooish::AttributeBuilder -standard;
use Types::Standard qw(Str Maybe ArrayRef);

use overload
	q{""} => "to_string",
	fallback => 1;

has param 'message' => (
	isa => Str,
);

has field 'caller' => (
	isa => Maybe [ArrayRef],
	default => sub {
		for my $call_level (1 .. 10) {
			my ($package, $file, $line) = caller $call_level;
			if (defined $package && $package !~ /^App::HL7::Compare/) {
				return [$package, $file, $line];
			}
		}
		return undef;
	},
);

sub raise
{
	my ($self, $error) = @_;

	if (defined $error) {
		$self = $self->new(message => $error);
	}

	die $self;
}

sub to_string
{
	my ($self) = @_;

	my $raised = $self->message;
	$raised =~ s/\s+\z//;

	my $caller = $self->caller;
	if (defined $caller) {
		$raised .= ' (raised at ' . $caller->[1] . ', line ' . $caller->[2] . ')';
	}

	return "An error occured in HL7 subroutines: $raised";
}

1;

