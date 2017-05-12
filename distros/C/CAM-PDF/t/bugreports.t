#!/usr/bin/perl -w

use warnings;
use strict;
use Carp;

$SIG{__WARN__} = $SIG{__DIE__} = \&Carp::confess;

use Test::More tests => 1;
use CAM::PDF;

{
   # From an email exchange with Malcolm Cook:
   #   exiftool is appending a comment after the "%%EOF" at the end of
   #   the document, which is confusing CAM::PDF.  Technically that's
   #   not allowed (the PDF spec says "The last line of the file
   #   contains only the end-of-file marker, %%EOF.") but the spec
   #   also has an implementation note in the appendix that says
   #   "Acrobat viewers require only that the %%EOF marker appear
   #   somewhere within the last 1024 bytes of the file."

   my $orig_pdf = CAM::PDF->new('t/sample1.pdf') || die $CAM::PDF::errstr;
   my $new_pdf_content = $orig_pdf->{content} . "\n%EndExifToolUpdate 621754\n";
   ok(CAM::PDF->new($new_pdf_content), 'can read a PDF with extra comments at the end');
}
