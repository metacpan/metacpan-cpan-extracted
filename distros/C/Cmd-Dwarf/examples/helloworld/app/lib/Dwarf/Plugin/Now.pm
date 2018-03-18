package Dwarf::Plugin::Now;
use Dwarf::Pragma;
use Dwarf::Util qw/add_method/;
use DateTime;

sub init {
	my ($class, $c, $conf) = @_;
	$conf ||= {};

	add_method($c, now => sub {
		my $self = shift;
		$self->{'dwarf.now'} ||= DateTime->now(%$conf);
	});
}

1;
