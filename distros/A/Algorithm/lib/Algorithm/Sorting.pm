package Algorithm::Sorting;

use warnings;
use strict;

our $VERSION = '0.05';


BEGIN {
	use Exporter();
	our @ISA=qw(Exporter);
	our @EXPORT=qw(&BubbleSort &ShakerSort &SelectionSort &InsertionSort &ShellSort &QuickSort);
}


sub _filter {
	my $array=shift;

	my @charstrings=grep(/[a-zA-Z]/, @$array);
	my @numbers=grep(/^-?\d*\.?\d*$/, @$array);

	return \@charstrings, $#charstrings+1, \@numbers, $#numbers+1;
}


sub BubbleSort {
	my $referenceOfItemList=shift;
	my ($c, $cc, $n, $nc)=_filter($referenceOfItemList);

	my ($a, $b, $t);
	for($a=1; $a<$cc; ++$a) {
		for($b=$cc-1; $b>=$a; --$b) {
			if($c->[$b-1] gt $c->[$b]) {
				$t=$c->[$b-1];
				$c->[$b-1]=$c->[$b];
				$c->[$b]=$t;
			}
		}
	}
	
	$a=undef; $b=undef, $t=undef;
	for($a=1; $a<$nc; ++$a) {
		for($b=$nc-1; $b>=$a; --$b) {
			if($n->[$b-1] > $n->[$b]) {
				$t=$n->[$b-1];
				$n->[$b-1]=$n->[$b];
				$n->[$b]=$t;
			}
		}
	}
	
	@$referenceOfItemList=(@$n, @$c);
}


sub ShakerSort {
	my $referenceOfItemList=shift;
	my ($c, $cc, $n, $nc)=_filter($referenceOfItemList);
	
	my ($a, $exchange, $t);
	do {
		$exchange=0;
		for($a=$cc-1; $a>0; --$a) {
			if($c->[$a-1] gt $c->[$a]) {
				$t=$c->[$a-1];
				$c->[$a-1]=$c->[$a];
				$c->[$a]=$t;
				$exchange=1;
			}
		}
		
		for($a=1; $a<$cc; ++$a) {
			if($c->[$a-1] gt $c->[$a]) {
				$t=$c->[$a-1];
				$c->[$a-1]=$c->[$a];
				$c->[$a]=$t;
				$exchange=1;
			}
		}
	} while($exchange);
	
	$a=undef; $exchange=undef; $t=undef;
	do {
		$exchange=0;
		for($a=$nc-1; $a>0; --$a) {
			if($n->[$a-1] > $n->[$a]) {
				$t=$n->[$a-1];
				$n->[$a-1]=$n->[$a];
				$n->[$a]=$t;
				$exchange=1;
			}
		}
		
		for($a=1; $a<$nc; ++$a) {
			if($n->[$a-1] > $n->[$a]) {
				$t=$n->[$a-1];
				$n->[$a-1]=$n->[$a];
				$n->[$a]=$t;
				$exchange=1;
			}
		}
	} while($exchange);
	
	@$referenceOfItemList=(@$n, @$c);
}

sub SelectionSort {
	my $referenceOfItemList=shift;
	my ($c, $cc, $n, $nc)=_filter($referenceOfItemList);
	
	my ($a, $b, $d, $t, $exchange);
	
	for($a=0; $a<$cc-1; ++$a) {
		$exchange=0;
		$d=$a;
		$t=$c->[$a];
		
		for($b=$a+1; $b < $cc; ++$b) {
			if($c->[$b] lt $t) {
				$d=$b;
				$t=$c->[$b];
				$exchange=1;
			}
		}
		if($exchange) {
			$c->[$d]=$c->[$a];
			$c->[$a]=$t;
		}
	}
	
	$a=undef; $b=undef; $d=undef; $exchange=undef;
	for($a=0; $a<$nc-1; ++$a) {
		$exchange=0;
		$d=$a;
		$t=$n->[$a];
		
		for($b=$a+1; $b < $nc; ++$b) {
			if($n->[$b] < $t) {
				$d=$b;
				$t=$n->[$b];
				$exchange=1;
			}
		}
		if($exchange) {
			$n->[$d]=$n->[$a];
			$n->[$a]=$t;
		}
	}
	
	@$referenceOfItemList=(@$n, @$c);
}

