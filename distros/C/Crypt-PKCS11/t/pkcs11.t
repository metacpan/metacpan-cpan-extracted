#!perl

use strict;
use Config;
use Test::More;

use Crypt::PKCS11 qw(:constant);

our $HAVE_LEAKTRACE;
our $LEAK_TESTING;

our $slotWithToken;
our $slotWithNoToken;
our $slotWithNotInitToken;
our $slotInvalid;
our %MECHANISM_INFO;
our %MECHANISM_SIGNVERIFY;
our $VENDOR;
our %SUPPORT;

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

sub initCheck {
    my ($obj) = @_;
    my %initArgs = (
        UnlockMutex => sub { return CKR_OK; },
        flags => CKF_OS_LOCKING_OK
    );

    myis( $obj->C_Finalize, CKR_CRYPTOKI_NOT_INITIALIZED, 'initCheck: C_Finalize uninitialized' );

    myis( $obj->C_Initialize(\%initArgs), CKR_ARGUMENTS_BAD, 'initCheck: C_Initialize bad args' );
    delete $initArgs{UnlockMutex};
    myis( $obj->C_Initialize(\%initArgs), CKR_OK, 'initCheck: C_Initialize' );
    myis( $obj->C_Initialize(\%initArgs), CKR_CRYPTOKI_ALREADY_INITIALIZED, 'initCheck: C_Initialize already initialized' );
    myis( $obj->C_Finalize, CKR_OK, 'initCheck: C_Finalize' );
    myis( $obj->C_Initialize({}), CKR_OK, 'initCheck: C_Initialize #2' );
    myis( $obj->C_Finalize, CKR_OK, 'initCheck: C_Finalize #2' );
    foreach (qw(CreateMutex DestroyMutex LockMutex UnlockMutex flags)) {
        $initArgs{$_} = undef;
        myis( $obj->C_Initialize(\%initArgs), CKR_ARGUMENTS_BAD, 'initCheck: C_Initialize '.$_ );
        delete $initArgs{$_};
    }
    foreach (qw(CreateMutex DestroyMutex LockMutex UnlockMutex flags)) {
        $initArgs{$_} = undef;
        myis( $obj->C_Initialize(\%initArgs), CKR_ARGUMENTS_BAD, 'initCheck: C_Initialize '.$_ );
    }
    %initArgs = (
#        CreateMutex => sub { return 9999; },
#        DestroyMutex => sub { die unless ($_[0] ==  9999); return CKR_OK; },
#        LockMutex => sub { die unless ($_[0] ==  9999); return CKR_OK; },
#        UnlockMutex => sub { die unless ($_[0] ==  9999); return CKR_OK; }
    );
    myis( $obj->C_Initialize(\%initArgs), CKR_OK, 'initCheck: C_Initialize #3' );
    myis( $obj->C_Finalize, CKR_OK, 'initCheck: C_Finalize #3' );
    Crypt::PKCS11::XS::clearCreateMutex;
    Crypt::PKCS11::XS::clearDestroyMutex;
    Crypt::PKCS11::XS::clearLockMutex;
    Crypt::PKCS11::XS::clearUnlockMutex;
    myis( $obj->C_Initialize({}), CKR_OK, 'initCheck: C_Initialize #2' );
    myis( $obj->C_Finalize, CKR_OK, 'initCheck: C_Finalize #2' );
}

sub infoCheck {
    my ($obj) = @_;
    my ($list, $info, $rv);

    myis( $obj->C_GetInfo($info = {}), CKR_CRYPTOKI_NOT_INITIALIZED, 'infoCheck: C_GetInfo uninitialized' );
    myis( $obj->C_GetSlotList(CK_FALSE, $list = []), CKR_CRYPTOKI_NOT_INITIALIZED, 'infoCheck: C_GetSlotList uninitialized' );
    myis( $obj->C_GetSlotInfo($slotInvalid, $info = {}), CKR_CRYPTOKI_NOT_INITIALIZED, 'infoCheck: C_GetSlotInfo uninitialized' );
    myis( $obj->C_GetTokenInfo($slotInvalid, $info = {}), CKR_CRYPTOKI_NOT_INITIALIZED, 'infoCheck: C_GetTokenInfo uninitialized' );
    myis( $obj->C_GetMechanismList($slotInvalid, $list = []), CKR_CRYPTOKI_NOT_INITIALIZED, 'infoCheck: C_GetMechanismList uninitialized' );
    myis( $obj->C_GetMechanismInfo($slotInvalid, CKM_VENDOR_DEFINED, $info = {}), CKR_CRYPTOKI_NOT_INITIALIZED, 'infoCheck: C_GetMechanismInfo uninitialized' );

    myis( $obj->C_Initialize({}), CKR_OK, 'infoCheck: C_Initialize' );
    myis( $obj->C_GetInfo($info = {}), CKR_OK, 'infoCheck: C_GetInfo' );
    myis( $obj->C_GetSlotList(CK_FALSE, $list = []), CKR_OK, 'infoCheck: C_GetSlotList' );
    myis( $obj->C_GetSlotList(CK_TRUE, $list = []), CKR_OK, 'infoCheck: C_GetSlotList' );
    myis( $obj->C_GetSlotInfo($slotInvalid, $info = {}), CKR_SLOT_ID_INVALID, 'infoCheck: C_GetSlotInfo slotInvalid' );
    myis( $obj->C_GetSlotInfo($slotWithToken, $info = {}), CKR_OK, 'infoCheck: C_GetSlotInfo' );
    myis( $obj->C_GetTokenInfo($slotInvalid, $info = {}), CKR_SLOT_ID_INVALID, 'infoCheck: C_GetTokenInfo slotInvalid' );
    defined $slotWithNoToken and myis2( ($rv = $obj->C_GetTokenInfo($slotWithNoToken, $info = {})), CKR_OK, CKR_TOKEN_NOT_PRESENT, 'infoCheck: C_GetTokenInfo slotWithNoToken' );
    if ($rv == CKR_OK) {
        myisnt( scalar $info, 0, 'infoCheck: C_GetTokenInfo slotWithNoToken CKR_OK' );
    }
    myis( $obj->C_GetTokenInfo($slotWithToken, $info = {}), CKR_OK, 'infoCheck: C_GetTokenInfo' );
    myis( $obj->C_GetMechanismList($slotInvalid, $list = []), CKR_SLOT_ID_INVALID, 'infoCheck: C_GetMechanismList slotInvalid' );
    myis( $obj->C_GetMechanismList($slotWithToken, $list = []), CKR_OK, 'infoCheck: C_GetMechanismList' );
    myis( $obj->C_GetMechanismInfo($slotInvalid, CKM_VENDOR_DEFINED, $info = {}), CKR_SLOT_ID_INVALID, 'infoCheck: C_GetMechanismInfo slotInvalid' );
    myis( $obj->C_GetMechanismInfo($slotWithToken, CKM_VENDOR_DEFINED, $info = {}), CKR_MECHANISM_INVALID, 'infoCheck: C_GetMechanismInfo invalid mechanism' );
    foreach (values %MECHANISM_INFO) {
        myis2( $obj->C_GetMechanismInfo($slotWithToken, $_->[0], $info = {}), CKR_OK, 'infoCheck: '.CKR_MECHANISM_INVALID, 'C_GetMechanismInfo '.$_->[1] );
    }
    myis( $obj->C_Finalize, CKR_OK, 'infoCheck: C_Finalize' );
}

sub sessionCheck {
    my ($obj) = @_;
    my @sessions = (CK_INVALID_HANDLE, CK_INVALID_HANDLE, CK_INVALID_HANDLE, CK_INVALID_HANDLE, CK_INVALID_HANDLE);
    my $info;

    myis( $obj->C_OpenSession($slotInvalid, 0, undef, $sessions[0]), CKR_CRYPTOKI_NOT_INITIALIZED, 'sessionCheck: C_OpenSession uninitialized' );
    myis2( $obj->C_CloseSession($sessions[0]), CKR_CRYPTOKI_NOT_INITIALIZED, CKR_SESSION_HANDLE_INVALID, 'sessionCheck: C_CloseSession uninitialized' );
    myis( $obj->C_CloseAllSessions($slotInvalid), CKR_CRYPTOKI_NOT_INITIALIZED, 'sessionCheck: C_CloseAllSessions uninitialized' );
    myis( $obj->C_GetSessionInfo($slotInvalid, $info = {}), CKR_CRYPTOKI_NOT_INITIALIZED, 'sessionCheck: C_GetSessionInfo uninitialized' );

    myis( $obj->C_Initialize({}), CKR_OK, 'sessionCheck: C_Initialize' );
    myis( $obj->C_OpenSession($slotInvalid, 0, undef, $sessions[0]), CKR_SLOT_ID_INVALID, 'sessionCheck: C_OpenSession slotInvalid' );
    defined $slotWithNoToken and myis2( $obj->C_OpenSession($slotWithNoToken, 0, undef, $sessions[0]), CKR_TOKEN_NOT_PRESENT, CKR_SESSION_PARALLEL_NOT_SUPPORTED, 'sessionCheck: C_OpenSession slotWithNoToken' );
    defined $slotWithNotInitToken and myis2( $obj->C_OpenSession($slotWithNotInitToken, 0, undef, $sessions[0]), CKR_TOKEN_NOT_RECOGNIZED, CKR_SESSION_PARALLEL_NOT_SUPPORTED, 'sessionCheck: C_OpenSession slotWithNotInitToken' );
    defined $slotWithNotInitToken and myis( $obj->C_OpenSession($slotWithNotInitToken, CKF_SERIAL_SESSION, undef, $sessions[0]), CKR_TOKEN_NOT_RECOGNIZED, 'sessionCheck: C_OpenSession slotWithNotInitToken #2' );
    myis( $obj->C_OpenSession($slotWithToken, 0, undef, $sessions[0]), CKR_SESSION_PARALLEL_NOT_SUPPORTED, 'sessionCheck: C_OpenSession not serial' );
    myis( $obj->C_OpenSession($slotWithToken, CKF_SERIAL_SESSION, undef, $sessions[0]), CKR_OK, 'sessionCheck: C_OpenSession #0' );
    myis( $obj->C_CloseSession(CK_INVALID_HANDLE), CKR_SESSION_HANDLE_INVALID, 'sessionCheck: C_CloseSession invalid handle' );
    myis( $obj->C_CloseSession($sessions[0]), CKR_OK, 'sessionCheck: C_CloseSession #0' );
    myis( $obj->C_OpenSession($slotWithToken, CKF_SERIAL_SESSION, undef, $sessions[1]), CKR_OK, 'sessionCheck: C_OpenSession #1' );
    myis( $obj->C_OpenSession($slotWithToken, CKF_SERIAL_SESSION, undef, $sessions[2]), CKR_OK, 'sessionCheck: C_OpenSession #2' );
    myis( $obj->C_OpenSession($slotWithToken, CKF_SERIAL_SESSION, undef, $sessions[3]), CKR_OK, 'sessionCheck: C_OpenSession #3' );
    myis( $obj->C_OpenSession($slotWithToken, CKF_SERIAL_SESSION, undef, $sessions[4]), CKR_OK, 'sessionCheck: C_OpenSession #4' );
    myis( $obj->C_CloseSession($sessions[3]), CKR_OK, 'sessionCheck: C_CloseSession #3' );
    myis( $obj->C_CloseAllSessions($slotInvalid), CKR_SLOT_ID_INVALID, 'sessionCheck: C_CloseAllSessions slotInvalid' );
    defined $slotWithNoToken and myis( $obj->C_CloseAllSessions($slotWithNoToken), CKR_OK, 'sessionCheck: C_CloseAllSessions slotWithNoToken' );
    myis( $obj->C_CloseSession($sessions[2]), CKR_OK, 'sessionCheck: C_CloseSession #2' );
    myis( $obj->C_CloseAllSessions($slotWithToken), CKR_OK, 'sessionCheck: C_CloseAllSessions slotWithToken' );
    myis( $obj->C_GetSessionInfo(CK_INVALID_HANDLE, $info = {}), CKR_SESSION_HANDLE_INVALID, 'sessionCheck: C_GetSessionInfo invalid handle' );
    myis( $obj->C_OpenSession($slotWithToken, CKF_SERIAL_SESSION, undef, $sessions[0]), CKR_OK, 'sessionCheck: C_OpenSession #0 #2' );
    myis( $obj->C_OpenSession($slotWithToken, CKF_SERIAL_SESSION | CKF_RW_SESSION, undef, $sessions[1]), CKR_OK, 'sessionCheck: C_OpenSession #1 #2' );
    myis( $obj->C_GetSessionInfo($sessions[0], $info = {}), CKR_OK, 'sessionCheck: C_GetSessionInfo #0' );
    myis( $obj->C_GetSessionInfo($sessions[1], $info = {}), CKR_OK, 'sessionCheck: C_GetSessionInfo #1' );
    myis( $obj->C_Finalize, CKR_OK, 'sessionCheck: C_Finalize' );
}

