#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

use Acme::Indigest::Crypt;

for (split m/\n/, <<'_END_' ) {
Xyzzy::10_000_000:$6$rounds=10000000$$vbg2CkLih12Hc7QAeDIzsv9p5aGr5QQO4KChuO7Xqkgo/kbNmJ4sG/QIFokzHdu.e8Fu6qqqE7LxVPsPwy/t61
Xyzzy:::$6$rounds=10000000$$vbg2CkLih12Hc7QAeDIzsv9p5aGr5QQO4KChuO7Xqkgo/kbNmJ4sG/QIFokzHdu.e8Fu6qqqE7LxVPsPwy/t61
Xyzzy:salt0::$6$rounds=10000000$salt0$bbPNeFPkDu/yMaLov8n8.qot6BDjMSIaPrVS9GdzTL8O3zH7XfAGAXBKisNBk3UwSJMPXbrg49GlYqn7FfHpw/
Xyzzy:salt0:10_000_000:$6$rounds=10000000$salt0$bbPNeFPkDu/yMaLov8n8.qot6BDjMSIaPrVS9GdzTL8O3zH7XfAGAXBKisNBk3UwSJMPXbrg49GlYqn7FfHpw/
Xyzzy:salt1:10_000_000:$6$rounds=10000000$salt1$3OK9/QOqkthvPkqc43CfU2Qyouip3r1yggVCsOHGaTE3uRWYKw40ZiJNFQrt2xNuZTb4u6oMGJNgF8wZQ2fZY.
Xyzzy:salt0:10_000_001:$6$rounds=10000001$salt0$5xNyTzFf1zCLBvcOm/Q/4Ar0hix8Yox5BW0rlGg7V.EcR6ZEGfuORK.jvgCsv.5lDWvdsrcCI/u536OcrHrn61
Xyzzy::10_000_100:$6$rounds=10000100$$0Y6k4t/gpWM8JKvzPXTVPKwm63hOeIdQ4mlG2RaRdYr.T4A4rSrTTB.3XhymhSzDAp6QqwF9X8TErafphUWqi0
Xyzzy::10_100_100:$6$rounds=10100100$$new0U2ntlEZPVUPLP3vD/PByGAVVnpnrJ2g9rs28rOmhNQgAah6k5yE/MUj44X5jlyPQ56FoJNIMVQp515vmI/
Xyzzy:salt0:10_100_100:$6$rounds=10100100$salt0$uaUll/x38DR2VZigveBmmuFbKG4ZBYfkt8x1r8pPSyTNQFsUv4/VJOUIgVUqRS5Xj2YlObxBUel.ILD6.zMm50
Alice:::$6$rounds=10000000$$9Ah5580mxlAGTrjHLMSWeoMmMsQwsGdBLzrjISOHj.t6Io6rXFGSzSnNfj6aB.T6JKDbV1sLSbWFeGfVx4jXf0
Bob:::$6$rounds=10000000$$DQXHtFd/jI0R.Bt3ZUiJ8.vOFeNwppdpzNOpBPYO/SkIKDncxwx210AXh/OOcGSMINcnfUfFmC4bYYkJ/DziD0
_END_
    next if m/^\s*#/;
    next unless my ( $passphrase, $salt_string, $rounds, $want ) = split ':', $_, 4;
    ( $salt_string, $rounds ) = Acme::Indigest::Crypt->parse_salt_string_rounds( $salt_string, $rounds );

    my $have = Acme::Indigest::Crypt->digest( $passphrase, $salt_string, $rounds );
    defined or $_ = '(undef)' for $salt_string;
    defined or $_ = '' for $rounds;
    is( $want, $have, "$passphrase => salt_string:$salt_string rounds:$rounds)" );
}

my ( $input, $output );

$input = <<_END_;
Alice:::Alice plaintext
Alice::10_000_000:Alice plaintext
Alice::10_000_001:Alice plaintext
Alice:salt0:10_000_000:Alice plaintext
Bob:::Bob plaintext
Bob:salt0::Bob plaintext
_END_

$output = <<'_END_';
Alice => $6$rounds=10000000$$AWyoBuupX7MljIsX/SsU7zAusbNnuYtPujTf/gIiaRs3W1EK3YoIUAVlBgBNq56MvuqNtzLnOMYb7KswXgRA4/
Alice => $6$rounds=10000000$$AWyoBuupX7MljIsX/SsU7zAusbNnuYtPujTf/gIiaRs3W1EK3YoIUAVlBgBNq56MvuqNtzLnOMYb7KswXgRA4/
Alice => $6$rounds=10000001$$VPta7ZWMZE3X6HHmBActRBG1hguVsK5tTSG4T8rDMJVG11CX9ZMS6nIozrV2fzPOhH.HCTvDXNKNFz8cxgIYr.
Alice => $6$rounds=10000000$salt0$z8DCDvpXBYwIDu5he92ooCLlLhwA487JelL4oyZqXKrJLMKeTc9KBoQYKPuNwuwj1Pl1wn6SSbsQs3sM0390k.
Bob => $6$rounds=10000000$$XNn8uzxqdIo4QmQgZlnoavTFgfewM0efeE38l4/lHTTSAfn0xeUUGQEXv95E/vaHoRoh93r4nKqKjMe.EfwfV.
Bob => $6$rounds=10000000$salt0$oflkK12WG1pMgBkVPOpMQe/7fXR0wjZ7D6anRfljrQPu.aba1xNPE2EkiYP80yScI05OjJjC.UAksw/hpFFLO/
_END_

is( Acme::Indigest::Crypt->digest_multiple( $input ), $output );

done_testing;
