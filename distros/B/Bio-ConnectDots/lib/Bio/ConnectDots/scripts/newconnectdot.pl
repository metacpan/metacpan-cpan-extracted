#!/usr/bin/perl

use Carp;
use Getopt::Long;
use Bio::ConnectDots::Config;
use Bio::ConnectDots::DB;
use Bio::ConnectDots::ConnectDots;
use Class::AutoClass::Args;
use strict;

my $cmd_line="$0 @ARGV";
my($HELP,$VERBOSE,$ECHO_CMD,$DATABASE,$HOST,$USER,$PASSWORD,$LOADDIR,$LOADSAVE,$CREATE,$JUST_CREATE,$DATADIR);

GetOptions ('help' => \$HELP,
 	    'verbose' => \$VERBOSE,
	    'X|echo' => \$ECHO_CMD,
	    'database=s'=>\$DATABASE,
            'db=s'=>\$DATABASE,
            'host=s'=>\$HOST,
            'user=s'=>\$USER,
            'password=s'=>\$PASSWORD,
	    'loaddir=s'=>\$LOADDIR,
	    'loadsave=s'=>\$LOADSAVE,
	    'create'=>\$CREATE,
	    'just_create'=>\$JUST_CREATE,
	    'datadir=s'=>\$DATADIR,
	   ) and !$HELP or die <<USAGE;
Usage: $0 [options] 

Benchmark connect-the-dots queries

Options
-------
   --help		Print this message
   --verbose		(for testing)
   -X or --echo		Echo command line (for testing and use in scripts)
  --database            Postgres database (default: --user)
  --db                  Synonym for --database
  --host                Postgres database (default: socks)
  --user                Postgres user (default: ngoodman)
  --password            Postgres password (default: undef)
  --loaddir             Directory for load files (default: /tmp/user_name)
  --loadsave            Specifies whether to save load files
                        Options: 'none', 'last', 'all'. Default: 'all'
  --create              Create table base_c needed for DotTable queries
  --just_create         Create base_c and exit
  --datadir             Directory storing the database files to parse [REQUIRED!]

Options may be abbreviated.  Values are case insenstive.

USAGE
;
print "$cmd_line\n" if $ECHO_CMD;
$DATADIR or $DATADIR = '/local/www/connectdot_datasource';

##############################################################################
###load all the public database
##############################################################################
print "### load all the public databases\n";

#load unigene, takes 7-9 hrs at least for 3 species
system "perl load.pl ../ConnectorSet/Unigene.cnf $DATADIR/Unigene.data";

#load locuslink, takes 60min
system "perl load.pl ../ConnectorSet/LocusLink.cnf $DATADIR/LL_tmpl";

#load Uniprot, takes ??? time (>6hrs)
system "perl load.pl ../ConnectorSet/Uniprot.cnf $DATADIR/uniprot_sp_tr.dat";

#load IPI (human, mouse and rat, take about 30min)
system "perl load.pl ../ConnectorSet/IPI.cnf $DATADIR/IPIall.dat";

#load EPconDBhumanchip1
system "perl load.pl ../ConnectorSet/EPconDBhumanchip1.cnf $DATADIR/RAD_HumanPanc1_ChipDump_20040130.txt";

#load EPconDBmousechip5
system "perl load.pl ../ConnectorSet/EPconDBmousechip5.cnf $DATADIR/RAD_Panc5_ChipDump_DoTS_rel9_20040621.txt";

#load homologGene
system "perl load.pl ../ConnectorSet/homologene.cnf $DATADIR/homologene.homemadeinfile";

#load affy chips
system "perl load.pl ../ConnectorSet/HG_U133A_2_annot_csv.cnf $DATADIR/HG-U133A_2_annot_csv";

system "perl load.pl ../ConnectorSet/HG_Focus_annot_csv.cnf $DATADIR/HG-Focus_annot_csv";

system "perl load.pl ../ConnectorSet/HG_U133A_annot_csv.cnf $DATADIR/HG-U133A_annot_csv";

system "perl load.pl ../ConnectorSet/HG_U133B_annot_csv.cnf $DATADIR/HG-U133B_annot_csv";

system "perl load.pl ../ConnectorSet/HG_U133_Plus_2_annot_csv.cnf $DATADIR/HG-U133_Plus_2_annot_csv";

system "perl load.pl ../ConnectorSet/HG_U95Av2_annot_csv.cnf $DATADIR/HG_U95Av2_annot_csv";

system "perl load.pl ../ConnectorSet/MG_U74Av2_annot_csv.cnf $DATADIR/MG_U74Av2_annot_csv";

system "perl load.pl ../ConnectorSet/MG_U74Bv2_annot_csv.cnf $DATADIR/MG_U74Bv2_annot_csv";

system "perl load.pl ../ConnectorSet/MG_U74Cv2_annot_csv.cnf $DATADIR/MG_U74Cv2_annot_csv";

system "perl load.pl ../ConnectorSet/Mouse430_2_annot_csv.cnf $DATADIR/Mouse430_2_annot_csv";

system "perl load.pl ../ConnectorSet/Mouse430A_2_annot_csv.cnf $DATADIR/Mouse430A_2_annot_csv";

system "perl load.pl ../ConnectorSet/Mu11KsubA_annot_csv.cnf $DATADIR/Mu11KsubA_annot_csv";

system "perl load.pl ../ConnectorSet/Mu11KsubB_annot_csv.cnf $DATADIR/Mu11KsubB_annot_csv";

system "perl load.pl ../ConnectorSet/RG_U34A_annot_csv.cnf $DATADIR/RG_U34A_annot_csv";

system "perl load.pl ../ConnectorSet/RG_U34B_annot_csv.cnf $DATADIR/RG_U34B_annot_csv";

system "perl load.pl ../ConnectorSet/RG_U34C_annot_csv.cnf $DATADIR/RG_U34C_annot_csv";

# load ENZYME, usually takes ~1 minute
system "perl load.pl ../ConnectorSet/ENZYME.cnf $DATADIR/enzyme.dat";

# load OMIM (~3 minutes)
system "perl load.pl ../ConnectorSet/OMIM.cnf $DATADIR/omim.txt";

# load DoTS (~1 minute)
# cat humDoTS_rel8_LL2DoTS musDoTS_rel8_LL2DoTS > DoTS_hum_mus.txt
system "perl load.pl ../ConnectorSet/DoTS.cnf $DATADIR/DoTS_hum_mus.txt";

# load GOA
system "perl load.pl ../ConnectorSet/GOA.cnf $DATADIR/gene_association.goa_all";



