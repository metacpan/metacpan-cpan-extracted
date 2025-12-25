package # hide from PAUSE
App::DBBrowser::DB::Informix;

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
    return 'Informix';
}


sub get_db_handle {
    my ( $sf, $db ) = @_;
    my $cred = App::DBBrowser::Credentials->new( $sf->{i}, $sf->{o} );
    my $dsn = "dbi:Informix:$db";
    my $show_sofar = 'DB '. $db;
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
    my $driver = $sf->get_db_driver();
    my @databases = DBI->data_sources( $driver );
    my ( @user_dbs, @sys_dbs );
    for ( @databases ) {
        s/^dbi:$driver://;
        s/\s+\z//;
        if ( m[(?:^|/)(?:sysadmin|sysmaster|sysuser|sysutils)\b]i ) {
            push @sys_dbs, $_;
        }
        else {
            push @user_dbs, $_;
        }
    }
    return [ sort @user_dbs ], [ sort @sys_dbs ];
}










1;


__END__
