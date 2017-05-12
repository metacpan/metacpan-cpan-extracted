#!perl -w

##  Note that this example only works as described if the "-w" switch
##  is set!

# ======================================================================
#   $toplocation = Data::Locations->new();
#   $sublocation = $location->new();
#   $location->filename($filename);
#   $location->print(@items);
#   $location->print($sublocation);
#   @list = $location->read();
# ======================================================================

package Non::Sense;

##  (This is to demonstrate that this example works with ANY package)

use Data::Locations;
use FileHandle;

use strict;
no strict "vars";

print "1..2\n";

$n = 1;

$self = $0;
$self =~ s!^.*[^0-9a-zA-Z_\.]!!;

$temp =
    $ENV{'TMP'} || $ENV{'TEMP'} || $ENV{'TMPDIR'} || $ENV{'TEMPDIR'} || '/tmp';
$temp =~ s!/+$!!;

$file = "$temp/$self.$$";

##  Redirect all output sent to STDOUT:

unless (open(FILE, ">$file"))
{
    die "$self: can't write '$file': \L$!\E\n";
}

##  Create scope for redirected STDOUT:

{
    local(*STDOUT) = *FILE;

    ##  Create the topmost location:

    $level0 = Data::Locations->new("level0.txt");

    print $level0 <<'VERBATIM';
Printing first line to location 'level0' via OPERATOR 'print'.
VERBATIM

    ##  Create an embedded location (nested 1 level deep):

    $level1 = $level0->new();

    $level0->print(<<'VERBATIM');
Printing last line to location 'level0' via METHOD 'print'.
VERBATIM

    ##  Now "tie" the embedded location to file handle STDOUT:

    $level1->tie('STDOUT');

    print "Printing to location 'level1' via STDOUT.\n";

    ##  Create another location (which will be embedded later):

    $level2 = Data::Locations->new();

    ##  Create a file handle ("IO::Handle" works equally well):

    $fh = FileHandle->new();

    ##  Now "tie" the location "$level2" to this file handle "$fh":

    $level2->tie($fh);

    ##  And select "$fh" as the default output file handle:

    select($fh);

    print "Printing to location 'level2' via default file handle '\$fh'.\n";

    ##  Embed location "$level2" in location "$level1":

    print $level1 $level2;

    ##  (Automatically removes "toplevel" status from location "$level2")

    print STDOUT "Printing to location 'level1' explicitly via STDOUT.\n";

    ##  Create a third embedded location (nested 3 levels deep):

    $level3 = $level2->new();

    ##  Restore STDOUT as the default output file handle:

    select(STDOUT);

    print $fh "Printing to location 'level2' via file handle '\$fh'.\n";

    ##  Trap all warnings:

    $SIG{__WARN__} = sub
    {
        print STDERR "WARNING intercepted:\n", @_, "End Of Warning.\n";
    };

    ##  Note that WITHOUT this trap, warnings would go to the system
    ##  standard error device DIRECTLY, WITHOUT passing through the
    ##  file handle STDERR!

    ##  Now "tie" location "$level3" to file handle STDERR:

    $level3->tie(*STDERR);

    ##  Provoke a warning message (don't forget the "-w" switch!):

    $fake = \$fh;
    $level3->print($fake);

    ##  Provoke another warning message (don't forget the "-w" switch!):

    $level3->dump();

    {
        ##  Silence warning that reference count of location is still > 0:

        local($^W) = 0;

        ##  And untie file handle STDOUT from location "$level1":

        untie *STDOUT;
    }

    print "Now STDOUT goes to the screen again.\n";

    ##  Read from location "$level3":

    while (<STDERR>)  ##  Copy warning messages to the screen:
    {
        if (/^.*?\bData::Locations::[a-z]+\(\):\s+(.+?)(?=\s+at\s|\n)/)
        {
            print "Warning: $1\n";
        }
    }

    while (<STDERR>) { print; }

    ##  (Prints nothing because location was already read past its end)

    ##  Reset the internal reading mark:

    (tied *{STDERR})->reset();

    ##  (You should usually use "$level3->reset();", though!)

    while (<STDERR>) { print; }

    ##  (Copies the contents of location "$level3" to the screen)
}

##  (End of scope for redirected STDOUT)

close(FILE);

##  Read output file "level0.txt":

$txt = join('', $level0->read());
$ref = <<'VERBATIM';
Printing first line to location 'level0' via OPERATOR 'print'\..*
Printing to location 'level1' via STDOUT\..*
Printing to location 'level2' via default file handle '\$fh'\..*
WARNING intercepted:.*
Data::Locations::print\(\): REF reference ignored.*
End Of Warning\..*
WARNING intercepted:.*
Data::Locations::dump\(\): filename missing or empty.*
End Of Warning\..*
Printing to location 'level2' via file handle '\$fh'\..*
Printing to location 'level1' explicitly via STDOUT\..*
Printing last line to location 'level0' via METHOD 'print'\.
VERBATIM

$ref =~ s!\n!!g;
if ($txt =~ /$ref/s)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

unless (open(FILE, "<$file"))
{
    die "$self: can't read '$file': \L$!\E\n";
}
$txt = join('', <FILE>);
close(FILE);
unlink($file);

$ref = <<'VERBATIM';
Now STDOUT goes to the screen again\..*
Warning: REF reference ignored.*
Warning: filename missing or empty.*
WARNING intercepted:.*
Data::Locations::print\(\): REF reference ignored.*
End Of Warning\..*
WARNING intercepted:.*
Data::Locations::dump\(\): filename missing or empty.*
End Of Warning\.
VERBATIM

$ref =~ s!\n!!g;
if ($txt =~ /$ref/s)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

#$txt = <<'VERBATIM';
#Now STDOUT goes to the screen again.
#Warning: REF reference ignored
#Warning: filename missing or empty
#WARNING intercepted:
## Data::Locations::print(): REF reference ignored
#File 'Bird:src:Pudge:pudgeprogs:perl:cpan:build:Data-Locations-4.3:t:18__example_3.t'; Line 125
#End Of Warning.
#WARNING intercepted:
## Data::Locations::dump(): filename missing or empty
#File 'Bird:src:Pudge:pudgeprogs:perl:cpan:build:Data-Locations-4.3:t:18__example_3.t'; Line 129
#End Of Warning.
#VERBATIM
#
#if ($txt =~ /$ref/s)
#{print "ok $n\n";} else {print "not ok $n\n";}
#$n++;

$level0->filename("");

__END__

