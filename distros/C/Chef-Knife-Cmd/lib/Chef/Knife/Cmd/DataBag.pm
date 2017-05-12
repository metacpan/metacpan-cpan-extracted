package Chef::Knife::Cmd::DataBag;
use Moo;

use Chef::Knife::Cmd::Node::RunList;

has knife => (is => 'ro', required => 1, handles => [qw/handle_options run/]);

sub show {
    my ($self, $data_bag, $item, %options) = @_;
    my @opts = $self->handle_options(%options);
    my @cmd  = (qw/knife data bag show/, $data_bag);
    push @cmd, $item if $item;
    push @cmd, @opts;
    $self->run(@cmd);
}

1;