sub userCheck {
    my ($obj) = @_;
    my @sessions = (CK_INVALID_HANDLE, CK_INVALID_HANDLE);

    myis2( $obj->C_Login(CK_INVALID_HANDLE, 9999, ""), CKR_CRYPTOKI_NOT_INITIALIZED, CKR_SESSION_HANDLE_INVALID, 'userCheck: C_Login uninitialized' );
    myis2( $obj->C_Logout(CK_INVALID_HANDLE), CKR_CRYPTOKI_NOT_INITIALIZED, CKR_SESSION_HANDLE_INVALID, 'userCheck: C_Logout uninitialized' );

    myis( $obj->C_Initialize({}), CKR_OK, 'userCheck: C_Initialize' );
    myis( $obj->C_OpenSession($slotWithToken, CKF_SERIAL_SESSION, undef, $sessions[0]), CKR_OK, 'userCheck: C_OpenSession #0' );
    myis( $obj->C_OpenSession($slotWithToken, CKF_SERIAL_SESSION | CKF_RW_SESSION, undef, $sessions[1]), CKR_OK, 'userCheck: C_OpenSession #1' );
    myis( $obj->C_Login(CK_INVALID_HANDLE, 9999, ""), CKR_SESSION_HANDLE_INVALID, 'userCheck: C_Login invalid handle' );
    myis2( $obj->C_Login($sessions[0], 9999, ""), CKR_ARGUMENTS_BAD, CKR_PIN_INCORRECT, CKR_USER_TYPE_INVALID, 'userCheck: C_Login bad pin' );
    myis( $obj->C_Login($sessions[0], 9999, "1234"), CKR_USER_TYPE_INVALID, 'userCheck: C_Login invalid user type' );
    myis( $obj->C_Login($sessions[0], CKU_CONTEXT_SPECIFIC, "1234"), CKR_OPERATION_NOT_INITIALIZED, 'userCheck: C_Login context specific' );
    myis( $obj->C_Login($sessions[0], CKU_USER, "123"), CKR_PIN_INCORRECT, 'userCheck: C_Login bad pin #2' );
    myis( $obj->C_Login($sessions[0], CKU_USER, "1234"), CKR_OK, 'userCheck: C_Login' );
    myis2( $obj->C_Login($sessions[0], CKU_CONTEXT_SPECIFIC, "1234"), CKR_OK, CKR_OPERATION_NOT_INITIALIZED, 'userCheck: C_Login context specific #2' );
    myis2( $obj->C_Login($sessions[1], CKU_SO, "12345678"), CKR_USER_ANOTHER_ALREADY_LOGGED_IN, CKR_SESSION_READ_ONLY_EXISTS, 'userCheck: C_Login already logged in' );
    myis( $obj->C_Logout($sessions[0]), CKR_OK, 'userCheck: C_Logout' );
    myis( $obj->C_Login($sessions[1], CKU_SO, "12345678"), CKR_SESSION_READ_ONLY_EXISTS, 'userCheck: C_Login read only exists' );
    myis( $obj->C_CloseSession($sessions[0]), CKR_OK, 'userCheck: C_CloseSession' );
    myis( $obj->C_Login($sessions[1], CKU_SO, "1234567"), CKR_PIN_INCORRECT, 'userCheck: C_Login SO bad pin' );
    myis( $obj->C_Login($sessions[1], CKU_SO, "12345678"), CKR_OK, 'userCheck: C_Login SO' );
    myis2( $obj->C_Login($sessions[1], CKU_CONTEXT_SPECIFIC, "12345678"), CKR_OK, CKR_OPERATION_NOT_INITIALIZED, 'userCheck: C_Login SO context specific' );
    myis2( $obj->C_Login($sessions[1], CKU_USER, "1234"), CKR_USER_ANOTHER_ALREADY_LOGGED_IN, CKR_SESSION_READ_ONLY_EXISTS, 'userCheck: C_Login already logged in #2' );
    myis( $obj->C_Logout(CK_INVALID_HANDLE), CKR_SESSION_HANDLE_INVALID, 'userCheck: C_Logout invalid handle' );
    myis( $obj->C_Logout($sessions[1]), CKR_OK, 'userCheck: C_Logout #2' );
    myis( $obj->C_Finalize, CKR_OK, 'userCheck: C_Finalize' );
}

sub randomCheck {
    my ($obj) = @_;
    my $session;
    my $seed = 'abcd';
    my $random;

    myis2( $obj->C_SeedRandom(CK_INVALID_HANDLE, $seed), CKR_CRYPTOKI_NOT_INITIALIZED, CKR_SESSION_HANDLE_INVALID, 'randomCheck: C_SeedRandom uninitialized' );
    myis2( $obj->C_GenerateRandom(CK_INVALID_HANDLE, $random, 1), CKR_CRYPTOKI_NOT_INITIALIZED, CKR_SESSION_HANDLE_INVALID, 'randomCheck: C_GenerateRandom uninitialized' );

    myis( $obj->C_Initialize({}), CKR_OK, 'randomCheck: C_Initialize' );
    myis( $obj->C_OpenSession($slotWithToken, CKF_SERIAL_SESSION, undef, $session), CKR_OK, 'randomCheck: C_OpenSession' );
    myis( $obj->C_SeedRandom(CK_INVALID_HANDLE, $seed), CKR_SESSION_HANDLE_INVALID, 'randomCheck: C_SeedRandom invalid handle' );
    myis( $obj->C_SeedRandom($session, $seed), CKR_OK, 'randomCheck: C_SeedRandom' );
    myis( $obj->C_GenerateRandom(CK_INVALID_HANDLE, $random, 1), CKR_SESSION_HANDLE_INVALID, 'randomCheck: C_GenerateRandom invalid handle' );
    myis( $obj->C_GenerateRandom($session, $random, 40), CKR_OK, 'randomCheck: C_GenerateRandom' );
    myis( $obj->C_Finalize, CKR_OK, 'randomCheck: C_Finalize' );
}

