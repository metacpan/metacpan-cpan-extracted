#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;
use Cwd;

$ENV{PATH} = $^O eq 'MSWin32' ? "t/bin;$ENV{PATH}" : "t/bin:$ENV{PATH}" ;
$ENV{EDITOR} = 'bluh';
$ENV{HOME} ||= getcwd;
my $c = "$ENV{HOME}/.resty/c/google.com";
$c =~ s(/)(\\)g if $^O eq 'MSWin32';
my @noxdg = (enable_xdg => 0);
subtest 'plugins must be an arrayref' => sub {
   like(exception {
      TestAdenosine->new({
         argv => ['http://google.com'],
         plugins => 'fail',
         @noxdg
      })
   }, qr/plugins must be an arrayref/, 'scalar');

   like(exception {
      TestAdenosine->new({
         argv => ['http://google.com'],
         plugins => {},
         @noxdg
      })
   }, qr/plugins must be an arrayref/, 'hashref');
};
TestAdenosine->new({ argv => ['http://google.com'], @noxdg });
is($TestAdenosine::stdout, "http://google.com*\n", 'http no *');
is($TestAdenosine::uri_base, "http://google.com*", 'uri_base set');
cmp_deeply(\@TestAdenosine::extra_options, [], 'extra options set');

TestAdenosine->new({ argv => ['google.com', '-v', '-H', 'Foo: Bar'], @noxdg });
is($TestAdenosine::stdout, "http://google.com*\n", 'just domain');
is($TestAdenosine::uri_base, "http://google.com*", 'uri_base set');
cmp_deeply(\@TestAdenosine::extra_options, ['-v', '-H', 'Foo: Bar'], 'extra options set');

TestAdenosine->new({
   argv => [],
   plugins => [Plugin1->new],
   @noxdg,
});
is($TestAdenosine::stdout, "http://google.com*\n", 'no args');
cmp_deeply(\@TestAdenosine::extra_options, ['-v', '-H', 'Foo: Bar'], 'extra options remain');

TestAdenosine->new({
   argv => ['https://google.com/user/*/1'],
   plugins => [qw(Plugin1)],
   @noxdg,
});
is($TestAdenosine::stdout, "https://google.com/user/*/1\n", 'https + *');
is($TestAdenosine::uri_base, "https://google.com/user/*/1", 'uri_base set');
cmp_deeply(\@TestAdenosine::extra_options, [], 'extra options cleared');

