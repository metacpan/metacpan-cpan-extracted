#!/usr/bin/perl
use strict;
use warnings;
use Test::More 'no_plan';

use FindBin '$Bin';
use lib "$Bin/../lib";
use_ok "Crypt::Password";
$Crypt::Password::TESTMODE = 1;

sub mock { bless {@_}, "Crypt::Password" };

no warnings 'once', 'redefine';
my $flav = $Crypt::Password::crypt_flav;
diag "testing Crypt::Password (crypt_flav='$flav')";
diag "os is '$^O'";
unless ($flav eq "windows") {
    my $line = (`man crypt`)[-1];
    $line =~ s/\s+/ /g;
    diag "bottom line of man crypt: '$line'";
}

diag "generate salt"; {
    my %uniq = map { mock()->salt() => undef } 1..20;
    is scalar(keys %uniq), 20, "random salts generated";
    my %uniq2 = map { password("hello") => undef } 1..20;
    is scalar(keys %uniq2), 20, "randomly salted hashes";
}

if ($flav eq "windows") {
    password("wintest", "_testtest");
    password("wintest", "_testbluh");
    password("wintest", "_aestbluh");
    password("wintest", "_aestblu");
    password("wintest", "_aestblu");
    password("wintest", "_aestbla");
    password('wintest', '$$');
    password('wintest', '$a');
    password('wintest', '$aetc');
    password('wintest', ',hello');
}

my $special;
$special->{extended} = sub {
    diag "extended special";
    is(password('$_blahblah$2ZtvPvnOO/w'), '$_blahblah$2ZtvPvnOO/w', "crypted string embodied");
    is(password("007", "blahblah"), '$_blahblah$2ZtvPvnOO/w', "crypts") for 1..3;
    is(password("007", "BLAHblah"), '$_BLAHblah$Y8YHRJXwFLE', "crypts with different salt") for 1..3;
    is(password("123", "_12341234"), '$_12341234$zPVAQUxtWss', "salt can start with _") for 1..2;
    is(password("a", "cc"), '$cc$IxmriBVsviU', "two character salt") for 1..3;
    ok(check_password('$_DADAdada$LASg2sXIXlI', "hello0"), "check_password");
    ok(!check_password('$_DADAdada$LASg2sXIXlI', "hello1"), "check_password incorrect");
    ok(!check_password('$_zzzzzzzz$LASg2sXIXlI', "hello0"), "check_password incorrect");
    
    if ($flav ne "windows") {
        diag "remake some known crypts";
        my @answers = map {[ split /\s+/, $_ ]} split /\n/, <<'ANSWERS';
ambiente $_12345555$V4oENXvTMYk $gi$CZewZaJV4pk
lampshade $_12345555$JacsOKd1xTo $gi$zi7R25ah3Zw
guitar $_12345555$2yFp.wqJEF. $gi$4tl8fx6Anh.
ANSWERS

        for my $row (@answers) {
            is(password($row->[0], "12345555"), $row->[1], "test $row->[0] salt=8");
            is(password($row->[0], "gi"), $row->[2], "test $row->[0] salt=2");
        }


        diag "various salt inputs";
        # all invalid
        for my $salt ("dgdb", "a", "123456", "1234567", "123456789") {
            eval { password("hello0", $salt) };
            like $@, qr/Bad salt input.+2 or 8 characters/, "wrong sized salt";
            $@ = "";
        }
        for my $salt ("_a", "_bb") {
            eval { password("hello0", "_a") };
            like $@, qr/Bad salt input.+2-character salt cannot start with _/,
                "can't start with _";
            $@ = "";
        }
        my $p;
        eval { $p = password('a', 'bbbbbbbb') };
        is $@, "", "salt=8 no error";
        is $p, '$_bbbbbbbb$DJEHexiq9NI', "salt=8 crypt";
        $@ = "";
    }
};
$special->{modular} = sub {
    diag "modular special";
    my $c = password("hello0");
    like $c, qr/^\$5\$(........)\$[a-zA-Z0-9\.\/]{43}$/, "crypted";
    my $c2 = password("hello0");
    like $c2, qr/^\$5\$(........)\$[a-zA-Z0-9\.\/]{43}$/, "another crypted";
    isnt $c, $c2, "generated different salts";
    $DB::single = 1;
    ok(check_password($c, "hello0"), "check passed");
    ok(check_password($c2, "hello0"), "check passed");
    ok(!check_password($c, "helu"), "check failed");

    diag "modular special argumentative";
    my $c3 = password("password", "salt");
    like $c3, qr/^\$5\$salt\$.{43}$/, "Default algorithm, supplied salt";
    my $c4 = password("password", "", "md5");
    like $c4, qr/^\$1\$\$.{22}$/, "md5, no salt";
    my $c5 = password("password", undef, "sha512");
    like $c5, qr/^\$6\$(.{8})\$.{86}$/, "sha512, invented salt";
    
    diag "modular special embodiment";
    my $password = '$5$%RK2BU%L$aFZd1/4Gpko/sJZ8Oh.ZHg9UvxCjkH1YYoLZI6tw7K8';
    is $password, password($password), "password embodied by password()";
    isnt $password, crypt_password($password), "force recrypted by crypt_password()";
};

diag "random salts"; {
    isnt(password("hello"), password("hello"), "different");
}

diag "set salts"; {
    is(password("hello", "1234abcd"), password("hello", "1234abcd"), "salt set - same");
};

diag "pass crypted as salt"; {
    my $h = password("etcetc");
    isnt($h, password("etcetc"), "hash made unique by generated salt");
    is($h, password("etcetc", $h), "hash passed as salt, regenerates the same hash");
}

diag "cant just pass crypted stuff into check_password"; {
    my $h = password('etcetc', 'blahblah');
    isnt(check_password($h, $h), "faile");
}

if ($flav eq "windows") {
    my $p;
    eval { $p = password('a', 'cc') };
    is $@, "", "salt=2 no error";
    is $p, '$cc$DFDkLhMbQ7wZ.', "salt=2 crypt";
    $@ = "";
}
elsif ($flav eq "glib" || $flav eq "freebsd") {
    $special->{modular}->();

    experiment("freesec", "extended");
}
else {
    $special->{extended}->();

    experiment("glib", "modular");
}

sub experiment {
    my ($flav, $other) = @_;
    diag "experimenting in $other with $flav...";
    no warnings;
    *isnt = sub { $_[0] ne $_[1] || diag "'$_[0]' ne '$_[1]' FAIL $_[2]" };
    *is =   sub { $_[0] eq $_[1] || diag "'$_[0]' eq '$_[1]' FAIL $_[2]" };
    *like = sub { $_[0] =~ /$_[1]/ || diag "'$_[0]' =~ '$_[1]' FAIL $_[2]" };
    *ok = sub { $_[0] || diag "ok FAIL $_[1]" };
    use warnings;

    local $Crypt::Password::crypt_flav = $flav;
    eval {
        $special->{$other}->();
    };
    diag "errors: $@" if $@;
}

