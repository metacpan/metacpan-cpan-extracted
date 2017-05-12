use Test::More tests => 27;

use lib './t';
use strict;

$ENV{CGI_APP_RETURN_ONLY} = 1;

use TestAppTName;
my $t1_obj = TestAppTName->new();
my $t1_output = $t1_obj->run();

like($t1_output, qr/file: test_mode\.tmpl/, 'correct template file');
like($t1_output, qr/:template param:/, 'template parameter');
like($t1_output, qr/:template param hash:/, 'template parameter hash');
like($t1_output, qr/:template param hashref:/, 'template parameter hashref');
like($t1_output, qr/:pre_process param:/, 'pre process parameter');
like($t1_output, qr/:post_process param:/, 'post process parameter');
like($t1_output, qr/:TestAppTName[\/\\]test_mode\.tmpl:/, 'template name ok');


my $t2_obj = TestAppTName::CustName->new();
my $t2_output = $t2_obj->run();

like($t2_output, qr/file: test\.tmpl/, 'correct template file');
like($t2_output, qr/:template param:/, 'template parameter');
like($t2_output, qr/:template param hash:/, 'template parameter hash');
like($t2_output, qr/:template param hashref:/, 'template parameter hashref');
like($t2_output, qr/:pre_process param:/, 'pre process parameter');
like($t2_output, qr/:post_process param:/, 'post process parameter');
like($t2_output, qr/:TestAppTName[\/\\]test\.tmpl:/, 'template name ok');


my $t3_obj = TestAppTName::NoVars->new();
my $t3_output = $t3_obj->run();

like($t3_output, qr/file: test_mode\.tmpl/, 'correct template file');
like($t3_output, qr/:pre_process param:/, 'pre process parameter');
like($t3_output, qr/:post_process param:/, 'post process parameter');


my $t4_obj = TestAppTName::NoNameNoVars->new();
my $t4_output = $t4_obj->run();

like($t4_output, qr/file: test_mode\.tmpl/, 'correct template file');
like($t4_output, qr/:pre_process param:/, 'pre process parameter');
like($t4_output, qr/:post_process param:/, 'post process parameter');

my $t5_obj = TestAppTName::UpLevel->new();
my $t5_output = $t5_obj->run();

like($t5_output, qr/file: test_mode\.tmpl/, 'correct template file');
like($t5_output, qr/:template param:/, 'template parameter');
like($t5_output, qr/:template param hash:/, 'template parameter hash');
like($t5_output, qr/:template param hashref:/, 'template parameter hashref');
like($t5_output, qr/:pre_process param:/, 'pre process parameter');
like($t5_output, qr/:post_process param:/, 'post process parameter');
like($t5_output, qr/:TestAppTName[\/\\]UpLevel[\/\\]test_mode\.tmpl:/, 'template name ok');