sub generateCheck {
    my ($obj) = @_;
    my @sessions = (CK_INVALID_HANDLE, CK_INVALID_HANDLE);
    my $modulusBits = pack(CK_ULONG_SIZE < 8 ? 'L' : 'Q', 768);
    my $publicExponent = pack('C*', 0x01, 0x00, 0x01);
    my $modulus = pack('C*',
        0xcb, 0x12, 0x9d, 0xba, 0x22, 0xfa, 0x2b, 0x33, 0x7e, 0x2a, 0x24, 0x65, 0x09, 0xa9,
        0xfb, 0x41, 0x1a, 0x0e, 0x2f, 0x89, 0x3a, 0xd6, 0x97, 0x49, 0x77, 0x6d, 0x2a, 0x6e, 0x98,
        0x48, 0x6b, 0xa8, 0xc4, 0x63, 0x8e, 0x46, 0x90, 0x70, 0x2e, 0xd4, 0x10, 0xc0, 0xdd, 0xa3,
        0x56, 0xcf, 0x97, 0x2f, 0x2f, 0xfc, 0x2d, 0xff, 0x2b, 0xf2, 0x42, 0x69, 0x4a, 0x8c, 0xf1,
        0x6f, 0x76, 0x32, 0xc8, 0xe1, 0x37, 0x52, 0xc1, 0xd1, 0x33, 0x82, 0x39, 0x1a, 0xb3, 0x2a,
        0xa8, 0x80, 0x4e, 0x19, 0x91, 0xa6, 0xa6, 0x16, 0x65, 0x30, 0x72, 0x80, 0xc3, 0x5c, 0x84,
        0x9b, 0x7b, 0x2c, 0x6d, 0x2d, 0x75, 0x51, 0x9f, 0xc9, 0x6d, 0xa8, 0x4d, 0x8c, 0x41, 0x41,
        0x12, 0xc9, 0x14, 0xc7, 0x99, 0x31, 0xe4, 0xcd, 0x97, 0x38, 0x2c, 0xca, 0x32, 0x2f, 0xeb,
        0x78, 0x37, 0x17, 0x87, 0xc8, 0x09, 0x5a, 0x1a, 0xaf, 0xe4, 0xc4, 0xcc, 0x83, 0xe3, 0x79,
        0x01, 0xd6, 0xdb, 0x8b, 0xd6, 0x24, 0x90, 0x43, 0x7b, 0xc6, 0x40, 0x57, 0x58, 0xe4, 0x49,
        0x2b, 0x99, 0x61, 0x71, 0x52, 0xf4, 0x8b, 0xda, 0xb7, 0x5a, 0xbf, 0xf7, 0xc5, 0x2a, 0x8b,
        0x1f, 0x25, 0x5e, 0x5b, 0xfb, 0x9f, 0xcc, 0x8d, 0x1c, 0x92, 0x21, 0xe9, 0xba, 0xd0, 0x54,
        0xf6, 0x0d, 0xe8, 0x7e, 0xb3, 0x9d, 0x9a, 0x47, 0xba, 0x1e, 0x45, 0x4e, 0xdc, 0xe5, 0x20,
        0x95, 0xd8, 0xe5, 0xe9, 0x51, 0xff, 0x1f, 0x9e, 0x9e, 0x60, 0x3c, 0x27, 0x1c, 0xf3, 0xc7,
        0xf4, 0x89, 0xaa, 0x2a, 0x80, 0xd4, 0x03, 0x5d, 0xf3, 0x39, 0xa3, 0xa7, 0xe7, 0x3f, 0xa9,
        0xd1, 0x31, 0x50, 0xb7, 0x0f, 0x08, 0xa2, 0x71, 0xcc, 0x6a, 0xb4, 0xb5, 0x8f, 0xcb, 0xf7,
        0x1f, 0x4e, 0xc8, 0x16, 0x08, 0xc0, 0x03, 0x8a, 0xce, 0x17, 0xd1, 0xdd, 0x13, 0x0f, 0xa3,
        0xbe, 0xa3 );
    my $id = pack('C', 123);
    my $label = pack('a*', 'label');
    my $pubClass = pack(CK_ULONG_SIZE < 8 ? 'L' : 'Q', CKO_PUBLIC_KEY);
    my $keyType = pack(CK_ULONG_SIZE < 8 ? 'L' : 'Q', CKK_RSA);
    my $true = pack('C', CK_TRUE);
    my $false = pack('C', CK_FALSE);
    my $certCategory = pack(CK_ULONG_SIZE < 8 ? 'L' : 'Q', 0);
    my $publicKey = CK_INVALID_HANDLE;
    my $privateKey = CK_INVALID_HANDLE;
    my $object = CK_INVALID_HANDLE;
    my $mechanism = {
        mechanism => CKM_VENDOR_DEFINED
    };
    my @publicKeyTemplate = (
        { type => CKA_ENCRYPT, pValue => $true },
        { type => CKA_VERIFY, pValue => $true },
        { type => CKA_WRAP, pValue => $true },
        { type => CKA_PUBLIC_EXPONENT, pValue => $publicExponent },
        { type => CKA_TOKEN, pValue => $true }
    );
    my @privateKeyTemplate = (
        { type => CKA_PRIVATE, pValue => $true },
        { type => CKA_ID, pValue => $id },
        { type => CKA_SENSITIVE, pValue => $true },
        { type => CKA_DECRYPT, pValue => $true },
        { type => CKA_SIGN, pValue => $true },
        { type => CKA_UNWRAP, pValue => $true },
        { type => CKA_TOKEN, pValue => $true }
    );
    my @pubTemplate = (
        { type => CKA_CLASS, pValue => $pubClass },
        { type => CKA_KEY_TYPE, pValue => $keyType },
        { type => CKA_LABEL, pValue => $label },
        { type => CKA_ID, pValue => $id },
        { type => CKA_TOKEN, pValue => $true },
        { type => CKA_VERIFY, pValue => $true },
        { type => CKA_ENCRYPT, pValue => $false },
        { type => CKA_WRAP, pValue => $false },
        { type => CKA_PUBLIC_EXPONENT, pValue => $publicExponent }
    );

    myis2( $obj->C_GenerateKeyPair(CK_INVALID_HANDLE, {}, [], [], $publicKey, $privateKey), CKR_CRYPTOKI_NOT_INITIALIZED, CKR_SESSION_HANDLE_INVALID, 'generateCheck: C_GenerateKeyPair uninitialized' );
    myis2( $obj->C_DestroyObject(CK_INVALID_HANDLE, CK_INVALID_HANDLE), CKR_CRYPTOKI_NOT_INITIALIZED, CKR_SESSION_HANDLE_INVALID, 'generateCheck: C_DestroyObject uninitialized' );
    myis2( $obj->C_CreateObject(CK_INVALID_HANDLE, [], $object), CKR_CRYPTOKI_NOT_INITIALIZED, CKR_SESSION_HANDLE_INVALID, 'generateCheck: C_CreateObject uninitialized' );

    myis( $obj->C_Initialize({}), CKR_OK, 'generateCheck: C_Initialize' );
    myis( $obj->C_OpenSession($slotWithToken, CKF_SERIAL_SESSION, undef, $sessions[0]), CKR_OK, 'generateCheck: C_OpenSession #0' );
    myis( $obj->C_OpenSession($slotWithToken, CKF_SERIAL_SESSION | CKF_RW_SESSION, undef, $sessions[1]), CKR_OK, 'generateCheck: C_OpenSession #1' );
    myis( $obj->C_GenerateKeyPair(CK_INVALID_HANDLE, {}, [], [], $publicKey, $privateKey), CKR_SESSION_HANDLE_INVALID, 'generateCheck: C_GenerateKeyPair invalid handle' );
    $mechanism->{mechanism} = CKM_RSA_PKCS_KEY_PAIR_GEN;
    myis2( $obj->C_GenerateKeyPair($sessions[0], $mechanism, \@publicKeyTemplate, \@privateKeyTemplate, $publicKey, $privateKey), CKR_USER_NOT_LOGGED_IN, CKR_SESSION_READ_ONLY, 'generateCheck: C_GenerateKeyPair not logged in' );
    myis( $obj->C_Login($sessions[0], CKU_USER, "1234"), CKR_OK, 'generateCheck: C_Login' );
    myis2( $obj->C_GenerateKeyPair($sessions[0], $mechanism, \@publicKeyTemplate, \@privateKeyTemplate, $publicKey, $privateKey), CKR_USER_NOT_LOGGED_IN, CKR_SESSION_READ_ONLY, 'generateCheck: C_GenerateKeyPair not logged in #2' );
    $mechanism->{mechanism} = CKM_VENDOR_DEFINED;
    myis( $obj->C_GenerateKeyPair($sessions[1], $mechanism, \@publicKeyTemplate, \@privateKeyTemplate, $publicKey, $privateKey), CKR_MECHANISM_INVALID, 'generateCheck: C_GenerateKeyPair invalid mechanism' );
    $mechanism->{mechanism} = CKM_RSA_PKCS_KEY_PAIR_GEN;
    myis( $obj->C_GenerateKeyPair($sessions[1], $mechanism, \@publicKeyTemplate, \@privateKeyTemplate, $publicKey, $privateKey), CKR_TEMPLATE_INCOMPLETE, 'generateCheck: C_GenerateKeyPair template incomplete' );
    push(@publicKeyTemplate, { type => CKA_MODULUS_BITS, pValue => $modulusBits });
    myis( $obj->C_GenerateKeyPair($sessions[1], $mechanism, \@publicKeyTemplate, \@privateKeyTemplate, $publicKey, $privateKey), CKR_OK, 'generateCheck: C_GenerateKeyPair' );
    myis( $obj->C_DestroyObject(CK_INVALID_HANDLE, CK_INVALID_HANDLE), CKR_SESSION_HANDLE_INVALID, 'generateCheck: C_DestroyObject invalid handle' );
    myis( $obj->C_DestroyObject($sessions[0], CK_INVALID_HANDLE), CKR_OBJECT_HANDLE_INVALID, 'generateCheck: C_DestroyObject invalid handle #2' );
    myis2( $obj->C_DestroyObject($sessions[0], $privateKey), CKR_OBJECT_HANDLE_INVALID, CKR_SESSION_READ_ONLY, 'generateCheck: C_DestroyObject invalid handle #3' );
    myis( $obj->C_DestroyObject($sessions[1], $privateKey), CKR_OK, 'generateCheck: C_DestroyObject' );
    myis( $obj->C_DestroyObject($sessions[1], $publicKey), CKR_OK, 'generateCheck: C_DestroyObject #2' );
    myis( $obj->C_Logout($sessions[0]), CKR_OK, 'generateCheck: C_Logout' );
    myis( $obj->C_CreateObject(CK_INVALID_HANDLE, [], $object), CKR_SESSION_HANDLE_INVALID, 'generateCheck: C_CreateObject invalid handle' );
    myis( $obj->C_CreateObject($sessions[0], \@pubTemplate, $object), CKR_SESSION_READ_ONLY, 'generateCheck: C_CreateObject read only' );
    myis( $obj->C_CreateObject($sessions[1], \@pubTemplate, $object), CKR_USER_NOT_LOGGED_IN, 'generateCheck: C_CreateObject not logged in' );
    myis( $obj->C_Login($sessions[0], CKU_USER, "1234"), CKR_OK, 'generateCheck: C_Login #2' );
    myis( $obj->C_CreateObject($sessions[1], \@pubTemplate, $object), CKR_TEMPLATE_INCOMPLETE, 'generateCheck: C_CreateObject template incomplete' );
    push(@pubTemplate, { type => CKA_MODULUS, pValue => $modulus },
        { type => CKA_CERTIFICATE_CATEGORY, pValue => $certCategory });
    myis( $obj->C_CreateObject($sessions[1], \@pubTemplate, $object), CKR_ATTRIBUTE_TYPE_INVALID, 'generateCheck: C_CreateObject attribute invalid' );
    pop(@pubTemplate);
    myis( $obj->C_CreateObject($sessions[1], \@pubTemplate, $object), CKR_OK, 'generateCheck: C_CreateObject' );
    myis( $obj->C_DestroyObject($sessions[1], $object), CKR_OK, 'generateCheck: C_DestroyObject #3' );
    myis( $obj->C_Finalize, CKR_OK, 'generateCheck: C_Finalize' );
}

