#! /usr/bin/perl -w

# $Id: defrag.pl,v 1.18 2001/04/28 13:51:28 rvsutherland Exp $
#
# Copyright (c) 2000, 2001 Richard Sutherland - United States of America
#
# See COPYRIGHT section in pod text below for usage and distribution rights.

use Cwd;
use DBI;
use DDL::Oracle;
use English;
use Getopt::Long;

use strict;

my %args;
my %uniq;

my @constraints;
my @export_objects;
my @export_temps;
my @logfiles;
my @perf_tables = ( 
                   'DBA_ALL_TABLES',
                   'DBA_INDEXES', 
                   'DBA_PART_INDEXES',
                   'DBA_PART_TABLES',
                   'DBA_SEGMENTS', 
                   'DBA_TABLES', 
                   'THE_CONSTRAINTS',
                   'THE_IOTS',
                   'THE_INDEXES',
                   'THE_PARTITIONS',
                   'THE_TABLES',
                  );
my @sizing_array;

my $add_ndx_log;
my $add_tbl_log;
my $add_temp_log;
my $add_temp_sql;
my $alttblsp;
my $aref;
my $create_ndx_ddl;
my $create_tbl_ddl;
my $create_temp_ddl;
my $date;
my $dbh;
my $drop_all_log;
my $drop_ddl;
my $drop_temp_ddl;
my $drop_temp_log;
my $drop_temp_sql;
my $expdir;
my $exp_log;
my $header10;
my $home = $ENV{HOME}
        || $ENV{LOGDIR}
        || ( getpwuid( $REAL_USER_ID ) )[7]
        || die "\nCan't determine HOME directory.\n";
my $imp_log;
my $logdir;
my $obj;
my $other_constraints;
my $partitions;
my $prefix;
my $prttn_exp_log;
my $prttn_exp_par;
my $prttn_exp_text;
my $prttn_imp_log;
my $prttn_imp_par;
my $prttn_imp_text;
my $row;
my $script;
my $sqldir;
my $sth;
my $stmt;
my $tblsp;
my $text;
my $user = getlogin
        || scalar getpwuid( $REAL_USER_ID )
        || undef
     unless $OSNAME eq 'MSWin32';
$user = 'Unknown User'    unless $user;

########################################################################

set_defaults();

if (
         @ARGV    == 0
     or  $ARGV[0] eq "?"
     or  $ARGV[0] eq "-?"
     or  $ARGV[0] eq "-h"
     or  $ARGV[0] eq "--help"
   ) 
{
  print_help();
  exit 0;
}

print "\n$0 is being executed by $user\non ", scalar localtime,"\n\n";
get_args();
print "Generating files to defrag Tablespace $tblsp.\n",
      "Using Tablespace $alttblsp for partition operations.\n\n";
initialize_queries();

#
# Display user options, and save them in .defrag.rc
#

delete $args{ sid } if $args{ sid } eq "";
open RC, ">$home/.defragrc" or die "Can't open $home/.defragrc:  $!\n";
KEY:
  foreach my $key ( sort keys %args ) 
  {
    next KEY unless (
                         $key eq "sid"
                      or $key eq "logdir"
                      or $key eq "sqldir"
                      or $key eq "prefix"
                      or $key eq "expdir"
                      or $key eq "resize"
                    );
    print "$key = $args{ $key }\n";
    print RC "$key = $args{ $key }\n";
  }
close RC or die "Can't close $home/.defragrc:  $!\n";

print "\nWorking...\n\n";

########################################################################

#
# Now we're ready -- start dafriggin' defraggin'
#

# The 10 steps below issue queries mostly comprised of 5 main queries,
# sometimes doing UNIONs and/or MINUSes among them.  The query results
# are stored in temporary tables for performance reasons.
#
# See sub 'initialize_queries' for the queries and their descriptions.
#

# Step 1 - Export the stray partitions -- those in our tablespace whose
#          table also has partitions in at least one other tablespace.
#          If said partitions exist, there will be 2 exports.  After the
#          first export, for each such partition:
#            a) Create a Temp table mirroring the partition.
#            b) Create indexes on the Temp table matching the LOCAL 
#               indexes on the partitioned table.
#            c) Create a PK matching the PK of the partitioned table,
#               if any.
#            d) EXCHANGE the Temp table with the partition.
#            e) MOVE the [now empty] partition to the alternate tablespace.
#
#          With the data now in the Temp table, the Temp table gets 
#          treated the same as other regular tables in our tablespace
#          (see Steps 2 - 9), but has added operations following the
#          creation of its indexes (same as the LOCAL indexes on the 
#          partition) and the addition of its PK (if any).
#
#            a) the Temp table does an EXCHANGE PARTITION so that the
#               data (which was imported into the Temp table) rejoins
#               the partitioned table.
#            b) the [now empty] Temp table is DROPped.
#
#            c) REBUILD all Global indexes (if any) on the partitioned
#               table(s).
#
#          NOTE:  Two 'fall back' scripts are created which are to be
#                 used ONLY in the event that problems occur during
#                 Step 1 (Shell #2 when such partitions exist).
#
#                  ***  DO NOT PROCEED IF Shell #2 HAS ERRORS ***
#
#                 Shells #8 and #9  will restore the data to the original
#                 condition Their Steps are:
#                   a) DROP the Temp table(s).
#                   b) TRUNCATE the partitions
#                   c) MOVE the partitions back to our tablespace
#                   d) Import the data back into the partitions.
#

$stmt =
      "
       SELECT
              owner
            , segment_name
            , partition_name
            , segment_type
            , partitioning_type
            , analyzed
       FROM
              THE_PARTITIONS
       ORDER
          BY
              1, 2, 3
      ";

$sth = $dbh->prepare( $stmt );
$sth->execute;
$aref = $sth->fetchall_arrayref;

foreach $row ( @$aref )
{
  my ( 
       $owner, 
       $table, 
       $partition, 
       $type, 
       $partitioning_type,
       $analyzed
     ) = @$row;

  $obj = DDL::Oracle->new(
                           type => 'exchange table',
                           list => [
                                     [
                                       "$owner",
                                       "$table:$partition",
                                     ]
                                   ],
                         );
  my $create_tbl = $obj->create;
  # Remove REM lines created by DDL::Oracle
  $create_tbl = ( join "\n",grep !/^REM/,split /\n/,$create_tbl )."\n\n";

  my $temp = "${tblsp}_${date}_" . unique_nbr();

  push @export_temps,   "\L$owner.$table:$partition";
  push @export_objects, "\L$owner.$temp";

  # Change the CREATE TABLE statement to create the temp
  my $ownr    = escaped_dollar_signs( $owner );
  my $tabl    = escaped_dollar_signs( $table );
  $create_tbl =~ s|\L$ownr.$tabl|\L$owner.$temp|g;

  my $exchange = index_and_exchange( $temp, @$row );

  $obj = DDL::Oracle->new(
                           type => 'table',
                           list => [
                                     [
                                       "$owner",
                                       "$temp",
                                     ]
                                   ],
                         );
  my $drop_tbl = $obj->drop;
  # Remove REM lines created by DDL::Oracle
  $drop_tbl = ( join "\n", grep !/^REM/, split /\n/, $drop_tbl ) . "\n\n";

  $obj = DDL::Oracle->new(
                           type => 'table',
                           list => [
                                     [
                                       "$owner",
                                       "$table:$partition",
                                     ]
                                   ],
                         );
  my $resize = $obj->resize;
  # Remove REM lines created by DDL::Oracle
  $resize =  ( join "\n", grep !/^REM/, split /\n/, $resize ) . "\n\n";
  $resize =~ s|\;|\nTABLESPACE \L$tblsp \;\n\n|;

  my $drop_temp =  $drop_tbl .
                   trunc( @$row ) .
                   $resize;

  $create_temp_ddl  = group_header( 1 )   unless $create_temp_ddl;
  $create_temp_ddl .= $create_tbl .
                      $exchange .
                      move( @$row, $alttblsp );

  $drop_ddl         = group_header( 2 )   unless $drop_ddl;
  $drop_ddl        .= $drop_tbl;

  $create_tbl_ddl   = group_header( 7 )   unless $create_tbl_ddl;
  $create_tbl_ddl  .= $create_tbl;

  $create_ndx_ddl   = group_header( 9 )   unless $create_ndx_ddl;
  $create_ndx_ddl  .= $exchange .
                      $drop_tbl;      

  $drop_temp_ddl    = group_header( 15 )  unless $drop_temp_ddl;
  $drop_temp_ddl   .= $drop_temp;
}

#
# Step 2 - Drop all Foreign Keys referenceing our tables and IOT's or
#          referenceing the tables of our other indexes.  NOTE:  our
#          indexes may not be the target of a foreign key, but for 
#          simplicity purposes if the index's table holds said target
#          (i.e., its index is in some other tablespace but it belongs
#          to the same table as our index), we'll drop the FK anyway --
#          it won't hurt anything and we promise to put it back.
#

$stmt =
      "
       SELECT --+ use_hash(c r)
              c.owner
            , c.constraint_name
       FROM
              THE_CONSTRAINTS  c
            , THE_CONSTRAINTS  r
       WHERE
                  c.constraint_type   = 'R'
              AND c.r_owner           = r.owner
              AND c.r_constraint_name = r.constraint_name
              AND (
                      r.owner
                    , r.table_name
                  ) IN (
                         SELECT
                                owner
                              , table_name
                         FROM
                                THE_TABLES
                         UNION ALL
                         SELECT
                                owner
                              , table_name
                         FROM
                                THE_IOTs
                         UNION ALL
                         SELECT
                                owner
                              , table_name
                         FROM
                                THE_INDEXES
                       )
       ORDER
          BY
              1, 2
      ";

