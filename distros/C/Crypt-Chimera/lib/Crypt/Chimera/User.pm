package Crypt::Chimera::User;

use strict;
use vars qw(@ISA %PARITY);
use Data::Dumper;
use Crypt::Chimera::Object;
use Crypt::Chimera::Event;

@ISA = qw(Crypt::Chimera::Object);

BEGIN {
	foreach my $i (0..1) {
		foreach my $j (0..1) {
			foreach my $k (0..1) {
				$PARITY{"$i$j$k"} = $i ^ $j ^ $k;
			}
		}
	}
}

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);

	die "No name in user" unless $self->{Name};
	die "No world in user" unless $self->{World};

	$self->{World}->register($self);

	return $self;
}

sub init {
	my $self = shift;

	$self->display(1, "new user, verbosity " . $self->{Verbose}, "");

	my $len = $self->{World}->{Length};

	my $bits = "0" x $len;
	foreach (0..$len) {
		substr($bits, $_, 1) = "1" if (rand() * 16) < 3;
	}

	$self->display(2, "initial", $bits);

	$self->{Bits} = [ $bits ];
}

sub fini {
}

sub parity {
	my $self = shift;

	my $bits = $self->{Bits}->[$self->{World}->{Round}];

	my $len = int(length($bits) / 3);
	my $out = "x" x $len;

	foreach (0..($len - 1)) {
		substr($out, $_, 1) = $PARITY{substr($bits, $_ * 3, 3)};
	}

	$self->display(3, "parities", $out);
	
	$self->{Parity} = $out;
}

sub round {
	my $self = shift;

	$self->parity unless exists $self->{Parity};

	my $event = new Crypt::Chimera::Event(
					Source	=> $self->{Name},
					Parity	=> $self->{Parity},
						);
	$self->{World}->event($event);
}

sub receive {
	my $self = shift;
	my $remote = shift;	# A string "10100101010"

	$self->parity unless exists $self->{Parity};

	my $len = length $self->{Parity};
	$len = length $remote if length $remote < $len;

	my $rbits = pack("B*", $remote);
	my $lbits = pack("B*", $self->{Parity});
	my $match = unpack("B*", ($rbits ^ ~ $lbits));
	$match = substr($match, 0, $len);

	$self->display(5, "parity match", $match);

	my $zeros = $match;
	$zeros =~ s/[^0]//g;
	$self->display(7, "zero count", length($zeros));
	# $self->display(7, "zero ratio", length($zeros) / length($match));

	my @match = split //, $match;
	my $bits = $self->{Bits}->[$self->{World}->{Round}];
	my $out = "x" x $len;
	my $i = 0;

	foreach (0..($len - 1)) {
		if ($match[$_]) {
			substr($out, $i++, 1) = substr($bits, $_ * 3, 1);
		}
	}

	$out = substr($out, 0, $i);

	$self->{Bits}->[$self->{World}->{Round} + 1] = $out;

	$self->display(2, "new bits", $out);
}

sub event {
	my $self = shift;
	my $event = shift;

	return unless $event->{Source} eq $self->{Remote};

	# $self->display(4, "process event", $event->{Seq});

	$self->receive($event->{Parity});
}

sub clean {
	my $self = shift;
	delete $self->{Parity};
}

sub huffman_recurse {
	my ($self, $code, $freq) = @_;

	# Make this deterministic, even though it shouldn't matter
	my @tokens = sort
			{ $freq->{$b} <=> $freq->{$a} || $b cmp $a }
					keys %$freq;

	if (@tokens == 2) {
		$code->{$tokens[0]} = '1';
		$code->{$tokens[1]} = '0';
		return;
	}

	my $s0 = pop @tokens;
	my $f0 = delete $freq->{$s0};

	# print STDERR "Least frequent is token $s0 with freq $f0\n";

	my $s1 = $tokens[-1];
	$freq->{$s1} += $f0;

	$self->huffman_recurse($code, $freq);

	$code->{$s0} = $code->{$s1} . '0';
	$code->{$s1} .= '1';

	$freq->{$s1} -= $f0;
	$freq->{$s0} = $f0;
}

sub freqtable {
	my ($self, $bits, $frag) = @_;

	$bits = $self->{Bits}->[-1] unless $bits;

	my $len = int(length($bits) / $frag);
	my %freq = ();

	foreach (0..($len - 1)) {
		my $ss = substr($bits, $_ * $frag, $frag);
		$freq{$ss}++;
	}

	return %freq;
}

sub huffman {
	my $self = shift;

	my $frag = 12;

	my $bits = $self->{Bits}->[-1];	# Last element

	$self->display(3, "huffman code", $bits);

	my $len = int(length($bits) / $frag);
	my %freq = $self->freqtable($bits, $frag);
	my %code = ();

	foreach (0..($len - 1)) {
		my $ss = substr($bits, $_ * $frag, $frag);
		$code{$ss} = '';
	}

	# print Dumper(\%freq);

	my @tokens = keys %freq;
	if (@tokens == 0) {
	}
	elsif (@tokens == 1) {
		$code{$tokens[0]} = '1';
	}
	else {
		$self->huffman_recurse(\%code, \%freq);
	}

	# print Dumper(\%code);

	my $out = '';
	foreach (0..($len - 1)) {
		$out .= $code{substr($bits, $_ * $frag, $frag)};
	}

	$self->display(1, "huffman output", $out);

	return $out;
}

1;
