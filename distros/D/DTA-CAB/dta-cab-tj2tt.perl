#!/usr/bin/perl -w

use lib '.';
use JSON::XS;
use DTA::CAB::Format::TT;
use DTA::CAB::Format::TJ;

our $tt = DTA::CAB::Format::TT->new;
our $tj = DTA::CAB::Format::TJ->new;
$tt->toFh(\*STDOUT);
our $sbuf='';

sub tj2tt {
  $tj->parseTJString(\$sbuf);
  $tt->putDocumentRaw($tj->{doc});
  $sbuf = '';
}

##-- MAIN
while (defined($_=<>)) {
  $sbuf .= $_;
  tj2tt() if (/^$/);
}
tj2tt() if ($sbuf);
$tt->flush;
