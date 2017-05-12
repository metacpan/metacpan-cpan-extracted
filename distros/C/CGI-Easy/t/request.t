use warnings;
use strict;
use Test::More;

plan tests=>73;

use t::share;
use CGI::Easy::Request;
use URI::Escape qw( uri_escape );
use MIME::Base64;

my ($r);
my ($REQUEST, @hdr);

sub setup_request {
    my $opt = shift;
    local (%ENV, *STDIN);
    t::share::setup_request(@_);
    $r    = CGI::Easy::Request->new($opt);
}


$REQUEST = <<'EOF';
GET / HTTP/1.0
Host: example.com
Authorization: NonBasic Something

EOF
setup_request({}, 'http', $REQUEST);
is $r->{error}, 'failed to parse HTTP_AUTHORIZATION',   'error: Authorization';

$REQUEST = <<'EOF';
POST / HTTP/1.0
Host: example.com
Content-Type: application/x-www-form-urlencoded
Content-Length: AUTO

EOF
setup_request({}, 'http', $REQUEST . ('X' x (1024*1024)));
is $r->{error}, q{},                                    'no error: POST 1MiB';
setup_request({}, 'http', $REQUEST . ('X' x (1024*1024+1)));
is $r->{error}, 'POST body too large',                  'error: POST >1MiB';
setup_request({max_post=>1024*1024*10}, 'http', $REQUEST . ('X' x (1024*1024+1)));
is $r->{error}, q{},                                    'no error: POST 10MiB max';

$REQUEST = <<'EOF';
POST / HTTP/1.0
Host: example.com
Content-Type: application/x-www-form-urlencoded
Content-Length: 5

EOF
setup_request({}, 'http', $REQUEST . 'XXXXXX');
is $r->{error}, q{},                                    'no error: Content-Length too small';
is $r->{STDIN}, 'XXXXX',                                'extra STDIN ignored';
setup_request({}, 'http', $REQUEST . 'XXXXX');
is $r->{error}, q{},                                    'no error: Content-Length ok';
setup_request({}, 'http', $REQUEST . 'XXXX');
is $r->{error}, 'POST body incomplete',                 'error: Content-Length too large';

########################

$REQUEST = <<'EOF';
GET / HTTP/1.0
Host: example.com
X-Real-REMOTE_ADDR: 10.0.0.1
X-Real-REMOTE_PORT: 6666
X-Real-HTTPS: on

EOF
setup_request({}, 'http', $REQUEST);
is $r->{REMOTE_ADDR}, '127.0.0.1',                      'frontend: wrong addr';
is $r->{REMOTE_PORT}, 12345,                            'frontend: wrong port';
is $r->{scheme}, 'http',                                'frontend: wrong scheme';
setup_request({frontend_prefix=>'X-Real-'}, 'http', $REQUEST);
is $r->{REMOTE_ADDR}, '10.0.0.1',                       'frontend: right addr';
is $r->{REMOTE_PORT}, 6666,                             'frontend: right port';
is $r->{scheme}, 'https',                               'frontend: right scheme';

$REQUEST = <<'EOF';
GET / HTTP/1.0
Host: example.com

EOF
setup_request({frontend_prefix=>'X-Real-'}, 'http', $REQUEST);
is $r->{REMOTE_ADDR}, '127.0.0.1',                      'no frontend: right addr';
is $r->{REMOTE_PORT}, 12345,                            'no frontend: right port';
is $r->{scheme}, 'http',                                'no frontend: right scheme';

########################

$REQUEST = <<'EOF';
GET http://evil.com:666/ HTTP/1.0
Host: example.com

EOF
setup_request({}, 'http', $REQUEST);
is $r->{host}, 'evil.com',                              'hostname conflict';
is $r->{port}, 80,                                      'port';
is $r->{path}, '/',                                     'path';

########################

$REQUEST = <<'EOF';
GET http://evil.com HTTP/1.0
Host: example.com

EOF
setup_request({}, 'http', $REQUEST);
is $r->{host}, 'evil.com',                              'hostname conflict';
is $r->{port}, 80,                                      'port';
is $r->{path}, '/',                                     'path';

########################

$REQUEST = <<'EOF';
GET / HTTP/1.0
Host: example.com

