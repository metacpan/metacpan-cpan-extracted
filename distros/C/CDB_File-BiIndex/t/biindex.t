#!/usr/bin/perl -w
=head1 Basic Checks

These just test that the BiIndex does in fact store two way relations.

=cut


$loaded = 0;
$loaded_gen = 0;

BEGIN { print "1..6\n"} ;
END { print "not ok 1\n" unless $loaded;  
      print "not ok 2\n" unless $loaded_gen; } ;


sub ok { print "ok ", shift, "\n" }
sub nok { print "not ok ", shift, "\n" }

use CDB_File::BiIndex::Generator;
$loaded = 1;
ok(1);
use CDB_File::BiIndex 0.026;
$loaded_gen = 1;
ok(2);

$gindex = new CDB_File::BiIndex::Generator "test";

#check that if we add a relation then it exists.

$gindex->add_relation("James", "Jean");
$gindex->add_relation("James", "Joan");
$gindex->add_relation("Roger", "Kenny");
$gindex->add_relation("Kenny", "Jean");

$gindex->finish(); 

#should actually probably do a DESTROY for proper testing, but
#sometimes this might fail :-)

$index = new CDB_File::BiIndex "test";

$::jamesrel=$index->lookup_first("James");

if ($::jamesrel->[0] eq "Jean" &&
	$::jamesrel->[1] eq "Joan") { ok(3) } else { nok(3) }

#check that the reverse relation exists

$::jeanrel=$index->lookup_second("Jean");

if ($::jeanrel->[0] eq "James" &&
	$::jeanrel->[1] eq "Kenny") { ok(4) } else { nok(4) }

#check no wrong way round relations

#  unless( defined $index->lookup_first("Jean") )
#  	 { ok(5) } else { nok(5) }

#  unless( defined $index->lookup_second("James") )
#  	 { ok(6) } else { nok(6) }

$::badjean=$index->lookup_first("Jean");
unless( $::badjean ) { ok(5) } else { nok(5) }

$::badjames= $index->lookup_second("James");
unless( $::badjames ) { ok(6) } else { nok(6) }

#FIXME - test iteration
