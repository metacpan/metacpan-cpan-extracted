
###
# Cz::Cstocs.pm

BEGIN { $^W = 0; $| = 1;
	eval 'use XBase;';
	if ($@) {
		print "1..0\n";
		exit;
		}
	print "1..4\n";
	}

###

print "Calling the external dbfcstocs program\n";

use ExtUtils::testlib;
my $libs = join " -I", '', @INC;
my $TSTDBF = 'test.dbf';
$TSTDBF = 't/' . $TSTDBF if -d 't';
my $OUTDBF = 'out-test.dbf';
$OUTDBF = 't/' . $OUTDBF if -d 't';

print "$TSTDBF and $OUTDBF.\n";

unlink $OUTDBF;

system("$^X $libs blib/script/dbfcstocs --field-names-charset=ascii il2 ascii $TSTDBF $OUTDBF");

if (not -f $OUTDBF) {
	print "not ok 1\n";
	exit;
	}
print "ok 1\n";

print "Loading the output dbf.\n";
my $table = new XBase $OUTDBF;
unless (defined $table) {
	print "Error loading the output file: $XBase::errstr\nnot ok 2\n";
	exit;
	}
print "ok 2\n";

print "Checking field names.\n";
my @fields = $table->field_names;
if ("@fields" ne "ID JMENO BYDLISTE D_NAROZENI ODMENA VYSKA") {
	print "Field names (@fields) were not converted correctly.\nnot ";
	}
print "ok 3\n";

print "Checking data.\n";
my @data = $table->get_record(0);
if ("@data" ne "0 1 Malicky Jezecek Pareziste 123 19980416 1700 0.17") {
	print "Data (@data) was not converted correctly.\nnot ";
	}
print "ok 4\n";

unlink $OUTDBF;