sub objectCheck {
    my ($obj) = @_;
    my @sessions = (CK_INVALID_HANDLE, CK_INVALID_HANDLE);
    my $modulusBits = pack(CK_ULONG_SIZE < 8 ? 'L' : 'Q', 768);
    my $publicExponent = pack('C*', 0x01, 0x00, 0x01);
    my $id = pack('C', 123);
    my $true = pack('C', CK_TRUE);
    my $publicKey = CK_INVALID_HANDLE;
    my $privateKey = CK_INVALID_HANDLE;
    my $mechanism = {
        mechanism => CKM_RSA_PKCS_KEY_PAIR_GEN
    };
    my @publicKeyTemplate = (
        { type => CKA_ENCRYPT, pValue => $true },
        { type => CKA_VERIFY, pValue => $true },
        { type => CKA_WRAP, pValue => $true },
        { type => CKA_PUBLIC_EXPONENT, pValue => $publicExponent },
        { type => CKA_TOKEN, pValue => $true },
        { type => CKA_MODULUS_BITS, pValue => $modulusBits }
    );
    my @privateKeyTemplate = (
        { type => CKA_PRIVATE, pValue => $true },
        { type => CKA_ID, pValue => $id },
        { type => CKA_SENSITIVE, pValue => $true },
        { type => CKA_DECRYPT, pValue => $true },
        { type => CKA_SIGN, pValue => $true },
        { type => CKA_UNWRAP, pValue => $true },
        { type => CKA_TOKEN, pValue => $true }
    );
    my $list;
    my $oClass = pack(CK_ULONG_SIZE < 8 ? 'L' : 'Q', CKO_PUBLIC_KEY);
    my @searchTemplate = (
        { type => CKA_CLASS, pValue => $oClass }
    );
    my @getAttr = (
        { type => CKA_PRIME_1 }
    );
    my @template1 = (
        { type => CKA_LABEL, pValue => pack('a*', 'New label') }
    );
    my @template2 = (
        { type => CKA_CLASS, pValue => pack(CK_ULONG_SIZE < 8 ? 'L' : 'Q', 1) }
    );
    my @getAttr2 = (
        { type => CKA_ID }
    );

    myis2( $obj->C_FindObjectsInit(CK_INVALID_HANDLE, $list = []), CKR_CRYPTOKI_NOT_INITIALIZED, CKR_SESSION_HANDLE_INVALID, 'objectCheck: C_FindObjectsInit uninitialized' );
    myis2( $obj->C_FindObjects(CK_INVALID_HANDLE, $list = [], 1), CKR_CRYPTOKI_NOT_INITIALIZED, CKR_SESSION_HANDLE_INVALID, 'objectCheck: C_FindObjects uninitialized' );
    myis2( $obj->C_FindObjectsFinal(CK_INVALID_HANDLE), CKR_CRYPTOKI_NOT_INITIALIZED, CKR_SESSION_HANDLE_INVALID, 'objectCheck: C_FindObjectsFinal uninitialized' );
    myis2( $obj->C_GetAttributeValue(CK_INVALID_HANDLE, CK_INVALID_HANDLE, $list = []), CKR_CRYPTOKI_NOT_INITIALIZED, CKR_SESSION_HANDLE_INVALID, 'objectCheck: C_GetAttributeValue uninitialized' );
    myis2( $obj->C_SetAttributeValue(CK_INVALID_HANDLE, CK_INVALID_HANDLE, $list = []), CKR_CRYPTOKI_NOT_INITIALIZED, CKR_SESSION_HANDLE_INVALID, 'objectCheck: C_SetAttributeValue uninitialized' );

    myis( $obj->C_Initialize({}), CKR_OK, 'objectCheck: C_Initialize' );
    myis( $obj->C_OpenSession($slotWithToken, CKF_SERIAL_SESSION, undef, $sessions[0]), CKR_OK, 'objectCheck: C_OpenSession #0' );
    myis( $obj->C_OpenSession($slotWithToken, CKF_SERIAL_SESSION | CKF_RW_SESSION, undef, $sessions[1]), CKR_OK, 'objectCheck: C_OpenSession #1' );
    myis( $obj->C_Login($sessions[1], CKU_USER, "1234"), CKR_OK, 'objectCheck: C_Login' );
    myis( $obj->C_GenerateKeyPair($sessions[1], $mechanism, \@publicKeyTemplate, \@privateKeyTemplate, $publicKey, $privateKey), CKR_OK, 'objectCheck: C_GenerateKeyPair' );
    if ($VENDOR ne 'softhsm2') {
        myis( $obj->C_Logout($sessions[1]), CKR_OK, 'objectCheck: C_Logout' );
        myis( $obj->C_FindObjectsInit(CK_INVALID_HANDLE, \@searchTemplate), CKR_SESSION_HANDLE_INVALID, 'objectCheck: C_FindObjectsInit invalid handle' );
        myis( $obj->C_FindObjectsInit($sessions[0], \@searchTemplate), CKR_OK, 'objectCheck: C_FindObjectsInit' );
        myis( $obj->C_FindObjectsInit($sessions[0], \@searchTemplate), CKR_OPERATION_ACTIVE, 'objectCheck: C_FindObjectsInit active' );
        myis( $obj->C_FindObjects(CK_INVALID_HANDLE, $list = [], 1), CKR_SESSION_HANDLE_INVALID, 'objectCheck: C_FindObjects invalid handle' );
        myis( $obj->C_FindObjects($sessions[1], $list = [], 1), CKR_OPERATION_NOT_INITIALIZED, 'objectCheck: C_FindObjects op not init' );
        myis( $obj->C_FindObjects($sessions[0], $list = [], 1), CKR_OK, 'objectCheck: C_FindObjects' );
        myis( $obj->C_FindObjectsFinal(CK_INVALID_HANDLE), CKR_SESSION_HANDLE_INVALID, 'objectCheck: C_FindObjectsFinal invalid handle' );
        myis( $obj->C_FindObjectsFinal($sessions[1]), CKR_OPERATION_NOT_INITIALIZED, 'objectCheck: C_FindObjectsFinal op not init' );
        myis( $obj->C_FindObjectsFinal($sessions[0]), CKR_OK, 'objectCheck: C_FindObjectsFinal' );
        myis( $obj->C_GetAttributeValue(CK_INVALID_HANDLE, CK_INVALID_HANDLE, $list = []), CKR_SESSION_HANDLE_INVALID, 'objectCheck: C_GetAttributeValue invalid handle' );
        myis( $obj->C_GetAttributeValue($sessions[0], CK_INVALID_HANDLE, $list = []), CKR_OBJECT_HANDLE_INVALID, 'objectCheck: C_GetAttributeValue invalid handle #2' );
        myis( $obj->C_GetAttributeValue($sessions[0], $privateKey, \@getAttr2), CKR_OBJECT_HANDLE_INVALID, 'objectCheck: C_GetAttributeValue invalid handle #3' );
        myis( $obj->C_Login($sessions[1], CKU_USER, "1234"), CKR_OK, 'objectCheck: C_Login #2' );
    }
    myis( $obj->C_GetAttributeValue($sessions[0], $privateKey, \@getAttr), CKR_ATTRIBUTE_SENSITIVE, 'objectCheck: C_GetAttributeValue' );
    $getAttr[0]->{type} = 999999;
    myis( $obj->C_GetAttributeValue($sessions[0], $privateKey, \@getAttr), CKR_ATTRIBUTE_TYPE_INVALID, 'objectCheck: C_GetAttributeValue #2' );
    $getAttr[0]->{type} = CKA_ID;
    myis( $obj->C_GetAttributeValue($sessions[0], $privateKey, \@getAttr), CKR_OK, 'objectCheck: C_GetAttributeValue #3' );
    if ($VENDOR ne 'softhsm2') {
        myis( $obj->C_Logout($sessions[1]), CKR_OK, 'objectCheck: C_Logout #2' );
        myis( $obj->C_SetAttributeValue(CK_INVALID_HANDLE, CK_INVALID_HANDLE, $list = []), CKR_SESSION_HANDLE_INVALID, 'objectCheck: C_SetAttributeValue invalid handle' );
        myis( $obj->C_SetAttributeValue($sessions[0], CK_INVALID_HANDLE, $list = []), CKR_OBJECT_HANDLE_INVALID, 'objectCheck: C_SetAttributeValue invalid handle #2' );
        myis( $obj->C_SetAttributeValue($sessions[0], $privateKey, $list = []), CKR_OBJECT_HANDLE_INVALID, 'objectCheck: C_SetAttributeValue invalid handle #3' );
        myis( $obj->C_Login($sessions[1], CKU_USER, "1234"), CKR_OK, 'objectCheck: C_Login #3' );
    }
    myis2( $obj->C_SetAttributeValue($sessions[0], $privateKey, $list = []), CKR_OBJECT_HANDLE_INVALID, CKR_ARGUMENTS_BAD, 'objectCheck: C_SetAttributeValue' );
    myis( $obj->C_SetAttributeValue($sessions[1], $privateKey, \@template2), CKR_ATTRIBUTE_READ_ONLY, 'objectCheck: C_SetAttributeValue #2' );
    myis( $obj->C_SetAttributeValue($sessions[1], $privateKey, \@template1), CKR_OK, 'objectCheck: C_SetAttributeValue #3' );
    myis( $obj->C_DestroyObject($sessions[1], $privateKey), CKR_OK, 'objectCheck: C_DestroyObject' );
    myis( $obj->C_DestroyObject($sessions[1], $publicKey), CKR_OK, 'objectCheck: C_DestroyObject #2' );
    if ($SUPPORT{C_CopyObject}) {
        my @copyTemplate1 = (
            { type => CKA_CLASS, pValue => pack(CK_ULONG_SIZE < 8 ? 'L' : 'Q', CKO_DATA) },
            { type => CKA_TOKEN, pValue => pack('C', CK_FALSE) },
            { type => CKA_PRIVATE, pValue => pack('C', CK_FALSE) },
            { type => CKA_LABEL, pValue => pack('a*', 'C_CopyObject') }
        );
        my @copyTemplate2 = (
            { type => CKA_LABEL, pValue => pack('a*', 'Label modified via C_CopyObject') }
        );
        my @copyTemplate3 = (
            { type => CKA_CLASS, pValue => pack(CK_ULONG_SIZE < 8 ? 'L' : 'Q', CKO_DATA) },
            { type => CKA_TOKEN, pValue => pack('C', CK_FALSE) },
            { type => CKA_PRIVATE, pValue => pack('C', CK_FALSE) },
            { type => CKA_LABEL, pValue => pack('a*', 'C_CopyObject') },
            { type => CKA_APPLICATION, pValue => pack('a*', 'application') },
            { type => CKA_OBJECT_ID, pValue => pack('a*', 'invalid object id') },
            { type => CKA_VALUE, pValue => pack('a*', 'Sample data') }
        );
        my $copyKey1 = CK_INVALID_HANDLE;
        my $copyKey2 = CK_INVALID_HANDLE;

        myis( $obj->C_Logout($sessions[1]), CKR_OK, 'objectCheck: C_CopyObject C_Logout' );
        myis( $obj->C_CreateObject($sessions[0], \@copyTemplate1, $copyKey1), CKR_OK, 'objectCheck: C_CopyObject C_CreateObject' );
        myis( $obj->C_CopyObject($sessions[0], $copyKey1, \@copyTemplate2, $copyKey2), CKR_OK, 'objectCheck: C_CopyObject' );
        myis( $obj->C_DestroyObject($sessions[0], $copyKey2), CKR_OK, 'objectCheck: C_CopyObject C_DestroyObject' );
        push(@copyTemplate2,
            { type => CKA_TOKEN, pValue => pack('C', CK_FALSE) },
            { type => CKA_PRIVATE, pValue => pack('C', CK_FALSE) });
        myis( $obj->C_CopyObject($sessions[0], $copyKey1, \@copyTemplate2, $copyKey2), CKR_OK, 'objectCheck: C_CopyObject #2' );
        myis( $obj->C_DestroyObject($sessions[0], $copyKey2), CKR_OK, 'objectCheck: C_CopyObject C_DestroyObject #2' );
        push(@copyTemplate2,
            { type => CKA_CLASS, pValue => pack(CK_ULONG_SIZE < 8 ? 'L' : 'Q', CKO_DATA) });
        myis( $obj->C_CopyObject($sessions[0], $copyKey1, \@copyTemplate2, $copyKey2), CKR_ATTRIBUTE_READ_ONLY, 'objectCheck: C_CopyObject #3' );
        pop(@copyTemplate2);
        $copyTemplate2[1]->{pValue} = pack('C', CK_TRUE);
        myis( $obj->C_CopyObject($sessions[0], $copyKey1, \@copyTemplate2, $copyKey2), CKR_SESSION_READ_ONLY, 'objectCheck: C_CopyObject #4' );
        $copyTemplate2[1]->{pValue} = pack('C', CK_FALSE);
        $copyTemplate2[2]->{pValue} = pack('C', CK_TRUE);
        myis( $obj->C_CopyObject($sessions[0], $copyKey1, \@copyTemplate2, $copyKey2), CKR_USER_NOT_LOGGED_IN, 'objectCheck: C_CopyObject #4' );
        $copyTemplate2[2]->{pValue} = pack('C', CK_FALSE);
        myis( $obj->C_DestroyObject($sessions[0], $copyKey1), CKR_OK, 'objectCheck: C_CopyObject C_DestroyObject #3' );
        myis( $obj->C_Login($sessions[1], CKU_USER, "1234"), CKR_OK, 'objectCheck: C_CopyObject C_Login' );
        myis( $obj->C_CreateObject($sessions[1], \@copyTemplate3, $copyKey1), CKR_OK, 'objectCheck: C_CopyObject C_CreateObject #2' );
        $copyTemplate2[1]->{pValue} = pack('C', CK_TRUE);
        myis( $obj->C_CopyObject($sessions[1], $copyKey1, \@copyTemplate2, $copyKey2), CKR_OK, 'objectCheck: C_CopyObject #2' );
        myis( $obj->C_DestroyObject($sessions[1], $copyKey2), CKR_OK, 'objectCheck: C_CopyObject C_DestroyObject #4' );
        $copyTemplate2[2]->{pValue} = pack('C', CK_TRUE);
        myis( $obj->C_CopyObject($sessions[1], $copyKey1, \@copyTemplate2, $copyKey2), CKR_OK, 'objectCheck: C_CopyObject #3' );
        myis( $obj->C_DestroyObject($sessions[1], $copyKey2), CKR_OK, 'objectCheck: C_CopyObject C_DestroyObject #5' );
        push(@copyTemplate2,
            { type => CKA_OBJECT_ID, pValue => pack('a*', 'Another object ID') });
        myis( $obj->C_CopyObject($sessions[1], $copyKey1, \@copyTemplate2, $copyKey2), CKR_ATTRIBUTE_READ_ONLY, 'objectCheck: C_CopyObject #4' );
        myis( $obj->C_DestroyObject($sessions[1], $copyKey1), CKR_OK, 'objectCheck: C_CopyObject C_DestroyObject #6' );
        $copyTemplate3[2]->{pValue} = pack('C', CK_TRUE);
        myis( $obj->C_CreateObject($sessions[1], \@copyTemplate3, $copyKey1), CKR_OK, 'objectCheck: C_CopyObject C_CreateObject #3' );
        $copyTemplate2[1]->{pValue} = pack('C', CK_FALSE);
        $copyTemplate2[2]->{pValue} = pack('C', CK_FALSE);
        myis( $obj->C_CopyObject($sessions[1], $copyKey1, \@copyTemplate2, $copyKey2), CKR_TEMPLATE_INCONSISTENT, 'objectCheck: C_CopyObject #5' );
        myis( $obj->C_DestroyObject($sessions[1], $copyKey1), CKR_OK, 'objectCheck: C_CopyObject C_DestroyObject #7' );
    }
    myis( $obj->C_Finalize, CKR_OK, 'objectCheck: C_Finalize' );
}

