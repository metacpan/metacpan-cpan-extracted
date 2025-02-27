package Daje::Workflow::Database;
use Mojo::Base -base, -signatures;


use Mojo::Loader qw(load_class);

# NAME
# ====
#
# Daje::Workflow::Database - It's the database migrate plugin for Daje::Workflow
#
# SYNOPSIS
# ========
#
#    use Daje::Workflow::Database;
#
#    push @{$migrations}, {class => 'Daje::Workflow::Database', name => 'workflow', migration => 2};
#
#    push @{$migrations}, {file => '/home/user/schema/users.sql', name => 'users'};
#
#    Daje::Workflow::Database->new(
#         pg            => $pg,
#         migrations    => $migrations,
#     )->migrate();
#
# DESCRIPTION
# ===========
#
# Daje::Workflow::Database is the Database migrate plugin for Daje::Workflow
#
# LICENSE
# =======
#
# Copyright (C) janeskil1525.
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# AUTHOR
# ======
#
# janeskil1525 E<lt>janeskil1525@gmail.comE<gt>
#

our $VERSION = "0.18";

has 'pg';
has 'migrations';

sub migrate($self) {

    my $length = scalar @{$self->migrations};
    for (my $i = 0; $i < $length; $i++) {
        if (exists @{$self->migrations}[$i]->{class}) {
            my $cl = load_class @{$self->migrations}[$i]->{class};
            $self->pg->migrations->name(
                @{$self->migrations}[$i]->{name}
            )->from_data(
                @{$self->migrations}[$i]->{class},
                @{$self->migrations}[$i]->{name}
            )->migrate(
                @{$self->migrations}[$i]->{migration}
            );
        } elsif (exists @{$self->migrations}[$i]->{file}) {
            $self->pg->migrations->name(
                @{$self->migrations}[$i]->{name}
            )->from_file(
                @{$self->migrations}[$i]->{file}
            )->migrate(
                @{$self->migrations}[$i]->{migration}
            );
        }
    }

    return 1;
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

-- 2 up

DROP INDEX idx_context_workflow_fkey;

CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_context_workflow_fkey
    ON context(workflow_fkey);

-- 2 down

DROP INDEX idx_unique_context_workflow_fkey;
CREATE INDEX IF NOT EXISTS idx_context_workflow_fkey
    ON context(workflow_fkey);

-- 3 up
ALTER TABLE history
    ADD COLUMN internal BIGINT NOT NULL DEFAULT 0;

ALTER TABLE history
    ADD COLUMN class VARCHAR NOT NULL DEFAULT '';

-- 3 down
ALTER TABLE history
    DROP COLUMN internal;

ALTER TABLE history
    DROP COLUMN class;

-- 4 up

CREATE TABLE IF NOT EXISTS workflow_connections
(
    workflow_connections_pkey serial not null primary key,
    editnum bigint NOT NULL DEFAULT 1,
    insby varchar NOT NULL DEFAULT 'System',
    insdatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    modby varchar NOT NULL DEFAULT 'System',
    moddatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    workflow_fkey bigint not null,
    connector varchar NOT NULL,
    connector_fkey BIGINT NOT NULL,
    CONSTRAINT workflow_connections_fkey FOREIGN KEY (workflow_fkey)
        REFERENCES workflow (workflow_pkey)
);

CREATE UNIQUE INDEX idx_workflow_connections_connector_connector_fkey
    ON workflow_connections(connector, connector_fkey);

CREATE UNIQUE INDEX idx_workflow_connections_workflow_fkey
    ON workflow_connections(workflow_fkey);

CREATE INDEX idx_workflow_connections_workflow_fkey_connector_connector_fkey
    ON workflow_connections(workflow_fkey, connector, connector_fkey);

-- 4 down

DROP TABLE workflow_connections;

__END__





#################### pod generated by Pod::Autopod - keep this line to make pod updates possible ####################

=head1 NAME


Daje::Workflow::Database - It's the database migrate plugin for Daje::Workflow



=head1 SYNOPSIS


   use Daje::Workflow::Database;

   push @{$migrations}, {class => 'Daje::Workflow::Database', name => 'workflow', migration => 2};

   push @{$migrations}, {file => '/home/user/schema/users.sql', name => 'users'};

   Daje::Workflow::Database->new(
        pg            => $pg,
        migrations    => $migrations,
    )->migrate();



=head1 DESCRIPTION


Daje::Workflow::Database is the Database migrate plugin for Daje::Workflow



=head1 REQUIRES

L<Mojo::Loader> 

L<Mojo::Base> 


=head1 METHODS

=head2 migrate($self)

 migrate($self)();


=head1 AUTHOR


janeskil1525 E<lt>janeskil1525@gmail.comE<gt>



=head1 LICENSE


Copyright (C) janeskil1525.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.



=cut

