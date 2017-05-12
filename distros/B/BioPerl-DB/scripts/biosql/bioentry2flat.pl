#!/usr/local/bin/perl

use Bio::DB::BioDB;
use Bio::Seq::RichSeq;
use Bio::SeqIO;
use Getopt::Long;

my $outfmt = 'EMBL';
my $host = undef;
my $sqlname = "bioperl_db";
my $dbuser = "root";
my $dbpass = undef;
my $dbname = '';
my $acc;
my $version;
my $stdout=0;
my $format='embl';
my $file;
my $driver = 'mysql';

&GetOptions( 'host=s' => \$host,
             'driver=s' => \$driver,
	     'dbuser=s' => \$dbuser,
	     'dbpass=s' => \$dbpass,
	     'dbname=s' => \$dbname,
	     'accession=s' => \$acc,
	     'version=s' => \$version,
	     'format:s' => \$format,
	     'outformat:s' => \$outfmt,
	     'file:s' => \$file
	     );

$biodbname = 'sprot_hum';

$dbname = shift @ARGV unless $dbname;
$acc    = shift @ARGV unless $acc;

#
# create the DBAdaptorI for our database
#
print STDERR "Connecting with $driver:$dbname:$dbuser:dbpass\n";

my $db = Bio::DB::BioDB->new(-database => "biosql",
			     -host     => $host,
			     -dbname   => $dbname,
			     -driver   => $driver,
			     -user     => $dbuser,
			     -pass     => $dbpass,
			     );


my $seqadaptor = $db->get_object_adaptor('Bio::SeqI');

my $seq = Bio::Seq::RichSeq->new( -accession_number => $acc, 
				  -version => $version,
				  -namespace => $biodbname );

$seq = $seqadaptor->find_by_unique_key($seq);

my $seqio;			

if ($file) {
    print STDERR "Going the $file way...";
    $seqio = Bio::SeqIO->new('-format' => $format,-file => ">$file");
    $seqio->write_seq($seq);
}
else {
    $out = Bio::SeqIO->newFh('-format' => $outfmt); 
    print $out $seq;
}





