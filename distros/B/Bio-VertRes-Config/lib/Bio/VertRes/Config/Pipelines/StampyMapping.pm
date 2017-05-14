package Bio::VertRes::Config::Pipelines::StampyMapping;

# ABSTRACT: Base class for the Stampy mapper


use Moose;
extends 'Bio::VertRes::Config::Pipelines::Mapping';

has 'slx_mapper'     => ( is => 'ro', isa => 'Str', default => 'stampy' );
has 'slx_mapper_exe' => ( is => 'ro', isa => 'Str', default => 'python2.7 /software/pathogen/external/apps/usr/local/stampy-1.0.22/stampy.py' );

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Bio::VertRes::Config::Pipelines::StampyMapping - Base class for the Stampy mapper

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

Base class for the Stampy mapper
   use Bio::VertRes::Config::Pipelines::StampyMapping;

   my $pipeline = Bio::VertRes::Config::Pipelines::StampyMapping->new(
     database => 'abc',
     reference => 'Staphylococcus_aureus_subsp_aureus_ABC_v1',
     limits => {
       project => ['ABC study'],
       species => ['EFG']
     },

     );
   $pipeline->to_hash();

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
