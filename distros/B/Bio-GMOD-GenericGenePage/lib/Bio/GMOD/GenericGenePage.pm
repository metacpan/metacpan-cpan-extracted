package Bio::GMOD::GenericGenePage;
use strict;
use warnings;
use English;
use Carp;

our $VERSION = 0.12;


=head1 NAME

Bio::GMOD::GenericGenePage - Generic GMOD gene page base class

=head1 SYNOPSIS

    my $page = Bio::GMOD::GenericGenePage->new( $gene_identifier );
    my $xml = $page->render_xml();

=head1 DESCRIPTION

Bio::GMOD::GenericGenePage is an abstract class to make it easier for 
Model Organism Databases (MODs) to serve up a simple XML that describes
attributes of their gene models.  In order to implement this, the user
needs to subclass Bio::GMOD::GenericGenePage and provide the methods
listed below as abstract classes.  These methods are then used by
the render_xml method to create XML for a given gene.

There is one example implementation included with this distribution,
Bio::GMOD::GenericGenePage::Chado, which is a Chado adapter for a 
yeast database derived from SGD's GFF3.  In order to implement this for
another Chado database it should be fairly easy to modify the provided
methods to create your own adaptor.  For example, ParameciumDB could
subclass Bio::GMOD::GenericGenePage::Chado and create
Bio::GMOD::GenericGenePage::Chado::ParameciumDB and only override
the data_provider and organism methods to have a working adaptor.
Databases not based on Chado will only have slightly more work, in order
to implement all of the abstract classes in Bio::GMOD::GenericGenePage.

Another example implementation is included, CXGN::Phenome::GenericGenePage,
however this is only a partial implementation and will not work with 
the current release of Bio::GMOD::GenericGenePage.

=head1 BASE CLASS(ES)

none

=head1 SUBCLASSES

Bio::GMOD::GenericGenePage::Chado
CXGN::Phenome::GenericGenePage

=head1 BUGS AND SUPPORT

Please report bugs and make support requests on the GMOD developers list, 
gmod-devel@lists.sourceforge.net.

=head1 AUTHOR

    Scott Cain
    CPAN ID: SCAIN
    Cold Spring Harbor Laboratory
    scain@cpan.org
    http://www.gmod.org/

and Robert Buels.

=head1 COPYRIGHT

Copyright (c) 2008 Scott Cain and Robert Buels.  All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=head1 PROVIDED METHODS

=cut

=head2 new

  Usage: my $genepage = MyGenePage->new( -id => $gene_identifier );
  Desc : create a new gene page object.  should be overridden
  Args : not specified
  Ret  : a new gene page object
  Side Effects: none as implemented here, but subclass
                implementations may have side effects
  Example:

=cut

sub new {
  my ($class,%args) = @_;
  return bless {}, $class;
}

sub _counter {
  my $self = shift;
  $self->{'counter'}++;
  return $self->{'counter'};
}

=head2 render_xml

  Usage: my $xml = $page->render_xml();
  Desc : render the XML for this generic gene page
  Args : none
  Ret  : string of xml
  Side Effects: none

=cut

sub render_xml {
  my ($self) = @_;

  my $data_provider = "  <data_provider>".$self->data_provider."</data_provider>\n";

  my @accs = $self->accessions;
  my $accession  = join "\n", map {
    qq|  <accession>$_</accession>|
  } @accs;


  my $name = $self->name;

  my @syn = $self->synonyms;
  #shift @syn; #should the real name be in there too?
  #I don't think so--querying the synonym table is easy, why bother with
  #a join when we don't need it

  #also, synonym should probably be a hash to optionally allow for a 
  #synonym type

  my $synonyms = join "\n", map {
    qq|  <name type="synonym">$_</name>|
  } @syn;

  my $dbreferences   = $self->_xml_render_colon_separated_dbrefs( 2, $self->dbxrefs);
  my $organism       = $self->_xml_render_organism();
  my $ontology_terms = $self->_xml_render_ontology_terms( 4, $self->ontology_terms);
  my $literature     = $self->_xml_render_colon_separated_dbrefs( 4, $self->literature_references);

  my $maplocations = join "\n", map {
    qq|    <mapLocation map="$_->{map_name}" chromosome="$_->{chromosome}" position="$_->{position}" units="$_->{units}" />|
  } $self->map_locations;

  my $comments       = $self->_xml_render_comments($self->comments);

  return <<EOXML;
<gene>
$data_provider
$accession

  <name type="primary">$name</name>

$synonyms

$dbreferences

$organism

  <mapLocations>
$maplocations
  </mapLocations>

  <ontology>
$ontology_terms
  </ontology>

  <literature>
$literature
  </literature>

$comments

</gene>
EOXML
}

