package Algorithm::Step;

use strict;
use warnings;

require Exporter;

our @ISA       = qw(Exporter);
our @EXPORT    = qw(step algorithm statistics end_algorithm);
our $VERSION   = 0.02;

my $algs = {};
my @algstack = ();
my $curralg;

sub algorithm {
	my ($name, $desc) = @_;
	if (!exists $algs->{$name}) {
		$algs->{$name} = {};
		$algs->{$name}->{desc} = $desc;
		$algs->{$name}->{steps} = {};
	}
	push @algstack, $name;
	$curralg = $name;
}

sub step {
	my @args = @_;
	my $argc = @_;
	my $refstep = $algs->{$curralg};
	foreach (0 .. $argc-2) {
		if (!exists $refstep->{steps}) {
			$refstep->{steps} = {};
		}
		$refstep = $refstep->{steps};
		if (!exists $refstep->{$args[$_]}) {
			$refstep->{$args[$_]} = {};
			$refstep->{$args[$_]}->{desc} = $args[$argc-1];
			$refstep->{$args[$_]}->{count} = 0;
		}
		$refstep=$refstep->{$args[$_]};
	}
	$refstep->{count}++;
}

sub statistics {
	print "\nSTATISTICS\n\n";
	foreach (keys %{$algs}) {
		print "Algorithm $_: $algs->{$_}->{desc}\n";
		my $name = $_;
		foreach (sort keys %{$algs->{$name}->{steps}}) {
			print_step($algs->{$name}->{steps}->{$_}, $_, 0); 
		}
	}
}

sub print_step {
	my ($step, $id, $indent) = @_;
	my $i;
	for ($i = 0; $i < $indent; $i++) {
		print "  ";
	}
	print pad_dots("STEP $id. $step->{desc} ", 72), " [$step->{count}]\n";
	if (exists $step->{steps}) {
		foreach (sort keys %{$step->{steps}}) {
			print_step($step->{steps}->{$_}, "$id.$_", $indent+1); 
		}
	}
}

sub pad_dots {
	my ($s, $len) = @_;
	return $s if $len <= (length $s);
	return $s . "." x ($len - length $s);
}

sub end_algorithm {
	pop @algstack;
	$curralg = pop @algstack;
	push @algstack, $curralg;
}

1;

__END__

=head1 NAME

MyStep - Trace execution steps of an algorithm

=head1 SYNOPSIS
  
	use Algorithm::Step;
	use integer;

	algorithm "P", "Print table of 500 primes";
	my @PRIME = ();

	step 1, "Start table, PRIME[1] <- 2, PRIME[2] <- 3";
	$PRIME[1] = 2;
	$n = 3;
	$j = 1;
	$PRIME[++$j] = $n;

	while ($j < 500) {

	step 2, "Advance n by 2";
    		$n += 2; 

	step 3, "k <- 1";
		$k = 1;

		do {

	step 4, "Increase k";
			++$k;

	step 5, "Divide n by PRIME[k]";
			$q = $n / $PRIME[$k]; 
			$r = $n % $PRIME[$k];

	step 6, "Remainder zero?";
			next if $r == 0;

	step 7, "PRIME[k] large?";
		} while ($q > $PRIME[$k]);

	step 8, "n is prime";
		$PRIME[++$j] = $n;
	}

	step 9, "Print result";
    	print "FIRST FIVE HUNDRED PRIMES\n";

	$m = 1;
	do {
		for (0,50,100,150,200,250,300,350,400) {
			print $PRIME[$_+$m], "\t";
		}
		print $PRIME[450+$m], "\n";
		$m++;
	} while ($m <= 50);

	end_algorithm "P";

=head1 DESCRIPTION

This is for observing the behavior of algorithms on some algorithm textbooks,
such as `The Art of Computer Programming', `Introduction to Algorithms'.
I write it only for fun. I have been thinking of how to embed documents
in program in a helpful way.

The usage is well demonstrated by the example above.

=over 4

=item B<algorithm>

Begins an algorithm. It takes two arguments. The first one is the name of this
algorithm, the second one is the short description.

=item B<end_algorithm>

Ends an algorithm.

=item B<step>

Increase count on this step by 1. It can be nested.
A step can be divided into sub steps, like:

	step 1, "desc";
	step 1,1, "desc";
	step 1,2, "desc";
	step 2, "desc";

=item B<statistics>

Print the execution information. If no argument is give,
print to stdout. If a filename is given, print to that file.

	statistics("prime.stat");

The output looks like:

  STATISTICS

  Algorithm P: Print table of 500 primes
  STEP 1. Start table, PRIME[1] <- 2, PRIME[2] <- 3 .... [1]
  STEP 2. Advance n by 2 ............................... [1784]
  STEP 3. k <- 1 ....................................... [1784]
  STEP 4. Increase k ................................... [9538]
  STEP 5. Divide n by PRIME[k] ......................... [9538]
  STEP 6. Remainder zero? .............................. [9538]
  STEP 7. PRIME[k] large? .............................. [8252]
  STEP 8. n is prime ................................... [498]
  STEP 9. Print result ................................. [1]

=back

=head1 TODO

Generate from comments. If a file `prime.pl' looks like:

	...

	# algorithm P: Print first five hundred primes

	# step 5: Divide n by PRIME[k]

	# end algorithm P

	...

Parse the comments, insert codes, and generate a new `step_prime.pl';

=head1 BUGS

Surely there are many. This is still pre-alpha.

=head1 SEE ALSO

=head1 AUTHOR

Chaoji Li <lichaoji@gmail.com>

=head1 COPYRIGHT

Use it anyway you please.

=cut
