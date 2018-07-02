use warnings;
use strict;

BEGIN {
	if("$]" < 5.013008) {
		require Test::More;
		Test::More::plan(skip_all =>
			"parse_*expr not available on this Perl");
	}
}

use Test::More tests => 4;
use t::LoadXS ();
use t::WriteHeader ();

t::WriteHeader::write_header("callparser1", "t", "getset1");
ok 1;
require_ok "Devel::CallParser";
t::LoadXS::load_xs("getset1", "t", [Devel::CallParser::callparser_linkable()]);
ok 1;

t::getset1::test_cv_getset_call_parser();
ok 1;

1;
