package Bio::VertRes::Config::Pipelines::Import;

# ABSTRACT: A class for generating the Import pipeline config file


use Moose;
use Bio::VertRes::Config::Pipelines::Common;
extends 'Bio::VertRes::Config::Pipelines::Common';

has 'pipeline_short_name' => ( is => 'ro', isa => 'Str', default => 'import' );
has 'module'              => ( is => 'ro', isa => 'Str', default => 'VertRes::Pipelines::Import_iRODS_fastq' );
has 'toplevel_action'      => ( is => 'ro', isa => 'Str', default => '__VRTrack_Import__' );

has '_mpsa_limit'         => ( is => 'ro', isa => 'Int', default => 500 );

override 'to_hash' => sub {
    my ($self) = @_;
    my $output_hash = super();
    $output_hash->{mpsa_limit} = $self->_mpsa_limit;
    $output_hash->{data}{exit_on_errors} = 0;

    return $output_hash;
};

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Bio::VertRes::Config::Pipelines::Import - A class for generating the Import pipeline config file

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

A class for generating the Import pipeline config file
   use Bio::VertRes::Config::Pipelines::Import;

   my $pipeline = Bio::VertRes::Config::Pipelines::Import->new(database => 'abc');
   $pipeline->to_hash();

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
