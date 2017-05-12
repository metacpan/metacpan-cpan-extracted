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

plan tests => 5;

$ENV{CGI_APP_RETURN_ONLY} = 1;

use TestAppIncludePath;
$ENV{TT_INCLUDE_PATH} = 't/include1';
my $t1_obj = TestAppIncludePath->new();
my $t1_output = $t1_obj->run();

like($t1_output, qr/include path: t\/include1/, 'include path');
like($t1_output, qr/template dir: include1/, 'template dir');

$ENV{TT_INCLUDE_PATH} = 't/include2';
my $t2_obj = TestAppIncludePath->new();
my $t2_output = $t2_obj->run();

like($t2_output, qr/include path: t\/include2/, 'include path second time');
like($t2_output, qr/template dir: include2/, 'template dir second time');

is_deeply($t1_obj->tt_include_path, [qw[t/include2]],'returns current paths');

