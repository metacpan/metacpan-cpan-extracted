#!/usr/bin/perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..12\n"; }
END {print "not ok 1\n" unless $loaded;}

use BBDB;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.




my $all = BBDB::simple("sample_data.bbdb");

print "not " unless @$all == 2;
print "ok 2\n";

print "not " unless $all->[0]->part('last') eq "last name";
print "ok 3\n";

print "not " unless @{$all->[1]->part('net')} == 2;
print "ok 4\n";

for ($i=0; $i<2; $i++) {
  my $a = $all->[$i];
  my $b = new BBDB;
  $b->decode($a->encode());
  print "not " unless $a->encode() eq $b->encode();
  printf "ok %d\n",5+$i;
}

my @exprected;
push @expected, <<END;
home: (415)-789-1159
fax: (415)-789-1156
mazatlan: 011-5269-164195
END

push @expected, <<END;
mailing: PMB 141
         524 San Anselmo Ave.
         San Anselmo, CA
         94960 USA
mazatlan: Reino de Navarra #757
          Frac. El Cid
          Mazatlan, Sinaloa
          CP-82110 Mexico
END

push @expected, <<END;
nadine.and.henry\@pobox.com
maztravel\@maztravel.com
END

push @expected, <<END;
Henry, Enrique
END

push @expected, <<END;
creation-date: 1999-09-02
timestamp: 1999-10-17
notes: Always split aces and eights
birthday: 6/15
END

chomp @expected;

print "not " unless $all->[1]->phone_as_text() eq shift @expected ;
print "ok 7\n";

print "not " unless $all->[1]->address_as_text() eq shift @expected ;
print "ok 8\n";

print "not " unless $all->[1]->net_as_text() eq shift @expected ;
print "ok 9\n";

print "not " unless $all->[1]->aka_as_text() eq shift @expected ;
print "ok 10\n";

print "not " unless $all->[1]->notes_as_text() eq shift @expected ;
print "ok 11\n";

print "not " unless $all->[1]->note_by_name('birthday') eq '6/15';
print "ok 12\n";


