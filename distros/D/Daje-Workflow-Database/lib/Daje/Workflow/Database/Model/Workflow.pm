package Daje::Workflow::Database::Model::Workflow;
use Mojo::Base -base, -signatures;

has 'db';

sub load($self, $workflow_pkey) {
    my $data = $self->db->select(
        'workflow',
        {
            workflow_pkey => $workflow_pkey
        }
    );

    my $hash;
    $hash = $data->hash if $data->rows > 0;

    return $hash;
}

sub save($self, $data) {
    if ($data->{workflow_pkey} > 0) {
        $self->db->update(
            'workflow',
            {
                $data
            },
            {
                workflow_pkey => $data->{workflow_pkey}
            }
        )
    } else {
        $data->{workflow_pkey} = $self->db->insert(
            'workflow',
                {
                    $data
                },
                {
                    returning => 'workflow_pkey'
                }
        )->hash->{workflow_pkey}
    }

    return $data->{workflow_pkey};
}
1;