package # hide from PAUSE
App::DBBrowser::DB::SQLite;

use warnings;
use strict;
use 5.016;

use Encode                qw( encode decode );
use File::Find            qw( find );
use File::Spec::Functions qw( catfile );

use DBD::SQLite 1.74;    # sqlite 3.42.0
use DBI            qw();
use Encode::Locale qw();

use Term::Choose       qw();
use Term::Choose::Util qw();

use App::DBBrowser::Auxil;


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
    return 'SQLite';
}


sub get_db_handle {
    my ( $sf, $db ) = @_;
    my $busy_timeout = delete $sf->{o}{connect_attr}{sqlite_busy_timeout};
    my $dsn = "dbi:SQLite:dbname=$db";
    my $dbh = DBI->connect( $dsn, '', '', {
        PrintError => 0,
        RaiseError => 1,
        AutoCommit => 1,
        ShowErrorStatement => 1,
        %{$sf->{o}{connect_attr}//{}}, ##

    } );
    if ( DBI::looks_like_number( $busy_timeout ) ) { ##
        $dbh->sqlite_busy_timeout( 0 + $busy_timeout );
    }
    return $dbh;
}


sub get_databases {
    my ( $sf ) = @_;
    return \@ARGV if @ARGV;
    my $cache_sqlite_files = sprintf $sf->{i}{db_cache_file_fmt}, $sf->{i}{plugin};
    my $ax = App::DBBrowser::Auxil->new( {}, {}, {} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $db_cache = $ax->read_json( $cache_sqlite_files ) // {};
    my $dirs = $db_cache->{directories} // [ $sf->{i}{home_dir} ];
    my $databases = $db_cache->{databases} // [];
    if ( ! $sf->{i}{search} && @$databases ) {
        return $databases;
    }
    while ( 1 ) {
        my ( $ok, $change ) = ( '- Confirm', '- Change' );
        # Choose
        my $choice = $tc->choose(
            [ undef, $ok, $change ],
            { %{$sf->{i}{lyt_v}}, prompt => 'Search databases in: ' . join( ', ', @$dirs ), info => 'SQLite' }
        );
        if ( ! defined $choice ) {
            return $databases;
        }
        elsif ( $choice eq $change ) {
            my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
            #my $info = 'Curr: ' . join( ', ', @$dirs ); #
            my $new_dirs = $tu->choose_directories( { confirm => $sf->{i}{_confirm}, back => $sf->{i}{_back} } );
            if ( ! @{$new_dirs//[]} ) {
                next;
            }
            $dirs = $new_dirs;
        }
        else {
            last;
        }
    }
    $databases = [];
    local $| = 1;
    print 'Searching ... ';
    my $encoding = Encode::find_encoding( 'locale_fs' );
    if ( $sf->{o}{G}{file_find_warnings} ) {
        my $file;
        for my $dir ( @$dirs ) {
            File::Find::find( {
                wanted => sub {
                    #my $file_fs = $_;
                    return if ! -f $_;
                    $file = $encoding->decode( $_ );
                    print "$file\n";
                    if ( ! eval {
                        open my $fh, '<:raw', $_ or die "$file: $!";
                        defined( read $fh, my $string, 13 ) or die "$file: $!";
                        close $fh;
                        push @$databases, $file if $string eq 'SQLite format';
                        1 }
                    ) {
                        utf8::decode( $@ );
                        print $@;
                    }
                },
                no_chdir => 1,
            },
            $encoding->encode( $dir ) );
        }
        $tc->choose(
            [ 'Press ENTER to continue' ],
            { prompt => 'Search finished.' }
        );
    }
    else {
        no warnings qw( File::Find );
        my $file;
        for my $dir ( @$dirs ) {
            File::Find::find( {
                wanted => sub {
                    #my $file_fs = $_;
                    return if ! -f $_;
                    $file = $encoding->decode( $_ );
                    print "$file\n";
                    eval {
                        open my $fh, '<:raw', $_ or die "$file: $!";
                        defined( read $fh, my $string, 13 ) or die "$file: $!";
                        close $fh;
                        push @$databases, $file if $string eq 'SQLite format';
                    };
                },
                no_chdir => 1,
            },
            $encoding->encode( $dir ) );
        }
    }
    print 'Ended searching' . "\n";
    $db_cache->{directories} = $dirs;
    $databases = [ sort { $a cmp $b } @$databases ];
    $db_cache->{databases} = $databases;
    $ax->write_json( $cache_sqlite_files, $db_cache );
    return $databases;
}








1;


__END__
