package DBIx::PhraseBook;

use strict;
use warnings;

=pod

=head1 NAME

DBIx::PhraseBook - provides phrasebooked database queries, allowing client code to avoid embedding
sql and direct dbi calls. supports named bind parameters only if the underlying DBD driver does.

=head1 WARNING

always returns uppercased key names and resultset is a structure as returned by fetchrow_hashref
(see DBI documentation).

=head1 IMPLEMENTATION

=over

=item 

my %phraseBooks = DBIx::PhraseBook->load( $prefix, $propsfile );

loads phrasebooks defined in a properties file, returning a hash keyed on phrasebook name.

example props file:

test.hosts.db.dsn=dbi:mysql:hostname=127.0.0.1;debug=1;port=1367;database=hosts
test.hosts.db.username=testuser
test.hosts.db.password=passwordstring
test.hosts.db.phrasebooks.1.name=hosts
test.hosts.db.phrasebooks.1.path=/fullpath/to/phrasebooks/hosts.xml
test.hosts.db.phrasebooks.1.key=key1
test.hosts.db.phrasebooks.2.name=hosts
test.hosts.db.phrasebooks.2.path=/fullpath/to/phrasebooks/hosts.xml
test.hosts.db.phrasebooks.2.key=key1

$prefix would be test.hosts.db for this properties file.

=back


=over

=item 

my $status = $phraseBooks{keyname}->execute($queryName,$inputArg,[outarg1=>$ref])

=item

my $status = $phraseBooks{keyname}->execute($queryName,{inarg1=>$i1,$inarg2=>$i2},{outarg1=>$ref1,outarg2=>$ref2})

=item

my $status = $phraseBooks{keyname}->execute($queryName,[$i1,$i2])

=item

my $hashref = $phraseBooks{keyname}->fetch($queryName,$inputArg,[outarg1=>$ref])

=item

my @data = $phraseBooks{keyname}->fetch($queryName,$inputArg,[outarg1=>$ref])

=item

my @data = $phraseBooks{keyname}->fetch($queryName,{inarg1=>$i1,$inarg2=>$i2},{outarg1=>$ref1,outarg2=>$ref2})

C<execute> and C<fetch> are the main methods in this class that client code will use. both execute a 
query retrieved from an xml file given a key, binding all necessary variables
along the way. C<fetch> returns an array or single row resultset according to 
what the caller expects (uses C<wantarray>). 

C<execute> does not do a fetch from the statement
handle and only returns execute status. 

in array context, fetch will return an array containing hashrefs of all rows.
in scalar context, will return one ie the first row as a hashref.

if query only has one input bind parameter, 
and it is called ':id', or query has a single '?',  then first form of each of 
C<execute> and C<fetch> (above) can be used.


=item

my @data = $phraseBooks{keyname}->fetchReport($queryName,$inputArg,[outarg1=>$ref])

does the same as fetch, but prints a timings report to the logger.

=item 

$phraseBooks{keyname}->prepare($queryName)

prepares named query and returns a statement handle - is used by C<execute>/C<fetch> and by test scripts.
not normally invoked directly by user.

=item 

$phraseBooks{keyname}->getAllQueryNames( )

returns names of all queries in phrasebook. used by test scripts. 

=item 

$phraseBooks{keyname}->useDbh($database_handle)

Force use of an existing handle

=item 

$phraseBooks{keyname}->getDbh()

Return existing handle

=item 

$phraseBooks{keyname}->debugOn( )

Switch DBMS Debugging on

=item 

$phraseBooks{keyname}->debugOff( )

Switch DBMS Debugging off


=head1 AUTHOR

Mark Clements, February 2003

=head1 BUGS

is a relatively thin wrapper around Class::Phrasebook and DBI and is quite simplistic - have probably missed a few tricks but should be flexible enough to extend as necessary without too much trouble. possibly should be implemented as a singleton.

C<getAllQueryNames> probably belongs in the Class::Phrasebook module - it's a bit messy 
having xpath in this class that directly references the phrasebook xml file.

=cut

use Benchmark::Timer;
use Carp qw(confess cluck);
use Carp::Assert;
use Class::Phrasebook;
use Config::PropertiesSequence;
use Data::Dumper;
use DBI;
use Log::Log4perl;
use Storable qw(dclone);
use XML::XPath;

our $logger;
our Class::Phrasebook $phraseBook;