$TestAdenosine::curl_stderr = <<'BLUUU';
* About to connect() to google.com port 80 (#0)
*   Trying 167.10.21.20... connected
> HEAD / HTTP/1.1
> User-Agent: curl/7.22.0 (x86_64-pc-linux-gnu) libcurl/7.22.0 OpenSSL/1.0.1 zlib/1.2.3.4 libidn/1.23 librtmp/2.3
> Host: google.com
> Accept: */*
>
< HTTP/1.1 200 OK
< Date: Thu, 08 Nov 2012 23:22:28 GMT
< Server: HTTP::Server::PSGI
< Content-Type: application/json
< X-Catalyst: 5.90015
< Vary: Accept-Encoding,User-Agent
* no chunk, no close, no size. Assume close to signal end
<
* Closing connection #0
BLUUU

%TestAdenosine::host_config = ( 'google.com' => <<'CONFIG' );
 GET -H 'Accept: text/html'

 POST -u foo:bar
CONFIG

$TestAdenosine::curl_stdout = <<'BLUU2';
{"some":"json"}
BLUU2

my $exit_code = TestAdenosine->new({ argv => ['GET'], @noxdg });
cmp_deeply(\@TestAdenosine::curl_options, [
   qw(curl -sLv -X GET -b), $c, '-c', $c, '-H', 'Accept: text/html',
   'https://google.com/user//1',
], 'GET');
is($TestAdenosine::stdout, $TestAdenosine::curl_stdout, 'output the right stuff!');

ok(!$exit_code, '200 means exit with 0');

$TestAdenosine::curl_stderr =~ s[(< HTTP/1\.1 )2][${1}5];
$exit_code = TestAdenosine->new({
   argv => [qw(GET 1 -v)],
   plugins => [{ '::Plugin2' => {} }],
   @noxdg,
});
cmp_deeply(\@TestAdenosine::curl_options, [
   qw(curl -sLv -X GET -b), $c, '-c', $c, '-H', 'Accept: text/html',
   'https://google.com/user/1/1',
], 'GET 1');
is($exit_code, 5, '500 exits correctly');
is($TestAdenosine::stderr, "'curl' '-sLv' '-X' 'GET' '-b' '$c' '-c' '$c' '-H' 'Accept: text/html' 'https://google.com/user/1/1'
$TestAdenosine::curl_stderr", '-v works');

TestAdenosine->new({ argv => [qw(POST 2), '{"foo":"bar"}'], @noxdg });
cmp_deeply(\@TestAdenosine::curl_options, [
   qw(curl -sLv {"foo":"bar"} -X POST -b ), $c, '-c', $c, qw(
      --data-binary -u foo:bar https://google.com/user/2/1),
], 'POST 2 $data');

if ($^O ne 'MSWin32') {
   TestAdenosine->new({ argv => [qw(POST 2), '-V'], @noxdg });
   cmp_deeply(\@TestAdenosine::curl_options, [
      qw(curl -sLv), '["frew","bar","baz"]', qw(-X POST -b ), $c, '-c', $c, qw(
         --data-binary -u foo:bar https://google.com/user/2/1),
   ], 'POST -V $data');
}

TestAdenosine->new({ argv => [qw(HEAD -u)], @noxdg });
cmp_deeply(\@TestAdenosine::curl_options, [
   qw(curl -sLv -X HEAD -b), $c, '-c', $c, qw(
     -u -I https://google.com/user//1),
], 'HEAD adds -I');

TestAdenosine->new({ argv => [qw(GET -q foo&bar)], @noxdg });
cmp_deeply(\@TestAdenosine::curl_options, [
   qw(curl -sLv -X GET -b), $c, '-c', $c, qw(
      -H ), 'Accept: text/html', 'https://google.com/user//1?foo%26bar',
], 'GET escaped');

TestAdenosine->new({ argv => [qw(GET -Q -q foo&bar)], @noxdg });
cmp_deeply(\@TestAdenosine::curl_options, [
   qw(curl -sLv -X GET -b), $c, '-c', $c, qw(
      -H ), 'Accept: text/html', 'https://google.com/user//1?foo&bar',
], 'GET not escaped');

{
local $ENV{XDG_CONFIG_HOME} = "$ENV{HOME}/.config";
my $c = "$ENV{XDG_CONFIG_HOME}/resty/c/google.com";
$c =~ s(/)(\\)g if $^O eq 'MSWin32';
TestAdenosine->new({ argv => [qw(GET foo)], });
cmp_deeply(\@TestAdenosine::curl_options, [
   qw(curl -sLv -X GET -b), $c, '-c', $c, qw(
      -H ), 'Accept: text/html', 'https://google.com/user/foo/1',
], 'GET not escaped');
}
done_testing;

BEGIN {
   package TestAdenosine;

   use strict;
   use warnings;

   if ($] >= 5.010) {
     require mro;
   } else {
     require MRO::Compat;
   }

   use lib 'lib';
   use base 'App::Adenosine';

   our @curl_options;
   our $stdout = '';
   our $stderr = '';
   our $curl_stderr;
   our $curl_stdout;
   our $uri_base;
   our %host_config;
   our @extra_options;

   sub _set_uri_base { $uri_base = $_[1] }
   sub _get_uri_base { $uri_base }
   sub _load_host_method_config { split /\n/, $host_config{$_[1]} }

   sub new {
      my $self = shift;

      $stdout = '';
      $stderr = '';

      $self->next::method(@_)
   }

   sub capture_curl {
      my $self = shift;
      @curl_options = @_;

      return ($curl_stdout, $curl_stderr, 0);
   }

   sub stdout { $stdout .= $_[1] }
   sub stderr { $stderr .= $_[1] }

   sub _set_extra_options { my $self = shift; @extra_options = @_ }
   sub _get_extra_options { @extra_options }

   package Plugin1;

   $INC{'Plugin1.pm'} = __FILE__;
   use Moo;

   with 'App::Adenosine::Role::FiltersStdErr';

   sub filter_stderr { $_[1] }

   package App::Adenosine::Plugin::Plugin2;

   $INC{'App/Adenosine/Plugin/Plugin2.pm'} = __FILE__;
   use Moo;

   with 'App::Adenosine::Role::FiltersStdErr';

   sub filter_stderr { $_[1] }
}

