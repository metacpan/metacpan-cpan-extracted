package # hide from PAUSE
App::DBBrowser::DB::ODBC;

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
    return 'ODBC';
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
        { name => 'LongReadLen', default => 80 },
        #{ name => 'odbc_batch_size', default => 10 },
    ];
}


sub set_attributes {
    my ( $sf ) = @_;
    return [
        { name => 'odbc_utf8_on',                   default => 0, values => [ 0, 1 ] },
        { name => 'LongTruncOk',                    default => 0, values => [ 0, 1 ] },
        { name => 'ChopBlanks',                     default => 0, values => [ 0, 1 ] },
        { name => 'odbc_ignore_named_placeholders', default => 0, values => [ 0, 1 ] },
        #{ name => 'odbc_array_operations', default => 0, values => [ 0, 1 ] },

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
    my $dsn = "dbi:$sf->{i}{driver}:DSN=$db";
    my $show_sofar = 'DSN '. $db;
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
    # data_sources returns a list of DSNs.
    my @dsn = DBI->data_sources( $driver );
    for ( @dsn ) {
        s/^dbi:$driver://;
        s/\s+\z//;
    }
    return [ @dsn ];
}





1;

__END__
