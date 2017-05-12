package DBIx::Class::DeploymentAdapter;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.08";

=encoding utf-8

=head1 NAME

DBIx::Class::DeploymentAdapter - Deployment handler adapter to your DBIC app, which offers some candy

=head1 SYNOPSIS

    use DBIx::Class::DeploymentAdapter;

    my $args = {
        schema              => $schema,
        script_directory    => './share/migrations',
        databases           => ['MySQL'],
        sql_translator_args => { mysql_enable_utf8 => 1 },
    };

    $args->{to_version}      = $to_version      if $to_version;
    $args->{force_overwrite} = $force_overwrite if $force_overwrite;

    my $da = DBIx::Class::DeploymentAdapter->new($args);

=head1 DESCRIPTION

Deployment handler adapter to your DBIC app, which offers some candy

=cut

use DBIx::Class::DeploymentHandler;

use Moose;

has dh_store => (
    is  => "rw",
    isa => "Maybe[Object]"
);

sub dh {

    my ( $self, $args ) = @_;

    if ( !$self->dh_store ) {

        return unless $args && $args->{schema};

        $args->{script_directory}    ||= "./share/migrations";
        $args->{databases}           ||= ["MySQL"];
        $args->{sql_translator_args} ||= { mysql_enable_utf8 => 1 };

        my $dh = DBIx::Class::DeploymentHandler->new($args);
        $self->dh_store( $dh );

    }

    return $self->dh_store;
}

sub BUILD {

    my $self = shift;
    my $args = shift;

    $self->dh($args);
}

=head2 install

Installs the schema files to the given Database

    $da->install;

=cut

sub install {

    my $self = shift;
    my @params = @_;

    return unless $self->dh;

    $self->dh->install(@params);
}

=head2 prepare

Summarize all prepares from L<DBIx::Class::DeploymentHandler> in one Command

    $da->prepare;

=cut

sub prepare {

    my ($self) = @_;

    return unless $self->dh;

    my $start_version  = $self->dh->database_version;
    my $target_version = $self->dh->schema->schema_version;

    $self->dh->prepare_install;

    $self->dh->prepare_upgrade(
        {
            from_version => $start_version,
            to_version   => $target_version,
        }
    );

    $self->dh->prepare_downgrade(
        {
            from_version => $target_version,
            to_version   => $start_version,
        }
    );
}

=head2 status

Returns the Status of database and schema versions as string

    $da->status;

=cut

sub status {

    my ( $self ) = @_;

    return unless ref $self->dh;

    my $deployed_version = $self->dh->database_version;
    my $schema_version   = $self->dh->schema->schema_version;

    return sprintf( "Schema is %s\nDeployed database is %s\n", $schema_version, $deployed_version );

}

=head2 upgrade_incremental

Upgrade the database version step by step, if anything wents wrong, it dies with the specific database error.

You can give a target version to the method to make it stop there

    $da->upgrade_incremental;
    $da->upgrade_incremental(112);

=cut

sub upgrade_incremental {

    my ( $self, $to_version ) = @_;

    return unless $self->dh;

    my $start_version  = $self->dh->database_version + 1;
    my $target_version = $self->dh->schema->schema_version;

    for my $upgrade_version ( $start_version .. $target_version ) {

        my $version = $self->dh->database_version;

        if( $to_version && $upgrade_version > $to_version ) {
            next;
        }

        warn "upgrading to version $upgrade_version\n";

        eval {
            my ( $ddl, $sql ) = @{ $self->dh->upgrade_single_step( { version_set => [ $version, $upgrade_version ] } ) || [] };    # from last version to desired version
            $self->dh->add_database_version(
                {
                    version     => $upgrade_version,
                    ddl         => $ddl,
                    upgrade_sql => $sql,
                }
            );
        };

        if ($@) {
            my $error_version = $self->dh->database_version;
            warn "Database remains on version $error_version";
            die "UPGRADE ERROR - Version $error_version upgrading to $version: " . $@;
        }
    }
}

1;



=head1 LICENSE

Copyright (C) Patrick Kilter.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Patrick Kilter E<lt>pk@gassmann.itE<gt>

=cut
