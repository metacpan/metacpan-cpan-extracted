# removes the specified connectorset

use Carp;
use lib qw( blib/lib/ ../lib ../../..);
use Getopt::Long;
use File::Path;
use Bio::ConnectDots::DB;
use Bio::ConnectDots::Config;
use strict;

my($HELP,$VERBOSE,$ECHO_CMD,$DATABASE,$HOST,$USER,$PASSWORD,$LOADDIR,$LOADSAVE,$CONNECTORSET,$REMOVEDOTS,$VERSION);

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
	    'connectorset=s'=>\$CONNECTORSET,
	    'removedots=s'=>\$REMOVEDOTS,
	    'version=s'=>\$VERSION,
	   ) and !$HELP or die <<USAGE;
Usage: $0 [options] cnf_file data_file

Load LocusLink into Connect-the-Dots database

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
  --loaddir             Directory for load files (default: /usr/tmp/user_name)
  --loadsave            Specifies whether to save load files
                        Options: 'none', 'last', 'all'. Default: 'none'
  --connectorset		Specifies the name of the ConnectorSet to remove                        
  --removedots			Removes this connectorsets dots from the database
  --version				Version of connectorset to remove. Default is the newest version.

Options  may be abbreviated.  Values are case insenstive.

USAGE
;

my $dbinfo = Bio::ConnectDots::Config::db('production');
$HOST or $HOST=$dbinfo->{host};
$USER or $USER=$dbinfo->{user};
$PASSWORD or $PASSWORD=$dbinfo->{password};
$DATABASE or $DATABASE=$dbinfo->{dbname};
die "Must provide a ConnectorSet name to remove: --connectorset name" unless $CONNECTORSET;

print "### Removing ConntorSet: $CONNECTORSET";
print ", version: $VERSION" if $VERSION;
print "\n";

my $db=new Bio::ConnectDots::DB
  (-database=>$DATABASE,-host=>$HOST,-user=>$USER,-password=>$PASSWORD,-ext_directory=>$LOADDIR);
remove_set($db,$CONNECTORSET,$REMOVEDOTS,$VERSION);


### allows  you to remove a connectorset. Pass in the name of the connectorset and whether you want 
### the dots from that set deleted (an expensive operation that may be unnecessary)
### usage remove_set( <ConnectDots database> <connectorset name>, <remove dots> )
sub remove_set {
	my ($db, $cs_name, $remove_dots, $version) = @_;
	throw("Must have database connection to remove a connectorset.") unless $db;
	my $dbh = $db->{dbh};
	my $iterator;
	my ($cs_id, $max_ver);
		
	# get cs_id of specified version. Otherwise select most current version
	if($version) { 
		$iterator = $dbh->prepare("SELECT connectorset_id,version FROM connectorset WHERE name='$cs_name' AND version='$version'");
		$iterator->execute();
		my @cols = $iterator->fetchrow_array();
		notfound($db, $cs_name, $version) unless $cols[0];		
		$cs_id = $cols[0];
	}
	else {
		$iterator = $dbh->prepare("SELECT connectorset_id,version FROM connectorset WHERE name='$cs_name'");
		$iterator->execute();
		while(my ($id, $ver) = $iterator->fetchrow_array()) {
			if($ver gt $max_ver) {
				$max_ver = $ver;
				$cs_id = $id;	
			}	
		}
	}
	
	notfound($db, $cs_name, $version) unless $cs_id;
	
	# remove set from connectorset and connectdot (easy deletes)
	$db->do_sql("DELETE FROM connectorset WHERE connectorset_id=$cs_id");
	$db->do_sql("DELETE FROM connectdot WHERE connectorset_id=$cs_id");
	
	# Delete and save labels and dotset ids for this connectorset
	my %dotsets; # hash on dotset_id 
	my %labels; # hash on label_id
	$iterator = $dbh->prepare("SELECT dotset_id,label_id FROM connectdotset WHERE connectorset_id=$cs_id");
	$iterator->execute();
	while (my @cols = $iterator->fetchrow_array()) {
		$dotsets{$cols[0]} = 'delete' if $cols[0];
		$labels{$cols[1]} = 'delete' if $cols[1];
	}
	$db->do_sql("DELETE FROM connectdotset WHERE connectorset_id=$cs_id");
	
	# scan connectdotset again and delete labels and dotsets that are not found
	$iterator = $dbh->prepare("SELECT dotset_id,label_id FROM connectdotset");
	$iterator->execute();
	while (my @cols = $iterator->fetchrow_array()) {
		$dotsets{$cols[0]} = 'save' if $cols[0];
		$labels{$cols[1]} = 'save' if $cols[1];
	}
	foreach my $ds_id (keys %dotsets) { # delete dotsets
		$db->do_sql("DELETE FROM dotset WHERE dotset_id=$ds_id") if $dotsets{$ds_id} eq 'delete';
	}
	foreach my $label_id (keys %labels) { # delete labels
		$db->do_sql("DELETE FROM label WHERE label_id=$label_id") if $labels{$label_id} eq 'delete';
	}
	
	# remove dependant connectortable entries in connectortablesets
	my $sql = qq(DELETE FROM connectortableset WHERE connectortable_id IN
					 (SELECT DISTINCT connectortable_id
	 				  FROM connectortableset 
				 	  WHERE connectorset_id=$cs_id)
				);	

	# remove dots from dot that are not in connectdot
	$db->do_sql("DELETE FROM dot WHERE dot_id NOT IN (SELECT dot_id FROM connectdot)") if $remove_dots;
	
}

sub notfound { 
	my ($db, $cs_name, $version) = @_;
	print "Unknown connectorset: $cs_name";
	print ", version $version" if $version;
	print " in database ", $db->{database}, ".\n"
	and die;
}