use constant DEFAULT_FETCH_KEYS => "NAME_uc";
use constant DEFAULTBINDPARAMETERNAME => 1;

use constant MAINTIMINGS              => 0;
use constant MILLISECONDFORMAT        => "%.2fms ";
use constant CALLERLEVEL              => 3;
use constant CALLERLINEFIELD          => 2;
use constant CALLERSUBROUTINEFIELD    => 3;

our $keepTimer;
our $VERSION = sprintf "%d.%03d", q$Revision: 1.3 $ =~ /(\d+)/g;

use fields qw(_phrasebook _dbh _keyname _timer);

INIT {
    DBI->trace(0);
    my $log4perl = join "\n",<DATA>;

    Log::Log4perl::init(\$log4perl);
    $logger = Log::Log4perl->get_logger("dbix.phrasebook");

our Benchmark::Timer $timer;
    sub  _getAllQueriesXpath ($){
        my $keyname = shift;
        return  q(/phrasebook/dictionary[@name=') . $keyname . q(']/phrase/@name);
    }
}

sub setLogger($$) {
    my $class = shift;
    $logger = shift;
}

sub init($$$) {
    my __PACKAGE__ $self = shift;
    my $phraseBookPath   = shift;
    my $dictionaryKey    = shift;
    my $setdbh           = shift;
    $phraseBook = Class::Phrasebook->new( undef, $phraseBookPath );
    $phraseBook->load($dictionaryKey);

}

sub new($$$) {
    my $class          = shift;
    my $phraseBookPath = shift;
    my $dictionaryKey  = shift;

    my __PACKAGE__ $self = fields::new($class);
    my Class::Phrasebook $phraseBook = Class::Phrasebook->new( undef, $phraseBookPath );
    $phraseBook->load($dictionaryKey);
    $self->{_phrasebook} = $phraseBook;
    $self->{_keyname} = $dictionaryKey;
    return $self;
}

sub load($$$) {
    my $class     = shift;
    my $prefix    = shift;
    my $propsFile = shift;

    assert( defined $prefix, "prefix not defined" );
    assert( -r $propsFile, "can't read propsfile $propsFile - $!" );

    ## load up properties
    my Config::PropertiesSequence $props = Config::PropertiesSequence->new();
    $props->load( FileHandle->new( $propsFile, "r" ) );

    ## get db connection defs (if any)
    my $defaultDBH;
    {
        my $dsn      = $props->getProperty("$prefix.dsn");
        my $username = $props->getProperty("$prefix.username");
        my $password = $props->getProperty("$prefix.password");

        if ( defined $dsn ) {
            $defaultDBH = _connect(
                dsn      => $dsn,
                username => $username,
                password => $password
            );
        }
    }

    ## get phrasebook definitions
    my @phraseBookDefs =
      $props->getPropertySequence( "$prefix.phrasebooks", qw(path name key default) );
    my %phraseBooks = ();

    ## load up phrasebooks
    foreach my $phraseBookDef (@phraseBookDefs) {
        my $phraseBookName = $phraseBookDef->{name};
        my $phraseBookKey  = $phraseBookDef->{key};
        my $phraseBookPath = $phraseBookDef->{path};
        
        $logger->info("load $phraseBookKey -> $phraseBookPath");
        my $newPhraseBook = __PACKAGE__->new( $phraseBookPath, $phraseBookKey );
        $newPhraseBook->setDBH($defaultDBH);
        $phraseBooks{$phraseBookName} = $newPhraseBook;
    }
    return %phraseBooks;

}

sub _connect(@) {
    my %settings = @_;
    my $dbh      = DBI->connect(
        $settings{dsn},
        $settings{username},
        $settings{password},
        {
            AutoCommit => 1,
            RaiseError => 1,
        }
    );
    my $errstr = $DBI::errstr || "";
    assert( defined $dbh, "failed to connect: $errstr" );

    return $dbh;
}

sub setDBH($$) {
    my __PACKAGE__ $self = shift;
    my $dbh = shift;

    $self->{_dbh} = $dbh;
}

sub useDbh ($$) {
    my __PACKAGE__ $self = shift;
    $self->{_dbh} = shift;
}

sub getDbh ($) {
    my __PACKAGE__ $self = shift;
    return $self->{_dbh};
}

sub getLogger($) {
    my $class     = shift;
    my $newLogger = shift;

    $logger = $newLogger;
}

