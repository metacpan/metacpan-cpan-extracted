package Algorithm::Searching;

use strict;
use warnings;

our $VERSION = '0.05';



BEGIN { 
	use Exporter();
	use Algorithm::Sorting;
	our @ISA=qw(Exporter);
	our @EXPORT=qw(&SequentialSearch &BinarySearch);
}



sub SequentialSearch {
	my ($list, $key)=@_;
	my $size=$#$list+1;
	my $t;
	
	for($t=0; $t<$size; ++$t) {
		return $t if("$key" eq "$list->[$t]");
	}
	return -1;
}

sub BinarySearch {
	my ($list, $key)=@_;

	my ($low, $high, $mid);
	$low=0;
	$high=$#$list;
	while($low<=$high) {
		$mid=int(($low+$high)/2);
		if($key lt $list->[$mid]) {
			$high=$mid-1;
		} 
		elsif($key gt $list->[$mid]) {
			$low=$mid+1;
		}
		else {
			return $mid;
		}
	}
	return -1;
}
		

return 1;

END {}


__END__

=head1 NAME

Algorithm::Searching - Provide Sequential Search & Binary Search methods.

=head1 SYNOPSIS

  use Algorithm::Searching;
  
  my @list=(1, "hello", 123, "abc");
  my $key="abc";
  
  #it will return index of the key if found, else -1
  my $index=SequentialSearch(\@list, $key);
  
  use Algorithm::Sorting;
  QuickSort(\@list);  #for binary search array must be sorted
  #it will return index of key if found, else -1
  my $return=BinarySearch(\@list, $key);  
  

=head1 DESCRIPTION

In this module, there are two very general searching Algorithms(Sequential Search & Binary Search) written for Perl.

=over 4

=item SequentialSearch

The subroutine performs sequential search on the list which may contain number or/and characters. In return gives index of the item searching for if found, else -1.

	my $index=SequentialSearch(\@array, $key);

=item BinarySearch

The subroutine performs the Binary search method on the list which may contain number or/and characters. In return it gives index of key if found, else -1.

	my $return=BinarySearch(\@array, $key);



=back


=head1 SEE ALSO

Algorithm::Sorting and Algorithm

=head1 AUTHOR

Vipin Singh, E<lt>qwer@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Vipin Singh

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