$sth = $dbh->prepare( $stmt );
$sth->execute;
my $fk_aref = $sth->fetchall_arrayref;

$obj = DDL::Oracle->new(
                         type => 'constraint',
                         list => $fk_aref,
                       );

$drop_ddl .= group_header( 3 ) . $obj->drop    if @$fk_aref;

#
# Step 3 - Drop and create the tables.  NOTE:  the DROP statements are in
#          one file followed by COALESCE tablespace statements, and the
#          CREATE statements are put in a separate file.  The assumption
#          here is that the user will verify that the DROP and COALESCE
#          statements executed OK before executing the CREATE tables file.
#

$stmt =
      "
       SELECT DISTINCT
              owner
            , table_name
            , analyzed
       FROM
            (
              SELECT
                     owner
                   , table_name
                   , analyzed
              FROM
                     THE_TABLES
              UNION ALL
              SELECT
                     owner
                   , table_name
                   , analyzed
              FROM
                     THE_IOTs
            )
       ORDER
          BY
              1, 2
      ";

$sth = $dbh->prepare( $stmt );
$sth->execute;
$aref = $sth->fetchall_arrayref;

if ( @$aref )
{
  $obj = DDL::Oracle->new(
                           type => 'table',
                           list => $aref,
                         );

  $drop_ddl       .= group_header( 4 ) . $obj->drop;

  $create_tbl_ddl .= group_header( 8 ) . $obj->create;

  foreach $row ( @$aref )
  {
    my ( $owner, $table, $analyzed ) = @$row;

    push @export_objects, "\L$owner.$table";

    if ( $analyzed eq 'YES' )
    {
      $create_ndx_ddl .= group_header( 10 )    unless $header10++;

      $create_ndx_ddl .= "PROMPT " .
                         "ANALYZE TABLE \L$owner.$table\n\n" .
                         "ANALYZE TABLE \L$owner.$table " .
                         "ESTIMATE STATISTICS ;\n\n";
    }
  }

}

#
# Step 4 - Drop all Primary Key, Unique and Check constraints on the tables
#          of our indexes (those on our tables disappeared with the DROP
#          TABLE statements).
#

$stmt =
      "
       SELECT
              owner
            , constraint_name
       FROM
              THE_CONSTRAINTS
       WHERE
                  constraint_type IN ('P','U','C')
              AND (
                      owner
                    , table_name
                  ) IN (
                         SELECT
                                owner
                              , table_name
                         FROM
                                THE_INDEXES
                         MINUS
                         (
                           SELECT
                                  owner
                                , table_name
                           FROM
                                  THE_TABLES
                           UNION ALL
                           SELECT
                                  owner
                                , table_name
                           FROM
                                  THE_IOTs
                         )
                       )
       ORDER
          BY
              1, 2
      ";

$sth = $dbh->prepare( $stmt );
$sth->execute;
$aref = $sth->fetchall_arrayref;

$obj = DDL::Oracle->new(
                         type => 'constraint',
                         list => $aref,
                       );

$drop_ddl .= group_header( 5 ) . $obj->drop    if @$aref;

#
# Step 5 - Drop all of our indexes, unless they are the supporting index
#          of a Primary Key or Unique constraint -- these disappeared in
#          the preceding step.
#

$stmt =
      "
       SELECT
              owner
            , index_name
       FROM 
              THE_INDEXES i
       WHERE
              NOT EXISTS   (
                             SELECT
                                    null
                             FROM
                                    THE_CONSTRAINTS
                             WHERE
                                        owner           = i.owner
                                    AND constraint_name = i.index_name
                           )
              AND (
                      owner
                    , table_name
                  ) NOT IN (
                             SELECT
                                    owner
                                  , table_name
                             FROM
                                    THE_TABLES
                             UNION ALL
                             SELECT
                                    owner
                                  , table_name
                             FROM
                                    THE_IOTs
                           )
       ORDER
          BY
              1, 2
      ";

$sth = $dbh->prepare( $stmt );
$sth->execute;
$aref = $sth->fetchall_arrayref;

$obj = DDL::Oracle->new(
                         type => 'index',
                         list => $aref,
                       );

$drop_ddl .= group_header( 6 ) . $obj->drop    if @$aref;

#
# Step 6 - Create ALL indexes.
#

$stmt =
      "
       SELECT
              owner
            , index_name
            , table_name
            , analyzed
       FROM 
              THE_INDEXES
       ORDER
          BY
              1, 2
      ";

$sth = $dbh->prepare( $stmt );
$sth->execute;
$aref = $sth->fetchall_arrayref;

$obj = DDL::Oracle->new(
                         type => 'index',
                         list => $aref,
                       );

$create_ndx_ddl .= group_header( 10 )    unless $header10++;

$create_ndx_ddl .= $obj->create    if @$aref;

foreach $row ( @$aref )
{
  my ( $owner, $index, $table, $analyzed ) = @$row;

  if ( $analyzed eq 'YES' )
  {
    $create_ndx_ddl .= "PROMPT " .
                       "ANALYZE INDEX \L$owner.$index\n\n" .
                       "ANALYZE INDEX \L$owner.$index\n" .
                       "   ESTIMATE STATISTICS ;\n\n" .
                       "PROMPT " .
                       "ANALYZE TABLE \L$owner.$table\n\n" .
                       "ANALYZE TABLE \L$owner.$table\n" .
                       "   ESTIMATE STATISTICS " .
                       "FOR ALL INDEXED COLUMNS ;\n\n";
  }
}

#
# Step 7 - Create all Primary Key, Unique and Check constraints on our
#          tables and on the tables of our indexes.  NOTE:  do not create
#          the constraints for the IOT tables -- their primary keys were
#          defined in the CREATE TABLE statements.
#

$stmt =
      "
       SELECT
              owner
            , constraint_name
            , constraint_type
            , search_condition
       FROM
              dba_constraints
       WHERE
                  constraint_type     IN ('P','U','C')
              AND (
                      owner
                    , table_name
                  ) IN (
                         SELECT
                                owner
                              , table_name
                         FROM
                                THE_TABLES
                         UNION ALL
                         SELECT
                                owner
                              , table_name
                         FROM
                                THE_INDEXES
                       )
       ORDER
          BY
              1, 2
      ";

$dbh->{ LongReadLen } = 8192;    # Allows SEARCH_CONDITION length of 8K
$dbh->{ LongTruncOk } = 1;

$sth = $dbh->prepare( $stmt );
$sth->execute;
$aref = $sth->fetchall_arrayref;

foreach $row ( @$aref )
{
  my ( $owner, $constraint_name, $cons_type, $condition, ) = @$row;

  if ( $cons_type ne 'C' )
  {
    push @constraints, [ $owner, $constraint_name ];
  }
  elsif ( $condition !~ /IS NOT NULL/ )  # NOT NULL is part of CREATE TABLE
  {
    push @constraints, [ $owner, $constraint_name ];
  }
}

$obj = DDL::Oracle->new(
                         type => 'constraint',
                         list => \@constraints,
                       );

$create_ndx_ddl .= group_header( 11 ) . $obj->create    if @constraints;

#
# Step 8 - Create all Check constraints on our IOT tables (their PK was
#          part of the CREATE TABLE, and they can't have any other indexes,
#          thus no UK's)
#

$stmt =
      "
       SELECT
              owner
            , constraint_name
            , constraint_type
            , search_condition
       FROM
              dba_constraints
       WHERE
                  constraint_type = 'C'
              AND (
                      owner
                    , table_name
                  ) IN (
                         SELECT
                                owner
                              , table_name
                         FROM
                                THE_IOTs
                       )
       ORDER
          BY
              1, 2
      ";

$dbh->{ LongReadLen } = 8192;    # Allows SEARCH_CONDITION length of 8K
$dbh->{ LongTruncOk } = 1;

$sth = $dbh->prepare( $stmt );
$sth->execute;
$aref = $sth->fetchall_arrayref;

@constraints = ();
foreach $row ( @$aref )
{
  my ( $owner, $constraint_name, $cons_type, $condition, ) = @$row;

  if ( $condition !~ /IS NOT NULL/ )  # NOT NULL is part of CREATE TABLE
  {
    push @constraints, [ $owner, $constraint_name ];
  }
}

$obj = DDL::Oracle->new(
                         type => 'constraint',
                         list => \@constraints,
                       );

$create_ndx_ddl .= group_header( 12 ) . $obj->create    if @constraints;

#
# Step 9 - Recreate all Foreign Keys referenceing our tables and IOT's or
#          referenceing the tables of our other indexes.  Use the same list
#          used in Step 2 to drop them ($fk_aref).
#

$obj = DDL::Oracle->new(
                         type => 'constraint',
                         list => $fk_aref,
                       );

$create_ndx_ddl .= group_header( 13 ) . $obj->create    if @$fk_aref;

#
# Step 10 - REBUILD all UNUSABLE indexes/index [sub]partitions. These are
#           the non-partitioned or Global partitioned indexes on THE
#           PARTITIONS.
#

$stmt =
      "
       SELECT 
              owner
            , index_name
       FROM
              dba_indexes
       WHERE
              (
                  owner
                , table_name
              ) IN (
                     SELECT
                            owner
                          , segment_name
                     FROM
                            THE_PARTITIONS
                   )
       MINUS
       SELECT              -- Ignore partitioned, LOCAL indexes
              owner
            , index_name
       FROM
              dba_part_indexes
       WHERE
              locality = 'LOCAL'
       ORDER
          BY
              1
      ";

$sth = $dbh->prepare( $stmt );
$sth->execute;
$aref = $sth->fetchall_arrayref;

$obj = DDL::Oracle->new(
                         type => 'index',
                         list => $aref,
                       );

$create_ndx_ddl .= group_header( 14 ) . $obj->resize    if @$aref;

