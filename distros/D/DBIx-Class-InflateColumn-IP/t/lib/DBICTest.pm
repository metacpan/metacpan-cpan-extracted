package # hide from PAUSE 
    DBICTest;

use strict;
use warnings;
use DBICTest::Schema;

=head1 NAME

DBICTest - Library to be used by DBIx::Class test scripts.

=head1 SYNOPSIS

  use lib qw(t/lib);
  use DBICTest;
  use Test::More;
  
  my $schema = DBICTest->init_schema();

=head1 DESCRIPTION

This module provides the basic utilities to write tests against 
DBIx::Class.

=head1 METHODS

=head2 init_schema

  my $schema = DBICTest->init_schema(
    no_deploy=>1,
    no_populate=>1,
  );

This method removes the test SQLite database in t/var/DBIxClass.db 
and then creates a new, empty database.

This method will call deploy_schema() by default, unless the 
no_deploy flag is set.

Also, by default, this method will call populate_schema() by 
default, unless the no_deploy or no_populate flags are set.

=cut

sub init_schema {
    my $self = shift;
    my %args = @_;
    my $db_file = "t/var/DBIxClass.db";

    unlink($db_file) if -e $db_file;
    unlink($db_file . "-journal") if -e $db_file . "-journal";
    mkdir("t/var") unless -d "t/var";

    my $dsn = $ENV{"DBICTEST_DSN"} || "dbi:SQLite:${db_file}";
    my $dbuser = $ENV{"DBICTEST_DBUSER"} || '';
    my $dbpass = $ENV{"DBICTEST_DBPASS"} || '';

   my $schema = DBICTest::Schema->compose_namespace('DBICTest')
                                ->connect($dsn, $dbuser, $dbpass);
    $schema->storage->on_connect_do(['PRAGMA synchronous = OFF']);
    if ( !$args{no_deploy} ) {
        __PACKAGE__->deploy_schema( $schema );
        __PACKAGE__->populate_schema( $schema ) if( !$args{no_populate} );
    }
    return $schema;
}

=head2 deploy_schema

  DBICTest->deploy_schema( $schema );

This method does one of two things to the schema.  It can either call 
the experimental $schema->deploy() if the DBICTEST_SQLT_DEPLOY environment 
variable is set, otherwise the default is to read in the t/lib/sqlite.sql 
file and execute the SQL within. Either way you end up with a fresh set 
of tables for testing.

=cut

sub deploy_schema {
    my $self = shift;
    my $schema = shift;

    if ($ENV{"DBICTEST_SQLT_DEPLOY"}) {
        return $schema->deploy();
    } else {
        open IN, "t/lib/sqlite.sql";
        my $sql;
        { local $/ = undef; $sql = <IN>; }
        close IN;
        ($schema->storage->dbh->do($_) || print "Error on SQL: $_\n") for split(/;\n/, $sql);
    }
}

=head2 populate_schema

  DBICTest->populate_schema( $schema );

After you deploy your schema you can use this method to populate 
the tables with test data.

=cut

sub populate_schema {
    my $self = shift;
    my $schema = shift;

    $schema->populate('Host', [
        [ qw/hostname address/ ],
        [ 'localhost', 2130706433 ],
    ]);

    $schema->populate('Network', [
       [ qw/netname address/ ],
       [ qw{localnet 127.0.0.0/8} ],
    ]);
}

1;
