package Daje::Workflow::Database::Model::History;
use Mojo::Base -base, -signatures;

has 'db';

sub load_list($self, $workflow_fkey) {
    my $data = $self->db->select(
        'workflow',
        {
            workflow_fkey => $workflow_fkey
        }
    );
    my $hashes;

    $hashes = $data->hashes if $data->rows > 0;

    return $hashes;
}

sub insert($self, $data) {
    $self->db->insert(
        'history',
        {
            $data
        }
    );
}

1;