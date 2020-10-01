package t::Crypt::Perl::PK;

use strict;
use warnings;

BEGIN {
    if ( $^V ge v5.10.1 ) {
        require autodie;
    }
}

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More;
use Test::FailWarnings;
use Test::Deep;
use Test::Exception;

use lib "$FindBin::Bin/lib";

use parent qw(
    TestClass
);

use Digest::SHA ();
use Crypt::Perl::ECDSA::EC::DB ();
use Crypt::Perl::BigInt ();

use Crypt::Perl::ECDSA::Deterministic ();

__PACKAGE__->new()->runtests() if !caller;

#----------------------------------------------------------------------

sub print_diag : Tests(startup) {
    diag join q< >, map { Crypt::Perl::BigInt->config($_) } qw(lib lib_version);
}

use constant _TEST_TESTS => (
    (
        map {
            my ($hashfn, $expect, $blksize) = @$_;

            {
                label => "P-192, $hashfn",
                order => 'FFFFFFFFFFFFFFFFFFFFFFFF99DEF836146BC9B1B4D22831',
                key => '6FAB034934E4C0FC9AE67F5B5659A9D7D1FEFD187EE09FD4',
                hash => $hashfn,
                expect => $expect,
            },
        }
        [ sha1 => 'd9cf9c3d3297d3260773a1da7418db5537ab8dd93de7fa25' ],
        [ sha224 => 'f5dc805f76ef851800700cce82e7b98d8911b7d510059fbe' ],
        [ sha256 => '5c4ce89cf56d9e7c77c8585339b006b97b5f0680b4306c6c' ],
        [ sha384 => '5afefb5d3393261b828db6c91fbc68c230727b030c975693' ],
        [ sha512 => '758753a5254759c7cfbad2e2d9b0792eee44136c9480527' ],
    ),

    (
        map {
            my ($hashfn, $expect, $blksize) = @$_;

            {
                label => "P-224, $hashfn",
                order => 'FFFFFFFFFFFFFFFFFFFFFFFFFFFF16A2E0B8F03E13DD29455C5C2A3D',
                key => 'F220266E1105BFE3083E03EC7A3A654651F45E37167E88600BF257C1',
                hash => $hashfn,
                expect => $expect,
            },
        }
        [ sha1 => '2519178f82c3f0e4f87ed5883a4e114e5b7a6e374043d8efd329c253' ],
        [ sha224 => 'df8b38d40dca3e077d0ac520bf56b6d565134d9b5f2eae0d34900524' ],
        [ sha256 => 'ff86f57924da248d6e44e8154eb69f0ae2aebaee9931d0b5a969f904' ],
        [ sha384 => '7046742b839478c1b5bd31db2e862ad868e1a45c863585b5f22bdc2d' ],
        [ sha512 => 'e39c2aa4ea6be2306c72126d40ed77bf9739bb4d6ef2bbb1dcb6169d' ],
    ),

    (
        map {
            my ($hashfn, $expect, $blksize) = @$_;

            {
                label => "P-256, $hashfn",
                order => 'FFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551',
                key => 'C9AFA9D845BA75166B5C215767B1D6934E50C3DB36E89B127B8A622B120F6721',
                hash => $hashfn,
                expect => $expect,
            },
        }
        [ sha1 => '8c9520267c55d6b980df741e56b4adee114d84fbfa2e62137954164028632a2e' ],
        [ sha224 => '669f4426f2688b8be0db3a6bd1989bdaefff84b649eeb84f3dd26080f667faa7' ],
        [ sha256 => 'd16b6ae827f17175e040871a1c7ec3500192c4c92677336ec2537acaee0008e0' ],
        [ sha384 => '16aeffa357260b04b1dd199693960740066c1a8f3e8edd79070aa914d361b3b8' ],
        [ sha512 => '6915d11632aca3c40d5d51c08daf9c555933819548784480e93499000d9f0b7f' ],
    ),

    (
        map {
            my ($hashfn, $expect, $blksize) = @$_;

            {
                label => "P-384, $hashfn",
                order => 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7634D81F4372DDF581A0DB248B0A77AECEC196ACCC52973',
                key => '6B9D3DAD2E1B8C1C05B19875B6659F4DE23C3B667BF297BA9AA47740787137D896D5724E4C70A825F872C9EA60D2EDF5',
                hash => $hashfn,
                expect => $expect,
            },
        }
        [ sha1 => '66cc2c8f4d303fc962e5ff6a27bd79f84ec812ddae58cf5243b64a4ad8094d47ec3727f3a3c186c15054492e30698497' ],
        [ sha224 => '18fa39db95aa5f561f30fa3591dc59c0fa3653a80daffa0b48d1a4c6dfcbff6e3d33be4dc5eb8886a8ecd093f2935726' ],
        [ sha256 => 'cfac37587532347dc3389fdc98286bba8c73807285b184c83e62e26c401c0faa48dd070ba79921a3457abff2d630ad7' ],
        [ sha384 => '15ee46a5bf88773ed9123a5ab0807962d193719503c527b031b4c2d225092ada71f4a459bc0da98adb95837db8312ea' ],
        [ sha512 => '3780c4f67cb15518b6acae34c9f83568d2e12e47deab6c50a4e4ee5319d1e8ce0e2cc8a136036dc4b9c00e6888f66b6c' ],
    ),

    (
        map {
            my ($hashfn, $expect, $blksize) = @$_;

            {
                label => "P-521, $hashfn",
                order => '1FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFA51868783BF2F966B7FCC0148F709A5D03BB5C9B8899C47AEBB6FB71E91386409',
                key => '0FAD06DAA62BA3B25D2FB40133DA757205DE67F5BB0018FEE8C86E1B68C7E75CAA896EB32F1F47C70855836A6D16FCC1466F6D8FBEC67DB89EC0C08B0E996B83538',
                hash => $hashfn,
                expect => $expect,
            },
        }
        [ sha1 => 'bb9f2bf4fe1038ccf4dabd7139a56f6fd8bb1386561bd3c6a4fc818b20df5ddba80795a947107a1ab9d12daa615b1ade4f7a9dc05e8e6311150f47f5c57ce8b222' ],
        [ sha224 => '40d09fcf3c8a5f62cf4fb223cbbb2b9937f6b0577c27020a99602c25a01136987e452988781484edbbcf1c47e554e7fc901bc3085e5206d9f619cff07e73d6f706' ],
        [ sha256 => '1de74955efaabc4c4f17f8e84d881d1310b5392d7700275f82f145c61e843841af09035bf7a6210f5a431a6a9e81c9323354a9e69135d44ebd2fcaa7731b909258' ],
        [ sha384 => '1f1fc4a349a7da9a9e116bfdd055dc08e78252ff8e23ac276ac88b1770ae0b5dceb1ed14a4916b769a523ce1e90ba22846af11df8b300c38818f713dadd85de0c88' ],
        [ sha512 => '16200813020ec986863bedfc1b121f605c1215645018aea1a7b215a564de9eb1b38a67aa1128b80ce391c4fb71187654aaa3431027bfc7f395766ca988c964dc56d' ],
    ),

    (
        map {
            my ($hashfn, $expect, $blksize) = @$_;

            {
                label => "K-163, $hashfn",
                order => '4000000000000000000020108A2E0CC0D99F8A5EF',
                key => '09A4D6792295A7F730FC3F2B49CBC0F62E862272F',
                hash => $hashfn,
                expect => $expect,
            },
        }
        [ sha1 => '14cab9192f39c8a0ea8e81b4b87574228c99cd681' ],
        [ sha224 => '91dd986f38eb936be053dd6ace3419d2642ade8d' ],
        [ sha256 => '193649ce51f0cff0784cfc47628f4fa854a93f7a2' ],
        [ sha384 => '37c73c6f8b404ec83da17a6ebca724b3ff1f7eeba' ],
        [ sha512 => '331ad98d3186f73967b1e0b120c80b1e22efc2988' ],
    ),

    (
        map {
            my ($hashfn, $expect, $blksize) = @$_;

            {
                label => "K-233, $hashfn",
                order => '8000000000000000000000000000069D5BB915BCD46EFB1AD5F173ABDF',
                key => '103B2142BDC2A3C3B55080D09DF1808F79336DA2399F5CA7171D1BE9B0',
                hash => $hashfn,
                expect => $expect,
            },
        }
        [ sha1 => '1d8bbf5cb6effa270a1cdc22c81e269f0cc16e27151e0a460ba9b51aff' ],
        [ sha224 => '67634d0aba2c9bf7ae54846f26dcd166e7100654bce6fdc96667631aa2' ],
        [ sha256 => '2ce5aedc155acc0ddc5e679ebacfd21308362e5efc05c5e99b2557a8d7' ],
        [ sha384 => '1b4bd3903e74fd0b31e23f956c70062014dfefee21832032ea5352a055' ],
        [ sha512 => '1775ed919ca491b5b014c5d5e86af53578b5a7976378f192af665cb705' ],
    ),

    (
        map {
            my ($hashfn, $expect, $blksize) = @$_;

            {
                label => "K-283, $hashfn",
                order => '1FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE9AE2ED07577265DFF7F94451E061E163C61',
                key => '06A0777356E87B89BA1ED3A3D845357BE332173C8F7A65BDC7DB4FAB3C4CC79ACC8194E',
                hash => $hashfn,
                expect => $expect,
            },
        }
        [ sha1 => '168b5f8c0881d4026c08ac5894a2239d219fa9f4da0600adaa56d5a1781af81f08a726e' ],
        [ sha224 => '45e13ea645ce01d9b25ea38c8a8a170e04c83bb7f231ee3152209fe10ec8b2e565536c' ],
        [ sha256 => 'b585a7a68f51089691d6ede2b43fc4451f66c10e65f134b963d4cbd4eb844b0e1469a6' ],
        [ sha384 => '1e88738e14482a09ee16a73d490a7fe8739df500039538d5c4b6c8d6d7f208d6ca56760' ],
        [ sha512 => 'e5f24a223bd459653f682763c3bb322d4ee75dd89c63d4dc61518d543e76585076bba' ],
    ),

    (
        map {
            my ($hashfn, $expect, $blksize) = @$_;

            {
                label => "K-409, $hashfn",
                order => '7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE5F83B2D4EA20400EC4557D5ED3E3E7CA5B4B5C83B8E01E5FCF',
                key => '29C16768F01D1B8A89FDA85E2EFD73A09558B92A178A2931F359E4D70AD853E569CDAF16DAA569758FB4E73089E4525D8BBFCF',
                hash => $hashfn,
                expect => $expect,
            },
        }
        [ sha1 => '545453d8dc05d220f9a12ef322d0b855e664c72835fabe8a41211453eb8a7cff950d80773839d0043a46852dda5a536e02291f' ],
        [ sha224 => '3c5352929d4ebe3cce87a2dce380f0d2b33c901e61abc530daf3506544ab0930ab9bfd553e51fcda44f06cd2f49e17e07db519' ],
        [ sha256 => '251e32dee10ed5ea4ad7370df3eff091e467d5531ca59de3aa791763715e1169ab5e18c2a11cd473b0044fb45308e8542f2eb0' ],
        [ sha384 => '11c540ea46c5038fe28bb66e2e9e9a04c9fe9567adf33d56745953d44c1dc8b5b92922f53a174e431c0ed8267d919329f19014' ],
        [ sha512 => '59527ce953bc09df5e85155cae7bb1d7f342265f41635545b06044f844ecb4fa6476e7d47420adc8041e75460ec0a4ec760e95' ],
    ),

    (
        map {
            my ($hashfn, $expect, $blksize) = @$_;

            {
                label => "K-571, $hashfn",
                order => '20000000000000000000000000000000000000000000000000000000000000000000000131850E1F19A63E4B391A8DB917F4138B630D84BE5D639381E91DEB45CFE778F637C1001',
                key => '0C16F58550D824ED7B95569D4445375D3A490BC7E0194C41A39DEB732C29396CDF1D66DE02DD1460A816606F3BEC0F32202C7BD18A32D87506466AA92032F1314ED7B19762B0D22',
                hash => $hashfn,
                expect => $expect,
            },
        }
        [ sha1 => '1d056563469e933e4be064585d84602d430983bfbfd6885a94ba484df9a7ab031ad6ac090a433d8eedc0a7643ea2a9bc3b6299e8aba933b4c1f2652bb49daee833155c8f1319908' ],
        [ sha224 => '1da875065b9d94dbe75c61848d69578bcc267935792624f9887b53c9af9e43cabfc42e4c3f9a456ba89e717d24f1412f33cfd297a7a4d403b18b5438654c74d592d5022125e0c6b' ],
        [ sha256 => '4ddd0707e81bb56ea2d1d45d7fafdbdd56912cae224086802fea1018db306c4fb8d93338dbf6841ce6c6ab1506e9a848d2c0463e0889268843dee4acb552cffcb858784ed116b2' ],
        [ sha384 => '141b53dc6e569d8c0c0718a58a5714204502fda146e7e2133e56d19e905b79413457437095de13cf68b5cf5c54a1f2e198a55d974fc3e507afc0acf95ed391c93cc79e3b3fe37c' ],
        [ sha512 => '14842f97f263587a164b215dd0f912c588a88dc4ab6af4c530adc1226f16e086d62c14435e6bfab56f019886c88922d2321914ee41a8f746aaa2b964822e4ac6f40ee2492b66824' ],
    ),

    (
        map {
            my ($hashfn, $expect, $blksize) = @$_;

            {
                label => "B-163, $hashfn",
                order => '40000000000000000000292FE77E70C12A4234C33',
                key => '35318FC447D48D7E6BC93B48617DDDEDF26AA658F',
                hash => $hashfn,
                expect => $expect,
            },
        }
        [ sha1 => '10024f5b324cbc8954ba6adb320cd3ab9296983b4' ],
        [ sha224 => '34f46de59606d56c75406bfb459537a7cc280aa62' ],
        [ sha256 => '38145e3ffca94e4ddacc20ad6e0997bd0e3b669d2' ],
        [ sha384 => '375813210ece9c4d7ab42ddc3c55f89189cf6dffd' ],
        [ sha512 => '25ad8b393bc1e9363600fda1a2ab6df40079179a3' ],
    ),

    (
        map {
            my ($hashfn, $expect, $blksize) = @$_;

            {
                label => "B-233, $hashfn",
                order => '1000000000000000000000000000013E974E72F8A6922031D2603CFE0D7',
                key => '07ADC13DD5BF34D1DDEEB50B2CE23B5F5E6D18067306D60C5F6FF11E5D3',
                hash => $hashfn,
                expect => $expect,
            },
        }
        [ sha1 => '250c5c90a4e2a3f8849feba87f0d0ae630ab18cbabb84f4fffb36ceac0' ],
        [ sha224 => '7bdb6a7fd080d9ec2fc84bff9e3e15750789dc04290c84fed00e109bbd' ],
        [ sha256 => '376886e89013f7ff4b5214d56a30d49c99f53f211a3afe01aa2bde12d' ],
        [ sha384 => '3726870de75613c5e529e453f4d92631c03d08a7f63813e497d4cb3877' ],
        [ sha512 => '9ce5810f1ac68810b0dffbb6beef2e0053bb937969ae7886f9d064a8c4' ],
    ),

    (
        map {
            my ($hashfn, $expect, $blksize) = @$_;

            {
                label => "B-283, $hashfn",
                order => '3FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEF90399660FC938A90165B042A7CEFADB307',
                key => '14510D4BC44F2D26F4553942C98073C1BD35545CEABB5CC138853C5158D2729EA408836',
                hash => $hashfn,
                expect => $expect,
            },
        }
        [ sha1 => '185c57a743d5ba06193ce2aa47b07ef3d6067e5ae1a6469bcd3fc510128ba564409d82' ],
        [ sha224 => '2e5c1f00677a0e015ec3f799fa9e9a004309dbd784640eaaf5e1ce64d3045b9fe9c1fa1' ],
        [ sha256 => '18a7d44f2b4341fefe68f6bd8894960f97e08124aab92c1ffbbe90450fcc9356c9aaa5' ],
        [ sha384 => '3c75397ba4cf1b931877076af29f2e2f4231b117ab4b8e039f7f9704de1bd3522f150b6' ],
        [ sha512 => '14e66b18441fa54c21e3492d0611d2b48e19de3108d915fd5ca08e786327a2675f11074' ],
    ),

    (
        map {
            my ($hashfn, $expect, $blksize) = @$_;

            {
                label => "B-409, $hashfn",
                order => '10000000000000000000000000000000000000000000000000001E2AAD6A612F33307BE5FA47C3C9E052F838164CD37D9A21173',
                key => '0494994CC325B08E7B4CE038BD9436F90B5E59A2C13C3140CD3AE07C04A01FC489F572CE0569A6DB7B8060393DE76330C624177',
                hash => $hashfn,
                expect => $expect,
            },
        }
        [ sha1 => '17e167eab1850a3b38ee66bfe2270f2f6bfdac5e2d227d47b20e75f0719161e6c74e9f23088f0c58b1e63bc6f185ad2ef4eae6' ],
        [ sha224 => '1adeb94c19951b460a146b8275d81638c07735b38a525d76023aaf26aa8a058590e1d5b1e78ab3c91608bda67cffbe6fc8a6cc' ],
        [ sha256 => '6eba3d58d0e0dfc406d67fc72ef0c943624cf40019d1e48c3b54ccab0594afd5dee30aebaa22e693dbcfecad1a85d774313dad' ],
        [ sha384 => 'a45b787db44c06deab846511eedbf7bfcfd3bd2c11d965c92fc195f67328f36a2dc83c0352885dab96b55b02fcf49dccb0e2da' ],
        [ sha512 => 'b90f8a0e757e81d4ea6891766729c96a6d01f9aedc0d334932d1f81cc4e1973a4f01c33555ff08530a5098cadb6edae268abb5' ],
    ),

    (
        map {
            my ($hashfn, $expect, $blksize) = @$_;

            {
                label => "B-571, $hashfn",
                order => '3FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE661CE18FF55987308059B186823851EC7DD9CA1161DE93D5174D66E8382E9BB2FE84E47',
                key => '028A04857F24C1C082DF0D909C0E72F453F2E2340CCB071F0E389BCA2575DA19124198C57174929AD26E348CF63F78D28021EF5A9BF2D5CBEAF6B7CCB6C4DA824DD5C82CFB24E11',
                hash => $hashfn,
                expect => $expect,
            },
        }
        [ sha1 => '19b506fd472675a7140e429aa5510dcddc21004206eec1b39b28a688a8fd324138f12503a4efb64f934840dfba2b4797cfc18b8bd0b31bbff3ca66a4339e4ef9d771b15279d1dc' ],
        [ sha224 => '333c711f8c62f205f926593220233b06228285261d34026232f6f729620c6de12220f282f4206d223226705608688b20b8ba86d8dfe54f07a37ec48f253283ac33c3f5102c8cc3e' ],
        [ sha256 => '328e02cf07c7b5b6d3749d8302f1ae5bfaa8f239398459af4a2c859c7727a8123a7fe9be8b228413fc8dc0e9de16af3f8f43005107f9989a5d97a5c4455da895e81336710a3fb2c' ],
        [ sha384 => '2a77e29ead9e811a9fda0284c14cdfa1d9f8fa712da59d530a06cde54187e250ad1d4fb5788161938b8de049616399c5a56b0737c9564c9d4d845a4c6a7cdfcbff0f01a82be672e' ],
        [ sha512 => '21ce6ee4a2c72c9f93bdb3b552f4a633b8c20c200f894f008643240184be57bb282a1645e47fbbe131e899b4c61244efc2486d88cdbd1dd4a65ebdd837019d02628d0dcd6ed8fb5' ],
    ),
);

