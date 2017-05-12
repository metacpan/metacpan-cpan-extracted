use strict;
use warnings FATAL => 'all';

package Apache::SWIT::Maker::Generator;
use base 'Apache::SWIT::Maker::GeneratorBase';
use File::Slurp;

sub location_section_contents {
	my ($self, $res, $n, $v) = @_;
	my $t = $v->{template} or return "";
	return "\tPerlSetVar SWITTemplate $t\n";
}

sub httpd_conf_start {
	my ($self, $res) = @_;
	$res = read_file('conf/httpd.conf.in') . "\n";
	return $res;
}

1;
