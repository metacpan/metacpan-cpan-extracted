use v5.24;
use experimental 'signatures';
use Test2::V0;
use FindBin '$Bin';
use lib "$Bin/../lib";
use AWS::Signature::V4;
use File::Temp qw< tempdir >;
use Math::BigInt;

# Example from the AWS SigV4 documentation (IAM ListUsers)
my $s = AWS::Signature::V4->new(
   service => 'iam', region => 'us-east-1',
   credentials => {
      access_key_id     => 'AKIDEXAMPLE',
      secret_access_key => 'wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY',
   },
);
my $r = $s->sign(
   method  => 'GET',
   url     => 'https://iam.amazonaws.com/?Action=ListUsers&Version=2010-05-08',
   headers => {'Content-Type' => 'application/x-www-form-urlencoded; charset=utf-8'},
   time    => 1440938160,    # 20150830T123600Z
);
is $r->{signature},
   '5d672d79c15b13162d9279b0855cfba6789a8edb4c82c400e06b5924a6f2b5d7',
   'HMAC signature matches AWS docs';
is $r->{signed_headers}, 'content-type;host;x-amz-date', 'signed headers';

# X.509 variant: verify with openssl itself
SKIP: {
   my $dir = tempdir(CLEANUP => 1);
   skip 'openssl not available', 20 if system("openssl version >/dev/null 2>&1");
   for my $alg (qw< RSA ECDSA >) {
      my $genkey = $alg eq 'RSA'
         ? "openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048"
         : "openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256";
      system("$genkey -out $dir/$alg.key 2>/dev/null") == 0 or die "genkey";
      system("openssl req -new -x509 -key $dir/$alg.key -subj /CN=test "
         . "-days 2 -out $dir/$alg.pem 2>/dev/null") == 0 or die "req";
      system("openssl x509 -in $dir/$alg.pem -pubkey -noout > $dir/$alg.pub") == 0
         or die "pubkey";
      my $verifies = sub ($string_to_sign, $signature) {
         open my $o, '>:raw', "$dir/sts" or die; print {$o} $string_to_sign; close $o;
         open my $g, '>:raw', "$dir/sig" or die; print {$g} pack 'H*', $signature; close $g;
         system("openssl dgst -sha256 -verify $dir/$alg.pub -signature $dir/sig $dir/sts >/dev/null") == 0;
      };
      open my $fh, '<', "$dir/$alg.pem" or die; my $pem = do { local $/; <$fh> };
      my $x = AWS::Signature::V4->new(
         service => 'rolesanywhere', region => 'eu-west-1',
         x509 => {key_type  => $alg, certificate => $pem,
                  private_key_file => "$dir/$alg.key"},
      );
      my $t = $x->sign(method => 'POST',
         url => 'https://rolesanywhere.eu-west-1.amazonaws.com/sessions',
         headers => {'Content-Type' => 'application/json'},
         body => '{"a":1}', time => 1440938160);
      my $xf = AWS::Signature::V4->new(
         service => 'rolesanywhere', region => 'eu-west-1',
         x509 => {key_type  => $alg, certificate_file => "$dir/$alg.pem",
                  private_key => do { open my $k, '<', "$dir/$alg.key" or die; local $/; <$k> }},
      );
      my $tf = $xf->sign(method => 'POST',
         url => 'https://rolesanywhere.eu-west-1.amazonaws.com/sessions',
         headers => {'Content-Type' => 'application/json'},
         body => '{"a":1}', time => 1440938160);
      is $tf->{headers}{'x-amz-x509'}, $t->{headers}{'x-amz-x509'},
         "$alg certificate_file equals certificate";
      system("openssl pkey -in $dir/$alg.key -outform DER -out $dir/$alg.der") == 0
         or die "pkey der";
      my $der = do { open my $k, '<:raw', "$dir/$alg.der" or die; local $/; <$k> };
      for my $variant ([private_key_file => "$dir/$alg.der"], [private_key => $der]) {
         my ($opt, $val) = @$variant;
         my $xd = AWS::Signature::V4->new(
            service => 'rolesanywhere', region => 'eu-west-1',
            x509 => {key_type  => $alg, certificate_file => "$dir/$alg.pem", $opt => $val},
         );
         my $td = $xd->sign(method => 'GET',
            url => 'https://rolesanywhere.eu-west-1.amazonaws.com/sessions',
            time => 1440938160);
         ok $verifies->($td->{string_to_sign}, $td->{signature}), "$alg DER $opt signature verifies";
      }
      my $xk = AWS::Signature::V4->new(
         service => 'rolesanywhere', region => 'eu-west-1',
         x509 => {key_type  => $alg, certificate_file => "$dir/$alg.pem",
                  private_key => $der, private_key_file => "$dir/nonexistent.key"},
      );
      my $tk = $xk->sign(method => 'GET',
         url => 'https://rolesanywhere.eu-west-1.amazonaws.com/sessions',
         time => 1440938160);
      ok $verifies->($tk->{string_to_sign}, $tk->{signature}),
         "$alg private_key wins over private_key_file";
      system("openssl pkey -in $dir/$alg.key -aes256 -passout pass:s3cret -out $dir/$alg.enc 2>/dev/null") == 0
         or die "pkey enc";
      for my $variant ([private_key_file => "$dir/$alg.enc"],
            [private_key => do { open my $k, '<', "$dir/$alg.enc" or die; local $/; <$k> }]) {
         my ($opt, $val) = @$variant;
         my $xe = AWS::Signature::V4->new(
            service => 'rolesanywhere', region => 'eu-west-1',
            x509 => {key_type  => $alg, certificate_file => "$dir/$alg.pem",
                     $opt => $val, private_key_password => 's3cret'},
         );
         my $te = $xe->sign(method => 'GET',
            url => 'https://rolesanywhere.eu-west-1.amazonaws.com/sessions',
            time => 1440938160);
         ok $verifies->($te->{string_to_sign}, $te->{signature}),
            "$alg encrypted $opt signature verifies";
      }
      is dies { AWS::Signature::V4->new(service => 'x', region => 'y', x509 => {
            key_type  => $alg, certificate_file => "$dir/$alg.pem",
            private_key_file => "$dir/$alg.enc", private_key_password => 'wrong'}) },
         object { prop blessed => 'Ouch'; call code => 400 },
         "$alg wrong password is rejected";
      like $t->{authorization},
         qr{^AWS4-X509-$alg-SHA256 Credential=\d+/20150830/eu-west-1/rolesanywhere/aws4_request, SignedHeaders=content-type;host;x-amz-date;x-amz-x509, Signature=[0-9a-f]+$},
         "$alg authorization shape";
      my $serial = qx{openssl x509 -in $dir/$alg.pem -noout -serial};
      my ($hex) = $serial =~ /serial=(\w+)/;
      my ($got) = $t->{authorization} =~ /Credential=(\d+)\//;
      is $got, Math::BigInt->from_hex($hex)->bstr, "$alg serial decimal";
      ok $verifies->($t->{string_to_sign}, $t->{signature}), "$alg signature verifies";
   }
}
done_testing;
