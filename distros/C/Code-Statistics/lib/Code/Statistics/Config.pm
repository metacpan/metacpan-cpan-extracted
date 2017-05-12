use strict;
use warnings;

package Code::Statistics::Config;
{
  $Code::Statistics::Config::VERSION = '1.112980';
}

# ABSTRACT: merges configuration options from various sources

use Moose;
use MooseX::HasDefaults::RO;

use Hash::Merge qw( merge );
use Config::INI::Reader;
use Path::Class qw(file);
use File::HomeDir;

has args => ( isa => 'HashRef', default => sub {{}} );

has command => ( isa => 'Str', );

has conf_file => ( isa => 'Str', default => '.codestatrc' );

has global_conf_file => ( isa => 'Str', default => sub { file( File::HomeDir->my_home, '.codestatrc' )->stringify } );

has profile => ( isa => 'Str', );


sub assemble {
    my ( $self ) = @_;

    my $config = {};

    $config = merge( $self->_global_config, $config );
    $config = merge( $self->_local_config,  $config );
    $config = merge( $self->args,    $config );

    return $config;
}

sub _local_config {
    my ( $self ) = @_;

    return $self->_merged_conf_from( $self->conf_file );
}

sub _global_config {
    my ( $self ) = @_;

    return $self->_merged_conf_from( $self->global_conf_file );
}

sub _merged_conf_from {
    my ( $self, $file ) = @_;

    return {} if !$file or !-e $file;

    my $conf = Config::INI::Reader->read_file( $file );

    my $merge;
    my @sections = grep { defined } ( '_', $self->command, $self->_profile_section );
    for ( @sections ) {
        next if !$conf->{$_};
        $merge = merge( $conf->{$_}, $merge );
    }

    return $merge;
}

sub _profile_section {
    my ( $self ) = @_;

    my $section = $self->command;
    $section .= '::' . $self->profile if $self->profile;

    return $section;
}

1;

__END__
=pod

=head1 NAME

Code::Statistics::Config - merges configuration options from various sources

=head1 VERSION

version 1.112980

=head2 assemble
    Builds the command-related configuration hash. The hash contains all config
    options from the global config file, local file and command line arguments.

=head1 AUTHOR

Christian Walde <mithaldu@yahoo.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Christian Walde.

This is free software, licensed under:

  DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE, Version 2, December 2004

=cut

