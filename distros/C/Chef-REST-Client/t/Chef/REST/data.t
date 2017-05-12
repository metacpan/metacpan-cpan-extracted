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
              #'chef_server'     => 'https://api.opscode.com/organizations/',
              'chef_client_name' => '',
              'chef_version'     => '',
          );

isa_ok( $obj, 'Chef::REST::Client' );
ok( $obj->server, 'get chef server' );
ok( $obj->name, 'get chef client name' );

ok( $obj->data->list, 'list data');

print Dumper $obj->data->list;

map{ print Dumper $obj->data( $_->name )->details } $obj->data->list;

print Dumper $obj->data( 'msusers' , 'webro' )->details;

done_testing;