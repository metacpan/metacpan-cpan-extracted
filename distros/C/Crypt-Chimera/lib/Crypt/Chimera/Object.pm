package Crypt::Chimera::Object;

use strict;
use vars qw($BOLD $RESET);

BEGIN {
	if (1) {
		*Crypt::Chimera::Object::color = sub { ""; };
	}
	else {
		eval qq{ use Term::ANSIColor; };
		if ($@) {
			warn "The output from this program is more readable " .
					"if you have Term::ANSIColor installed.\n" .
					"Continuing anyway...";
			*Crypt::Chimera::Object::color = sub { ""; };
		}
	}
}

$BOLD = color 'cyan';
$RESET = color 'reset';

sub new {
	my $class = shift;
	my $self = ($#_ == 0) ? { %{ (shift) } } : { @_ };
	$self->{Verbose} = 2 unless $self->{Verbose};
	return bless $self, $class;
}

sub display {
	my ($self, $level, $msg, $data) = @_;
	return unless $level <= $self->{Verbose};
	if (length($data) > 50) {
		my $len = length $data;
		$data = substr($data, 0, 40);
		$data =~ s/(...)(...)/$1$BOLD$2$RESET/g;
		$data .= "... ($len bytes)";
	}
	else {
		$data =~ s/(...)(...)/$1$BOLD$2$RESET/g;
	}
	print "$self->{Name}\[$level] ($msg): $data\n";
}

1;
