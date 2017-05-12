#!/usr/bin/perl

use lib '/users/staff/leithdo/perl5/lib/perl5/';
use Bib::Tools;
use CGI;
use CGI::Carp qw(warningsToBrowser fatalsToBrowser); 

# send html header
print "Content-Type: text/html;\n\n";

my $q = CGI->new;
my $refs = Bib::Tools->new;
my $orcid = scalar $q->param('orcid');
$orcid =~ /([0-9\-]+)$/; # extract id out of url
$orcid = $1;
if (length($orcid) > 5) {
  $refs->add_orcid($1);
} 

my $google = scalar $q->param('google'); #NB: CGI has already carried out URL decoding
if (length($google) > 15) {
  if (!($google =~ m/^http/)) { $google = "http://".$google;}
  if ($google =~ m/https?:\/\/scholar.google.com/) {
    $refs->add_google($google);
  } else {
    print "<p style='color:red'>google url looks invalid: ", $google,"</p>";
  }
}
my $google2 = scalar $q->param('google2'); #NB: CGI has already carried out URL decoding
if (length($google2) > 15) {
  if (!($google2 =~ m/^http/)) { $google2 = "http://".$google2;}
  if ($google2 =~ m/https?:\/\/scholar.google.com/) {
    $refs->add_google_search($google2);
  } else {
    print "<p style='color:red'>google url looks invalid: ", $google2,"</p>";
  }
}
my $dblp = scalar $q->param('dblp');
if (length($dblp) > 5) {
  if (!($dblp =~ m/^http/)) { $dblp = "http://".$dblp;}
  $refs->add_dblp($dblp);
}
my $pubmed = scalar $q->param('pubmed');
if (length($pubmed) > 5) {
  $refs->add_pubmed($pubmed);
}

$filename = scalar $q->param('bibtex');
$tmpfilename = $q->tmpFileName($filename);
open my $fh, "<", $tmpfilename;
$refs->add_bibtex($fh);

my @values = $q->multi_param('refs');
foreach my $value (@values) {
  #NB: CGI has already carried out URL decoding
  open my $fh, "<", \$value;
  $refs->add_fromfile($fh);
}      
$refs->sethtml;
print $refs->send_resp;