#
# It's hard to believe, but maybe they gave us an empty tablespace
# to practice on.
#

die "\n***Error:  Tablespace $tblsp is empty. 
           Doest thou take me for a fool?\n\n"
     unless $create_tbl_ddl . $create_ndx_ddl;

#
# OK, we're ligit.  Coalesce all data/index tablespaces
#

$stmt =
      "
       SELECT
              LOWER(tablespace_name)
       FROM
              dba_tablespaces  t
       WHERE
                  status            = 'ONLINE'
              AND contents         <> 'TEMPORARY'
              AND tablespace_name  <> 'SYSTEM'
              AND extent_management = 'DICTIONARY'
       MINUS
       SELECT
              LOWER(tablespace_name)
       FROM
              dba_segments
       WHERE
              segment_type    = 'ROLLBACK'
       ORDER
          BY
              1
      ";

$sth = $dbh->prepare( $stmt );
$sth->execute;
$aref = $sth->fetchall_arrayref;

foreach $row ( @$aref )
{
  $drop_ddl .= "PROMPT ALTER TABLESPACE @$row->[0] COALESCE\n\n" .
               "ALTER TABLESPACE @$row->[0] COALESCE ;\n\n",
}

# Get rid of double blank lines
$drop_ddl        =~ s|\n\n+|\n\n|g;
$drop_temp_ddl   =~ s|\n\n+|\n\n|g;
$create_tbl_ddl  =~ s|\n\n+|\n\n|g;
$create_ndx_ddl  =~ s|\n\n+|\n\n|g;
$create_temp_ddl =~ s|\n\n+|\n\n|g;

drop_perf_temps();

#
# Wrap it up -- open, write and close all files
#

if ( $create_temp_ddl )
{
  $add_temp_sql = "$sqldir/$prefix${tblsp}_add_temp.sql";
  print "Create temps            : $add_temp_sql\n";
  write_file( $add_temp_sql, $create_temp_ddl, 'REM' );

  $drop_temp_sql = "$sqldir/$prefix${tblsp}_drop_temp.sql";
  print "Drop temps              : $drop_temp_sql\n";
  write_file( $drop_temp_sql, $drop_temp_ddl, 'REM' );
}

my $drop_all_sql = "$sqldir/$prefix${tblsp}_drop_all.sql";
print "Drop objects            : $drop_all_sql\n";
write_file( $drop_all_sql, $drop_ddl, 'REM' );

my $add_tbl_sql = "$sqldir/$prefix${tblsp}_add_tbl.sql";
print "Create tables           : $add_tbl_sql\n";
write_file( $add_tbl_sql, $create_tbl_ddl, 'REM' );

my $add_ndx_sql = "$sqldir/$prefix${tblsp}_add_ndx.sql";
print "Create indexes          : $add_ndx_sql\n\n";
write_file( $add_ndx_sql, $create_ndx_ddl, 'REM' );

my $pipefile = "$expdir/$prefix$tblsp.pipe";
unlink $pipefile;
eval { system ("mknod $pipefile p") };

if ( $create_temp_ddl )
{
  $prttn_exp_par   = "$expdir/$prefix${tblsp}_prttn_exp.par";
  $prttn_exp_text  = export_par_text( $prttn_exp_log, \@export_temps);
  print "Partition Export parfile: $prttn_exp_par\n";
  print "Partition Export logfile: $prttn_exp_log\n";
  write_file( $prttn_exp_par, $prttn_exp_text, '#' );

  $prttn_imp_par  = "$expdir/$prefix${tblsp}_prttn_imp.par";
  $prttn_imp_text = import_par_text( $prttn_imp_log, \@export_temps );
  print "Partition Import parfile: $prttn_imp_par\n";
  print "Partition Import logfile: $prttn_imp_log\n\n";
  write_file( $prttn_imp_par, $prttn_imp_text, '#' );
}

my $exp_par   = "$expdir/$prefix${tblsp}_exp.par";
my $exp_text  = export_par_text( $exp_log, \@export_objects );
print "Table Export parfile    : $exp_par\n";
print "Table Export logfile    : $exp_log\n";
write_file( $exp_par, $exp_text, '#' );

my $imp_par  = "$expdir/$prefix${tblsp}_imp.par";
my $imp_text = import_par_text( $imp_log, \@export_objects );
print "Table Import parfile    : $imp_par\n";
print "Table Import logfile    : $imp_log\n\n";
write_file( $imp_par, $imp_text, '#' );

print "Export FIFO pipe        : $pipefile\n\n";

#
# And, finally, the little shell scripts to help with the driving
#

print "\n";

my $i     = 0;
my $shell = "$sqldir/$prefix$tblsp.sh";
my $gzip  = "$expdir/$prefix${tblsp}_prttn.dmp.gz";

if ( $create_temp_ddl )
{

  $script = $shell . ++$i;
  $text =
    "# Step $i -- Export the partitions in Tablespace $tblsp\n\n" .
    "nohup cat $pipefile | gzip -c \\\n" .
    "        > $gzip &\n\n" .
    "exp / parfile = $prttn_exp_par\n" .
    check_exp_log( $script, $prttn_exp_log );
  create_shell( $script, $text );

  $script = $shell . ++$i;
  $text =
    "# Step $i -- Use SQL*Plus to run $add_temp_sql\n" .
    "#           which will create temp tables for partitions " .
    "in tablespace $tblsp\n\n" .
    "sqlplus -s / << EOF\n\n" .
    "   SPOOL $add_temp_log\n\n" .
    "   @ $add_temp_sql\n\n" .
    "EOF\n" .
    check_sql_log( $script, $add_temp_log );
  create_shell( $script, $text );
}

$script = $shell . ++$i;
$text = "# Step $i -- Export the tables in Tablespace $tblsp\n\n";
if ( @export_objects )
{
  $text .=
  "nohup cat $pipefile | gzip -c \\\n" .
  "        > $gzip &\n\n" .
  "exp / parfile = $exp_par\n" .
  check_exp_log( $script, $exp_log );
}
else
{
  $text .=
  "echo\n" .
  "echo There are no Tables in tablespace $tblsp.\n" .
  "echo Skipping Export.\n" .
  "echo\n" .
  "echo $shell\n" .
  "echo completed successfully without errors.\n" .
  "echo on \` date \`\n" .
  "echo\n\n";
}
create_shell( $script, $text );

$script = $shell . ++$i;
$text =
  "# Step $i -- Use SQL*Plus to run $drop_all_sql\n" .
  "#           which will drop all objects in tablespace $tblsp\n\n" .
  "sqlplus -s / << EOF\n\n" .
  "   SPOOL $drop_all_log\n\n" .
  "   @ $drop_all_sql\n\n" .
  "EOF\n" .
  check_sql_log( $script, $drop_all_log );
create_shell( $script, $text );

$script = $shell . ++$i;
$text =
  "# Step $i -- Use SQL*Plus to run $add_tbl_sql\n".
  "#           which will recreate all tables in tablespace $tblsp\n\n" .
  "sqlplus -s / << EOF\n\n" .
  "   SPOOL $add_tbl_log\n\n" .
  "   @ $add_tbl_sql\n\n" .
  "EOF\n" .
  check_sql_log( $script, $add_tbl_log );
create_shell( $script, $text );

$script = $shell . ++$i;
$text = "# Step $i -- Import the tables back into Tablespace $tblsp\n\n";
if ( @export_objects )
{
  $text .=
  "nohup gunzip -c $gzip \\\n" .
  "              > $pipefile &\n\n" .
  "imp / parfile = $imp_par\n" .
  check_imp_log( $script, $imp_log );
}
else
{
  $text .=
  "echo\n" .
  "echo There are no Tables in tablespace $tblsp.\n" .
  "echo Skipping Import.\n" .
  "echo\n" .
  "echo $shell\n" .
  "echo completed successfully without errors.\n" .
  "echo on \` date \`\n" .
  "echo\n\n";
}
create_shell( $script, $text );

$script = $shell . ++$i;
$text =
  "# Step $i -- Use SQL*Plus to run $add_ndx_sql\n" .
  "#           which will recreate all indexes/constraints " .
  "in tablespace $tblsp\n\n" .
  "sqlplus -s / << EOF\n\n" .
  "   SPOOL $add_ndx_log\n\n" .
  "   @ $add_ndx_sql\n\n" .
  "EOF\n" .
  check_sql_log( $script, $add_ndx_log );
create_shell( $script, $text );

$text = "echo $shell is being executed by $user\n" .
        "echo on \` date \`\n\n";

foreach my $j ( 1 .. $i )
{
  $text .= "$shell$j\n\n" .
           "RC=\$?\n\n" .
           "if [ \${RC} -gt 0 ]\n" .
           "then\n\n" .
           "   echo\n" .
           "   echo\n" .
           "   echo '*** ERROR'\n" .
           "   echo $shell$j failed\n" .
           "   echo on \` date \`\n" .
           "   echo\n" .
           "   exit \${RC}\n\n" .
           "fi\n\n";
}

$text .= "echo And so did $shell\n" .
         "echo\n" .
         "echo YAHOO!!\n" .
         "echo\n" .
         "exit 0\n\n";

print "\nAnd if you want a driver script for all of the above, it is:\n\n",
      "   $shell\n\n\n";
open SHELL, ">$shell"     or die "Can't open $shell: $!\n";
write_header( \*SHELL, $shell, '# ' );
print SHELL $text . "#  --- END OF FILE ---\n\n";
close SHELL                  or die "Can't close $shell: $!\n";

