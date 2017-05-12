use strict;
use FindBin;
use Blosxom::Plugin::Web::Request;
use Test::More tests => 10;

# Stolen from CGI.pm

local %ENV = (
    SCRIPT_NAME       => '/test.cgi',
    SERVER_NAME       => 'perl.org',
    HTTP_CONNECTION   => 'TE, close',
    REQUEST_METHOD    => 'POST',
    SCRIPT_URI        => 'http://www.perl.org/test.cgi',
    CONTENT_LENGTH    => 3285,
    SCRIPT_FILENAME   => '/home/usr/test.cgi',
    SERVER_SOFTWARE   => 'Apache/1.3.27 (Unix)',
    HTTP_TE           => 'deflate,gzip;q=0.3',
    QUERY_STRING      => '',
    REMOTE_PORT       => '1855',
    HTTP_USER_AGENT   => 'Mozilla/5.0 (compatible; Konqueror/2.1.1; X11)',
    SERVER_PORT       => '80',
    REMOTE_ADDR       => '127.0.0.1',
    CONTENT_TYPE      => 'multipart/form-data; boundary=xYzZY',
    SERVER_PROTOCOL   => 'HTTP/1.1',
    PATH              => '/usr/local/bin:/usr/bin:/bin',
    REQUEST_URI       => '/test.cgi',
    GATEWAY_INTERFACE => 'CGI/1.1',
    SERVER_ADDR       => '127.0.0.1',
    DOCUMENT_ROOT     => '/home/develop',
    HTTP_HOST         => 'www.perl.org',
);

local *STDIN;
open STDIN, "< $FindBin::Bin/upload_post_text.txt"
    or die 'missing test file t/upload_post_text.txt';
binmode STDIN;

my $request = Blosxom::Plugin::Web::Request->new;

my @got = sort $request->upload;
my @expected = qw(
    100;100_gif        300x300_gif
    does_not_exist_gif hello_world
);
is_deeply \@got, \@expected;

my $file = $request->upload( '300x300_gif' );
is $file->content_type, 'image/gif';
is $file->size, 1656;
is $file->filename, '300x300.gif';
is $file->basename, '300x300.gif';
isa_ok $file->fh, 'Fh'; # See CGI.pm
isa_ok $file->fh->handle, 'IO::Handle';
isa_ok $file->fh->file, 'IO::File';

my @hello_names = $request->upload( 'hello_world' );
is $hello_names[0]->filename, 'goodbye_world.txt';
is $hello_names[1]->filename, 'hello_world.txt';
