##
## derived.t
##
## $Id: pm.t,v 1.1 2001/09/10 22:32:08 tony Exp $
##

use strict;
use Test;
BEGIN { plan test => 12; }

my $rcs_id = '$Id: pm.t,v 1.1 2001/09/10 22:32:08 tony Exp $';

use Acme::Cow::Frogs;
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

my $x = new Acme::Cow::Frogs();
$x->text('Hi.');
compare_bubbles($x->as_string(), <<'EOC');
                                               _____
                                              < Hi. >
                                               -----
                                              /
                                            /
          oO)-.                       .-(Oo
         /__  _\                     /_  __\
         \  \(  |     ()~()         |  )/  /
          \__|\ |    (-___-)        | /|__/
          '  '--'    ==`-'==        '--'  '
EOC
$x->print();