sub _xml_render_organism {
  my $self = shift;
  my $counter = $self->_counter;
  my $org = $self->organism;
  my $organism = <<END;
  <organism>
    <name type="common">$org->{common}</name>
    <name type="scientific">$org->{binomial}</name>
    <dbReference type="NCBI Taxonomy" key="$counter" id="$org->{ncbi_taxon_id}" />
  </organism>
END
  return $organism;
}

sub _xml_render_colon_separated_dbrefs {
  my ($self,$spaces,@refs) = @_;
  my $refstring = '';
  for my $ref (@refs) {
    my $counter = $self->_counter;
    my ($type,$id) = split /:/,$ref,2;
    $refstring .= (' 'x$spaces).qq|<dbReference type="$type" key="$counter" id="$id" />\n|
  }
  return $refstring;
}

sub _xml_render_ontology_terms {
  my ($self,$spaces,%term) = @_;
 
  my $xml_string = ''; 
  for my $key (keys %term) {
      my ($type,$id) = split /:/,$key;
      my $value = $term{$key};
      my $counter = $self->_counter;

      # the low casing of the 'o' seems inconsistent, so go with the upper
      #$type = "Go" if ($type eq "GO");
      $xml_string .= (' 'x$spaces).qq|<dbReference type="$type" key="$counter" id="$key">\n|; 
      $xml_string .= (' 'x($spaces+2)).qq|<property value="$value" type="term"/>\n|;
      $xml_string .= (' 'x$spaces).qq|</dbReference>\n|;
  }
  return $xml_string;
}

sub _xml_render_comments {
  my ($self, %comments) = @_;

  my $xml_string = '';

  for my $key (keys %comments) {
    my $value = $comments{$key} || "miscellaneous";
    $xml_string .= "  <comment type=\"$value\">\n";
    $xml_string .= "    <text>$key</text>\n";
    $xml_string .= "  </comment>\n\n"; 
  }

  return $xml_string;
}

=head2 render_html NOT IMPLEMENTED!

  Usage: my $html = $page->render_html();
  Desc : render HTML for this generic gene page.  you may want to
         override this method for your implementation
  Args : none
  Ret  : string of html
  Side Effects: none

=cut

sub render_html {
  my ($self) = @_;

  return <<EOHTML;

EOHTML
}

#helper method that calls all those functions
sub _info {
  my ($self) = @_;

  return
    { name => $self->name,
      syn  => [$self->synonyms],
      loc  => [$self->map_locations],
      ont  => [$self->ontology_terms],
      dbx  => [$self->dbxrefs],
      lit  => [$self->lit_refs],
      comments => [$self->comment_text],
      species => $self->species,
    };
}


=head1 ABSTRACT METHODS

Methods below should be overridden by each GenericGenePage implementation.

=head2 name

  Usage: my $name = $genepage->name();
  Desc : get the string name of this gene
  Args : none
  Ret  : string gene name, e.g. 'Pax6'
  Side Effects: none

=cut

sub name {
  my ($self) = @_;
  die 'name() method is abstract, must be implemented in a subclass;'
}

=head2 accessions

  Usage: my @accessions = $genepage->accessions();
  Desc : get a list of local accession values
  Args : none
  Ret  : a list of local accessions
  Side Effects: none

Note that these are the accessions that are used by the MOD providing the
information, not accessions in external databases like GenBank.

=cut

sub accessions {
  my ($self) = @_;
  die 'accession() method is abstract, must be implemented in a subclass;'
}

