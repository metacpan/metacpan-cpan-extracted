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

# list cookbooks
# endpoint /cookbooks
#diag Dumper $obj->cookbooks->list;

#endpoint /cookbook/yum
#diag Dumper $obj->cookbooks('yum','_latest')->details->attributes;
diag Dumper $obj->cookbooks('yum','_latest')->details->recipes;

#diag Dumper $obj->environments( $environment_name )->details;

# endpoint POST /environments/<env_name>/cookbooks_versions
# post data run_list => [ <cookbook>@<cookbook_version> , .. ]
#___ TESTING not complete ____
#diag Dumper $obj->environments( $environment_name
#                              ,'cookbooks_versions'
#                              , {
#                              	method => 'post'
#                                ,data   => {
#                              					runlist => [ $runlist ]
#                                          }
#                                }
#                              );
                              

done_testing;