sub prepare($$) {
    my __PACKAGE__ $self = shift;
    my $type = shift;

    ## retrieve query from phrasebook
    my $phraseBook = $self->{_phrasebook};
    my $query      = $phraseBook->get($type);
    $logger->info("query $type = $query");

    my $dbh = $self->{_dbh};
    assert( defined $query, "attempted to get query for undefined query type $type" );

    ## prepare query and return statement handle
    my $sth = $dbh->prepare($query);
    assert( $sth, "failed to prepare query " . ( $dbh->errstr() || "(no error)" ) );

    return $sth;
}

sub getAllQueryNames($) {
    my __PACKAGE__ $self = shift;

    ## extract all query names from phrasebook
    my XML::XPath $xpath = XML::XPath->new( filename => $self->{_phrasebook}->get_xml_path() );
    assert( defined $xpath, "could not load xpath - $! " );
    my $nodeset = $xpath->find(_getAllQueriesXpath($self->{_keyname}));

    ## store returned names in array and return
    my @allQueries = ();
    foreach my $node ( $nodeset->get_nodelist() ) {
        my $queryName = $node->string_value();
        push @allQueries, $queryName;
    }
    return @allQueries;

}

sub execute($$;$$) {
    my __PACKAGE__ $self    = shift;
    my $type    = shift;
    my $inargs  = shift;
    my $outargs = shift;

    my $mainTimer;
    if (MAINTIMINGS) {
        $mainTimer = Benchmark::Timer->new();
        $mainTimer->start("main timing");
    }
    my $debugArgs = $self->getDebugArgs( $inargs, $outargs );
    my ( $result, $sth ) = $self->_executeQuery( $type, $inargs, $outargs );

    if ( !defined $sth ) {
        $logger->warn( "failed => " . $self->getDebug( $type, $debugArgs ) );

    } else {
        my $timing = "";
        if (MAINTIMINGS) {
            $mainTimer->stop("main timing");
            $timing = $mainTimer->result("main timing");
            $logger->info( $self->getDebug( $type, $debugArgs, $timing ) );
        }

#        undef $timer;
    }
    return $result;

}

sub fetchReport($$;$$) {
    my __PACKAGE__ $self    = shift;
    my $type    = shift;
    my $inargs  = shift;
    my $outargs = shift;
    my $trials  = shift || 1;

    my $timer     = Benchmark::Timer->new();
    $self->{_timer} = $timer;
    $keepTimer = 1;
    my @results = ();
    for ( my $ii = 0 ; $ii < $trials ; $ii++ ) {
        @results = $self->fetch( $type, $inargs, $outargs );
    }
    $self->report();

    if(wantarray){
        return @results;
    }else{
        return $results[0];
    }
}

sub report($) {
    my __PACKAGE__ $self = shift;
    $self->{_timer}->report();
}

sub fetch($$;$$) {
    my __PACKAGE__ $self    = shift;
    my $type    = shift;
    my $inargs  = shift;
    my $outargs = shift;

    my $mainTimer;
    if (MAINTIMINGS) {
        $mainTimer = Benchmark::Timer->new();
        $mainTimer->start("main timing");
    }

    my $timer = $self->{_timer};
    $timer->start("overall") if defined $timer;
    
    my $debugArgs = "";

    $timer->start("build args")  if defined $timer;
    if ( $logger->is_info() ) {
        $debugArgs = $self->getDebugArgs( $inargs, $outargs );
    }
    $timer->stop("build args") if defined $timer;

    $timer->start("main") if defined $timer;
    my ( $result, $sth ) = $self->_executeQuery( $type, $inargs, $outargs );
    $timer->stop("main") if defined $timer;

    ## fetch resultset from statement handle as necessary
    my @out = ();

    my $resultSet;
    if ( wantarray() ) {
        $timer->start("multirow fetch") if defined $timer;
        while ( my $row = $sth->fetchrow_hashref(DEFAULT_FETCH_KEYS) ) {
            push @out, $row;
        }
        $timer->stop("multirow fetch") if defined $timer;
    } else {
        $timer->start("single row fetch") if defined $timer;
        $resultSet = $sth->fetchrow_hashref(DEFAULT_FETCH_KEYS);
        $timer->stop("single row fetch") if defined $timer;

    }
    $timer->stop("overall") if defined $timer;
    
    if (MAINTIMINGS) {
        my $timing;
        $mainTimer->stop("main timing");
        $timing = $mainTimer->result("main timing");
        $logger->info( $self->getDebug( $type, $debugArgs, $timing ) );
    }

    if ( wantarray() ) {
        return @out;
    } else {
        return $resultSet;
    }
}