EOF
{
    local (%ENV, *STDIN);
    t::share::setup_request('http', $REQUEST);
    $ENV{AUTH_TYPE}     = 'Basic';
    $ENV{REMOTE_USER}   = 'powerman';
    $r    = CGI::Easy::Request->new();
}
is $r->{AUTH_TYPE}, 'Basic',                            '.htpasswd AUTH_TYPE';
is $r->{REMOTE_USER}, 'powerman',                       '.htpasswd REMOTE_USER';
is $r->{REMOTE_PASS}, undef,                            '.htpasswd REMOTE_PASS';

$REQUEST = <<"EOF";
GET / HTTP/1.0
Host: example.com
Authorization: Basic ${\encode_base64('powerman:')}

EOF
setup_request({}, 'http', $REQUEST);
is $r->{AUTH_TYPE}, 'Basic',                            'custom AUTH_TYPE';
is $r->{REMOTE_USER}, 'powerman',                       'custom REMOTE_USER';
is $r->{REMOTE_PASS}, q{},                              'custom REMOTE_PASS';

########################

my $wait_params = {
    name        => 'powerman',
    'color[]'   => ['red','green'],
};

$REQUEST = <<'EOF';
HEAD /?name=powerman&color[]=red&color%5B%5D=green HTTP/1.0
Host: example.com
Content-Type: application/x-www-form-urlencoded
Content-Length: 7

a=5&b=6
EOF
setup_request({}, 'http', $REQUEST);
is $r->{ENV}{REQUEST_METHOD}, 'HEAD',                   'method HEAD';
is_deeply $r->{GET}, $wait_params,                      'params in {GET}';
is_deeply $r->{POST}, {},                               'empty {POST}';

$REQUEST = <<'EOF';
DELETE /?name=powerman&color[]=red&color%5B%5D=green HTTP/1.0
Host: example.com
Content-Type: application/x-www-form-urlencoded
Content-Length: 7

a=5&b=6
EOF
setup_request({}, 'http', $REQUEST);
is $r->{ENV}{REQUEST_METHOD}, 'DELETE',                 'method DELETE';
is_deeply $r->{GET}, $wait_params,                      'params in {GET}';
is_deeply $r->{POST}, {},                               'empty {POST}';

$REQUEST = <<'EOF';
PUT /?a=5&b=6 HTTP/1.0
Host: example.com
Content-Type: application/x-www-form-urlencoded
Content-Length: 43

name=powerman&color[]=red&color%5B%5D=green
EOF
setup_request({}, 'http', $REQUEST);
is $r->{ENV}{REQUEST_METHOD}, 'PUT',                    'method PUT';
is_deeply $r->{GET}, {},                                'empty {GET}';
is_deeply $r->{POST}, $wait_params,                     'params in {POST}';

$REQUEST = <<'EOF';
POST /?a=5&b=6 HTTP/1.0
Host: example.com
Content-Type: application/x-www-form-urlencoded
Content-Length: 43

name=powerman&color[]=red&color%5B%5D=green
EOF
setup_request({post_with_get=>1}, 'http', $REQUEST);
is $r->{ENV}{REQUEST_METHOD}, 'POST',                   'method POST';
is_deeply $r->{GET}, {a=>5,b=>6},                       'params in {GET}';
is_deeply $r->{POST}, $wait_params,                     'params in {POST}';

########################

$REQUEST = <<'EOF';
GET /?name=powerman&name=someone&color[]=red&color%5B%5D=green HTTP/1.0
Host: example.com

EOF
setup_request({}, 'http', $REQUEST);
is_deeply $r->{GET}, $wait_params,                      'params in {GET}';

my $wait_all_params = {
    name        => ['powerman'],
    'color[]'   => ['red','green'],
};
$REQUEST = <<'EOF';
GET /?name=powerman&color[]=red&color%5B%5D=green HTTP/1.0
Host: example.com

EOF
setup_request({keep_all_values=>1}, 'http', $REQUEST);
is_deeply $r->{GET}, $wait_all_params,                  'all params in {GET}';

########################

use utf8;
my $hi_str = 'Привет';
my $hi_bin = $hi_str;
utf8::encode($hi_bin);

$REQUEST = <<"EOF";
GET /?greet=${\uri_escape($hi_bin)} HTTP/1.0
Host: example.com

EOF
setup_request({}, 'http', $REQUEST);
is_deeply $r->{GET}, {greet=>$hi_str},                  'Unicode param value';
setup_request({raw=>1}, 'http', $REQUEST);
is_deeply $r->{GET}, {greet=>$hi_bin},                  'raw param value';

