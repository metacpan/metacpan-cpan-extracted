
use strict;
use warnings;

use Test;
use App::MrShell;

plan tests => 2;

my $shell = App::MrShell->new;
my @cmd = (qw(a b c %h d e f %h g h i j k l));

DIRECT: {
    my $host  = "nombre";
    my @type1 = $shell->set_subst_vars('%h'=>$host)->subst_cmd_vars(@cmd);
    ok("@type1", "a b c nombre d e f nombre g h i j k l");
}

INDIRECT1: {
    my $host  = "via1!nombre";
    my @type1 = $shell->set_subst_vars('%h'=>$host)->subst_cmd_vars(@cmd);
    ok("@type1", "a b c via1 a b c nombre d e f via1 a b c via1 a b c nombre d e f nombre g h i j k l");
}
