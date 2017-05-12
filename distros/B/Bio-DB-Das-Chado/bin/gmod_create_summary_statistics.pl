#!/usr/bin/perl 
use strict;
use warnings;

use Bio::GMOD::Config;
use Bio::GMOD::DB::Config;
use Getopt::Long;

my ($DBPROFILE,);

GetOptions(
    'dbprofile=s' => \$DBPROFILE,
) or ( system( 'pod2text', $0 ), exit -1 );

my $gmod_conf = Bio::GMOD::Config->new();
my $db_conf   = Bio::GMOD::DB::Config->new($gmod_conf, $DBPROFILE);

my $dbh    = $db_conf->dbh;
my $schema = $db_conf->schema;
$schema    ||= 'public';

create_table($dbh, $schema);
create_functions($dbh);
populate_table($dbh);

exit(0);



sub populate_table {
    my $dbh = shift;

    $dbh->do("SELECT populate_gff_interval_stats()") or die $dbh->errstr;
}

sub create_table {
    my $dbh = shift;
    my $schema = shift;
    my $table_def =<<END
CREATE TABLE gff_interval_stats (
   typeid            varchar(1024) not null,
   srcfeature_id     integer not null,
   bin               integer not null,
   cum_count         integer not null
);
CREATE UNIQUE INDEX gff_interval_stats_idx1 ON gff_interval_stats(typeid,srcfeature_id,bin);
END
;

#determine if the table already exists
    my @table_exists = $dbh->selectrow_array("SELECT * FROM pg_tables WHERE tablename
 = 'gff_interval_stats' AND schemaname = '$schema'");
    if (!scalar(@table_exists)) {
        $dbh->do($table_def) or die $dbh->errstr;
    }
    else { #empty the table out
        $dbh->do("DELETE FROM gff_interval_stats") or die $dbh->errstr; 
    }
    return;
}

sub create_functions {
    my $dbh = shift;

    my $load_bins =<<'END'
CREATE OR REPLACE FUNCTION gff_load_bins (varchar, int, int) RETURNS void AS $$
  DECLARE
    current_type  ALIAS FOR $1;
    current_srcf  ALIAS FOR $2;
    current_bin   ALIAS FOR $3;

    i             int;
    cumcount      int;
    result        gff_interval_stats%ROWTYPE;
  BEGIN
    cumcount = 0;

    FOR result IN SELECT * FROM gff_interval_stats WHERE typeid is not null
                                                   AND typeid = current_type
                                                   AND srcfeature_id = current_srcf
                                                   AND bin <= current_bin
                                                   order by bin LOOP

        cumcount = result.cum_count + cumcount;
        UPDATE gff_interval_stats SET cum_count = cumcount
            WHERE typeid = current_type
              AND srcfeature_id = current_srcf
              AND bin = result.bin;
    END LOOP;
  END;
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION gff_load_bins (varchar, int) RETURNS void AS $$
  DECLARE
    current_type  ALIAS FOR $1;
    current_srcf  ALIAS FOR $2;

    i             int;
    cumcount      int;
    result        gff_interval_stats%ROWTYPE;
  BEGIN
    cumcount = 0;

    FOR result IN SELECT * FROM gff_interval_stats WHERE typeid is not null
                                                   AND typeid = current_type
                                                   AND srcfeature_id = current_srcf
                                                   order by bin LOOP

        cumcount = result.cum_count + cumcount;

        UPDATE gff_interval_stats SET cum_count = cumcount
            WHERE typeid = current_type
              AND srcfeature_id = current_srcf
              AND bin = result.bin;
    END LOOP;
  END;
$$
LANGUAGE 'plpgsql';
END
;

    my $populate_gff_interval_stats =<<'END'
CREATE OR REPLACE FUNCTION populate_gff_interval_stats() RETURNS void AS $$
  DECLARE
    binsize       int;
    resrow        record;

    current_bin   int;
    last_bin      int;
    current_srcf  int;
    current_type  varchar;
    ibin          int;

    i             int;
    tempvalue     int;
  BEGIN
    binsize       = 1000;
    current_bin   = -1;
    current_srcf  = -1;
    current_type  = '';


    FOR resrow IN SELECT cvterm.name ||':'|| dbxref.accession as typeid,
                         fl.srcfeature_id, fl.fmin, fl.fmax
        FROM featureloc fl left join feature f using (feature_id)
         left join cvterm on (f.type_id = cvterm.cvterm_id)
         left join feature_dbxref fd on (f.feature_id = fd.feature_id)
         left join dbxref on (fd.dbxref_id = dbxref.dbxref_id and dbxref.db_id = 2)
        ORDER BY typeid, fl.srcfeature_id, fl.fmin LOOP

        ibin = resrow.fmin/binsize;

        IF (ibin != current_bin) THEN
            IF ((resrow.srcfeature_id != current_srcf
                 OR resrow.typeid != current_type) AND current_srcf > 0) THEN

                PERFORM gff_load_bins(current_type,current_srcf);

            ELSE
                --I don't think any thing needs to happen here

            END IF;
        END IF;

        current_bin  = ibin;
        current_type = resrow.typeid;
        current_srcf = resrow.srcfeature_id;

        last_bin = (resrow.fmax-1)/binsize;
        FOR i IN ibin..last_bin LOOP
            SELECT INTO tempvalue COALESCE (cum_count,0) FROM gff_interval_stats
                        WHERE bin = i
                          AND srcfeature_id = resrow.srcfeature_id
                          AND typeid = resrow.typeid;
            IF (tempvalue > 0) THEN
                UPDATE gff_interval_stats SET cum_count = tempvalue + 1
                    WHERE bin = i
                      AND srcfeature_id = resrow.srcfeature_id
                      AND typeid = resrow.typeid;
            ELSEIF (resrow.typeid IS NOT NULL) THEN
                INSERT INTO gff_interval_stats (typeid,srcfeature_id,bin,cum_count)
                    VALUES (resrow.typeid,resrow.srcfeature_id,i,1);
            END IF;
        END LOOP;

    END LOOP;

    PERFORM gff_load_bins(current_type,current_srcf);

  END;
$$
LANGUAGE 'plpgsql';
END
;
    #check to see if the functions exist already
    #if it does, don't do anything
#    my @func_exists = $dbh->selectrow_array("SELECT * FROM pg_proc WHERE proname
# = 'populate_gff_interval_stats'");
#    if (!scalar(@func_exists)) {
        $dbh->do($load_bins) or die $dbh->errstr;
        $dbh->do($populate_gff_interval_stats) or die $dbh->errstr;
#    }
    return;
}
