use warnings;
use strict;
use Test::More;

plan tests => 61;

use t::share;
use CGI::Easy::Request;
use CGI::Easy::Headers;
use CGI::Easy::Session;
use URI::Escape qw( uri_escape );
use MIME::Base64;

my ($r, $h, $sess);
my (@hdr);

sub setup_request {
    local (%ENV, *STDIN);
    t::share::setup_request(@_);
    $r    = CGI::Easy::Request->new();
    $h    = CGI::Easy::Headers->new();
    $sess = CGI::Easy::Session->new($r, $h);
}


######################
# CGI::Easy/SYNOPSIS #
######################
ok 1, '----- CGI::Easy/SYNOPSIS';

###############################
setup_request('https', <<'EOF');
GET /index.php?name=powerman&color[]=red&color%5B%5D=green HTTP/1.0
Host: example.com
Cookie: some=123

EOF

ok 1, '--- access basic GET request details';
my $url = "$r->{scheme}://$r->{host}:$r->{port}$r->{path}";
my $param_name  = $r->{GET}{name};
my @param_color = @{ $r->{GET}{'color[]'} };
my $cookie_some = $r->{cookie}{some};
is $url, 'https://example.com:80/index.php',    'scheme/host/port/path';
is $param_name, 'powerman',                     'GET scalar';
is_deeply \@param_color, ['red', 'green'],      'GET array';
is $cookie_some, '123',                         'cookie';

###############################
setup_request('http', <<'EOF');
POST /upload/ HTTP/1.0
Host: example.com
Content-Type: multipart/form-data; boundary=----------2A33hj1wqbMp0fkWlQoYU5
Content-Length: AUTO

------------2A33hj1wqbMp0fkWlQoYU5
Content-Disposition: form-data; name="name"

John Smith
------------2A33hj1wqbMp0fkWlQoYU5
Content-Disposition: form-data; name="age"

20
------------2A33hj1wqbMp0fkWlQoYU5
Content-Disposition: form-data; name="avatar"; filename="C:\images\avatar.png"
Content-Type: image/png

PNG
IMAGE
HERE
------------2A33hj1wqbMp0fkWlQoYU5--
EOF

ok 1, '--- file upload';
my $avatar_image    = $r->{POST}{avatar};
my $avatar_filename = $r->{filename}{avatar};
my $avatar_mimetype = $r->{mimetype}{avatar};
is $avatar_image, "PNG\r\nIMAGE\r\nHERE",       'POST file content';
is $avatar_filename, 'C:\\images\\avatar.png',  'POST file filename';
is $avatar_mimetype, 'image/png',               'POST file mimetype';

###############################
setup_request('http', <<"EOF");
GET / HTTP/1.0
Host: example.com
Cookie: temp=${\uri_escape('a 0 x 5 b 1')}; perm=${\uri_escape("name 'John Smith' y 7")}

EOF

ok 1, '--- easy way to identify visitors and get data stored in cookies';
my $session_id  = $sess->{id};
my $tempcookie_x= $sess->{temp}{x};
my $permcookie_y= $sess->{perm}{y};
ok defined $session_id && length $session_id,   'session id';
is $tempcookie_x, 5,                            'session temp';
is $permcookie_y, 7,                            'session perm';

###############################
setup_request('http', <<'EOF');
GET / HTTP/1.0
Host: example.com

EOF
ok 1, '--- set custom HTTP headers and cookies';
$h->{Expires} = 'Sat, 01 Jan 2000 00:00:00 GMT';
$h->add_cookie({
    name    => 'some',
    value   => 'custom cookie',
    domain  => '.example.com',
    expires => time+86400,
});
my $headers = $h->compose();
@hdr = split /\r\n/, $headers;
is $hdr[0], 'Status: 200 OK',                           'Status:';
is $hdr[1], 'Content-Type: text/html; charset=utf-8',   'Content-Type:';
like $hdr[2], qr/\ADate: \w\w\w, \d\d \w\w\w 20\d\d \d\d:\d\d:\d\d GMT\z/, 'Date:';
like $hdr[3], qr/\ASet-Cookie: sid=/,                   'Set=Cookie: sid';
like $hdr[4], qr/\ASet-Cookie: some=custom%20cookie; /, 'Set=Cookie: some';
is $hdr[5], 'Expires: Sat, 01 Jan 2000 00:00:00 GMT',   'Expires:';
is $#hdr, 5,                                            '(no more headers)';
like $headers, qr/\r\n\r\n\z/,                          'headers end with empty hdr';

###############################
setup_request('http', <<'EOF');
GET / HTTP/1.0
Host: example.com

EOF
ok 1, '--- easy way to store data in cookies';
$sess->{temp}{x} = 'until browser closes';
$sess->{perm}{y} = 'for 1 year';
$sess->save();
@hdr = split /\r\n/, $h->compose();
is $hdr[0], 'Status: 200 OK',                           'Status:';
is $hdr[1], 'Content-Type: text/html; charset=utf-8',   'Content-Type:';
like $hdr[2], qr/\ADate: /,                             'Date:';
like $hdr[3], qr/\ASet-Cookie: sid=/,                   'Set=Cookie: sid';
like $hdr[4], qr/\ASet-Cookie: perm=${\uri_escape("y 'for 1 year'")}; .*; expires=/,
                                                        'Set=Cookie: perm';
like $hdr[5], qr/\ASet-Cookie: temp=${\uri_escape("x 'until browser closes'")}; path=\//,
                                                        'Set=Cookie: temp';