sub digestCheck {
    my ($obj) = @_;
    my @sessions = (CK_INVALID_HANDLE, CK_INVALID_HANDLE);
    my $mechanism = {
        mechanism => CKM_VENDOR_DEFINED
    };
    my $data = 'Text to digest';
    my $digest;

    myis2( $obj->C_DigestInit(CK_INVALID_HANDLE, $mechanism), CKR_CRYPTOKI_NOT_INITIALIZED, CKR_SESSION_HANDLE_INVALID, 'digestCheck: C_DigestInit uninitialized' );
    myis2( $obj->C_Digest(CK_INVALID_HANDLE, $data, $digest), CKR_CRYPTOKI_NOT_INITIALIZED, CKR_SESSION_HANDLE_INVALID, 'digestCheck: C_Digest uninitialized' );
    myis2( $obj->C_DigestUpdate(CK_INVALID_HANDLE, $data), CKR_CRYPTOKI_NOT_INITIALIZED, CKR_SESSION_HANDLE_INVALID, 'digestCheck: C_DigestUpdate uninitialized' );
    myis2( $obj->C_DigestFinal(CK_INVALID_HANDLE, $digest), CKR_CRYPTOKI_NOT_INITIALIZED, CKR_SESSION_HANDLE_INVALID, 'digestCheck: C_DigestFinal uninitialized' );

    myis( $obj->C_Initialize({}), CKR_OK, 'digestCheck: C_Initialize' );
    myis( $obj->C_OpenSession($slotWithToken, CKF_SERIAL_SESSION, undef, $sessions[0]), CKR_OK, 'digestCheck: C_OpenSession #0' );
    myis( $obj->C_OpenSession($slotWithToken, CKF_SERIAL_SESSION, undef, $sessions[1]), CKR_OK, 'digestCheck: C_OpenSession #1' );
    myis( $obj->C_DigestInit(CK_INVALID_HANDLE, $mechanism), CKR_SESSION_HANDLE_INVALID, 'digestCheck: C_DigestInit invalid handle' );
    myis( $obj->C_DigestInit($sessions[0], $mechanism), CKR_MECHANISM_INVALID, 'digestCheck: C_DigestInit' );
    $mechanism->{mechanism} = CKM_SHA512;
    myis( $obj->C_DigestInit($sessions[0], $mechanism), CKR_OK, 'digestCheck: C_DigestInit #2' );
    myis( $obj->C_DigestInit($sessions[0], $mechanism), CKR_OPERATION_ACTIVE, 'digestCheck: C_DigestInit #3' );
    myis( $obj->C_Digest(CK_INVALID_HANDLE, $data, $digest), CKR_SESSION_HANDLE_INVALID, 'digestCheck: C_Digest invalid handle' );
    myis( $obj->C_Digest($sessions[1], $data, $digest), CKR_OPERATION_NOT_INITIALIZED, 'digestCheck: C_Digest op not init' );
    myis( $obj->C_Digest($sessions[0], $data, $digest), CKR_OK, 'digestCheck: C_Digest' );
    myisnt( $digest, undef, 'digestCheck: C_Digest not undef' );
    myisnt( $digest, '', 'digestCheck: C_Digest not empty string' );
    myis( $obj->C_Digest($sessions[0], $data, $digest), CKR_OPERATION_NOT_INITIALIZED, 'digestCheck: C_Digest #2' );
    myis( $obj->C_DigestUpdate(CK_INVALID_HANDLE, $data), CKR_SESSION_HANDLE_INVALID, 'digestCheck: C_DigestUpdate invalid handle' );
    myis( $obj->C_DigestUpdate($sessions[0], $data), CKR_OPERATION_NOT_INITIALIZED, 'digestCheck: C_DigestUpdate op not init' );
    myis( $obj->C_DigestInit($sessions[0], $mechanism), CKR_OK, 'digestCheck: C_DigestInit #3' );
    myis( $obj->C_DigestUpdate($sessions[0], $data), CKR_OK, 'digestCheck: C_DigestUpdate' );
    myis( $obj->C_DigestFinal(CK_INVALID_HANDLE, $digest), CKR_SESSION_HANDLE_INVALID, 'digestCheck: C_DigestFinal invalid handle' );
    $digest = undef;
    myis( $obj->C_DigestFinal($sessions[1], $digest), CKR_OPERATION_NOT_INITIALIZED, 'digestCheck: C_DigestFinal op not init' );
    myis( $obj->C_DigestFinal($sessions[0], $digest), CKR_OK, 'digestCheck: C_DigestFinal' );
    myisnt( $digest, undef, 'digestCheck: C_Digest not undef' );
    myisnt( $digest, '', 'digestCheck: C_Digest not empty string' );
    myis( $obj->C_Finalize, CKR_OK, 'digestCheck: C_Finalize' );
}

sub signCheck {
    my ($obj) = @_;
    my @sessions = (CK_INVALID_HANDLE, CK_INVALID_HANDLE);
    my $modulusBits = pack(CK_ULONG_SIZE < 8 ? 'L' : 'Q', 768);
    my $publicExponent = pack('C*', 0x01, 0x00, 0x01);
    my $id = pack('C', 123);
    my $true = pack('C', CK_TRUE);
    my $publicKey = CK_INVALID_HANDLE;
    my $privateKey = CK_INVALID_HANDLE;
    my $mechanism = {
        mechanism => CKM_RSA_PKCS_KEY_PAIR_GEN
    };
    my @publicKeyTemplate = (
        { type => CKA_ENCRYPT, pValue => $true },
        { type => CKA_VERIFY, pValue => $true },
        { type => CKA_WRAP, pValue => $true },
        { type => CKA_PUBLIC_EXPONENT, pValue => $publicExponent },
        { type => CKA_TOKEN, pValue => $true },
        { type => CKA_MODULUS_BITS, pValue => $modulusBits }
    );
    my @privateKeyTemplate = (
        { type => CKA_PRIVATE, pValue => $true },
        { type => CKA_ID, pValue => $id },
        { type => CKA_SENSITIVE, pValue => $true },
        { type => CKA_DECRYPT, pValue => $true },
        { type => CKA_SIGN, pValue => $true },
        { type => CKA_UNWRAP, pValue => $true },
        { type => CKA_TOKEN, pValue => $true }
    );
    my $data = 'Text to sign';
    my $signature;

    myis2( $obj->C_SignInit(CK_INVALID_HANDLE, $mechanism, $privateKey), CKR_CRYPTOKI_NOT_INITIALIZED, CKR_SESSION_HANDLE_INVALID, 'signCheck: C_SignInit uninitialized' );
    myis2( $obj->C_Sign(CK_INVALID_HANDLE, $data, $signature), CKR_CRYPTOKI_NOT_INITIALIZED, CKR_SESSION_HANDLE_INVALID, 'signCheck: C_Sign uninitialized' );
    myis2( $obj->C_SignUpdate(CK_INVALID_HANDLE, $data), CKR_CRYPTOKI_NOT_INITIALIZED, CKR_SESSION_HANDLE_INVALID, 'signCheck: C_SignUpdate uninitialized' );
    myis2( $obj->C_SignFinal(CK_INVALID_HANDLE, $signature), CKR_CRYPTOKI_NOT_INITIALIZED, CKR_SESSION_HANDLE_INVALID, 'signCheck: C_SignFinal uninitialized' );

    myis( $obj->C_Initialize({}), CKR_OK, 'signCheck: C_Initialize' );
    myis( $obj->C_OpenSession($slotWithToken, CKF_SERIAL_SESSION, undef, $sessions[0]), CKR_OK, 'signCheck: C_OpenSession #0' );
    myis( $obj->C_OpenSession($slotWithToken, CKF_SERIAL_SESSION | CKF_RW_SESSION, undef, $sessions[1]), CKR_OK, 'signCheck: C_OpenSession #1' );
    myis( $obj->C_Login($sessions[1], CKU_USER, "1234"), CKR_OK, 'signCheck: C_Login' );
    myis( $obj->C_GenerateKeyPair($sessions[1], $mechanism, \@publicKeyTemplate, \@privateKeyTemplate, $publicKey, $privateKey), CKR_OK, 'signCheck: C_GenerateKeyPair' );
    if ($VENDOR ne 'softhsm2') {
        myis( $obj->C_Logout($sessions[1]), CKR_OK, 'signCheck: C_Logout' );
        $mechanism->{mechanism} = CKM_VENDOR_DEFINED;
        myis( $obj->C_SignInit(CK_INVALID_HANDLE, $mechanism, CK_INVALID_HANDLE), CKR_SESSION_HANDLE_INVALID, 'signCheck: C_SignInit invalid handle' );
        myis( $obj->C_SignInit($sessions[0], $mechanism, CK_INVALID_HANDLE), CKR_KEY_HANDLE_INVALID, 'signCheck: C_SignInit invalid handle #2' );
        myis( $obj->C_SignInit($sessions[0], $mechanism, $privateKey), CKR_KEY_HANDLE_INVALID, 'signCheck: C_SignInit invalid handle #3' );
        myis( $obj->C_Login($sessions[1], CKU_USER, "1234"), CKR_OK, 'signCheck: C_Login #2' );
    }
    myis( $obj->C_SignInit($sessions[0], $mechanism, $privateKey), CKR_MECHANISM_INVALID, 'signCheck: C_SignInit' );
    $mechanism->{mechanism} = CKM_SHA512_RSA_PKCS;
    myis( $obj->C_SignInit($sessions[0], $mechanism, $privateKey), CKR_OK, 'signCheck: C_SignInit #2' );
    myis( $obj->C_SignInit($sessions[0], $mechanism, $privateKey), CKR_OPERATION_ACTIVE, 'signCheck: C_SignInit #3' );
    myis( $obj->C_Sign(CK_INVALID_HANDLE, $data, $signature), CKR_SESSION_HANDLE_INVALID, 'signCheck: C_Sign invalid handle' );
    myis( $obj->C_Sign($sessions[1], $data, $signature), CKR_OPERATION_NOT_INITIALIZED, 'signCheck: C_Sign op not init' );
    myis( $obj->C_Sign($sessions[0], $data, $signature), CKR_OK, 'signCheck: C_Sign' );
    myisnt( $signature, undef, 'signCheck: C_Sign not undef' );
    myisnt( $signature, '', 'signCheck: C_Sign not empty string' );
    myis( $obj->C_Sign($sessions[0], $data, $signature), CKR_OPERATION_NOT_INITIALIZED, 'signCheck: C_Sign #2' );
    myis( $obj->C_SignUpdate(CK_INVALID_HANDLE, $data), CKR_SESSION_HANDLE_INVALID, 'signCheck: C_SignUpdate invalid handle' );
    myis( $obj->C_SignUpdate($sessions[0], $data), CKR_OPERATION_NOT_INITIALIZED, 'signCheck: C_SignUpdate op not init' );
    myis( $obj->C_SignInit($sessions[0], $mechanism, $privateKey), CKR_OK, 'signCheck: C_SignInit #3' );
    myis( $obj->C_SignUpdate($sessions[0], $data), CKR_OK, 'signCheck: C_SignUpdate' );
    myis( $obj->C_SignFinal(CK_INVALID_HANDLE, $signature), CKR_SESSION_HANDLE_INVALID, 'signCheck: C_SignFinal invalid handle' );
    $signature = undef;
    myis( $obj->C_SignFinal($sessions[1], $signature), CKR_OPERATION_NOT_INITIALIZED, 'signCheck: C_SignFinal op not init' );
    myis( $obj->C_SignFinal($sessions[0], $signature), CKR_OK, 'signCheck: C_SignFinal' );
    myisnt( $signature, undef, 'signCheck: C_Sign not undef' );
    myisnt( $signature, '', 'signCheck: C_Sign not empty string' );
    myis( $obj->C_DestroyObject($sessions[1], $privateKey), CKR_OK, 'signCheck: C_DestroyObject' );
    myis( $obj->C_DestroyObject($sessions[1], $publicKey), CKR_OK, 'signCheck: C_DestroyObject #2' );
    myis( $obj->C_Finalize, CKR_OK, 'signCheck: C_Finalize' );
}

