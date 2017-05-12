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

use_ok( 'Chef::Encoder' );

use_ok(  'File::Slurp' );

my $obj = new_ok( 'Chef::Encoder' );
my $pk = join '/' , @base , 'data', 'private_key.pem';

if (  ! -e $pk )
{
   diag " $pk does not exist skipping all tests";
   done_testing;
   exit 0;
}

subtest 'sha1 tests' => sub {
  isa_ok( $obj->sha1 , 'Chef::Encoder::sha1' );
  ok(  $obj->sha1->digest( 'data' => 'GenSHA1OfTEMP') , 'sha1 digest');
};

subtest 'base64 tests' => sub {
  isa_ok( $obj->base64 , 'Chef::Encoder::base64');
  #ok( $obj->base64( 'data' => 'bhavin' )->encode , 'encoding "bhavin" to base64 ');
};


subtest 'pki tests' => sub {
  isa_ok( $obj->pki , 'Chef::Encoder::pki' );
  ok( $obj->pki->rsa_private( 'private_key_file' => $pk )->sign( 'bhavin' ) , 'sign' );
  ok( $obj->pki
          ->rsa_private( 'private_key_file' => $pk )
          ->verify( 'bhavin',
                    $obj->pki
                        ->rsa_private( 'private_key_file' => $pk )
                        ->sign( 'bhavin' )
                  ),
             "verifying signature" 
          );
};

done_testing;
