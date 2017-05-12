use Test::More;
use File::Spec;

use lib './t';
use strict;
use CGI::Application::Plugin::Session;

eval {
    require CGI::Simple;
    CGI::Simple->import;
};

if ($@) {
    plan skip_all => "CGI::Simple required for this test";
    exit;
}

plan tests => 12;

$ENV{CGI_APP_RETURN_ONLY} = 1;

use TestAppCGISimple;
my $t1_obj = TestAppCGISimple->new(QUERY=>CGI::Simple->new());
my $t1_output = $t1_obj->run();

like($t1_output, qr/session created/, 'session created');
like($t1_output, qr/query=CGI::Simple/, 'using CGI::Simple');
like($t1_output, qr/Set-Cookie: CGISESSID=[a-zA-Z0-9]+/, 'session cookie set');

my ($id1) = $t1_output =~ /id=([a-zA-Z0-9]+)/s;
ok($id1, 'found session id');

# Session object will not dissapear and be written
# to disk until it is DESTROYed
undef $t1_obj;

# Set a cookie in $ENV{HTTP_COOKIE}
$ENV{HTTP_COOKIE} = CGI::Session->name.'='.$id1;

my $t2_obj = TestAppCGISimple->new(QUERY=>CGI::Simple->new());
my $t2_output = $t2_obj->run();

like($t2_output, qr/session found/, 'session found');
like($t2_output, qr/value=test1/, 'session parameter retrieved');
like($t2_output, qr/query=CGI::Simple/, 'using CGI::Simple');
unlike($t2_output, qr/Set-Cookie: CGISESSID=[a-zA-Z0-9]+/, 'session cookie not set');

undef $t2_obj;
unlink File::Spec->catdir('t', 'cgisess_'.$id1);

# test with an expired cookie
$ENV{HTTP_COOKIE} = CGI::Session->name.'=badsessionid';

my $t3_obj = TestAppCGISimple->new(QUERY=>CGI::Simple->new());
my $t3_output = $t3_obj->run();

like($t3_output, qr/session created/, 'session created');
unlike($t3_output, qr/value=test1/, 'session parameter not found');
like($t3_output, qr/query=CGI::Simple/, 'using CGI::Simple');
like($t3_output, qr/Set-Cookie: CGISESSID=[a-zA-Z0-9]+/, 'session cookie set');

my ($id3) = $t3_output =~ /id=([a-zA-Z0-9]+)/s;
undef $t3_obj;
unlink File::Spec->catdir('t', 'cgisess_'.$id3);
