
use strict;
use warnings;

use Test;
use App::MrShell;

plan tests => 3;

my $shell = App::MrShell->new;
my @cmd = ("a b", '%h', "c d", '%h', "e f");

DIRECT: {
    my $host  = "nombre";
    my @res = $shell->set_subst_vars('%h'=>$host)->subst_cmd_vars(@cmd);
    ok("@res", "a b nombre c d nombre e f");
}

INDIRECT1: {
    my $host  = "via1!nombre";
    my @res = $shell->set_subst_vars('%h'=>$host)->subst_cmd_vars(@cmd);
    ok("@res", 'a b via1 "a b" nombre "c d" via1 "a b" via1 "\"a b\"" nombre "\"c d\"" nombre "\"e f\""');
}

INDIRECT1: {
    @cmd = map {my @a = map { (m/^\[/ or $_ eq '%h') ? $_ : substr $_, 0, 1} split; "@a"} @App::MrShell::DEFAULT_SHELL_COMMAND;
    # do { local $" = ")("; warn " wtf(@cmd)\n" };

    my $host  = "via1!via2!via3!nombre";
    my @res = $shell->set_subst_vars('%h'=>$host)->subst_cmd_vars(@cmd);
    ok("@res", 's - B y - S n - C 2 via1 s - "B y" - "S n" - "C 2" via2 s - "\"B y\"" - "\"S n\"" - "\"C 2\"" via3 s - "\"\\\\\\"B y\\\\\\"\"" - "\"\\\\\\"S n\\\\\\"\"" - "\"\\\\\\"C 2\\\\\\"\"" nombre');
}
