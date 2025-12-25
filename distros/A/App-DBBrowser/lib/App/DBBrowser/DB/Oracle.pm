package # hide from PAUSE
App::DBBrowser::DB::Oracle;

use warnings;
use strict;
use 5.016;

use DBI qw();

use Term::Choose qw( choose );

use App::DBBrowser::Auxil;
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
    return 'Oracle';
}


sub get_db_handle {
    my ( $sf, $db ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, {} );
    my $cred = App::DBBrowser::Credentials->new( $sf->{i}, $sf->{o} );
    my $show_sofar = 'DB: '. $db;
    my $host = $cred->get_login( 'host', $show_sofar );
    my $port;
    if ( length $host ) {
        $show_sofar .= "\n" . 'Host: ' . $host;
        $port = $cred->get_login( 'port', $show_sofar );
        if ( length $port ) {
            $show_sofar .= "\n" . 'Port: ' . $port;
        }
    }
    my $attr = $ax->clone_data( $sf->{o}{connect_attr} );
    my $ask_if_sid = delete $attr->{AskIfSID};
    my $dsn = "dbi:Oracle:";
    if ( $host ) {
        my $db_type;
        my $sid = 'SID';
        if ( $ask_if_sid ) {
            $db_type = choose(
                [ undef, 'Service_Name', $sid ],
                { info => $show_sofar . "\n", prompt => "DB Identifier Type:",  undef => '<' }
            );
            if ( defined $db_type ) {
                $show_sofar .= "\n" . 'Type: ' . $db_type;
            }
        }
        if ( defined $db_type && $db_type eq $sid ) {
            if ( $port ) {
                $dsn .= "host=$host;port=$port;sid=$db";
            }
            else {
                $dsn .= "host=$host;sid=$db";
            }
        }
        else {
            if ( $port ) {
                $dsn .= "//$host:$port/$db";
            }
            else {
                $dsn .= "//$host/$db";
            }
        }
    }
    else {
        $dsn .= $db;
    }
    my $user = $cred->get_login( 'user', $show_sofar );
    $show_sofar .= "\n" . 'User: ' . $user if defined $user;
    my $passwd = $cred->get_login( 'pass', $show_sofar );
    my $dbh = DBI->connect( $dsn, $user, $passwd, {
        PrintError => 0,
        RaiseError => 1,
        AutoCommit => 1,
        ShowErrorStatement => 1,
        %{$attr//{}},
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
