use Test::More;
use Switch;
use Capture::Tiny 'capture_stdout';
use CGI::Compile;

my $sub = eval {
    CGI::Compile->compile("t/switch.cgi");
};

if ($@) {
    fail 'CGI with source filter compiles';
    done_testing;
    exit;
}

my $stdout = capture_stdout { $sub->() };
is $stdout, "switch works\n", 'source filter works in CGI';

done_testing;
