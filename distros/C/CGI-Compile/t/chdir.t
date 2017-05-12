use strict;
use Test::More;
use CGI::Compile;
use Cwd;

my $sub = CGI::Compile->compile("t/error.cgi");

my $dir = Cwd::cwd;
eval { $sub->() };

is Cwd::cwd, $dir;

done_testing;


