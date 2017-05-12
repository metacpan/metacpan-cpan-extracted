use Test::Pod::Coverage tests => 8;

pod_coverage_ok( "Data::Transform", {
		coverage_class => 'Pod::Coverage::CountParents',
	});

pod_coverage_ok( "Data::Transform::Identity", {
		coverage_class => 'Pod::Coverage::CountParents',
	});

pod_coverage_ok( "Data::Transform::Line", {
		coverage_class => 'Pod::Coverage::CountParents',
                trustme => [qw(AUTODETECT_STATE AUTO_STATE_DONE AUTO_STATE_FIRST AUTO_STATE_SECOND DEBUG FRAMING_BUFFER INPUT_BUFFER INPUT_REGEXP OUTPUT_LITERAL)],

	});

pod_coverage_ok( "Data::Transform::Reference", {
		coverage_class => 'Pod::Coverage::CountParents',
                trustme => [qw(BUFFER DESERIALIZE SERIALIZE INPUT)],
	});

pod_coverage_ok( "Data::Transform::Grep", {
		coverage_class => 'Pod::Coverage::CountParents',
                trustme => [qw(BUFFER CODEGET CODEPUT)],
	});

pod_coverage_ok( "Data::Transform::Map", {
		coverage_class => 'Pod::Coverage::CountParents',
                trustme => [qw(BUFFER CODEGET CODEPUT)],
	});

pod_coverage_ok( "Data::Transform::Stackable", {
		coverage_class => 'Pod::Coverage::CountParents',
                trustme => [qw(FILTERS)],
	});

pod_coverage_ok( "Data::Transform::Identity", {
		coverage_class => 'Pod::Coverage::CountParents',
	});

