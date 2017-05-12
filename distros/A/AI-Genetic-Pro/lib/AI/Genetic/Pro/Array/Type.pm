package AI::Genetic::Pro::Array::Type;

use warnings;
use strict;
use Exporter::Lite;
use Tie::Array::Packed;
#=======================================================================
our @EXPORT_OK = qw(
	get_package_by_element_size
	get_array_ref_by_element_size
);
#=======================================================================
sub get_package_by_element_size {
	my $size = shift;
	
	my $type =	#$size <				   32	? undef										:	#  Pure Perl array
				#$size <			   32	? 'AI::Genetic::Pro::Array::Tied'			:	#  Pure Perl array
			 	$size <     		  128	? 'Tie::Array::Packed::Char'				: 	#  8 bits
				$size <     		  256	? 'Tie::Array::Packed::UnsignedChar'		:	#  8 bits
				$size <  		   65_537	? 'Tie::Array::Packed::ShortNative'			:	# 16 bits
				$size < 		  131_073	? 'Tie::Array::Packed::UnsignedShortNative'	:	# 16 bits
				$size < 	2_147_483_648	? 'Tie::Array::Packed::Integer'				:	# 32 bits
				$size < 	4_294_967_297	? 'Tie::Array::Packed::UnsignedInteger'		:	# 32 bits; MAX
				undef;
				
	return unless $type;
	return $type;
}
#=======================================================================
sub get_array_ref_by_element_size {
	my $package = get_package_by_element_size(shift);
	my @array;
	tie @array, $package if $package;
	return \@array;
}
#=======================================================================
1;