=head2 data_provider

  Usage: my $data_provider = $genepage->data_provider();
  Desc : The name of the data providing authority (ie, WormBase, SGD, etc)
  Args : none
  Ret  : string, name of the data provider
  Side Effects: none

=cut

sub data_provider {
  my ($self) = @_;
  die 'data_provider() method is abstract, must be implemented in a subclass;'
}


=head2 synonyms

  Usage: my @syn = $genepage->synonyms();
  Desc : get a list of synonyms for this gene
  Args : none

  Ret : list of strings,
        e.g. (  '1500038E17Rik',
                'AEY11',
                'Dey',
                "Dickie's small eye",
                'Gsfaey11',
                'Pax-6',
             )
  Side Effects: none

=cut

sub synonyms {
  my ($self) = @_;
  die 'synonyms() method is abstract, must be implemented in a subclass;'
}

=head2 map_locations

  Usage: my @locs = $genepage->map_locations()
  Desc : get a list of known map locations for this gene
  Args : none
  Ret  : list of map locations, each a hashref as:
         {  map_name => string map name,
            chromosome => string chromosome name,
            marker     => (optional) associated marker name,
            position   => numerical position on the map,
            units      => map units, either 'cm', for centimorgans,
                          or 'b', for bases
         }
  Side Effects: none

=cut

sub map_locations {
  my ($self) = @_;
  die 'map_locations() method is abstract, must be implemented in a subclass;'
}


=head2 ontology_terms

  Usage: my @terms = $genepage->ontology_terms();
  Desc : get a list of ontology terms
  Args : none
  Ret  : hash-style list as:
           termname => human-readable description,
  Side Effects: none
  Example:

     my %terms = $genepage->ontology_terms()

     # and %terms is now
     (  GO:0016711 => 'F:flavonoid 3'-monooxygenase activity',
        ...
     )

Note that the value in that has is the the concatenation of F:, B: or C:
for molecular_function, biological_process, or cellular_component GO terms
respectively.  If the term does not belong to GO, there is no prepended
identifier.

=cut

sub ontology_terms {
  my ($self) = @_;
  die 'go_terms() method is abstract, must be implemented in a subclass'
}

=head2 dbxrefs

  Usage: my @dbxrefs = $genepage->dbxrefs();
  Desc : get a list of database cross-references for info related to this gene
  Args : none
  Ret  : list of strings, like type:id e.g. ('PFAM:00012')
  Side Effects: none

=cut

sub dbxrefs {
  my ($self) = @_;
  die 'dbxrefs() method is abstract, must be implemented in a subclass'
}

=head2 comments

  Usage: my @comments = $genepage->comments();
  Desc : get a list of comments with types
  Args : none
  Ret  : a hash of comment=>type, where type is optional (empty string)
  Side Effects: none

=cut

sub comments {
  my ($self) = @_;
  die 'comments() method is abstract, must be impemented in a subclass';
}


=head2 literature_references

  Usage: my @refs = $genepage->lit_refs();
  Desc : get a list of literature references for this gene
  Args : none
  Ret  : list of literature reference identifers, as type:id,
         like ('PMID:0023423',...)
  Side Effects: none

=cut

sub literature_references {
  my ($self) = @_;
  die 'lit_refs() method is abstract, must be implemented in a subclass'
}


=head2 summary_text

  Usage: my $summary = $page->summary_text();
  Desc : get a text string of plain-English summary text for this gene
  Args : none
  Ret  : string of summary text
  Side Effects: none

=cut

sub summary_text {
  my ($self) = @_;
  die 'summary_text() method is abstract, must be implemented in a subclass'
}

=head2 organism

  Usage: my $species_info = $genepage->organism
  Desc : get a handful of species-related information
  Args : none
  Ret  : hashref as:
         { ncbi_taxon_id => ncbi taxon id, (e.g. 3702),
           binomial      => e.g. 'Arabidopsis thaliana',
           common        => e.g. 'Mouse-ear cress',
         }
  Side Effects: none

=cut

sub organism {
  my ($self) = @_;
  die 'organism() method is abstract, must be implemented in a subclass';
}


1;
# The preceding line will help the module return a true value

