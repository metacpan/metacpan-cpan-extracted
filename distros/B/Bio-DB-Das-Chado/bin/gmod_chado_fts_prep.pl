#!/usr/bin/perl
use strict;
use warnings;

use Bio::GMOD::Config;
use Bio::GMOD::DB::Config;
use Getopt::Long;

=pod 

=head1 NAME

gmod_chado_fts_prep.pl - prepares a Chado schema to use full text searching

=head1 SYNOPSIS

  % gmod_chado_fts_prep.pl [--dbprofile (name)]

=head1 COMMAND-LINE OPTIONS

  --dbprfile    Specify a gmod.conf profile name (otherwise use default)

=head1 DESCRIPTION

note about pg version
note about all_feature_names materialized view

=head1 AUTHOR 

Scott Cain E<lt>scain@cpan.orgE<gt>

Copyright (c) 2010

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

my ($DBPROFILE,);

GetOptions(
    'dbprofile=s' => \$DBPROFILE,
) or ( system( 'pod2text', $0 ), exit -1 );

$DBPROFILE ||='default';

my $gmod_conf = Bio::GMOD::Config->new();
my $db_conf   = Bio::GMOD::DB::Config->new($gmod_conf, $DBPROFILE);
my $schema    = $db_conf->schema;
$schema       ||= 'public';

print STDERR "Making ".$db_conf->name()." database ready for use with\nfull text searching in Bio::DB::Das::Chado.\n\n";

my $dbh = $db_conf->dbh();

validate_prereqs($dbh);
create_searchable_columns($dbh,$schema);
create_all_feature_names($DBPROFILE,$schema);
create_search_triggers($dbh);

exit(0);

=head1 Internally used methods


=head2 validate_prereqs

=over

=item Usage

  validate_prereqs()

=item Function

Checks that the Pg version is OK and that all_feature_names is a 
table an not a view.

=item Returns

Nothing.

=item Arguments

The DBI database handle for the database to be modified.

=back

=cut

sub validate_prereqs {
    my $dbh = shift;

    my $version_query = "select version()";
    my $arrayref = $dbh->selectall_arrayref($version_query);

    #parse ugly not very useful version result
    if ($$arrayref[0]->[0] =~ /PostgreSQL\s+(\S+)\s/) {
        my $versionstring = $1;
        my ($major, $minor, $rev) = split /\./, $versionstring;
        my $version = $major + $minor/10;
        if ($version < 8.4) {
            warn "The PostgreSQL server version is less than the required 8.4 (it reported $version).\n";
            warn "Exiting...\n";
            exit(1);
        }
    } 
    else {
        warn "Unable to determine PostgreSQL server version; exiting...\n";
        exit(1);
    }
}

=head2 create_searchable_columns

=over

=item Usage

  create_searchable_columns($dbh);

=item Function

To modify existing feature, synonym and dbxref tables to add a "searchable"
column for names and accessions.

=item Returns

Nothing.

=item Arguments

The DBI database handle for the database to be modified.

=back

=cut

sub create_searchable_columns {
    my $dbh    = shift;
    my $schema = shift;

    my $exists_query = "select count(*) from information_schema.columns where table_schema='$schema' and table_name='feature' and column_name='searchable_name'";
    my $arrayref = $dbh->selectall_arrayref($exists_query);
    if ( $$arrayref[0]->[0] == 1) {
        warn "Dropping feature.searchable_name so it can be replaced.\n";
        $dbh->do("ALTER TABLE feature DROP COLUMN searchable_name") or die;
    }

    $dbh->do("ALTER TABLE feature ADD COLUMN searchable_name tsvector") or die;
    $dbh->do("UPDATE feature SET searchable_name = to_tsvector('pg_catalog.english', COALESCE((name,'') || ' ' || (uniquename,'')))") or die;

    $exists_query = "select count(*) from information_schema.columns where table_schema='$schema' and table_name='synonym' and column_name='searchable_synonym_sgml'";
    $arrayref = $dbh->selectall_arrayref($exists_query);
    if ( $$arrayref[0]->[0] == 1) {
        warn "Dropping synonym.searchable_synonym_sgml so it can be replaced.\n";
        $dbh->do("ALTER TABLE synonym DROP COLUMN searchable_synonym_sgml") or die;
    }

    $dbh->do("ALTER TABLE synonym ADD COLUMN searchable_synonym_sgml tsvector") or die;
    $dbh->do("UPDATE synonym SET searchable_synonym_sgml = to_tsvector('pg_catalog.english', synonym_sgml)") or die;

    $exists_query = "select count(*) from information_schema.columns where table_schema='$schema' and table_name='dbxref' and column_name='searchable_accession'";
    $arrayref = $dbh->selectall_arrayref($exists_query);
    if ( $$arrayref[0]->[0] == 1) {
        warn "Dropping dbxref.searchable_accession so it can be replaced.\n\n";
        $dbh->do("ALTER TABLE dbxref DROP COLUMN searchable_accession") or die;
    }

    $dbh->do("ALTER TABLE dbxref ADD COLUMN searchable_accession tsvector") or die;
    $dbh->do("UPDATE dbxref SET searchable_accession = to_tsvector('pg_catalog.english', accession)") or die;

    return;
}

