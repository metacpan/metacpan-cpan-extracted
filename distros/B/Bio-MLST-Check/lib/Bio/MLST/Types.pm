package Bio::MLST::Types;
# ABSTRACT: Moose types to use for validation.
$Bio::MLST::Types::VERSION = '2.1.1706216';

use Moose;
use Moose::Util::TypeConstraints;
use Bio::MLST::Validate::Executable;
use Bio::MLST::Validate::File;
use Bio::MLST::Validate::Resource;

subtype 'Bio::MLST::Executable',
  as 'Str',
  where { Bio::MLST::Validate::Executable->new()->does_executable_exist($_) };

subtype 'Bio::MLST::File',
  as 'Str',
  where { Bio::MLST::Validate::File->new()->does_file_exist($_) };

subtype 'Bio::MLST::Resource',
  as 'Str',
  where { Bio::MLST::Validate::Resource->new()->does_resource_exist($_) };

no Moose;
no Moose::Util::TypeConstraints;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::MLST::Types - Moose types to use for validation.

=head1 VERSION

version 2.1.1706216

=head1 SYNOPSIS

Moose types to use for validation.

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
