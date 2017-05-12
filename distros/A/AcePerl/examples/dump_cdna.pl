#!/usr/bin/perl

# this script dumps the spliced form of all predicted genes

use Ace::Sequence;

my $host = shift || 'www.wormbase.org';
my $port = shift || 200005;

$db = Ace->connect(-host=>'www.wormbase.org',-port=>200005);
warn "fetching all genes....\n";
@genes = $db->fetch(Predicted_gene=>'*');
foreach (@genes) {
  warn "Fetching dna for $_\n";
  my $data = $_->asDNA;
  $data =~ s/$/ (spliced)/m;
  print $data;

  my $seq       = Ace::Sequence->new($_);
  my $unspliced = $seq->dna;
  $unspliced =~ s/(\w{50})/$1\n/g;
  print ">$_ (unspliced)\n$unspliced\n";
}
