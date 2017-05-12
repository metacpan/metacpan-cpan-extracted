use CGI 'escape','img';

# here's the root of all our stuff
$ROOT = '/perl/ace/elegans';
$WB   = '/wormbase';  # The root is at the top level

# ========= $NAME =========
# symbolic name of the database (defaults to name of file, lowercase)
$NAME = 'elegans';

# ========= $HOST  =========
# name of the host to connect to
#$HOST = 'brie2.cshl.org';
#$HOST = 'stein.cshl.org';
$HOST = 'localhost';
#$HOST = 'brie.cshl.org';

# ========= $PORT  =========
# Port number to connect to
$PORT = 2005;

# ========= $STYLESHEET =========
# stylesheet to use
$STYLESHEET = "$WB/stylesheets/wormdb.css";

# ========= $PICTURES ==========
# Where to write temporary picture files to:
#   The URL and the physical location, which must be writable
# by the web server.
@PICTURES = ('/ace_images' => '/var/tmp/ace_images');

# This controls at what point the "pic" script should stop making individually-clickable
# elements.
$MAX_IN_COLUMN = 100;

# location of random pictures to display on certain pages
$RANDOM_PICTS = "$WB/random_pic";
$PIC_SCRIPT   = "$ROOT/misc/random_pic";

#========================= WORMBASE-SPECIFIC CONFIGURATION ==================

# ========== An icon to use for "home" ==========
# leaving this undefined suppresses the generation of a "home" link
# $HOME_ICON = "$ICONS/arrows/uarrw.gif";

# =========  An icon to use for searching =======
# leaving this undefined suppresses the generation of a "search" link
# $SEARCH_ICON = "$ICONS/unknown.gif";

# position of the big banner
$BANNERS   = "$WB/banners";
$BANNERS   = "$WB/banners";
@BANNER_SIZE   = (640,56);

# fixed width for the page
$PAGEWIDTH = 660;

# position of the "cross"
$CROSS_ICON = "$WB/images/cross1.gif";
$ARROWR_ICON = "$WB/images/arrow_right.gif";
$ARROWL_ICON = "$WB/images/arrow_left.gif";

# position of neuron diagrams
$NEURON_DIAGRAMS = "$WB/cell/diagrams";

# ======== BLAST DATABASES ===========
# location of BLAST databases
$BLAST_ROOT = '/usr/local/wublast';;
$BLAST_BIN   = "$BLAST_ROOT/bin/";
$BLAST_MATRIX  = "$BLAST_ROOT/matrix";
$BLAST_FILTER  = "$BLAST_ROOT/filter";
$BLAST_DB      = "/usr/local/acedb/elegans/blast";
$BLAST_CUTOFF  = 0.001;
$BLAST_MAXHITS = 20;
@BLAST_default = ('blastp' => 'WormPep');
%BLAST_labels  = ('EST_Elegans' => 'elegans ESTs',
		  'Elegans'     => 'elegans genomic',
		  'WormPep'     => 'WormPep');
%BLAST_ok      = ('blastn'  => [qw/Elegans EST_Elegans/],
		  'tblastn' => [qw/Elegans EST_Elegans/],
		  'blastp'  => [qw/WormPep/],
		  'blastx'  => [qw/WormPep/]
		 );
# ========= $BANNER =========
# Banner HTML
# This will appear at the top of each page. 
$BANNER = 'WormBase';

# ========= $FOOTER =========
# Footer HTML
# This will appear at the bottom of each page
# $FOOTER = img({-src=>"$WORMBASE/images/foot_logo.gif"});
$MY_FOOTER = a({-href=>'http://stein.cshl.org/'},
	       img({-border=>0,-src=>"$WB/images/foot_logo2.gif"})
	      );

# ========= @SEARCHES  =========
# search scripts available
# NOTE: the order is important
@SEARCHES   = (
	       basic => { name      => 'Simple Search',
			   url      => "$ROOT/searches/basic",
			   onimage  => "$WB/buttons/basic_on.gif",
			   offimage => "$WB/buttons/basic_off.gif",
			   #width, height
			   size     => [109,20], },
		 
	       expr_search => { name    => 'Expr. Pattern Search',
			       url      => "$ROOT/searches/expr_search",
			       onimage  => "$WB/buttons/expr_on.gif",
			       offimage => "$WB/buttons/expr_off.gif",
			       size     => [147,20], },
	       
	       hunter => { name      => 'Gene Hunter',
			    url      => "$ROOT/hunter/hunter.cgi",
			    onimage  => "$WB/buttons/hunter_on.gif",
			    offimage => "$WB/buttons/hunter_off.gif",
			    size     => [100,20], },
	       
#	       browser => { name      => 'Class Browser',
#			    url      => "$ROOT/searches/browser",
#			    onimage  => "$WB/buttons/browser_on.gif",
#			    offimage => "$WB/buttons/browser_off.gif",
#			    size     => [100,20], },

	       blast => { name     => 'Blast Search',
			  url      => "$ROOT/searches/blast",
			  onimage  => "$WB/buttons/blast_on.gif",
			  offimage => "$WB/buttons/blast_off.gif",
			  size     => [99,20], },
	       
	       advanced => { name     => 'Advanced Search',
			     url      => "$ROOT/searches/query",
			     onimage  => "$WB/buttons/advanced_on.gif",
			     offimage => "$WB/buttons/advanced_off.gif",
			     size     => [129,20], },
	       
	       atlas => { name     => 'Worm Atlas',
			  url      => "$WB/atlas/atlas.html",
			  onimage  => "$WB/buttons/atlas_on.gif",
			  offimage => "$WB/buttons/atlas_off.gif",
			  size     => [46,20], },
	      );

