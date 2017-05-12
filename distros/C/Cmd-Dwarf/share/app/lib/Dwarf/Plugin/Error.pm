package Dwarf::Plugin::Error;
use Dwarf::Pragma;
use Dwarf::Util qw/add_method/;

sub init {
	my ($class, $c, $conf) = @_;
	$conf ||= {};

	die "conf must be HASH" unless ref $conf eq 'HASH';

	while (my ($k, $v) = each %$conf) {
		die "key must not be REFERENCE" if ref $k;
		die "value must be CODE" unless ref $v eq 'CODE';
		add_method($c->error, $k, $v);
	}
}

1;
