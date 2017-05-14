package Bio::VertRes::Config::MultipleTopLevelFiles;

# ABSTRACT: A class to represent multiple top level files. It splits out mixed config files into the correct top level files


use Moose;
use Bio::VertRes::Config::TopLevel;

has 'database'         => ( is => 'ro', isa => 'Str',      required => 1 );
has 'pipeline_configs' => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has 'config_base'  => ( is => 'ro', isa => 'Str',     required => 1 );

sub update_or_create {
    my ($self) = @_;

    my %short_name_to_configs;

    # split by short name
    for my $pipeline_config ( @{ $self->pipeline_configs } ) {
        # Create the config file
        $pipeline_config->create_config_file;
        if ( !defined( $short_name_to_configs{ $pipeline_config->pipeline_short_name } ) ) {
            $short_name_to_configs{ $pipeline_config->pipeline_short_name } = [];
        }
        push( @{$short_name_to_configs{ $pipeline_config->pipeline_short_name }}, $pipeline_config );
    }

    for my $pipeline_short_name ( keys %short_name_to_configs ) {
        Bio::VertRes::Config::TopLevel->new(
            database            => $self->database,
            pipeline_configs    => $short_name_to_configs{$pipeline_short_name},
            pipeline_short_name => $pipeline_short_name,
            config_base => $self->config_base
        )->update_or_create();

    }
    return $self;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Bio::VertRes::Config::MultipleTopLevelFiles - A class to represent multiple top level files. It splits out mixed config files into the correct top level files

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

A class to represent multiple top level files. It splits out mixed config files into the correct top level files
   use Bio::VertRes::Config::MultipleTopLevelFiles;

   my $pipeline = Bio::VertRes::Config::MultipleTopLevelFiles->new(database => 'abc', pipeline_configs => [$config_obj1, $config_obj2]);
   $pipeline->update_or_create();

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
