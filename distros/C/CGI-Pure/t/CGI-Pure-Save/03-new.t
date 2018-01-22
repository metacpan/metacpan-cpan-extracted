use strict;
use warnings;

use CGI::Pure;
use CGI::Pure::Save;
use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
eval {
	CGI::Pure::Save->new;
};
is($EVAL_ERROR, "CGI::Pure object doesn't define.\n");
clean();

# Test.
my $cgi_pure = CGI::Pure->new;
my $obj = CGI::Pure::Save->new('cgi_pure' => $cgi_pure);
isa_ok($obj, 'CGI::Pure::Save');
