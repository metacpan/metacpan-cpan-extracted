use Test::More;
use CGI::Compile;
use Capture::Tiny 'capture_stdout';

{
    my $sub = CGI::Compile->compile("t/data.cgi");
    my $out = capture_stdout { $sub->() };
    like $out, qr/Hello\nWorld/;
}

{
    my $sub = CGI::Compile->compile("t/data_crlf.cgi");
    my $out = capture_stdout { $sub->() };
    like $out, qr/Hello\r?\nWorld/;
}

eval {
    my $sub = CGI::Compile->compile("t/end.cgi");
};

is $@, '';

eval {
    my $sub = CGI::Compile->compile("t/end_crlf.cgi");
};

is $@, '';

{
    local $main::FLNO;
    my $sub = CGI::Compile->compile(\<<'EOF');
$main::FLNO = fileno DATA;
print +(<DATA>)[0,3];
__DATA__
line 1
line 2
line 3
line 4
EOF

    my $out = capture_stdout { $sub->() };
    like $out, qr/line 1\r?\nline 4/;

    $out = capture_stdout { $sub->() };
    like $out, qr/line 1\r?\nline 4/;

    is $main::FLNO, -1;
}

{
    local $main::S;
    my $sub = CGI::Compile->compile(\<<'EOF');
$main::S = $^S;
EOF

    $sub->();
    is $main::S, 1;
}

done_testing;
