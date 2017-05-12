use Apache::ASP::CGI;
use lib qw(t .);
use T;
use strict;

$SIG{__DIE__} = \&Carp::confess;

chdir('t');
my $r = Apache::ASP::CGI->init('asp_object.t');
my %config = (
#	      Debug => -3,
	      NoState => 0,
	      );
for(keys %config) {
    $r->dir_config->set($_, $config{$_});
}

my $t = T->new;

my $ASP_1 = Apache::ASP->new($r);
#$ASP_1->Out($ASP_1);

$t->eok($ASP_1->Session && $ASP_1->Application, "ASP Objects 1");
my $app_1 = $ASP_1->Application;
	
my $ASP_2 = Apache::ASP->new($r);
$t->eok($ASP_2->Session && $ASP_2->Application, "ASP Objects 2");
my $app_2 = $ASP_2->Application;

$app_1->{Test} = 'OK';
$t->eok($app_2->{Test} eq 'OK', "Application data OK pre DESTROY");
$ASP_1->DESTROY;
$t->eok($app_2->{Test} eq 'OK', "Application data OK post DESTROY");

$t->done;

