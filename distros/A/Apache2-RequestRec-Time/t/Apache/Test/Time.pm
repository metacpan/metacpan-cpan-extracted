
package Apache::Test::Time;

use strict;
use warnings FATAL => 'all';

use Apache2::RequestRec ();
use Apache2::RequestIO ();

use Apache2::Const -compile => 'OK';

eval 'use Apache2::RequestRec::Time';
my $use_error = $@;

sub get_data {
	my $r = shift;
	my $out = '';

	my $rt = $r->request_time;
	$out .= sprintf "request_time [%d]\n", $rt;
	my $rt_us = eval { $r->request_time_microseconds };
	$out .= sprintf "request_time_microseconds [%.0f]\n", $rt_us;
	my $rd = eval { $r->request_duration };
	$out .= sprintf "request_duration [%d]\n", $rd;
	my $rd_us = eval { $r->request_duration_microseconds };
	$out .= sprintf "request_duration_microseconds [%d]\n", $rd_us;
	return $out;
}

sub handler {
	my $r = shift;
	$r->content_type('text/plain');
	if ($use_error) {
		$r->print("use error:\n");
		$r->print($use_error);
	} else {
		$r->print("start:\n", get_data($r));
		sleep 2;
		$r->print("end:\n", get_data($r));
	}
	return Apache2::Const::OK;
}

1;

