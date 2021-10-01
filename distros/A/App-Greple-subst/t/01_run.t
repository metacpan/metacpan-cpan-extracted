use v5.14;
use warnings;
use Encode;
use utf8;

use Test::More;
use Data::Dumper;

use lib '.';
use t::Util;

sub slurp {
    my $file = shift;
    open my $fh, "<:utf8", $file or die "open: $!";
    do { local $/; <$fh> };
}

sub line {
    my($text, $line, $comment) = @_;
    like($text, qr/\A(.*\n){$line}\z/, $comment//'');
}

is(subst(qw(--dict t/JA.dict t/JA-bad.txt))->run->{result}, 0);

line(subst(qw(--dict t/JA.dict t/JA-bad.txt))
     ->run->{stdout}, 9, "--dict");
line(subst(qw(--dict t/JA.dict t/JA-bad.txt --stat))
     ->run->{stdout}, 11, "--stat");
line(subst(qw(--dict t/JA.dict t/JA-bad.txt --with-stat))
     ->run->{stdout}, 20, "--with-stat");
line(subst(qw(--dict t/JA.dict t/JA-bad.txt --with-stat --stat-item dict=1))
     ->run->{stdout}, 21, "dict=1");

line(subst(qw(--dict t/JA.dict t/JA-bad.txt --diff))
     ->run->{stdout}, 28, "--diff");

line(subst(qw(--dict t/JA.dict --diff))
     ->setstdin(slurp('t/JA-bad.txt'))
     ->run->{stdout}, 28, "--diff (stdin)");

line(subst('--dictdata', <<'END', 't/JA-bad.txt')->run->{stdout}, 2, "--dictdata");
イーハトー(ヴォ|ボ)	イーハトーヴォ
END

line(subst('--dictdata', <<'END', 't/JA-bad.txt')->run->{stdout}, 3, "--dictdata");
イーハトー(ヴォ|ボ)	イーハトーヴォ
デストゥ?パーゴ		デストゥパーゴ
END

is(subst(qw(--dict t/JA.dict t/JA-bad.txt --subst --all --no-color))
   ->run->{stdout},
   slurp("t/JA.txt"), "--subst");

is(subst(qw(--dict t/JA.dict --subst --all --no-color))
   ->setstdin(slurp('t/JA-bad.txt'))
   ->run->{stdout},
   slurp("t/JA.txt"), "--subst (stdin)");

done_testing;
