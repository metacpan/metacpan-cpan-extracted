use Test::More;
use t::Capture;
use CGI::Compile;

my $sub = CGI::Compile->compile("t/warnings.cgi");

my $stdout = do {
    local $^W = 0;

    capture_out($sub);
};

like $stdout, qr/\s*1\z/, '-w switch preserved';

done_testing;
