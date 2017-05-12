
use Apache::ASP::CGI;
use lib qw(t .);
use T;
use strict;

$SIG{__DIE__} = \&Carp::confess;

chdir('t');
my $r = Apache::ASP::CGI->init('reload_global_asa.t');
my %config = (
	      UseStrict => 1,
#	      Debug => -3,
	      );
for(keys %config) {
    $r->dir_config->set($_, $config{$_});
}

my $t = T->new;

# will trigger error when reloading subs
# critical to the test case
local $^W = 1; 

my $ASP_1 = Apache::ASP->new($r);
$t->eok(keys(%Apache::ASP::Compiled) >= 1, "nothing compiled");
%Apache::ASP::Compiled = (); # free compiled routines
my $ASP_2 = Apache::ASP->new($r);

# so to untie STDOUT
$ASP_1->DESTROY;
$ASP_2->DESTROY;

$t->ok;
$t->done;

