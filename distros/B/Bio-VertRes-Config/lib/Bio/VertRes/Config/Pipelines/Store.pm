package Bio::VertRes::Config::Pipelines::Store;

# ABSTRACT: A class for generating the Store pipeline config file which archives data to nfs units


use Moose;
use Bio::VertRes::Config::Pipelines::Common;
extends 'Bio::VertRes::Config::Pipelines::Common';

has 'pipeline_short_name' => ( is => 'ro', isa => 'Str', default => 'stored' );
has 'module'              => ( is => 'ro', isa => 'Str', default => 'VertRes::Pipelines::StoreLane' );
has 'toplevel_action'     => ( is => 'ro', isa => 'Str', default => '__VRTrack_Storing__' );

has '_limit'              => ( is => 'ro', isa => 'Int', default => 100 );

override 'to_hash' => sub {
    my ($self) = @_;
    my $output_hash = super();
    $output_hash->{limit} = $self->_limit;
    $output_hash->{vrtrack_processed_flags} = { qc => 1, stored => 0 };

    return $output_hash;
};

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Bio::VertRes::Config::Pipelines::Store - A class for generating the Store pipeline config file which archives data to nfs units

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

A class for generating the Store pipeline config file
   use Bio::VertRes::Config::Pipelines::Store;

   my $pipeline = Bio::VertRes::Config::Pipelines::Store->new(database => 'abc');
   $pipeline->to_hash();

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
