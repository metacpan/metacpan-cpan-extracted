use strict;
use Test;
BEGIN { plan test => 17; }

my $rcs_id = '$Id: balloon.t,v 1.1 2001/09/10 22:32:08 tony Exp $';

use Acme::Cow::TextBalloon;
ok(1);

sub compare_bubbles
{
    my ($a, $b) = @_;
    my (@a, @b);
    @a = split("\n", $a);
    @b = split("\n", $b);
    ok(scalar @a, scalar @b);
    chomp @a;
    chomp @b;
    for my $i (0..$#a) {
	ok($a[$i], $b[$i]);
    }
}

my $x = new Acme::Cow::TextBalloon;
$x->text("Hi.");
compare_bubbles($x->as_string(), <<'EOB');
 _____
< Hi. >
 -----
EOB
$x->print();

$x->think();
$x->adjust(0);
$x->text(" Hi.");
$x->over(6);
compare_bubbles($x->as_string(), <<'EOB');
       ______
      (  Hi. )
       ------
EOB
$x->print();

$x->adjust(0);
$x->say();
$x->over(0);
$x->text(
"A limerick packs laughs anatomical\n",
"Into space that is quite economical.\n",
"\tBut the good ones I've seen\n",
"\tSo seldom are clean\n",
"And the clean ones so seldom are comical.\n"
);

compare_bubbles($x->as_string(), <<'EOB');
 ___________________________________________
/ A limerick packs laughs anatomical        \
| Into space that is quite economical.      |
|         But the good ones I've seen       |
|         So seldom are clean               |
\ And the clean ones so seldom are comical. /
 -------------------------------------------
EOB
$x->print();
