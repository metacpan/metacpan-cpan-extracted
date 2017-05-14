package Bio::VertRes::Config::Recipes::Roles::Reference;
# ABSTRACT: Attributes for working with references


use Moose::Role;

has 'reference'             => ( is => 'ro', isa => 'Str', required => 1 );
has 'reference_lookup_file' => ( is => 'ro', isa => 'Str', required => 1 );

no Moose;
1;

__END__

=pod

=head1 NAME

Bio::VertRes::Config::Recipes::Roles::Reference - Attributes for working with references

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

Attributes for working with references

   with 'Bio::VertRes::Config::Recipes::Roles::Reference';

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
