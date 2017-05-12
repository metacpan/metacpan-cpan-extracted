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
use Crypt::Ctr;
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
    $t[$i] = new Crypt::Ctr($key, $algos[$i]);
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
Crypt::Blowfish 2172c2a14c8657bd1e40396781a107d977efeaacde94c4c7982427ea94ba200d0409f0740f99861970b97e3dbe5a054bb2ad95b0281ad4a10147c1472af0fa2aedcdaa1754a9583dc67f0530f0ffe699c6b9669c2572f9225851b1f2cc8779a950b5894fd128d3a335350e17b44d2a2f4f0da1b6036dbb7ffae3cd945961f2216f8aa5801988968d66cce5116eeac90dc47b38aa99ce4795be9df3df490c2c566cfd691c379a3cf9c3b849d05789394317c8db4d1527813460c4ef24a420babd207952c1c6527253f3bd3f2c12244c19a88134763e04533477bbabea0f
Crypt::DES 506b62d77816e16c7a5a043a37764fbe03422fb8b3a48bd12001b89bcefeb7542710cda652a30d9bbe7fb088427577803815f79b7e50d361383796c0acc51f18f0fd3cd75e5730b57d3bf883a380f1df793dfaad05cb42a57ccfdadbecd43002aeb1a65354056dfa775053d5559b3b764c422388a8c0473e18375ae5d4a3e40ef2286a822138ff3f4b41063fbfdf1b4ce0cd523070a736d73c9c55e986fa37b4f2513c32461802950716c7331f285c9dbda82c9e19cc983e8015b9b4abc446bf4ee15fef47964e6a9987f8176013676a7fd68a1e8a39777828bdc02062
Crypt::DES_EDE3 61cf476098dfa557cf5977142fc212d556394bff24852b0c22640cb30d502bb6849c396d9c915ca4015b8b04aaa3065d8633f6f86e1fa5bee309c62082a3b82c7a2eede910e594b9b2e4f025a504d1e73a1d23b5efa2a740d041b94ddad34431e4f6fa4c4d2c9440251f1080681c85486638f4ec8f233ba29fead165a3aee2d68a633ddbd526920b83ce15afc2f8e2a5dabc7a29e30c7305e7adc8a2c175f783ef3403739732b0916e9d17da6903dbbd5e3e6c5a1af8b7fb4d9e813d4cb37f7d1963bf8169d90bfcdf93028d4606554d57d3f36e522e6e1b06f1de97f7
Crypt::GOST 99783e7267256edf0aebd5f278245c62d0e5a96fc771739aa960650d8fb93ce072431831a5eb25f7d77bca9a8a12f856a419b43eabdaccc9ad39886c0bf20fdbe92b4936f3040f5d606ccc7eeed1ac6a5e4e66a4b09cbdd27fdb32e3f5acf5bed7ecddea0a05782ec875e3bc8669e3d67fd98d42cd7364458caf687570283c7fd46600721cae02ae73a347b84cccf8f3acc6e6b0adaeb272f37ae4d72f9d188c54145e4d4f3f77e135eedac3039070063ec9098a0e70dbed5aed78c45b73a98bf3993eaf3206da9e691219921db7dad1d6e97a60d2cd9c0f9280e0b13e
Crypt::NULL 202020556e732069737420696e20616c74656e206de672656e207c207c2077756e646572732076696c206765736569740a202020766f6e2068656c64656e206c6f626562e672656e207c207c20766f6e206772f47a657220617265626569742c0a202020766f6e206672657564656e2c2068f4636867657aee74656e2c207c207c20766f6e207765696e656e20756e6420766f6e206b6c6167656e2c0a202020766f6e206bfc656e6572207265636b656e20737472ee74656e207c207c206d75676574206972206e752077756e646572206872656e20736167656e2e0a
Crypt::RC6 6b88c512974e284f9e2194b17a2755ea314c46d5cb61f22f19394e3d30785442c110e3d39ac513d4860b44fb8532a3fb6e1a6f4ec65bd49c21e4761debebbb07d5e62c54ee08113a9cd259b6a1f0a6a06514ff849ffb5278ff2a46bac8985d872dac545db27e5b9cdeea2174679cfbb1d1e6214ffc60127c0d15390bef21355d41f96dde618f453ea5faf89c4d8597082ec46d1bca203a2ba7a8c9712f5e2e8f608a259da4c227b2c3995bb3a0ce487eb889a814365f0bcfadb04ff3d89ff80c771fbb290641ff9afe4d7de4648326801340ad1950946113a0957137ec
Crypt::Rijndael a0885b0575c33bd11f28bfbca7fa08bcf64f2fbbc7ed8a8ac557e623f3cba05be89edf05832f29db9ab50d93401df860b8212b73d714ec8c719408ecda82bae02e214601af83fe001b7f4acdbaf263fdbc055546cce4d07a5191b81a88e8d4abd295c74463ae1811e6d5e5b1d1885bda13c8b65c66eef06a5e64b3d188a68881f7dce756628b3d1b9b87d1ee0e83c22ed2f5558f5e10b5901610f78231158e114d6a0f2a962b81467c8ea156dc5b1c5f8d01650e266d2af3cac42d8a57054182cdd69b9b20a6db2e3754e595a66c365502d0325c288bf9a890046deddb
Crypt::Serpent 6abec9aee40585007f9fc42cd2ad2559c2eeec387033a7bffca9f2fa8226e51f3909db900eadedb978e1fbc3f1d7d67ef49ff5c63c5dd456e80213b26d227b1a82fbcca05e0a7c223c72890aa71943323850e38ce565f591996eb0024b1e92532c1c3021bb8d7ace5e63cd13c8b6a3e5f7e54d26bc20992f0eec09a074c6cbe5be4b5ed03e6314b8796dfb806b10d75323349f9cdd1ff81eed47d3b806fff4c9dba2601d7ca2e8b670016fa9520451bf649c1f32ec658903427364ef0cdcfba12f7043c334d2923ba9659ca3cfd4771b8873b7d6913cc0a9a81f8e2a7f
Crypt::TEA a5444a52bdb83a3972d68d6367d1a80e31cffb800f7359fcda0f49f0f2c7c4061b348319be137f7f3361fd9f513426de393aabb3cdbd0ecb89090081d8fcf228448fbd53f61badfabaa46827e0b30d6231397d3516a1928b9899f06073010e2410ed412a6786c045db606587343d07d72a8d41c252994ada7897796cf43f661da63bd3a65c8e1755f2b965ff686e573da95281946f0f0e2f15970e99dc8aab86d776edb8a923b729d57c6258ea1b029616be01f59de72a9bcdda27c52df4b9313776bf7940533806aa6e63b7b5a945df3741fa41fe41033168489bec41
Crypt::Twofish 83953f07dcb19ac7b288795fcae39d6f305a66302b551ace57a54f7dacf0b0444305477f4d5548e2ba703a62a6b78a277d3b4401dc2562254bce4db14276a49b5c3eb37ce8c38d7577f9b4e1ff7292c6ff4866499b4cad6adc154db038f2dc291eff93a44bfd48a584c23650a911334df53f79d47ae229c62319a5d32ef4e7bc57ecd3964fe1b40e19e84bbb705c2b81fd78e1aa17ee29b0396dad5a9b01cd67b03370945008fa4a2697853d5a01b4d825dc75be6325055c6b0ec6d0441b3d42ee96bf893d35f410bfd4d9b94e987c1d26381be3a5eaa3049cef0be6b4
Crypt::Twofish2 2e0dd4bf6fcc7587be318e81733a84ed0c157925849a8de867537d1f110e54c1dbacfc3fcd22dbe5e8de4cef46ae721c4b4faa051020b33b6aee32c780f1fbb003b26e90f6a9dde129767388ff30a8afad14a33757f24c3f6474c6ad4421fc9d8e10be983150a54e7d0e1507c0b8f24469496d70746b32f1deb26bd1cba8dbee7410b369bef2ef1b96641198d8a71fb4235b8a3ade17563cbb9bb89722bffdf7d1f4217afbe429a36afa533c299be3d7b35d3beca800c96312123f2dc47b7657cc0f72130a9e926ee9c38486317aa0215238bae00a4432030d31cb2537
Digest::MD2 1bbab6041be1acdc46bf849ee8f4e609363fddb5721fa4c94866c659941097030ef7a419eac32a3762412a99428a775782b748baf620a0a96f82c2716c274641e1d0ac587ae21d72cbf74e41fd6f65843a9175e023c00c4a2d75d191678c53d5a0e23e582c06a795084b0a7e16b570620082f289b5f6cc6bf35372dfd60d229ec7d5f74278a4b74d4cfc9e2027951ec1628cc3d732001ca3428c9e5e733033970745c187655b1d766413e2c1036ff279d36fe975d1346c07947d25b334daf2705792e9d1bf57d2987de906b77aeee583d18f407d50e78e925c85bbf099
Digest::MD5 c89e5c048a162c67c991017cde164df2c773ee947d5a0e83190604ef0c8b27606e7d92b6fe99c4ca03eba80ed8ea43238739b27fab48539792fbc06fa392651adc5683a7fe35ee17fd22b3e3f563dc0fd85a44d00de18dc9df5749995654ab2ceda4e093d0605b1169e48a24cf55e63c3394cf6430a25af8f7f6df75c9add595563e632bac9cab02f5d0359926a6d8a3ce3db818c290f162310621f22c722213f00845e183d1901876349fe13b101b16ef42db0023aa58dab4175b6d60861e539d2daed30004d5c9d5c85e0ad1180dd2c628e15d3af98bfeab11f92ae6
Digest::SHA1 f78485f05f6489aa647f59a0c236fa6e9e8f5af3922acfdaee4a92659740b5c7f73a4489f7bd5098b037c8758468bc175a6db32c0f5a46ae35a58aceebc66d896c4c3e7ef1044e0c8b190d2318f01d1f618bbc9f768f705ba80202bcc96ba0f810f10de257e218d835715d20e44af727e4ab8bb5e74031e49b3a3d707384847ce08287ab06a61afc55fcaff3208b0ed7fec18c6010daf21b660abb124a77955c72c1bd8f1e3ff040c04fbacbffc6305f292f9b4530bd8366f11add28e82ed1423ab38de20c83f72ea187c047aba60605a2134d9fe773fb5d169e32ddd7
