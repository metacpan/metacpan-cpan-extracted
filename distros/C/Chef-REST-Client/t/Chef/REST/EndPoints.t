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
  pop @base;    
  push @INC , join  '/', @base, 'lib';
};

use_ok('Chef::REST::Client::EndPoints');

my $obj = new_ok( 'Chef::REST::Client::EndPoints');

can_ok ( $obj , 'new' );
can_ok( $obj , 'api_end_point' );

done_testing();