use App::Test;

my $t = App::Test->new(will_decode_content => 1);

$t->req_ok(GET => "http://localhost/");

SKIP: {
	skip("Because Cli modules and Api::ShowSession is not working on production", 1)
		if $t->c->is_production;
	$t->req_ok(GET => "http://localhost/api/ping");
	$t->req_ok(GET => "http://localhost/api/show_session");
};

done_testing;