is $#hdr, 5,                                            '(no more headers)';

###############################
setup_request('http', <<'EOF');
GET / HTTP/1.0
Host: example.com

EOF
$h->redirect('http://example.com/');
ok 1, '--- output redirect';
@hdr = split /\r\n/, $h->compose();
is $hdr[0], 'Status: 302 Found',                        'Status:';
is $hdr[1], 'Content-Type: text/html; charset=utf-8',   'Content-Type:'; # TODO?
like $hdr[2], qr/\ADate: /,                             'Date:';
like $hdr[3], qr/\ASet-Cookie: sid=/,                   'Set=Cookie: sid';
is $hdr[4], 'Location: http://example.com/',            'Location:';
is $#hdr, 4,                                            '(no more headers)';

###############################
setup_request('http', <<'EOF');
GET / HTTP/1.0
Host: example.com

EOF
ok 1, '--- output custom reply';
$h->{Status} = '500 Internal Server Error';
$h->{'Content-Type'} = 'text/plain; charset=utf-8';
@hdr = split /\r\n/, $h->compose();
is $hdr[0], 'Status: 500 Internal Server Error',        'Status:';
is $hdr[1], 'Content-Type: text/plain; charset=utf-8',  'Content-Type:';
like $hdr[2], qr/\ADate: /,                             'Date:';
like $hdr[3], qr/\ASet-Cookie: sid=/,                   'Set=Cookie: sid';
is $#hdr, 3,                                            '(no more headers)';

#########################
# CGI::Easy/DESCRIPTION #
#########################
ok 1, '----- CGI::Easy/DESCRIPTION';

###############################
setup_request('http', <<"EOF");
GET /?name=powerman&color[]=red&color[]=green HTTP/1.0
Host: example.com
Cookie: somevar=someval
Authorization: Basic ${\encode_base64('powerman:secret')}

EOF
my $wait_r = {
    # -- URL info
    scheme       => 'http',
    host         => 'example.com',
    port         => 80,
    path         => '/',
    # -- CGI parameters
    GET          => { name => 'powerman', 'color[]' => ['red','green'], },
    POST         => { },
    filename     => { },
    mimetype     => { },
    cookie       => { somevar => 'someval', },
    # -- USER details
    REMOTE_ADDR  => '127.0.0.1',
    REMOTE_PORT  => 12345,
    AUTH_TYPE    => 'Basic',
    REMOTE_USER  => 'powerman',
    REMOTE_PASS  => 'secret',
    # -- original request data
    ENV          => {
        REQUEST_METHOD      => 'GET',
        REQUEST_URI         => '/?name=powerman&color[]=red&color[]=green',
        SERVER_NAME         => 'localhost',
        SERVER_PORT         => 80,
        HTTP_COOKIE         => 'somevar=someval',
        HTTP_AUTHORIZATION  => 'Basic cG93ZXJtYW46c2VjcmV0',
        HTTP_HOST           => 'example.com',
        QUERY_STRING        => 'name=powerman&color[]=red&color[]=green',
        REMOTE_ADDR         => '127.0.0.1',
        REMOTE_PORT         => 12345,
    },
    STDIN        => q{},
    # -- request parsing status
    error        => q{},
};
is_deeply $r, $wait_r,  'CGI::Easy::Request object';

###############################
setup_request('http', <<'EOF');
GET / HTTP/1.0
Host: example.com

EOF
$h->{'Set-Cookie'} = [
    { name=>'mycookie1', value=>'myvalue1' },
    { name=>'x', value=>5,
        domain=>'.example.com', expires=>time+86400 }
];
@hdr = split /\r\n/, $h->compose();
is $hdr[0], 'Status: 200 OK',                           'Status:';
is $hdr[1], 'Content-Type: text/html; charset=utf-8',   'Content-Type:';
like $hdr[2], qr/\ADate: /,                             'Date:';
like $hdr[3], qr/\ASet-Cookie: mycookie1=myvalue1; path=\/\z/,
                                                        'Set=Cookie: mycookie1';
like $hdr[4], qr/\ASet-Cookie: x=5; domain=\.example\.com; path=\/; expires=/,
                                                        'Set=Cookie: x';
is $#hdr, 4,                                            '(no more headers)';

###############################
setup_request('http', <<'EOF');
GET / HTTP/1.0
Host: example.com
Referer: http://example.com/

EOF
ok !defined $sess->{id},                                'no cookie support';

###############################
setup_request('http', <<"EOF");
GET / HTTP/1.0
Host: example.com
Cookie: temp=${\uri_escape('y 5')}

EOF
ok defined $sess->{id},                                 'cookie supported';
$sess->{perm}{x} = 5;
$sess->{perm}{somename} = 'somevalue';
$sess->{temp}{y}++;
$sess->save();
@hdr = split /\r\n/, $h->compose();
is $hdr[0], 'Status: 200 OK',                           'Status:';
is $hdr[1], 'Content-Type: text/html; charset=utf-8',   'Content-Type:';
like $hdr[2], qr/\ADate: /,                             'Date:';
like $hdr[3], qr/\ASet-Cookie: sid=/,                   'Set=Cookie: sid';
like $hdr[4], qr/\ASet-Cookie: perm=(?:somename%20somevalue%20x%205|x%205%20somename%20somevalue); .*; expires=/,
                                                        'Set=Cookie: perm';
like $hdr[5], qr/\ASet-Cookie: temp=y%206; path=\//,    'Set=Cookie: temp';
is $#hdr, 5,                                            '(no more headers)';

