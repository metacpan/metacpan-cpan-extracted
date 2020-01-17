use Test::More;
use CGI::Compile;
use Capture::Tiny 'capture_stdout';

{
    my $str =<<EOL;
#!/usr/bin/perl

print "Content-Type: text/plain\015\012\015\012", <DATA>;

__DATA__
Hello
World
EOL

    my $sub = CGI::Compile->compile(\$str);
    my $out = capture_stdout { $sub->() };
    like $out, qr/Hello\nWorld/;
}

done_testing;

