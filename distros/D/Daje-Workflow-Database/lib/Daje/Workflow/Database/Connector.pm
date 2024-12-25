package Daje::Workflow::Database::Connector;
use Mojo::Base -base, -signatures;

use Daje::Workflow::Database::Model::Workflow;
use Daje::Workflow::Database::Model::Context;


has 'pg';
has 'db';
has 'workflow_pkey';
has 'workflow';


sub start($self) {

    $self->pg->migrate->from_date(
        'workflow', 'Daje::Workflow::Database::Connector'
    );

    my $data = $self->load();

    return $data;
}

sub stop($self, $workflow, $context) {
    $self->save_workflow($workflow);
    $context->{workflow_fkey} = $workflow->{workflow_pkey};
    $self->save_context($context);
}

sub load($self ) {
    my $data->{workflow} = $self->load_workflow();
    $data->{context} = $self->load_context();
    return $data;
}

sub load_workflow($self, $workflow_pkey) {
    my $data = Daje::Workflow::Database::Model::Workflow->new(
        db => $self->db
    )->load(
        workflow_pkey => $self->workflow_pkey,
        workflow      => $self->workflow,
    );
    return $data;
}

sub save_workflow($self, $data) {
    my $workflow_pkey = Daje::Workflow::Database::Model::Workflow->new(
        db => $self->db
    )->save(
        $data
    );
    return $workflow_pkey;
}

sub load_context($self, $workflow_pkey) {
    my $data = Daje::Workflow::Database::Model::Context->new(
        db => $self->db
    )->load(
        workflow_fkey => $self->workflow_pkey
    );

    return $data;
}

sub save_context($self, $data) {
    Daje::Workflow::Database::Model::Context->new(
        db => $self->db
    )->save(
        $data
    );
    return ;
}
1;

__DATA__

@@ workflow

-- 1 up

CREATE TABLE IF NOT EXISTS workflow
(
    workflow_pkey serial not null primary key,
    editnum bigint NOT NULL DEFAULT 1,
    insby varchar NOT NULL DEFAULT 'System',
    insdatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    modby varchar NOT NULL DEFAULT 'System',
    moddatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    name varchar not null,
    state varchar not null
);

CREATE TABLE IF NOT EXISTS context
(
    context_pkey serial not null primary key,
    editnum bigint NOT NULL DEFAULT 1,
    insby varchar NOT NULL DEFAULT 'System',
    insdatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    modby varchar NOT NULL DEFAULT 'System',
    moddatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    workflow_fkey bigint not null,
    context JSON,
    CONSTRAINT context_workflow_fkey FOREIGN KEY (workflow_fkey)
        REFERENCES workflow (workflow_pkey)
);

CREATE INDEX IF NOT EXISTS idx_context_workflow_fkey
    ON context(workflow_fkey);

CREATE TABLE IF NOT EXISTS history
(
    history_pkey serial not null primary key,
    editnum bigint NOT NULL DEFAULT 1,
    insby varchar NOT NULL DEFAULT 'System',
    insdatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    modby varchar NOT NULL DEFAULT 'System',
    moddatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    workflow_fkey bigint not null,
    history varchar,
    CONSTRAINT history_workflow_fkey FOREIGN KEY (workflow_fkey)
        REFERENCES workflow (workflow_pkey)
);

CREATE INDEX IF NOT EXISTS idx_history_workflow_fkey
    ON history(workflow_fkey);

-- 1 down

DROP TABLE workflow;
DROP TABLE context;
DROP TABLE history;