#!/usr/bin/env perl

use strict;
use warnings;

use Carp;
use DBI;
use Getopt::Long::Descriptive;
use Try::Tiny;

my @supported_dbs = qw/
    db2
    default
    mysql
    oracle
    pg
/;

my ( $opt, $usage ) = describe_options(
    "$0 %o",
    [ 'db_version|b=s', 'Database version (mainly for a local DB2 v8 instance) -- optional' ],
    [ 'dsn|d=s',        'Database source name (dsn) to connect to -- required' ],
    [ 'execute|e',      'Execute the database update -- otherwise will just rollback' ],
    [ 'schema|s=s',     'Database schema -- optional' ],
    [ 'pass|p=s',       'Database password -- optional' ],
    [ 'trace|t',        'Enable DBI_TRACE -- optional' ],
    [ 'user|u=s',       'Database username -- optional' ],
    [],
    [ 'help|h',         'Print usage message and exit' ],
);

print( $usage->text ), exit if $opt->help or !$opt->dsn;

my $schema_attributes = {
    AutoCommit => 0,
    RaiseError => 1,
};
if ( $opt->dsn =~ m/db2/i ) {
    $schema_attributes->{db2_set_schema} = $opt->schema
        or croak "***** Must supply a schema for db2.";
}

my $dbh
    = DBI->connect( $opt->dsn, $opt->user, $opt->pass, $schema_attributes )
    or croak "***** Error connecting to db:\n" . $DBI::errstr;

DBI->trace(1) if $opt->trace;

try {
    my %update = map { $_ => \&$_ } @supported_dbs;
    my $code_ref = $update{ lc($dbh->{Driver}{Name}) } || $update{'default'};
    if ( $code_ref ) {
        $code_ref->($dbh);
        if ( $opt->execute ) {
           $dbh->commit;
        }
        else {
            print "***** Rolling back changes as the 'execute' parameter was not passed.\n";
            $dbh->rollback;
        }
    }
    else {
        print "***** Database '" . lc($dbh->{Driver}{Name}) . "' not supported.\n";
    }
}
catch {
    carp "***** Database definition update aborted: $_";
    $dbh->rollback;
}
finally {
    $dbh->disconnect;
};

sub default {
    my $dbh = shift;
    print "Executing 'default' database update.\n";
    my @sql = (

        # audit_log_changeset
        'ALTER TABLE audit_log_changeset RENAME COLUMN "USER" TO "USER_ID"',
        'ALTER TABLE audit_log_changeset RENAME COLUMN "TIMESTAMP" TO "CREATED_ON"',

        # audit_log_action
        'ALTER TABLE audit_log_action RENAME COLUMN "CHANGESET" TO "CHANGESET_ID"',
        'ALTER TABLE audit_log_action RENAME COLUMN "AUDITED_TABLE" TO "AUDITED_TABLE_ID"',
        'ALTER TABLE audit_log_action RENAME COLUMN "TYPE" TO "ACTION_TYPE"',

        # audit_log_change
        'ALTER TABLE audit_log_change RENAME COLUMN "ACTION" TO "ACTION_ID"',
        'ALTER TABLE audit_log_change RENAME COLUMN "FIELD" TO "FIELD_ID"',

        # audit_log_field
        'ALTER TABLE audit_log_field RENAME COLUMN "AUDITED_TABLE" TO "AUDITED_TABLE_ID"',
    );

    $dbh->do($_) for @sql;
}

