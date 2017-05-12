#########
# Author:        aj
# Maintainer:    $Author: zerojinx $
# Created:       2006
# Last Modified: $Date: 2010-11-02 11:57:52 +0000 (Tue, 02 Nov 2010) $
# Id:            $Id: ensembl.pm 688 2010-11-02 11:57:52Z zerojinx $
# Source:        $Source$
# $HeadURL: https://proserver.svn.sourceforge.net/svnroot/proserver/trunk/lib/Bio/Das/ProServer/SourceAdaptor/Transport/ensembl.pm $
#
package Bio::Das::ProServer::SourceAdaptor::Transport::ensembl;

use strict;
use warnings;

use Carp;
use English qw(-no_match_vars);
use Bio::EnsEMBL::Registry;

use base qw(Bio::Das::ProServer::SourceAdaptor::Transport::generic);

our $VERSION  = do { my ($v) = (q$Revision: 688 $ =~ /\d+/mxsg); $v; };

sub init {
  my ($self) = @_;
  $self->{'_species'} = $self->config->{'species'};
  $self->{'_group'}   = $self->config->{'group'};
  $self->_apply_override;
  $self->_load_registry;
  return;
}

sub _load_registry {
  my ($self) = @_;
  if (!$self->config->{'skip_registry'}) {
    Bio::EnsEMBL::Registry->load_registry_from_db(
      -host => 'ensembldb.ensembl.org',
      -user => 'anonymous',
      -verbose => $self->{'debug'} );
  }
  Bio::EnsEMBL::Registry->set_disconnect_when_inactive();
  return;
}

sub _apply_override {
  my ($self) = @_;
  my $dbname = $self->config->{'dbname'};

  if ($dbname) {

    my ($species, $group) = $dbname =~ m/([a-z_]+)_([a-z]+)_\d+/mxs;
    if ($species  eq 'ensembl') {
      $species = 'multi';
    }
    $self->{'_species'} ||= $species;
    $self->{'_group'}   ||= $group;

    if (!$self->{'_species'} || !$self->{'_group'}) {
      croak "Unable to parse database species and group: $dbname";
    }

    $self->{'debug'} && carp sprintf "Overriding database with %s (%s,%s)\n",
                                     $dbname, $self->{'_species'}, $self->{'_group'};

    # This is a map from group names to Ensembl DB adaptors.
    # Taken from Bio::EnsEMBL::Registry
    my %group2adaptor = (
      'blast'   => 'Bio::EnsEMBL::External::BlastAdaptor',
      'compara' => 'Bio::EnsEMBL::Compara::DBSQL::DBAdaptor',
      'core'    => 'Bio::EnsEMBL::DBSQL::DBAdaptor',
      'estgene' => 'Bio::EnsEMBL::DBSQL::DBAdaptor',
      'funcgen' => 'Bio::EnsEMBL::Funcgen::DBSQL::DBAdaptor',
      'haplotype' =>
        'Bio::EnsEMBL::ExternalData::Haplotype::DBAdaptor',
      'hive' => 'Bio::EnsEMBL::Hive::DBSQL::DBAdaptor',
      'lite' => 'Bio::EnsEMBL::Lite::DBAdaptor',
      'otherfeatures' => 'Bio::EnsEMBL::DBSQL::DBAdaptor',
      'pipeline' =>
        'Bio::EnsEMBL::Pipeline::DBSQL::DBAdaptor',
      'snp' =>
        'Bio::EnsEMBL::ExternalData::SNPSQL::DBAdaptor',
      'variation' =>
        'Bio::EnsEMBL::Variation::DBSQL::DBAdaptor',
      'vega' => 'Bio::EnsEMBL::DBSQL::DBAdaptor',
    );

    my $adaptorclass = $group2adaptor{ $self->{'_group'} } || croak 'Unknown database group: '.$self->{'_group'};
    # Creating a new connection will add it to the registry.
    eval "require $adaptorclass" || croak $EVAL_ERROR; ## no critic (BuiltinFunctions::ProhibitStringyEval)
    $adaptorclass->new(
      -host    => $self->config->{'host'}     || 'localhost',
      -port    => $self->config->{'port'}     || '3306',
      -user    => $self->config->{'username'} || 'ensro',
      -pass    => $self->config->{'password'},
      -dbname  => $dbname,
      -species => $self->{'_species'},
      -group   => $self->{'_group'},
    );
  }
  return;
}

