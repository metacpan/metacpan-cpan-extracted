use Test::More;
BEGIN: {
    my @missing = ();
    eval "use Catalyst::Model::CDBI";
    push @missing, "Catalyst::Model::CDBI" if $@;
    eval "use Class::DBI::SQLite";
    push @missing, "Class::DBI::SQLite" if $@;
    eval "use YAML";
    push @missing, "YAML" if $@;
    if ( @missing ) {
        plan skip_all => "The following are required to run the test app: " .
                         join(', ', @missing);
    }
    else {
        plan tests => 3;
    }
}
use lib 't/MyApp/lib';
use FindBin;
use YAML ();
use DBI;
use File::Spec;

my $home = File::Spec->catfile( $FindBin::Bin, 'MyApp' );
my $db_file = File::Spec->catfile( $home, 'myapp.db' );

open my $DB, '>', $db_file or die "Couldn't open database file $db_file: $!";
close $DB or die "Couldn't close database file $db_file: $!";

my $config = YAML::LoadFile( File::Spec->catfile($home, 'MyApp.yml' ) );
my $dsn    = $config->{dsn};
$dsn      =~ s/__HOME__/$home/;
my $dbh    = DBI->connect($dsn);

ok(
    $dbh->do( qq{ CREATE TABLE artist (
        artistid INTEGER PRIMARY KEY,
        name VARCHAR(255)
    ) } ),
    "Create artist table"
);

ok( 
    $dbh->do( qq{ CREATE TABLE cd (
        cdid INTEGER PRIMARY KEY,
        artist INTEGER,
        title VARCHAR(255),
        year CHAR(4),
        FOREIGN KEY(artist) REFERENCES cd(artistid)
    ) } ),
    "Create cd table"
);

ok(
    $dbh->do( qq{ CREATE TABLE liner_notes (
        cdid INTEGER PRIMARY KEY,
        notes TEXT
    ) } ),
    "Create liner_notes table"
);
