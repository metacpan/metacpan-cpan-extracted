package Bio::VertRes::Config::Pipelines::Roles::MultiplePrefix;
# ABSTRACT: Moose Role for where you want different prefixes to allow you to run the same pipeline multiple times on the same data


use Moose::Role;

override 'prefix' => sub {
  my ($self) = @_;
  join('_',('',time(),int(rand(9999)),''));
};

no Moose;
1;

__END__

=pod

=head1 NAME

Bio::VertRes::Config::Pipelines::Roles::MultiplePrefix - Moose Role for where you want different prefixes to allow you to run the same pipeline multiple times on the same data

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

Moose Role for where you want different prefixes to allow you to run the same pipeline multiple times on the same data. For example with mapping, bam improvement, rna seq

   with 'Bio::VertRes::Config::Pipelines::Roles::MultiplePrefix';

=head1 METHODS

=head2 prefix

Creates a timestamped prefix with a random number at the end to reduce the probablity of collisions.

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
