#
# This file is part of DBIx-Class-InflateColumn-Serializer-CompressJSON
#
# This software is copyright (c) 2012 by Weborama.  No
# license is granted to other entities.
#
package # hide from PAUSE 
   DBICTest;

use strict;
use warnings;

use strict;
use warnings;
use DBICTest::Schema;

sub populate_schema {

}

sub has_custom_dsn {
	return $ENV{"DBICTEST_DSN"} ? 1:0;
}

sub _sqlite_dbfilename {
    return "t/var/DBIxClass.db";
}

sub _sqlite_dbname {
    my $self = shift;
    my %args = @_;
    return $self->_sqlite_dbfilename if $args{sqlite_use_file} or $ENV{"DBICTEST_SQLITE_USE_FILE"};
	return ":memory:";
}

sub _database {
    my $self = shift;
    my %args = @_;
    my $db_file = $self->_sqlite_dbname(%args);

    unlink($db_file) if -e $db_file;
    unlink($db_file . "-journal") if -e $db_file . "-journal";
    mkdir("t/var") unless -d "t/var";

    my $dsn = $ENV{"DBICTEST_DSN"} || "dbi:SQLite:${db_file}";
    my $dbuser = $ENV{"DBICTEST_DBUSER"} || '';
    my $dbpass = $ENV{"DBICTEST_DBPASS"} || '';

    my @connect_info = ($dsn, $dbuser, $dbpass, { AutoCommit => 1, %args });

    return @connect_info;
}

sub init_schema {
    my $self = shift;
    my %args = @_;

    my $schema;
    
    $args{'no_deploy'} = $ENV{'DBICTEST_NODEPLOY'} if (defined $ENV{'DBICTEST_NODEPLOY'});

    if ($args{compose_connection}) {
      $schema = DBICTest::Schema->compose_connection(
                  'DBICTest', $self->_database(%args)
                );
    } else {
      $schema = DBICTest::Schema->compose_namespace('DBICTest');
    }
    if( $args{storage_type}) {
    	$schema->storage_type($args{storage_type});
    }    
    if ( !$args{no_connect} ) {
      $schema = $schema->connect($self->_database(%args));
      $schema->storage->on_connect_do(['PRAGMA synchronous = OFF'])
       unless $self->has_custom_dsn;
    }
    if ( !$args{no_deploy} ) {
        __PACKAGE__->deploy_schema( $schema, $args{deploy_args} );
        __PACKAGE__->populate_schema( $schema )
         if( !$args{no_populate} );
    }
    return $schema;
}

sub deploy_schema {
    my $self = shift;
    my $schema = shift;
    my $args = shift || {};

    if ($ENV{"DBICTEST_SQLT_DEPLOY"}) { 
        $schema->deploy($args);    
    } else {
        open IN, "t/lib/sqlite.sql";
        my $sql;
        { local $/ = undef; $sql = <IN>; }
        close IN;
        for my $chunk ( split (/;\s*\n+/, $sql) ) {
          if ( $chunk =~ / ^ (?! --\s* ) \S /xm ) {  # there is some real sql in the chunk - a non-space at the start of the string which is not a comment
            $schema->storage->dbh->do($chunk) or print "Error on SQL: $chunk\n";
          }
        }
    }
    return;
}

1;


1;
