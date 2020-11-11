#!perl
use strict;
use warnings;

use Test::More;
use Data::Dumper;

use Crypt::Sodium::Nitrate;

sub lived_ok ($) { pass($_[0]) }

sub main {
    my $k = "K" x Crypt::Sodium::Nitrate::KEYBYTES();
    my $n = "N" x Crypt::Sodium::Nitrate::NONCEBYTES();
    my $v = "original value do not steal $$";
    my @args = ($v, $n, $k);

    subtest "encrypt" => sub {
        my $e = \&Crypt::Sodium::Nitrate::encrypt;
        my @encrypt;
        $encrypt[0] = Crypt::Sodium::Nitrate::encrypt($v, $n, $k);
        lived_ok("custom op");

        $encrypt[1] = &Crypt::Sodium::Nitrate::encrypt($v, $n, $k);
        lived_ok("xs func");

        $encrypt[2] = $e->($v, $n, $k);
        lived_ok("xs func via ref");

        $encrypt[3] = Crypt::Sodium::Nitrate::encrypt(@args);
        lived_ok("custom op with list args");

        $encrypt[4] = &Crypt::Sodium::Nitrate::encrypt(@args);
        lived_ok("xs func with list args");

        $encrypt[5] = $e->(@args);
        lived_ok("xs func via ref with list args");

        push @encrypt, Crypt::Sodium::Nitrate::encrypt($v, $n, $k);
        lived_ok("custom op list context");

        push @encrypt, &Crypt::Sodium::Nitrate::encrypt($v, $n, $k);
        lived_ok("xs func list context");

        push @encrypt, $e->($v, $n, $k);
        lived_ok("xs func via ref list context");

        push @encrypt, Crypt::Sodium::Nitrate::encrypt(@args);
        lived_ok("custom op list context list args");

        push @encrypt, &Crypt::Sodium::Nitrate::encrypt(@args);
        lived_ok("xs func list context list args");

        push @encrypt, $e->(@args);
        lived_ok("xs func via ref list context list args");

        my %seen; $seen{$_}++ for @encrypt;
        is(keys(%seen), 1, "all variations of encrypt give the same result")
            or diag(Dumper(\@encrypt));
    };

    $v = $args[0] = Crypt::Sodium::Nitrate::encrypt($v, $n, $k);
    subtest "decrypt" => sub {
        my $e = \&Crypt::Sodium::Nitrate::decrypt;
        my @decrypt;
        $decrypt[0] = Crypt::Sodium::Nitrate::decrypt($v, $n, $k);
        lived_ok("custom op");

        $decrypt[1] = &Crypt::Sodium::Nitrate::decrypt($v, $n, $k);
        lived_ok("xs func");

        $decrypt[2] = $e->($v, $n, $k);
        lived_ok("xs func via ref");

        $decrypt[3] = Crypt::Sodium::Nitrate::decrypt(@args);
        lived_ok("custom op with list args");

        $decrypt[4] = &Crypt::Sodium::Nitrate::decrypt(@args);
        lived_ok("xs func with list args");

        $decrypt[5] = $e->(@args);
        lived_ok("xs func via ref with list args");

        push @decrypt, Crypt::Sodium::Nitrate::decrypt($v, $n, $k);
        lived_ok("custom op list context");

        push @decrypt, &Crypt::Sodium::Nitrate::decrypt($v, $n, $k);
        lived_ok("xs func list context");

        push @decrypt, $e->($v, $n, $k);
        lived_ok("xs func via ref list context");

        push @decrypt, Crypt::Sodium::Nitrate::decrypt(@args);
        lived_ok("custom op list context list args");

        push @decrypt, &Crypt::Sodium::Nitrate::decrypt(@args);
        lived_ok("xs func list context list args");

        push @decrypt, $e->(@args);
        lived_ok("xs func via ref list context list args");

        my %seen; $seen{$_}++ for @decrypt;
        is(keys(%seen), 1, "all variations of decrypt give the same result")
            or diag(Dumper(\@decrypt));
    };
}

main();

done_testing;

