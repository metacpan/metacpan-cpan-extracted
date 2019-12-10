package # hide from PAUSE
App::DBBrowser::DB::SQLite;

use warnings;
use strict;
use 5.010001;

use Encode                qw( encode decode );
use File::Find            qw( find );
use File::Spec::Functions qw( catfile );

use DBI            qw();
use Encode::Locale qw();

use Term::Choose       qw();
use Term::Choose::Util qw();

use App::DBBrowser::Auxil;
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
    return 'SQLite';
}


sub set_attributes {
    my ( $sf ) = @_;
    return [
        { name => 'sqlite_unicode',             default => 1, values => [ 0, 1 ] },
        { name => 'sqlite_see_if_its_a_number', default => 1, values => [ 0, 1 ] },
    ];
}


sub get_db_handle {
    my ( $sf, $db ) = @_;
    my $db_opt_get = App::DBBrowser::Opt::DBGet->new( $sf->{i}, $sf->{o} );
    my $attributes = $db_opt_get->attributes( $db );
    my $dsn = "dbi:$sf->{i}{driver}:dbname=$db";
    my $dbh = DBI->connect( $dsn, '', '', {
        PrintError => 0,
        RaiseError => 1,
        AutoCommit => 1,
        ShowErrorStatement => 1,
        %$attributes,
    } ) or die DBI->errstr;
    return $dbh;
}


sub get_databases {
    my ( $sf ) = @_;
    return \@ARGV if @ARGV;
    my $cache_sqlite_files = catfile $sf->{i}{app_dir}, 'cache_SQLite_files.json';
    my $ax = App::DBBrowser::Auxil->new( {}, {}, {} );
    my $db_cache = $ax->read_json( $cache_sqlite_files );
    my $dirs = $db_cache->{directories} || [ $sf->{i}{home_dir} ];
    my $databases = $db_cache->{databases} || [];
    if ( ! $sf->{i}{sqlite_search} && @$databases ) {
        return $databases;
    }
    my ( $ok, $change ) = ( '- Confirm', '- Change' );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $choice = $tc->choose(
        [ undef, $ok, $change ],
        { %{$sf->{i}{lyt_v_clear}}, prompt => 'Search path: ' . join( ', ', @$dirs ), info => 'SQLite Databases' }
    );
    if ( ! defined $choice ) {
        return $databases;
    }
    if ( $choice eq $change ) {
        my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
        my $info = 'Curr: ' . join( ', ', @$dirs );
        my $name = 'Dirs: ';
        my $new_dirs = $tu->choose_directories(
            { cs_label => $name, info => "Where to search for databases?\n" . $info }
        );
        if ( defined $new_dirs && @$new_dirs ) {
            $dirs = $new_dirs;
        }
    }
    $databases = [];
    local $| = 1;
    print 'Searching ... ';
    if ( $sf->{o}{G}{file_find_warnings} ) {
        for my $dir ( @$dirs ) {
            File::Find::find( {
                wanted => sub {
                    my $file_fs = $_;
                    return if ! -f $file_fs;
                    my $file = decode( 'locale_fs', $file_fs );
                    print "$file\n";
                    if ( ! eval {
                        open my $fh, '<:raw', $file_fs or die "$file: $!";
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
            encode( 'locale_fs', $dir ) );
        }
        $tc->choose(
            [ 'Press ENTER to continue' ],
            { prompt => 'Search finished.' }
        );
    }
    else {
        no warnings qw( File::Find );
        for my $dir ( @$dirs ) {
            File::Find::find( {
                wanted => sub {
                    my $file_fs = $_;
                    return if ! -f $file_fs;
                    my $file = decode( 'locale_fs', $file_fs );
                    print "$file\n";
                    eval {
                        open my $fh, '<:raw', $file_fs or die "$file: $!";
                        defined( read $fh, my $string, 13 ) or die "$file: $!";
                        close $fh;
                        push @$databases, $file if $string eq 'SQLite format';
                    };
                },
                no_chdir => 1,
            },
            encode( 'locale_fs', $dir ) );
        }
    }
    print 'Ended searching' . "\n";
    $db_cache->{directories} = $dirs;
    $db_cache->{databases} = $databases;
    $ax->write_json( $cache_sqlite_files, $db_cache );
    return $databases;
}








1;


__END__
