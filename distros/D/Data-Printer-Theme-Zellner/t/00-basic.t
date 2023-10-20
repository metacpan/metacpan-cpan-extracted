#! perl -I. -w
use t::Test::abeltje;

use Data::Printer theme => "Zellner";

my $esc = chr(27);

{
    my $x = "string";
    my $c = np($x, colored => 1);

    my $black_quote = "$esc\\[0;38;5;16m\"$esc\\[m";
    my $magenta_string = "$esc\\[0;38;5;201mstring$esc\\[m";

    like(
        $c,
        qr{^ $black_quote $magenta_string $black_quote $}x,
        "Right colour codes (string): $c"
    );
}

{
    my $x = 42;
    my $c = np($x, colored => 1);

    my $red_number = "$esc\\[0;38;5;88m 42 $esc\\[m";

    like(
        $c,
        qr{^ $red_number $}x,
        "Right colour codes (number): $c"
    );
}

{
    my $x = { een => 42 };
    my $c = np($x, colored => 1);

    my $black_copen = "$esc\\[0;38;5;16m \\{ $esc\\[m";
    my $black_cclose = "$esc\\[0;38;5;16m \\} $esc\\[m";
    my $black_space = "$esc\\[0;38;5;16m \\ \\ \\  $esc\\[m";

    my $blue_key = "$esc\\[0;38;5;21m een $esc\\[m";
    my $red_number = "$esc\\[0;38;5;88m 42 $esc\\[m";

    like(
        $c,
        qr{^ $black_copen \n\ \ \ \  $blue_key $black_space $red_number \n $black_cclose }x,
        "Right colour codes (hash): $c"
    );
}

{
    my $x = [ 1, 2 ];
    my $c = np($x, colored => 1);

    my $b_bopen = "$esc\\[0;38;5;16m \\[ $esc\\[m";
    my $b_bclose = "$esc\\[0;38;5;16m \\] $esc\\[m";
    my $b_comma = "$esc\\[0;38;5;16m , $esc\\[m";

    my $lred_i0 = "$esc\\[0;38;5;196m \\[0\\] \\  $esc\\[m";
    my $lred_i1 = "$esc\\[0;38;5;196m \\[1\\] \\  $esc\\[m";

    my $red_n1 = "$esc\\[0;38;5;88m 1 $esc\\[m";
    my $red_n2 = "$esc\\[0;38;5;88m 2 $esc\\[m";

    my $nl_i = "\\n\\ \\ \\ \\ ";
    like(
        $c,
        qr{^ $b_bopen $nl_i $lred_i0 $red_n1 $b_comma $nl_i $lred_i1 $red_n2 \n $b_bclose $}x,
        "Right colour codes (array): $c"
    );
}

{
    my $x = qr/^ (capture) follow $/x;
    my $c = np($x, colored => 1);

    my $blue_re = "$esc\\[0;38;5;18m \\^\\ \\(capture\\) \\  follow \\ \\\$ $esc\\[m";

    like(
        $c,
        qr{^ $blue_re \ \  \(modifiers:\ x\) $}x,
        "Right colour codes (regex): $c"
    );
}

abeltje_done_testing();
