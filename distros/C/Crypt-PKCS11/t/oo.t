#!perl

use Test::More;
use Config;

use Crypt::PKCS11 qw(:constant :constant_names);
use Crypt::PKCS11::Attributes;

our $HAVE_LEAKTRACE;
our $LEAK_TESTING;

sub myok {
    my ($res, $name) = @_;
    my ($package, $filename, $line) = caller;

    unless ($LEAK_TESTING) {
        ok( $res, $filename.'@'.$line.($name?': '.$name:'') );
    }
}

sub myisa_ok {
    my ($obj, $class, $name) = @_;
    my ($package, $filename, $line) = caller;

    unless ($LEAK_TESTING) {
        isa_ok( $obj, $class, $filename.'@'.$line.($name?': '.$name:'') );
    }
}

sub myis {
    my ($a, $b, $n) = @_;
    my ($package, $filename, $line) = caller;

    unless ($LEAK_TESTING) {
        is( $a, $b, $filename.'@'.$line.($n?': '.$n:'') );
    }
}

sub myis2 {
    my $a = shift;
    my $n = pop;
    my ($package, $filename, $line) = caller;

    unless ($LEAK_TESTING) {
        foreach (@_) {
            if ($a == $_) {
                is( $a, $_, $filename.'@'.$line.($n?': '.$n:'') );
                return;
            }
        }
        is( $a, $_[0], $filename.'@'.$line.($n?': '.$n:'') );
    }
}

sub myisnt {
    my ($a, $b, $n) = @_;
    my ($package, $filename, $line) = caller;

    unless ($LEAK_TESTING) {
        isnt( $a, $b, $filename.'@'.$line.($n?': '.$n:'') );
    }
}

sub signVerifyCheck {
    my ($obj) = @_;
    my $mechanism = Crypt::PKCS11::CK_MECHANISM->new;
    my $publicKeyTemplate = Crypt::PKCS11::Attributes->new->push(
        Crypt::PKCS11::Attribute::Encrypt->new->set(1),
        Crypt::PKCS11::Attribute::Verify->new->set(1),
        Crypt::PKCS11::Attribute::Wrap->new->set(1),
        Crypt::PKCS11::Attribute::PublicExponent->new->set(0x01, 0x00, 0x01),
        Crypt::PKCS11::Attribute::Token->new->set(1),
        Crypt::PKCS11::Attribute::ModulusBits->new->set(768)
    );
    my $privateKeyTemplate = Crypt::PKCS11::Attributes->new->push(
        Crypt::PKCS11::Attribute::Private->new->set(1),
        Crypt::PKCS11::Attribute::Id->new->set(123),
        Crypt::PKCS11::Attribute::Sensitive->new->set(1),
        Crypt::PKCS11::Attribute::Decrypt->new->set(1),
        Crypt::PKCS11::Attribute::Sign->new->set(1),
        Crypt::PKCS11::Attribute::Unwrap->new->set(1),
        Crypt::PKCS11::Attribute::Token->new->set(1)
    );
    my $data = 'Text';
    my $signature;
    my $session;

    myok( $obj->Initialize, 'signVerifyCheck: Initialize' );
    myisa_ok( $session = $obj->OpenSession($slotWithToken, CKF_SERIAL_SESSION | CKF_RW_SESSION), 'Crypt::PKCS11::Session', 'signVerifyCheck: OpenSession #1' );
    myok( $session->Login(CKU_USER, "1234"), 'signVerifyCheck: Login' );
    myis( $mechanism->set_mechanism(CKM_RSA_PKCS_KEY_PAIR_GEN), CKR_OK, 'signVerifyCheck: set_mechanism' );
    my ($publicKey, $privateKey) = $session->GenerateKeyPair($mechanism, $publicKeyTemplate, $privateKeyTemplate);
    myis( $session->errno, CKR_OK, 'signVerifyCheck: GenerateKeyPair '.$session->errstr );
    myisa_ok( $publicKey, 'Crypt::PKCS11::Object', 'signVerifyCheck: publicKey' );
    myisa_ok( $privateKey, 'Crypt::PKCS11::Object', 'signVerifyCheck: privateKey' );
    foreach (values %MECHANISM_SIGNVERIFY) {
        myok( $session->SignInit($_, $privateKey), 'signVerifyCheck: SignInit mech '.$CKM_NAME{$_->mechanism} );
        $signature = undef;
        myok( $signature = $session->Sign($data), 'signVerifyCheck: Sign mech '.$CKM_NAME{$_->mechanism} );
        myok( $session->VerifyInit($_, $publicKey), 'signVerifyCheck: VerifyInit mech '.$CKM_NAME{$_->mechanism} );
        myok( $session->Verify($data, $signature), 'signVerifyCheck: Verify mech '.$CKM_NAME{$_->mechanism} );
    }
    myok( $session->DestroyObject($privateKey), 'signVerifyCheck: DestroyObject' );
    myok( $session->DestroyObject($publicKey), 'signVerifyCheck: DestroyObject #2' );
    myok( $obj->Finalize, 'signVerifyCheck: Finalize' );
}

