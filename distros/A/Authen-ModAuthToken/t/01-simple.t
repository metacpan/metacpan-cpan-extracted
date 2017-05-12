use strict;
use warnings;

use Test::More ;

plan tests => 1;

use Authen::ModAuthToken qw/generate_mod_auth_token/;

my $web_server = "http://my.server.com" ;
my $prefix_url = "/protected";

my $file_to_protect = "/myfile.txt";

my $token = generate_mod_auth_token(
			secret => "FlyingMonkeys",
			filepath => $file_to_protect ) ;

my $url = $web_server . $prefix_url . $token ;

#print STDERR "url = $url\n";

pass("simple1");
