package Chef::Knife::Cmd::EC2;
use Moo;

use Chef::Knife::Cmd::EC2::Server;

has knife  => (is => 'ro', required => 1, handles => [qw/handle_options run/]);
has server => (is => 'lazy');

sub _build_server { Chef::Knife::Cmd::EC2::Server->new(knife => shift) }

1;