sub mytests {
    my @pkcs11_libraries = (
        '/softhsm/libsofthsm.so',
        '/softhsm/libsofthsm2.so'
    );
    my %library_paths = (
        '/usr/local/lib64' => 1,
        '/usr/lib64' => 1,
        '/usr/local/lib' => 1,
        '/usr/lib' => 1
    );
    my @libraries;

    foreach my $path (
        split / /, $Config{loclibpth},
        split / /, $Config{libpth} )
    {
        $library_paths{$path} = 1;
    }

    foreach my $path (keys %library_paths) {
        foreach my $so (@pkcs11_libraries) {
            push(@libraries, $path.$so) if (-r $path.$so);
        }
    }

    unless (scalar @libraries) {
        ok( 1, 'no libraries to test' );
        return;
    }

    foreach my $so (@libraries) {
        my $obj;
        my $s;

        $slotWithToken = 1;
        %MECHANISM_INFO = (
            CKM_RSA_PKCS_KEY_PAIR_GEN() => [ CKM_RSA_PKCS_KEY_PAIR_GEN, 'CKM_RSA_PKCS_KEY_PAIR_GEN' ],
            CKM_RSA_PKCS() => [ CKM_RSA_PKCS, 'CKM_RSA_PKCS' ],
            CKM_MD5() => [ CKM_MD5, 'CKM_MD5' ],
            CKM_RIPEMD160() => [ CKM_RIPEMD160, 'CKM_RIPEMD160' ],
            CKM_SHA_1() => [ CKM_SHA_1, 'CKM_SHA_1' ],
            CKM_SHA256() => [ CKM_SHA256, 'CKM_SHA256' ],
            CKM_SHA384() => [ CKM_SHA384, 'CKM_SHA384' ],
            CKM_SHA512() => [ CKM_SHA512, 'CKM_SHA512' ],
            CKM_MD5_RSA_PKCS() => [ CKM_MD5_RSA_PKCS, 'CKM_MD5_RSA_PKCS' ],
            CKM_RIPEMD160_RSA_PKCS() => [ CKM_RIPEMD160_RSA_PKCS, 'CKM_RIPEMD160_RSA_PKCS' ],
            CKM_SHA1_RSA_PKCS() => [ CKM_SHA1_RSA_PKCS, 'CKM_SHA1_RSA_PKCS' ],
            CKM_SHA256_RSA_PKCS() => [ CKM_SHA256_RSA_PKCS, 'CKM_SHA256_RSA_PKCS' ],
            CKM_SHA384_RSA_PKCS() => [ CKM_SHA384_RSA_PKCS, 'CKM_SHA384_RSA_PKCS' ],
            CKM_SHA512_RSA_PKCS() => [ CKM_SHA512_RSA_PKCS, 'CKM_SHA512_RSA_PKCS' ]
        );
        %MECHANISM_SIGNVERIFY = ();
        foreach (( CKM_RSA_PKCS, CKM_RSA_X_509, CKM_MD5_RSA_PKCS,
            CKM_RIPEMD160_RSA_PKCS, CKM_SHA1_RSA_PKCS ,CKM_SHA256_RSA_PKCS,
            CKM_SHA384_RSA_PKCS, CKM_SHA512_RSA_PKCS, CKM_SHA1_RSA_PKCS_PSS,
            CKM_SHA256_RSA_PKCS_PSS, CKM_SHA384_RSA_PKCS_PSS,
            CKM_SHA512_RSA_PKCS_PSS ))
        {
            myisa_ok( ($MECHANISM_SIGNVERIFY{$_} = Crypt::PKCS11::CK_MECHANISM->new), 'Crypt::PKCS11::CK_MECHANISMPtr' );
            myis( $MECHANISM_SIGNVERIFY{$_}->set_mechanism($_), CKR_OK, 'CK_MECHANISM->new->set_mechanism('.$CKM_NAME{$_}.')' );
        }

        myisa_ok( ($param = Crypt::PKCS11::CK_RSA_PKCS_PSS_PARAMS->new), 'Crypt::PKCS11::CK_RSA_PKCS_PSS_PARAMSPtr' );
        myis( $param->set_hashAlg(CKM_SHA_1), CKR_OK, 'CK_RSA_PKCS_PSS_PARAMS->set_hashAlg(CKM_SHA_1)' );
        myis( $param->set_mgf(CKG_MGF1_SHA1), CKR_OK, 'CK_RSA_PKCS_PSS_PARAMS->set_mgf(CKG_MGF1_SHA1)' );
        myis( $param->set_sLen(20), CKR_OK, 'CK_RSA_PKCS_PSS_PARAMS->set_sLen(20)' );
        myis( $MECHANISM_SIGNVERIFY{CKM_SHA1_RSA_PKCS_PSS()}->set_pParameter($param->toBytes), CKR_OK, 'CK_MECHANISM(CKM_SHA1_RSA_PKCS_PSS)->new->set_pParameter()' );

        myisa_ok( ($param = Crypt::PKCS11::CK_RSA_PKCS_PSS_PARAMS->new), 'Crypt::PKCS11::CK_RSA_PKCS_PSS_PARAMSPtr' );
        myis( $param->set_hashAlg(CKM_SHA256), CKR_OK, 'CK_RSA_PKCS_PSS_PARAMS->set_hashAlg(CKM_SHA256)' );
        myis( $param->set_mgf(CKG_MGF1_SHA256), CKR_OK, 'CK_RSA_PKCS_PSS_PARAMS->set_mgf(CKG_MGF1_SHA256)' );
        myis( $param->set_sLen(0), CKR_OK, 'CK_RSA_PKCS_PSS_PARAMS->set_sLen(0)' );
        myis( $MECHANISM_SIGNVERIFY{CKM_SHA256_RSA_PKCS_PSS()}->set_pParameter($param->toBytes), CKR_OK, 'CK_MECHANISM(CKM_SHA256_RSA_PKCS_PSS)->new->set_pParameter()' );

        myisa_ok( ($param = Crypt::PKCS11::CK_RSA_PKCS_PSS_PARAMS->new), 'Crypt::PKCS11::CK_RSA_PKCS_PSS_PARAMSPtr' );
        myis( $param->set_hashAlg(CKM_SHA384), CKR_OK, 'CK_RSA_PKCS_PSS_PARAMS->set_hashAlg(CKM_SHA384)' );
        myis( $param->set_mgf(CKG_MGF1_SHA384), CKR_OK, 'CK_RSA_PKCS_PSS_PARAMS->set_mgf(CKG_MGF1_SHA384)' );
        myis( $param->set_sLen(0), CKR_OK, 'CK_RSA_PKCS_PSS_PARAMS->set_sLen(0)' );
        myis( $MECHANISM_SIGNVERIFY{CKM_SHA384_RSA_PKCS_PSS()}->set_pParameter($param->toBytes), CKR_OK, 'CK_MECHANISM(CKM_SHA384_RSA_PKCS_PSS)->new->set_pParameter()' );

        myisa_ok( ($param = Crypt::PKCS11::CK_RSA_PKCS_PSS_PARAMS->new), 'Crypt::PKCS11::CK_RSA_PKCS_PSS_PARAMSPtr' );
        myis( $param->set_hashAlg(CKM_SHA512), CKR_OK, 'CK_RSA_PKCS_PSS_PARAMS->set_hashAlg(CKM_SHA512)' );
        myis( $param->set_mgf(CKG_MGF1_SHA512), CKR_OK, 'CK_RSA_PKCS_PSS_PARAMS->set_mgf(CKG_MGF1_SHA512)' );
        myis( $param->set_sLen(0), CKR_OK, 'CK_RSA_PKCS_PSS_PARAMS->set_sLen(0)' );
        myis( $MECHANISM_SIGNVERIFY{CKM_SHA512_RSA_PKCS_PSS()}->set_pParameter($param->toBytes), CKR_OK, 'CK_MECHANISM(CKM_SHA512_RSA_PKCS_PSS)->new->set_pParameter()' );

        if ($so =~ /libsofthsm\.so$/o) {
            $ENV{SOFTHSM_CONF} = 'softhsm.conf';
            system('softhsm --slot 1 --init-token --label slot1 --so-pin 12345678 --pin 1234') == 0 || die;
        }
        elsif ($so =~ /libsofthsm2\.so$/o) {
            $ENV{SOFTHSM2_CONF} = 'softhsm2.conf';
            system('mkdir -p tokens') == 0 || die;
            system('softhsm2-util --slot 0 --init-token --label slot1 --so-pin 12345678 --pin 1234') == 0 || die;
            $slotWithToken = 0;
            delete $MECHANISM_INFO{CKM_RIPEMD160()};
            delete $MECHANISM_INFO{CKM_RIPEMD160_RSA_PKCS()};
            delete $MECHANISM_SIGNVERIFY{CKM_RIPEMD160_RSA_PKCS()};
        }

        my (%hash, @array, $a);
        myisa_ok( $obj = Crypt::PKCS11->new, 'Crypt::PKCS11', $so.' new' );
        myok( $obj->load($so), $so.' load' );
        myok( $obj->Initialize, $so.' Initialize' );
        myisa_ok( scalar $obj->GetInfo, 'HASH', $so.' GetInfo' );
        %hash = $obj->GetInfo;
        myok( scalar %hash, 'GetInfo %hash' );
        myisa_ok( scalar $obj->GetSlotList, 'ARRAY', $so.' GetSlotList' );
        @array = $obj->GetSlotList;
        myok( scalar @array, 'GetSlotList @array' );
        myisa_ok( scalar $obj->GetSlotInfo($slotWithToken), 'HASH', $so.' GetSlotInfo' );
        %hash = $obj->GetSlotInfo($slotWithToken);
        myok( scalar %hash, 'GetSlotInfo %hash' );
        myisa_ok( scalar $obj->GetTokenInfo($slotWithToken), 'HASH', $so.' GetTokenInfo' );
        %hash = $obj->GetTokenInfo($slotWithToken);
        myok( scalar %hash, 'GetTokenInfo %hash' );
        myisa_ok( scalar $obj->GetMechanismList($slotWithToken), 'ARRAY', $so.' GetMechanismList' );
        @array = $obj->GetMechanismList($slotWithToken);
        myok( scalar @array, 'GetMechanismList @array' );
        myisa_ok( scalar $obj->GetMechanismInfo($slotWithToken, $array[0]), 'HASH', $so.' GetMechanismInfo' );
        %hash = $obj->GetMechanismInfo($slotWithToken, $array[0]);
        myok( scalar %hash, 'GetMechanismInfo %hash' );
        myisa_ok( $s = $obj->OpenSession($slotWithToken, CKF_SERIAL_SESSION), 'Crypt::PKCS11::Session', $so.' OpenSession' );
        myok( $s->CloseSession, $so.' CloseSession' );
        myok( $obj->CloseAllSessions($slotWithToken), $so.' CloseAllSessions' );
        myis( $obj->WaitForSlotEvent(CKF_DONT_BLOCK, $a = undef), undef, $so.' WaitForSlotEvent' );
        myok( $obj->Finalize, $so.' Finalize' );
        signVerifyCheck($obj);
        myok( $obj->Initialize, $so.' Initialize' );
        myok( $obj->InitToken($slotWithToken, "12345678", "ѪѫѬѪѫѬ"), 'InitToken '.$obj->errstr );
        myok( $obj->Finalize, $so.' Finalize' );
        myok( $obj->unload, $so.' unload' );

        myok( $obj->load($so), $so.' load' );
        $obj = undef;
    }
}

BEGIN {
    eval '
        use Test::LeakTrace;
        $HAVE_LEAKTRACE = 1;
    ';
}

chdir('t');
mytests;
if ($HAVE_LEAKTRACE and $ENV{TEST_LEAKTRACE}) {
    $LEAK_TESTING = 1;
    leaks_cmp_ok { mytests; } '<', 1;
}
done_testing;
