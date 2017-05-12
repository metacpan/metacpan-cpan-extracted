#!/usr/bin/perl

use strict;
use Test::More;
use DBI;

# use warnings;
# use Data::Dumper;

############################
## get DB connection info ##
############################

use lib 'testconfig';
my $Config;
eval q[
    use DBIx::TableReferences::MSSQL::TestConfig;
    $Config = DBIx::TableReferences::MSSQL::TestConfig->Config;
];

###################
## DB connection ##
###################

if ($Config->{server} =~ /^skip$/i) {
    plan skip_all => "User has skipped the test suite. Run `perl Makefile.PL "
                   . "-s` to reconfigure the connection parameters for the "
		   . "test database.";
}

my $dbh = eval {
    my $dsn = join ';',map {"$_=$Config->{$_}"} qw/Server database uid pwd/;
    $dsn = "dbi:ODBC:driver=\{SQL Server\};$dsn;";
    DBI->connect( $dsn )
};

if (not $dbh) {
    plan skip_all => "Couldn't connect to the database for testing. Run `perl "
                   . "Makefile.PL -s` to reconfigure the connection parameters "
		   . "for the test database.";

} else {
    plan tests => 31;
    diag "Starting test suite. Run `perl Makefile.PL -s` to reconfigure "
       . "connection parameters for the test database.";
}

diag "Dropping tables if they exist";
for (qw/DBIx_TR_TEMP_FKTABLE 
        DBIx_TR_TEMP_FKTABLE1 
        DBIx_TR_TEMP_FKTABLE2 
        DBIx_TR_TEMP_FKTABLE3 
        DBIx_TR_TEMP_FKTABLE4 
        DBIx_TR_TEMP_PKTABLE 
        DBIx_TR_TEMP_PKTABLE1/) {
    $dbh->do( qq{
        IF EXISTS ( select 1 
                    from sysobjects 
                    where name = '$_' and uid = user_id('dbo')) 
            DROP TABLE [dbo].[$_]
        }
    );
}

diag "Creating tables and referential constraints";
$dbh->do($_) for (split /;/, <<"END_OF_SQL");

    create table [dbo].[DBIx_TR_TEMP_PKTABLE] (
        id              int PRIMARY KEY,
        name            varchar(50) not null
    );
    create table [dbo].[DBIx_TR_TEMP_FKTABLE] (
        id              int PRIMARY KEY,
        pid             int NOT NULL
    );
    
    ALTER TABLE [dbo].[DBIx_TR_TEMP_FKTABLE]
    ADD CONSTRAINT [fk_fktable] FOREIGN KEY ([pid]) 
    REFERENCES [dbo].[DBIx_TR_TEMP_PKTABLE] ([id]);
    
    create table [dbo].[DBIx_TR_TEMP_PKTABLE1] (
        id1             int NOT NULL,
        id2             int NOT NULL,
        name            varchar(50) not null
    );

    ALTER TABLE [dbo].[DBIx_TR_TEMP_PKTABLE1] 
    ADD CONSTRAINT [pk_table1] PRIMARY KEY ([id1],[id2])

    create table [dbo].[DBIx_TR_TEMP_FKTABLE1] (
        id              int PRIMARY KEY,
        pid1            int NOT NULL,
        pid2            int NOT NULL
    );
    
    create table [dbo].[DBIx_TR_TEMP_FKTABLE2] (
        id              int PRIMARY KEY
    );
    
    ALTER TABLE [dbo].[DBIx_TR_TEMP_FKTABLE1]
    ADD CONSTRAINT [fk_fktable1] FOREIGN KEY ([pid1],[pid2]) 
    REFERENCES [dbo].[DBIx_TR_TEMP_PKTABLE1] ([id1],[id2]);

    ALTER TABLE [dbo].[DBIx_TR_TEMP_FKTABLE2]
    ADD CONSTRAINT [fk_fktable2_casc_del] FOREIGN KEY ([id])
    REFERENCES [dbo].[DBIx_TR_TEMP_PKTABLE] ([id])
    ON DELETE CASCADE;
    
    ALTER TABLE [dbo].[DBIx_TR_TEMP_FKTABLE2]
    ADD CONSTRAINT [fk_fktable2_casc_upd] FOREIGN KEY ([id])
    REFERENCES [dbo].[DBIx_TR_TEMP_PKTABLE] ([id])
    ON UPDATE CASCADE;

    ALTER TABLE [dbo].[DBIx_TR_TEMP_FKTABLE2]
    ADD CONSTRAINT [fk_fktable2_nfr] FOREIGN KEY ([id])
    REFERENCES [dbo].[DBIx_TR_TEMP_PKTABLE] ([id])
    NOT FOR REPLICATION;

    create table [dbo].[DBIx_TR_TEMP_FKTABLE3] (
        id              int PRIMARY KEY
    );
    
    ALTER TABLE [dbo].[DBIx_TR_TEMP_FKTABLE3]
    ADD CONSTRAINT [fk_fktable3_casc_del_nfr] FOREIGN KEY ([id])
    REFERENCES [dbo].[DBIx_TR_TEMP_PKTABLE] ([id])
    ON DELETE CASCADE NOT FOR REPLICATION;
    
    create table [dbo].[DBIx_TR_TEMP_FKTABLE4] (
        id              int PRIMARY KEY
    );
    
    ALTER TABLE [dbo].[DBIx_TR_TEMP_FKTABLE4]
    ADD CONSTRAINT [fk_fktable4_casc_upd_nfr] FOREIGN KEY ([id])
    REFERENCES [dbo].[DBIx_TR_TEMP_PKTABLE] ([id])
    ON UPDATE CASCADE NOT FOR REPLICATION;
    
    
