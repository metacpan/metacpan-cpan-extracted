package Apache::Foo::Filter;

use strict;
use warnings FATAL => 'all';

sub handler {
	my $r = shift;
	
	$r->log->debug("Filtering response");
	$r->send_http_header();
	
	$r = $r->filter_register;

	my $fh = $r->filter_input;
	
	while (<$fh>) {
		$r->log->debug("Filtering data $_");
		# remove the underscores
		s/_//g;
		$r->log->debug("Filtered data $_");
		
		print;
	}
}

1;