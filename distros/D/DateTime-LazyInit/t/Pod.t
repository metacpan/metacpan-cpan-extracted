use Test::More tests=>1;

SKIP: {
	eval{ require Test::Pod };
	skip "Test::Pod isn't installed. Believe me: the POD is ok!", 1 if $@;

	Test::Pod::pod_file_ok('lib/DateTime/LazyInit.pm','Pod tests OK');
}


