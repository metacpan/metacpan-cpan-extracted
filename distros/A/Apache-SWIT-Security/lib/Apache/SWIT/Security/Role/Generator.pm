use strict;
use warnings FATAL => 'all';

package Apache::SWIT::Security::Role::Generator;
use base 'Apache::SWIT::Maker::GeneratorBase';
use Apache::SWIT::Security::Maker;

sub httpd_conf_start {
	my ($self, $res) = @_;
	Apache::SWIT::Security::Maker->new->write_sec_modules;
	return $res;
}

1;
