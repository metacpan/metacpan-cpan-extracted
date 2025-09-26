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
    return 'Firebird';
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


sub read_attributes {
    my ( $sf ) = @_;
    return [
        { name => 'ib_dialect',                    },
        { name => 'ib_role',                       },
        { name => 'ib_charset',  default => 'UTF8' },
        { name => 'LongReadLen', default => 80     },
    ];
}


sub set_attributes {
    my ( $sf ) = @_;
    return [
        { name => 'ib_enable_utf8', default => 1, values => [ 0, 1 ] },
        { name => 'LongTruncOk',    default => 0, values => [ 0, 1 ] },
        { name => 'ChopBlanks',     default => 0, values => [ 0, 1 ] },
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
    my $dsn = "dbi:$sf->{i}{driver}:dbname=$db";
    my $show_sofar = 'DB '. basename( $db );
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
    my $dbh_attributes = $set_attributes;

    for my $key ( keys %$read_attributes ) {
        if ( $key =~ /^(?:ib_dialect|ib_role|ib_charset)\z/ ) {
            #$show_sofar .= "\n" . $key . ': ' . $read_attributes->{$key};
            $dsn .= ";$key=$read_attributes->{$key}";
        }
        else {
            $dbh_attributes->{$key} = $read_attributes->{$key};
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
        %$dbh_attributes,
    } );
    return $dbh;
}


sub get_databases {
    my ( $sf ) = @_;
    return \@ARGV if @ARGV;
    my $file_firebird_dbs = catfile $sf->{i}{app_dir}, 'Firebird_databases.json';
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