sub adaptor {
  my ($self, $species, $group) = @_;
  $species ||= $self->{'_species'} || 'human';
  $group   ||= $self->{'_group'}   || 'core';
  my $dba = Bio::EnsEMBL::Registry->get_DBAdaptor( $species, $group );
  $self->{'debug'} && carp "Got adaptor for $species / $group (".$dba->dbc->dbname.")\n";
  return $dba;
}

sub gene_adaptor {
  my ($self, $species, $group) = @_;
  return $self->adaptor($species, $group)->get_GeneAdaptor();
}

sub slice_adaptor {
  my ($self, $species, $group) = @_;
  return $self->adaptor($species, $group)->get_SliceAdaptor();
}

sub chromosome_by_region { ## no critic
  my ($self, $chr, $start, $end, $species, $group) = @_;
  return $self->slice_adaptor($species, $group)->fetch_by_region('chromosome', $chr, $start, $end);
}

sub chromosomes {
  my ($self, $species, $group) = @_;
  return $self->slice_adaptor($species, $group)->fetch_all('chromosome');
}

sub gene_by_id {
  my ($self, $id, $species, $group) = @_;
  return $self->gene_adaptor($species, $group)->fetch_by_stable_id($id);
}

sub genes {
  my ($self, $species, $group) = @_;
  return $self->gene_adaptor($species, $group)->fetch_all();
}

sub version {
  my ($self) = @_;
  return Bio::EnsEMBL::Registry->software_version();
}

sub last_modified {
  my ($self) = @_;
  my $dbc = $self->adaptor()->dbc();
  my $sth = $dbc->prepare(q(SHOW TABLE STATUS));
  $sth->execute();
  my $server_text = [sort { $b cmp $a } ## no critic
                     keys %{ $sth->fetchall_hashref('Update_time') }
                    ]->[0]; # server local time
  $sth->finish();
  $sth = $dbc->prepare(q(SELECT UNIX_TIMESTAMP(?) as 'unix'));
  $sth->execute($server_text); # sec since epoch
  my $server_unix = $sth->fetchrow_arrayref()->[0];
  $sth->finish();
  return $server_unix;
}

sub disconnect {
  my $self = shift;
  Bio::EnsEMBL::Registry->disconnect_all();
  $self->{'debug'} and carp "$self performed disconnect\n";
  return;
}

1;
__END__

=head1 NAME

Bio::Das::ProServer::SourceAdaptor::Transport::ensembl

=head1 VERSION

$LastChangedRevision: 688 $

=head1 SYNOPSIS

A transport for using the Registry to retrieve Ensembl data.

=head1 DESCRIPTION

This class is a Transport that provides an interface to the Ensembl API. It uses
the Ensembl Resistry to determine the location of the appropriate databases,
and can be used in a species specific or cross-species manner. The main
advantage of using this Transport is that the registry automatically provides
access to the latest data available to the installed API.

=head1 SUBROUTINES/METHODS

=head2 init - Post-construction initialisation.

  $oTransport->init();
  
  Loads the registry from the Ensembl database, and applies a custom database
  override if specified.

=head2 adaptor - Gets an Ensembl adaptor.

  $oAdaptor = $oTransport->adaptor();
  $oAdaptor = $oTransport->adaptor('human', 'core');

  Arguments:
    species        (optional, default configured in INI or 'human')
    database group (optional, default configured in INI or 'core')
  Returns:
    L<Bio::EnsEMBL::DBSQL::DBAdaptor|Bio::EnsEMBL::DBSQL::DBAdaptor>

=head2 slice_adaptor - Gets an Ensembl slice adaptor.
  
  $oAdaptor = $oTransport->slice_adaptor();
  $oAdaptor = $oTransport->slice_adaptor('human', 'core');

  Arguments:
    species        (optional, default configured in INI or 'human')
    database group (optional, default configured in INI or 'core')
  Returns:
    L<Bio::EnsEMBL::DBSQL::SliceAdaptor|Bio::EnsEMBL::DBSQL::SliceAdaptor>

