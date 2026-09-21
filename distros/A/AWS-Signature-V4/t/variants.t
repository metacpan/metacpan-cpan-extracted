use v5.24;
use Test2::V0;
use FindBin '$Bin';
use lib "$Bin/../lib";
use experimental 'signatures';
use MIME::Base64 qw< encode_base64 >;
use AWS::Signature::V4;
use AWS::Signature::V4::Credentials;
use AWS::Signature::V4::X509;

sub bad_request ($name) {
   object { prop blessed => 'Ouch'; call code => 400; call message => match qr/\Q$name\E/ };
}

subtest 'credentials' => sub {
   my $c = AWS::Signature::V4::Credentials->new(
      access_key_id => 'AKIDEXAMPLE',
      secret_access_key => 'wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY',
   );
   is $c->algorithm, 'AWS4-HMAC-SHA256', 'algorithm';
   is $c->credential_id, 'AKIDEXAMPLE', 'credential id is the access key';
   ok $c->can_sign_chunks, 'it can sign chunks';
   is [$c->extra_fields], [], 'no token, no extra fields';

   my $scope = '20150830/us-east-1/iam/aws4_request';
   is unpack('H*', $c->signing_key($scope)),
      'c4afb1cc5771d871763a393e44b703571b55cc28424d1a5e86da6ed3c154a4b9',
      'signing key, from the AWS documentation';
   like $c->signature($scope, 'anything'), qr/\A[0-9a-f]{64}\z/, 'hex signature';

   my $t = AWS::Signature::V4::Credentials->new(
      access_key_id => 'a', secret_access_key => 'b', session_token => 'TOKEN');
   is [$t->extra_fields], ['X-Amz-Security-Token' => 'TOKEN'], 'the session token';
   $t = AWS::Signature::V4::Credentials->new(
      access_key_id => 'a', secret_access_key => 'b', session_token => '');
   is [$t->extra_fields], [], 'an empty session token is no token';
   my $s = AWS::Signature::V4->new(service => 'sts', region => 'us-east-1',
      credentials => {access_key_id => 'a', secret_access_key => 'b', session_token => ''});
   my $r = $s->sign(method => 'GET', url => 'https://sts.amazonaws.com/', time => 0);
   ok !exists $r->{headers}{'x-amz-security-token'}, 'no empty token header';
   unlike $r->{signed_headers}, qr/security-token/, 'no empty token signed';
   unlike $s->presign(url => 'https://sts.amazonaws.com/', time => 0)->{url},
      qr/Security-Token/, 'no empty token presigned';

   is dies { AWS::Signature::V4::Credentials->new(secret_access_key => 'b') },
      bad_request('credentials/access_key_id'), 'access key is needed';
   is dies { AWS::Signature::V4::Credentials->new(access_key_id => 'a') },
      bad_request('credentials/secret_access_key'), 'secret is needed';
   is dies { AWS::Signature::V4::Credentials->new(access_key_id => '', secret_access_key => 'b') },
      bad_request('credentials/access_key_id'), 'access key cannot be empty';
   is dies { AWS::Signature::V4::Credentials->new(access_key_id => 'a', secret_access_key => '') },
      bad_request('credentials/secret_access_key'), 'secret cannot be empty';
};

