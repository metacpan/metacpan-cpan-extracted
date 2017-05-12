#!/usr/bin/perl

use lib '.','./blib/lib','../blib/lib';
use Bio::Das;

my $das = Bio::Das->new(5);  # timeout of 5 sec
my @response = $das->dsn('https://euclid.well.ox.ac.uk/cgi-bin/das',
			 'http://www.wormbase.org/db/das');

foreach (@response) {
    if ($_->is_success) {
    my @results = $_->results;
    print "$_:\n\t",join ("\n\t",@results),"\n";
  } else {
    print "$_: ",$_->error,"\n";
  }
}
