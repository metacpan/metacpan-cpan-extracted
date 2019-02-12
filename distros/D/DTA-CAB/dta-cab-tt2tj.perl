#!/usr/bin/perl -w

use lib '.';
use JSON::XS;
use DTA::CAB::Format::TT;
use DTA::CAB::Format::TJ;
use Getopt::Long ':config'=>'no_ignore_case';

our ($help);
our $tjlevel = 0;
GetOptions('help|h' => \$help,
	   'text|t!' => sub {$tjlevel=$_[1] ? 0 : -1;},
	   'T|z' => sub {$tjlevel=!$_[1] ? 0 : -1;},
	   'tjlevel|level|ol|l=i' => \$tjlevel,
	  );

if ($help) {
  print STDERR
    ("Usage: $0 [OPTIONS] [TT_FILE(s)] > TJ_FILE\n",
     " Options:\n",
     "   -text  ,  -notext    ##-- do/don't include json 'text' attribute (default=do)\n",
     "   -t     ,  -T         ##-- alias for -text , -notext\n",
    );
  exit 0;
}

our $tt = DTA::CAB::Format::TT->new;
our $tj = DTA::CAB::Format::TJ->new(level=>$tjlevel);
$tj->toFh(\*STDOUT);
our $sbuf='';


sub tt2tj {
  $tt->parseTTString(\$sbuf);
  $tj->putDocumentRaw($tt->{doc});
  $sbuf = '';
}

##-- MAIN
while (defined($_=<>)) {
  $sbuf .= $_;
  tt2tj() if (/^$/);
}
tt2tj() if ($sbuf);
$tj->flush;
