##
## file.t
##
## $Id: file.t,v 1.1 2001/09/10 22:32:08 tony Exp $
##

use strict;
use Test;
BEGIN { plan test => 16; }

my $rcs_id = '$Id: file.t,v 1.1 2001/09/10 22:32:08 tony Exp $';

use Acme::Cow qw(compare_bubbles);
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

my $x = new Acme::Cow(File => (-e "t/eyes.cow" ? "t/eyes.cow" : "eyes.cow"));
$x->text("Bwahaha!");
compare_bubbles($x->as_string(), <<'EOC');
 __________
< Bwahaha! >
 ----------
    \
     \
                                   .::!!!!!!!:.
  .!!!!!:.                        .:!!!!!!!!!!!!
  ~~~~!!!!!!.                 .:!!!!!!!!!UWWW$$$ 
      :$$NWX!!:           .:!!!!!!XUWW$$$$$$$$$P 
      $$$$$##WX!:      .<!!!!UW$$$$"  $$$$$$$$# 
      $$$$$  $$$UX   :!!UW$$$$$$$$$   4$$$$$* 
      ^$$$B  $$$$     $$$$$$$$$$$$   d$$R" 
        "*$bd$$$$      '*$$$$$$$$$$$o+#" 
             """"          """"""" 
EOC
$x->print();