if ( $create_temp_ddl )
{
  $gzip  = "$expdir/$prefix${tblsp}_prttn.dmp.gz";

  print "\n*** The following 2 scripts ARE FOR FALLBACK PURPOSES ONLY!!\n" .
        "*** Use these scripts ONLY IF Shell #2 HAD ERRORS.\n\n";

  $script = $shell . ++$i;
  $text =
    "# USE FOR FALLBACK PURPOSES ONLY\n\n" .
    "# Use SQL*Plus to run $drop_temp_sql\n" .
    "# which will drop the temp tables holding data for partitions " .
    "in tablespace $tblsp\n\n" .
    "sqlplus -s / << EOF\n\n" .
    "   SPOOL $drop_temp_log\n\n" .
    "   @ $drop_temp_sql\n\n" .
    "EOF\n" .
    check_sql_log( $script, $drop_temp_log );
  create_shell( $script, $text );

  $script = $shell . ++$i;
  $text =
    "# USE FOR FALLBACK PURPOSES ONLY\n\n" .
    "#Import the tables back into the partitions in " .
    "Tablespace $tblsp\n\n" .
    "echo\n" .
    "echo \"**************** NOTICE ***************\"\n" .
    "echo\n" .
    "echo Ignore warnings about missing partitions -- because not\n" .
    "echo all partitions were exported, and thus not all partitions\n" .
    "echo need be re-imported.\n" .
    "echo The error to be ignored is:\n" .
    "echo\n" .
    "echo \"  IMP-00057: Warning: Dump file may not contain data of all partitions...\"\n" .
    "echo\n" .
    "echo \"************ END OF NOTICE ************\"\n\n" .
    "nohup gunzip -c $gzip \\\n" .
    "              > $pipefile &\n\n" .
    "imp / parfile = $prttn_imp_par\n" .
    check_imp_log( $script, $prttn_imp_log );
  create_shell( $script, $text );
}

my @shells = glob( "$sqldir/$prefix$tblsp.sh*" );
chmod( 0754, @shells ) == @shells or die "\nCan't chmod some shells: $!\n";

print "\n$0 completed successfully\non ", scalar localtime,"\n\n";

exit 0;

#################### Subroutines (alphabetically) ######################

