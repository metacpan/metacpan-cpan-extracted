use Test::Pod::Coverage tests=>1;

pod_coverage_ok( "Data::Transform::SAXBuilder", {
		coverage_class => 'Pod::Coverage::CountParents',
                trustme => [qw(BUFFER HANDLER PARSER)],
	});

