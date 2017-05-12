package Chef::Knife::Cmd::Client;
use Moo;

use Chef::Knife::Cmd::Node::RunList;

has knife => (is => 'ro', required => 1, handles => [qw/handle_options run/]);

sub delete {
    my ($self, $client, %options) = @_;
    my @opts = $self->handle_options(%options);
    my @cmd  = (qw/knife client delete/, $client, @opts);
    $self->run(@cmd);
}

1;
