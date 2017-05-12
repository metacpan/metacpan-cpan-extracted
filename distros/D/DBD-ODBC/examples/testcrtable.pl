#!/usr/bin/perl -w -I./t
# $Id$


use strict;
use DBI qw(:sql_types);

my (@row);

my $dbh = DBI->connect()
	  or exit(0);
# ------------------------------------------------------------


my %TypeTests = (
		 'SQL_ALL_TYPES' => 0,
		 'SQL_VARCHAR' => SQL_VARCHAR,
		 'SQL_CHAR' => SQL_CHAR,
		 'SQL_INTEGER' => SQL_INTEGER,
		 'SQL_SMALLINT' => SQL_SMALLINT,
		 'SQL_NUMERIC' => SQL_NUMERIC,
		 'SQL_LONGVARCHAR' => SQL_LONGVARCHAR,
		 'SQL_LONGVARBINARY' => SQL_LONGVARBINARY,
		);

my $ret;
print "\nInformation for DBI_DSN=$ENV{'DBI_DSN'}\n\t", $dbh->get_info(17), "\n";
my $SQLInfo;

print "Listing all types\n";
my $sql = "create table PERL_TEST (\n";
my $icolno = 0;
use constant {
    gti_name => 0,
    gti_type => 1,
    gti_column_size => 2,
    gti_prefix => 3,
    gti_suffix => 4,
    gti_create_params => 5,
    gti_nullable => 6
};

my $sth = $dbh->func(0, 'GetTypeInfo');
if ($sth) {
   my $colcount = $sth->func(1, 0, 'ColAttributes'); # 1 for col (unused) 0 for SQL_COLUMN_COUNT
   # print "Column count is $colcount\n";
   my $i;
   my @coldescs = ();
   # column 0 should be an error/blank
   for ($i = 0; $i <= $colcount; $i++) {
      my $stype = $sth->func($i, 2, 'ColAttributes');
      my $sname = $sth->func($i, 1, 'ColAttributes');
      push(@coldescs, $sname);
   }

   my @cols = ();
   my $seen_identity;
   while (@row = $sth->fetchrow()) {
       print "$row[gti_name]| ",
           nullif($row[gti_type]), "| ",
               nullif($row[gti_column_size]), "| ",
                   nullif($row[gti_prefix]), "| ",
                       nullif($row[gti_suffix]), "| ",
                           nullif($row[gti_create_params]), "| ",
                               nullif($row[gti_nullable]), "| ",
                                   "\n";
       if ($row[gti_name] =~ /identity/) {
           next if $seen_identity; # you cannot have multiple identity columns
           $seen_identity = 1;
       }
       if (!($row[gti_name] =~ /auto/)) {
           my $tmp = " COL_$icolno $row[gti_name]";

           if (defined($row[gti_create_params]) &&
                   ($row[gti_create_params] =~ /length/ or
                        $row[gti_create_params] =~ /precision/)) {
               if ($row[gti_name] =~ /\(\)/) {
                   $tmp =~ s/\(\)/($row[gti_column_size])/;
               } else {
                   $tmp .= "(10)"; #"($row[gti_column_size])"
               }
           }
           push(@cols, $tmp);
       }
       $icolno++;
   }
   $sql .= join("\n , ", @cols) . ")\n";
   $sth->finish;
}
print $sql;
eval {
	$dbh->do("drop table PERL_TEST");
};

$dbh->do($sql);

my @tables = $dbh->tables;

my @mtable = grep(/PERL_TEST/, @tables);
my ($catalog, $schema, $table) = split(/\./, $mtable[0]);
$catalog =~ s/"//g;
$schema =~ s/"//g;
$table =~ s/"//g;
#$table="PERL_DBD_TEST";
print "Getting column info for: $catalog, $schema, $table\n";
my $sth = $dbh->column_info(undef, undef, $table, undef);
my @row;

print join(', ', @{$sth->{NAME}}), "\n";
while (@row = $sth->fetchrow_array) {

   # join prints nasty warning messages with -w. There's gotta be a better way...
   foreach (@row) { $_ = "" if (!defined); }

   print join(", ", @row), "\n";
}

$dbh->disconnect();

sub nullif {
   my $val = shift;
   $val ? $val : "(null)";
}
