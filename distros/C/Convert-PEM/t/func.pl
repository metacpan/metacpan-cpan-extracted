use strict;
use Digest::MD5 qw(md5 md5_hex);

### supporting functions
sub miss {
	my($i,$r,$m) = @_;
	return $i if $r;
	push @{$m}, $i unless grep(/^$i$/,@{$m});
	return "";
}

sub run_tests
{
	my($pem,$modules,$tests) = @_;

	#### files
	my %ciphs;
	my @fmiss;
	my @files = grep { miss($_,-e $_->{rx},\@fmiss) } map { $ciphs{$_->{name}}++;$_ } @{$tests};
	if (!@files) {
		plan skip_all => "because these tests require existing encrypted files";
		exit;
	}
	if (@fmiss) {
		diag("Some test files are missing\n  ".join("\n  ", map {colored(['yellow'],$_)} @fmiss));
	}

	#### modules
	my %mods;
	my @mods;
	my @mmiss;
	foreach my$c (keys %ciphs) {
		push @mods, grep {
				!$mods{$_}++
			} grep {
				miss($_,$pem->set_cipher_module($c, $_),\@mmiss)
			} @{$modules};
	}
	if (!@mods) {
		plan skip_all => "because there are no modules installed that support cipher(s) being tested: '".join("', '", sort keys %ciphs)."'. Usually OK";
		exit;
	}

	my $ossl = !system('openssl version > /dev/null');
	my $ossl_ver = `openssl version`;
	my $cnt = 15;
	$cnt += 1 if $ossl;

	my $test_count = 1;												# object creation
	$test_count += scalar(@mods);									# setting ciphers
	$test_count += ( scalar(@mods) * scalar(@files) * $cnt );		# file tests

	plan tests => $test_count;
	diag "Some cipher modules failed to load and cannot be tested: '".join("', '", @mmiss)."'. usually OK" if @mmiss;
	diag "Some test files are missing and cannot be tested: '".join("', '", @fmiss)."'. usually OK" if @fmiss;

	isa_ok $pem, "Convert::PEM";

	# 11 tests per file/cipher
	foreach my $m (@mods)
	{
		note("Start testing module $m");
		ok $pem->set_cipher_module($tests->[0]->{name}, $m), "Setting all $tests->[0]->{name} related ciphers to use modules '$m'";

		foreach my $t (@files)
		{
			my($obj1,$obj2);
			my($dec1,$dec2);
			my($der1,$der2);
			my($h1,$h2);

			# read the file
			ok -e $t->{rx} ,  "file '$t->{rx}' exists";
			lives_ok { $obj1 = $pem->read( Filename => $t->{rx}, Password => "test" ) } "can read '$t->{rx}' file using module $m";
			diag("error occurred reading file $t->{rx}: ".$pem->errstr()) if $pem->errstr();
			ok defined $obj1, "Load $t->{name} encrypted object using module $m";
			lives_ok { $der1 = $pem->to_der( Content => $obj1 ) } "encode object into DER format";
			$h1 = lc md5_hex($der1);
			ok $h1 eq $t->{hash}, "hash '$h1' of key from file $t->{rx} matches expected value of '$t->{hash}'";

			# encode the read object
			lives_ok { $dec1 = $pem->encode( Content => $obj1) } "Encode $t->{name} object from file $t->{rx} without encryption";
			ok defined $dec1, $t->{name}." object encoded successfully";
			diag("error occurred reading file $t->{tx}: ".$pem->errstr()) if $pem->errstr();

			# write the file
			lives_ok { $pem->write( Filename => $t->{tx}, Password => "test", Content => $obj1, Cipher => $t->{name} ) } "can write '$t->{tx}' file using module $m";
			diag("error occurred writing file $t->{tx}: ".$pem->errstr()) if $pem->errstr();

			# re-read the written file
			lives_ok { $obj2 = $pem->read( Filename => $t->{tx}, Password => "test", Cipher => $t->{name} ) } "can re-read '$t->{tx}' file using module $m";
			diag("error occurred reading file $t->{tx}: ".$pem->errstr()) if $pem->errstr();
			ok defined $obj2, "read $t->{name} object from file '$t->{tx}' using module $m";
			lives_ok { $dec2 = $pem->encode( Content => $obj2) } "Encode $t->{name} object from file $t->{tx} without encryption";
			ok defined $dec2, "Write and re-read $t->{name} object encripted using cipher module $m";
			lives_ok { $der2 = $pem->to_der( Content => $obj2 ) } "DER Encode $t->{name} object from file $t->{tx}";
			$h2 = lc md5_hex($der2);
			ok $h2 eq $t->{hash}, "hash '$h2' of key from file $t->{tx} matches expected value of '$t->{hash}'";

			# compare the original with the written/re-read
			ok defined $dec1 && defined $dec2 && $dec1 eq $dec2, "Read original $t->{name} file '$t->{rx}' and match contents to written file '$t->{tx}'";

			# openssl tests
			if ($ossl) {
 				SKIP: {
 					skip("Author Tests only for openssl test", 1) if !$ENV{AUTHOR_TESTING};
 					skip("No support for IDEA-CBC", 1) if (`openssl enc -ciphers` !~ /idea-cbc/m) && ($t->{tx} =~ /idea/);
  					skip("No support for DES", 1) 
  						if (`openssl enc -ciphers` !~ /des-cbc/m) || (($t->{tx} =~ /des.wr.pem/) && ($ossl_ver =~ /OpenSSL 3/));
					ok !system("openssl rsa -in $t->{tx} -passin pass:test -noout 2> /dev/null"), "use openssl to read file '$t->{tx}' encrypted with $t->{name} using module $m";
 				}
			}
			unlink $t->{tx};
		}
	}
}

sub get_rsa
{
	my $rsa_asn = <<ASN1;

   Version ::= INTEGER  --{  v1(0), v2(1), v3(2)  }

   OtherPrimeInfos ::= SEQUENCE --SIZE(1..MAX) OF OtherPrimeInfo

   OtherPrimeInfo ::= SEQUENCE {
      prime             INTEGER,  -- ri
      exponent          INTEGER,  -- di
      coefficient       INTEGER   -- ti
   }

   RSAPrivateKey ::= SEQUENCE {
          version           INTEGER,
          modulus           INTEGER,  -- n
          publicExponent    INTEGER,  -- e
          privateExponent   INTEGER,  -- d
          prime1            INTEGER,  -- p
          prime2            INTEGER,  -- q
          exponent1         INTEGER,  -- d mod (p-1)
          exponent2         INTEGER,  -- d mod (q-1)
          coefficient       INTEGER,  -- (inverse of q) mod p
          otherPrimeInfos   EXPLICIT OtherPrimeInfos OPTIONAL }

ASN1

	return Convert::PEM->new(
		Name 	=> "RSA PRIVATE KEY",
		ASN  	=> $rsa_asn,
		Macro	=>	"RSAPrivateKey",
		@_,
    );
}


1;
