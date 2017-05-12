#!/usr/bin/perl

use strict;
use Test::Simple tests => 5;

use Cisco::Management;
ok(1, "Loading Module"); # If we made it this far, we're ok.

#########################

my @encryptions = qw(
                     00071A150754
                     01100F175804
                     02050D480809
                     030752180500
                     045802150C2E
                     05080F1C2243
                     060506324F41
                     070C285F4D06
                     0822455D0A16
                     094F471A1A0A
                     104D000A0618
                     110A1016141D
                     121A0C041104
                     13061E010803
                     14141B180F0B
                     1511021F0725
                     160805172924
                     170F0D39282B
                     180723382727
                     192922372B3C
                     20282D3B303A
                     21272120362D
                     222B3A26211C
                     23303C311008
                     24362B000419
                     25211A14150C
                     26100E05000E
                     27041F100259
                     28150A125556
                     290008455A57
                     30025F4A5B5C
                     3155504B505B
                     325A51405701
                     335B5A470D0C
                     34505D1D0017
                     355707101B19
                     360D0A0B1556
                     370011055A57
                     381B1F4A5B58
                     3915504B545C
                     405A5144505D
                     415B5E40515A
                     42545A41565B
                     43505B465704
                     44515C470854
                     45565D185809
                     465702480508
                     470852150457
                     48580F145B58
                     49050E4B540B
                     50045144071C
                     515B5E171009
                     52540D00050B
                    );

sub decrypt_test {
    for (@encryptions) {
        if (my $passwd = Cisco::Management->password_decrypt($_)) {
            if ($passwd ne "cisco") {
                print "Error: password_decrypt($_) returned $passwd ne cisco\n";
                return 1
            }
        } else {
            printf "Error: %s\n", Cisco::Management->error;
            return 1
        }
    }
    return 0
}
ok(decrypt_test() == 0, "Decrypt Test");

sub encrypt_test {
    if (my $passwd = Cisco::Management->password_encrypt('cisco')) {
        for (0..$#{$passwd}) {
            if ($passwd->[$_] ne $encryptions[$_]) {
                printf "Error: password_encrypt('cisco') returned %s ne %s\n", $passwd->[$_], $encryptions[$_];
                return 1
            }
        }
        return 0
    } else {
        printf "Error: %s\n", Cisco::Management->error;
        return 1
    }
}
ok(encrypt_test() == 0, "Encrypt Test");

sub encrypt_test_arg {
    if (my $passwd = Cisco::Management->password_encrypt('cisco',5)) {
        for (0..$#{$passwd}) {
            if ($passwd->[$_] ne $encryptions[5]) {
                printf "Error: password_encrypt('cisco',5) returned %s ne %s\n", $passwd->[$_], $encryptions[5];
                return 1
            }
        }
        return 0
    } else {
        printf "Error: %s\n", Cisco::Management->error;
        return 1
    }
}
ok(encrypt_test_arg() == 0, "Encrypt Test with argument");

sub encrypt_test_random {
    if (my $passwd = Cisco::Management->password_encrypt('cisco','*')) {
        for (0..$#{$passwd}) {
            my $index = substr $passwd->[$_], 0, 2;
            if ($passwd->[$_] ne $encryptions[$index]) {
                printf "Error: password_encrypt('cisco','*') returned %s ne %s\n", $passwd->[$_], $encryptions[$index];
                return 1
            }
        }
        return 0
    } else {
        printf "Error: %s\n", Cisco::Management->error;
        return 1
    }
}
ok(encrypt_test_random() == 0, "Encrypt Test with random");
