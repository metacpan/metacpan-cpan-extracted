package Bio::LITE::Taxonomy::NCBI;

=head1 NAME

Bio::LITE::Taxonomy::NCBI - Lightweight and efficient NCBI taxonomic manager

=head1 SYNOPSIS

 use Bio::LITE::Taxonomy::NCBI;

 my $taxDB = Bio::LITE::Taxonomy::NCBI->new (
                                             db=>"NCBI",
                                             names=> "/path/to/names.dmp",
                                             nodes=>"/path/to/nodes.dmp"
                                            );

 my $tax = $taxDB->get_taxonomy(1442); # 1442 is a Taxid
 my $taxid = $taxDB->get_taxid_from_name("Bacteroidetes");
 my $term = $taxDB->get_term_at_level(1442,"family");

 my $taxDB2 = Bio::LITE::Taxonomy::NCBI-> new (
                                               db=>"NCBI",
                                               names=> "/path/to/names.dmp",
                                               nodes=>"/path/to/nodes.dmp",
                                               dict=>"/path/to/dictionary/file",
                                              );
 my $tax2 = $taxDB2->get_taxonomy_from_gi(12553);

 # Methods from Bio::LITE::Taxonomy::NCBI::Gi2taxid
 # can also be called directly:

 my $taxid2 = $taxDB2->get_taxid(12553);


=head1 DESCRIPTION

This module provides easy and efficient access to the NCBI taxonomy with minimal dependencies and without intermediary databases.

This module is not part of the Bioperl bundle. For bioperl alternatives see the L</"SEE ALSO"> section of this document.

=head1 CONSTRUCTOR

=head2 C<new (%ARGS)>

Creates a Bio::LITE::Taxonomy::NCBI object.

The following parameters are needed

=over 4

=item names

The location of the I<names.dmp> file. Filehandles are also allowed. I<Mandatory>.

=item nodes

The location of the I<nodes.dmp> file. Filehandles are also allowed. I<Mandatory>.

=item synonyms

An array reference listing the categories of synonymous names made available to methods C<get_taxid_from_name> and C<get_taxonomy_from_name>. This parameter is optional and set to C<['synonym']> by default.

As of May 2015, meaningful values are: I<acronym>, I<anamorph>, I<authority>, I<blast name>, I<common name>, I<equivalent name>, I<genbank acronym>, I<genbank anamorph>, I<genbank common name>, I<genbank synonym>, I<in-part>, I<includes>, I<misnomer>, I<misspelling>, I<synonym>, I<teleomorph>, I<type material>.

 my $taxDB = Bio::LITE::Taxonomy::NCBI->new (
                                             db=>"NCBI",
                                             names=> "/path/to/names.dmp",
                                             nodes=>"/path/to/nodes.dmp",
                                             synonyms=>['anamorph','teleomorph','synonym']
                                            );

=item dict

You can query the tree using C<GI>s directly instead of C<Taxid>s. For doing this, you should provide the NCBIs GI to Taxid mapper in binary format as explained in L<Bio::LITE::Taxonomy::NCBI::Gi2taxid>. I<Optional>

=item save_mem

Use this option to avoid to load the binary dictionary (GI to Taxid) into memory. This will save almost 1GB of system memory but looking up for Taxids will be ~20% slower. This parameter is optional, only makes sense if you are using the C<GI> to C<Taxid> dictionary and is I<off> by default.

=back

=head1 METHODS

This module inherits from L<Bio::LITE::Taxonomy> so all the methods explained there are accessible.
These methods are also available:

=over 4

=item get_taxonomy_from_gi

Accepts a C<GI> as input and returns an array with its ascendants ordered from top to bottom.

  my @tax = $tax->get_taxonomy_from_gi($gi);
  print "$_\n" for (@tax);

If called in scalar context, returns an array reference instead of the array.
See L<Bio::LITE::Taxonomy>::get_taxonomy

=item get_taxonomy_with_levels_from_gi

The same as get_taxonomy_from_gi but instead of getting the ascendants returns an array of array references. Each array reference has the ascendant and its taxonomic level (at positions 0 and 1 respectively). This is simpler than it sounds. Check L<Bio::LITE::Taxonomy>::get_taxonomy_with_levels for more information.

If called in scalar context, returns an array reference instead of the array.

=item get_term_at_level_from_gi

Given a gi and a taxonomic level as input, returns the taxon. For example,

  my $taxon = $tax->get_term_at_level_from_gi($gi,"family");

See L<Bio::LITE::Taxonomy>::get_term_at_level.

=back

=head1 SEE ALSO

L<Bio::Gi2taxid> - Module to convert NCBIs GIs to Taxids

L<Bio::LITE::Taxonomy>

L<Bio::Taxonomy::RDP>

L<Bio::DB::Taxonomy::*> - Bioperl alternative for NCBI taxonomies.


=head1 AUTHOR

Miguel Pignatelli
Any comments or suggestions should be addressed to emepyc@gmail.com

