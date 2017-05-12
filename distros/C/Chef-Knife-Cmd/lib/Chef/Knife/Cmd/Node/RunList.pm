package Chef::Knife::Cmd::Node::RunList;
use Moo;

has knife => (is => 'ro', required => 1, handles => [qw/run handle_options/]);

sub add {
    my ($self, $node, $entries_in, %options) = @_;

    # build a comma separated list
    my @entries = map { $_ . ',' } @$entries_in; # add a comma to every entry
    chop($entries[-1]);                          # rm comma from last entry

    my @opts = $self->handle_options(%options);
    my @cmd  = (qw/knife node run_list add/, $node, @entries, @opts);
    $self->run(@cmd);
}

1;
