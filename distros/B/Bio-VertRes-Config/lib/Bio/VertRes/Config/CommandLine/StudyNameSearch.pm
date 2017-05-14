package Bio::VertRes::Config::CommandLine::StudyNameSearch;

# ABSTRACT: Prevent a study name from being registered in two different databases


use Moose;
use Bio::VertRes::Config::RegisterStudy;
with 'Bio::VertRes::Config::Pipelines::Roles::RootDatabaseLookup';

has 'default_database_name' => ( is => 'ro', isa => 'Str', required => 1 );
has 'study_name'            => ( is => 'ro', isa => 'Str', required => 1 );
has 'config_base'           => ( is => 'ro', isa => 'Str', required => 1 );

sub get_study_database_name_or_default_if_not_found {
    my ($self) = @_;

    # In the normal case the study will be in the default database, so check it first to save on IO
    if (
        Bio::VertRes::Config::RegisterStudy->new(
            database    => $self->default_database_name,
            study_name  => $self->study_name,
            config_base => $self->config_base
        )->is_study_in_file_already == 1
      )
    {
        return $self->default_database_name;
    }

    for my $database_name ( sort keys( %{$self->non_standard_databases} ) ) {
        if (
            Bio::VertRes::Config::RegisterStudy->new(
                database    => $database_name,
                study_name  => $self->study_name,
                config_base => $self->config_base
            )->is_study_in_file_already == 1
          )
        {
            return $database_name;
        }
    }

    return $self->default_database_name;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Bio::VertRes::Config::CommandLine::StudyNameSearch - Prevent a study name from being registered in two different databases

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

Prevent a study name from being registered in two different databases.
   use Bio::VertRes::Config::CommandLine::StudyNameSearch;

   my $obj = Bio::VertRes::Config::CommandLine::StudyNameSearch->new(
     default_database_name => 'pathogen_rnd_track', 
     config_base => $destination_directory,
     study_name => 'Unseen study'
     );
   $obj->get_study_database_name_or_default_if_not_found;

=head1 METHODS

=head2 get_study_database_name_or_default_if_not_found

Lookup the study name in all the standard databases. If its found then return that database. If its a new study return the default.

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
