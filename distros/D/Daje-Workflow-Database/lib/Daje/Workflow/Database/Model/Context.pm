package Daje::Workflow::Database::Model::Context;
use Mojo::Base -base, -signatures;

has 'db';

sub load($self, $workflow_fkey) {
    my $data = $self->db->select(
        'context',
        {
            workflow_fkey => $workflow_fkey
        }
    );

    my $hash;
    $hash = $data->hash if $data->rows > 0;

    return $hash;
}

sub save($self, $data) {
    if ($data->{workflow_fkey} > 0) {
        $self->db->update(
            'context',
            {
                $data
            },
            {
                workflow_fkey => $data->{workflow_fkey}
            }
        )
    } else {
        $data->{workflow_fkey} = $self->db->insert(
            'context',
            {
                $data
            },
            {
                returning => 'workflow_fkey'
            }
        )->hash->{workflow_fkey}
    }

    return $data->{workflow_pkey};
}

1;