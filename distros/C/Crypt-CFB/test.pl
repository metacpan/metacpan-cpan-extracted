# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

# List of Blockciphers (from CPAN)
# Not included:
# TripleDES (no keysize, encrypt method is named encrypt3),
# RC5 (inherently no keysize, maximum is 4096 bits),
# IDEA (keysize does not work in certain contexts).

my @algos_crypt = map { "Crypt::".$_ } ('DES', 'Blowfish', 'AES', 'Rijndael', 'RC6', 'CAST5_PP', '3DES','Serpent', 'NULL',  'GOST', 'TEA',  'DES_EDE3', 'Twofish','Twofish2'); 

# List of Hash functions (from CPAN)
# Not included: Tiger (no add method)

my @algos_digest = map {"Digest::".$_} ('MD5', 'SHA1', 'RIPEMD160','MD2');

# Silly one-liner to check which of the modules are installed 

my @algos = grep {`perl -M$_ -e "1;" 2> /dev/null`; not $?} (@algos_crypt, @algos_digest);

print "\n";
print "Seems as if we can use the following Crypt/Digest modules:\n";
print join "\n", @algos;
print "\n";

my $number = ($#algos*2) + 3;
		
######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1;}
END {print "not ok 1\n" unless $loaded;}
use Crypt::CFB;
$loaded = 1;
print "1 .. $number\n";
print "ok 1\n";

######################### End of black magic.

my ($key, $i);
for $i (0 .. 55) {
     $key .= unpack "a" , (pack "c", $i);
}

my $testval = << "EOF";
   Uns ist in alten mæren | | wunders vil geseit
   von helden lobebæren | | von grôzer arebeit,
   von freuden, hôchgezîten, | | von weinen und von klagen,
   von küener recken strîten | | muget ir nu wunder hren sagen.
EOF

# Read in test values (see below)
my %tests;
while (<DATA>) {
	my ($k, $vv)  = split;
	$tests{$k} = unpack "a*" ,( pack "H*", $vv);
}

# open O, ">/tmp/tests" or die "a terrible death";

# Test with all available block ciphers and digests
my @t ;
my $tt = 2 ;
foreach $i (0 .. $#algos) {
    $t[$i] = new Crypt::CFB($key, $algos[$i]);
    if (not ($@ eq "")) {
    	print "Error while loading $algos[$i], maybe it is not installed after all\n";
    } else {
        $t[$i]->reset;
        $g = $t[$i]->encrypt($testval);
        $t[$i]->reset;
		if (exists $tests{$algos[$i]}) {
			if ($g eq $tests{$algos[$i]}) {
				print "ok $tt\n";
			} else {
				print "not ok $tt\n";
			}
			$tt++;
		} 
#		else {
#			print O "$algos[$i] ";
#			print O (unpack "H*", (pack "a*", $g));
#			print O "\n";
#		}
			
        $h = $t[$i]->decrypt($g);
        if ($h eq $testval)  {
       	    print "ok $tt\n";
        } else {
    	    print "not ok $tt\n";
        }
		$tt++;
    }
}

# close O;

__DATA__
Crypt::Blowfish 21a7e2e12244d6b15f952f1c250a09cd3e09a88cc33be4e4ba8b5ca8ecd71d172aeff0b26c4d9431167c89391fb163198b438f4c349438584e3b20bef0797d51c40232d7a5918b69904005448f961654ef77bf45b4dd2321bf307c55ba2ffd462099647f1b7d232cd584a7f8968729c49fda43017ec4e075768f4cc114e8ab25743b950aac041dd9e5b666cd58210bd7e2db9413acac29c5d7f350deb8fe9104e3a46687db23722345cceeb52bfbd322e4c5f256dc9b0d9a75f0029c5d5f36da2fc75700e32137f6c6d237d976a57d97a31d61485172324a3ea0ad1bdb
Crypt::DES 505cd1b2bbfec96fd119da6e89fa4b6dc6956ff3476993e5012e7358dc7a945778830acd05cfd71b0793e27bbb0f649460bc5b14594bf299cf5cf9c2719a939982bce3a2b6117a677d2af8d06c07843ceea2927af7628f4f316bb97be980e30d421f94d8d43effa421f89a411e73318f5d34aece6ae98a1d61489336c5bd6d3f8bcf5793a24af307e60ea0e29f045593397baee29d1afd848b4ae48a62f3968e32e14d1e4d641958f968de92d7b57a5eb2a6dff257c482a1f024ef462e765412a9f3ff7a43ad1a212e9a6b1b26cfeff79220410897784001c687610e40
Crypt::DES_EDE3 61e41bc3d080559b16378ad8e2dc3aec54b92ebe1f6fd958ecf305ece3db382f9f2a5eb0fc34bc458a54d2c00e5c2ebdc336a948fd7a56db2820d3ec516fd699c6b325baf4fa34a7f65c203380fc615a142ff271fee243d50c21a5880d11c86fd368c16bc01d67900f6d2d3210e0a85fa7724397fc9937314ca47bd574c6b9b5eb4feb4d6cbaf411cc24cadcc5ea48d0860bfa15c38dda53f494dffc6a3dec7f34a098b9e1e61ebb32465d1ff75c355ea9bdf680cb0516c2e9d4e3c1cd5cc1f622e153819c83f2af63f256750aae38ae7c397a4169c30eef4d0c170407
Crypt::GOST 99ef4c414da74ca6f3a86e84d68c88e0481267602cbb57ddead963d6ec3e8b6f041a5a19ea160141a2d41ad1c3ca5c16e20fc2aef6dc856aad752df6228a2caa4a0503cc0b499c09493ed177b6a088636b5dc62c10d01523dcd69565434bbf90872b5e07189451f688883a415a68df1fb55a445344bdb825d73d0a52f19a6f5958ad82680819f1acc9d6b4a1557bacef99a4203d1ef2b3b398d65214f078e67833f551a4ab95ab6071d092c69a60231a2d057a0c43d5e919d364316745c121dc1e89308cdc8002eaea8569c984d41aeebad59eb10053348856dfa42ede
Crypt::NULL 200020751b6848215226066f0121402c583d53731ef88aef81a1ddfd81a1d6a3cda9ccbecded9bf29ebed9bccfaac3b7bd9dbd9deb84eacaa2c7abcfaac4e488e785e0826416731d3d41611d3d4b244a6a0d7f8bf194e6c6a7d5b0d2b7deaa868cac8cacdab5dbfb9def8aff9bfe90bc9cf400630b6c09739de98ce2ceee92b2ceee98f799b9ceabc2acc9a787f29cf8d8aec1af8fe488e98eeb85a9a383a383f59af4d4bf4326482d5f7f0d680b60056b4b384c3ed0a4c1af8ff3d3af8fe297f095e1c1a8dafa94e1c1b6c3adc9acdefe96e481efcfbcddbadfb19f95
Crypt::RC6 6b8af71a1183e7026dda6081edb34613830cb4601b7a4b0cc6fe7155fc50806d95ef63ed2c5a8257a18224750b09bab6ce029f7d1a4ff8bca7d645528f00d1f9df034a5cc653b638b8d0d2bf8b7eed978fc727ca30b37e0d9c9d9868bad5f00b0b700022735c6a6ab396923cb1a8645a3d83ff31019b7622a2f7ab376d87c3bda11a68ca8008253dc8366309337072d49e24a0ba84c11b367de1aa1db1c0959668776143a2193fbcb45c39b7b2914caceba9dfe81c24fb9dcf9f12319353bcf41e0163b4e68b97f535e33ca54b9ba6353602d49dd726d0f681824a129c
Crypt::Rijndael a068886fb1bca003bef095a6012a305315696b8cdf8740c7f22d912c30dfb9df534306b493a89f66383f5d157e2339ff68a1f88da82ad0a3564ae0084f8c9c237301c292c3b4adb15ea343da91d38320da78474b35765165a92f0dd36d8ee4ad23d0d0d8d3057d3f77957b6d37981b26c6829556a2fc9f0ac52f24ef3813345d6081701e81bb2e02a2135af1e6ded2e1121e4df100599b5f0ef32468dde02063daecd83d96761131afc30abb470b8e95cdb853fe4b947b6570f23d87950eda1a75d73777c6e7539d083194de88c905606fd08568945fcff4cb127dee60
Crypt::Serpent 6ae724ce753187389f1508b62c5a7e3ee7cc6075c6315cb2f6b97a1d7137f399550b2e91a72cfa62a93f442750f38499c72e61f1ef4fa6bed6a953b58148b902d363fbf6bebd8071b06c2ceeda4c965c2b3704952fbfa34c6ff7f206f2beef4e82315c0b07d2b8a3a58ad846645fd252edb54291934a9e97867e94dde893248217c9f57a19c67619fc8d6d7be516584fb9a1af852b153554a7021b97f121da27161dc9ef9d161ae1d9e769ed359a346e1efb7ec8dd6ede607e512880355656a25c2bddd78786ecbb9c1b5e20f691c75e96e6ca890d66f25fe068e23456
Crypt::TEA a526f8333f4c40502310a39ddda4a9b3e88a6fa8e2f9c3f6f867e8cd0491b549e27a9d93639b39a8e8d6c082a4bbd2d48c759f17ab511131a8f9fa3adb4570678b94d7e1719d8a08a1dfadb2ab2759b2870a0aab4b010d766c481a11d4048e533e1e2eadd5bf9d15d96b5f1dabacea271cbe16821ed691fa960f207f15002bb841a1226518198d8df63a815b98a93346245e816582092a9f84278e18e20b050721bd54366306c1194ed8747c9a591d9fbda77d30e70f7a910f17d7f462962b645167a8e5f31b06b9d3b31875b419050b008b4caa7cef0f92c52f108ad2
Crypt::Twofish 836daf5a51cc2cb5d7161be11e5cd1d9b4cee3260efa8e98a1b0425ac466d8449db168a2741db9e372e032741f05206e7ac56d1391683480b934b969905478f4b06f29659c8c724f0f76d2493db26a3b0d324e7cf09048e6ae3e85ffa8b0f36b831c56a53f4111018abe8a969e0824e2ac45477a9cd9be74b61f9f2103f5369e56379d5610daabf3d678e7387fa4038c0d7b59faaee1249d58d967c5ecec6fd9e33511a99f0f8ee8b7e9d7a33fbf840b24f9d7193f6b618f096c620428fbf6d82915f788554a2d5de344d2d1319c8ebcf2704cb341607d330a384bf015
Crypt::Twofish2 2e53f97cc822af85f0776f0bfa70962be4e4ff88406797205410b541984e8eaf30c299fa6a1f962c72e91c33ae5ae19938e6ad1a2b9eed670df2a6242105b8a67e30f5dd7b3d4ee60f30e390940254da7b17737c198548308d35fafc4c9a483851390c54acabd48f82e52f3ff6cc05d76195fde8381a4e4dbe5ee1cb8aa74c447fa047b052fba47eb8070d52679911194f84b790d6aabd40c2396c6feca727987e9bbfcbdf57df69a536e34751bf8fc949ab9e4364459807c12c703b71b8ffd1afdf709972c2b9e46f7eff990f3af29d5e2f9d78ff2f523e94743b9e98
Digest::MD2 1b383e66dd8fa5ea917781542e61b0098132c538292841278255dce9ed1347bb036316ae353a1a65ef537bb37b9fde7472508df9e1454635495e56260d05267a2028e9bd9a03a7a868ef930afd2ba4d80948ccae129ebb9235897c5eca74591c209ef8d7768bc8b52b1fd15e8fd3da09347fb837cb01ce7858e03b5dd8dff084dd43804d92ef7ed2ba9fcd944fcd30ed20a940749f85882d9d08ffab37101b4f1d2224f063e17f0ad36028a47293564c8b55bc99b6a6bce00b1d1a3c90785cb1c68457fd35d045ab3005ac38b799fad591951dd3f58d810dceabe8e37d
Digest::MD5 c83bbc3953506c59b0649aa6b9b2c046852d2c86e70705fb8a07d205493b09dac69280043a3d93bab0a6722cd43567875c4460c7973e7ed28ef3ef1ad4fd4644d90f44f07cee25680ba14b4c054bc9258f32b1dbd99b5aa40bd0ea3f9240f8b5980b1f9ddb76c97cf35a87fc96f0be5d67ee9a52db3685e0de7c51998e3c6b54959a2c4e953fb1ec8e0aa27b006d0fede9792cb0f1869b253faac8eb6b227647f8542dc26fde3da8e9a48e4ceb7e458a648acf68ee06c888cd99730679a383e11d3e263673a03a1233c52680b583da2f998aa3ce58a6a07b000b46b84b
Digest::SHA1 f775f7ad8c4853e5725247e420adfa6be4bb1d9e644d85b8e0352d774aca27dc083d09426be94942c53c130bda2b6b18b88331448e4fbd245bd65dd08a56f282deeb8a104af5674eaec3975fdf440a24321f6950e1dd2744ff5e3abf487b9362a375a72bbb6841ba962dfa8170e579de587a50fd65983f53f9b3678c19f93f2f1e3b879d96ffdae4a7a1c6adab69a4ea0d53eddd16264dec3be8e66672327006794e0b27e1cb0ed78c3efa72373b9a70db6b16de3687041c2f4298fc14f6bcc7bf6b5cc16f0437838a91b963f46f9171ca5a53cd052fb7031c31b4d687