sub getDebugArgs($$$) {
    my __PACKAGE__ $self    = shift;
    my $inargs  = shift;
    my $outargs = shift;

    my $debugArgs = "";

    ## note use of dclone - Dumper does something weird to inargs and outargs...
    local $Data::Dumper::Terse = 1;
    if ( defined $inargs ) {
        if ( ref $inargs ) {
            $debugArgs = Dumper( dclone $inargs);
        } else {
            $debugArgs = $inargs;
        }
    }
    if ( defined $outargs ) {
        if ( ref $outargs ) {
            $debugArgs .= ", " . Dumper( dclone $outargs);
        } else {
            $debugArgs .= ", " . $outargs;
        }
    }
    $debugArgs =~ s/\n/ /g;
    $debugArgs =~ s/ +/ /g;

    return $debugArgs;
}

sub _executeQuery($$;$$) {
    my __PACKAGE__ $self    = shift;
    my $type    = shift;
    my $inargs  = shift;
    my $outargs = shift;

    ## prepare query
    my $timer = $self->{_timer};
    $timer->start("prepare") if defined $timer;
    my $sth = $self->prepare($type);
    $timer->stop("prepare") if defined $timer;

    ## bind arguments accordingly
    $timer->start("bind") if defined $timer;
    eval {
        if ( defined $inargs )
        {
            if ( my $reftype = ref $inargs ) {
                if ( $reftype eq "HASH" ) {
                    while ( my ( $key, $value ) = each %{$inargs} ) {
                        $sth->bind_param( ":$key" => $value );
                    }
                } elsif ( $reftype eq "ARRAY" ) {
                    for ( my $ii = 0 ; $ii < @$inargs ; $ii++ ) {
                        my $bindPos = $ii + 1;
                        $logger->info("bind $bindPos => $inargs->[$ii]");
                        $sth->bind_param( $bindPos, $inargs->[$ii] );
                    }
                } else {
                    warn "unknown arg - $reftype";
                }
            } else {
                $sth->bind_param( DEFAULTBINDPARAMETERNAME, $inargs );
            }
        }

        if ( ref $outargs ) {
            while ( my ( $key, $value ) = each %{$outargs} ) {
                $sth->bind_param_inout( ":$key" => $value, 0 );
            }
        }
    };
    $timer->stop("bind") if defined $timer;

    ## whinge and die as necessary
    confess $@ if $@;

    ## execute
    $timer->start("execute") if defined $timer;
    my $rv;
    eval { $rv = $sth->execute(); };
    my $dbh = $self->{_dbh};
    if ( $@ || $dbh->errstr() ) {
        cluck( "problem with $type => " . $dbh->errstr );
        $self->error_handle( $dbh->errstr );
        return;
    }
    $timer->stop("execute") if defined $timer;

    return ( $rv, $sth );
}
sub error_handle($){
    my __PACKAGE__ $self = shift;
    my $errorMessage = shift;

}

sub DESTROY($$$$) {
    my __PACKAGE__ $self = shift;
    eval { $self->{_dbh}->disconnect(); };
}

sub getDebug($$$$) {
    my __PACKAGE__ $self      = shift;
    my $type      = shift;
    my $debugArgs = shift;
    my $timing    = shift;

    my ( $line, $subroutine ) = ( caller(CALLERLEVEL) )[ CALLERLINEFIELD, CALLERSUBROUTINEFIELD ];
    return (
        "query=> $type sub=> $subroutine line=> $line"
          . (
            MAINTIMINGS
            ? " t=> " . ( sprintf( MILLISECONDFORMAT, $timing * 1000 ) )
            : ""
          )
          . ( $debugArgs ne "" ? "args=> " . $debugArgs : "(no arguments)" )
    );
}

sub debugOn () {
    my __PACKAGE__ $self      = shift;
    $self->{_dbh}->trace(1);
}

sub debugOff () {
    my __PACKAGE__ $self      = shift;
    $self->{_dbh}->trace(0);
}

1;

__DATA__
log4perl.category.dbix.phrasebook = WARN,Screen
log4perl.appender.Screen         = Log::Log4perl::Appender::Screen
log4perl.appender.Screen.stderr  = 1
log4perl.appender.Screen.layout   =  Log::Log4perl::Layout::SimpleLayout

