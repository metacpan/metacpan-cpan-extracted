use Test::Pod::Coverage tests=>1;

pod_coverage_ok( "Data::Transform::SSL", {
		coverage_class => 'Pod::Coverage::CountParents',
                trustme => [qw(BUF CERT CTX KEY OUTBUF RB SSL SSL_RECEIVED_SHUTDOWN SSL_SENT_SHUTDOWN STATE STATE_CONN STATE_DISC STATE_SHUTDOWN TYPE TYPE_CLIENT TYPE_SERVER WB)],
	});

