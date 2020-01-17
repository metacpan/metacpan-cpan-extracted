use Test::More;
use Capture::Tiny 'capture_stdout';
use CGI::Compile;

my $sub = CGI::Compile->compile("t/warnings.cgi");

my $stdout = do {
    local $^W = 0;

    capture_stdout { $sub->() };
};

like $stdout, qr/\s*1\z/, '-w switch preserved';

done_testing;
