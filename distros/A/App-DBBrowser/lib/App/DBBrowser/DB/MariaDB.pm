package # hide from PAUSE
App::DBBrowser::DB::MariaDB;

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
    return 'MariaDB';
}


sub env_variables {
    my ( $sf ) = @_;
    return [ qw( DBI_HOST DBI_PORT DBI_USER DBI_PASS ) ];
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
        { name => 'mariadb_bind_type_guessing', default => 1, values => [ 0, 1 ] },
        { name => 'ChopBlanks',                 default => 0, values => [ 0, 1 ] },
    ];
}


sub get_db_handle {
    my ( $sf, $db ) = @_;
    my $db_opt_get = App::DBBrowser::Opt::DBGet->new( $sf->{i}, $sf->{o} );
    my $db_opt         = $db_opt_get->read_db_config_files();
    my $login_data     = $db_opt_get->get_login_data( $db, $db_opt );
    my $env_var_yes    = $db_opt_get->enabled_env_vars( $db, $db_opt );
    my $set_attributes = $db_opt_get->get_set_attributes( $db, $db_opt );

    my $cred = App::DBBrowser::Credentials->new( $sf->{i}, $sf->{o} );
    my $settings = { login_data => $login_data, env_var_yes => $env_var_yes };
    my $dsn = "dbi:$sf->{i}{driver}:dbname=$db";
    my $show_sofar = 'DB '. $db;
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
    my $user   = $cred->get_login( 'user', $show_sofar, $settings );
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
    my $info_database = 'information_schema';
    my $dbh = $sf->get_db_handle( $info_database );
    my $stmt = "SELECT schema_name FROM information_schema.schemata ORDER BY schema_name";
    my $databases = $dbh->selectcol_arrayref( $stmt, {}, () );
    $dbh->disconnect();
    my $user_db   = [];
    my $system_db = [];
    for my $database ( @{$databases} ) {
        if ( $database =~ /^(?:mysql|information_schema|performance_schema|sys)\z/ ) {
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
