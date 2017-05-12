
# ----------- Plug ------------

# it will be useful to represent
# Nama-side and external ports
# and connections

package Audio::Nama::Plug;
use Modern::Perl;
our $VERSION = 1.0;
our @ISA;
use Audio::Nama::Log qw(logpkg);
use Audio::Nama::Globals qw(:all);
use Audio::Nama::Object qw(
				direction
				type
				id
				channel
				width
				client
				port
				track
				chain
				);
sub new {
	my ($class, %args) = @_;
	my $self = bless { channel => 1,
						width  => 1,
						%args 		}, $class;
	$self
}
sub jack_client {
}
sub jack_ports {
}
sub send_type {

}
sub send_id {

}

			
=comment
my $inplug = Audio::Nama::Plug->new(
						direction => 'input',
push @connections, [$inplug, $outplug];
=cut

1
__END__