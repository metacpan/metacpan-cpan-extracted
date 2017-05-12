use strict;
use Test::More;
use CGI::PSGI;
use CGI;
use IO::Handle;

my $content = do { local $/; <DATA> };
$content =~ s/\x0A/\x0D\x0A/g; # LF => CR+LF
open my $input, "<", \$content;

my $env = {
    'CONTENT_LENGTH'  => length $content,
    'CONTENT_TYPE'    => 'multipart/form-data; boundary=----BOUNDARY',
    'REQUEST_METHOD'  => 'POST',
    'SERVER_PROTOCOL' => 'HTTP/1.0',
    'psgi.input'      => $input,
};

{
    my $q = CGI::PSGI->new($env);
    is $q->param("bar"), "BAR";

    my $fh = $q->upload("upload_foo");
    is     $fh, "foo.txt";
    isa_ok $fh, "Fh";

    my $body = do { local $/; <$fh> };
    is $body, "FOO";
}

done_testing;

__DATA__
------BOUNDARY
Content-Disposition: form-data; name="upload_foo"; filename="foo.txt"
Content-Type: text/plain

FOO
------BOUNDARY
Content-Disposition: form-data; name="bar"

BAR
------BOUNDARY--
