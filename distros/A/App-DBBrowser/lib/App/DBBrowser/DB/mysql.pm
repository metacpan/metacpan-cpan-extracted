package # hide from PAUSE
App::DBBrowser::DB::mysql;

use warnings;
use strict;
use 5.016;

use DBD::mysql 4.041 qw();  # mysql_enable_utf8mb4 requires 4.041 or greater
use DBI              qw();

use App::DBBrowser::Credentials;

sub new {
    my ( $class, $info, $opt ) = @_;
    my $sf = {
        i => $info,
        o => $opt
    };
    bless $sf, $class;
}


sub get_db_driver {
    my ( $sf ) = @_;
    return 'mysql';
}


sub get_db_handle {
    my ( $sf, $db ) = @_;
    my $cred = App::DBBrowser::Credentials->new( $sf->{i}, $sf->{o} );
    my $dsn = "dbi:mysql:dbname=$db";
    my $show_sofar = 'DB '. $db;
    my $host = $cred->get_login( 'host', $show_sofar );
    if ( defined $host ) {
        $show_sofar .= "\n" . 'Host: ' . $host;
        $dsn .= ";host=$host" if length $host;
    }
    my $port = $cred->get_login( 'port', $show_sofar );
    if ( defined $port ) {
        $show_sofar .= "\n" . 'Port: ' . $port;
        $dsn .= ";port=$port" if length $port;
    }
    my $user   = $cred->get_login( 'user', $show_sofar );
    $show_sofar .= "\n" . 'User: ' . $user if defined $user;
    my $passwd = $cred->get_login( 'pass', $show_sofar );
    my $dbh = DBI->connect( $dsn, $user, $passwd, {
        PrintError => 0,
        RaiseError => 1,
        AutoCommit => 1,
        ShowErrorStatement => 1,
        %{$sf->{o}{connect_attr}//{}}, ##
    } );
    return $dbh;
}


sub get_databases {
    my ( $sf ) = @_;
    return \@ARGV if @ARGV;

    #my $ax = App::DBBrowser::Auxil->new( {}, {}, {} );
    #my $file_mysql_dbs = sprintf $sf->{i}{db_cache_file_fmt}, $sf->{i}{plugin}; ##
    #my $cache = $ax->read_json( $file_mysql_dbs ) // {};
    #if ( ! $sf->{i}{search} && @{$cache->{user_databases}//[]} ) {
    #    return $cache->{user_databases}, $cache->{system_databases};
    #}

    my $dbh = $sf->get_db_handle( 'information_schema' );
    my $stmt = "SELECT schema_name FROM information_schema.schemata ORDER BY schema_name";
    my $databases = $dbh->selectcol_arrayref( $stmt, {}, () );
    $dbh->disconnect();
    my $user_db   = [];
    my $system_db = [];
    for my $database ( @$databases ) {
        if ( $database =~ /^(?:mysql|information_schema|performance_schema|sys)\z/ ) {
            push @$system_db, $database;
        }
        else {
            push @$user_db, $database;
        }
    }

    #$cache = {
    #    user_databases   => $user_db,
    #    system_databases => $system_db,
    #};
    #$ax->write_json( $file_mysql_dbs, $cache );

    return $user_db, $system_db;
}





1;


__END__
