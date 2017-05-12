package Chef::Knife::Cmd::Node;
use feature qw/say/;
use Moo;

use Chef::Knife::Cmd::Node::RunList;
use Chef::Knife::Cmd::Node::From;

has knife    => (is => 'ro', required => 1, handles => [qw/handle_options run/]);
has run_list => (is => 'lazy');
has from     => (is => 'lazy');

sub _build_run_list { Chef::Knife::Cmd::Node::RunList->new(knife => shift) }
sub _build_from     { Chef::Knife::Cmd::Node::From->new(knife => shift) }

sub show {
    my ($self, $node, %options) = @_;
    my @opts = $self->handle_options(%options);
    my @cmd  = (qw/knife node show/, $node, @opts);
    $self->run(@cmd);
}

sub delete {
    my ($self, $node, %options) = @_;
    my @opts = $self->handle_options(%options);
    my @cmd  = (qw/knife node delete/, $node, @opts);
    $self->run(@cmd);
}

sub create {
    my ($self, $node, %options) = @_;
    my @opts = $self->handle_options(%options);
    my @cmd  = (qw/knife node create/, $node, @opts);
    $self->run(@cmd);
}

sub list {
    my ($self, $node, %options) = @_;
    my @opts = $self->handle_options(%options);
    my @cmd  = (qw/knife node list/, @opts);
    $self->run(@cmd);
}

sub flip {
    my ($self, $node, $environment, %options) = @_;
    my @opts = $self->handle_options(%options);
    my @cmd  = (qw/knife node flip/, $node, $environment, @opts);
    $self->run(@cmd);
}

1;