sub verifyCheck {
    my ($obj) = @_;
    my @sessions = (CK_INVALID_HANDLE, CK_INVALID_HANDLE);
    my $modulusBits = pack(CK_ULONG_SIZE < 8 ? 'L' : 'Q', 768);
    my $publicExponent = pack('C*', 0x01, 0x00, 0x01);
    my $id = pack('C', 123);
    my $true = pack('C', CK_TRUE);
    my $publicKey = CK_INVALID_HANDLE;
    my $privateKey = CK_INVALID_HANDLE;
    my $mechanism = {
        mechanism => CKM_RSA_PKCS_KEY_PAIR_GEN
    };
    my @publicKeyTemplate = (
        { type => CKA_ENCRYPT, pValue => $true },
        { type => CKA_VERIFY, pValue => $true },
        { type => CKA_WRAP, pValue => $true },
        { type => CKA_PUBLIC_EXPONENT, pValue => $publicExponent },
        { type => CKA_TOKEN, pValue => $true },
        { type => CKA_MODULUS_BITS, pValue => $modulusBits }
    );
    my @privateKeyTemplate = (
        { type => CKA_PRIVATE, pValue => $true },
        { type => CKA_ID, pValue => $id },
        { type => CKA_SENSITIVE, pValue => $true },
        { type => CKA_DECRYPT, pValue => $true },
        { type => CKA_SIGN, pValue => $true },
        { type => CKA_UNWRAP, pValue => $true },
        { type => CKA_TOKEN, pValue => $true }
    );
    my $signature = 'bad';
    my $data = 'Text';

    myis2( $obj->C_VerifyInit(CK_INVALID_HANDLE, $mechanism, $publicKey), CKR_CRYPTOKI_NOT_INITIALIZED, CKR_SESSION_HANDLE_INVALID, 'verifyCheck: C_VerifyInit uninitialized' );
    myis2( $obj->C_Verify(CK_INVALID_HANDLE, $data, $signature), CKR_CRYPTOKI_NOT_INITIALIZED, CKR_SESSION_HANDLE_INVALID, 'verifyCheck: C_Verify uninitialized' );
    myis2( $obj->C_VerifyUpdate(CK_INVALID_HANDLE, $data), CKR_CRYPTOKI_NOT_INITIALIZED, CKR_SESSION_HANDLE_INVALID, 'verifyCheck: C_VerifyUpdate uninitialized' );
    myis2( $obj->C_VerifyFinal(CK_INVALID_HANDLE, $signature), CKR_CRYPTOKI_NOT_INITIALIZED, CKR_SESSION_HANDLE_INVALID, 'verifyCheck: C_VerifyFinal uninitialized' );

    myis( $obj->C_Initialize({}), CKR_OK, 'verifyCheck: C_Initialize' );
    myis( $obj->C_OpenSession($slotWithToken, CKF_SERIAL_SESSION, undef, $sessions[0]), CKR_OK, 'verifyCheck: C_OpenSession #0' );
    myis( $obj->C_OpenSession($slotWithToken, CKF_SERIAL_SESSION | CKF_RW_SESSION, undef, $sessions[1]), CKR_OK, 'verifyCheck: C_OpenSession #1' );
    myis( $obj->C_Login($sessions[1], CKU_USER, "1234"), CKR_OK, 'verifyCheck: C_Login' );
    myis( $obj->C_GenerateKeyPair($sessions[1], $mechanism, \@publicKeyTemplate, \@privateKeyTemplate, $publicKey, $privateKey), CKR_OK, 'verifyCheck: C_GenerateKeyPair' );
    $mechanism->{mechanism} = CKM_VENDOR_DEFINED;
    if ($VENDOR ne 'softhsm2') {
        myis( $obj->C_Logout($sessions[1]), CKR_OK, 'verifyCheck: C_Logout' );
        myis( $obj->C_VerifyInit(CK_INVALID_HANDLE, $mechanism, CK_INVALID_HANDLE), CKR_SESSION_HANDLE_INVALID, 'verifyCheck: C_VerifyInit invalid handle' );
        myis( $obj->C_VerifyInit($sessions[0], $mechanism, CK_INVALID_HANDLE), CKR_KEY_HANDLE_INVALID, 'verifyCheck: C_VerifyInit invalid handle #2' );
        myis( $obj->C_VerifyInit($sessions[0], $mechanism, $publicKey), CKR_KEY_HANDLE_INVALID, 'verifyCheck: C_VerifyInit invalid handle #3' );
        myis( $obj->C_Login($sessions[1], CKU_USER, "1234"), CKR_OK, 'verifyCheck: C_Login #2' );
    }
    myis( $obj->C_VerifyInit($sessions[0], $mechanism, $publicKey), CKR_MECHANISM_INVALID, 'verifyCheck: C_VerifyInit' );
    $mechanism->{mechanism} = CKM_SHA512_RSA_PKCS;
    myis( $obj->C_VerifyInit($sessions[0], $mechanism, $publicKey), CKR_OK, 'verifyCheck: C_VerifyInit #2' );
    myis( $obj->C_VerifyInit($sessions[0], $mechanism, $publicKey), CKR_OPERATION_ACTIVE, 'verifyCheck: C_VerifyInit #3' );
    myis( $obj->C_Verify(CK_INVALID_HANDLE, $data, $signature), CKR_SESSION_HANDLE_INVALID, 'verifyCheck: C_Verify invalid handle' );
    myis( $obj->C_Verify($sessions[1], $data, $signature), CKR_OPERATION_NOT_INITIALIZED, 'verifyCheck: C_Verify op not init' );
    myis( $obj->C_Verify($sessions[0], $data, $signature), CKR_SIGNATURE_LEN_RANGE, 'verifyCheck: C_Verify' );
    myis( $obj->C_Verify($sessions[0], $data, $signature), CKR_OPERATION_NOT_INITIALIZED, 'verifyCheck: C_Verify #2' );
    myis( $obj->C_VerifyUpdate(CK_INVALID_HANDLE, $signature), CKR_SESSION_HANDLE_INVALID, 'verifyCheck: C_VerifyUpdate invalid handle' );
    myis( $obj->C_VerifyUpdate($sessions[0], $signature), CKR_OPERATION_NOT_INITIALIZED, 'verifyCheck: C_VerifyUpdate op not init' );
    myis( $obj->C_VerifyInit($sessions[0], $mechanism, $publicKey), CKR_OK, 'verifyCheck: C_VerifyInit #3' );
    myis( $obj->C_VerifyUpdate($sessions[0], $signature), CKR_OK, 'verifyCheck: C_VerifyUpdate' );
    myis( $obj->C_VerifyFinal(CK_INVALID_HANDLE, $signature), CKR_SESSION_HANDLE_INVALID, 'verifyCheck: C_VerifyFinal invalid handle' );
    myis( $obj->C_VerifyFinal($sessions[1], $signature), CKR_OPERATION_NOT_INITIALIZED, 'verifyCheck: C_VerifyFinal op not init' );
    myis( $obj->C_VerifyFinal($sessions[0], $signature), CKR_SIGNATURE_LEN_RANGE, 'verifyCheck: C_VerifyFinal' );
    myis( $obj->C_DestroyObject($sessions[1], $privateKey), CKR_OK, 'verifyCheck: C_DestroyObject' );
    myis( $obj->C_DestroyObject($sessions[1], $publicKey), CKR_OK, 'verifyCheck: C_DestroyObject #2' );
    myis( $obj->C_Finalize, CKR_OK, 'verifyCheck: C_Finalize' );
}

sub encryptCheck {
    my ($obj) = @_;
    my @sessions = (CK_INVALID_HANDLE, CK_INVALID_HANDLE);
    my $modulusBits = pack(CK_ULONG_SIZE < 8 ? 'L' : 'Q', 768);
    my $publicExponent = pack('C*', 0x01, 0x00, 0x01);
    my $id = pack('C', 123);
    my $true = pack('C', CK_TRUE);
    my $false = pack('C', CK_FALSE);
    my $publicKey1 = CK_INVALID_HANDLE;
    my $privateKey1 = CK_INVALID_HANDLE;
    my $publicKey2 = CK_INVALID_HANDLE;
    my $privateKey2 = CK_INVALID_HANDLE;
    my $mechanism = {
        mechanism => CKM_RSA_PKCS_KEY_PAIR_GEN
    };
    my @publicKeyTemplate1 = (
        { type => CKA_ENCRYPT, pValue => $true },
        { type => CKA_VERIFY, pValue => $true },
        { type => CKA_WRAP, pValue => $true },
        { type => CKA_PUBLIC_EXPONENT, pValue => $publicExponent },
        { type => CKA_TOKEN, pValue => $true },
        { type => CKA_MODULUS_BITS, pValue => $modulusBits }
    );
    my @publicKeyTemplate2 = (
        { type => CKA_ENCRYPT, pValue => $false },
        { type => CKA_VERIFY, pValue => $true },
        { type => CKA_WRAP, pValue => $true },
        { type => CKA_PUBLIC_EXPONENT, pValue => $publicExponent },
        { type => CKA_TOKEN, pValue => $true },
        { type => CKA_MODULUS_BITS, pValue => $modulusBits }
    );
    my @privateKeyTemplate = (
        { type => CKA_PRIVATE, pValue => $true },
        { type => CKA_ID, pValue => $id },
        { type => CKA_SENSITIVE, pValue => $true },
        { type => CKA_DECRYPT, pValue => $true },
        { type => CKA_SIGN, pValue => $true },
        { type => CKA_UNWRAP, pValue => $true },
        { type => CKA_TOKEN, pValue => $true }
    );
    my $data = 'Text';
    my $encrypted;

    myis2( $obj->C_EncryptInit(CK_INVALID_HANDLE, $mechanism, $publicKey1), CKR_CRYPTOKI_NOT_INITIALIZED, CKR_SESSION_HANDLE_INVALID, 'encryptCheck: C_VerifyInit uninitialized' );
    myis2( $obj->C_Encrypt(CK_INVALID_HANDLE, $data, $encrypted), CKR_CRYPTOKI_NOT_INITIALIZED, CKR_SESSION_HANDLE_INVALID, 'encryptCheck: C_VerifyInit uninitialized' );

    myis( $obj->C_Initialize({}), CKR_OK, 'encryptCheck: C_Initialize' );
    myis( $obj->C_OpenSession($slotWithToken, CKF_SERIAL_SESSION, undef, $sessions[0]), CKR_OK, 'encryptCheck: C_OpenSession #0' );
    myis( $obj->C_OpenSession($slotWithToken, CKF_SERIAL_SESSION | CKF_RW_SESSION, undef, $sessions[1]), CKR_OK, 'encryptCheck: C_OpenSession #1' );
    myis( $obj->C_Login($sessions[1], CKU_USER, "1234"), CKR_OK, 'encryptCheck: C_Login' );
    myis( $obj->C_GenerateKeyPair($sessions[1], $mechanism, \@publicKeyTemplate1, \@privateKeyTemplate, $publicKey1, $privateKey1), CKR_OK, 'encryptCheck: C_GenerateKeyPair' );
    myis( $obj->C_GenerateKeyPair($sessions[1], $mechanism, \@publicKeyTemplate2, \@privateKeyTemplate, $publicKey2, $privateKey2), CKR_OK, 'encryptCheck: C_GenerateKeyPair #2' );
    $mechanism->{mechanism} = CKM_VENDOR_DEFINED;
    if ($VENDOR ne 'softhsm2') {
        myis( $obj->C_Logout($sessions[1]), CKR_OK, 'encryptCheck: C_Logout' );
        myis( $obj->C_EncryptInit(CK_INVALID_HANDLE, $mechanism, CK_INVALID_HANDLE), CKR_SESSION_HANDLE_INVALID, 'encryptCheck: C_EncryptInit invalid handle' );
        myis( $obj->C_EncryptInit($sessions[0], $mechanism, CK_INVALID_HANDLE), CKR_KEY_HANDLE_INVALID, 'encryptCheck: C_EncryptInit invalid handle #2' );
        myis( $obj->C_EncryptInit($sessions[0], $mechanism, $publicKey1), CKR_KEY_HANDLE_INVALID, 'encryptCheck: C_EncryptInit invalid handle #3' );
        myis( $obj->C_Login($sessions[1], CKU_USER, "1234"), CKR_OK, 'encryptCheck: C_Login #2' );
    }
    myis2( $obj->C_EncryptInit($sessions[0], $mechanism, $privateKey1), CKR_KEY_TYPE_INCONSISTENT, CKR_KEY_FUNCTION_NOT_PERMITTED, 'encryptCheck: C_EncryptInit' );
    myis( $obj->C_EncryptInit($sessions[0], $mechanism, $publicKey2), CKR_KEY_FUNCTION_NOT_PERMITTED, 'encryptCheck: C_EncryptInit #2' );
    myis( $obj->C_EncryptInit($sessions[0], $mechanism, $publicKey1), CKR_MECHANISM_INVALID, 'encryptCheck: C_EncryptInit #3' );
    $mechanism->{mechanism} = CKM_RSA_PKCS;
    myis( $obj->C_EncryptInit($sessions[0], $mechanism, $publicKey1), CKR_OK, 'encryptCheck: C_EncryptInit #4' );
    myis( $obj->C_EncryptInit($sessions[0], $mechanism, $publicKey1), CKR_OPERATION_ACTIVE, 'encryptCheck: C_EncryptInit #5' );
    myis( $obj->C_Encrypt(CK_INVALID_HANDLE, $data, $encrypted), CKR_SESSION_HANDLE_INVALID, 'encryptCheck: C_Encrypt invalid handle' );
    myis( $obj->C_Encrypt($sessions[1], $data, $encrypted), CKR_OPERATION_NOT_INITIALIZED, 'encryptCheck: C_Encrypt op not init' );
    myis( $obj->C_Encrypt($sessions[0], $data, $encrypted), CKR_OK, 'encryptCheck: C_Encrypt' );
    myis( $obj->C_Encrypt($sessions[0], $data, $encrypted), CKR_OPERATION_NOT_INITIALIZED, 'encryptCheck: C_Encrypt #2' );
    myisnt( $encrypted, undef, 'encryptCheck: C_Encrypt not undef' );
    myisnt( $encrypted, '', 'encryptCheck: C_Encrypt not empty string' );
    myis( $obj->C_DestroyObject($sessions[1], $privateKey1), CKR_OK, 'encryptCheck: C_DestroyObject' );
    myis( $obj->C_DestroyObject($sessions[1], $publicKey1), CKR_OK, 'encryptCheck: C_DestroyObject #2' );
    myis( $obj->C_DestroyObject($sessions[1], $privateKey2), CKR_OK, 'encryptCheck: C_DestroyObject #3' );
    myis( $obj->C_DestroyObject($sessions[1], $publicKey2), CKR_OK, 'encryptCheck: C_DestroyObject #4' );
    myis( $obj->C_Finalize, CKR_OK, 'encryptCheck: C_Finalize' );
}

