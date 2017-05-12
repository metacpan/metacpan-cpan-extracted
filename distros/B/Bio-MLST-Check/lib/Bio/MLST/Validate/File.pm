package Bio::MLST::Validate::File;
# ABSTRACT: Check to see if a file exists. For validation when classes have input files.
$Bio::MLST::Validate::File::VERSION = '2.1.1706216';

use Moose;

sub does_file_exist
{
  my($self, $file) = @_;
  return 1 if(-e $file);
  
  return 0;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::MLST::Validate::File - Check to see if a file exists. For validation when classes have input files.

=head1 VERSION

version 2.1.1706216

=head1 SYNOPSIS

Check to see if a file exists. For validation when classes have input files.

=head1 METHODS

=head2 does_file_exist

Check to see if a file exists. For validation when classes have input files.

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
