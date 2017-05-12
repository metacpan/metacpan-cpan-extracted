# -*- Mode: perl -*-
# file: GeneSubs.pm
# Some URL constants useful for molecular biology

package Ace::Browser::GeneSubs;
use strict 'vars';
use vars qw/@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS/;

require Exporter;
@ISA = Exporter;

@EXPORT = qw(ENTREZ ENTREZP PROTEOME SWISSPROT PUBMED NCBI);
@EXPORT_OK = ();
%EXPORT_TAGS = ();

# Foreign URLs
use constant ENTREZ      => 'http://www.ncbi.nlm.nih.gov:80/entrez/query.fcgi?cmd=Search&db=Nucleotide&doptcmdl=GenBank&term=';
use constant ENTREZP     => 'http://www.ncbi.nlm.nih.gov:80/entrez/query.fcgi?cmd=Search&db=Protein&doptcmdl=GenPep&term=';
use constant NCBI        => 'http://www.ncbi.nlm.nih.gov/htbin-post/Entrez/query';
use constant PROTEOME    => 'http://www.proteome.com/WormPD/';
use constant SWISSPROT   => 'http://www.ncbi.nlm.nih.gov/htbin-post/Entrez/query?db=p&form=1&field=Sequence+ID&term=';
use constant PUBMED      => 'http://www.ncbi.nlm.nih.gov/htbin-post/Entrez/query?db=m&form=4&term=nematode [ORGANISM]+AND+';

1;
