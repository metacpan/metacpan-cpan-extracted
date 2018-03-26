use Test::More tests => 56;

use DT;

my $dt = DT->new(time - 1);
my $ud = undef;

ok !defined($dt == undef), "== undef";
ok !defined($ud == $dt), "undef ==";
is $dt == time, !1, "==";
is time == $dt, !1, "reverse ==";

ok !defined($dt != undef), "!= undef";
ok !defined($ud != $dt), "undef !=";
is $dt != time, 1, "!=";
is time != $dt, 1, "reverse !=";

ok !defined($dt <=> undef), "<=> undef";
ok !defined($ud <=> $dt), "undef <=>";
is $dt <=> time, -1, "<=>";
is time <=> $dt, 1, "reverse <=>";

ok !defined($dt < undef), "< undef";
ok !defined($ud < $dt), "undef <";
is $dt < time, 1, "<";
is time < $dt, !1, "reverse <";

ok !defined($dt <= undef), "<= undef";
ok !defined($ud <= $dt), "undef <=";
is $dt <= time, 1, "<=";
is time <= $dt, !1, "reverse <=";

ok !defined($dt > undef), "> undef";
ok !defined($ud > $dt), "undef >";
is $dt > time, !1, ">";
is time > $dt, 1, ">";

ok !defined($dt >= undef), ">= undef";
ok !defined($ud >= $dt), "undef >=";
is $dt >= time, !1, ">=";
is time >= $dt, 1, "reverse >=";

ok !defined($dt eq undef), "eq undef";
ok !defined($ud eq $dt), "undef eq";
is $dt eq time, !1, "eq";
is time eq $dt, !1, "reverse eq";

ok !defined($dt ne undef), "ne undef";
ok !defined($ud ne $dt), "undef ne";
is $dt ne time, 1, "ne";
is time ne $dt, 1, "reverse ne";

ok !defined($dt cmp undef), "cmp undef";
ok !defined($ud cmp $dt), "undef cmp";
is $dt cmp time, -1, "cmp";
is time cmp $dt, 1, "reverse cmp";

ok !defined($dt lt undef), "lt undef";
ok !defined($ud lt $dt), "undef lt";
is $dt lt time, 1, "lt";
is time lt $dt, !1, "reverse lt";

ok !defined($dt le undef), "le undef";
ok !defined($ud le $dt), "undef le";
is $dt le time, 1, "le";
is time le $dt, !1, "reverse le";

ok !defined($dt gt undef), "gt undef";
ok !defined($ud gt $dt), "undef gt";
is $dt gt time, !1, "gt";
is time gt $dt, 1, "reverse gt";

ok !defined($dt ge undef), "ge undef";
ok !defined($ud ge $dt), "undef ge";
is $dt ge time, !1, "ge";
is time ge $dt, 1, "reverse ge";
