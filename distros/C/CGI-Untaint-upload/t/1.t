use Test::More tests => 3;

BEGIN {
open FORM, "t/testdata" or die $!;
*STDIN = *FORM;
local $/;
my $formdata = <STDIN>;
seek STDIN, 0, 0;
$ENV{CONTENT_LENGTH} = length $formdata;
$ENV{CONTENT_TYPE} = "multipart/form-data; boundary=----------0xKhTmLbOuNdArY";
$ENV{REQUEST_METHOD} = "POST";
}

use CGI::Untaint;
use CGI;
my $x = CGI->new;
my $handler = CGI::Untaint->new( map { $_ => $x->param($_) } $x->param);
my $uploaded = $handler->extract(-as_upload => "filetest");

is(ref($uploaded), "HASH", "We got the right sort of thing back");

is($uploaded->{filename}, "mynat", "Filename correct");

# Not superfluous! It caught a bug in _untaint_payload_re!
like($uploaded->{payload}, qr/^#!.*any to any$/s, "Payload correct");
