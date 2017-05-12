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


use_ok( 'Chef::Header' );
my $obj = new_ok( 'Chef::Header', [
    ]);
ok( $obj->header , 'header' );
ok( $obj->header->hash , 'header has' );
ok( $obj->header->chef_header, 'header chef header' );

subtest 'header verification' => sub {

	my $private_key_file = join '/', @base, 'data', 'private_key.pem';
	my $public_key_file  = join '/', @base, 'data', 'public_key.pem';

	plan skip_all => 'private and public key files not present' 
	unless -e $private_key_file && $public_key_file;

	plan skip_all => 'specific to env';

	use Crypt::OpenSSL::RSA;
	use File::Slurp;

	my $h = $obj->header->chef_header->XOpsAuthorization ;
	my $e = join '', ( $h->{'X-Ops-Authorization-1'} ,
   	                $h->{'X-Ops-Authorization-2'} ,
      	             $h->{'X-Ops-Authorization-3'} ,
         	          $h->{'X-Ops-Authorization-4'} ,
            	       $h->{'X-Ops-Authorization-5'} ,
               	    $h->{'X-Ops-Authorization-6'} );

  	my $public_key = read_file( $public_key_file );
  	my $private_key = read_file ( $private_key_file);
	
	my $rsa_pri = Crypt::OpenSSL::RSA->new_private_key( $private_key );
  
	my $chef_header = $obj->header->chef_header->to_string;
  
  	use Chef::Encoder;
  	my $ce = new Chef::Encoder();
  	my $sign = $rsa_pri->sign( $chef_header );
    
  pass;
};

done_testing;