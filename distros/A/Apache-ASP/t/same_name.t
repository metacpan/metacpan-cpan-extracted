use Apache::ASP::CGI::Test;
use lib qw(t .);
use T;
use strict;
use Cwd qw(cwd);

$SIG{__DIE__} = \&Carp::confess;

my $t = T->new;
my $cwd = cwd();

for my $test_num (1..2) {
    chdir($cwd) || die("can't chdir to $cwd");
    my $r = Apache::ASP::CGI::Test->init($cwd.'/t/same_name/test'.$test_num.'/test.asp');
    my %config = (
		  NoState => 1,
		  GlobalPackage => 'SameName',
#		  Debug => -3,
		  );
    for(keys %config) { $r->dir_config->set($_, $config{$_}); }
    
    my $rv = Apache::ASP->handler($r);

    $t->eok($r->test_body_out eq $test_num, "test $test_num output is: ".$r->test_body_out.", return value: $rv");
}

$t->done;