$REQUEST = <<"EOF";
GET /?${\uri_escape($hi_bin)}=greet HTTP/1.0
Host: example.com
Cookie: greet=${\uri_escape($hi_bin)}; ${\uri_escape($hi_bin)}=greet

EOF
setup_request({}, 'http', $REQUEST);
is_deeply $r->{GET}, {$hi_str=>'greet'},                'Unicode param name';
is $r->{cookie}{greet}, $hi_str,                        'Unicode cookie value';
is $r->{cookie}{$hi_str}, 'greet',                      'Unicode cookie name';
setup_request({raw=>1}, 'http', $REQUEST);
is_deeply $r->{GET}, {$hi_bin=>'greet'},                'raw param name';
is $r->{cookie}{greet}, $hi_bin,                        'raw cookie value';
is $r->{cookie}{$hi_bin}, 'greet',                      'raw cookie name';

$REQUEST = <<"EOF";
POST / HTTP/1.0
Host: example.com
Content-Type: application/x-www-form-urlencoded
Content-Length: 85

greet=${\uri_escape($hi_bin)}\&${\uri_escape($hi_bin)}=greet
EOF
setup_request({}, 'http', $REQUEST);
is $r->{POST}{greet}, $hi_str,                          'POST Unicode value';
is $r->{POST}{$hi_str}, 'greet',                        'POST Unicode name';
setup_request({raw=>1}, 'http', $REQUEST);
is $r->{POST}{greet}, $hi_bin,                          'POST raw value';
is $r->{POST}{$hi_bin}, 'greet',                        'POST raw name';

$REQUEST = <<"EOF";
POST /upload/ HTTP/1.0
Host: example.com
Content-Type: multipart/form-data; boundary=----------2A33hj1wqbMp0fkWlQoYU5
Content-Length: AUTO

------------2A33hj1wqbMp0fkWlQoYU5
Content-Disposition: form-data; name="greet"

$hi_bin
------------2A33hj1wqbMp0fkWlQoYU5
Content-Disposition: form-data; name="$hi_bin"

greet
------------2A33hj1wqbMp0fkWlQoYU5
Content-Disposition: form-data; name="avatar"; filename="C:\\images\\$hi_bin.png"
Content-Type: image/png

$hi_bin
------------2A33hj1wqbMp0fkWlQoYU5--
EOF
setup_request({}, 'http', $REQUEST);
is $r->{POST}{greet}, $hi_str,                          'POST multipart Unicode value';
is $r->{POST}{$hi_str}, 'greet',                        'POST multipart Unicode name';
is $r->{POST}{avatar}, $hi_bin,                         'POST multipart raw file';
is $r->{filename}{avatar}, "C:\\images\\$hi_str.png",   'POST multipart Unicode filename';

########################

$REQUEST = <<'EOF';
POST /?a=5&b=6&name=someone&color[]=blue HTTP/1.0
Host: example.com
Content-Type: application/x-www-form-urlencoded
Content-Length: 43

name=powerman&color[]=red&color%5B%5D=green
EOF
setup_request({post_with_get=>1}, 'http', $REQUEST);
is_deeply [sort $r->param()], [sort 'a','b','name','color[]'],  'param()';
is scalar $r->param('a'), 5,                                    'scalar param(a)';
is scalar $r->param('b'), 6,                                    'scalar param(b)';
is scalar $r->param('name'), 'powerman',                        'scalar param(name)';
is scalar $r->param('color[]'), 'red',                          'scalar param(color[])';
is_deeply [$r->param('a')], [5],                                'array param(a)';
is_deeply [$r->param('b')], [6],                                'array param(b)';
is_deeply [$r->param('name')], ['powerman','someone'],          'array param(name)';
is_deeply [$r->param('color[]')], ['red','green','blue'],       'array param(color[]) SCALAR';
setup_request({}, 'http', $REQUEST);
is_deeply [sort $r->param()], [sort 'name','color[]'],          'param()';
is scalar $r->param('name'), 'powerman',                        'scalar param(name)';
is scalar $r->param('color[]'), 'red',                          'scalar param(color[])';
is_deeply [$r->param('name')], ['powerman'],                    'array param(name)';
is_deeply [$r->param('color[]')], ['red','green'],              'array param(color[]) SCALAR';

