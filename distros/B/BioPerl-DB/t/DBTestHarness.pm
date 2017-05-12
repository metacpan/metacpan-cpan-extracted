# $Id$

=pod

=head1 NAME - DBTestHarness.pm

=head1 SYNOPSIS

    # Add test dir to lib search path
    use lib 't';
    
    use DBTestHarness;
    
    my $harness = DBTestHarness->new();
    
    # Load some data into the db
    $ens_test->do_sql_file("some_data.sql");
    
    # Get an Overlap db object for the test db
    my $db = $harness->db();

=head1 DESCRIPTION

This is a direct copy-and-paste from the Ensembl 
EnsTestDB system.

It provides an encapsulation of creating, loading
and dropping databases for testing

=head1 METHODS

=cut

package DBTestHarness;

use strict;
use Sys::Hostname 'hostname';

use DBI;
use Carp;
use Bio::DB::BioDB;
use Bio::DB::SimpleDBContext;

#Package variable for unique database name
my $counter=0;

# Default settings as a hash
my $dflt = {
    'driver'        => 'mysql',
    'host'          => 'localhost',
    'user'          => 'root',
    'port'          => undef,
    'password'      => '',
    'schema_sql'    => ['../biosql-schema/sql/biosqldb-mysql.sql'],
    'database'      => 'biosql',
    'module'        => 'Bio::DB::BioSQL::DBAdaptor'
    };

    # This is a list of possible entries in the config
    # file "DBHarness.conf"
my %known_field = map {$_, 1} qw(
        driver
        host
        user
        port
        password
        schema_sql
	dbname
        database
        module
	);
    
sub new {
    my( $pkg,$db ) = @_;
    
    $counter++;
    my $self;
    
    confess "Must provide db, no default any more" unless $db;
    # Get config from file, or use default values
    if( $db eq 'biosql' ) {
	$self = do 'DBHarness.biosql.conf';
    } elsif ( $db eq 'markerdb' ) {
	$self = do 'DBHarness.markerdb.conf';
	$self->{"schema_sql"} = ['./sql/markerdb-mysql.sql']
	    unless $self->{"schema_sql"};
    } else {
	confess "Don't know about db $db : are you sure you meant to say $db?";
    }
    foreach my $f (keys %$self) {
	confess "Unknown config field: '$f'" unless $known_field{$f};
    }
    bless $self, $pkg;
    $self->create_db() unless exists($self->{"dbname"});
    
    return $self;
}


sub driver {
    my( $self, $value ) = @_;
    
    if ($value) {
        $self->{'driver'} = $value;
    }
    return $self->{'driver'} || confess "driver not set";
}

sub host {
    my( $self, $value ) = @_;
    
    if ($value) {
        $self->{'host'} = $value;
    }
    return $self->{'host'};
}

sub user {
    my( $self, $value ) = @_;
    
    if ($value) {
        $self->{'user'} = $value;
    }
    return $self->{'user'};
}

sub port {
    my( $self, $value ) = @_;
    
    if ($value) {
        $self->{'port'} = $value;
    }
    return $self->{'port'};
}

sub password {
    my( $self, $value ) = @_;
    
    if ($value) {
        $self->{'password'} = $value;
    }
    return $self->{'password'};
}

sub schema_sql {
    my( $self, $value ) = @_;
    
    if ($value) {
        push(@{$self->{'schema_sql'}}, $value);
    }
    return $self->{'schema_sql'} || confess "schema_sql not set";
}

sub dbname {
    my( $self, $value ) = @_;

    if($value && (! exists($self->{'dbname'}))) {
	$self->{'dbname'} = $value;
    }
    $self->{'dbname'} = $self->_create_db_name()
	unless exists($self->{'dbname'});
    return $self->{'dbname'};
}

sub database {
    my( $self, $value ) = @_;

    if($value && (! exists($self->{'database'}))) {
	$self->{'database'} = $value;
    }
    return $self->{'database'};
}

# convenience method: by calling it, you get the name of the database,
# which  you can cut-n-paste into another window for doing some mysql
# stuff interactively
sub pause {
    my ($self) = @_;
    my $db = $self->{'_dbname'};
    print STDERR "pausing to inspect database; name of database is:  $db\n";
    print STDERR "press ^D to continue\n";
    while(<>) { 1; }
}

sub module {
    my ($self, $value) = @_;
    $self->{'module'} = $value if ($value);
    return $self->{'module'};
}

sub _create_db_name {
    my( $self ) = @_;

    my $host = hostname();
    my $db_name = "_test_db_${host}_$$".$counter;
    $db_name =~ s{\W}{_}g;
    return $db_name;
}

