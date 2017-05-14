#!/usr/bin/perl -w

use strict;
use Test::More tests => 2;

use Business::ReportWriter::Pdf;

  my $s = new Business::ReportWriter::Pdf();
  ok(defined $s);
  ok($s->isa('Business::ReportWriter::Pdf'));
#!/usr/bin/perl -w
