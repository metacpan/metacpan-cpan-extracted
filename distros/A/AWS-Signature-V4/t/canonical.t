use v5.24;
use utf8;
use experimental 'signatures';
use Test2::V0;
use FindBin '$Bin';
use lib "$Bin/../lib";
use AWS::Signature::V4;
use Digest::SHA qw< sha256_hex >;

my %cred = (access_key_id => 'AKID', secret_access_key => 'SECRET');
my $std = AWS::Signature::V4->new(service => 'service', region => 'us-east-1', credentials => {%cred});
my $s3  = AWS::Signature::V4->new(service => 's3',      region => 'us-east-1', credentials => {%cred});

sub canon ($signer, $url, %rest) {
   my $r = $signer->sign(method => 'GET', url => $url, time => 1440938160, %rest);
   my @lines = split /\n/, $r->{canonical_request}, -1;
   return ($lines[1], $lines[2], $r);    # path, query, whole result
}
sub path_of  ($signer, $url) { (canon($signer, $url))[0] }
sub query_of ($signer, $url) { (canon($signer, $url))[1] }
sub req (@args) { (canon(@args))[2] }

# errors caused by the caller: Ouch exceptions with code 400
sub bad ($re = qr/./) {
   object { prop blessed => 'Ouch'; call code => 400; call message => match $re };
}

subtest 'path, non-S3 (normalized, double-encoded)' => sub {
   my %case = (    # from the AWS SigV4 test suite
      'https://h'                      => '/',
      'https://h/'                     => '/',
      'https://h/example/..'           => '/',
      'https://h/./'                   => '/',
      'https://h/./example'            => '/example',
      'https://h//example//'           => '/example/',
      'https://h/example/./a/../b'     => '/example/b',
      'https://h/../a'                 => '/a',
      'https://h/example/'             => '/example/',
      'https://h/example space/'       => '/example%2520space/',
      'https://h/example%20space/'     => '/example%2520space/',
      'https://h/%E1%88%B4'            => '/%25E1%2588%25B4',
      'https://h/a-._~b'               => '/a-._~b',
      'https://h/a$b'                  => '/a%2524b',
   );
   is path_of($std, $_), $case{$_}, $_ for sort keys %case;
};

subtest 'path, S3 (verbatim, single-encoded)' => sub {
   my %case = (
      'https://h/'                 => '/',
      'https://h/example space/'   => '/example%20space/',
      'https://h/example%20space/' => '/example%20space/',
      'https://h/a/../b'           => '/a/../b',
      'https://h//a//b'            => '//a//b',
      'https://h/%E1%88%B4'        => '/%E1%88%B4',
      'https://h/a$b'              => '/a%24b',
   );
   is path_of($s3, $_), $case{$_}, $_ for sort keys %case;
};

subtest 'query' => sub {
   my %case = (
      'https://h/'                                 => '',
      'https://h/?'                                => '',
      'https://h/?Param1=value1'                   => 'Param1=value1',
      'https://h/?Param2=v2&Param1=v1'             => 'Param1=v1&Param2=v2',
      'https://h/?a=2&a=1&a=3'                     => 'a=1&a=2&a=3',
      'https://h/?B=1&a=1&b=1&A=1'                 => 'A=1&B=1&a=1&b=1',
      'https://h/?a&b='                            => 'a=&b=',
      'https://h/?a=&a=x'                          => 'a=&a=x',
      'https://h/?k=a b'                           => 'k=a%20b',
      'https://h/?k=a%20b'                         => 'k=a%20b',
      'https://h/?k=a%2fb'                         => 'k=a%2Fb',
      'https://h/?k=a/b:c'                         => 'k=a%2Fb%3Ac',
      'https://h/?-._~=-._~'                       => '-._~=-._~',
      'https://h/?%E1%88%B4=%E1%88%B4'             => '%E1%88%B4=%E1%88%B4',
      'https://h/?a=1&&b=2'                        => 'a=1&b=2',
      'https://h/?a=x=y'                           => 'a=x%3Dy',
      'https://h/?a=1#frag'                        => 'a=1',
   );
   is query_of($std, $_), $case{$_}, $_ for sort keys %case;
   is query_of($s3, 'https://h/?b=2&a=1'), 'a=1&b=2', 'S3 sorts too';
};

