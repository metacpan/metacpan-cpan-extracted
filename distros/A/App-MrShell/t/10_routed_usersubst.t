
use strict;
use warnings;

use Test;
use App::MrShell;

plan tests => 6;

my $shell = App::MrShell->new;
my @cmd = (qw(a b [%u]c [%u]%u %u d %h));

$" = ")(";

DIRECT: {
    my $host   = "nombre";
    my @result = $shell->set_subst_vars('%h'=>$host)->subst_cmd_vars(@cmd);
    ok("(@result)", '(a)(b)(%u)(d)(nombre)');
}

ROUTED: {
    my $host   = "via1!via2!nombre";
    my @result = $shell->set_subst_vars('%h'=>$host)->subst_cmd_vars(@cmd);
    ok("(@result)", '(a)(b)(%u)(d)(via1)(a)(b)(%u)(d)(via2)(a)(b)(%u)(d)(nombre)');
}

DIRECTWU: {
    my $host   = 'A@nombre';
    my @result = $shell->set_subst_vars('%h'=>$host)->subst_cmd_vars(@cmd);
    ok("(@result)", '(a)(b)(c)(A)(A)(d)(nombre)');
}

ROUTEDWU: {
    my $host   = 'A@via1!B@via2!C@nombre';
    my @result = $shell->set_subst_vars('%h'=>$host)->subst_cmd_vars(@cmd);
    ok("(@result)", '(a)(b)(c)(A)(A)(d)(via1)(a)(b)(c)(B)(B)(d)(via2)(a)(b)(c)(C)(C)(d)(nombre)');
}

ROUTEDWU: {
    my $host   = 'via1!via2!C@nombre'; # this failed for me IRL
    my @cmd    = (qw(ssh [%u]-l [%u]%u %h));
    my @result = $shell->set_subst_vars('%h'=>$host)->subst_cmd_vars(@cmd);
    ok("(@result)", '(ssh)(via1)(ssh)(via2)(ssh)(-l)(C)(nombre)');
}

ROUTEDWU: {
    my $host   = 'via1!via2!C@nombre'; # no-no, *this* failed for me IRL
    my @cmd    = (qw(ssh [%u]-l []%u %h));
    my @result = $shell->set_subst_vars('%h'=>$host)->subst_cmd_vars(@cmd);
    ok("(@result)", '(ssh)(via1)(ssh)(via2)(ssh)(-l)(C)(nombre)');
}
