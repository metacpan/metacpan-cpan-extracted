package Chef::Knife::Cmd::EC2::Server;
use Moo;

has knife  => (is => 'ro', required => 1, handles => [qw/handle_options run/]);

sub list {
    my ($self, %options) = @_;
    my @opts = $self->handle_options(%options);
    my @cmd  = (qw/knife ec2 server list/, @opts);
    $self->run(@cmd);
}

sub create {
    my ($self, %options) = @_;
    my @opts = $self->handle_options(%options);
    my @cmd  = (qw/knife ec2 server create/, @opts);
    $self->run(@cmd);
}

sub delete {
    my ($self, $nodes, %options) = @_;
    my $nodes_str = join " ", @$nodes;
    my @opts = $self->handle_options(%options);
    my @cmd  = (qw/knife ec2 server delete/, $nodes_str, @opts);
    $self->run(@cmd);
}

1;
