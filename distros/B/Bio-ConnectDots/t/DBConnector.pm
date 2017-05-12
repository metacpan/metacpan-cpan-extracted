package DBConnector;
## this is a database utility class that provides a common connection api
## for all the tests.
use lib qw(. ../blib ../lib);
use Bio::ConnectDots::Config;
use strict;
use vars qw($noConnectionFile $DB_DATABASE $DB_USER $DB_PASS $DB_DRIVER $DB_NAME $DB_HOST @ISA);
use DBI;


###############################################################################
# Constructor
###############################################################################

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {};

		### SET DEFAULT DATABASE CONNECTION VALUES
		my $dbinfo = Bio::ConnectDots::Config::db('test');
		$self->{DB_HOST} = $dbinfo->{host};
		$self->{DB_DATABASE}  = $dbinfo->{dbname};
		$self->{DB_DRIVER}	= "DBI:Pg:dbname=";	
		$self->{DB_USER}      = $dbinfo->{user};
		$self->{DB_PASS}      = $dbinfo->{password};

    bless $self, $class;
    return($self);
}

sub connect {
	my ($self,$dbname) = @_;
	$self->{DB_DATABASE}  = $dbname if $dbname;
	$DB_DRIVER = $self->{DB_DRIVER};
	$DB_DATABASE = $self->{DB_DATABASE};
	$DB_USER = $self->{DB_USER};
	$DB_PASS = $self->{DB_PASS};
	$DB_HOST = $self->{DB_HOST};

	# Connect to default database to setup other db
	#connect to a database first before able to create a new database, 
	my $DSN="DBI:Pg:dbname=template1;";
#	$DSN .= "host=$DB_HOST;" if $DB_HOST;
	my $dbh = DBI -> connect ($DSN, $self->{DB_USER}, $self->{DB_PASSWORD});

	if(&can_connect && $dbh){
	  my $ext = $dbh->selectall_arrayref("SELECT datname FROM pg_database WHERE datname='$DB_DATABASE'");
	  if ($ext->[0]) {
	    $dbh->do("DROP DATABASE $DB_DATABASE") or die "### Can not assure fresh database. Please remove databse: $DB_DATABASE\n";	
	  }
	  $dbh->do("create database ". $DB_DATABASE) if $DB_DATABASE;
	  $dbh->disconnect();
		$dbh = DBI->connect($self->{DB_DRIVER}.$DB_DATABASE, "$self->{DB_USER}", "$self->{DB_PASS}") || _mark_noconnect();
	}
	$self->{dbh} = $dbh;
	return $dbh;
}

###############################################################################
# _mark_noconnect
#
# writes a file named ".noDBConnnection" in this directory so that both
# testing class and instance methods can find out if we have a DB connection
###############################################################################
sub _mark_noconnect {
  $noConnectionFile = "__noDBConnection";
  open(FILE,">./$noConnectionFile");
}

###############################################################################
# can_connect
#
# Returns true if there is an active db handle, false otherwise
###############################################################################

sub can_connect {
  my $connected=0;
  if (!$noConnectionFile) {
  	$connected=1;
  } else {
  	open(FILE,"$noConnectionFile");
  }
  return $connected;
}

###############################################################################
# get DB Handle
#
# Returns the current database connection handle to be used by any query.
# If the database handle doesn't yet exist, dbConnect() is called to create
# one.
###############################################################################
sub getDBHandle {
    my $self = shift;

    return $self->can_connect()? $self->{dbh} : undef;
}

###############################################################################
# get DB Database
#
# Return the database name of the connection.
###############################################################################
sub getDBDatabase {
    my $self = shift;
    $self->{DB_DATABASE};
}

END  {
	   if(&can_connect){
#         my $dbh = DBI->connect($DB_DRIVER."template1", "$DB_USER", "$DB_PASS")
#	       or die "$DBI::errstr : perhaps you should alter $0's connection parameters";

#         $dbh->do("drop database $DB_DATABASE");
#         $dbh->disconnect();
	   }
	   else{ 	   	  
	   	     unlink $noConnectionFile;
	   }
     }
     

1;