sub create_db {
    my( $self ) = @_;
    
    ### FIXME: not portable between different drivers
    my $locator = 'dbi:'. $self->driver .':host='. $self->host .';';
    if ($self->driver eq "Pg") {
        # HACK! with DBD::Pg we *must* connect to a db
        $locator = 'dbi:Pg:dbname=template1';
        $locator .= ";host=".$self->host if $self->host;
    }
    print STDERR "locator:$locator\n" if $ENV{SQL_TRACE};
    my $db = DBI->connect(
        $locator, $self->user, $self->password, {RaiseError => 1}
        ) or confess "Can't connect to server";
    my $db_name = $self->dbname;
    $db->do("CREATE DATABASE $db_name");
    $db->disconnect;
    push(@{$self->{"_created_dbs"}}, $db_name);
    
    $self->do_sql_file(@{$self->schema_sql});
}

sub test_locator {
    my( $self ) = @_;

    my %dbname_param = ("mysql"  => "database=",
			"Pg"     => "dbname=",
			"Oracle" => "");

    my $locator = 'dbi:'. $self->driver .":". $dbname_param{$self->driver()} .
	$self->dbname;
    foreach my $meth (qw{ host port }) {
        if (my $value = $self->$meth()) {
            $locator .= ";$meth=$value";
        }
    }
    return $locator;
}


sub db_handle {
    my( $self, $no_create ) = @_;
    
    unless ($self->{'_db_handle'} || $no_create) {
        $self->{'_db_handle'} = DBI->connect(
            $self->test_locator, $self->user, $self->password, {RaiseError => 1}
            ) or confess "Can't connect to server";
    }
    return $self->{'_db_handle'};
}

sub get_DBAdaptor {
    my( $self, $dbc ) = @_;
    
    if(! $dbc) {
	return $self->get_DBContext()->dbadaptor();
    }
    return Bio::DB::BioDB->new(-database   => $self->database,
			       -dbcontext  => $dbc,
                               -printerror => $ENV{HARNESS_VERBOSE},
                               -verbose    => $ENV{HARNESS_VERBOSE},
                               );
}

sub get_DBContext {
    my ($self) = @_;
    my $dbc = Bio::DB::SimpleDBContext->new("-driver" => $self->driver,
					    "-dbname" => $self->dbname,
					    "-host"   => $self->host,
					    "-user"   => $self->user,
					    "-pass"   => $self->password,
					    "-port"   => $self->port);
    my $dbadp = $self->get_DBAdaptor($dbc);
    $dbc->dbadaptor($dbadp);
    return $dbc;
}

sub do_sql_file {
    my( $self, @files ) = @_;
    local *SQL;
    my $i = 0;
    my $dbh = $self->db_handle;
    
    foreach my $file (@files)
    {
        my $sql = '';
        open SQL, $file or die "Can't read SQL file '$file' : $!";
        while (<SQL>) {
            s/(#|--).*//;       # Remove comments
            next unless /\S/;   # Skip lines which are all space
            $sql .= $_;
            $sql .= ' ';
        }
        close SQL;
        
	#Modified split statement, only semicolumns before end of line,
	#so we can have them inside a string in the statement
        foreach my $s (grep /\S/, split /;\n/, $sql) {
            $self->validate_sql($s);
            $dbh->do($s);
            $i++
        }
    }
    return $i;
}

sub validate_sql {
    my ($self, $statement) = @_;
    if ($statement =~ /insert/i)
    {
        $statement =~ s/\n/ /g; #remove newlines
        die ("INSERT should use explicit column names (-c switch in mysqldump)\n$statement\n")
            unless ($statement =~ /insert.+into.*\(.+\).+values.*\(.+\)/i);
    }
}

sub DESTROY {
    my( $self, $file ) = @_;
    my $dbh = $self->db_handle("no_create");

    if($dbh) {
	$dbh->disconnect;
	$dbh = undef;
    }
    while(my $db_name = shift(@{$self->{"_created_dbs"}})) {
	if(! $dbh) {
	    ### FIXME: not portable between different drivers
	    my $locator = 'dbi:'. $self->driver .':host='. $self->host .';';
	    if ($self->driver eq "Pg") {
		# HACK! with DBD::Pg we *must* connect to a db
		$locator = 'dbi:Pg:dbname=template1';
		$locator .= ";host=".$self->host if $self->host;
	    }
	    my $db = DBI->connect($locator, $self->user, $self->password,
				  {RaiseError => 0})
		or warn "Can't connect to server ($locator), ".
		        "can't drop database $db_name: $@\n";
	}
	$dbh->do("DROP DATABASE $db_name") if $dbh;
    }
    $dbh->disconnect() if $dbh;
}

1;


__END__

=head1 AUTHOR

James Gilbert B<email> jgrg@sanger.ac.uk
