use Test::More tests=>7;

use CGI::Application::Plus::Util;

use CGI;

# Prevent output to STDOUT
$ENV{CGI_APP_RETURN_ONLY} = 1;
$ENV{OLD_CGI_APP_COMPATIBLE} = 1;


BEGIN
{
    chdir './t' ;
    require 'test/TestCGI.pm'  ;
    require 'test/TestApp9.pm'  ;
}

# Test making a modification to the output body
{
    my $q = CGI->new({rm=>"postrun_body"});
    my $app = TestApp9->new(QUERY=>$q);
    my $output = $app->run();
    like($output, qr/^Content\-Type\:\ text\/html/, "Postrun body has headers");
    like($output, qr/Hello world: postrun_body/, "Hello world: postrun_body");
    like($output, qr/postrun\ was\ here/, "Postrun was here");
}


# Test changing HTTP headers
{
    my $q = CGI->new({rm=>"postrun_header"});
    my $app = TestApp9->new(QUERY=>$q);
    my $output = $app->run();
    like($output, qr/302 Moved/, "Postrun header is redirect");
    like($output, qr/postrun.html/, "Postrun header is redirect to postrun.html");
    like($output, qr/Hello world: postrun_header/, "Hello world: postrun_header");
    unlike($output, qr/postrun\ was\ here/, "Postrun was NOT here");
}
