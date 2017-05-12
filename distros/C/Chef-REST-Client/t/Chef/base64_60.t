#--------------------------------------------------------------------#
# Chef::Rest::Client Test Cases                                      #
# @author : Bhavin Patel                                             #
#--------------------------------------------------------------------#

use Test::More;
use Data::Dumper;

my @base;
BEGIN {
use File::Basename qw { dirname };
use File::Spec::Functions qw { splitdir rel2abs };

  @base = ( splitdir( rel2abs ( dirname ( __FILE__ ) ) ) );
  pop @base;
  pop @base;    
  push @INC , join  '/', @base, 'lib';
};

use_ok( 'Chef::REST' );

subtest 'generate split 60 string' => sub {

	pass;
	return ;
	
	my $string = join '', map{ $_ } (1 .. 1000);

	print Dumper split_60 ($string);

	sub split_60 {
  		my ($string,$result) = (@_);
  		my $fp = join '',(split ('', $string, 61))[0..59];
  		my $sp = (split ('', $string, 61))[60];

  		push @{$result} , $fp;

		split_60( $sp,$result) if $sp;

  		return $result; 
	};
};

done_testing;
