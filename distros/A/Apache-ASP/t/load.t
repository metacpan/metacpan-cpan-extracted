use Apache::ASP::CGI;
use lib '.'; use lib qw(t); use T; my $t = T->new();

use Carp;
chdir('t');

$SIG{__DIE__} = \&Carp::confess;
$main::TestLoad = 0;
Apache::ASP->Loader('load.inc', undef, Debug => 1, Execute => 1);
$t->eok($main::TestLoad, "failed to execute load.inc while loading");

my $error_mark;
{	
    # Apache::ASP->Loader() uses warn() aliased to Apache::ASP::Warn() to put out error messages
    $^W = 0;
    local *Apache::ASP::Warn = sub {
	my $log_output = join("", @_);
	if($log_output =~ /not_scoped_variable/is) {
	    $error_mark = $log_output;
	} else {
	    warn(@_);
	}
    };
    $^W = 1;
  Apache::ASP->Loader('load_error.inc', undef, Debug => 1, UseStrict => 1);
}
$t->eok($error_mark, "failed to catch compile error of load_error.inc while loading");

$t->done;
