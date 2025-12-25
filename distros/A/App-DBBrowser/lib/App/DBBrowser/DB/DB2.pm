package # hide from PAUSE
App::DBBrowser::DB::DB2;

use warnings;
use strict;
use 5.016;

use DBI qw();

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
    return 'DB2';
}


sub get_db_handle {
    my ( $sf, $db ) = @_;
    my $cred = App::DBBrowser::Credentials->new( $sf->{i}, $sf->{o} );
    # DBD::DB2 - Data Source Names:
    # Cataloged database connections can be done by passing the database alias, username, and password as parameters.
    # This method does not allow entering the host name, port number, etc but will require you to catalog the database
    # (local or remote) through DB2.
    my $dsn = "dbi:DB2:$db";
    my $show_sofar = 'DB '. $db;
    my $user = $cred->get_login( 'user', $show_sofar );
    $show_sofar .= "\n" . 'User: ' . $user if defined $user;
    my $passwd = $cred->get_login( 'pass', $show_sofar );
    my $dbh = DBI->connect( $dsn, $user, $passwd, {
        PrintError => 0,
        RaiseError => 1,
        AutoCommit => 1,
        ShowErrorStatement => 1,
        %{$sf->{o}{connect_attr}//{}},
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
