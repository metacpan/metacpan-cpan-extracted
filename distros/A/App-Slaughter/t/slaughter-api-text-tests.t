#!/usr/bin/perl -w -I../lib -I./lib/
#
#  Some simple tests that validate the Slaughter code is correct.
#
#  Here we use the following API methods:
#
#    AppendIfMissing      +
#    CommentLinesMatching +
#    FileMatches          +
#    ReplaceRegexp
#
# Steve
# --
#


use strict;
use Test::More qw! no_plan !;
use File::Temp qw/ tempfile /;

#
#  Load the Slaughter module
#
BEGIN {use_ok('Slaughter');}
require_ok('Slaughter');


#
#  Create a temporary file.
#
my ( $fh, $filename ) = tempfile();

ok( -e $filename, "We created a temporary file" );
is( -s $filename, 0, "The file is empty" );


#
#  Write out known-contents to the file
#
open( my $handle, ">", $filename ) or
  die "Failed to write to temporary file: $!";
print $handle <<EOF;
Steve
Kemp
1234567890
ABCDEFGHI
EOF
close($handle);

#
#  File contents are known, so size is known
#
is( -s $filename, 32, "The file has our test data present" );

#
#  Does the file-matching succeed?
#
is( FileMatches( File => $filename, Pattern => '^[0-9]*$' ),
    1, "File matches a simple regular expression" );
is( FileMatches( File => $filename, Line => '1234567890' ),
    1, "File matches literally." );

#
#  And the file should now contain a comment.
#
is( FileMatches( File => $filename, Pattern => '^#' ),
    0, "File does not contain a comment." );

#
#  Now we'll comment lines containing numeric code.
#
CommentLinesMatching( File => $filename, Pattern => '^[0-9]*$' );

#
#  Which means the filesize is one more than it was.
#
is( -s $filename, 33, "The file has grown, as expected" );

#
#  And the file no longer should match our simple pattern?
#
is( FileMatches( File => $filename, Pattern => '^[0-9]*$' ),
    0, "File no longer matches our simple regular expression" );
is( FileMatches( File => $filename, Line => '1234567890' ),
    0, "File no longer matches literally." );

#
#  And the file should now contain a comment.
#
is( FileMatches( File => $filename, Pattern => '^#' ),
    1, "File contains a comment." );
is( FileMatches( File => $filename, Line => '#1234567890' ),
    1, "File match, with comment, succeeds." );

#
#  Append a new line
#
AppendIfMissing( File => $filename, Line => "Testing is fun!" );

#
#  The file size should have grown.
#
is( -s $filename, 49, "The file has grown, as expected" );

#
#  Repeating a few times should result in no change though,
# as the line is present.
#
for ( my $i = 0 ; $i < 5 ; $i++ )
{
    AppendIfMissing( File => $filename, Line => "Testing is fun!" );
    is( -s $filename, 49, "Appending a new line is not required" );
}


#
#  OK now we have a file which contains:
#
# --
# Steve
# Kemp
# #1234567890
# ABCDEFGHI
# Testing is fun!
#--
#
#  Replace lines matching "Steve" with "Bob".
#
is( FileMatches( File => $filename, Pattern => '^Bob' ),
    0, "Prior to replacement there is no 'Bob' in the file." );

ReplaceRegexp( File => $filename, Pattern => "Steve", Replace => "Bob" );

is( FileMatches( File => $filename, Pattern => '^Bob' ),
    1, "After replacement there is 'Bob' in the file." );
is( FileMatches( File => $filename, Pattern => '^Bob$' ),
    1, "After replacement there is 'Bob' in the file." );


#
#  Replace " is " with " isn't ".
#
is( FileMatches( File => $filename, Pattern => " isn't " ),
    0, "Prior to replacement there is no 'isn't' in the file." );

ReplaceRegexp( File => $filename, Pattern => " is ", Replace => " isn't " );

is( FileMatches( File => $filename, Pattern => " isn't " ),
    1, "After replacement there is 'isn't' in the file." );

#
#  Now do a replacement with lower-casing - to test the /eval modifier.
#
is( FileMatches( File => $filename, Pattern => "^[A-Z]+\$" ),
    1,
    "Before down-casing there is a line consisting solely of upper-case letters"
  );
is( FileMatches( File => $filename, Pattern => "^[a-z]+\$" ),
    0,
    "Before down-casing there is no line consisting solely of lower-case letters"
  );

ReplaceRegexp( File    => $filename,
               Pattern => "^([A-Z]+)\$",
               Replace => "lc(\$1)"
             );

is( FileMatches( File => $filename, Pattern => "^[A-Z]+\$" ),
    0,
    "After down-casing there is no line consisting solely of upper-case letters"
  );
is( FileMatches( File => $filename, Pattern => "^[a-z]+\$" ),
    1,
    "After down-casing there is a line consisting solely of lower-case letters"
  );


#
#  Cleanup
#
unlink($filename);
ok( !-e $filename, "Post-testing our temporary file is gone" );