#----------------------------------------------------------------------

use constant _SAMPLE_TESTS => (
    {
        label => 'detailed example from RFC',
        order => '4000000000000000000020108A2E0CC0D99F8A5EF',
        key => '09A4D6792295A7F730FC3F2B49CBC0F62E862272F',
        hash => 'sha256',
        expect => '23af4074c90a02b3fe61d286d5c87f425e6bdd81b',
    },

    {
        label => 'python-ecdsa, SECP256k1 (1)',
        order => 'fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141',
        key => '9d0219792467d7d37b4d43298a7d0c05',
        hash => 'sha256',
        expect => '8fa1f95d514760e498f28957b824ee6ec39ed64826ff4fecc2b5739ec45b91cd',
    },

    {
        label => 'python-ecdsa, SECP256k1 (2)',
        order => 'fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141',
        key => 'cca9fbcc1b41e5a95d369eaa6ddcff73b61a4efaa279cfc6567e8daa39cbaf50',
        hash => 'sha256',
        expect => '2df40ca70e639d89528a6b670d9d48d9165fdc0febc0974056bdce192b8e16a3',
    },

    {
        label => 'python-ecdsa, SECP256k1 (3)',
        order => 'fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141',
        key => '1',
        hash => 'sha256',
        expect => '8f8a276c19f4149656b280621e358cce24f5f52542772691ee69063b74f15d15',
        message => 'Satoshi Nakamoto',
    },

    {
        label => 'python-ecdsa, SECP256k1 (4)',
        order => 'fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141',
        key => '1',
        hash => 'sha256',
        expect => '38aa22d72376b4dbc472e06c3ba403ee0a394da63fc58d88686c611aba98d6b3',
        message => 'All those moments will be lost in time, like tears in rain. Time to die...',
    },

    {
        label => 'python-ecdsa, SECP256k1 (5)',
        order => 'fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141',
        key => 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364140',
        hash => 'sha256',
        expect => '33a19b60e25fb6f4435af53a3d42d493644827367e6453928554f43e49aa6f90',
        message => 'Satoshi Nakamoto',
    },

    (
        map {
            my ($hashfn, $expect, $blksize) = @$_;

            {
                label => "P-192, $hashfn",
                order => 'FFFFFFFFFFFFFFFFFFFFFFFF99DEF836146BC9B1B4D22831',
                key => '6FAB034934E4C0FC9AE67F5B5659A9D7D1FEFD187EE09FD4',
                hash => $hashfn,
                expect => $expect,
            },
        }
        [ sha1 => '37d7ca00d2c7b0e5e412ac03bd44ba837fdd5b28cd3b0021' ],
        [ sha224 => '4381526b3fc1e7128f202e194505592f01d5ff4c5af015d8' ],
        [ sha256 => '32b1b6d7d42a05cb449065727a84804fb1a3e34d8f261496' ],
        [ sha384 => '4730005c4fcb01834c063a7b6760096dbe284b8252ef4311' ],
        [ sha512 => 'a2ac7ab055e4f20692d49209544c203a7d1f2c0bfbc75db1' ],
    ),

    (
        map {
            my ($hashfn, $expect, $blksize) = @$_;

            {
                label => "P-224, $hashfn",
                order => 'FFFFFFFFFFFFFFFFFFFFFFFFFFFF16A2E0B8F03E13DD29455C5C2A3D',
                key => 'F220266E1105BFE3083E03EC7A3A654651F45E37167E88600BF257C1',
                hash => $hashfn,
                expect => $expect,
            },
        }
        [ sha1 => '7eefadd91110d8de6c2c470831387c50d3357f7f4d477054b8b426bc' ],
        [ sha224 => 'c1d1f2f10881088301880506805feb4825fe09acb6816c36991aa06d' ],
        [ sha256 => 'ad3029e0278f80643de33917ce6908c70a8ff50a411f06e41dedfcdc' ],
        [ sha384 => '52b40f5a9d3d13040f494e83d3906c6079f29981035c7bd51e5cac40' ],
        [ sha512 => '9db103ffededf9cfdba05184f925400c1653b8501bab89cea0fbec14' ],
    ),

    (
        map {
            my ($hashfn, $expect, $blksize) = @$_;

            {
                label => "P-256, $hashfn",
                order => 'FFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551',
                key => 'C9AFA9D845BA75166B5C215767B1D6934E50C3DB36E89B127B8A622B120F6721',
                hash => $hashfn,
                expect => $expect,
            },
        }
        [ sha1 => '882905f1227fd620fbf2abf21244f0ba83d0dc3a9103dbbee43a1fb858109db4' ],
        [ sha224 => '103f90ee9dc52e5e7fb5132b7033c63066d194321491862059967c715985d473' ],
        [ sha256 => 'a6e3c57dd01abe90086538398355dd4c3b17aa873382b0f24d6129493d8aad60' ],
        [ sha384 => '9f634b188cefd98e7ec88b1aa9852d734d0bc272f7d2a47decc6ebeb375aad4' ],
        [ sha512 => '5fa81c63109badb88c1f367b47da606da28cad69aa22c4fe6ad7df73a7173aa5' ],
    ),

    (
        map {
            my ($hashfn, $expect, $blksize) = @$_;

            {
                label => "P-384, $hashfn",
                order => 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC7634D81F4372DDF581A0DB248B0A77AECEC196ACCC52973',
                key => '6B9D3DAD2E1B8C1C05B19875B6659F4DE23C3B667BF297BA9AA47740787137D896D5724E4C70A825F872C9EA60D2EDF5',
                hash => $hashfn,
                expect => $expect,
            },
        }
        [ sha1 => '4471ef7518bb2c7c20f62eae1c387ad0c5e8e470995db4acf694466e6ab096630f29e5938d25106c3c340045a2db01a7' ],
        [ sha224 => 'a4e4d2f0e729eb786b31fc20ad5d849e304450e0ae8e3e341134a5c1afa03cab8083ee4e3c45b06a5899ea56c51b5879' ],
        [ sha256 => '180ae9f9aec5438a44bc159a1fcb277c7be54fa20e7cf404b490650a8acc414e375572342863c899f9f2edf9747a9b60' ],
        [ sha384 => '94ed910d1a099dad3254e9242ae85abde4ba15168eaf0ca87a555fd56d10fbca2907e3e83ba95368623b8c4686915cf9' ],
        [ sha512 => '92fc3c7183a883e24216d1141f1a8976c5b0dd797dfa597e3d7b32198bd35331a4e966532593a52980d0e3aaa5e10ec3' ],
    ),

    (
        map {
            my ($hashfn, $expect, $blksize) = @$_;

            {
                label => "P-521, $hashfn",
                order => '1FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFA51868783BF2F966B7FCC0148F709A5D03BB5C9B8899C47AEBB6FB71E91386409',
                key => '0FAD06DAA62BA3B25D2FB40133DA757205DE67F5BB0018FEE8C86E1B68C7E75CAA896EB32F1F47C70855836A6D16FCC1466F6D8FBEC67DB89EC0C08B0E996B83538',
                hash => $hashfn,
                expect => $expect,
            },
        }
        [ sha1 => '89c071b419e1c2820962321787258469511958e80582e95d8378e0c2ccdb3cb42bede42f50e3fa3c71f5a76724281d31d9c89f0f91fc1be4918db1c03a5838d0f9' ],
        [ sha224 => '121415ec2cd7726330a61f7f3fa5de14be9436019c4db8cb4041f3b54cf31be0493ee3f427fb906393d895a19c9523f3a1d54bb8702bd4aa9c99dab2597b92113f3' ],
        [ sha256 => 'edf38afcaaecab4383358b34d67c9f2216c8382aaea44a3dad5fdc9c32575761793fef24eb0fc276dfc4f6e3ec476752f043cf01415387470bcbd8678ed2c7e1a0' ],
        [ sha384 => '1546a108bc23a15d6f21872f7ded661fa8431ddbd922d0dcdb77cc878c8553ffad064c95a920a750ac9137e527390d2d92f153e66196966ea554d9adfcb109c4211' ],
        [ sha512 => '1dae2ea071f8110dc26882d4d5eae0621a3256fc8847fb9022e2b7d28e6f10198b1574fdd03a9053c08a1854a168aa5a57470ec97dd5ce090124ef52a2f7ecbffd3' ],
    ),

    (
        map {
            my ($hashfn, $expect, $blksize) = @$_;

            {
                label => "K-163, $hashfn",
                order => '4000000000000000000020108A2E0CC0D99F8A5EF',
                key => '09A4D6792295A7F730FC3F2B49CBC0F62E862272F',
                hash => $hashfn,
                expect => $expect,
            },
        }
        [ sha1 => '9744429fa741d12de2be8316e35e84db9e5df1cd' ],
        [ sha224 => '323e7b28bfd64e6082f5b12110aa87bc0d6a6e159' ],
        [ sha256 => '23af4074c90a02b3fe61d286d5c87f425e6bdd81b' ],
        [ sha384 => '2132abe0ed518487d3e4fa7fd24f8bed1f29ccfce' ],
        [ sha512 => 'bbcc2f39939388fdfe841892537ec7b1ff33aa3' ],
    ),

    (
        map {
            my ($hashfn, $expect, $blksize) = @$_;

            {
                label => "K-233, $hashfn",
                order => '8000000000000000000000000000069D5BB915BCD46EFB1AD5F173ABDF',
                key => '103B2142BDC2A3C3B55080D09DF1808F79336DA2399F5CA7171D1BE9B0',
                hash => $hashfn,
                expect => $expect,
            },
        }
        [ sha1 => '273179e3e12c69591ad3dd9c7cce3985820e3913ab6696eb14486ddbcf' ],
        [ sha224 => '71626a309d9cd80ad0b975d757fe6bf4b84e49f8f34c780070d7746f19' ],
        [ sha256 => '73552f9cac5774f74f485fa253871f2109a0c86040552eaa67dba92dc9' ],
        [ sha384 => '17d726a67539c609bd99e29aa3737ef247724b71455c3b6310034038c8' ],
        [ sha512 => 'e535c328774cde546be3af5d7fcd263872f107e807435105ba2fdc166' ],
    ),

    (
        map {
            my ($hashfn, $expect, $blksize) = @$_;

            {
                label => "K-283, $hashfn",
                order => '1FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE9AE2ED07577265DFF7F94451E061E163C61',
                key => '06A0777356E87B89BA1ED3A3D845357BE332173C8F7A65BDC7DB4FAB3C4CC79ACC8194E',
                hash => $hashfn,
                expect => $expect,
            },
        }
        [ sha1 => 'a96f788decaf6c9dbe24dc75aba6eaae85e7ab003c8d4f83cb1540625b2993bf445692' ],
        [ sha224 => '1b4c4e3b2f6b08b5991bd2bdde277a7016da527ad0aae5bc61b64c5a0ee63e8b502ef61' ],
        [ sha256 => '1ceb9e8e0dff53ce687deb81339aca3c98e7a657d5a9499ef779f887a934408ecbe5a38' ],
        [ sha384 => '1460a5c41745a5763a9d548ae62f2c3630bbed71b6aa549d7f829c22442a728c5d965da' ],
        [ sha512 => 'f3b59fcb5c1a01a1a2a0019e98c244dff61502d6e6b9c4e957eddceb258ef4dbef04a' ],
    ),

    (
        map {
            my ($hashfn, $expect, $blksize) = @$_;

            {
                label => "K-409, $hashfn",
                order => '7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE5F83B2D4EA20400EC4557D5ED3E3E7CA5B4B5C83B8E01E5FCF',
                key => '29C16768F01D1B8A89FDA85E2EFD73A09558B92A178A2931F359E4D70AD853E569CDAF16DAA569758FB4E73089E4525D8BBFCF',
                hash => $hashfn,
                expect => $expect,
            },
        }
        [ sha1 => '7866e5247f9a3556f983c86e81eda696ac8489db40a2862f278603982d304f08b2b6e1e7848534beaf1330d37a1cf84c7994c1' ],
        [ sha224 => '512340db682c7b8ebe407bf1aa54194dfe85d49025fe0f632c9b8a06a996f2fcd0d73c752fb09d23db8fbe50605dc25df0745c' ],
        [ sha256 => '782385f18baf5a36a588637a76dfab05739a14163bf723a4417b74bd1469d37ac9e8cce6aec8ff63f37b815aaf14a876eed962' ],
        [ sha384 => '4da637cb2e5c90e486744e45a73935dd698d4597e736da332a06eda8b26d5abc6153ec2ece14981cf3e5e023f36ffa55eea6d7' ],
        [ sha512 => '57055b293ecfdfe983cef716166091e573275c53906a39eadc25c89c5ec8d7a7e5629fcfdfad514e1348161c9a34ea1c42d58c' ],
    ),

    (
        map {
            my ($hashfn, $expect, $blksize) = @$_;

            {
                label => "K-571, $hashfn",
                order => '20000000000000000000000000000000000000000000000000000000000000000000000131850E1F19A63E4B391A8DB917F4138B630D84BE5D639381E91DEB45CFE778F637C1001',
                key => '0C16F58550D824ED7B95569D4445375D3A490BC7E0194C41A39DEB732C29396CDF1D66DE02DD1460A816606F3BEC0F32202C7BD18A32D87506466AA92032F1314ED7B19762B0D22',
                hash => $hashfn,
                expect => $expect,
            },
        }
        [ sha1 => '17f7e360b21beae4a757a19aca77fb404d273f05719a86ead9d7b3f4d5ed7b4630584bb153cf7dcd5a87cca101bd7ea9eca0ce5ee27ca985833560000bb52b6bbe068740a45b267' ],
        [ sha224 => 'b599d068a1a00498ee0b9ad6f388521f594bd3f234e47f7a1db6490d7b57d60b0101b36f39cc22885f78641c69411279706f0989e6991e5d5b53619e43efb397e25e0814ef02bc' ],
        [ sha256 => 'f79d53e63d89fb87f4d9e6dc5949f5d9388bcfe9ebcb4c2f7ce497814cf40e845705f8f18dbf0f860de0b1cc4a433ef74a5741f3202e958c082e0b76e16ecd5866aa0f5f3df300' ],
        [ sha384 => '308253c022d25f8a9ebcd24459dd6596590bdec7895618eee8a2623a98d2a2b2e7594ee6b7ad3a39d70d68cb4ed01cb28e2129f8e2cc0cc8dc7780657e28bcd655f0be9b7d35a2' ],
        [ sha512 => 'c5ee7070af55f84ebc43a0d481458cede1dcebb57720a3c92f59b4941a044fecff4f703940f3121773595e880333772acf822f2449e17c64da286bcd65711dd5da44d7155bf004' ],
    ),

    (
        map {
            my ($hashfn, $expect, $blksize) = @$_;

            {
                label => "B-163, $hashfn",
                order => '40000000000000000000292FE77E70C12A4234C33',
                key => '35318FC447D48D7E6BC93B48617DDDEDF26AA658F',
                hash => $hashfn,
                expect => $expect,
            },
        }
        [ sha1 => '707a94c3d352e0a9fe49fb12f264992152a20004' ],
        [ sha224 => '3b24c5e2c2d935314eabf57a6484289b291adfe3f' ],
        [ sha256 => '3d7086a59e6981064a9cdb684653f3a81b6ec0f0b' ],
        [ sha384 => '3b1e4443443486c7251a68ef184a936f05f8b17c7' ],
        [ sha512 => '2edf5cfcac7553c17421fdf54ad1d2ef928a879d2' ],
    ),

    (
        map {
            my ($hashfn, $expect, $blksize) = @$_;

            {
                label => "B-233, $hashfn",
                order => '1000000000000000000000000000013E974E72F8A6922031D2603CFE0D7',
                key => '07ADC13DD5BF34D1DDEEB50B2CE23B5F5E6D18067306D60C5F6FF11E5D3',
                hash => $hashfn,
                expect => $expect,
            },
        }
        [ sha1 => 'a4e0b67a3a081c1b35d7beceb5fe72a918b422b907145db5416ed751ce' ],
        [ sha224 => 'f2b1c1e80beb58283aaa79857f7b83bdf724120d0913606fd07f7ffb2c' ],
        [ sha256 => '34a53897b0bbdb484302e19bf3f9b34a2abfed639d109a388dc52006b5' ],
        [ sha384 => '4d4670b28990bc92eeb49840b482a1fa03fe028d09f3d21f89c67eca85' ],
        [ sha512 => 'de108aaada760a14f42c057ef81c0a31af6b82e8fbca8dc86e443ab549' ],
    ),

    (
        map {
            my ($hashfn, $expect, $blksize) = @$_;

            {
                label => "B-283, $hashfn",
                order => '3FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEF90399660FC938A90165B042A7CEFADB307',
                key => '14510D4BC44F2D26F4553942C98073C1BD35545CEABB5CC138853C5158D2729EA408836',
                hash => $hashfn,
                expect => $expect,
            },
        }
        [ sha1 => '277f389559667e8ae4b65dc056f8ce2872e1917e7cc59d17d485b0b98343206fbccd441' ],
        [ sha224 => '14cc8fcfeecd6b999b4dc6084ebb06fded0b44d5c507802cc7a5e9ecf36e69da6ae23c6' ],
        [ sha256 => '38c9d662188982943e080b794a4cfb0732dba37c6f40d5b8cfaded6ff31c5452ba3f877' ],
        [ sha384 => '21b7265debf90e6f988cffdb62b121a02105226c652807cc324ed6fb119a287a72680ab' ],
        [ sha512 => '20583259dc179d9da8e5387e89bff2a3090788cf1496bcabfe7d45bb120b0c811eb8980' ],
    ),

    (
        map {
            my ($hashfn, $expect, $blksize) = @$_;

            {
                label => "B-409, $hashfn",
                order => '10000000000000000000000000000000000000000000000000001E2AAD6A612F33307BE5FA47C3C9E052F838164CD37D9A21173',
                key => '0494994CC325B08E7B4CE038BD9436F90B5E59A2C13C3140CD3AE07C04A01FC489F572CE0569A6DB7B8060393DE76330C624177',
                hash => $hashfn,
                expect => $expect,
            },
        }
        [ sha1 => '42d8a2b34402757eb2ccfddc3e6e96a7add3fda547fc10a0cb77cfc720b4f9e16eeaaa2a8cc4e4a4b5dbf7d8ac4ea491859e60' ],
        [ sha224 => 'c933f1dc4c70838c2ad16564715acaf545bcdd8dc203d25af3ec63949c65cb2e68ac1f60ca7eaca2a823f4e240927aa82ceec5' ],
        [ sha256 => '8ec42d13a3909a20c41bebd2dfed8cacce56c7a7d1251df43f3e9e289dae00e239f6960924ac451e125b784cb687c7f23283fd' ],
        [ sha384 => 'da881bce3ba851485879ef8ac585a63f1540b9198ecb8a1096d70cb25a104e2f8a96b108ae76cb49cf34491abc70e9d2aad450' ],
        [ sha512 => '750926ffad7ff5de85df7960b3a4f9e3d38cf5a049bfc89739c48d42b34fbee03d2c047025134cc3145b60afd22a68df0a7fb2' ],
    ),

    (
        map {
            my ($hashfn, $expect, $blksize) = @$_;

            {
                label => "B-571, $hashfn",
                order => '3FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE661CE18FF55987308059B186823851EC7DD9CA1161DE93D5174D66E8382E9BB2FE84E47',
                key => '028A04857F24C1C082DF0D909C0E72F453F2E2340CCB071F0E389BCA2575DA19124198C57174929AD26E348CF63F78D28021EF5A9BF2D5CBEAF6B7CCB6C4DA824DD5C82CFB24E11',
                hash => $hashfn,
                expect => $expect,
            },
        }
        [ sha1 => '2669fafef848af67d437d4a151c3c5d3f9aa8bb66edc35f090c9118f95ba0041b0993be2ef55daaf36b5b3a737c40db1f6e3d93d97b8419ad6e1bb8a5d4a0e9b2e76832d4e7b862' ],
        [ sha224 => '2eafad4ac8644deb29095bbaa88d19f31316434f1766ad4423e0b54dd2fe0c05e307758581b0daed2902683bbc7c47b00e63e3e429ba54ea6ba3aec33a94c9a24a6ef8e27b7677a' ],
        [ sha256 => '15c2c6b7d1a070274484774e558b69fdfa193bdb7a23f27c2cd24298ce1b22a6cc9b7fb8cabfd6cf7c6b1cf3251e5a1cddd16fbfed28de79935bb2c631b8b8ea9cc4bcc937e669e' ],
        [ sha384 => 'fef0b68cb49453a4c6ecbf1708dbeefc885c57fdafb88417aaefa5b1c35017b4b498507937adce2f1d9effa5fe8f5aeb116b804fd182a6cf1518fdb62d53f60a0ff6eb707d856b' ],
        [ sha512 => '3ff373833a06c791d7ad586afa3990f6ef76999c35246c4ad0d519bff180ca1880e11f2fb38b764854a0ae3becddb50f05ac4fcee542f207c0a6229e2e19652f0e647b9c4882193' ],
    ),
);