sub db2 {
    my $dbh = shift;
    print "Executing 'db2' database update.\n";
    my @sql;
    if ( $opt->db_version && $opt->db_version =~ /8\.?/ ) {
        @sql = (
            ### DROP ALL FOREIGN KEY INDEXES

            'DROP INDEX "' . ($opt->schema) . '"."AL_CS_IDX_U"',
            'DROP INDEX "' . ($opt->schema) . '"."AL_A_IDX_AT"',
            'DROP INDEX "' . ($opt->schema) . '"."AL_A_IDX_CS"',
            'DROP INDEX "' . ($opt->schema) . '"."AL_C_IDX_A"',
            'DROP INDEX "' . ($opt->schema) . '"."AL_C_IDX_F"',
            'DROP INDEX "' . ($opt->schema) . '"."AL_F_IDX_AT"',

            ### DROP ALL FOREIGN KEYS

            'ALTER TABLE "' . ($opt->schema) . '"."AUDIT_LOG_CHANGESET" DROP FOREIGN KEY "AL_CS_FK_U"',
            'ALTER TABLE "' . ($opt->schema) . '"."AUDIT_LOG_ACTION"    DROP FOREIGN KEY "AL_A_FK_AT"',
            'ALTER TABLE "' . ($opt->schema) . '"."AUDIT_LOG_ACTION"    DROP FOREIGN KEY "AL_A_FK_CS"',
            'ALTER TABLE "' . ($opt->schema) . '"."AUDIT_LOG_CHANGE"    DROP FOREIGN KEY "AL_C_FK_A"',
            'ALTER TABLE "' . ($opt->schema) . '"."AUDIT_LOG_CHANGE"    DROP FOREIGN KEY "AL_C_FK_F"',
            'ALTER TABLE "' . ($opt->schema) . '"."AUDIT_LOG_FIELD"     DROP FOREIGN KEY "AL_F_FK_AT"',

            ### ALTER TABLE STRUCTURE

            'ALTER TABLE "' . ($opt->schema) . '"."AUDIT_LOG_CHANGESET" RENAME COLUMN "USER"          TO "USER_ID"',
            'ALTER TABLE "' . ($opt->schema) . '"."AUDIT_LOG_CHANGESET" RENAME COLUMN "TIMESTAMP"     TO "CREATED_ON"',
            'ALTER TABLE "' . ($opt->schema) . '"."AUDIT_LOG_ACTION"    RENAME COLUMN "CHANGESET"     TO "CHANGESET_ID"',
            'ALTER TABLE "' . ($opt->schema) . '"."AUDIT_LOG_ACTION"    RENAME COLUMN "AUDITED_TABLE" TO "AUDITED_TABLE_ID"',
            'ALTER TABLE "' . ($opt->schema) . '"."AUDIT_LOG_ACTION"    RENAME COLUMN "TYPE"          TO "ACTION_TYPE"',
            'ALTER TABLE "' . ($opt->schema) . '"."AUDIT_LOG_CHANGE"    RENAME COLUMN "ACTION"        TO "ACTION_ID"',
            'ALTER TABLE "' . ($opt->schema) . '"."AUDIT_LOG_CHANGE"    RENAME COLUMN "FIELD"         TO "FIELD_ID"',
            'ALTER TABLE "' . ($opt->schema) . '"."AUDIT_LOG_FIELD"     RENAME COLUMN "AUDITED_TABLE" TO "AUDITED_TABLE_ID"',

            #### RE-ADD THE INDEXES AND CONSTRAINTS

            # add the foreign key indexes
            'CREATE INDEX "' . ($opt->schema) . '"."AUDIT_LOG_CHANGESET_IDX_USER"       ON "' . ($opt->schema) . '"."AUDIT_LOG_CHANGESET" ( "USER_ID" )',
            'CREATE INDEX "' . ($opt->schema) . '"."AUDIT_LOG_FIELD_IDX_AUDITED_TABLE"  ON "' . ($opt->schema) . '"."AUDIT_LOG_FIELD"     ( "AUDITED_TABLE_ID" )',
            'CREATE INDEX "' . ($opt->schema) . '"."AUDIT_LOG_ACTION_IDX_AUDITED_TABLE" ON "' . ($opt->schema) . '"."AUDIT_LOG_ACTION"    ( "AUDITED_TABLE_ID" )',
            'CREATE INDEX "' . ($opt->schema) . '"."AUDIT_LOG_ACTION_IDX_CHANGESET"     ON "' . ($opt->schema) . '"."AUDIT_LOG_ACTION"    ( "CHANGESET_ID" )',
            'CREATE INDEX "' . ($opt->schema) . '"."AUDIT_LOG_CHANGE_IDX_ACTION"        ON "' . ($opt->schema) . '"."AUDIT_LOG_CHANGE"    ( "ACTION_ID" )',
            'CREATE INDEX "' . ($opt->schema) . '"."AUDIT_LOG_CHANGE_IDX_FIELD"         ON "' . ($opt->schema) . '"."AUDIT_LOG_CHANGE"    ( "FIELD_ID" )',

            # add the foreign keys
            'ALTER TABLE "' . ($opt->schema) . '"."AUDIT_LOG_CHANGESET" ADD CONSTRAINT AUDIT_LOG_CHANGESET_FK_USER       FOREIGN KEY ("USER_ID")          REFERENCES AUDIT_LOG_USER("ID")      ON DELETE CASCADE',
            'ALTER TABLE "' . ($opt->schema) . '"."AUDIT_LOG_FIELD"     ADD CONSTRAINT AUDIT_LOG_FIELD_FK_AUDITED_TABLE  FOREIGN KEY ("AUDITED_TABLE_ID") REFERENCES AUDIT_LOG_TABLE("ID")     ON DELETE CASCADE',
            'ALTER TABLE "' . ($opt->schema) . '"."AUDIT_LOG_ACTION"    ADD CONSTRAINT AUDIT_LOG_ACTION_FK_AUDITED_TABLE FOREIGN KEY ("AUDITED_TABLE_ID") REFERENCES AUDIT_LOG_TABLE("ID")     ON DELETE CASCADE',
            'ALTER TABLE "' . ($opt->schema) . '"."AUDIT_LOG_ACTION"    ADD CONSTRAINT AUDIT_LOG_ACTION_FK_CHANGESET     FOREIGN KEY ("CHANGESET_ID")     REFERENCES AUDIT_LOG_CHANGESET("ID") ON DELETE CASCADE',
            'ALTER TABLE "' . ($opt->schema) . '"."AUDIT_LOG_CHANGE"    ADD CONSTRAINT AUDIT_LOG_CHANGE_FK_ACTION        FOREIGN KEY ("ACTION_ID")        REFERENCES AUDIT_LOG_ACTION("ID")    ON DELETE CASCADE',
            'ALTER TABLE "' . ($opt->schema) . '"."AUDIT_LOG_CHANGE"    ADD CONSTRAINT AUDIT_LOG_CHANGE_FK_FIELD         FOREIGN KEY ("FIELD_ID")         REFERENCES AUDIT_LOG_FIELD("ID")     ON DELETE CASCADE',
        );
    }
    else {
        @sql = (
            ### DROP ALL FOREIGN KEY INDEXES

            'DROP INDEX "' . ($opt->schema) . '"."AUDIT_LOG_CHANGESET_IDX_USER"',
            'DROP INDEX "' . ($opt->schema) . '"."AUDIT_LOG_ACTION_IDX_AUDITED_TABLE"',
            'DROP INDEX "' . ($opt->schema) . '"."AUDIT_LOG_ACTION_IDX_CHANGESET"',
            'DROP INDEX "' . ($opt->schema) . '"."AUDIT_LOG_CHANGE_IDX_ACTION"',
            'DROP INDEX "' . ($opt->schema) . '"."AUDIT_LOG_CHANGE_IDX_FIELD"',
            'DROP INDEX "' . ($opt->schema) . '"."AUDIT_LOG_FIELD_IDX_AUDITED_TABLE"',

            ### DROP ALL FOREIGN KEYS

            'ALTER TABLE "' . ($opt->schema) . '"."AUDIT_LOG_CHANGESET" DROP FOREIGN KEY "AUDIT_LOG_CHANGESET_FK_USER"',
            'ALTER TABLE "' . ($opt->schema) . '"."AUDIT_LOG_ACTION"    DROP FOREIGN KEY "AUDIT_LOG_ACTION_FK_AUDITED_TABLE"',
            'ALTER TABLE "' . ($opt->schema) . '"."AUDIT_LOG_ACTION"    DROP FOREIGN KEY "AUDIT_LOG_ACTION_FK_CHANGESET"',
            'ALTER TABLE "' . ($opt->schema) . '"."AUDIT_LOG_CHANGE"    DROP FOREIGN KEY "AUDIT_LOG_CHANGE_FK_ACTION"',
            'ALTER TABLE "' . ($opt->schema) . '"."AUDIT_LOG_CHANGE"    DROP FOREIGN KEY "AUDIT_LOG_CHANGE_FK_FIELD"',
            'ALTER TABLE "' . ($opt->schema) . '"."AUDIT_LOG_FIELD"     DROP FOREIGN KEY "AUDIT_LOG_FIELD_FK_AUDITED_TABLE"',

            ### ALTER TABLE STRUCTURE

            'ALTER TABLE "' . ($opt->schema) . '"."AUDIT_LOG_CHANGESET" RENAME COLUMN "USER"          TO "USER_ID"',
            'ALTER TABLE "' . ($opt->schema) . '"."AUDIT_LOG_CHANGESET" RENAME COLUMN "TIMESTAMP"     TO "CREATED_ON"',
            'ALTER TABLE "' . ($opt->schema) . '"."AUDIT_LOG_ACTION"    RENAME COLUMN "CHANGESET"     TO "CHANGESET_ID"',
            'ALTER TABLE "' . ($opt->schema) . '"."AUDIT_LOG_ACTION"    RENAME COLUMN "AUDITED_TABLE" TO "AUDITED_TABLE_ID"',
            'ALTER TABLE "' . ($opt->schema) . '"."AUDIT_LOG_ACTION"    RENAME COLUMN "TYPE"          TO "ACTION_TYPE"',
            'ALTER TABLE "' . ($opt->schema) . '"."AUDIT_LOG_CHANGE"    RENAME COLUMN "ACTION"        TO "ACTION_ID"',
            'ALTER TABLE "' . ($opt->schema) . '"."AUDIT_LOG_CHANGE"    RENAME COLUMN "FIELD"         TO "FIELD_ID"',
            'ALTER TABLE "' . ($opt->schema) . '"."AUDIT_LOG_FIELD"     RENAME COLUMN "AUDITED_TABLE" TO "AUDITED_TABLE_ID"',

            #### RE-ADD THE INDEXES AND CONSTRAINTS

            # add the foreign key indexes
            'CREATE INDEX "' . ($opt->schema) . '"."AUDIT_LOG_CHANGESET_IDX_USER"       ON "' . ($opt->schema) . '"."AUDIT_LOG_CHANGESET" ( "USER_ID" )',
            'CREATE INDEX "' . ($opt->schema) . '"."AUDIT_LOG_FIELD_IDX_AUDITED_TABLE"  ON "' . ($opt->schema) . '"."AUDIT_LOG_FIELD"     ( "AUDITED_TABLE_ID" )',
            'CREATE INDEX "' . ($opt->schema) . '"."AUDIT_LOG_ACTION_IDX_AUDITED_TABLE" ON "' . ($opt->schema) . '"."AUDIT_LOG_ACTION"    ( "AUDITED_TABLE_ID" )',
            'CREATE INDEX "' . ($opt->schema) . '"."AUDIT_LOG_ACTION_IDX_CHANGESET"     ON "' . ($opt->schema) . '"."AUDIT_LOG_ACTION"    ( "CHANGESET_ID" )',
            'CREATE INDEX "' . ($opt->schema) . '"."AUDIT_LOG_CHANGE_IDX_ACTION"        ON "' . ($opt->schema) . '"."AUDIT_LOG_CHANGE"    ( "ACTION_ID" )',
            'CREATE INDEX "' . ($opt->schema) . '"."AUDIT_LOG_CHANGE_IDX_FIELD"         ON "' . ($opt->schema) . '"."AUDIT_LOG_CHANGE"    ( "FIELD_ID" )',

            # add the foreign keys
            'ALTER TABLE "' . ($opt->schema) . '"."AUDIT_LOG_CHANGESET" ADD CONSTRAINT AUDIT_LOG_CHANGESET_FK_USER       FOREIGN KEY ("USER_ID")          REFERENCES ' . ($opt->schema) . '.AUDIT_LOG_USER("ID")      ON DELETE CASCADE',
            'ALTER TABLE "' . ($opt->schema) . '"."AUDIT_LOG_FIELD"     ADD CONSTRAINT AUDIT_LOG_FIELD_FK_AUDITED_TABLE  FOREIGN KEY ("AUDITED_TABLE_ID") REFERENCES ' . ($opt->schema) . '.AUDIT_LOG_TABLE("ID")     ON DELETE CASCADE',
            'ALTER TABLE "' . ($opt->schema) . '"."AUDIT_LOG_ACTION"    ADD CONSTRAINT AUDIT_LOG_ACTION_FK_AUDITED_TABLE FOREIGN KEY ("AUDITED_TABLE_ID") REFERENCES ' . ($opt->schema) . '.AUDIT_LOG_TABLE("ID")     ON DELETE CASCADE',
            'ALTER TABLE "' . ($opt->schema) . '"."AUDIT_LOG_ACTION"    ADD CONSTRAINT AUDIT_LOG_ACTION_FK_CHANGESET     FOREIGN KEY ("CHANGESET_ID")     REFERENCES ' . ($opt->schema) . '.AUDIT_LOG_CHANGESET("ID") ON DELETE CASCADE',
            'ALTER TABLE "' . ($opt->schema) . '"."AUDIT_LOG_CHANGE"    ADD CONSTRAINT AUDIT_LOG_CHANGE_FK_ACTION        FOREIGN KEY ("ACTION_ID")        REFERENCES ' . ($opt->schema) . '.AUDIT_LOG_ACTION("ID")    ON DELETE CASCADE',
            'ALTER TABLE "' . ($opt->schema) . '"."AUDIT_LOG_CHANGE"    ADD CONSTRAINT AUDIT_LOG_CHANGE_FK_FIELD         FOREIGN KEY ("FIELD_ID")         REFERENCES ' . ($opt->schema) . '.AUDIT_LOG_FIELD("ID")     ON DELETE CASCADE',
        );
    }

    $dbh->do($_) for @sql;
}

