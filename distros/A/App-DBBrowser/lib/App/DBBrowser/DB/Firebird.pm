package # hide from PAUSE
App::DBBrowser::DB::Firebird;

use warnings;
use strict;
use 5.016;

use File::Basename        qw( basename );
use File::Spec::Functions qw( catfile );

use DBI             qw();
use List::MoreUtils qw( uniq );

use Term::Choose::Util qw();

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
    return 'Firebird';
}


sub get_db_handle {
    my ( $sf, $db ) = @_;
    my $cred = App::DBBrowser::Credentials->new( $sf->{i}, $sf->{o} );
    my $dsn = "dbi:Firebird:dbname=$db";
    my $show_sofar = 'DB '. basename( $db );
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
    my $connect_attr = $sf->{o}{connect_attr};
    my $dbh_attributes = {};

    for my $key ( keys %$connect_attr ) {
        if ( ! length $connect_attr->{$key} ) {
            next;
        }
        elsif ( $key =~ /^(?:ib_dialect|ib_role|ib_charset)\z/ ) {
            $dsn .= ";$key=$connect_attr->{$key}";
        }
        else {
            $dbh_attributes->{$key} = $connect_attr->{$key};
        }
    }
    my $user = $cred->get_login( 'user', $show_sofar );
    $show_sofar .= "\n" . 'User: ' . $user if defined $user;
    my $passwd = $cred->get_login( 'pass', $show_sofar );
    my $dbh = DBI->connect( $dsn, $user, $passwd, {
        PrintError => 0,
        RaiseError => 1,
        AutoCommit => 1,
        ShowErrorStatement => 1,
        %$dbh_attributes,
    } );
    return $dbh;
}


sub get_databases {
    my ( $sf ) = @_;
    return \@ARGV if @ARGV;
    my $file_firebird_dbs = sprintf $sf->{i}{db_cache_file_fmt}, $sf->{i}{plugin};
    my $ax = App::DBBrowser::Auxil->new( {}, {}, {} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $saved_databases = $ax->read_json( $file_firebird_dbs ) // [];
    my $databases = [ @$saved_databases ];
    if ( ! $sf->{i}{search} && @$databases ) {
        return $databases;
    }
    my @pre = ( undef );
    my ( $confirm, $add, $remove ) = ( '  Confirm', '- Add', '- Remove' );
    my $changed = 0;

    while ( 1 ) {
        my $info = join( "\n", 'Databases: ', @$databases, '' );
        # Choose
        my $choice = $tc->choose(
            [ @pre, $confirm, $add, $remove ],
            { %{$sf->{i}{lyt_v}}, info => $info, undef => '  <=' }
        );
        $ax->print_sql_info( $info );
        if ( ! defined $choice ) {
            return $saved_databases;
        }
        elsif ( $choice eq $confirm ) {
            if ( $changed ) {
                $ax->write_json( $file_firebird_dbs, $databases );
            }
            return $databases;
        }
        elsif ( $choice eq $add ) {
            my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
            my $new = $tu->choose_a_file( {
                info => $info,
                prompt => 'Choose the database location:',
                cs_label => 'Database: ',
                prompt2 => 'Your choice:'
            } );
            if ( length $new ) {
                $databases = [ uniq sort( @$databases, $new ) ];
                $changed++;
            }
        }
        elsif ( $choice eq $remove ) {
            my $info = 'Remove database';
            my @pre = ( undef );
            my $idx = $tc->choose( [ @pre, @$databases ], { info => $info, index => 1, layout => 2 } );
            if ( $idx ) {
                splice( @$databases, $idx - @pre, 1 );
                $changed++;
            }
        }
    }
}






1;

__END__