subtest 'x509' => sub {
   my $der   = "\x30\x03\x02\x01\x05";     # tiny but well-formed DER
   my $chain = "\x30\x03\x02\x01\x06";
   my %x = (certificate => $der, serial => 7, signer => sub { "\x01\x02" });

   my $x = AWS::Signature::V4::X509->new(key_type  => 'ecdsa', %x);
   is $x->algorithm, 'AWS4-X509-ECDSA-SHA256', 'algorithm, from the key type';
   is $x->credential_id, 7, 'credential id is the serial';
   ok !$x->can_sign_chunks, 'it cannot sign chunks';
   is dies { $x->signing_key('20150830/us-east-1/iam/aws4_request') },
      bad_request('credentials variant'), 'no derived key';
   is $x->signature('any/scope', 'anything'), '0102', 'the signature is the hex of the signer output';
   is [$x->extra_fields], ['X-Amz-X509' => encode_base64($der, '')], 'the certificate';

   $x = AWS::Signature::V4::X509->new(key_type  => 'RSA', %x, chain => [$chain, $chain]);
   is [$x->extra_fields], [
      'X-Amz-X509' => encode_base64($der, ''),
      'X-Amz-X509-Chain' => join(',', (encode_base64($chain, '')) x 2),
   ], 'the certificate and the chain';

   for my $case (
      [chain => {leaf => $chain}], [chain => [$chain, undef]], [chain => [\$chain]],
      [chain_files => {leaf => '/x'}], [chain_files => [undef]],
   ) {
      my ($name, $value) = @$case;
      is dies { AWS::Signature::V4::X509->new(key_type => 'RSA', %x, $name => $value) },
         bad_request("x509/$name"), "$name: " . (ref $value eq 'HASH' ? 'hash' : 'bad item');
   }
   is warns { my $e = dies { AWS::Signature::V4::X509->new(key_type => 'RSA', %x, chain => [undef]) } },
      0, 'undefined chain item: no warnings';

   my %length_errors = (
      'indefinite length'   => "\x30\x80",
      'long form under 128' => "\x30\x81\x03\x02\x01\x05",
      'leading zero byte'   => "\x30\x82\x00\x03\x02\x01\x05",
      'length of 5 bytes'   => "\x30\x85\x00\x00\x00\x00\x03\x02\x01\x05",
   );
   for my $name (sort keys %length_errors) {
      my $bad = $length_errors{$name};
      is dies { AWS::Signature::V4::X509->new(key_type => 'RSA', %x, certificate => $bad) },
         bad_request('not a DER-encoded certificate'), "certificate, $name";
      is dies { AWS::Signature::V4::X509->new(key_type => 'RSA', %x, chain => [$bad]) },
         bad_request('not a DER-encoded certificate'), "chain, $name";
   }
   my $long = "\x30\x81\x80" . ("\x05\x00" x 64);    # long form, when needed
   is [AWS::Signature::V4::X509->new(key_type => 'RSA', %x, certificate => $long)->extra_fields],
      ['X-Amz-X509' => encode_base64($long, '')], 'minimal long form accepted';

   for my $case ([undef, 'undef'], ['', 'empty'], [[1], 'a reference'], ["\x{263a}", 'wide']) {
      my ($out, $name) = @$case;
      my $y = AWS::Signature::V4::X509->new(key_type => 'RSA', %x, signer => sub { $out });
      is dies { $y->signature('any/scope', 'anything') },
         bad_request('x509 signer returned'), "signer returns $name";
   }
   is dies { AWS::Signature::V4->new(service => 'iam', region => 'r',
      x509 => {key_type => 'RSA', %x, signer => sub { undef }})
      ->sign(method => 'GET', url => 'https://h/') },
      bad_request('x509 signer returned no signature'), 'sign reports the signer failure';
   my $z = AWS::Signature::V4::X509->new(key_type => 'RSA', %x, signer => sub { "\x{e9}" });
   is $z->signature('any/scope', 'anything'), 'e9', 'characters under 256 are bytes';

   is dies { AWS::Signature::V4::X509->new(%x) },
      bad_request('x509/key_type'), 'key type is needed';
   is dies { AWS::Signature::V4::X509->new(%x, key_type  => 'DSA') },
      bad_request('RSA or ECDSA'), 'key type is checked';
   is dies { AWS::Signature::V4::X509->new(key_type  => 'RSA', signer => sub { 1 }) },
      bad_request('certificate'), 'certificate is needed';
   is dies { AWS::Signature::V4::X509->new(key_type  => 'RSA', certificate => $der, serial => 1) },
      bad_request('signer'), 'a way to sign is needed';
};

subtest 'the main class gives the same results as the variants' => sub {
   my %cred = (access_key_id => 'AKID', secret_access_key => 'secret');
   my $s = AWS::Signature::V4->new(service => 'iam', region => 'us-east-1', credentials => {%cred});
   my $r = $s->sign(method => 'GET', url => 'https://iam.amazonaws.com/', time => 1440938160);
   my $c = AWS::Signature::V4::Credentials->new(%cred);
   is $r->{signature}, $c->signature($r->{scope}, $r->{string_to_sign}), 'credentials signature';
   is $s->algorithm, $c->algorithm, 'credentials algorithm';

   my $x = AWS::Signature::V4->new(
      service => 'iam', region => 'us-east-1',
      x509 => {key_type  => 'RSA', certificate => "\x30\x03\x02\x01\x05", serial => 9,
               signer => sub { 'sig' }});
   $r = $x->sign(method => 'GET', url => 'https://iam.amazonaws.com/', time => 1440938160);
   is $r->{signature}, unpack('H*', 'sig'), 'x509 signature';
   like $r->{authorization}, qr{Credential=9/20150830/us-east-1/iam/aws4_request}, 'x509 credential';
   ok exists $r->{headers}{'x-amz-x509'}, 'the certificate header';
   is $x->algorithm, 'AWS4-X509-RSA-SHA256', 'x509 algorithm';
};

done_testing;
