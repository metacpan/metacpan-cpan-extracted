package # hide from PAUSE
App::DBBrowser::DB::Pg;

use warnings;
use strict;
use 5.014;

use DBI qw();

use App::DBBrowser::Credentials;
use App::DBBrowser::Opt::DBGet;


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
    return 'Pg';
}


sub env_variables {
    my ( $sf ) = @_;
    return [ qw( DBI_DSN DBI_HOST DBI_PORT DBI_USER DBI_PASS ) ];
}


sub read_login_data {
    my ( $sf ) = @_;
    return [
        { name => 'host', secret => 0 },
        { name => 'port', secret => 0 },
        { name => 'user', secret => 0 },
        { name => 'pass', secret => 1 },
    ];
}


sub set_attributes {
    my ( $sf ) = @_;
    return [
        { name => 'pg_enable_utf8', default => 2, values => [ 0, 1, -1 ] },
        { name => 'ChopBlanks',     default => 0, values => [ 0, 1 ]     },
    ];
}


sub get_db_handle {
    my ( $sf, $db ) = @_;
    my $db_opt_get     = App::DBBrowser::Opt::DBGet->new( $sf->{i}, $sf->{o} );
    my $db_opt         = $db_opt_get->read_db_config_files();
    my $login_data     = $db_opt_get->get_login_data( $db, $db_opt );
    my $env_var_yes    = $db_opt_get->enabled_env_vars( $db, $db_opt );
    my $set_attributes = $db_opt_get->get_set_attributes( $db, $db_opt );

    my $cred = App::DBBrowser::Credentials->new( $sf->{i}, $sf->{o} );
    my $settings = { login_data => $login_data, env_var_yes => $env_var_yes };
    my $dsn;
    my $show_sofar = 'DB '. $db;
    if ( ! $env_var_yes->{DBI_DSN} || ! exists $ENV{DBI_DSN} ) {
        $dsn = "dbi:$sf->{i}{driver}:dbname=$db";
        my $host = $cred->get_login( 'host', $show_sofar, $settings );
        if ( defined $host ) {
            $show_sofar .= "\n" . 'Host: ' . $host;
            $dsn .= ";host=$host" if length $host;
        }
        my $port = $cred->get_login( 'port', $show_sofar, $settings );
        if ( defined $port ) {
            $show_sofar .= "\n" . 'Port: ' . $port;
            $dsn .= ";port=$port" if length $port;
        }
    }
    my $user = $cred->get_login( 'user', $show_sofar, $settings );
    $show_sofar .= "\n" . 'User: ' . $user if defined $user;
    my $passwd = $cred->get_login( 'pass', $show_sofar, $settings );
    my $dbh = DBI->connect( $dsn, $user, $passwd, {
        PrintError => 0,
        RaiseError => 1,
        AutoCommit => 1,
        ShowErrorStatement => 1,
        %$set_attributes,
    } );
    return $dbh;
}


sub get_databases {
    my ( $sf ) = @_;
    return \@ARGV if @ARGV;
    my $info_database = 'postgres';
    my $dbh = $sf->get_db_handle( $info_database );
    my $stmt = "SELECT pg_catalog.quote_ident(datname) FROM pg_catalog.pg_database ORDER BY datname";
    my $databases = $dbh->selectcol_arrayref( $stmt, {}, () );
    $dbh->disconnect();
    my $user_db   = [];
    my $system_db = [];
    for my $database ( @{$databases} ) {
        if ( $database =~ /^(?:postgres|template0|template1)\z/i ) {
            push @$system_db, $database;
        }
        else {
            push @$user_db, $database;
        }
    }
    return $user_db, $system_db;
}






1;


__END__
