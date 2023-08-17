package # hide from PAUSE
App::DBBrowser::DB::Oracle;

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
    return 'Oracle';
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


sub read_attributes {
    my ( $sf ) = @_;
    return [
        { name => 'ora_charset', default => 'AL32UTF8' },
        { name => 'LongReadLen', default => 80         },
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
    my $db_opt         = $db_opt_get->read_db_config_files();
    my $login_data     = $db_opt_get->get_login_data( $db, $db_opt );
    my $env_var_yes    = $db_opt_get->enabled_env_vars( $db, $db_opt );
    my $read_attributes = $db_opt_get->get_read_attributes( $db, $db_opt );
    my $set_attributes  = $db_opt_get->get_set_attributes( $db, $db_opt );

    my $cred = App::DBBrowser::Credentials->new( $sf->{i}, $sf->{o} );
    my $settings = { login_data => $login_data, env_var_yes => $env_var_yes };
    my $dsn;
    my $show_sofar = 'DB '. $db;
    if ( ! $env_var_yes->{DBI_DSN} || ! exists $ENV{DBI_DSN} ) {
        my $host = $cred->get_login( 'host', $show_sofar, $settings );
        if ( defined $host ) {
            $show_sofar .= "\n" . 'Host: ' . $host;
        }
        my $port = $cred->get_login( 'port', $show_sofar, $settings );
        if ( defined $port ) {
            $show_sofar .= "\n" . 'Port: ' . $port;
        }
        my @address;
        push @address, "host=$host" if length $host;
        push @address, "sid=$db";
        push @address, "port=$port" if length $port;
        if ( @address == 1 ) {
            $dsn = "dbi:$sf->{i}{driver}:$db";
        }
        else {
            $dsn = "dbi:$sf->{i}{driver}:" . join( ';', @address );
        }
    }
    my $user   = $cred->get_login( 'user', $show_sofar, $settings );
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
    my @data_sources = DBI->data_sources( 'Oracle' );
    return [ map { s/^dbi:Oracle://; $_ } @data_sources ], [];
}








1;


__END__