subtest 'url must be ASCII' => sub {
   is dies { canon($std, 'https://h/ሴ') }, bad(qr/ASCII/), 'non-ASCII path rejected';
   is dies { canon($std, 'https://h/?ሴ=1') }, bad(qr/ASCII/), 'non-ASCII query rejected';
   is dies { canon($std, "https://h/\x{e9}") }, bad(qr/ASCII/), 'latin-1 character rejected';
};

subtest 'host' => sub {
   my %case = (
      'https://example.com/'          => 'example.com',
      'https://example.com:443/'      => 'example.com',
      'http://example.com:80/'        => 'example.com',
      'https://example.com:8443/'     => 'example.com:8443',
      'http://example.com:443/'       => 'example.com:443',
      'https://example.com'           => 'example.com',
      'https://STS.Amazonaws.com/'    => 'sts.amazonaws.com',
      'https://h:0443/'               => 'h',
      'https://h:/'                   => 'h',
      'https://h:08443/'              => 'h:8443',
      'HTTPS://h:443/'                => 'h',
      'https://[::1]:443/'            => '[::1]',
   );
   for my $url (sort keys %case) {
      is req($std, $url)->{headers}{host}, $case{$url}, $url;
   }
   like req($std, 'https://STS.Amazonaws.com/')->{canonical_request},
      qr/\nhost:sts\.amazonaws\.com\n/, 'the lowercase host is signed';
   is req($std, 'https://a/', headers => {Host => 'b'})->{headers}{host}, 'b',
      'explicit Host wins';
   is dies { canon($std, 'https://user:pw@example.com/') }, bad(qr/user/),
      'user information is refused';
   for my $url ('https://evil.example\\.b.s3.amazonaws.com/x', 'https://b s3/',
         'https://h:abc/', 'https://h:443:443/', 'https://h:123456/') {
      is dies { canon($std, $url) }, bad(qr/invalid/), "invalid url: $url";
   }
};

subtest 'headers' => sub {
   my $r = req($std, 'https://h/', headers => {
      'X-Amz-Meta-B' => '  a   b  ',
      'x-amz-meta-a' => "tab\there",
      'X-Multi'      => ['1', '2'],
      'User-Agent'   => 'ignored',
      'Authorization' => 'ignored',
   });
   like $r->{canonical_request},
      qr{\nhost:h\nx-amz-date:20150830T123600Z\nx-amz-meta-a:tab here\nx-amz-meta-b:a b\nx-multi:1,2\n\nhost;x-amz-date;x-amz-meta-a;x-amz-meta-b;x-multi\n},
      'lowercased, sorted, trimmed, collapsed, multi-valued joined';
   unlike $r->{signed_headers}, qr/user-agent|authorization/, 'unsigned headers left out';
   is $r->{headers}{'user-agent'}, 'ignored', 'but still returned';

   # arrayref pairs, repeated names are merged
   $r = req($std, 'https://h/', headers => [X => 'a', x => 'b']);
   like $r->{canonical_request}, qr/\nx:a,b\n/, 'repeated header names merged';

   $r = req($std, 'https://h/',
      headers => {A => 1, B => 2}, signed_headers => ['B', 'Host', 'x-amz-date']);
   is $r->{signed_headers}, 'b;host;x-amz-date', 'explicit signed_headers';
   is dies { canon($std, 'https://h/', signed_headers => ['nope']) },
      bad(qr/missing header/), 'signing a missing header croaks';

   # only ASCII whitespace is trimmed: 0xA0 and 0x85 are UTF-8 bytes here
   $r = req($std, 'https://h/', headers => {
      'x-amz-meta-title' => "citt\xC3\xA0", 'x-amz-meta-ni' => " \xE4\xBD\xA0\x85 "});
   like $r->{canonical_request}, qr/\nx-amz-meta-title:citt\xC3\xA0\n/, 'trailing 0xA0 kept';
   like $r->{canonical_request}, qr/\nx-amz-meta-ni:\xE4\xBD\xA0\x85\n/,
      'inner 0xA0 and 0x85 kept, spaces trimmed';

   # undefined values are like missing headers
   is warns {
      $r = req($std, 'https://h/', headers => {Host => undef, 'X-A' => undef, 'X-B' => ['1', undef]});
   }, 0, 'undefined header values: no warnings';
   is $r->{headers}{host}, 'h', 'undefined Host: taken from the url';
   ok !exists $r->{headers}{'x-a'}, 'undefined value: no header';
   is $r->{headers}{'x-b'}, '1', 'undefined items of a list are skipped';

   # names that differ only in case are joined in a repeatable order
   is req($std, 'https://h/', headers => {'X-Foo' => 'a', 'x-foo' => 'b', 'X-FOO' => 'c'})
      ->{headers}{'x-foo'}, 'c,a,b', 'sorted by name as given';
};

