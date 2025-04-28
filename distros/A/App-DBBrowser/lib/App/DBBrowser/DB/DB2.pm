package # hide from PAUSE
App::DBBrowser::DB::DB2;

use warnings;
use strict;
use 5.016;

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
    return 'DB2';
}


sub env_variables {
    my ( $sf ) = @_;
    return [ qw( DBI_USER DBI_PASS ) ];
}


sub read_login_data {
    my ( $sf ) = @_;
    return [
        { name => 'user', secret => 0 },
        { name => 'pass', secret => 1 },
    ];
}


sub read_attributes {
    my ( $sf ) = @_;
    return [
        { name => 'LongReadLen', default => 32700 },
    ];
}


sub set_attributes {
    my ( $sf ) = @_;
    return [
        { name => 'LongTruncOk', default => 0, values => [ 0, 1 ] },
        { name => 'ChopBlanks',  default => 0, values => [ 0, 1 ] },
    ];
}


sub get_db_handle {
    my ( $sf, $db ) = @_;
    my $db_opt_get = App::DBBrowser::Opt::DBGet->new( $sf->{i}, $sf->{o} );
    my $db_opt          = $db_opt_get->read_db_config_files();
    my $login_data      = $db_opt_get->get_login_data( $db, $db_opt );
    my $env_var_yes     = $db_opt_get->enabled_env_vars( $db, $db_opt );
    my $read_attributes = $db_opt_get->get_read_attributes( $db, $db_opt );
    my $set_attributes  = $db_opt_get->get_set_attributes( $db, $db_opt );

    my $cred = App::DBBrowser::Credentials->new( $sf->{i}, $sf->{o} );
    my $settings = { login_data => $login_data, env_var_yes => $env_var_yes };
    # DBD::DB2 - Data Source Names:
    # Cataloged database connections can be done by passing the database alias, username, and password as parameters.
    # This method does not allow entering the host name, port number, etc but will require you to catalog the database
    # (local or remote) through DB2.
    my $dsn = "dbi:$sf->{i}{driver}:$db";
    my $show_sofar = 'DB '. $db;
    my $user = $cred->get_login( 'user', $show_sofar, $settings );
    $show_sofar .= "\n" . 'User: ' . $user if defined $user;
    my $passwd = $cred->get_login( 'pass', $show_sofar, $settings );
    my $dbh = DBI->connect( $dsn, $user, $passwd, {
        PrintError => 0,
        RaiseError => 1,
        AutoCommit => 1,
        ShowErrorStatement => 1,
        %$read_attributes,
        %$set_attributes,
    } );
    return $dbh;
}


sub get_databases {
    my ( $sf ) = @_;
    return \@ARGV if @ARGV;
    my $driver = $sf->get_db_driver();
    # data_sources returns a list of all cataloged databases.
    my @cataloged_databases = DBI->data_sources( $driver );
    for ( @cataloged_databases ) {
        s/^dbi:$driver://;
        s/\s+\z//;
    }
    return [ @cataloged_databases ];
}






1;

__END__