sub InsertionSort {
	my $referenceOfItemList=shift;
	my ($c, $cc, $n, $nc)=_filter($referenceOfItemList);
	
	my ($a, $b, $t);
	
	for($a=1; $a<$cc; ++$a) {
		$t=$c->[$a];
		for($b=$a-1; ($b>=0) && ($t lt $c->[$b]); $b--) {
				$c->[$b+1]=$c->[$b];
		}
		$c->[$b+1]=$t;
	}
	
	$a=undef; $b=undef; $t=undef;
	for($a=1; $a<$nc; ++$a) {
		$t=$n->[$a];
		for($b=$a-1; ($b>=0) && ($t < $n->[$b]); $b--) {
				$n->[$b+1]=$n->[$b];
		}
		$n->[$b+1]=$t;
	}
	
	@$referenceOfItemList=(@$n, @$c);
}

sub ShellSort {
	my $referenceOfItemList=shift;
	my ($c, $cc, $n, $nc)=_filter($referenceOfItemList);
	
	my ($i, $j, $gap, $k, $x);
	
	my @a=(9, 5, 3, 2, 1);
	
	for($k=0; $k<5; $k++) {
		$gap=$a[$k];
		for($i=$gap; $i<$cc; ++$i) {
			$x=$c->[$i];
			for($j=$i-$gap; ($x lt $c->[$j]) && ($j>=0); $j=$j-$gap) {
				$c->[$j+$gap]=$c->[$j];
			}
			$c->[$j+$gap]=$x;
		}
	}
	
	$i=undef; $j=undef; $gap=undef; $k=undef; $x=undef;
	for($k=0; $k<5; $k++) {
		$gap=$a[$k];
		for($i=$gap; $i<$nc; ++$i) {
			$x=$n->[$i];
			for($j=$i-$gap; ($x < $n->[$j]) && ($j>=0); $j=$j-$gap) {
				$n->[$j+$gap]=$n->[$j];
			}
			$n->[$j+$gap]=$x;
		}
	}
	
	@$referenceOfItemList=(@$n, @$c);
}

sub QuickSort {
	my $referenceOfItemList=shift;
	my ($c, $cc, $n, $nc)=_filter($referenceOfItemList);
	
	_quicksortNumber($n, 0, $nc-1);
	_quicksortChar($c, 0, $cc-1);
	
	@$referenceOfItemList=(@$n, @$c);
}

sub _quicksortChar {
	my ($list, $left, $right)=@_;
	
	my ($i, $j, $x, $y);
	
	$i=$left;
	$j=$right;
	
	$x=$list->[($left + $right)/2];
	
	do {
		$i++ while($list->[$i] && ($list->[$i] lt $x) && ($i<$right));
		$j-- while($x && ($x lt $list->[$j]) && ($j>$left));
				
		if($i <= $j) {
			$y=$list->[$i];
			$list->[$i]=$list->[$j];
			$list->[$j]=$y;
			$i++;
			$j--;
		}
	} while($i <= $j);
	
	_quicksortChar($list, $left, $j) if($left < $j);
	_quicksortChar($list, $i, $right) if($j < $right);
}

sub _quicksortNumber {
	my ($list, $left, $right)=@_;
	
	my ($i, $j, $x, $y);
	
	$i=$left;
	$j=$right;
	
	$x=$list->[($left + $right)/2];
	
	do {
		$i++ while($list->[$i] && ($list->[$i] < $x) && ($i<$right));
		$j-- while(( $x < $list->[$j]) && ($j>$left));
		
		if($i <= $j) {
			$y=$list->[$i];
			$list->[$i]=$list->[$j];
			$list->[$j]=$y;
			$i++;
			$j--;
		}
	} while($i <= $j);
	
	_quicksortNumber($list, $left, $j) if($left < $j);
	_quicksortNumber($list, $i, $right) if($j < $right);
}


return 1;

END {}


__END__


=head1 NAME

Algorithm::Sorting - Provide various sorting methods.

=head1 SYNOPSIS

  use Algorithm::Sorting;
  
  my @list=(1, "hello", 123, "abc");
    
  BubbleSort(\@list);
  print "@list\n"; #will print the sorted list.
  
  
  

=head1 DESCRIPTION

In this module, there are many very general sorting Algorithms written for Perl. Those are

	Bubble Sort
	Shaker Sort
	Selection Sort
	Insertion Sort
	Shell Sort
	Quick Sort

Here, all subroutines have same syntax to use.

=over 4

=item BubbleSort

	BubbleSort(\@array);
	print "@array\n";

=item ShakerSort

	ShakerSort(\@array);
	print "@array\n";

=item SelectionSort

	SelectionSort(\@array);
	print "@array\n";	

=item InsertionSort

	InsertionSort(\@array);
	print "@array\n";	

=item ShellSort

	ShellSort(\@array);
	print "@array\n";	

=item QuickSort

	QuickSort(\@array);
	print "@array\n";	

=back

=head1 SEE ALSO

Algorithm and Algorithm::Searching

=head1 AUTHOR

Vipin Singh, E<lt>qwer@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Vipin Singh

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
