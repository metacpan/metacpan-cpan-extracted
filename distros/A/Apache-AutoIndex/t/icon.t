use Apache::test;

skip_test unless have_module Apache::Icon;

print "1..1\n";

test 1, &testing;                              

sub testing {
	return 1;
	}