sub decryptCheck {
    my ($obj) = @_;
    my @sessions = (CK_INVALID_HANDLE, CK_INVALID_HANDLE);
    my $modulusBits = pack(CK_ULONG_SIZE < 8 ? 'L' : 'Q', 768);
    my $publicExponent = pack('C*', 0x01, 0x00, 0x01);
    my $id = pack('C', 123);
    my $true = pack('C', CK_TRUE);
    my $false = pack('C', CK_FALSE);
    my $publicKey1 = CK_INVALID_HANDLE;
    my $privateKey1 = CK_INVALID_HANDLE;
    my $publicKey2 = CK_INVALID_HANDLE;
    my $privateKey2 = CK_INVALID_HANDLE;
    my $mechanism = {
        mechanism => CKM_RSA_PKCS_KEY_PAIR_GEN
    };
    my @publicKeyTemplate = (
        { type => CKA_ENCRYPT, pValue => $true },
        { type => CKA_VERIFY, pValue => $true },
        { type => CKA_WRAP, pValue => $true },
        { type => CKA_PUBLIC_EXPONENT, pValue => $publicExponent },
        { type => CKA_TOKEN, pValue => $true },
        { type => CKA_MODULUS_BITS, pValue => $modulusBits }
    );
    my @privateKeyTemplate1 = (
        { type => CKA_PRIVATE, pValue => $true },
        { type => CKA_ID, pValue => $id },
        { type => CKA_SENSITIVE, pValue => $true },
        { type => CKA_DECRYPT, pValue => $true },
        { type => CKA_SIGN, pValue => $true },
        { type => CKA_UNWRAP, pValue => $true },
        { type => CKA_TOKEN, pValue => $true }
    );
    my @privateKeyTemplate2 = (
        { type => CKA_PRIVATE, pValue => $true },
        { type => CKA_ID, pValue => $id },
        { type => CKA_SENSITIVE, pValue => $true },
        { type => CKA_DECRYPT, pValue => $false },
        { type => CKA_SIGN, pValue => $true },
        { type => CKA_UNWRAP, pValue => $true },
        { type => CKA_TOKEN, pValue => $true }
    );
    my $data = 'Text';
    my $encrypted;
    my $decrypted;

    myis2( $obj->C_DecryptInit(CK_INVALID_HANDLE, $mechanism, $privateKey1), CKR_CRYPTOKI_NOT_INITIALIZED, CKR_SESSION_HANDLE_INVALID, 'decryptCheck: C_VerifyInit uninitialized' );
    myis2( $obj->C_Decrypt(CK_INVALID_HANDLE, $data, $encrypted), CKR_CRYPTOKI_NOT_INITIALIZED, CKR_SESSION_HANDLE_INVALID, 'decryptCheck: C_VerifyInit uninitialized' );

    myis( $obj->C_Initialize({}), CKR_OK, 'decryptCheck: C_Initialize' );
    myis( $obj->C_OpenSession($slotWithToken, CKF_SERIAL_SESSION, undef, $sessions[0]), CKR_OK, 'decryptCheck: C_OpenSession #0' );
    myis( $obj->C_OpenSession($slotWithToken, CKF_SERIAL_SESSION | CKF_RW_SESSION, undef, $sessions[1]), CKR_OK, 'decryptCheck: C_OpenSession #1' );
    myis( $obj->C_Login($sessions[1], CKU_USER, "1234"), CKR_OK, 'decryptCheck: C_Login' );
    myis( $obj->C_GenerateKeyPair($sessions[1], $mechanism, \@publicKeyTemplate, \@privateKeyTemplate1, $publicKey1, $privateKey1), CKR_OK, 'decryptCheck: C_GenerateKeyPair' );
    myis( $obj->C_GenerateKeyPair($sessions[1], $mechanism, \@publicKeyTemplate, \@privateKeyTemplate2, $publicKey2, $privateKey2), CKR_OK, 'decryptCheck: C_GenerateKeyPair #2' );
    $mechanism->{mechanism} = CKM_VENDOR_DEFINED;
    if ($VENDOR ne 'softhsm2') {
        myis( $obj->C_Logout($sessions[1]), CKR_OK, 'decryptCheck: C_Logout' );
        myis( $obj->C_DecryptInit(CK_INVALID_HANDLE, $mechanism, CK_INVALID_HANDLE), CKR_SESSION_HANDLE_INVALID, 'decryptCheck: C_DecryptInit invalid handle' );
        myis( $obj->C_DecryptInit($sessions[0], $mechanism, CK_INVALID_HANDLE), CKR_KEY_HANDLE_INVALID, 'decryptCheck: C_DecryptInit invalid handle #2' );
        myis( $obj->C_DecryptInit($sessions[0], $mechanism, $privateKey1), CKR_KEY_HANDLE_INVALID, 'decryptCheck: C_DecryptInit invalid handle #3' );
        myis( $obj->C_Login($sessions[1], CKU_USER, "1234"), CKR_OK, 'decryptCheck: C_Login #2' );
    }
    if ($VENDOR eq 'softhsm2') {
        $mechanism->{mechanism} = CKM_RSA_PKCS;
        myis( $obj->C_EncryptInit($sessions[0], $mechanism, $publicKey1), CKR_OK, 'decryptCheck: C_EncryptInit' );
        myis( $obj->C_Encrypt($sessions[0], $data, $encrypted), CKR_OK, 'decryptCheck: C_Encrypt' );
        myisnt( $encrypted, undef, 'decryptCheck: C_Encrypt not undef' );
        myisnt( $encrypted, '', 'decryptCheck: C_Encrypt not empty string' );
        $mechanism->{mechanism} = CKM_VENDOR_DEFINED;
    }
    myis2( $obj->C_DecryptInit($sessions[0], $mechanism, $publicKey1), CKR_KEY_TYPE_INCONSISTENT, CKR_KEY_FUNCTION_NOT_PERMITTED, 'decryptCheck: C_DecryptInit' );
    myis( $obj->C_DecryptInit($sessions[0], $mechanism, $privateKey2), CKR_KEY_FUNCTION_NOT_PERMITTED, 'decryptCheck: C_DecryptInit #2' );
    myis( $obj->C_DecryptInit($sessions[0], $mechanism, $privateKey1), CKR_MECHANISM_INVALID, 'decryptCheck: C_DecryptInit #3' );
    $mechanism->{mechanism} = CKM_RSA_PKCS;
    myis( $obj->C_DecryptInit($sessions[0], $mechanism, $privateKey1), CKR_OK, 'decryptCheck: C_DecryptInit #4' );
    myis( $obj->C_DecryptInit($sessions[0], $mechanism, $privateKey1), CKR_OPERATION_ACTIVE, 'decryptCheck: C_DecryptInit #5' );
    if ($VENDOR ne 'softhsm2') {
        myis( $obj->C_EncryptInit($sessions[0], $mechanism, $publicKey1), CKR_OK, 'decryptCheck: C_EncryptInit' );
        myis( $obj->C_Encrypt($sessions[0], $data, $encrypted), CKR_OK, 'decryptCheck: C_Encrypt' );
        myisnt( $encrypted, undef, 'decryptCheck: C_Encrypt not undef' );
        myisnt( $encrypted, '', 'decryptCheck: C_Encrypt not empty string' );
    }
    myis( $obj->C_Decrypt(CK_INVALID_HANDLE, $encrypted, $decrypted), CKR_SESSION_HANDLE_INVALID, 'decryptCheck: C_Decrypt invalid handle' );
    myis( $obj->C_Decrypt($sessions[1], $encrypted, $decrypted), CKR_OPERATION_NOT_INITIALIZED, 'decryptCheck: C_Decrypt op not init' );
    myis( $obj->C_Decrypt($sessions[0], $encrypted, $decrypted), CKR_OK, 'decryptCheck: C_Decrypt' );
    myis( $obj->C_Decrypt($sessions[0], $encrypted, $decrypted), CKR_OPERATION_NOT_INITIALIZED, 'decryptCheck: C_Decrypt #2' );
    myisnt( $decrypted, undef, 'decryptCheck: C_Decrypt not undef' );
    myisnt( $decrypted, '', 'decryptCheck: C_Decrypt not empty string' );
    myis( $obj->C_EncryptInit($sessions[0], $mechanism, $publicKey2), CKR_OK, 'decryptCheck: C_EncryptInit #2' );
    $encrypted = undef;
    myis( $obj->C_Encrypt($sessions[0], $data, $encrypted), CKR_OK, 'decryptCheck: C_Encrypt #2' );
    myisnt( $encrypted, undef, 'decryptCheck: C_Encrypt not undef #2' );
    myisnt( $encrypted, '', 'decryptCheck: C_Encrypt not empty string #2' );
    myis( $obj->C_DecryptInit($sessions[0], $mechanism, $privateKey1), CKR_OK, 'decryptCheck: C_DecryptInit #6' );
    $decrypted = undef;
    myis2( $obj->C_Decrypt($sessions[0], $encrypted, $decrypted), CKR_ENCRYPTED_DATA_INVALID, CKR_GENERAL_ERROR, 'decryptCheck: C_Decrypt #3' );
    myis( $obj->C_DestroyObject($sessions[1], $privateKey1), CKR_OK, 'decryptCheck: C_DestroyObject' );
    myis( $obj->C_DestroyObject($sessions[1], $publicKey1), CKR_OK, 'decryptCheck: C_DestroyObject #2' );
    myis( $obj->C_DestroyObject($sessions[1], $privateKey2), CKR_OK, 'decryptCheck: C_DestroyObject #3' );
    myis( $obj->C_DestroyObject($sessions[1], $publicKey2), CKR_OK, 'decryptCheck: C_DestroyObject #4' );
    myis( $obj->C_Finalize, CKR_OK, 'decryptCheck: C_Finalize' );
}