sub mysql {
    my $dbh = shift;
    print "Executing 'mysql' database update.\n";
    my @sql = (

        # audit_log_changeset
        'ALTER TABLE `audit_log_changeset` DROP FOREIGN KEY `audit_log_changeset_fk_user`',
        'ALTER TABLE `audit_log_changeset` CHANGE `timestamp` `created_on` TIMESTAMP  NOT NULL DEFAULT CURRENT_TIMESTAMP,
            CHANGE `user` `user_id` INTEGER  DEFAULT NULL,
            DROP INDEX `audit_log_changeset_idx_user`,
            ADD INDEX `audit_log_changeset_idx_user` USING BTREE(`user_id`),
            ADD CONSTRAINT `audit_log_changeset_fk_user` FOREIGN KEY `audit_log_changeset_fk_user` (`user_id`)
                REFERENCES `audit_log_user` (`id`)
                ON DELETE CASCADE
                ON UPDATE CASCADE',

        # audit_log_action
        'ALTER TABLE `audit_log_action` DROP FOREIGN KEY `audit_log_action_fk_audited_table`',
        'ALTER TABLE `audit_log_action` DROP FOREIGN KEY `audit_log_action_fk_changeset`',
        'ALTER TABLE `audit_log_action` CHANGE `changeset` `changeset_id` INTEGER  NOT NULL,
            CHANGE `audited_table` `audited_table_id` INTEGER  NOT NULL,
            DROP INDEX `audit_log_action_idx_audited_table`,
            ADD INDEX `audit_log_action_idx_audited_table` USING BTREE(`audited_table_id`),
            DROP INDEX `audit_log_action_idx_changeset`,
            ADD INDEX `audit_log_action_idx_changeset` USING BTREE(`changeset_id`),
            ADD CONSTRAINT `audit_log_action_fk_audited_table` FOREIGN KEY `audit_log_action_fk_audited_table` (`audited_table_id`)
               REFERENCES `audit_log_table` (`id`)
               ON DELETE CASCADE
               ON UPDATE CASCADE,
            ADD CONSTRAINT `audit_log_action_fk_canngeset` FOREIGN KEY `audit_log_action_fk_canngeset` (`changeset_id`)
               REFERENCES `audit_log_changeset` (`id`)
               ON DELETE CASCADE
               ON UPDATE CASCADE',
        'ALTER TABLE `audit_log_action CHANGE `type` `action_type` VARCHAR(10) NOT NULL',

        # audit_log_change
        'ALTER TABLE `audit_log_change` DROP FOREIGN KEY `audit_log_change_fk_action`',
        'ALTER TABLE `audit_log_change` DROP FOREIGN KEY `audit_log_change_fk_field`',

        'ALTER TABLE `audit_log_change` CHANGE `action` `action_id` INTEGER  NOT NULL,
            CHANGE `field` `field_id` INTEGER  NOT NULL,
            DROP INDEX `audit_log_change_idx_action`,
            ADD INDEX `audit_log_change_idx_action` USING BTREE(`action_id`),
            DROP INDEX `audit_log_change_idx_field`,
            ADD INDEX `audit_log_change_idx_field` USING BTREE(`field_id`),
            ADD CONSTRAINT `audit_log_change_fk_action` FOREIGN KEY `audit_log_change_fk_action` (`action_id`)
                REFERENCES `audit_log_action` (`id`)
                ON DELETE CASCADE
                ON UPDATE CASCADE,
            ADD CONSTRAINT `audit_log_change_fk_field` FOREIGN KEY `audit_log_change_fk_field` (`field_id`)
                REFERENCES `audit_log_field` (`id`)
                ON DELETE CASCADE
                ON UPDATE CASCADE',

        # audit_log_field
        'ALTER TABLE `audit_log_field` DROP FOREIGN KEY `audit_log_field_fk_audited_table`',

        'ALTER TABLE `audit_log_field` CHANGE `audited_table` `audited_table_id` INTEGER  NOT NULL,
            DROP INDEX `audit_log_field_idx_audited_table`,
            ADD INDEX `audit_log_field_idx_audited_table` USING BTREE(`audited_table_id`),
            ADD CONSTRAINT `audit_log_field_fk_audited_table` FOREIGN KEY `audit_log_field_fk_audited_table` (`audited_table_id`)
                REFERENCES `audit_log_table` (`id`)
                ON DELETE CASCADE
                ON UPDATE CASCADE',
    );

    $dbh->do($_) for @sql;
}