subtest 'x-amz-* headers are always signed' => sub {
   my $t = AWS::Signature::V4->new(service => 's3', region => 'r',
      credentials => {%cred, session_token => 'TOK'});
   my $r = $t->sign(method => 'PUT', url => 'https://b.s3.amazonaws.com/k', time => 0,
      headers => {'Content-Type' => 'text/plain', 'X-Amz-Acl' => 'private'},
      signed_headers => ['content-type'], body => 'abc');
   is $r->{signed_headers},
      'content-type;host;x-amz-acl;x-amz-content-sha256;x-amz-date;x-amz-security-token',
      'those given and those added by sign';
   is req($std, 'https://h/', signed_headers => [])->{signed_headers}, 'host;x-amz-date',
      'even with an empty list';
};

subtest 'payload' => sub {
   my $empty = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';
   my $r = req($std, 'https://h/');
   like $r->{canonical_request}, qr/\n$empty\z/, 'empty body';
   ok !exists $r->{headers}{'x-amz-content-sha256'}, 'no payload header outside S3';

   $r = req($s3, 'https://h/');
   is $r->{headers}{'x-amz-content-sha256'}, $empty, 'S3 payload header';
   like $r->{signed_headers}, qr/x-amz-content-sha256/, 'and it is signed';

   $r = req($std, 'https://h/', unsigned_payload => 1);
   like $r->{canonical_request}, qr/\nUNSIGNED-PAYLOAD\z/, 'unsigned payload';

   $r = req($std, 'https://h/', payload_hash => 'STREAMING-X');
   like $r->{canonical_request}, qr/\nSTREAMING-X\z/, 'explicit payload hash';

   $r = req($std, 'https://h/', body => "\xc3\xa9");
   like $r->{canonical_request}, qr/\n\Q@{[ sha256_hex("\xc3\xa9") ]}\E\z/,
      'byte strings are hashed as they are';
   is dies { canon($std, 'https://h/', body => "\x{263a}") },
      bad(qr/byte string/), 'wide characters in the body are rejected';

   $r = req($std, 'https://h/', body => 'abc', payload_hash => undef);
   like $r->{canonical_request}, qr/\n\Q@{[ sha256_hex('abc') ]}\E\z/,
      'undefined payload_hash: the body is hashed';
   $r = req($std, 'https://h/', payload_hash => 'BA7816BF8F01CFEA414140DE5DAE2223B00361A396177A9CB410FF61F20015AD');
   like $r->{canonical_request}, qr/\nba7816bf[0-9a-f]{56}\z/, 'hex payload_hash is lowercased';
   for my $hash ("x\r\nX-Injected: 1", 'HASH', 'a' x 63, {}) {
      is dies { canon($s3, 'https://h/', payload_hash => $hash) }, bad(qr/payload_hash/),
         'invalid payload_hash ' . (ref $hash || $hash =~ s/[\r\n]/?/gr);
   }
};

