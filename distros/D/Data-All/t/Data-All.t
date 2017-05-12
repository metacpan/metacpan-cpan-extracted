
#	A simple, file-based test for Data::All
#       may-6-2004, delano mandelbaum

#########################

use Test::More;
BEGIN { plan tests => 4 };
use Data::All;
ok(1, "Module loaded"); 

#########################

use FindBin;

my %infile = (
	path	=> $FindBin::Bin . '/sample.csv',
	profile => 'csv',
	ioconf  => ['file', 'r']
);

my %outfile = (
        path    => $FindBin::Bin . '/sample.fixed',
        format	=> ['fixed', "\n", [16,4,32,32]],
        ioconf  => ['file', 'w']
);

my $da = Data::All->new(source =>\%infile, target=> \%outfile);

$da->open();

my $rec = $da->read();

ok($#{ $rec } == 2, "Check record count");
ok(exists($rec->[0]->{'name'}), "Check field names");

$da->close();

$da->convert(source =>\%infile, target=> \%outfile);

ok(1, "Lookin' good")
