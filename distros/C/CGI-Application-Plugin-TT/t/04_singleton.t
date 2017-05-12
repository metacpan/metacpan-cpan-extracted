use Test::More;

use lib './t';
use strict;

eval {
  require Class::ISA;
  Class::ISA->import;
};
 
if ($@) {
  plan skip_all => "Class::ISA required for Singleton support";
  exit;
}

plan tests => 6;

$ENV{CGI_APP_RETURN_ONLY} = 1;

use TestAppSingleton;
my $t1_obj = TestAppSingleton->new();
my $t1_output = $t1_obj->run();

like($t1_output, qr/template param\./, 'template parameter');
like($t1_output, qr/template param hash\./, 'template parameter hash');
like($t1_output, qr/template param hashref\./, 'template parameter hashref');
like($t1_output, qr/pre_process param\./, 'pre process parameter');
like($t1_output, qr/post_process param\./, 'post process parameter');

# make sure the CGI::Application instance is destroyed, and then check for TT object
undef $t1_obj;
ok(ref($TestAppSingleton::__TT_OBJECT), 'singleton still exists');

