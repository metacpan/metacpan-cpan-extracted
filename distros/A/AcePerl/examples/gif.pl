#!/usr/local/bin/perl

use lib '..','../blib/lib','../blib/arch';
use Ace;

use constant HOST => $ENV{ACEDB_HOST} || 'stein.cshl.org';
use constant PORT => $ENV{ACEDB_PORT} || 200005;

die <<END if -t STDOUT;
Pipe the output to a file or a GIF displaying program.
 Examples:
           gif.pl | xv -
           gif.pl > output.gif
END

$ace = Ace->connect(-host=>HOST,-port=>PORT);
$m4 = $ace->fetch('Sequence', 'AC3' );
($gif,$box) = $m4->asGif;
print $gif;
