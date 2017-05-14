package Bio::VertRes::Config::Types;

# ABSTRACT: Moose types to use for validation.


use Moose;
use Moose::Util::TypeConstraints;
use Bio::VertRes::Config::Validate::Prefix;
use Bio::VertRes::Config::Validate::File;

subtype 'Bio::VertRes::Config::Prefix', as 'Str', where { Bio::VertRes::Config::Validate::Prefix->new()->is_valid($_) };


subtype 'Bio::VertRes::Config::File',
  as 'Str',
  where { Bio::VertRes::Config::Validate::File->new()->does_file_exist($_) };

no Moose;
no Moose::Util::TypeConstraints;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::VertRes::Config::Types - Moose types to use for validation.

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

Moose types to use for validation.

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