END_OF_SQL

####################
## initialization ##
####################

diag "Running tests";
use lib 'lib';
use_ok('DBIx::TableReferences::MSSQL');

my $tr = DBIx::TableReferences::MSSQL->new( $dbh );

ok( $tr->isa('DBIx::TableReferences::MSSQL') , 'ISA is as expected');

my @tables = $tr->reftables('DBIx_TR_TEMP_FKTABLE');
ok( @tables == 1, 'FKTABLE has 1 reference');
ok("@tables" eq "dbo.DBIx_TR_TEMP_PKTABLE", "FKTABLE references PKTABLE");

@tables = $tr->reftables('DBIx_TR_TEMP_FKTABLE1');
ok( @tables == 1, 'FKTABLE1 has 1 reference');
ok("@tables" eq "dbo.DBIx_TR_TEMP_PKTABLE1", "FKTABLE1 references PKTABLE1");

@tables = $tr->reftables('DBIx_TR_TEMP_PKTABLE');
ok( @tables == 0, 'PKTABLE has 0 references');

@tables = $tr->reftables('DBIx_TR_TEMP_PKTABLE1');
ok( @tables == 0, 'PKTABLE1 has 0 references');

my $refs = $tr->references('DBIx_TR_TEMP_FKTABLE');
ok ($refs->[0]->{table} eq 'DBIx_TR_TEMP_FKTABLE', 'Table name');
ok ($refs->[0]->{owner} eq 'dbo', 'Table owner');
ok ("@{$refs->[0]->{cols}}" eq 'pid', 'Columns'); 
ok ($refs->[0]->{reftable} eq 'DBIx_TR_TEMP_PKTABLE', 'Referenced table name');
ok ($refs->[0]->{refowner} eq 'dbo', 'Referenced table owner');
ok ("@{$refs->[0]->{refcols}}" eq 'id', 'Referenced table columns'); 
ok ($refs->[0]->{sql_add} eq qq{ALTER TABLE [dbo].[DBIx_TR_TEMP_FKTABLE]\nADD CONSTRAINT [fk_fktable] FOREIGN KEY (\n\t[pid]\n)\nREFERENCES [dbo].[DBIx_TR_TEMP_PKTABLE] (\n\t[id]\n)}, 'SQL Add');
ok ($refs->[0]->{sql_drop} eq qq{ALTER TABLE [dbo].[DBIx_TR_TEMP_FKTABLE] DROP CONSTRAINT [fk_fktable]}, 'SQL Drop');