subtest 'payload header' => sub {
   my $lambda = AWS::Signature::V4->new(service => 'lambda', region => 'r', credentials => {%cred});
   my $r = req($lambda, 'https://h/', body => '{}', unsigned_payload => 1);
   is $r->{headers}{'x-amz-content-sha256'}, 'UNSIGNED-PAYLOAD', 'unsigned payload: header added';
   like $r->{signed_headers}, qr/x-amz-content-sha256/, 'and signed';
   $r = req($lambda, 'https://h/', payload_hash => 'STREAMING-X');
   is $r->{headers}{'x-amz-content-sha256'}, 'STREAMING-X', 'same for any marker';

   my $abc = sha256_hex('abc');
   $r = req($s3, 'https://h/', headers => {'X-Amz-Content-Sha256' => $abc});
   is $r->{headers}{'x-amz-content-sha256'}, $abc, 'S3: the header given is kept';
   like $r->{canonical_request}, qr/\n$abc\z/, 'and used as the payload hash';
   $r = req($lambda, 'https://h/', headers => {'X-Amz-Content-Sha256' => 'UNSIGNED-PAYLOAD'});
   like $r->{canonical_request}, qr/\nUNSIGNED-PAYLOAD\z/, 'other services too';
   is $r->{headers}{'x-amz-content-sha256'}, 'UNSIGNED-PAYLOAD', 'and it is sent';
   $r = req($s3, 'https://h/', headers => {'X-Amz-Content-Sha256' => $abc}, body => 'abc');
   like $r->{canonical_request}, qr/\n$abc\z/, 'it can agree with the body';
   is dies { canon($lambda, 'https://h/', body => 'abc',
         headers => {'X-Amz-Content-Sha256' => 'UNSIGNED-PAYLOAD'}) },
      bad(qr/does not match/), 'a header that disagrees with the body is refused';
   is dies { canon($s3, 'https://h/', headers => {'X-Amz-Content-Sha256' => 'nope'}) },
      bad(qr/x-amz-content-sha256/), 'an invalid header is refused';
};

subtest 'S3 under other names' => sub {
   for my $name (qw< s3-object-lambda s3-outposts s3express >) {
      my $t = AWS::Signature::V4->new(service => $name, region => 'r', credentials => {%cred});
      my ($path, undef, $r) = canon($t, 'https://h/a%20b//c/../d');
      is $path, '/a%20b//c/../d', "$name: path verbatim";
      is $r->{headers}{'x-amz-content-sha256'}, sha256_hex(''), "$name: payload header";
      like $t->presign(url => 'https://h/', time => 0)->{canonical_request},
         qr/\nUNSIGNED-PAYLOAD\z/, "$name: presign with UNSIGNED-PAYLOAD";
   }
   my $t = AWS::Signature::V4->new(service => 's3x', region => 'r', credentials => {%cred});
   is path_of($t, 'https://h/a/../b'), '/b', 'but not any name starting with s3';
};

subtest 'body as scalar reference' => sub {
   my $body = 'some payload';
   my $plain = req($std, 'https://h/', body => $body);
   my $byref = req($std, 'https://h/', body => \$body);
   is $byref->{signature}, $plain->{signature}, 'same signature by reference';
   is $body, 'some payload', 'referenced body untouched';

   my $big = 'x' x 10_000_000;
   my $b1 = req($std, 'https://h/', body => \$big);
   like $b1->{canonical_request}, qr/\n[0-9a-f]{64}\z/, 'large body by reference';

   my $chars = "\x{263a}";
   is dies { canon($std, 'https://h/', body => \$chars) }, bad(qr/byte string/),
      'wide characters rejected through a reference too';
   my $latin = "\xe9"; utf8::upgrade($latin);
   my $l = req($std, 'https://h/', body => \$latin);
   my $l2 = req($std, 'https://h/', body => "\xe9");
   is $l->{signature}, $l2->{signature}, 'upgraded latin-1 string hashes as bytes';
   ok utf8::is_utf8($latin), 'and the input string was not downgraded';

   my $undef;
   my $e1 = req($std, 'https://h/', body => \$undef);
   my $e2 = req($std, 'https://h/');
   is $e1->{signature}, $e2->{signature}, 'reference to undef is an empty body';
   is dies { canon($std, 'https://h/', body => []) }, bad(qr/body/), 'array reference rejected';
   is dies { canon($std, 'https://h/', body => sub {}) }, bad(qr/body/), 'code reference rejected';
};

