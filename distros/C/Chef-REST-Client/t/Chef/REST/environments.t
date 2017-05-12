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

use_ok( 'Chef::REST::Client' );
use DateTime;

done_testing;
exit 0;

my $obj = new Chef::REST::Client(
              #'chef_server' => 'https://api.opscode.com/organizations/',
              'chef_client_name' => '',
              'chef_version' => '',
          );

isa_ok( $obj, 'Chef::REST::Client' );
ok( $obj->server, 'get chef server' );
ok( $obj->name, 'get chef client name' );

ok ( $obj->environments->list , 'list environments' );
#diag Dumper $obj->environments->list;

# endpoint /environments/<env_name>/
ok( $obj->environments('devenv')->details, 'environments details' );
diag Dumper $obj->environments('devenv')->details;

# endpoint /environments/<env_name>/cookbooks/<cookbook_name>
diag Dumper $obj->environments('product1','cookbooks','cookbook-name')->details;

# get all the cookbooks for a specific environment.
# endpoint /environments/<env name>/cookbooks
#diag Dumper $obj->environments('environment-prod1','cookbooks');

map {
	print Dumper $obj->environments( $_->name )->details;
} $obj->environments->list;


map {
	print Dumper $obj->environments( $_->name )->details;
} $obj->environments->list;


done_testing;