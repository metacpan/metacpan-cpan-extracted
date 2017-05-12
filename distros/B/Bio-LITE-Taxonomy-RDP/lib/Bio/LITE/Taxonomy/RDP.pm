package Bio::LITE::Taxonomy::RDP;

=head1 NAME

Bio::LITE::Taxonomy::RDP - Lightweight and efficient RDP taxonomic manager

=head1 SYNOPSIS

  use Bio::LITE::Taxonomy::RDP;

  my $taxRDP = Bio::LITE::Taxonomy::RDP->new (
                                              bergeyXML => "/path/to/BergeyTrainingTree.xml",
                                             );

  my  @tax = $taxRDP->get_taxonomy (22075);

  my $level = $taxRDP->get_level_from_name("Bacillaceae 1");



=head1 DESCRIPTION

This module provides easy and efficient access to the RDP taxonomy with minimal dependencies and without intermediary databases.

This module is not part of the Bioperl bundle.

=head1 SEE ALSO

L<Bio::Taxonomy>

L<Bio::Taxonomy::NCBI>

=head1 AUTHOR

Miguel Pignatelli

Any comments or suggestions should be addressed to emepyc@gmail.com

=head1 LICENSE

Copyright 2009 Miguel Pignatelli, all rights reserved.

This library is free software; you may redistribute it and/or modify it under the same terms as Perl itself.

=cut

use strict;
use warnings;
use Carp qw/croak/;
use XML::Simple qw(:strict);

use Bio::LITE::Taxonomy;

#if (do {(sprintf "%vd",$^V) =~ /5\.(\d\d)/; $1}  >= 10}) {
#    import base qw(Taxonomy);
#} else {
#    import parent qw(Taxonomy);
#}
use base qw(Bio::LITE::Taxonomy);

our $VERSION = 0.03;

sub new
  {
    my ($class,%args) = @_;
    my %opts;

    defined $args{'bergeyXML'} or croak "Need the file bergeyTrainingTree.xml";

    $opts{bergeyXML} = $args{bergeyXML};
    my $self = bless \%opts, $class;
    $self->_build_taxonomy();
    return $self;
  }

sub _build_taxonomy
  {
    my ($self) = @_;
    my $bergeysXML = $self->{bergeyXML};
    my $xmlfh;
    if ((UNIVERSAL::isa($bergeysXML, 'GLOB')) or (ref \$bergeysXML eq 'GLOB')) {
      $xmlfh = $bergeysXML;  # Note: Check permissions
    } else {
      open $xmlfh, "<", $bergeysXML or croak $!;
    }
    my @bergeysxml = <$xmlfh>;
    my $bergeysTree = XMLin(
                            (shift @bergeysxml && join "", ("<tree>",@bergeysxml,"</tree>")), # bergeysXML is not a comformant XML file
                            ForceArray => 0,
                            KeyAttr => ["taxid"]
                           );

    $self->_parse_tree($bergeysTree);
    close($xmlfh) unless ((UNIVERSAL::isa($bergeysXML, 'GLOB')) or (ref \$bergeysXML eq 'GLOB'));
  }


sub _parse_tree
    {
      my ($self, $bergeysTree) = @_;

      my %names;
      my %allowed_levels;

      for my $taxid (keys %{$bergeysTree->{TreeNode}}) {
        $bergeysTree->{TreeNode}->{$taxid}->{parent} = $bergeysTree->{TreeNode}->{$taxid}->{parentTaxid};
        $bergeysTree->{TreeNode}->{$taxid}->{level}  = $bergeysTree->{TreeNode}->{$taxid}->{rank};
        delete @{$bergeysTree->{TreeNode}->{$taxid}}{qw/parentTaxid rank leaveCount genusIndex/};
        $bergeysTree->{TreeNode}->{$taxid}->{name} =~ s/"//g;
        $bergeysTree->{TreeNode}->{$taxid}->{name} = "root" if ($bergeysTree->{TreeNode}->{$taxid}->{name} eq "Root");
        $names{$bergeysTree->{TreeNode}->{$taxid}->{name}} = $taxid;
        $allowed_levels{$bergeysTree->{TreeNode}->{$taxid}->{level}} = 1;
      }
      $self->{nodes} = $bergeysTree->{TreeNode};
      $self->{names} = { %names };
      $self->{allowed_levels} = { %allowed_levels };
    }

    1;