subtest 'method, scope, token' => sub {
   my $r = $std->sign(method => 'post', url => 'https://h/', time => 1440938160);
   like $r->{canonical_request}, qr/\APOST\n/, 'method uppercased';
   is $r->{scope}, '20150830/us-east-1/service/aws4_request', 'scope';
   like $r->{authorization},
      qr{^AWS4-HMAC-SHA256 Credential=AKID/20150830/us-east-1/service/aws4_request, SignedHeaders=host;x-amz-date, Signature=[0-9a-f]{64}$},
      'authorization header';

   my $t = AWS::Signature::V4->new(service => 'service', region => 'r',
      credentials => {%cred, session_token => 'TOK'});
   $r = $t->sign(method => 'GET', url => 'https://h/', time => 0);
   is $r->{headers}{'x-amz-security-token'}, 'TOK', 'session token header';
   like $r->{signed_headers}, qr/x-amz-security-token/, 'is signed';
   like $r->{headers}{'x-amz-date'}, qr/^19700101T000000Z$/, 'epoch 0';
};

subtest 'constructor errors' => sub {
   is dies { AWS::Signature::V4->new(region => 'r', credentials => {%cred}) },
      bad(qr/service/), 'no service';
   is dies { AWS::Signature::V4->new(service => 's', credentials => {%cred}) },
      bad(qr/region/), 'no region';
   is dies { AWS::Signature::V4->new(service => 's', region => 'r') },
      bad(qr/credentials/), 'no credentials';
   is dies { AWS::Signature::V4->new(service => 's', region => 'r', credentials => {access_key_id => 'x'}) },
      bad(qr/secret_access_key/), 'missing secret';
   is dies { AWS::Signature::V4->new(service => 's', region => 'r', credentials => {%cred, token => 'T'}) },
      bad(qr/unknown option "token" in credentials/), 'unknown credentials option';
   is dies { AWS::Signature::V4->new(service => 's', region => "us-east-1\r\nX-Evil: 1",
         credentials => {%cred}) }, bad(qr/region/), 'invalid region';
   is dies { AWS::Signature::V4->new(service => 'a/b', region => 'r', credentials => {%cred}) },
      bad(qr/service/), 'invalid service';
};

