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

sub _database {
    my $self = shift;
    my $db_file = "t/var/DBIxClass.db";

    unlink($db_file) if -e $db_file;
    unlink($db_file . "-journal") if -e $db_file . "-journal";
    mkdir("t/var") unless -d "t/var";

    my $dsn = $ENV{"DBICTEST_DSN"} || "dbi:SQLite:${db_file}";
    my $dbuser = $ENV{"DBICTEST_DBUSER"} || '';
    my $dbpass = $ENV{"DBICTEST_DBPASS"} || '';

    my @connect_info = ($dsn, $dbuser, $dbpass, { AutoCommit => 1 });

    return @connect_info;
}

sub rst
{
	DBICTest::DimCity->ignore_columns(undef);
	DBICTest::DimCountry->ignore_columns(undef);
	DBICTest::DimDate->ignore_columns(undef);
	DBICTest::DimRegion->ignore_columns(undef);
	DBICTest::DimTime->ignore_columns(undef);
	DBICTest::FactA->ignore_columns(undef);
	DBICTest::FactB->ignore_columns(undef);
}

sub init_schema {
    my $self = shift;
    my %args = @_;

    my $schema;

    if ($args{compose_connection}) {
      $schema = DBICTest::Schema->compose_connection(
                  'DBICTest', $self->_database
                );
    } else {
      $schema = DBICTest::Schema->compose_namespace('DBICTest');
    }
    if ( !$args{no_connect} ) {
      $schema = $schema->connect($self->_database);
      $schema->storage->on_connect_do(['PRAGMA synchronous = OFF']);
    }
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

sub populate_schema
{
    my $self   = shift;
    my $schema = shift;

    $schema->populate(
        'DimDate',
        [
            [qw/date_id day_of_week day_of_month day_of_year/],
            [ 1, 1, 1, 30 ],
            [ 2, 5, 9, 28 ],
            [ 3, 2, 7, 13 ]
        ]
    );

    $schema->populate(
        'DimTime',
        [
            [qw/time_id hour minute/],
            [ 1, 14, 10 ],
            [ 2, 2,  15 ],
            [ 3, 7,  11 ],
            [ 4, 2,  9 ]
        ]
    );

    $schema->populate(
        'FactA',
        [
            [qw/fact_id date_id time_id fact/],
            [ 1, 1, 1, 'foo' ],
            [ 2, 3, 2, 'bar' ],
            [ 3, 1, 2, 'baz' ],
            [ 4, 2, 3, 'fish' ],
        ]
    );

    $schema->populate(
        'DimCountry',
        [
            [qw/ country_id country/],
            [ 1, 'USA' ],
            [ 2, 'Canada' ],
            [ 3, 'Great Britain' ]
        ]
    );

    $schema->populate(
        'DimRegion',
        [
            [qw/ region_id region country_id/],
            [ 1, 'Missouri',   1 ],
            [ 2, 'California', 1 ],
            [ 3, 'Ontario',    2 ],
            [ 4, 'Quebec',     2 ]
        ]
    );

    $schema->populate(
        'DimCity',
        [
            [ qw/ city_id region_id city/],
            [ 1, 1, 'Mexico'   ],
            [ 2, 1, 'Paris'    ],
            [ 3, 1, 'Rolla'    ],
            [ 4, 1, 'Cuba'     ],
            [ 5, 1, 'Bourbon'  ],
            [ 6, 1, 'St. Louis'],
            [ 7, 2, 'Riverside'],
            [ 8, 2, 'Anaheim'  ],
            [ 9, 3, 'Thunder Bay'],
            [ 10, 4, 'Sioux Lookout']
        ]
    );

    $schema->populate(
        'FactB',
        [
            [ qw/ city_id date_id / ],
            [ 1, 1 ],
            [ 1, 3 ],
            [ 2, 1 ],
            [ 2, 2 ],
            [ 3, 1 ],
            [ 3, 2 ],
            [ 3, 3 ],
            [ 4, 2 ],
            [ 4, 3 ],
            [ 5, 3 ],
            [ 5, 1 ],
            [ 6, 1 ],
            [ 6, 2 ],
            [ 6, 3 ],
        ]
    );

}

1;
