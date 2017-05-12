use Test::More tests => 2;
use lib qw(./t/lib);
use TestMasonApp::InterpExecFromScalarRef;

$ENV{CGI_APP_RETURN_ONLY} = 1;

my $output = TestMasonApp::InterpExecFromScalarRef->new->run;
like($output, qr/<title>InterpExecFromScalarRef<\/title>/, "mason scalarref title");
like($output, qr/param : success/, "mason scalarref parameter");

