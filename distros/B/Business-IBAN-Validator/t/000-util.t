#! perl -I. -w
use t::Test::abeltje;

BEGIN { use_ok('Business::IBAN::Util', qw( numify_iban mod97 )); }

{
    note("testing 'mod97' on numeric level");
    # Numbers need to be at least 9 digits
    my $num = big_mul("1234567890987654321",97);
    my $mod = mod97($num);
    is($mod, 0, "$num mod97 also works on large-ints: $mod");

    $num = big_sum($num, 67);
    $mod = mod97($num);
    is($mod, 67, "$num mod97: $mod");
}

{
    note("numify_iban put the first 4 at the end and numify letters");
    my $str = 'ABE19700101';
    my $num = numify_iban($str);
    is($num, '97001011011141', "iso7064: $str => $num");
    my $mod = mod97($num);
    is($mod, 26, "mod97(): $mod");

    $str = 'blub1234567890';
    $num = numify_iban($str);
    is($num, '123456789011213011', "iso7064: $str => $num");
    $mod = mod97($num);
    is($mod, 70, "mod97(): $mod");
}

abeltje_done_testing();

# these work only for non-negative "numbers"
sub big_sum {
    my ($l, $r) = @_;

    my @ld = reverse split(/|/, $l);
    my @rd = reverse split(/|/, $r);
    while (@rd > @ld) { push(@ld, '0') }
    while (@ld > @rd) { push(@rd, '0') }
    my @s = ();

    my $h = 0;
    for (my $i = 0; $i < @ld; $i++) {
        $h += $ld[$i] + $rd[$i];
        push(@s, $h % 10);
        $h = int($h / 10);
    }

    return join("", reverse @s);

}

sub big_mul {
    my ($l, $r) = @_;

    my @ld = reverse split(/|/, $l);
    my @rd = reverse split(/|/, $r);
    my @p =  (0, 0);

    for (my $i = 0; $i < @ld; $i++) {
        my $h = 0;
        for (my $j = 0; $j < @rd; $j++) {
            no warnings 'uninitialized';
            $h += $p[$i + $j] + ($ld[$i] * $rd[$j]);
            $p[$i + $j] = $h % 10;
            $h = int($h / 10);
        }
        while ($h > 0) {
            push(@p, $h % 10);
            $h = int($h / 10);
        }
    }
    return join("", reverse @p);
}
