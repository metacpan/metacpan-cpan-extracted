package # hide from PAUSE
App::DBBrowser::DB::mysql;

use warnings;
use strict;
use 5.008003;

use File::Basename qw( basename );

use DBI qw();

use App::DBBrowser::Credentials;


sub new {
    my ( $class, $info ) = @_;
    my $self = {
        driver       => 'mysql',
        app_dir      => $info->{app_dir},
        add_metadata => $info->{add_metadata},
    };
    bless $self, $class;
}


sub get_db_driver {
    my ( $self ) = @_;
    return $self->{driver};
}


sub env_variables {
    my ( $self ) = @_;
    return [ qw( DBI_DSN DBI_HOST DBI_PORT DBI_USER DBI_PASS ) ];
}


sub read_arguments {
    my ( $self ) = @_;
    return [
        { name => 'host', prompt => "Host",     secret => 0 },
        { name => 'port', prompt => "Port",     secret => 0 },
        { name => 'user', prompt => "User",     secret => 0 },
        { name => 'pass', prompt => "Password", secret => 1 },
    ];
}


sub set_attributes {
    my ( $self ) = @_;
    return [
        { name => 'mysql_enable_utf8',        default => 1, values => [ 0, 1 ] },
        { name => 'mysql_enable_utf8mb4',     default => 0, values => [ 0, 1 ] }, ##
        { name => 'mysql_bind_type_guessing', default => 1, values => [ 0, 1 ] },
    ];
}


sub get_db_handle {
    my ( $self, $db, $parameter ) = @_;
    my $cred = App::DBBrowser::Credentials->new( { parameter => $parameter } );
    my $dsn;
    my $info = 'DB '. basename( $db );
    if ( ! $parameter->{use_env_var}{DBI_DSN} || ! exists $ENV{DBI_DSN} ) {
        $dsn = "dbi:$self->{driver}:dbname=$db";
        my $host = $cred->get_login( 'host', $info );
        if ( defined $host ) {
            $info .= "\n" . 'Host: ' . $host;
            $dsn .= ";host=$host" if length $host;
        }
        my $port = $cred->get_login( 'port', $info );
        if ( defined $port ) {
            $info .= "\n" . 'Port: ' . $port;
            $dsn .= ";port=$port" if length $port;
        }
    }
    my $user   = $cred->get_login( 'user', $info );
    $info .= "\n" . 'User: ' . $user if defined $user;
    my $passwd = $cred->get_login( 'pass', $info );
    my $dbh = DBI->connect( $dsn, $user, $passwd, {
        PrintError => 0,
        RaiseError => 1,
        AutoCommit => 1,
        ShowErrorStatement => 1,
        %{$parameter->{attributes}},
    } ) or die DBI->errstr;
    return $dbh;
}


sub get_databases {
    my ( $self, $parameter ) = @_;
    return \@ARGV if @ARGV;
    my @regex_system_db = ( '^mysql$', '^information_schema$', '^performance_schema$' );
    my $stmt = "SELECT schema_name FROM information_schema.schemata";
    if ( ! $self->{add_metadata} ) {
        $stmt .= " WHERE " . join( " AND ", ( "schema_name NOT REGEXP ?" ) x @regex_system_db );
    }
    $stmt .= " ORDER BY schema_name";
    my $info_database = 'information_schema';
    #print $self->{clear_screen};
    #print "DB: $info_database\n";
    my $dbh = $self->get_db_handle( $info_database, $parameter );
    my $databases = $dbh->selectcol_arrayref( $stmt, {}, $self->{add_metadata} ? () : @regex_system_db );
    $dbh->disconnect(); #
    if ( $self->{add_metadata} ) {
        my $regexp = join '|', @regex_system_db;
        my $user_db   = [];
        my $system_db = [];
        for my $database ( @{$databases} ) {
            if ( $database =~ /(?:$regexp)/ ) {
                push @$system_db, $database;
            }
            else {
                push @$user_db, $database;
            }
        }
        return $user_db, $system_db;
    }
    else {
        return $databases;
    }
}


#sub primary_key_auto {
#    return "INT NOT NULL AUTO_INCREMENT PRIMARY KEY";
#}





1;


__END__
