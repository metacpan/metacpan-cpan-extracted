package Crypt::Chimera::Cracker;

use strict;
use vars qw(@ISA %PTABLE %USERS);
use Data::Dumper;
use Crypt::Chimera::User;

@ISA = qw(Crypt::Chimera::User);

BEGIN {
	%PTABLE = (
		1	=> qw/001 010 100 111/,
		0	=> qw/000 110 101 011/,
			);
	# I hate this
	%USERS = (
		Alice	=> 0,
		Bob		=> 1,
			);
}

sub init {
	my $self = shift;
	$self->display(1, "new eve, verbosity " . $self->{Verbose}, "");
}

sub round {
}

sub event {
	my $self = shift;
	my $event = shift;
	$self->{Event}->[$event->{Round}]->[$USERS{$event->{Source}}] =
					$event->{Parity};
}

sub matchvector {
	my ($self, $ap, $bp, $len) = @_;

	$self->display(3, "first parity", $ap);
	$self->display(3, "second parity", $bp);

	my $rbits = pack("B*", $ap);
	my $lbits = pack("B*", $bp);
	my $match = unpack("B*", ($rbits ^ ~ $lbits));
	$match = substr($match, 0, $len);

	$self->display(3, "match vector", $match);

	return $match;
}

sub guess {
	my $self = shift;
	my $events = shift;

	my $ap = $events->[0];
	my $bp = $events->[1];

	my $len = length $ap;
	$len = length $bp if length $bp < $len;

	my $match = $self->matchvector($ap, $bp, $len);

	my @match = split //, $match;

	my $out = "x" x $len;
	my $i = 0;

	foreach (0..($len - 1)) {
		if ($match[$_]) {
			substr($out, $i++, 1) = substr($ap, $_, 1);
		}
	}

	$out = substr($out, 0, $i);

	$self->display(3, "guess", $out);

	return $out;
}

sub fini {
	my $self = shift;

	print Dumper($self->{Event});

	my $guess = $self->guess($self->{Event}->[-1]);

	if (0) {
		if (exists $self->{Bits}) {
			$self->parity;
			my $guess = $self->guess;
		}
		else {
			my $guess = $self->guess;
			$self->{Bits} = [ undef, $guess ];
		}
	}

}

1;
