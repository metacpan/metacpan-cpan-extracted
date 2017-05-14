package Bio::VertRes::Config::Pipelines::Common;

# ABSTRACT: A set of attributes common to all pipeline config files


use Moose;
use File::Slurp;
use Bio::VertRes::Config::Types;
use Data::Dumper;
use File::Basename;
use File::Path qw(make_path);
with 'Bio::VertRes::Config::Pipelines::Roles::RootDatabaseLookup';

has 'prefix'              => ( is => 'ro', isa => 'Bio::VertRes::Config::Prefix', default  => '_' );
has 'pipeline_short_name' => ( is => 'ro', isa => 'Str',                          required => 1 );
has 'module'              => ( is => 'ro', isa => 'Str',                          required => 1 );
has 'toplevel_action'     => ( is => 'ro', isa => 'Str',                          required => 1 );

has 'overwrite_existing_config_file' => ( is => 'ro', isa => 'Bool', default => 0 );

has 'log' => ( is => 'ro', isa => 'Str', lazy => 1, builder => '_build_log' );
has 'log_base'      => ( is => 'ro', isa => 'Str', required => 1 );
has 'log_file_name' => ( is => 'ro', isa => 'Str', default => 'logfile.log' );

has 'config' => ( is => 'ro', isa => 'Str', lazy => 1, builder => '_build_config' );
has 'config_base'      => ( is => 'ro', isa => 'Str', required => 1 );
has 'config_file_name' => ( is => 'ro', isa => 'Str', default  => 'global.conf' );

has 'root' => ( is => 'ro', isa => 'Str', lazy => 1, builder => '_build_root' );
has 'root_base'            => ( is => 'ro', isa => 'Str', required => 1 );
has 'root_pipeline_suffix' => ( is => 'ro', isa => 'Str', default => 'seq-pipelines' );

has 'database' => ( is => 'ro', isa => 'Str',        required => 1 );
has 'host'     => ( is => 'ro', isa => 'Str',        lazy     => 1, builder => '_build_host' );
has 'port'     => ( is => 'ro', isa => 'Int',        lazy     => 1, builder => '_build_port' );
has 'user'     => ( is => 'ro', isa => 'Str',        lazy     => 1, builder => '_build_user' );
has 'password' => ( is => 'ro', isa => 'Maybe[Str]', lazy     => 1, builder => '_build_password' );

has 'database_connect_file' => ( is => 'ro', isa => 'Str', required => 1 );
has '_database_connection_details' =>
  ( is => 'ro', isa => 'Maybe[HashRef]', lazy => 1, builder => '_build__database_connection_details' );

sub _build_root {
    my ($self) = @_;
    join( '/', ( $self->root_base, $self->root_database_name, $self->root_pipeline_suffix ) );
}

sub _build_config {
    my ($self) = @_;
    my $conf_file_name = join( '_', ( $self->pipeline_short_name, $self->config_file_name ) );
    join( '/', ( $self->config_base, $self->root_database_name, $self->pipeline_short_name, $conf_file_name ) );
}

sub _build_log {
    my ($self) = @_;
    my $log_file_name = join( '_', ( $self->pipeline_short_name, $self->log_file_name ) );
    join( '/', ( $self->log_base, $self->root_database_name, $log_file_name ) );
}

sub _build_host {
    my ($self) = @_;
    if ( defined( $self->_database_connection_details ) ) {
        return $self->_database_connection_details->{host};
    }
    return $ENV{VRTRACK_HOST} || 'localhost';
}

sub _build_port {
    my ($self) = @_;
    if ( defined( $self->_database_connection_details ) ) {
        return $self->_database_connection_details->{port};
    }
    return $ENV{VRTRACK_PORT} || 3306;
}

sub _build_user {
    my ($self) = @_;
    if ( defined( $self->_database_connection_details ) ) {
        return $self->_database_connection_details->{user};
    }
    return $ENV{VRTRACK_RW_USER} || 'root';
}

sub _build_password {
    my ($self) = @_;
    if ( defined( $self->_database_connection_details ) ) {
        return $self->_database_connection_details->{password};
    }
    return $ENV{VRTRACK_PASSWORD};
}

sub _build__database_connection_details {
    my ($self) = @_;
    my $connection_details;
    if ( -f $self->database_connect_file ) {
        my $text = read_file( $self->database_connect_file );
        $connection_details = eval($text);
    }
    return $connection_details;
}

sub _limits_values_part_of_filename {
    my ($self) = @_;
    my $output_filename = "";
    my @limit_values;
    for my $limit_type (qw(project sample library species lane)) {
        if ( defined $self->limits->{$limit_type} ) {
            my $list_of_limit_values = $self->limits->{$limit_type};
            for my $limit_value ( @{$list_of_limit_values} ) {
                $limit_value =~ s/^\s+|\s+$//g;
                push( @limit_values, $limit_value );

            }
        }
    }
    if ( @limit_values > 0 ) {
        $output_filename = join( '_', @limit_values );
    }
    return $output_filename;
}

sub _filter_characters_truncate_and_add_suffix {
    my ( $self, $output_filename, $suffix ) = @_;
    $output_filename =~ s!\W+!_!g;
    $output_filename =~ s/_$//g;
    $output_filename =~ s/_+/_/g;

    if ( length($output_filename) > 150 ) {
        $output_filename = substr( $output_filename, 0, 146 ) . '_' . int( rand(999) );
    }
    return join( '.', ( $output_filename, $suffix ) );
}

sub create_config_file {
    my ($self) = @_;
    
    my $mode = 0777;
    if ( !( -e $self->config ) ) {
        my ( $config_filename, $directories, $suffix ) = fileparse( $self->config );
        make_path( $directories, {mode => $mode} );
    }

    # If the file exists and you dont want to overwrite existing files, skip it
    return if ( ( -e $self->config ) && $self->overwrite_existing_config_file == 0 );

    # dont print out an extra wrapper variable
    $Data::Dumper::Terse = 1;
    write_file( $self->config, Dumper( $self->to_hash ) );
    chmod $mode, $self->config;
}

sub to_hash {
    my ($self) = @_;

    my %output_hash = (
        root   => $self->root,
        module => $self->module,
        prefix => $self->prefix,
        log    => $self->log,
        db     => {
            database => $self->database,
            host     => $self->host,
            port     => $self->port,
            user     => $self->user,
            password => $self->password,
        },
        data => {
            dont_wait => 0,
            db        => {
                database => $self->database,
                host     => $self->host,
                port     => $self->port,
                user     => $self->user,
                password => $self->password,
            },
        }
    );
    return \%output_hash;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Bio::VertRes::Config::Pipelines::Common - A set of attributes common to all pipeline config files

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

A set of attributes common to all pipeline config files. It is ment to be extended rather than used on its own.
   use Bio::VertRes::Config::Pipelines::Common;
   extends 'Bio::VertRes::Config::Pipelines::Common';

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
