package # hide from PAUSE
App::DBBrowser::DB::SQLite;

use warnings;
use strict;
use 5.008003;
no warnings 'utf8';

#our $VERSION = '';

use Encode       qw( encode decode );
use File::Find   qw( find );
use Scalar::Util qw( looks_like_number );

use DBI            qw();
use Encode::Locale qw();

use App::DBBrowser::Auxil;



sub new {
    my ( $class, $ref ) = @_;
    $ref->{db_driver} = 'SQLite';
    $ref->{driver_prefix} = 'sqlite';
    $ref->{plugin_api_version} = 1.5;
    bless $ref, $class;
}


sub plugin_api_version {
    my ( $self ) = @_;
    return $self->{plugin_api_version};
}


sub db_driver {
    my ( $self ) = @_;
    return $self->{db_driver};
}


sub driver_prefix {
    my ( $self ) = @_;
    return $self->{driver_prefix};
}


#sub environment_variables {
#    my ( $self ) = @_;
#    return [];
#}


#sub read_arguments {
#    my ( $self ) = @_;
#    return [];
#}


sub choose_arguments {
    my ( $self ) = @_;
    return [
        { name => 'sqlite_unicode',             default_index => 1, avail_values => [ 0, 1 ] },
        { name => 'sqlite_see_if_its_a_number', default_index => 1, avail_values => [ 0, 1 ] },
    ];
}


sub get_db_handle {
    my ( $self, $db, $connect_parameter ) = @_;
    my $dsn = "dbi:$self->{db_driver}:dbname=$db";
    my $dbh = DBI->connect( $dsn, '', '', {
        PrintError => 0,
        RaiseError => 1,
        AutoCommit => 1,
        ShowErrorStatement => 1,
        %{$connect_parameter->{chosen_arg}},
    } ) or die DBI->errstr;
    $dbh->sqlite_create_function( 'regexp', 3, sub {
            my ( $regex, $string, $case_sensitive ) = @_;
            $string = '' if ! defined $string;
            return $string =~ m/$regex/sm if $case_sensitive;
            return $string =~ m/$regex/ism;
        }
    );
    $dbh->sqlite_create_function( 'truncate', 2, sub {
            my ( $number, $places ) = @_;
            return if ! defined $number;
            return $number if ! looks_like_number( $number );
            return sprintf "%.*f", $places, int( $number * 10 ** $places ) / 10 ** $places;
        }
    );
    $dbh->sqlite_create_function( 'bit_length', 1, sub {
            use bytes;
            return length $_[0];
        }
    );
    $dbh->sqlite_create_function( 'char_length', 1, sub {
            return length $_[0];
        }
    );
    return $dbh;
}


sub available_databases {
    my ( $self, $connect_parameter ) = @_;
    return \@ARGV if @ARGV;
    my $dirs = $connect_parameter->{dir_sqlite};
    my $cache_key = $self->{db_plugin} . '_' . join ' ', @$dirs;
    my $auxil = App::DBBrowser::Auxil->new();
    my $db_cache = $auxil->__read_json( $self->{db_cache_file} );
    if ( $self->{sqlite_search} ) {
        delete $db_cache->{$cache_key};
    }
    my $databases = [];
    if ( ! defined $db_cache->{$cache_key} ) {
        print 'Searching...' . "\n";
        for my $dir ( @$dirs ) {
            File::Find::find( {
                wanted => sub {
                    my $file = $_;
                    return if ! -f $file;
                    return if ! -s $file; #
                    return if ! -r $file; #
                    #print "$file\n";
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
        print 'Ended searching' . "\n";
        $db_cache->{$cache_key} = $databases;
        $auxil->__write_json( $self->{db_cache_file}, $db_cache );
    }
    else {
        $databases = $db_cache->{$cache_key};
    }
    return $databases;
}


sub get_schema_names {
    my ( $self, $dbh, $db ) = @_;
    return [ 'main' ];
}


sub get_table_names {
    my ( $self, $dbh, $schema ) = @_;
    my $regexp_system_tbl = '^sqlite_';
    my $stmt = "SELECT name FROM sqlite_master WHERE type = 'table'";
    if ( ! $self->{add_metadata} ) {
        $stmt .= " AND name NOT REGEXP ?";
    }
    $stmt .= " ORDER BY name";
    my $tables = $dbh->selectcol_arrayref( $stmt, {}, $self->{add_metadata} ? () : ( $regexp_system_tbl ) );
    if ( $self->{add_metadata} ) {
        my $user_tbl   = [];
        my $system_tbl = [];
        for my $table ( @{$tables} ) {
            if ( $table =~ /(?:$regexp_system_tbl)/ ) {
                push @$system_tbl, $table;
            }
            else {
                push @$user_tbl, $table;
            }
        }
        push @$system_tbl, 'sqlite_master';
        return $user_tbl, $system_tbl;
    }
    else {
        return $tables;
    }
}


sub primary_key_auto {
    return "INTEGER PRIMARY KEY";
}


sub column_names_and_types {
    my ( $self, $dbh, $db, $schema, $tables ) = @_; # qt_table
    my ( $col_names, $col_types );
    for my $table ( @$tables ) {
        my $sth = $dbh->prepare( "SELECT * FROM $table" );
        $col_names->{$table} = $sth->{NAME};
        $col_types->{$table} = $sth->{TYPE};
    }
    return $col_names, $col_types;
}


sub primary_and_foreign_keys {
    my ( $self, $dbh, $db, $schema, $tables ) = @_;
    my $pk_cols = {};
    my $fks     = {};
    for my $table ( @$tables ) {
        for my $c ( @{$dbh->selectall_arrayref( "pragma foreign_key_list( $table )" )} ) {
            $fks->{$table}{$c->[0]}{foreign_key_col}  [$c->[1]] = $c->[3];
            $fks->{$table}{$c->[0]}{reference_key_col}[$c->[1]] = $c->[4];
            $fks->{$table}{$c->[0]}{reference_table} = $c->[2];
        }
        $pk_cols->{$table} = [ $dbh->primary_key( undef, $schema, $table ) ];
    }
    return $pk_cols, $fks;
}


sub sql_regexp {
    my ( $self, $quote_col, $do_not_match_regexp, $case_sensitive ) = @_;
    if ( $do_not_match_regexp ) {
        return sprintf ' NOT REGEXP(?,%s,%d)', $quote_col, $case_sensitive;
    }
    else {
        return sprintf ' REGEXP(?,%s,%d)', $quote_col, $case_sensitive;
    }
}


sub concatenate {
    my ( $self, $arg ) = @_;
    return join( ' || ', @$arg );
}



# scalar functions

sub epoch_to_datetime {
    my ( $self, $col, $interval ) = @_;
    return "DATETIME($col/$interval,'unixepoch','localtime')";
}

sub epoch_to_date {
    my ( $self, $col, $interval ) = @_;
    return "DATE($col/$interval,'unixepoch','localtime')";
}

sub truncate {
    my ( $self, $col, $precision ) = @_;
    return "TRUNCATE($col,$precision)";
}

sub bit_length {
    my ( $self, $col ) = @_;
    return "BIT_LENGTH($col)";
}

sub char_length {
    my ( $self, $col ) = @_;
    return "CHAR_LENGTH($col)";
}




1;


__END__