# ========= %HOME  =========
# Home page URL
@HOME      = (
	      'http://www.wormbase.org' => 'WormBase home'
	     );

@HOME_BUTTON = ("$WB/buttons/home_bottom.gif" => [20,56]);

# ========= %DISPLAYS =========
%DISPLAYS = (
	     gene =>  {'url'   => "$ROOT/gene/locus",
		       'label' => 'Gene Report'},

	     cell =>  {'url'   => "$ROOT/cell/cell.cgi",
		       'label' => 'Cell Summary'},

	     pedigree => {'url'   => "$ROOT/cell/pedigree",
		       'label' => 'Pedigree Browser'},

	     mappingdata => {'url'   => "$ROOT/gene/mapping_data",
			     'label' => 'Map Data'},

	     biblio => {'url'   => "$ROOT/misc/biblio",
			'label' => 'Bibliography'},
	     
	     nearby_genes => {'url'   =>"$ROOT/gene/genetable#pos", 
			     'label' => 'Nearby Genes'},

	     geneapplet    => {'url'   =>"$ROOT/gene/geneapplet", 
			     'label' => 'Interactive Map'},

	     hunter        => {'url'   =>"$ROOT/hunter/hunter.cgi", 
			     'label' => 'Genome Hunter'},

	     sequence => { 'url'   => "$ROOT/seq/sequence",  
			   'label' => 'Sequence Report'},
	     
	     author => { 'url'      => "$ROOT/misc/author",
			 'label'    => 'Author Info'},
	     
	     biblio => {'url'      => "$ROOT/misc/biblio",
			'label'    => 'Bibliography'},

	     clone => {'url'   => "$ROOT/seq/clone",
		       'label' => 'Clone Report'},

	     paper => {'url'   => "$ROOT/misc/paper",
		       'label' => 'Citation'},
	     
	     laboratory => { 'url'   => "$ROOT/misc/laboratory",
			     'label' => 'Lab Listing'},

	     expr_pattern => { 'url'   => "$ROOT/gene/expression",      
			       'label' => 'Expression Pattern'},

	     tree => { 'url'     => "$ROOT/misc/etree",   
		       'label'   => 'Tree Display'},

	     xml => { 'url'     => "$ROOT/misc/xml",   
		       'label'   => 'XML Dump'},

	     pic => { 'url'     => "$ROOT/misc/epic",    
		      'label'   => 'Graphic Display'},

	     align => { 'url'     => "$ROOT/seq/align",    
			'label'   => 'alignment'},
);

# ========= %CLASSES =========
# displays to show
%CLASSES = (	
	     # There are three representations of Locus, in addition to the basic ones
	     Locus     => [ qw/gene mappingdata nearby_genes hunter biblio geneapplet/ ],
     
	     # there are two representations of sequence, in addition to the basic ones
	     Sequence  => [ qw/sequence nearby_genes hunter/ ],
	     
	     # two representations of Author
	     Author => [ qw/author biblio/ ],

	     # one representation of Clone, Paper, Laboratory, and Expr_pattern
	     Clone     => [ 'clone' ],
	     
	     Paper     => [ 'paper' ],

	     Cell      => [ 'cell','pedigree' ],

	     Map       => [ 'pic', 'geneapplet' ],

	     Laboratory     => [ 'laboratory' ],
	     
	     Expr_pattern     => [ 'expr_pattern' ],
	    
	    # default  has special meaning
	     Default => [ qw/tree xml pic/ ],
	   );

