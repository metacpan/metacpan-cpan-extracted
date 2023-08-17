use Test::More;
use Capture::Tiny 'capture_stdout';
use CGI::Compile;

my $sub = eval {
    CGI::Compile->compile("t/switch.cgi");
};

is $@, '', 'CGI with source filter compiles' or do {
    done_testing;
    exit;
};

my $stdout = capture_stdout { $sub->() };
is $stdout, "filter works\n", 'source filter works in CGI';

done_testing;
