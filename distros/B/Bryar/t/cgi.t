use Test::More 'no_plan';
use_ok("Bryar::Frontend::CGI");

ok(Bryar::Frontend::CGI->can("parse_args"), "We can call parse_args");
# Test the output method exists
ok(Bryar::Frontend::CGI->can("output"), "We can call output");

