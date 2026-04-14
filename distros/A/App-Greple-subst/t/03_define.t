use v5.14;
use warnings;
use Encode;
use utf8;

use Test::More;
use Data::Dumper;

use lib '.';
use t::Util;

# Basic DEFINE pattern
line(subst('--dictdata', <<'END', 't/JA-bad.txt')->run->{stdout}, 2, "DEFINE basic");
(?(DEFINE)(?<vo>[ヴブボ]ォ?))
イ[エー]ハトー?(?&vo)	イーハトーヴォ
END

# Multiple DEFINE patterns
line(subst('--dictdata', <<'END', 't/JA-bad.txt')->run->{stdout}, 3, "DEFINE multiple");
(?(DEFINE)(?<vo>[ヴブボ]ォ?))
(?(DEFINE)(?<pago>パーゴ))
イ[エー]ハトー?(?&vo)	イーハトーヴォ
デストゥ?(?&pago)	デストゥパーゴ
END

# DEFINE with --dict file (JA.dict uses DEFINE)
line(subst(qw(--dict t/JA.dict t/JA-bad.txt))
     ->run->{stdout}, 9, "DEFINE in dict file");

# Nested DEFINE patterns
line(subst('--dictdata', <<'END', 't/JA-bad.txt')->run->{stdout}, 2, "DEFINE nested");
(?(DEFINE)(?<vb>[ヴブボ]))
(?(DEFINE)(?<vo>(?&vb)ォ?))
イ[エー]ハトー?(?&vo)	イーハトーヴォ
END

# Undefined pattern error
{
    my $result = subst('--dictdata', <<'END', 't/JA-bad.txt')->run;
test(?&undefined)	TEST
END
    isnt($result->{result}, 0, "DEFINE undefined pattern exits with error");
    my $output = ($result->{stderr} // '') . ($result->{stdout} // '');
    like($output, qr/undefined pattern: undefined/,
	 "DEFINE undefined pattern error message");
}

done_testing;
