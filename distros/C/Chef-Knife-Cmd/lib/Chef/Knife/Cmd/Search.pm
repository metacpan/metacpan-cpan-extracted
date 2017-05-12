package Chef::Knife::Cmd::Search;
use Moo;

use Chef::Knife::Cmd::Node::RunList;

has knife => (is => 'ro', required => 1, handles => [qw/handle_options run/]);

sub node {
    my ($self, $query, %options) = @_;
    my @opts = $self->handle_options(%options);
    my @cmd  = (qw/knife search node/, $query, @opts);
    $self->run(@cmd);
}

sub client {
    my ($self, $query, %options) = @_;
    my @opts = $self->handle_options(%options);
    my @cmd  = (qw/knife search client/, $query, @opts);
    $self->run(@cmd);
}

1;
