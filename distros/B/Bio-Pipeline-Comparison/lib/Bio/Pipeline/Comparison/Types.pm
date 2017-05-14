package Bio::Pipeline::Comparison::Types;

# ABSTRACT: Moose types to use for validation


use Moose;
use Moose::Util::TypeConstraints;
use Bio::Pipeline::Comparison::Validate::Executable;

subtype 'Bio::Pipeline::Comparison::Executable',
  as 'Str',
  where { Bio::Pipeline::Comparison::Validate::Executable->new()->does_executable_exist($_) };


no Moose;
no Moose::Util::TypeConstraints;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::Pipeline::Comparison::Types - Moose types to use for validation

=head1 VERSION

version 1.123050

=head1 SYNOPSIS

Moose types to use for validation

=head1 SEE ALSO

=over 4

=item *

L<Bio::Pipeline::Comparison>

=back

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
