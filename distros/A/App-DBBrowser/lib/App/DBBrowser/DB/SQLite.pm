package # hide from PAUSE
App::DBBrowser::DB::SQLite;

use warnings;
use strict;
use 5.008003;

use Encode                qw( encode decode );
use File::Find            qw( find );
use File::Spec::Functions qw( catfile );

use DBI            qw();
use Encode::Locale qw();

use Term::Choose       qw( choose );
use Term::Choose::Util qw( choose_dirs );

use App::DBBrowser::Auxil;


sub new {
    my ( $class, $info ) = @_;
    my $self = {
        driver  => 'SQLite',
        home_dir => $info->{home_dir},
        app_dir => $info->{app_dir},
        reset_search_cache => $info->{reset_search_cache},
        file_find_warnings => $info->{file_find_warnings},
    };
    bless $self, $class;
}


sub get_db_driver {
    my ( $self ) = @_;
    return $self->{driver};
}


sub set_attributes {
    my ( $self ) = @_;
    return [
        { name => 'sqlite_unicode',             default => 1, values => [ 0, 1 ] },
        { name => 'sqlite_see_if_its_a_number', default => 1, values => [ 0, 1 ] },
    ];
}


sub get_db_handle {
    my ( $self, $db, $parameter ) = @_;
    my $dsn = "dbi:$self->{driver}:dbname=$db";
    my $dbh = DBI->connect( $dsn, '', '', {
        PrintError => 0,
        RaiseError => 1,
        AutoCommit => 1,
        ShowErrorStatement => 1,
        %{$parameter->{attributes}},
    } ) or die DBI->errstr;
    return $dbh;
}


sub get_databases {
    my ( $self ) = @_;
    return \@ARGV if @ARGV;
    my $cache_sqlite_files = catfile $self->{app_dir}, 'cache_SQLite_files.json';
    my $ax = App::DBBrowser::Auxil->new( {}, {}, {} );
    my $db_cache = $ax->read_json( $cache_sqlite_files );
    my $dirs = $db_cache->{directories} || [ $self->{home_dir} ];
    my $databases = $db_cache->{databases} || [];
    if ( ! $self->{reset_search_cache} && @$databases ) {
        return $databases;
    }
    my ( $ok, $change ) = ( '- Confirm', '- Change' );
    my $choice = choose(
        [ undef, $ok, $change ],
        { info => 'SQLite Databases', prompt =>  'Search path: ' . join( ', ', @$dirs ),
          undef => '  BACK', layout => 3, clear_screen => 1 }
    );
    if ( ! defined $choice ) {
        return $databases;
    }
    if ( $choice eq $change ) {
        my $info = 'Del ' . join( ', ', @$dirs );
        my $name = ' OK ';
        my $new_dirs = choose_dirs( { info => "Where to search for databases?\n" . $info, name => $name } );
        if ( defined $new_dirs && @$new_dirs ) {
            $dirs = $new_dirs;
        }
    }
    $databases = [];
    local $| = 1;
    print 'Searching ... ';
    if ( $self->{file_find_warnings} ) {
        for my $dir ( @$dirs ) {
            File::Find::find( {
                wanted => sub {
                    my $file = $_;
                    return if ! -f $file;
                    print "$file\n";
                    if ( ! eval {
                        open my $fh, '<:raw', $file or die "$file: $!";
                        defined( read $fh, my $string, 13 ) or die "$file: $!";
                        close $fh;
                        push @$databases, decode( 'locale_fs', $file ) if $string eq 'SQLite format';
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
        choose( [ 'Press ENTER to continue' ], { prompt => 'Search finished.' } );
    }
    else {
        no warnings qw( File::Find );
        for my $dir ( @$dirs ) {
            File::Find::find( {
                wanted => sub {
                    my $file = $_;
                    return if ! -f $file;
                    print "$file\n";
                    eval {
                        open my $fh, '<:raw', $file or die "$file: $!";
                        defined( read $fh, my $string, 13 ) or die "$file: $!";
                        close $fh;
                        push @$databases, decode( 'locale_fs', $file ) if $string eq 'SQLite format';
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
