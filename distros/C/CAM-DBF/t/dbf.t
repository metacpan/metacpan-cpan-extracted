#!perl

use warnings;
use strict;
use Time::HiRes qw(gettimeofday tv_interval);
use File::Temp qw(tempfile);
use Test::More tests => 14;

BEGIN
{
   use_ok('CAM::DBF');
}

my ($start,$stop); # used for time testing

# Make a temp file in the same directory as this testfile
my ($fh, $tmpfile) = tempfile();
close $fh;

END
{
   unlink $tmpfile;
}

my @columns = (
               {name=>'id',
                type=>'N', length=>8,  decimals=>0},
               {name=>'lastedit',
                type=>'D', length=>8,  decimals=>0},
               {name=>'firstname',
                type=>'C', length=>15, decimals=>0},
               {name=>'lastname',
                type=>'C', length=>20, decimals=>0},
               {name=>'height_cm',
                type=>'N', length=>6, decimals=>2},
               {name=>'active',
                type=>'L', length=>1, decimals=>0},
               );

my $MULT = 10000;
my $NUM = 3777;

diag("Performance measurements are CPU time for $NUM rows written and");
diag(($NUM*2)." rows read, extrapolated to time for $MULT rows for readability");

{
   # Enclose in a block so $dbf goes away
   my $dbf = CAM::DBF->create($tmpfile, @columns);
   ok($dbf, 'Create new dbf table');

   $start = [gettimeofday];
   foreach my $i (0..$NUM-1)
   {
      $dbf->appendrow_arrayref([$i,'03/02/03','Clotho','Adv Media', 200, 'Y']);
   }
   $stop = [gettimeofday];
   ok(1,'Performance of appendrow_arrayref: ' . $MULT * tv_interval($start,$stop) / $NUM . " secs/$MULT records");
   is($dbf->nrecords(), $NUM, 'Count appended records');

   $start = [gettimeofday];
   foreach my $i (0..$NUM-1)
   {
      $dbf->appendrow_hashref({id => $i+$NUM,
                               lastedit => '03/02/03',
                               firstname => 'Clotho',
                               lastname => 'Adv Media',
                               height_cm => 200,
                               active => 'Y'});
   }
   $stop = [gettimeofday];
   ok(1,'Performance of appendrow_hashref: ' . $MULT * tv_interval($start,$stop) / $NUM . " secs/$MULT records");

   is($dbf->nrecords(), $NUM*2, 'Count appended records');

   ok ($dbf->closeDB(), 'Close database after writing');
}

{
   my $dbf = CAM::DBF->new($tmpfile);
   ok($dbf, 'Reopen dbf table');

   is($dbf->nrecords(), $NUM*2, 'Count records');

   is_deeply($dbf->{fields}, \@columns, 'Test column data structure');

   my $errors = 0;
   $start = [gettimeofday];
   for my $iRow (0 .. $dbf->nrecords()-1)
   {
      my $ref = $dbf->fetchrow_arrayref($iRow);
      $errors++ if ((!$ref) || $ref->[0] != $iRow);
   }
   $stop = [gettimeofday];
   ok(1,'Performance of fetchrow_arrayref: ' . $MULT * tv_interval($start,$stop) / $dbf->nrecords() . " secs/$MULT records");

   is ($errors, 0, 'Test IDs for incoming rows');

   $errors = 0;
   $start = [gettimeofday];
   for my $iRow (0 .. $dbf->nrecords()-1)
   {
      my $ref = $dbf->fetchrow_hashref($iRow);
      $errors++ if ((!$ref) || $ref->{id} != $iRow);
   }
   $stop = [gettimeofday];
   ok(1,'Performance of fetchrow_hashref: ' . $MULT * tv_interval($start,$stop) / $dbf->nrecords() . " secs/$MULT records");

   is($errors, 0, 'Test IDs for incoming rows');
}