sub oracle {
    my $dbh = shift;
    print "Executing 'oracle' database update.\n";
    my @sql = (

        # audit_log_changeset
        'ALTER TABLE audit_log_changeset RENAME COLUMN "USER" TO "USER_ID"',
        'ALTER TABLE audit_log_changeset RENAME COLUMN "TIMESTAMP" TO "CREATED_ON"',

        # audit_log_action
        'ALTER TABLE audit_log_action RENAME COLUMN "CHANGESET" TO "CHANGESET_ID"',
        'ALTER TABLE audit_log_action RENAME COLUMN "AUDITED_TABLE" TO "AUDITED_TABLE_ID"',
        'ALTER TABLE audit_log_action RENAME COLUMN "TYPE" TO "ACTION_TYPE"',

        # audit_log_change
        'ALTER TABLE audit_log_change RENAME COLUMN "ACTION" TO "ACTION_ID"',
        'ALTER TABLE audit_log_change RENAME COLUMN "FIELD" TO "FIELD_ID"',

        # audit_log_field
        'ALTER TABLE audit_log_field RENAME COLUMN "AUDITED_TABLE" TO "AUDITED_TABLE_ID"',
    );

    $dbh->do($_) for @sql;
}

sub pg {
    my $dbh = shift;
    print "Executing 'pg' database update.\n";
    my @sql = (

        # audit_log_changeset
        'ALTER TABLE audit_log_changeset RENAME COLUMN "user" TO "user_id"',
        'ALTER TABLE audit_log_changeset RENAME COLUMN "timestamp" TO "created_on"',

        # audit_log_action
        'ALTER TABLE audit_log_action RENAME COLUMN "changeset" TO "changeset_id"',
        'ALTER TABLE audit_log_action RENAME COLUMN "audited_table" TO "audited_table_id"',
        'ALTER TABLE audit_log_action RENAME COLUMN "type" TO "action_type"',

        # audit_log_change
        'ALTER TABLE audit_log_change RENAME COLUMN "action" TO "action_id"',
        'ALTER TABLE audit_log_change RENAME COLUMN "field" TO "field_id"',

        # audit_log_field
        'ALTER TABLE audit_log_field RENAME COLUMN "audited_table" TO "audited_table_id"',
    );

    $dbh->do($_) for @sql;
}