sub signVerifyCheck {
    my ($obj) = @_;
    my @sessions = (CK_INVALID_HANDLE);
    my $modulusBits = pack(CK_ULONG_SIZE < 8 ? 'L' : 'Q', 768);
    my $publicExponent = pack('C*', 0x01, 0x00, 0x01);
    my $id = pack('C', 123);
    my $true = pack('C', CK_TRUE);
    my $false = pack('C', CK_FALSE);
    my $publicKey = CK_INVALID_HANDLE;
    my $privateKey = CK_INVALID_HANDLE;
    my $mechanism = {
        mechanism => CKM_RSA_PKCS_KEY_PAIR_GEN
    };
    my @publicKeyTemplate = (
        { type => CKA_ENCRYPT, pValue => $true },
        { type => CKA_VERIFY, pValue => $true },
        { type => CKA_WRAP, pValue => $true },
        { type => CKA_PUBLIC_EXPONENT, pValue => $publicExponent },
        { type => CKA_TOKEN, pValue => $true },
        { type => CKA_MODULUS_BITS, pValue => $modulusBits }
    );
    my @privateKeyTemplate = (
        { type => CKA_PRIVATE, pValue => $true },
        { type => CKA_ID, pValue => $id },
        { type => CKA_SENSITIVE, pValue => $true },
        { type => CKA_DECRYPT, pValue => $true },
        { type => CKA_SIGN, pValue => $true },
        { type => CKA_UNWRAP, pValue => $true },
        { type => CKA_TOKEN, pValue => $true }
    );
    my $data = 'Text';
    my $signature;

    myis( $obj->C_Initialize({}), CKR_OK, 'signVerifyCheck: C_Initialize' );
    myis( $obj->C_OpenSession($slotWithToken, CKF_SERIAL_SESSION | CKF_RW_SESSION, undef, $sessions[0]), CKR_OK, 'signVerifyCheck: C_OpenSession #1' );
    myis( $obj->C_Login($sessions[0], CKU_USER, "1234"), CKR_OK, 'signVerifyCheck: C_Login' );
    myis( $obj->C_GenerateKeyPair($sessions[0], $mechanism, \@publicKeyTemplate, \@privateKeyTemplate, $publicKey, $privateKey), CKR_OK, 'signVerifyCheck: C_GenerateKeyPair' );
    foreach (values %MECHANISM_SIGNVERIFY) {
        myis( $obj->C_SignInit($sessions[0], $_, $privateKey), CKR_OK, 'signVerifyCheck: C_SignInit mech '.($MECHANISM_INFO{$_->{mechanism}} ? $MECHANISM_INFO{$_->{mechanism}}->[1] : $_->{mechanism}) );
        $signature = undef;
        myis( $obj->C_Sign($sessions[0], $data, $signature), CKR_OK, 'signVerifyCheck: C_Sign mech '.($MECHANISM_INFO{$_->{mechanism}} ? $MECHANISM_INFO{$_->{mechanism}}->[1] : $_->{mechanism}) );
        myis( $obj->C_VerifyInit($sessions[0], $_, $publicKey), CKR_OK, 'signVerifyCheck: C_VerifyInit mech '.($MECHANISM_INFO{$_->{mechanism}} ? $MECHANISM_INFO{$_->{mechanism}}->[1] : $_->{mechanism}) );
        myis( $obj->C_Verify($sessions[0], $data, $signature), CKR_OK, 'signVerifyCheck: C_Verify mech '.($MECHANISM_INFO{$_->{mechanism}} ? $MECHANISM_INFO{$_->{mechanism}}->[1] : $_->{mechanism}) );
    }
    myis( $obj->C_DestroyObject($sessions[0], $privateKey), CKR_OK, 'signVerifyCheck: C_DestroyObject' );
    myis( $obj->C_DestroyObject($sessions[0], $publicKey), CKR_OK, 'signVerifyCheck: C_DestroyObject #2' );
    myis( $obj->C_Finalize, CKR_OK, 'signVerifyCheck: C_Finalize' );
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
    my $ulongx3 = CK_ULONG_SIZE < 8 ? 'L'x3 : 'Q'x3;

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
        my $obj = Crypt::PKCS11::XS->new;
        myisa_ok( $obj, 'Crypt::PKCS11::XSPtr' );

        $slotWithToken = 1;
        $slotWithNoToken = 0;
        $slotWithNotInitToken = 2;
        $slotInvalid = 9999;
        %MECHANISM_INFO = (
            CKM_RSA_PKCS_KEY_PAIR_GEN => [ CKM_RSA_PKCS_KEY_PAIR_GEN, 'CKM_RSA_PKCS_KEY_PAIR_GEN' ],
            CKM_RSA_PKCS => [ CKM_RSA_PKCS, 'CKM_RSA_PKCS' ],
            CKM_MD5 => [ CKM_MD5, 'CKM_MD5' ],
            CKM_RIPEMD160 => [ CKM_RIPEMD160, 'CKM_RIPEMD160' ],
            CKM_SHA_1 => [ CKM_SHA_1, 'CKM_SHA_1' ],
            CKM_SHA256 => [ CKM_SHA256, 'CKM_SHA256' ],
            CKM_SHA384 => [ CKM_SHA384, 'CKM_SHA384' ],
            CKM_SHA512 => [ CKM_SHA512, 'CKM_SHA512' ],
            CKM_MD5_RSA_PKCS => [ CKM_MD5_RSA_PKCS, 'CKM_MD5_RSA_PKCS' ],
            CKM_RIPEMD160_RSA_PKCS => [ CKM_RIPEMD160_RSA_PKCS, 'CKM_RIPEMD160_RSA_PKCS' ],
            CKM_SHA1_RSA_PKCS => [ CKM_SHA1_RSA_PKCS, 'CKM_SHA1_RSA_PKCS' ],
            CKM_SHA256_RSA_PKCS => [ CKM_SHA256_RSA_PKCS, 'CKM_SHA256_RSA_PKCS' ],
            CKM_SHA384_RSA_PKCS => [ CKM_SHA384_RSA_PKCS, 'CKM_SHA384_RSA_PKCS' ],
            CKM_SHA512_RSA_PKCS => [ CKM_SHA512_RSA_PKCS, 'CKM_SHA512_RSA_PKCS' ]
        );
        %MECHANISM_SIGNVERIFY = (
            CKM_RSA_PKCS => { mechanism => CKM_RSA_PKCS },
            CKM_RSA_X_509 => { mechanism => CKM_RSA_X_509 },
            CKM_MD5_RSA_PKCS => { mechanism => CKM_MD5_RSA_PKCS },
            CKM_RIPEMD160_RSA_PKCS => { mechanism => CKM_RIPEMD160_RSA_PKCS },
            CKM_SHA1_RSA_PKCS => { mechanism => CKM_SHA1_RSA_PKCS },
            CKM_SHA256_RSA_PKCS => { mechanism => CKM_SHA256_RSA_PKCS },
            CKM_SHA384_RSA_PKCS => { mechanism => CKM_SHA384_RSA_PKCS },
            CKM_SHA512_RSA_PKCS => { mechanism => CKM_SHA512_RSA_PKCS },
            CKM_SHA1_RSA_PKCS_PSS => { mechanism => CKM_SHA1_RSA_PKCS_PSS, pParameter => pack($ulongx3, CKM_SHA_1, CKG_MGF1_SHA1, 20) },
            CKM_SHA256_RSA_PKCS_PSS => { mechanism => CKM_SHA256_RSA_PKCS_PSS, pParameter => pack($ulongx3, CKM_SHA256, CKG_MGF1_SHA256, 0) },
            CKM_SHA384_RSA_PKCS_PSS => { mechanism => CKM_SHA384_RSA_PKCS_PSS, pParameter => pack($ulongx3, CKM_SHA384, CKG_MGF1_SHA384, 0) },
            CKM_SHA512_RSA_PKCS_PSS => { mechanism => CKM_SHA512_RSA_PKCS_PSS, pParameter => pack($ulongx3, CKM_SHA512, CKG_MGF1_SHA512, 0) }
        );
        $VENDOR = '';
        %SUPPORT = ();

        if ($so =~ /libsofthsm\.so$/o) {
            $ENV{SOFTHSM_CONF} = 'softhsm.conf';
            system('softhsm --slot 1 --init-token --label slot1 --so-pin 12345678 --pin 1234') == 0 || die;
        }
        elsif ($so =~ /libsofthsm2\.so$/o) {
            $ENV{SOFTHSM2_CONF} = 'softhsm2.conf';
            system('mkdir -p tokens') == 0 || die;
            system('softhsm2-util --slot 0 --init-token --label slot0 --so-pin 12345678 --pin 1234') == 0 || die;
            system('softhsm2-util --slot 1 --init-token --label slot1 --so-pin 12345678 --pin 1234') == 0 || die;

            $slotWithToken = 0;
            $slotWithNoToken = 1;
            delete $MECHANISM_INFO{CKM_RIPEMD160};
            delete $MECHANISM_INFO{CKM_RIPEMD160_RSA_PKCS};
            delete $MECHANISM_SIGNVERIFY{CKM_RIPEMD160_RSA_PKCS};
            $VENDOR = 'softhsm2';
            $SUPPORT{C_CopyObject} = 1;
        }

        myis( $obj->load($so), Crypt::PKCS11::CKR_OK );

        initCheck($obj);
        infoCheck($obj);
        sessionCheck($obj);
        userCheck($obj);
        randomCheck($obj);
        generateCheck($obj);
        objectCheck($obj);
        digestCheck($obj);
        signCheck($obj);
        verifyCheck($obj);
        encryptCheck($obj);
        decryptCheck($obj);
        signVerifyCheck($obj);

#        foreach (@$a) {
#            myis( $obj->C_InitToken($_, "12345678", "ѪѫѬѪѫѬ"), Crypt::PKCS11::CKR_OK );

            # TODO: C_InitPIN
            # TODO: C_SetPIN
            # Supported by SoftHSMv2:
            # TODO: C_GetObjectSize
            # TODO: C_DigestKey
            # TODO: C_GenerateKey
            # TODO: C_WrapKey
            # TODO: C_UnwrapKey
            # TODO: C_DeriveKey

            # TODO: C_GetOperationState
            # TODO: C_SetOperationState
            # TODO: C_EncryptUpdate
            # TODO: C_EncryptFinal
            # TODO: C_DecryptUpdate
            # TODO: C_DecryptFinal
            # TODO: C_SignRecoverInit
            # TODO: C_SignRecover
            # TODO: C_VerifyRecoverInit
            # TODO: C_VerifyRecover
            # TODO: C_DigestEncryptUpdate
            # TODO: C_DecryptDigestUpdate
            # TODO: C_SignEncryptUpdate
            # TODO: C_DecryptVerifyUpdate
            # TODO: C_GetFunctionStatus
            # TODO: C_CancelFunction
            # TODO: C_WaitForSlotEvent
#        }

        myis( $obj->unload, Crypt::PKCS11::CKR_OK );
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
