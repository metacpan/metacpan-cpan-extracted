package Bio::MLST::FilterAlleles;
# ABSTRACT: Filter Alleles
$Bio::MLST::FilterAlleles::VERSION = '2.1.1706216';

use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(only_keep_alleles is_metadata);

# A list of column headings in a profile file which
# can be assumed not to be allele names.  If this list
# gets much longer we should have a rethink about
# getting a whitelist of alleles either based on the
# contents of the alleles directory or from the
# config file downloaded from the internet.
my @allele_blacklist = (
  'CC',
  'Lineage',
  'ST',
  'clonal_complex',
  'mlst_clade',
  'species'
);

sub is_metadata
{
  my ($column_heading) = @_;
  if(defined($column_heading))
  {
     return grep( /^$column_heading$/, @allele_blacklist );
  }
  else
  {
     return 0;
  }
}

sub only_keep_alleles
{
  my ($alleles) = @_;
  my @alleles_to_keep = ();
  for my $allele (@$alleles) {
    push( @alleles_to_keep, $allele ) unless is_metadata($allele);
  }
  return \@alleles_to_keep;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::MLST::FilterAlleles - Filter Alleles

=head1 VERSION

version 2.1.1706216

=head1 SYNOPSIS

FilterAlleles.pm - Filter header row  from profile to remove non-alleles

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