# ========= &URL_MAPPER  =========
# mapping from object type to URL.  Return empty list to fall through
# to default.
sub URL_MAPPER {
    my ($display,$name,$class) = @_;
    # Small Ace inconsistency: Models named "#name" should be
    # transduced to Models named "?name"
    $name = "?$1" if $class eq 'Model' && $name=~/^\#(.*)/;
    my $n = escape($name);
    my $c = escape($class);
    my $qs = "name=$n";
    my $qsc = "name=$n&class=$c";

    return (laboratory => $qs)             if $class eq 'Laboratory';
    return (paper => $qs)                  if $class eq 'Paper';
    return (biblio => "$qs&class=Keyword") if $class eq 'Keyword';
    return (clone => $qs )                if $class eq 'Clone';
    return (gene => $qs )                 if $class eq 'Locus';
    return (sequence => $qs )             if $class eq 'Sequence';
    return (expr_pattern => $qs)          if $class eq 'Expr_pattern';
    return (author => $qs )               if $class eq 'Author';
    return (tree => $qsc)                 if $class eq 'Metabolite';
    return (cell => $qs)                  if $class eq 'Cell';

    if ($class eq 'Pathway') {
      return (pic  => $qsc )  if $name =~ /^\*/;
      return (tree => $qsc) if $name !~ /^\*/;
    }
    
    # maps are always displayed graphically by default
    return (pic => $qsc )         if $class =~ /map/i;

    # pictures remain pictures
    return (pic => $qsc )  if $display eq 'pic';
    return (tree => $qsc );
}

# ========= Configuration information for the simple search script
@SIMPLE = ('Any'              => '<i>Anything</i>',
	   'Accession_number' => 'Genbank Accession Number',
	   'Author'           => 'Author',
	   'Cell'             => 'Cell',
	   'Clone'            => 'Clone',
	   'Locus'            => 'Confirmed Gene',
	   'Genetic_map'      => 'Genetic Map',
	   'Predicted_gene'   => 'Predicted Gene',
      	   'Sequence'         => 'Sequence (any)',
	   'Genome_sequence', => 'Sequence (genomic)',
	   'Sequence_map'     => 'Sequence Map',
	   'Strain'           => 'Worm Strain',	  
	  );

# Jalview configuration information
$JALVIEW       =  '/applets/jalview.jar';
$JALVIEW_MAIL  = 'beta.crbm.cnrs-mop.fr';
$JALVIEW_HELP  = 'http://circinus.ebi.ac.uk:6543/jalview/help.html';

# Meow configuration
$MEOW_CONFIRMED = 'http://iubio.bio.indiana.edu/meow/.bin/moquery?dbid=ACEDB:';
$MEOW_PREDICTED = 'http://iubio.bio.indiana.edu/meow/.bin/moquery?dbid=ACEPRED:';

# ========= Configuration information for the feedback script
@FEEDBACK_RECIPIENTS = (
			[ ' Paul Sternberg <pws@its.caltech.edu>'     => 'general complaints and suggestions'=>1 ],
			[ ' Lincoln Stein <lstein@cshl.org>'          => 'user interface' ],
			[ ' Norma Foltz <norma@caltech.edu>'          => 'cells and expression patterns' ],
			[ ' Jonathan Hodgkin & Sylvia Martinelli <cgc@mrc-lmb.cam.ac.uk>'  => 'genetic data; gene names'],
                        [ ' wormbase@caltech.edu '                     => 'gene regulation and interactions' ],
			[ ' Sylvia Martinelli <cgc@mrc-lmb.cam.ac.uk>'  => 'addresses'                        ],
			[ ' Theresa Stiernagle <stier@biosci.cbs.umn.edu>' => 'strains, bibliographic references' ],
                        [ ' Richard Durbin <rd@sanger.ac.uk>'              =>'systematic genome sequence analysis, acedb problems' ],
			[ ' Danielle & Jean Thierry-Mieg <mieg@ncbi.nlm.nih.gov>' => 'gene structures, ESTs and new largescale datasets' ],
			[ ' John Spieth <jspieth@watson.wustl.edu>'              => 'St. Louis sequence annotations; gene structures' ],
			[ ' worm@sanger.ac.uk'                                   => 'Cambridge sequence annotations; gene structures' ],
			[ ' Alan Coulson <alan@sanger.ac.uk> '                   => 'physical map' ],
		       );
@FEEDBACK_CHECKED = (0);  # number zero is paul

# position of the chromosome tables, in URL space
$CHROMOSOME_TABLES = "$WB/chromosomes";
$CHROMOSOME_TABLE_LENGTH = 2_000_000;

# all-important copyright statement
$COPYRIGHT = "$WB/copyright.html";

# ========= transcript script ===========
# dimensions of the transcript picture shown in the sequence screen
@TRANSCRIPT_DIMENSIONS = ($PAGEWIDTH,150);
$TRANSCRIPT_HEIGHT = 10;

# ======== geneapplet script ==========

$JADEX_PORT = 2005;
$JADEX_PATH = '/applets/jadex.jar';
$JADEX_IMAGE = "$WB/images/geneticMapApplet.gif";

# ======== promoter motif search script ==========
$PROMOTER_DB = "$WB/chromosomes/promoters.db";
