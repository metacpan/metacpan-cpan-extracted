use strict;
use warnings;

use Test::More tests => 5;
BEGIN { use_ok('Algorithm::CP::IZ') };

{
    my $iz = Algorithm::CP::IZ->new();
    my $s = $iz->create_int(1, 9);
    my $e = $iz->create_int(0, 9);
    my $n = $iz->create_int(0, 9);
    my $d = $iz->create_int(0, 9);
    my $m = $iz->create_int(1, 9);
    my $o = $iz->create_int(0, 9);
    my $r = $iz->create_int(0, 9);
    my $y = $iz->create_int(0, 9);

    $iz->AllNeq([$s, $e, $n, $d, $m, $o, $r, $y]);

    my $v1 = $iz->ScalProd([$s, $e, $n, $d], [1000, 100, 10, 1]);
    my $v2 = $iz->ScalProd([$m, $o, $r, $e], [1000, 100, 10, 1]);
    my $v3 = $iz->ScalProd([$m, $o, $n, $e, $y], [10000, 1000, 100, 10, 1]);
    my $v4 = $iz->Add($v1, $v2);
    $v3->Eq($v4);

    my $rc = $iz->search([$s, $e, $n, $d, $m, $o, $r, $y]);
    is($rc, 1);

    my $l1 = join(" ", map { $_->value } ($s, $e, $n, $d));
    my $l2 = join(" ", map { $_->value } ($m, $o, $r, $e));
    my $l3 = join(" ", map { $_->value } ($m, $o, $n, $e, $y));

    is($l1, "9 5 6 7");
    is($l2, "1 0 8 5");
    is($l3, "1 0 6 5 2");

    # print STDERR "\n";
    # print STDERR "  ", join(" ", map { $_->value } ($s, $e, $n, $d)), "\n";
    # print STDERR "  ", join(" ", map { $_->value } ($m, $o, $r, $e)), "\n";
    # print STDERR join(" ", map { $_->value } ($m, $o, $n, $e, $y)), "\n";
    # print STDERR "\n";
}