=head2 create_search_triggers

=over

=item Usage

  create_search_triggers($dbh)

=item Function

Creates database triggers on the searchable columns to keep them up
to date.

=item Returns

Nothing.

=item Arguments

The database handle, $dbh, for the database to be modified.

=back

From Leighton's notes:

Add trigger function to each table to populate the
searchable column when a data-modifying operation occurs 
on the target field.

This is made much easier by the existence of the tsvector_update_trigger() 
procedure.

=cut

sub create_search_triggers {
    my $dbh = shift;

    $dbh->do("DROP TRIGGER IF EXISTS feature_searchable_iu ON feature") or die;
    $dbh->do("CREATE TRIGGER feature_searchable_iu
  BEFORE INSERT OR UPDATE ON feature
    FOR EACH ROW
      EXECUTE PROCEDURE
        tsvector_update_trigger(searchable_name, 'pg_catalog.english', name, uniquename)") or die;

    $dbh->do("DROP TRIGGER IF EXISTS synonym_searchable_iu ON synonym") or die;
    $dbh->do("CREATE TRIGGER synonym_searchable_iu
  BEFORE INSERT OR UPDATE ON synonym
    FOR EACH ROW
      EXECUTE PROCEDURE
        tsvector_update_trigger(searchable_synonym_sgml, 'pg_catalog.english', synonym_sgml)") or die;

    $dbh->do("DROP TRIGGER IF EXISTS dbxref_searchable_iu ON dbxref") or die;
    $dbh->do("CREATE TRIGGER dbxref_searchable_iu
  BEFORE INSERT OR UPDATE ON dbxref
    FOR EACH ROW
      EXECUTE PROCEDURE
        tsvector_update_trigger(searchable_accession, 'pg_catalog.english', accession)") or die;

    return;
}

=head2 create_all_feature_names

=over

=item Usage

  create_all_feature_names($dbprof)

=item Function

Creates the materialized view of all_feature_names, making sure to
dematerialize it first.  It does this by making system calls to
the gmod_materialized_view_tool.pl script that comes with the Chado
distribution.

=item Returns

Nothing.

=item Arguments

The name of the Bio::GMOD::DB::Config profile.

=back

=cut

sub create_all_feature_names {
    my $dbprof = shift;
    my $schema = shift;

    system("gmod_materialized_view_tool.pl --dbprof $dbprof --dem all_feature_names --yes" );

    system( <<END
gmod_materialized_view_tool.pl --create_view --view_name all_feature_names --table_name $schema.all_feature_names --refresh_time daily --column_def "feature_id integer,name varchar(255),organism_id integer,searchable_name tsvector" --sql_query "SELECT feature_id, CAST(substring(uniquename FROM 0 FOR 255) AS varchar(255)) AS name, organism_id, to_tsvector('english', CAST(substring(uniquename FROM 0 FOR 255) AS varchar(255))) AS searchable_name FROM feature UNION SELECT feature_id, name, organism_id, to_tsvector('english', name) AS searchable_name FROM feature WHERE name IS NOT NULL UNION SELECT fs.feature_id, s.name, f.organism_id, to_tsvector('english', s.name) AS searchable_name FROM feature_synonym fs, synonym s, feature f WHERE fs.synonym_id = s.synonym_id AND fs.feature_id = f.feature_id UNION SELECT fp.feature_id, CAST(substring(fp.value FROM 0 FOR 255) AS varchar(255)) AS name, f.organism_id, to_tsvector('english',CAST(substring(fp.value FROM 0 FOR 255) AS varchar(255))) AS searchable_name FROM featureprop fp, feature f WHERE f.feature_id = fp.feature_id UNION SELECT fd.feature_id, d.accession, f.organism_id,to_tsvector('english',d.accession) AS searchable_name FROM feature_dbxref fd, dbxref d,feature f WHERE fd.dbxref_id = d.dbxref_id AND fd.feature_id = f.feature_id" --index_fields "feature_id,name" --special_index "CREATE INDEX searchable_all_feature_names_idx ON all_feature_names USING gin(searchable_name)" --yes --dbprof $dbprof
END
);

}