=head1 CONTRIBUTORS

Denis Baurain (denis.baurain -AT- ulg.ac.be) 

=head1 LICENSE

Copyright 2015 Miguel Pignatelli, all rights reserved.

This library is free software; you may redistribute it and/or modify it under the same terms as Perl itself.

=cut

use strict;
use warnings;
use Carp qw/croak/;

#use Bio::LITE::Taxonomy;
#if (do {(sprintf "%vd",$^V) =~ /5\.(\d\d)/; $1}  >= 10}) {
#    import base qw(Taxonomy);
#} else {
#	 import parent qw(Taxonomy);
#}
use base qw(Bio::LITE::Taxonomy);

our $VERSION = 0.1;

use constant FS => '\t\|\t';
use constant RS => '\t\|\n';

sub new {
  my ($class,%args) = @_;
  my %opts;

  defined $args{'nodes'} or croak "Need the file nodes.dmp";
  defined $args{'names'} or croak "Need the file names.dmp";

  @opts{qw/nodesFile namesFile synList/} = @args{qw/nodes names synonyms/};
  my $self = bless \%opts, $class;
  $self->_build_taxonomy();
  if (defined $args{dict}) {
    require Bio::LITE::Taxonomy::NCBI::Gi2taxid;
    $self->{dict} = Bio::LITE::Taxonomy::NCBI::Gi2taxid->new(dict=>$args{dict},save_mem=>$args{save_mem} || 0);
  }
  return $self;
}

sub _build_taxonomy {
  my ($self) = @_;
  my $nodesFile = $self->{nodesFile};
  my $tax;
  if ((UNIVERSAL::isa($nodesFile, 'GLOB')) or (ref \$nodesFile eq 'GLOB')) {
    $tax = $nodesFile;
  } else {
    open $tax, "<", $nodesFile or croak "$!";
  }
  while (<$tax>){
    chomp;
    $self -> _create_node(_parse_tax_rec($_));
  }
  $self -> _name_nodes();
  close $tax unless ((UNIVERSAL::isa($nodesFile, 'GLOB')) or (ref \$nodesFile eq 'GLOB'));
}

sub _create_node {
  my ($self,$node,$parent,$level) = @_;
  $self->{allowed_levels}{$level} = 1 if (! defined $self->{allowed_levels}{$level});
  @{$self->{nodes}->{$node}}{qw/parent level/} = ($parent,$level);
}

sub _name_nodes {
  my ($self) = @_;
  my $namesFile = $self->{namesFile};
  my $nodesNames;
  if ((UNIVERSAL::isa($namesFile, 'GLOB')) or (ref \$namesFile eq 'GLOB')) {
    $nodesNames = $namesFile;
  } else {
    open $nodesNames, "<", $namesFile or croak $!;
  }
  my %wanted = map { $_ => 1 } @{$self->{synList} // ['synonym']};
  while (<$nodesNames>){
    chomp;
    my ($taxId,$taxName,$comment) = _process_tax_name ($_);
    if ($comment eq 'scientific name'){
      ${$self->{nodes}->{$taxId}}{name} = $taxName;
      $self->{names}->{$taxName} = $taxId;
    } elsif ($wanted{$comment}) {
      $self->{names}->{$taxName} = $taxId;
    }
  }
  close $nodesNames;
}

sub _parse_tax_rec {
  my $line = shift @_;
  return (split FS,$line)[0,1,2];
}


sub _process_tax_name {
  my $line = shift @_;
  my @fields = split FS, $line;
  $fields[3] =~ s/\t\|$//;
  return ($fields[0],$fields[1],$fields[3]);
}

sub get_taxonomy_from_gi {
  my ($self,$gi) = @_;
  croak "Undefined GI\n" unless (defined $gi);
  my $taxid = $self->{dict}->get_taxid($gi);
  return $self->get_taxonomy($taxid);
}

sub get_taxonomy_with_levels_from_gi {
  my ($self,$gi) = @_;
  croak "Undefined GI\n" unless (defined $gi);
  my $taxid = $self->{dict}->get_taxid($gi);
  return $self->get_taxonomy_with_levels($taxid);
}

sub get_term_at_level_from_gi {
  my ($self,$gi,$level) = @_;
  croak "Undefined GI\n" unless (defined $gi);
  croak "Undefined Level\n" unless (defined $level);
  my $taxid = $self->{dict}->get_taxid($gi);
  return $self->get_term_at_level($taxid,$level);
}

# Note: Use methods in Gi2taxid as if they were from here
sub AUTOLOAD {
  my ($self,$args) = @_;
  our $AUTOLOAD;
  my $method = $AUTOLOAD;
  $method =~ s/.*:://;
  $self->{dict}->can($method) or croak "$method not defined in package __PACKAGE__\n";
  return $self->{dict}->$method($args);
}

# Needed to dont call AUTLOAD on object destruction
sub DESTROY     { }

1;