sub new {
    my $self = shift()->SUPER::new(@_);

    $self->num_method_tests( 'test__generate_k__sample', 0 + @{ [ _SAMPLE_TESTS ] } );
    $self->num_method_tests( 'test__generate_k__test', 0 + @{ [ _TEST_TESTS ] } );

    return $self;
}

sub test__generate_k__sample : Tests() {
    my $msg = 'sample';

    for my $t ( _SAMPLE_TESTS ) {
        _run_test_with_message($t, $msg);
    }

    return;
}

sub test__generate_k__test : Tests() {
    my $msg = 'test';

    for my $t ( _TEST_TESTS ) {
        _run_test_with_message($t, $msg);
    }

    return;
}

sub _run_test_with_message {
    my ($t, $msg) = @_;

    # For a few of the python-ecdsa-copied tests:
    $msg = $t->{'message'} if $t->{'message'};

    my ($q, $key, $hashfn, $expect) = @{$t}{'order', 'key', 'hash', 'expect'};

    $_ = Crypt::Perl::BigInt->from_hex($_) for ($q, $key);
    my $hash_cr = Digest::SHA->can($hashfn);

    my $hashed_msg = $hash_cr->($msg);

    my $k = Crypt::Perl::ECDSA::Deterministic::generate_k($q, $key, $hashed_msg, $hashfn);

    is(
        $k->to_hex(),
        $expect,
        $t->{label},
    );
}

1;