# sub check
#
# returns text for a shell script to check its LOG file for errors
#
sub check
{
  my ($shell, $log ) = @_;

  return
"then

   echo
   echo '*** ERRORS during'
   echo $shell
   echo
   echo CHECK LOG $log
   echo
   exit 1

else

   echo
   echo $shell
   echo completed successfully without errors.
   echo on \` date \`
   echo

fi

";

}

# sub check_exp_log
#
# returns text for a shell script to check its exp log file for errors
#
sub check_exp_log
{
  my ( $shell, $log ) = @_;

  return
"
cat $log 

EXP=\` grep -c ^EXP- $log \`
ORA=\` grep -c ^ORA- $log \`

if [ \${ORA} -gt 0 -o \${EXP} -gt 0 ]
" . 
check( @_ );
}

# sub check_imp_log
#
# returns text for a shell script to check its imp log file for errors
#
sub check_imp_log
{
  my ( $shell, $log ) = @_;

  # Check log for errors, but ignore:
  #   IMP-00057 -- Not all partitions imported (we didn't export them all)
  #   IMP-00041 -- Store PL/SQL compilation errors (not our fault)
  return
"
cat $log 

IMP=\` grep -v ^IMP-00057 $log | \\
      grep -v ^IMP-00041 | \\
      grep -c ^IMP- \`
ORA=\` grep -c ^ORA- $log \`

if [ \${ORA} -gt 0 -o \${IMP} -gt 0 ]
" . 
check( @_ );
}

# sub check_sql_log
#
# returns text for a shell script to check its SQL spool file for errors
#
sub check_sql_log
{
  my ( $shell, $log ) = @_;

  return
"
ORA=\` grep -c ^ORA- $log \`

if [ \${ORA} -gt 0 ]
" . 
check( @_ );

}

# sub connect_to_oracle
#
# Requires both "user" and "password", or neither.  If "user" is supplied
# but not "password", will prompt for a "password".  On Unix systems, a
# system call to "stty" is made before- and after-hand to control echoing
# of keystrokes.  [How do we do this on Windows?]
#
sub connect_to_oracle
{
  if ( $args{ user } and not $args{ password } )
  {
    print "Enter password: ";
    eval{ system("stty -echo" ); };
    chomp( $args{ password } = <STDIN> );
    print "\n";
    eval{ system( "stty echo" ); };
  }

  $args{ sid }      = "" unless $args{ sid };
  $args{ user }     = "" unless $args{ user };
  $args{ password } = "" unless $args{ password };

  $dbh = DBI->connect(
                       "dbi:Oracle:$args{ sid }",
                       "$args{ user }",
                       "$args{ password }",
                       {
                         PrintError => 0,
                         RaiseError => 1,
                       }
                     );

  # $dbh->do( "alter session set sql_trace = true" );

  DDL::Oracle->configure(
                          dbh    => $dbh,
                          view   => 'DBA',
                          schema => 1,
                          resize => $args{ resize } || 1,
                        );
}

# sub create_shell
#
# Opens, writes $text, closes the named shell script
#
sub create_shell
{
  my ( $script, $text ) = @_;

  print "Shell #$i is $script\n";
  open SHELL, ">$script"     or die "Can't open $script: $!\n";
  write_header( \*SHELL, $script, '# ' );
  print SHELL $text . "#  --- END OF FILE ---\n\n";
  close SHELL                  or die "Can't close $script: $!\n";
}

# sub drop_perf_temps
#
# Drops the temporary tables created to boost performance
#
sub drop_perf_temps
{
  foreach my $table ( @perf_tables )
  {
    $stmt =
     "
      SELECT
             'Yo!'
      FROM
             user_synonyms
      WHERE
             synonym_name = UPPER( ? )
     ";

    $sth = $dbh->prepare( $stmt );
    $sth->execute( $table );
    my $present = $sth->fetchrow_array;
    $dbh->do( "DROP SYNONYM $table" )    if $present;

    if ( $table =~ /^DBA/ )
    {
      $stmt =
       "
        SELECT
               'Present, sir!'
        FROM
               user_tables
        WHERE
               table_name = UPPER( ? )
       ";

      $sth = $dbh->prepare( $stmt );
      $sth->execute( "$prefix$table" );
      my $present = $sth->fetchrow_array;

      if ( $present )
      {
        $dbh->do( "TRUNCATE TABLE $prefix$table" );
        $dbh->do( "DROP     TABLE $prefix$table" );
      }
    }
    else
    {
      $stmt =
       "
        SELECT
               'Present, sir!'
        FROM
               user_tables
        WHERE
               table_name = ?
       ";

      $sth = $dbh->prepare( $stmt );
      $sth->execute( $table );
      my $present = $sth->fetchrow_array;

      if ( $present )
      {
        $dbh->do( "TRUNCATE TABLE $table" );
        $dbh->do( "DROP     TABLE $table" );
      }
    }
  }
}

# sub escaped_dollar_signs
#
# Routines dealing with the Temp tables, indexes and constraints must
# substitute generated names for the names of real objects returned by
# DDL::Oracle.  However, Oracle allows dollar signs ('$') within names
# for database objects.  This causes problems with the s/// operator,
# since it sees the '$' as a meta character, causing the substitution
# to fail.
#
# This little subroutine inserts a '\' in front of each '$', which
# effectively escapes it for the s/// operator.
#
sub escaped_dollar_signs
{
  my ( $str ) = @_;

  my $pos = 0;

  until ( $pos == -1 )
  {
    $pos = index( $str, '$', $pos );
    if ( $pos > -1 )
    {
      substr( $str, $pos, 0 ) = qq#\\#;
      $pos += 2;
    }
  }

  return $str;
}

# sub export_par_text
#
# Returns the text for the parfile of an export
#
sub export_par_text
{
  my ( $log, $table_aref ) = @_;

  my $text = "log          = $log\n" .
             "file         = $pipefile\n" .
             "rows         = y\n" .
             "grants       = y\n";

  # My linux Oracle 8.1.6 has a bug, so
  $text   .= "direct       = y\n"    unless $OSNAME eq 'linux';

  $text   .= "buffer       = 65535\n" .
             "indexes      = n\n" .
             "compress     = n\n" .
             "triggers     = y\n" .
             "statistics   = none\n" .
             "constraints  = n\n" .
             "recordlength = 65535\n" .
             "tables       = (\n" .
             "                   " .
             join ( "\n                 , ", @$table_aref ) .
             "\n               )\n\n";

  return $text
}

# sub get_args
#
# Uses supplied module Getopt::Long to place command line options into the
# hash %args.  Ensures that at least the mandatory argument --tablespace
# was supplied.  Also verifies directory arguments and connects to Oracle.
#
sub get_args
{
  #
  # Get options from command line and store in %args
  #
  GetOptions(
              \%args,
              "alttablespace:s",
              "expdir:s",
              "logdir:s",
              "password:s",
              "prefix:s",
              "sid:s",
              "resize:s",
              "sqldir:s",
              "tablespace:s",
              "user:s",
            );

  #
  # If there is anything left in @ARGV, we have a problem
  #
  die "\n***Error:  unrecognized argument",
      ( @ARGV == 1 ? ":  " : "s:  " ),
      ( join " ",@ARGV ),
      "\n$0 aborted,\n\n" ,
    if @ARGV;
  
  #
  # Validate arguments (maybe they type as badly as we do!
  #

  $tblsp = uc( $args{ tablespace } ) or
  die "\n***Error:  You must specify --tablespace=<NAME>\n",
      "\n$0 aborted,\n\n";

  $sqldir = ( $args{ sqldir } eq "." ) ? cwd : $args{ sqldir };
  die "\n***Error:  sqldir '$sqldir', is not a Directory\n",
      "\n$0 aborted,\n\n"
    unless -d $sqldir;

  die "\n***Error:  sqldir '$sqldir', is not a writeable Directory\n",
      "\n$0 aborted,\n\n"
    unless -w $sqldir;

  $logdir = ( $args{ logdir } eq "." ) ? cwd : $args{ logdir };
  die "\n***Error:  logdir '$logdir', is not a Directory\n",
      "\n$0 aborted,\n\n"
    unless -d $logdir;

  die "\n***Error:  logdir '$logdir', is not a writeable Directory\n",
      "\n$0 aborted,\n\n"
    unless -w $logdir;

  $expdir = ( $args{ expdir } eq "." ) ? cwd : $args{ expdir };
  die "\n***Error:  expdir '$expdir', is not a Directory\n",
      "\n$0 aborted,\n\n"
    unless -d $expdir;

  die "\n***Error:  sqldir '$expdir', is not a writeable Directory\n",
      "\n$0 aborted,\n\n"
    unless -w $expdir;

  $prefix = $args{ prefix };

  $add_ndx_log     = "$logdir/$prefix${tblsp}_add_ndx.log";
  $add_tbl_log     = "$logdir/$prefix${tblsp}_add_tbl.log";
  $add_temp_log    = "$logdir/$prefix${tblsp}_add_temp.log";
  $drop_all_log    = "$logdir/$prefix${tblsp}_drop_all.log";
  $drop_temp_log   = "$logdir/$prefix${tblsp}_drop_temp.log";
  $exp_log         = "$logdir/$prefix${tblsp}_exp.log";
  $imp_log         = "$logdir/$prefix${tblsp}_imp.log";
  $prttn_exp_log   = "$logdir/$prefix${tblsp}_prttn_exp.log";
  $prttn_imp_log   = "$logdir/$prefix${tblsp}_prttn_imp.log";

  push @logfiles, (
                    $add_ndx_log,
                    $add_tbl_log,
                    $add_temp_log,
                    $drop_all_log,
                    $drop_temp_log,
                    $exp_log,
                    $imp_log,
                    $prttn_exp_log,
                    $prttn_imp_log,
                  );

  validate_log_names( \@logfiles );

  $alttblsp = uc( $args{ alttablespace } );

  connect_to_oracle();      # Will fail unless sid, user, password are OK

  print "Initializing private copies of some dictionary views...\n\n";

  initialize_perf_temps();

  # Confirm the tablespace exists
  $stmt =
      "
       SELECT
              tablespace_name
       FROM
              dba_tablespaces  t
       WHERE
                  tablespace_name   = '$tblsp'
              AND status            = 'ONLINE'
              AND contents         <> 'TEMPORARY'
              AND extent_management = 'DICTIONARY'
       MINUS
       SELECT
              tablespace_name
       FROM
              dba_segments
       WHERE
              segment_type = 'ROLLBACK'
      ";

  $sth = $dbh->prepare( $stmt );
  $sth->execute;
  $row = $sth->fetchrow_array;

  die "\n***Error:  Tablespace \U$tblsp",
      " does not exist\n",
      "           or is not ONLINE\n",
      "           or is managed LOCALLY\n",
      "           or is a TEMPORARY tablespace\n",
      "           or contains ROLLBACK segments.\n\n"
    unless $row;

  # First row returned is valid tablespace, and is $alttblsp.
  # Since we know $tblsp is good, we're guaranteed at least one row.
  $stmt =
      "
       (
         SELECT
                tablespace_name
         FROM
                dba_tablespaces
         WHERE
                    tablespace_name   = '$alttblsp'
                AND status            = 'ONLINE'
                AND contents         <> 'TEMPORARY'
                AND extent_management = 'DICTIONARY'
         MINUS
         SELECT
                tablespace_name
         FROM
                dba_segments
         WHERE
                segment_type = 'ROLLBACK'
       )
       UNION ALL
       (
         SELECT
                tablespace_name
         FROM
                dba_tablespaces
         WHERE
                    tablespace_name   = 'USERS'
                AND status            = 'ONLINE'
                AND contents         <> 'TEMPORARY'
                AND extent_management = 'DICTIONARY'
         MINUS
         SELECT
                tablespace_name
         FROM
                dba_segments
         WHERE
                segment_type = 'ROLLBACK'
       )
       UNION ALL
       (
         SELECT
                '$tblsp'
         FROM
                dual
       )
      ";

  $sth = $dbh->prepare( $stmt );
  $sth->execute;
  $aref = $sth->fetchall_arrayref;

  $alttblsp = ( shift @$aref )->[0];

  my ( undef,undef,undef,$day,$month,$year,undef,undef,undef ) = localtime;
  $date = $year + 1900 . $month + 1 . $day;
}

# sub group_header
#
# Returns a Remark to identify the ensuing DDL statements
#
sub group_header
{
  my ( $nbr ) = @_;

  return 'REM ' . '#' x 60 . "\n" .
         "REM\n" .
         "REM                      Statement Group $nbr\n" .
         "REM\n" .
         'REM ' . '#' x 60 . "\n\n";
}

# sub import_par_text
#
# Returns the text for the parfile of an import
#
sub import_par_text
{
  my ( $log, $table_aref ) = @_;

  return            "log          = $log\n" .
                    "file         = $pipefile\n" .
                    "rows         = y\n" .
                    "commit       = y\n" .
                    "ignore       = y\n" .
                    "buffer       = 65535\n" .
                    "analyze      = n\n" .
                    "recordlength = 65535\n" .
                    "full         = y\n\n" .
                    "#tables       = (\n" .
                    "#                   " .
                    join ( "\n#                 , ", @$table_aref ) .
                    "\n#               )\n\n";
}

# sub index_and_exchange
#
# Generate the DDL to:
#
# 1.  Create an index on named temp table equal to every LOCAL index on the
#     named partitioned table.
# 2.  Create a PK for the temp table equal to the PK of the partitioned table,
#     if any.
# 3.  Exchange the temp table with the named partition.
#
sub index_and_exchange
{
  my ( 
       $temp,
       $owner, 
       $table, 
       $partition, 
       $type, 
       $partitioning_type,
       $analyzed
     ) = @_;

  my $sql;
  my $text;

  # Get partitioned, local indexes
  $stmt =
      "
       SELECT DISTINCT
              index_name
       FROM
              dba_indexes
       WHERE
                  owner      = ?
              AND table_name = ?
       MINUS
       SELECT                     -- Ignore GLOBAL indexes
              index_name
       FROM
              dba_part_indexes
       WHERE
                  owner      = ?
              AND table_name = ?
              AND locality   = 'GLOBAL'
       MINUS
       SELECT                     -- Ignore non-partitioned indexes
              segment_name
       FROM
              dba_segments
       WHERE
              segment_type = 'INDEX'
       ORDER
          BY
              1
      ";

  $sth = $dbh->prepare( $stmt );
  $sth->execute( $owner, $table, $owner, $table );
  $aref = $sth->fetchall_arrayref;

  foreach $row ( @$aref )
  {
    my $index = @$row->[0];

    $obj = DDL::Oracle->new(
                             type => 'exchange index',
                             list => [
                                       [
                                         "$owner",
                                         "$index:$partition",
                                       ]
                                     ],
                           );
    my $sql = $obj->create;
    # Remove REM lines created by DDL::Oracle
    $sql =  ( join "\n", grep !/^REM/, split /\n/, $sql ) . "\n\n";

    my $indx =  "${tblsp}_${date}_" . unique_nbr();

    # Change the CREATE INDEX statement
    # to use the Temp Index and Table names
    my $ownr = escaped_dollar_signs( $owner );
    my $tabl = escaped_dollar_signs( $table );
    my $indr = escaped_dollar_signs( $index );
    $sql     =~ s|\L$ownr.$indr|\L$owner.$indx|g;
    $sql     =~ s|\L$ownr.$tabl|\L$owner.$temp|g;

    $text .= $sql;
  }

  $stmt =
      "
       SELECT
              constraint_name
       FROM
              THE_CONSTRAINTS
       WHERE
                  owner           = ?
              AND table_name      = ?
              AND constraint_type = 'P'
      ";

  $sth = $dbh->prepare( $stmt );
  $sth->execute( $owner, $table );
  my @row = $sth->fetchrow_array;

  if ( @row )
  {
    my ( $constraint ) = @row;

    $obj = DDL::Oracle->new(
                             type => 'constraint',
                             list => [
                                       [
                                         "$owner",
                                         "$constraint",
                                       ]
                                     ],
                           );
    my $sql = $obj->create;
    # Remove REM lines created by DDL::Oracle
    $sql =  ( join "\n", grep !/^REM/, split /\n/, $sql ) . "\n\n";

    my $cons =  "${tblsp}_${date}_" . unique_nbr();

    # Change the ALTER TABLE ADD CONSTRAINT statement
    # to use the Temp Constraint and Table names
    my $ownr = escaped_dollar_signs( $owner );
    my $tabl = escaped_dollar_signs( $table );
    my $conr = escaped_dollar_signs( $constraint );
    $sql     =~ s|\L$ownr.$tabl|\L$owner.$temp|g;
    $sql     =~ s|\L$conr|\L$cons|g;

    $text .= $sql;
  }

  if ( $analyzed eq 'YES' )
  {
    $text .= "PROMPT " .
             "ANALYZE TABLE \L$owner.$temp\n\n" .
             "ANALYZE TABLE \L$owner.$temp \UESTIMATE STATISTICS\n" .
             "   FOR TABLE\n" .
             "   FOR ALL INDEXED COLUMNS ;\n\n";
  }

  $text .= "PROMPT " .
           "ALTER TABLE \L$owner.$table \UEXCHANGE $type \L$partition\n\n" .
           "ALTER TABLE \L$owner.$table\n" .
           "   \UEXCHANGE $type \L$partition \UWITH TABLE \L$owner.$temp\n" .
           "   INCLUDING INDEXES\n".
           "   WITHOUT VALIDATION ;\n\n";

  return $text;
}

# sub initialize_perf_temps
#
sub initialize_perf_temps
{
  # Drop the Performance enhancing tables -- they shouldn't be here,
  # but who knows, maybe we crashed last time (how rude!)

  drop_perf_temps();

  # Some Dictionary views are queried repeatedly by us (defrag.pl) as well
  # as by DDL::Oracle.  They are often complex views, taking as much as 3
  # to 10 seconds for each query on a large database (e.g., 50,000 segments).
  # Let's get our own, more efficient copy of this data and avoid this
  # overhead

  TABLE:
    foreach my $table ( @perf_tables )
    {
      next TABLE unless $table =~ /^DBA/;

      $dbh->do
      ( "
         CREATE GLOBAL TEMPORARY TABLE $prefix$table
         ON COMMIT PRESERVE ROWS
         AS
         SELECT
                *
         FROM
                sys.$table
        "
      );
      $dbh->do( "CREATE SYNONYM $table FOR $prefix$table" );
    }
}

# sub initialize_queries
#
# Initializes the driving queries used to retrieve object names involved in
# the defrag.  Because these are UNIONed and MINUSed, at times, store the
# the results in in-memory temporary tables for efficiency reasons.
#
sub initialize_queries
{
  # This query produces a list of THE CONSTRAINTS, sans search_condition
  # which is needed for creating Check Constraints
  $stmt =
      "
       CREATE GLOBAL TEMPORARY TABLE the_constraints
       ON COMMIT PRESERVE ROWS
       AS
       SELECT
              owner
            , constraint_name
            , constraint_type
            , table_name
            , r_owner
            , r_constraint_name
       FROM
              dba_constraints
      ";

  $dbh->do( $stmt );

  # This query produces a list of THE PARTITIONS, which are the partitions
  # in THE TABLESPACE belonging to tables which have at least one partition
  # in some other tablespace.  These will be the target of ALTER TABLE
  # EXCHANGE [SUB]PARTITION statements with "temp" tables.
  #
  $stmt =
      "
       CREATE GLOBAL TEMPORARY TABLE the_partitions
       ON COMMIT PRESERVE ROWS
       AS
       SELECT
              s.owner
            , s.segment_name
            , s.partition_name
            , SUBSTR(s.segment_type,7)                 AS segment_type
            , p.partitioning_type                      AS partitioning_type
            , DECODE(
                      s.segment_type
                     ,'TABLE PARTITION'   ,DECODE(
                                                   a.last_analyzed
                                                  ,null,'NO'
                                                  ,'YES'
                                                 )
                     ,'TABLE SUBPARTITION',DECODE(
                                                   b.last_analyzed
                                                  ,null,'NO'
                                                  ,'YES'
                                                 )
                    )                                  AS analyzed
       FROM
              dba_segments          s
            , dba_part_tables       p
            , dba_tab_partitions    a
            , dba_tab_subpartitions b
       WHERE
                  p.table_name            = s.segment_name
              AND s.segment_type       LIKE 'TABLE%PARTITION'
              AND s.tablespace_name       = '$tblsp'
              AND a.table_name        (+) = s.segment_name
              AND b.table_name        (+) = s.segment_name
              AND a.partition_name    (+) = s.partition_name
              AND b.subpartition_name (+) = s.partition_name
              AND a.table_owner       (+) = s.owner
              AND b.table_owner       (+) = s.owner
              AND EXISTS (
                           SELECT
                                  null
                           FROM
                                  dba_segments
                           WHERE
                                      segment_type  LIKE 'TABLE%PARTITION'
                                  AND tablespace_name <> '$tblsp'
                                  AND owner            = s.owner
                                  AND segment_name     = s.segment_name
                         )
              AND (
                      s.owner
                    , s.segment_name
                  ) NOT IN (
                             SELECT
                                    owner
                                  , table_name
                             FROM
                                    dba_snapshots
                           )
      ";

  $dbh->do( $stmt );

  # This query produces a list of THE INDEXES (and their tables) -- those
  # non-partitioned indexes which reside in THE TABLESPACE, plus indexes 
  # which have at least one partition in THE TABLESPACE.  These indexes are
  # on tables other than the tables of THE PARTITIONS but may be on THE
  # TABLES.
  #
  $stmt =
      "
       CREATE GLOBAL TEMPORARY TABLE the_indexes
       ON COMMIT PRESERVE ROWS
       AS
       SELECT
              owner
            , index_name
            , table_name
            , MAX(analyzed)        AS analyzed
       FROM
            (
              SELECT
                     owner
                   , index_name
                   , table_name
                   , DECODE(
                             last_analyzed
                            ,null,'NO'
                            ,'YES'
                           )                  AS analyzed
              FROM
                     dba_indexes
              WHERE
                         tablespace_name = '$tblsp'
                     AND index_type     <> 'IOT - TOP'
              UNION ALL
              SELECT
                     i.owner
                   , i.index_name
                   , i.table_name
                   , DECODE(
                             p.last_analyzed
                            ,null,'NO'
                            ,'YES'
                           )                  AS analyzed
              FROM
                     dba_indexes         i
                   , dba_ind_partitions  p
              WHERE
                         p.tablespace_name = '$tblsp'
                     AND i.owner           = p.index_owner
                     AND i.index_name      = p.index_name
                     AND i.index_type     <> 'IOT - TOP'
              UNION ALL
              SELECT
                     i.owner
                   , i.index_name
                   , i.table_name
                   , DECODE(
                             p.last_analyzed
                            ,null,'NO'
                            ,'YES'
                           )                  AS analyzed
              FROM
                     dba_indexes            i
                   , dba_ind_subpartitions  p
              WHERE
                         p.tablespace_name = '$tblsp'
                     AND i.owner           = p.index_owner
                     AND i.index_name      = p.index_name
                     AND i.index_type      <> 'IOT - TOP'
            )
       WHERE
             (
                 owner
               , table_name
             ) NOT IN (
                        SELECT
                               owner
                             , segment_name
                        FROM
                               THE_PARTITIONS
                      )
       GROUP
          BY
              owner
            , index_name
            , table_name
      ";

  $dbh->do( $stmt );

  # This query produces a list of THE IOTs -- non-partition index organized
  # tables which reside in THE TABLESPACE or partitioned index organized
  # tables which have at least one partition in THE TABLESPACE.
  # 
  $stmt =
      "
       CREATE GLOBAL TEMPORARY TABLE the_IOTs
       ON COMMIT PRESERVE ROWS
       AS
       SELECT
              owner
            , table_name
            , MAX(analyzed)        AS analyzed
       FROM
            (
              SELECT
                     owner
                   , table_name
                   , DECODE(
                             last_analyzed
                            ,null,'NO'
                            ,'YES'
                           )                  AS analyzed
              FROM
                     dba_indexes
              WHERE
                         tablespace_name = '$tblsp'
                     AND index_type      = 'IOT - TOP'
              UNION ALL
              SELECT
                     i.owner
                   , i.table_name
                   , DECODE(
                             p.last_analyzed
                            ,null,'NO'
                            ,'YES'
                           )                  AS analyzed
              FROM
                     dba_indexes         i
                   , dba_ind_partitions  p
              WHERE
                         p.tablespace_name = '$tblsp'
                     AND i.index_type      = 'IOT - TOP'
                     AND i.owner           = p.index_owner
                     AND i.table_name      = p.index_name
              UNION ALL
              SELECT
                     i.owner
                   , i.table_name
                   , DECODE(
                             p.last_analyzed
                            ,null,'NO'
                            ,'YES'
                           )                  AS analyzed
              FROM
                     dba_indexes            i
                   , dba_ind_subpartitions  p
              WHERE
                         p.tablespace_name = '$tblsp'
                     AND i.index_type      = 'IOT - TOP'
                     AND i.owner           = p.index_owner
                     AND i.table_name      = p.index_name
            )
       GROUP
          BY
              owner
            , table_name
      ";

  $dbh->do( $stmt );

  # This query produces a list of THE TABLES -- non-partitioned tables which
  # reside in THE TABLESPACE or partitioned tables which have at every
  # partition in THE TABLESPACE.
  #
  $stmt =
      "
       CREATE GLOBAL TEMPORARY TABLE the_tables
       ON COMMIT PRESERVE ROWS
       AS
       SELECT
              owner
            , table_name
            , MAX(analyzed)        AS analyzed
       FROM
            (
              SELECT
                     owner
                   , table_name
                   , DECODE(
                             last_analyzed
                            ,null,'NO'
                            ,'YES'
                           )                  AS analyzed
              FROM
                     dba_tables
              WHERE
                     tablespace_name   = '$tblsp'
              UNION ALL
              SELECT
                     table_owner
                   , table_name
                   , DECODE(
                             last_analyzed
                            ,null,'NO'
                            ,'YES'
                           )                  AS analyzed
              FROM
                     dba_tab_partitions  t
              WHERE
                         tablespace_name   = '$tblsp'
                     AND NOT EXISTS (
                                      SELECT
                                             null
                                      FROM
                                             dba_tab_partitions
                                      WHERE
                                                 table_owner = t.table_owner
                                             AND table_name  = t.table_name
                                             AND tablespace_name <> '$tblsp'
                                      UNION ALL
                                      SELECT
                                             null
                                      FROM
                                             dba_tab_subpartitions
                                      WHERE
                                                 table_owner = t.table_owner
                                             AND table_name  = t.table_name
                                             AND tablespace_name <> '$tblsp'
                                    )
              UNION ALL
              SELECT
                     table_owner
                   , table_name
                   , DECODE(
                             last_analyzed
                            ,null,'NO'
                            ,'YES'
                           )                  AS analyzed
              FROM
                     dba_tab_subpartitions  t
              WHERE
                         tablespace_name   = '$tblsp'
                     AND NOT EXISTS (
                                      SELECT
                                             null
                                      FROM
                                             dba_tab_subpartitions
                                      WHERE
                                                 table_owner = t.table_owner
                                             AND table_name  = t.table_name
                                             AND tablespace_name <> '$tblsp'
                                    )
              -- Ignore Snapshots/Materialized Views.
              -- Yeah, it's a cop out.
              MINUS
              SELECT
                     owner
                   , table_name
                   , 'YES'                    AS analyzed
              FROM
                     dba_snapshots
              MINUS
              SELECT
                     owner
                   , table_name
                   , 'NO'                     AS analyzed
              FROM
                     dba_snapshots
            )
       GROUP
          BY
              owner
            , table_name
      ";

  $dbh->do( $stmt );
}

# sub move
# 
# Formats an ALTER TABLE MOVE [SUB]PARTITION statement
#
sub move
{
  my ( 
       $owner, 
       $table, 
       $partition, 
       $type, 
       $part_type,
       $analyzed,
       $tblsp,
     ) = @_;

  my $sql = "PROMPT " .
            "ALTER TABLE \L$owner.$table \UMOVE $type \L$partition\n\n" .
            "ALTER TABLE \L$owner.$table \UMOVE $type \L$partition\n" .
            "TABLESPACE \L$tblsp\n";

  # Can't specify INITIAL/NEXT on HASH partitions,
  # and all subpartitions are currently HASH
  if ( $type eq 'PARTITION' and $part_type eq 'RANGE' )
  {
    $sql .= "STORAGE\n" .
            "(\n" .
            "  INITIAL  2K\n" .
            "  NEXT     2K\n" .
            ") ";
  }

  return $sql .= ";\n\n";
}

# sub print_help
#
# Displays a description of each argument.
#
sub print_help
{
  print "
  Usage:  defrag.pl [OPTION] [OPTION]...

  ?, -?, -h, --help   Prints this help.

  --tablespace=TABLESPACE

           Drop/recreate all objects in the named tablespace -- tables,
           table partitions, non-partitioned indexes and indexes which
           have even one partition in the named tablespace.

           This argument is REQUIRED.

  --alttablespace=TABLESPACE

           If table partition(s) is(are) part of the defrag, a
           substitute, placeholder partition is created in this
           tablespace.  If not given, tablespace USERS will be used if
           present, otherwise the named tablespace.  If the argument
           is not given, and if there are partitioned tables in the
           named tablespace, and if there is not a USERS tablespace,
           the placeholder partitions will probably prevent a complete
           coalesce of the named tablesapace.  This argument is highly
           recommended.

  --expdir=PATH *

           Directory to place the import/export .par files.  Defaults to
           environment variable DBA_EXP, or to the current directory.

  --logdir=PATH *

           Directory to place the import/export .log files, as well
           as the SPOOLed .log files created by SQL*Plus.  Defaults to
           environment variable DBA_LOG, or to the current directory.

  --password=PASSWORD

           User's password.  Not required if user is authenticated
           externally.  Respresents a security risk on Unix systems.

           If USER is given and PASSWORD is not, program will prompt
           for PASSWORD.  This would be preferable to entering the
           password on the command line, since the password will then
           not be visible in a 'ps' command.

  --prefix=STRING *

           The leading portion of all filenames.  Defaults to 'defrag_',
           and may be '' (in which case filenames will begin with the
           name of the tablespace).

  --sid=SID *

           The SID or service used to connect to Oracle.  If omitted,
           the connection will be to the instance identified in
           environment variable ORACLE_SID.

  --resize=STRING *

           In the CREATE statement, objects are given INITIAL and NEXT
           extent sizes, appropriate for objects having the number of
           blocks used.  This is a colon delimited string consisting
           of n sets of LIMIT:INITIAL:NEXT.  LIMIT is expressed in
           Database Blocks.  The highest LIMIT may contain the string
           'UNLIMITED', and in any event will be forced to be so by
           DDL::Oracle.

  --sqldir=PATH *

           Directory to place the SQL (.sql) files.  Defaults to
           environment variable DBA_SQL, or to the current directory.

  --user=USERNAME

           Connects to Oracle as this user.  Defaults to operating
           system username.

  *  Items marked with '*' are saved in a file named .defragrc,
     stored in the user's HOME directory.  If omitted in subsequent
     usages of defrag.pl, these entries will be reused unless a
     new entry is assigned at that time.

  ";

  $text = "
  Program 'defrag.pl' uses 5 main SQL statements to retrieve record sets which
  form the basis of generated DDL.  They are sometimes UNIONed, sometimes 
  MINUSed, etc., to refine the record sets.  The queries are:

  THE TABLESPACE -- the Tablspace named by the '--tablespace=<name>' argument.

  THE CONSTRAINTS -- provides a substitute for DBA_CONSTRAINTS, sans column
  SEARCH_CONDITION.

  THE TABLES -- provides a list of Owner/Table_name's which fully reside in
  THE TABLESPACE.  These are non-partitioned tables plus partitioned tables
  where every partition and subpartition reside in THE TABLESPACE.  This list 
  excludes IOT tables.

  THE IOTS -- provides a list of Owner/Table_name's which fully or partially
  reside in THE TABLESPACE.  In other words, if a partitioned IOT table has
  even one partition in THE TABLESPACE, it is included in this list.  Reasons
  these are in  a separate list from THE TABLES include the fact that their 
  Primary Key is part of the CREATE TABLE syntax, and there are never other 
  indexes on them,

  THE INDEXES -- provides a list of Owner/Index_name/Table_name's for indexes
  not belonging to THE TABLES but which fully or partially reside in THE
  TABLESPACE.  In other words, a partitioned index with even one partition in
  THE TABLESPACE is included in this list.

  The data in THE TABLES and THE IOTS will be exported, after which members of
  all 3 of the lists will be dropped before THE TABLESPACE is coalesced into
  as few as 1 extent per datafile.

  THE PARTITIONS -- provides Owner/Table_name/Partition_name/Segment_type's 
  for all partitions and subpartitions not belonging to THE TABLES nor to THE
  IOTS but which are located in THE TABLESPACE.  If any of these exist, the
  first step will be to perform a 'safety' export of their data directly from
  THE PARTITIONS.  Under normal circumstances, this export is not used.
  Rather, for each partition a corresponding 'temp' table is built matching
  the partition in structure, indexes and Primary Key.  The temp table is then
  EXCHANGED with the partition; this results in the temp table holding the
  data and the partition becoming empty.  The empty partition is moved to the
  alternate tablespace before the coalescing takes place.  The temp table is
  then treated like a member of THE TABLES (i.e., exported, dropped,
  recreated, indexed, imported, etc.).  After the temp table has its data
  imported, it is again EXCHANGED with its original partition, and thus the
  data once again becomes part of the table in its new, properly sized 
  segment.

  Note that nothing is done with indexes on the tables of THE PARTITIONS.  In
  the event that such an index or a partition thereof happens to reside in THE
  TABLESPACE, it will still be there after all other objects have been dropped 
  or moved eleehwhere.  Likewise, unless an alternate tablespace other than
  THE TABLESPACE is given (or if the named alternate tablespace does not
  exist), then the empty partition segments will also remain in THE TABLESPACE.
  If either of these conditions occurs, the THE TABLESPACE will not be
  completely empty when it is coalesced.  This is not necessarily a big
  problem, it is just not as clean as when THE TABLESPACE becomes completely
  empty before it is coalesced.

  The following descriptions of the 'Statement Groups' show the sequence of
  statments used to defragment THE TABLESPACE.  These DDL statements are in
  3 to 5 files.  Shell scripts are provided which perform the statements in
  the correct sequence, intermingled with the exports and imports.  The user
  should check the execution of each shell script for errors before continuing
  with the next step.  Within the SQL files, each group of statements is
  delineated by a header record which refers to a 'Statement Group Number'.
  These groups are defined below.
  
  EXPORT the data from THE PARTITIONS. (If all goes well, we won't use this.)
  
   1.  For each member of THE PARTITIONS:
         a.  Create a Temp table.
         b.  Add appropriate indexes.
         c.  Add a PK, if any.
         d.  EXCHANGE the Temp table with the partition.
         e.  MOVE the [now empty] Temp table to the alternate tablespace.
  
  EXPORT the data from THE TABLES, THE IOTS and the Temp tables.
  
   2.  DROP the Temp tables created in Group #1.
  
   3.  DROP all Foreign Keys referencing THE TABLES, THE IOTS or the tables
       of THE INDEXES.
  
   4.  DROP members of THE TABLES and THE IOTS.  Note: this DROPs all
       constrints on these tables.

   5.  DROP Primary Keys, Unique Constraints and Check Constraints on the
       tables of THE INDEXES. 

   6.  DROP members of THE INDEXES unless they enforce a Primay Key or Unique
       Constraint of the same name -- those that do disappeared in Group #5.
       Note: this will generate DROP INDEX statements for PK/UK's if the 
       Constraint name differs from the Index name (e.g., system generated
       names).  It won't cause any harm, but it will show an error in the log
       file spooled in SQL*Plus; these should be ignored.  Maybe we'll fix
       this someday.

   7.  CREATE the Temp tables.
  
   8.  CREATE members of THE TABLES and THE IOTS.

  IMPORT the data for THE TABLES, THE IOTS and the Temp tables.
  
   9.  CREATE indexes and PK's on the Temp tables.  EXCHANGE them with their
       corresponding partition, and DROP the now empty Temp tables.
  
  10.  CREATE indexes on THE TABLES, plus THE INDEXES themselves.

  11.  CREATE all Constraints on THE TABLES.

  12.  CREATE Check Cosntraints on THE IOTS.

  13.  CREATE Foreign Keys referencing THE TABLES, THE IOTS or the tables
       of THE INDEXES.

  14.  REBUILD non-partitioned or Global partitioned indexes on THE PARTITIONS
       (these were marked UNUSABLE during the partition EXCHANGE).

  ONLY IF PROBLEMS OCCURED DURING EXECUTION OF GROUP #1:

  15.  DROP the Temp tables.

  IMPORT the data for THE PARTITIONS.

  ";

  write_file( "./README.defrag", $text, '' );

  print "
  Also, see the 'README.defrag' which was just written in this directory
  for information about the DDL statements generated and their sequence.
  ";

  return;
}

# sub set_defaults
#
# If file HOME/.defragrc exists, reads its contents into hash %args.
# Otherwise, fill the hash with arbitrary defaults.
#
sub set_defaults
{
  if ( -e "$home/.defragrc" ) 
  {
    # We've been here before -- set up per .defragrc
    open RC, "<$home/.defragrc"    or die "Can't open $home/.defragrc:  $!\n";
    while ( <RC> ) 
    {
      chomp;                       # no newline
      s/#.*//;                     # no comments
      s/^\s+//;                    # no leading white space
      s/\s+$//;                    # no trailing white space
      next unless length;          # anything left? (or was blank)
      my ( $key, $value ) = split( /\s*=\s*/, $_, 2 );
      $args{ $key } = $value;
    }
    close RC                       or die "Can't close $home/.defragrc:  $!\n";

    # Just in case they farkled the .defragrc file
    $args{ expdir } = '.'       unless $args{ expdir };
    $args{ sqldir } = '.'       unless $args{ sqldir };
    $args{ logdir } = '.'       unless $args{ logdir };
    $args{ prefix } = 'defrag_' unless $args{ prefix };
  }
  else 
  {
    # First time for this user
    $args{ expdir } = $ENV{ DBA_EXP }    || ".";
    $args{ sqldir } = $ENV{ DBA_SQL }    || ".";
    $args{ logdir } = $ENV{ DBA_LOG }    || $ENV{ LOGDIR } || ".";
    $args{ prefix } = "defrag_";
  }
  Getopt::Long::Configure( 'passthrough' );
}

# sub trunc
#
# Formats a TRUNCATE statement for the supplied [sub]partition
#
sub trunc
{
  my ( $owner, $table, $partition, $type ) = @_;

  return  "PROMPT " .
          "ALTER TABLE \L$owner.$table \UTRUNCATE $type \L$partition  \n\n" .
          "ALTER TABLE \L$owner.$table \UTRUNCATE $type \L$partition ;\n\n";
}

# sub unique_nbr
#
# Generates a unique 6-digit number for use in Temp Table names
#
sub unique_nbr
{
  my $nbr;

  while( 1 )
  {
    $nbr = int( rand 900000 ) + 100000;
    $uniq{ $nbr }++;
    last unless $uniq{ $nbr } > 1;
  }

  return $nbr
}

# sub validate_log_names
#
# Ensures that log files are writeable.  These files are not actually
# OPENed during the program, so this check is not foolproof, but it
# might save a little time just in case the filename is unwriteable.
#
sub validate_log_names
{
  my ( $aref ) = @_;

  foreach my $file ( @$aref )
  {
    die "\n***Error:  Log file $file\n",
        "           is not writeable\n",
        "\n$0 aborted,\n\n"
      unless (
                  -e $file and -w $file
               or not -e $file
             );
  }
}

# sub write_file
#
# Opens, writes, closes a .sql or .par file
#
sub write_file
{
  my ( $filename, $text, $remark ) = @_;

  open FILE, ">$filename"     or die "Can't open $filename: $!\n";
  write_header( \*FILE, $filename, $remark );
  print FILE $text,
             "$remark --- END OF FILE ---\n\n";
  close FILE                  or die "Can't close $filename: $!\n";
}

# sub write_header
#
# Creates a 7-line header in the supplied file, marked as comments.
#
sub write_header
{
  my ( $fh, $filename, $remark ) = @_;

  print $fh "$remark $filename\n",
            "$remark \n",
            "$remark Created by $0\n",
            "$remark on ", scalar localtime,"\n\n\n\n";
}

# $Log: defrag.pl,v $
# Revision 1.18  2001/04/28 13:51:28  rvsutherland
# Fixed to work on Windows [I think].
#
# Revision 1.17  2001/01/27 16:23:25  rvsutherland
# Upgraded to handle tablespaces having no tables (only indexes).
#
# Revision 1.16  2001/01/14 16:47:55  rvsutherland
# Nominal changes for version 0.32
#
# Revision 1.15  2001/01/07 16:44:54  rvsutherland
# Changed 'WITHOUT' to 'without' in success message of scripts
#
# Revision 1.14  2001/01/01 22:43:21  rvsutherland
# Altered shell scripts to be completely self checking.
# Added driver shell script to call all other scripts, so that defragging
#    could take place in background while DBA eats pizza.
#
# Revision 1.13  2001/01/01 12:59:52  rvsutherland
# Fixed bug in export parfile.
#
# Revision 1.12  2000/12/31 12:51:59  rvsutherland
# Added ANALYZE TABLE/INDEX following Import, for previously analyzed objects
#
# Revision 1.11  2000/12/31 00:46:58  rvsutherland
# Before starting, verified that Log files were writiable.
# Modified queries in anticipation of adding ANALYZE TABLE statements
#
# Revision 1.10  2000/12/28 21:45:25  rvsutherland
# Upgraded to handle table names containing '$'.
# Corrected Statement Group 15 to MOVE the partitions back to THE TABLESPACE.
# Put all Log files in logdir (were going to sqldir -- go figure)
# Corrected NEXT size if object reached last tier (was null)
#
# Revision 1.9  2000/12/09 17:38:56  rvsutherland
# Additional tuning refinements.
# Minor cleanup of code.
#
# Revision 1.8  2000/12/06 00:43:45  rvsutherland
# Significant performance improvements.
# No, make that MAJOR gains (i.e., orders of magnitude for large databases).
# To wit:
#   Replaced convoluted Dictionary views with 8i Temporary Tables
#   Widely (but not entirely) switched to bind variables (was interpolated,
#     causing reparsing in most cases).
# Also fixed error on REBUILD of Global and non-partitioned indexes.
#
# Revision 1.7  2000/12/02 14:06:20  rvsutherland
# Completed 'exchange' method for handling partitions,
# including REBUILD of UNUSABLE indexes.
# Removed 'resize' method for handling partitions.
#
# Revision 1.6  2000/11/26 20:10:54  rvsutherland
# Added 'exchange' method for handling partitions.  Will probably
# remove the 'resize' method next update.
#
# Revision 1.5  2000/11/24 18:36:00  rvsutherland
# Restructured file writes
# Revamped 'resize' method for handling partitions
#
# Revision 1.4  2000/11/19 20:08:58  rvsutherland
# Added 'resize' partitions option.
# Restructured file creation.
# Added shell scripts to simplify executing generated files.
# Modified selection of IOT tables (now handled same as indexes)
# Added validation of input arguments -- meaning we now check for
# hanging chad and pregnant votes  ;-)
#
# Revision 1.3  2000/11/17 21:35:53  rvsutherland
# Commented out Direct Path export -- Import has a bug (at least on Linux)
#
# Revision 1.2  2000/11/16 09:14:38  rvsutherland
# Major restructure to take advantage of DDL::Oracle.pm
#

__END__

########################################################################

=head1 NAME

defrag.pl -- Creates SQL*Plus command files to defragment a tablespace.

=head1 SYNOPSIS

[ ? | -? | -h | --help ]

--tablespace=TABLESPACE 

[--alttablespace=TABLESPACE]

[--expdir=PATH]

[--logdir=PATH]

[--resize=STRING]

[--sqldir=PATH]

[--user=USERNAME]

[--password=PASSWORD]

[--prefix=PREFIX]

[--sid=SID]

[--resize=STRING]

Note:  descriptions of each of these arguments are provided via 'help',
which may be displayed by entering 'defrag.pl' without any arguments.

=head1 DESCRIPTION

Creates command files to defragment (reorganize) an entire Oracle
Tablespace.  Arguments are specified on the command line.

A "defrag" is usually performed to recapture the little fragments of
unused (and unusable) space that tend to accumulate in Oracle
tablespaces when objects are repeatedly created and dropped.. To fix
this, data is first exported.  Objects are then dropped and the
tablespace is "coalesced" into one large extent of available space.  The
objects are then recreated using either the default sizing algorithm or a
user supplied algorithm, and the data is imported.  Space utilized is then
contiguous, and the unused free space has been captured for use.

The steps in the process are:

    1.  Export all objects in the tablespace (tables, indexes, partitions).
    2.  Drop all objects.
    3.  Coalesce the tablespace.
    4.  Create all tables and partitions, resized appropriately.
    5.  Import the data into the new structures.
    6.  Recreate the indexes.
    7.  Restore all constraints.

=head1 TO DO

=head1 BUGS

=head1 FILES

The names and number of files output varies according to the Tablespace
specified and the options selected.  All .sql and .log files and shell
scripts produced are displayed on STDOUT during the execution of the program.

Also, see 'README.defrag', which will be created when Help is displayed (by
entering 'defrag.pl' without any arguments).

=head1 AUTHOR

 Richard V. Sutherland
 rvsutherland@yahoo.com

=head1 COPYRIGHT

Copyright (c) 2000, 2001 Richard V. Sutherland.  All rights reserved.
This script is free software.  It may be used, redistributed, and/or
modified under the same terms as Perl itself.  See:

    http://www.perl.com/perl/misc/Artistic.html

=cut

