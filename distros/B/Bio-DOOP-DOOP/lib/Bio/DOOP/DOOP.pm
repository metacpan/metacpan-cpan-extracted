package Bio::DOOP::DOOP;

use strict;
use warnings;
use Bio::DOOP::DBSQL;
use Bio::DOOP::Cluster;
use Bio::DOOP::ClusterSubset;
use Bio::DOOP::Sequence;
use Bio::DOOP::SequenceFeature;
use Bio::DOOP::Motif;
use Bio::DOOP::Util::Search;
use Bio::DOOP::Util::Sort;
use Bio::DOOP::Util::Filt;
use Bio::DOOP::Util::Run::Mofext;
use Bio::DOOP::Util::Run::Fuzznuc;
use Bio::DOOP::Util::Run::GeneMerge;
use Bio::DOOP::Graphics::Feature;

=head1 NAME

Bio::DOOP::DOOP - DOOP API main module

=head1 VERSION

Version 1.04

=cut

our $VERSION = '1.04';

=head1 SYNOPSIS

  use Bio::DOOP::DOOP;

  # to connect to the primary database use the parameters in the
  # following example

  $user     = "promoter";
  $pass     = "sql04CP";
  $database = "doop-chordate-1_4"; # latest chordate database
  $database = "doop-plant-1_6";    # latest plant database
  $host     = "bioweb.abc.hu";

  $db = Bio::DOOP::DBSQL->connect($user,$pass,$database,$host);

  # in one line

  $db = Bio::DOOP::DBSQL->connect("promoter", "sql04CP", "doop-choordate-1_4", "bioweb.abc.hu");

=head1 DESCRIPTION

DoOP is a database containing orthologous clusters of promoters from Homo sapiens, 
Arabidopsis thaliana and other organisms. Visit the doop.abc.hu or doopsearch.abc.hu
sites for more information or read the following article.

Endre Barta, Endre Sebestyen, Tamas B. Palfy, Gabor Toth, Csaba P. Ortutay, and Laszlo Patthy
DoOP: Databases of Orthologous Promoters, collections of clusters of orthologous upstream 
sequences from chordates and plants.

Nucl. Acids Res. 2005, Vol 33, Database issue D86-D90

This is a container module for all of the DOOP modules. You can simply use this module 
to access all DOOP objects. For a more detailed help, use the documentation of the individual
objects.

If you would like to connect to the MySQL database of Agricultural Biotechnology Center (www.abc.hu),
use the following syntax.

  $db = Bio::DOOP::DBSQL->connect("promoter", "sql04CP", "doop-choordate-1_4", "bioweb.abc.hu");

=head1 AUTHORS

Tibor Nagy, Godollo, Hungary and Endre Sebestyen, Martonvasar, Hungary

=head1 OBJECTS

=head2 Bio::DOOP::DBSQL

Object for simple SQL queries. Use this to connect to the database.
This is the first module you should use.

=head2 Bio::DOOP::Cluster

Object for the clusters. A cluster is a homologous promoter collection.

=head2 Bio::DOOP::ClusterSubset

Object for different subsets of sequences in a given cluster.

=head2 Bio::DOOP::Sequence

Object for a sequences of a cluster.

=head2 Bio::DOOP::SequenceFeature

Object for the different features of a sequence.

=head2 Bio::DOOP::Motif

Object for the conserved sequence features.

=head2 Bio::DOOP::Util::Search

Module for different search subrutines.

=head2 Bio::DOOP::Util::Sort

Sort an array of array by given conditions.

=head2 Bio::DOOP::Util::Filt

Filter a cluster array by given conditions.

=head2 Bio::DOOP::Util::Run::Mofext

MOFEXT wrapper. MOFEXT is a motif search 
tool developed by Tibor Nagy.

=head2 Bio::DOOP::Util::Run::Fuzznuc

FUZZNUC wrapper. Install EMBOSS to use this.

=head2 Bio::DOOP::Util::Run::GeneMerge

GeneOntology analyzer, based on the program GeneMerge.

=head2 Bio::DOOP::Graphics::Feature

Module for generating a PNG picture of the sequences and features of a cluster.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Tibor Nagy, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