subtest 'arguments' => sub {
   is $std->sign({method => 'GET', url => 'https://h/', time => 0})->{signature},
      $std->sign(method => 'GET', url => 'https://h/', time => 0)->{signature},
      'a hash reference is the same as a list of pairs';
   is dies { $std->sign(method => 'GET', url => 'https://h/', 'time') },
      bad(qr/pairs/), 'odd list';
   is dies { canon($std, 'https://h/', content => 'x') }, bad(qr/unsupported for sign: "content"/),
      'unknown parameter';
   is dies { canon($std, 'https://h/', expires => 60) }, bad(qr/unsupported for sign: "expires"/),
      'presign-only parameter';
   for my $name (qw< body payload_hash unsigned_payload >) {
      is dies { canon($s3, 'https://h/', streaming => 1, decoded_content_length => 1, $name => 'x') },
         bad(qr/"$name" does not apply to streaming/), "$name with streaming";
   }
   is dies { canon($std, 'https://h/', decoded_content_length => 1) },
      bad(qr/needs streaming/), 'streaming option without streaming';

   my %bad = (
      'headers as a string'       => [headers => 'Host: h'],
      'odd headers array'         => [headers => ['X-A']],
      'header value a hash'       => [headers => {'X-A' => {}}],
      'wide header value'         => [headers => {'X-A' => "\x{263a}"}],
      'signed_headers a string'   => [signed_headers => 'host'],
      'signed_headers empty str'  => [signed_headers => ''],
      'method not a token'        => [method => "GET\n/other"],
      'method with a byte > 127'  => [method => "\xff"],
      'empty method'              => [method => ''],
      'method a reference'        => [method => {}],
      'time in nanoseconds'       => [time => 1440938160 * 1e9],
      'time as a date'            => [time => '2015-08-30T12:36:00Z'],
      'negative time'             => [time => -1],
      'url a reference'           => [url => []],
   );
   for my $name (sort keys %bad) {
      is dies { $std->sign(method => 'GET', url => 'https://h/', $bad{$name}->@*) }, bad(), $name;
   }
   is req($std, 'https://h/', time => 1440938160.75)->{headers}{'x-amz-date'},
      '20150830T123600Z', 'fractional time is fine';
};

subtest 'url path and query' => sub {
   for my $url ('foo/bar', 'folder/file.txt', 'x') {
      is dies { canon($std, $url, headers => {Host => 'h'}) }, bad(qr{start with "/"}),
         "relative path $url refused";
   }
   is path_of($std, 'https://h?a=1'), '/', 'empty path is fine';
   is req($std, '/a/b', headers => {Host => 'h'})->{headers}{host}, 'h', 'absolute path with Host';
   is dies { canon($std, 'https://h/?prefix=a+b') }, bad(qr/\+/), 'plus sign in the query refused';
   is query_of($std, 'https://h/?prefix=a%2Bb%20c'), 'prefix=a%2Bb%20c', 'encoded is fine';
   is path_of($std, 'https://h/a+b'), '/a%252Bb', 'plus sign in the path is a plus sign';
   for my $url ('https://h/public/%2e%2e/admin', 'https://h/a/%2E/b', 'https://h/a/.%2e/b') {
      is dies { canon($std, $url) }, bad(qr/dot segment/), "encoded dot segment: $url";
   }
   is path_of($s3, 'https://h/public/%2e%2e/admin'), '/public/../admin',
      'S3 does not normalize: fine there';
};

subtest 'values that the module puts in headers or in the query' => sub {
   my $signer = sub (%creds) {
      AWS::Signature::V4->new(service => 'service', region => 'r',
         credentials => {%cred, %creds});
   };
   my $t = $signer->(session_token => "TOKEN\n");
   is dies { $t->sign(method => 'GET', url => 'https://h/') },
      bad(qr/x-amz-security-token/), 'session token with a newline';
   my $k = $signer->(access_key_id => "AKID\r\nX-Evil: 1");
   is dies { $k->sign(method => 'GET', url => 'https://h/') },
      bad(qr/authorization/), 'access key id with CR/LF';

   # wide characters would reach sha256_hex, or _uri_encode in presign, and
   # die there instead of being reported as bad input
   my $w = $signer->(session_token => "TOK\x{263a}EN");
   is dies { $w->sign(method => 'GET', url => 'https://h/') },
      bad(qr/x-amz-security-token.*byte string/), 'session token with a wide character';
   is dies { $w->presign(url => 'https://h/') },
      bad(qr/X-Amz-Security-Token.*byte string/), '... in a presigned url too';
   my $wk = $signer->(access_key_id => "AKID\x{263a}");
   is dies { $wk->sign(method => 'GET', url => 'https://h/') },
      bad(qr/authorization.*byte string/), 'access key id with a wide character';
   is dies { $wk->presign(url => 'https://h/') },
      bad(qr/X-Amz-Credential.*byte string/), '... in a presigned url too';
};

done_testing;
