#!/usr/bin/perl
use strict;
use warnings;
use Test::More qw/no_plan/;

BEGIN {
    use_ok "Acme::Siteswap";
}

Simple_siteswaps: {
    my @simple = (
        # Regular patterns
        ( map { { valid => 1, pattern => $_, balls => $_ } } (0 .. 9) ),
        
        # 2-ball patterns
        ( map { { valid => 1, pattern => $_, balls => 2 } } qw(31 330) ),
        
        # 3-ball patterns
        ( map { { valid => 1, pattern => $_, balls => 3 } } 
            qw(441 63501 72330 423 64005 73131 504 64014 73302 531 64050 73401
            5511 64140 74130 51414 64500 74400 51234 66300 75300 52413 6050505
            713151 52440 6131451 71701701 52512 6161601 801 53034 6316131 8040
            53403 711 720 8130 55014 7131 84012 5505051 7401 84030 61251 70161
            8123601 61305 70251 9111 61314 70305 90141 61350 70314 90303 63051
            70350 90501 63141 70701 91401)
        ),

        # 4-ball patterns
        ( map { { valid => 1, pattern => $_, balls => 4 } } 
            qw( 53 6262525 75305 552 6461641 75314 534 6605155 75350 5551
            6615163 75620 55514 71 75701 55550 77231 615 714 77330 633 723
            751515 642 741 7261246 660 7045 7123456 6424 7063 7161616 6055
            7126 7427242 6235 7135 7471414 6415 7333 7272712 6451 7405
            74716151 6631 7441 831 61355 70166 80345 62345 70256 80525 62525
            70355 80723 62561 70364 81236 63353 70616 81416 63524 70625 81425
            63551 70661 81461 63623 70706 81812 64055 72335 83333 64145 72461
            84440 64163 73136 84512 64253 73406 85241 64505 73424 86420 64613
            72416 8441841481441 64514 72425 9151 66125 73451 90506 61616 73631
            90551 66305 74135 91424 66314 74162 91901 66350 74234 92333 661515
            74405 94034 663504 74450 95141 6155155 74612 95501 6262525 74630
            96131 6461641 75161 6605155 75251 53633733383333933333)
        ),

        # 5-ball patterns
        ( map { { valid => 1, pattern => $_, balls => 5 } } 
            qw( 64 8273 933 645 81277 942 663 81727 90808 66661 81772 92527
            726 81817 92923 744 83446 94444 753 83833 94552 771 84445 94642
            7571 8448641 95191 7733 8446661 95551 7463 84733 95524 7562 84742
            96181 72466 8448551 96451 73636 8537741 96631 74734 85345 96901
            75616 85516 97531 75625 85561 94493344 75661 85525 9552952592552
            75751 86416 77416 86425 77425 86461 77461 86731 77731 88441 825
            824466 861 85716814 8633 91 8246 915 780)
        ),
        { valid => 0, pattern => '4', balls => 3,
            reason => qr/does not equal # of balls/ },
        { valid => 0, pattern => '243', balls => 3,
            reason => qr/land at the same time/ },
        { valid => 0, pattern => '870', balls => 5,
			reason => qr/land at the same time/ },
    );

    test_siteswaps(\@simple);
}

Multiplex_siteswaps: {
    my @multiplexes = (
        ( map { { valid => 1, pattern => $_, balls => 4 } }
            qw([43]14 [64]1324 [53]22 [64]2323 [54]21 
               [64]4123 [65]01 [65]3123 [43]5323 [74]2421)
        ),
		{ valid => 1, pattern => '[33]', balls => 6 },
        { valid => 0, pattern => '[42]15', balls => 4,
            reason => qr/land at the same time/ },
    );
    test_siteswaps(\@multiplexes);
}


sub test_siteswaps {
    my $patterns = shift;
    for my $test (@$patterns) {
        my $siteswap = Acme::Siteswap->new(
            pattern => $test->{pattern},
            balls => $test->{balls},
        );
        if ($test->{valid}) {
            ok $siteswap->valid, "'$test->{pattern}' is valid";
            if (!$siteswap->valid) {
                diag $siteswap->error;
            }
        }
        else {
            ok !$siteswap->valid, "'$test->{pattern}' is invalid";
            like $siteswap->error, $test->{reason}, 'reason is correct';
        }
    }
}
