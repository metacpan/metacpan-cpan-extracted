package # hide from PAUSE
App::DBBrowser::DB::DuckDB;

use warnings;
use strict;
use 5.016;

use DBI             qw();
use List::MoreUtils qw( uniq );

use Term::Choose::Util qw();


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
    return 'DuckDB';
}


sub get_db_handle {
    my ( $sf, $db ) = @_;
    my $dsn = "dbi:DuckDB:dbname=$db";
    my $dbh = DBI->connect( $dsn, '', '', {
        PrintError => 0,
        RaiseError => 1,
        AutoCommit => 1,
        ShowErrorStatement => 1,
        #%{$sf->{o}{connect_attr}//{}},
    } );
    return $dbh;
}


sub get_databases {
    my ( $sf ) = @_;
    return \@ARGV if @ARGV;
    my $file_duckdb_dbs = sprintf $sf->{i}{db_cache_file_fmt}, $sf->{i}{plugin}; ##
    my $ax = App::DBBrowser::Auxil->new( {}, {}, {} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $saved_databases = $ax->read_json( $file_duckdb_dbs ) // [];
    my $databases = [ @$saved_databases ];
    if ( ! $sf->{i}{search} && @$databases ) {
        return $databases;
    }
    my @pre = ( undef );
    my ( $confirm, $add, $remove ) = ( '  Confirm', '- Add Database', '- Remove Database' );

    while ( 1 ) {
        my $info = join( "\n", 'Databases: ', @$databases, '' );
        # Choose
        my $choice = $tc->choose(
            [ @pre, $confirm, $add, $remove ],
            { %{$sf->{i}{lyt_v}}, info => $info, undef => $sf->{i}{_back} }
        );
        $ax->print_sql_info( $info );
        if ( ! defined $choice ) {
            return $saved_databases;
        }
        elsif ( $choice eq $confirm ) {
            $ax->write_json( $file_duckdb_dbs, $databases );
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
            }
        }
        elsif ( $choice eq $remove ) {
            my $info = 'Remove database';
            my @pre = ( undef );
            my $idx = $tc->choose( [ @pre, @$databases ], { info => $info, index => 1, layout => 2 } );
            if ( $idx ) {
                splice( @$databases, $idx - @pre, 1 );
            }
        }
    }
}




1;

__END__
