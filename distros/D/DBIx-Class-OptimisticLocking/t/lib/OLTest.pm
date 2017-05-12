package # hide from PAUSE
	OLTest;

use strict;
use warnings;

use File::Spec;
use Cwd qw(abs_path);

my ($vol, $dir, $file) = File::Spec->splitpath(abs_path(__FILE__));

# much of this is ripped directly from DBIx::Class::VirtualColumns (thanks for the jumpstart!)
sub init_schema {
    my $self = shift;
    my %args = @_;

    my $schema;

    if ( $args{compose_connection} ) {
        $schema =
          OLTest::Schema->compose_connection( 'OLTest',
            "dbi:SQLite:$dir/../var/oltest.db", "", "", { AutoCommit => 1 } );
    }
    else {
        $schema = OLTest::Schema->compose_namespace('OLTest');
    }
    if ( !$args{no_connect} ) {
        $schema =
          $schema->connect( "dbi:SQLite:$dir/../var/oltest.db", "", "", { AutoCommit => 1 } );
        $schema->storage->on_connect_do( ['PRAGMA synchronous = OFF'] );
    }
    unless ( $args{no_deploy} ) {
        __PACKAGE__->deploy_schema($schema);
    }
    return $schema;
}

sub deploy_schema {
    my $self   = shift;
    my $schema = shift;

    if ( $ENV{"OLTEST_SQLT_DEPLOY"} ) {
        return $schema->deploy();
    }
    else {
        open IN, "$dir/../var/oltest.sql";
        my $sql;
        { local $/ = undef; $sql = <IN>; }
        close IN;
        ( $schema->storage->dbh->do($_) || print "Error on SQL: $_\n" )
          for split( /;\n/, $sql );
    }
}

1;