$refs = $tr->references('dbo.DBIX_TR_TEMP_FKTABLE1');
ok ($refs->[0]->{table} eq 'DBIx_TR_TEMP_FKTABLE1', 'Table name');
ok ($refs->[0]->{owner} eq 'dbo', 'Table owner');
ok ("@{$refs->[0]->{cols}}" eq 'pid1 pid2', 'Columns'); 
ok ($refs->[0]->{reftable} eq 'DBIx_TR_TEMP_PKTABLE1', 'Referenced table name');
ok ($refs->[0]->{refowner} eq 'dbo', 'Referenced table owner');
ok ("@{$refs->[0]->{refcols}}" eq 'id1 id2', 'Referenced table columns'); 
ok ($refs->[0]->{sql_add} eq qq{ALTER TABLE [dbo].[DBIx_TR_TEMP_FKTABLE1]\nADD CONSTRAINT [fk_fktable1] FOREIGN KEY (\n\t[pid1],[pid2]\n)\nREFERENCES [dbo].[DBIx_TR_TEMP_PKTABLE1] (\n\t[id1],[id2]\n)}, 'SQL Add');
ok ($refs->[0]->{sql_drop} eq qq{ALTER TABLE [dbo].[DBIx_TR_TEMP_FKTABLE1] DROP CONSTRAINT [fk_fktable1]}, 'SQL Drop');
ok ($refs->[0]->{constraint} eq 'fk_fktable1', 'Constraint name');

$refs = $tr->references('dbo.DBIx_TR_TEMP_FKTABLE2');
ok (@{$refs} == 3, 'Reference count');
for (@{$refs}) {
    my $sql = 'FAIL UNLESS WE ENCOUNTER AN EXPECTED FK';
    if ($_->{constraint} eq 'fk_fktable2_casc_del') {
        $sql = 'ON DELETE CASCADE';
    } elsif ($_->{constraint} eq 'fk_fktable2_casc_upd') {
        $sql = 'ON UPDATE CASCADE';
    } elsif ($_->{constraint} eq 'fk_fktable2_nfr') {
        $sql = 'NOT FOR REPLICATION';
    }
    ok ($_->{sql_add} =~ /$sql$/, $sql);
}

$refs = $tr->references('dbo.DBIx_TR_TEMP_FKTABLE3');
ok ($refs->[0]->{sql_add} =~ /ON DELETE CASCADE NOT FOR REPLICATION$/, 'ON DELETE CASCADE NOT FOR REPLICATION');

$refs = $tr->references('dbo.DBIx_TR_TEMP_FKTABLE4');
ok ($refs->[0]->{sql_add} =~ /ON UPDATE CASCADE NOT FOR REPLICATION$/, 'ON UPDATE CASCADE NOT FOR REPLICATION');

#############
## cleanup ##
#############

END {
exit;    if ($dbh and $dbh->{Active}) {
        diag "Dropping tables";
        $dbh->do($_) for (split /\s*;\s*/, <<'        END_OF_SQL');
            drop table dbo.DBIx_TR_TEMP_FKTABLE2;
            drop table dbo.DBIx_TR_TEMP_FKTABLE1;
            drop table dbo.DBIx_TR_TEMP_FKTABLE;
            drop table dbo.DBIx_TR_TEMP_PKTABLE1;
            drop table dbo.DBIx_TR_TEMP_PKTABLE;
        END_OF_SQL

        diag "Disconnecting from database";
        $dbh->disconnect;
    }
}