=head2 gene_adaptor - Gets an Ensembl gene adaptor.
  
  $oAdaptor = $oTransport->gene_adaptor();
  $oAdaptor = $oTransport->gene_adaptor('human', 'core');

  Arguments:
    species        (optional, default configured in INI or 'human')
    database group (optional, default configured in INI or 'core')
  Returns:
    L<Bio::EnsEMBL::DBSQL::GeneAdaptor|Bio::EnsEMBL::DBSQL::GeneAdaptor>

=head2 chromosome_by_region - Gets a chromosome slice.

  $oSlice = $oTransport->chromosome_by_region('X');
  $oSlice = $oTransport->chromosome_by_region('X', 123453, 132424);
  $oSlice = $oTransport->chromosome_by_region('X', 123453, 132424, 'human', 'core');
  
  Arguments:
    chromosome #   (required)
    start          (optional)
    end            (optional)
    species        (optional, default configured in INI or 'human')
    database group (optional, default configured in INI or 'core')
  Returns:
    L<Bio::EnsEMBL::Slice|Bio::EnsEMBL::Slice>

=head2 chromosomes - Gets all chromosomes.

  $aSlices = $oTransport->chromosomes();
  $aSlices = $oTransport->chromosomes('human', 'core');
  
  Arguments:
    species        (optional, default configured in INI or 'human')
    database group (optional, default configured in INI or 'core')
  Returns:
    listref of L<Bio::EnsEMBL::Slice|Bio::EnsEMBL::Slice> objects

=head2 gene_by_id - Gets a gene.

  $oGene = $oTransport->gene_by_id('ENSG00000139618'); # BRCA2
  $oGene = $oTransport->gene_by_id('ENSG00000139618', 'human', 'core');
  
  Arguments:
    gene stable ID (required)
    species        (optional, default configured in INI or 'human')
    database group (optional, default configured in INI or 'core')
  Returns:
    L<Bio::EnsEMBL::Gene|Bio::EnsEMBL::Gene>

=head2 genes - Gets all genes.

  $aGenes = $oTransport->genes();
  $aGenes = $oTransport->genes('human', 'core');
  
  Arguments:
    species        (optional, default configured in INI or 'human')
    database group (optional, default configured in INI or 'core')
  Returns:
    listref of L<Bio::EnsEMBL::Gene|Bio::EnsEMBL::Gene> objects

=head2 version - Gets the Ensembl API's release number.

  $sVersion = $oTransport->version();
  
=head2 last_modified - Gets a last modified date from the database.

  $sVersion = $oTransport->version();

=head2 disconnect - ProServer hook to disconnect all connected databases.

  $oTransport->disconnect();

=head1 CONFIGURATION AND ENVIRONMENT

Configured as part of each source's ProServer 2 INI file.

  The transport will automatically load database connection settings from
  the Ensembl Registry at ensembldb.ensembl.org. To skip this, set the
  'skip_registry' INI property.
  
  A specific database may also be overridden using these INI properties:
    dbname
    host     (defaults to localhost)
    port     (defaults to 3306)
    username (defaults to ensro)
    password

  The 'default database' used in the transport's data access methods may be
  configured using these INI properties:
    species  (defaults to human)
    group    (defaults to core)

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item L<Carp|Carp>

=item L<English|English>

=item L<Bio::Das::ProServer::SourceAdaptor::Transport::generic|Bio::Das::ProServer::SourceAdaptor::Transport::generic>

=item Ensembl core API

=item Additional Ensembl APIs if used

=back

=head1 INCOMPATIBILITIES

None reported

=head1 BUGS AND LIMITATIONS

None reported

=head1 REFERENCES

=over

=item L<http://www.ensembl.org/info/software/Pdoc/ensembl/|http://www.ensembl.org/info/software/Pdoc/ensembl/> Ensembl API

=back

=head1 AUTHOR

Andy Jenkinson <andy.jenkinson@ebi.ac.uk>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007 EMBL-EBI
