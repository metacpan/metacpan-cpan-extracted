###############################################################################
package Acme::Buckaroo;
###############################################################################
#
# Acme::Buckaroo.pm
#
###############################################################################
#
# Author:  Kevin J. Rice
#          Buffalo Grove, IL
#          http://www.JustAnyone.com
#
###############################################################################
#
# NOTE: For Module Comments, see bottom of this file for POD documentation.
#
# Version Information:
#
# 1.01  Kevin J. Rice  June 11th, 2002
#       Submitted to CPAN.
# 1.02  Kevin J. Rice  June 13th, 2002
#       Fixed "bug" in POD documentation, in response to bug #741 in the
#       cpan but tracking database (see http://rt.cpan.org)
#
###############################################################################

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = ();
our $VERSION = '1.02';

###############################################################################
# IF YOU WANT TO TURN ON DEBUG MODE
# (and thus see lots of logging lines that explain how things are happening
# as they happen), set debug_mode = 1.
# If you do, you'll need either:
#   (1) Perl 5.6 (to get Data::Dumper by default), or
#   (2) to have Data::Dumper already installed.
# Data::Dumper is a very, very handy module, but it wasn't in the default Perl
# installation until (I think) Perl 5.6.  Perl 5.005 usually don't have it.
# Look on CPAN.ORG for Data::Dumper if you don't have it.
###############################################################################
my $debug_mode = 0;
print("starting script...\n") if $debug_mode;

if ($debug_mode)
{
    use Data::Dumper;
}
else
{
#    sub Dumper { return(""); }
}

my $header = "Buckaroo Banzai Across The Eigth Dimension " x 2 . "\n";

###############################################################################
# this translation array is just for fun, but also for debugging so you can see
# how characters are encoded as they are encoded.
#
# If you try a new encoding method, use this one and you'll be able to see if
# characters are encoded and decoded correctly.

my @xlate_array1 = (qw(
    000q 001q 002q 003q 004q 005q 006q 007q 008q 009q
    010q 011q 012q 013q 014q 015q 016q 017q 018q 019q
    020q 021q 022q 023q 024q 025q 026q 027q 028q 029q
    030q 031q 032q 033q 034q 035q 036q 037q 038q 039q
    040q 041q 042q 043q 044q 045q 046q 047q 048q 049q
    050q 051q 052q 053q 054q 055q 056q 057q 058q 059q
    060q 061q 062q 063q 064q 065q 066q 067q 068q 069q
    070q 071q 072q 073q 074q 075q 076q 077q 078q 079q
    080q 081q 082q 083q 084q 085q 086q 087q 088q 089q
    090q 091q 092q 093q 094q 095q 096q 097q 098q 099q
    100q 101q 102q 103q 104q 105q 106q 107q 108q 109q
    110q 111q 112q 113q 114q 115q 116q 117q 118q 119q
    120q 121q 122q 123q 124q 125q 126q 127q 128q 129q
    130q 131q 132q 133q 134q 135q 136q 137q 138q 139q
    140q 141q 142q 143q 144q 145q 146q 147q 148q 149q
    150q 151q 152q 153q 154q 155q 156q 157q 158q 159q
    160q 161q 162q 163q 164q 165q 166q 167q 168q 169q
    170q 171q 172q 173q 174q 175q 176q 177q 178q 179q
    180q 181q 182q 183q 184q 185q 186q 187q 188q 189q
    190q 191q 192q 193q 194q 195q 196q 197q 198q 199q
    200q 201q 202q 203q 204q 205q 206q 207q 208q 209q
    210q 211q 212q 213q 214q 215q 216q 217q 218q 219q
    220q 221q 222q 223q 224q 225q 226q 227q 228q 229q
    230q 231q 232q 233q 234q 235q 236q 237q 238q 239q
    240q 241q 242q 243q 244q 245q 246q 247q 248q 249q
    250q 251q 252q 253q 254q ));

my @xlate_array = (
"Aggie Guerard Rodgers", "Alan Howarth", "Alan Oliney", "Alexandra Leviloff", "Anne Thompson", "Anthony Milch",
"Arne Schulze", "Artie Duncan", "Arties Artery", "Baby Bang", "Bari Dreiband-Burman", "Beverly Bernacki",
"Bill Cobb", "Bill Henderson", "Billy Travers", "Billy Vera", "Black Lectroid", "Blue Blazer Irregulars",
"Bodifications", "Bones Howe", "Brian Ralph", "Bruce McBroom", "Bryan Denegal", "Dan Hedaya", "Dan Lupovitz",
"Dan Roth", "David Blitstein", "David E. Campbell", "David Gross", "David P. Newell", "David R. Hardberger",
"David Schwartz", "Buckaroo Banzai", "Defense Sec. McKinley", "Penny Priddy", "Dry LA aqueduct",
"Eighth dimension", "Ellen Barkin", "Future Begins Tomorrow", "Girl Named John", "Hanoi Xan",
"Hong Kong Cavaliers", "Hydraulic Watermelon", "Jeff Goldblum", "John Balook", "John Bigboote",
"John Lithgow", "John Smallberries", "John Ya Ya", "Lectoid", "Monkey Boy", "Neurosurgeon",
"NoNoNo Dont Tugonthat", "Nomatterwhereyougo thereyouare", "Nuclear Physicst", "Oscillation Overthruster",
"Perfect Tommy", "Peter Weller", "Pinky Carruthers", "Planet 10", "President Widmark", "Prof Toichi Hikita",
"Rawhide", "Red Lectroids", "Reno Nevada", "Sandra Banzai", "Scooter Lindley", "Sidney Zwibel", "Smolensk USSR",
"Thermopod", "Truncheon Bomber", "W.D. Richter", "Yakov Smirnoff", "Yoyodyne Propulsion Systems", "Carl Lumbly",
"Cash for lithium", "Casper Lindley", "Cheryl Bloch", "Chris Casady", "Chris Collins", "Christopher Keith",
"Christopher Lloyd", "Chuck Cooper", "Clancy Brown", "Colette Emanuel", "Comic Book Hero", "Crying of Lot 49",
"Damon Hines", "Dena Fischer", "Dennis E. Jones", "Dennis Schultz", "Duck Hunter Bubba", "Duck Hunter Burt",
"Earl Mac Rauch", "Doctor Emilio Lizardo", "Tom Cranham", "Ron Gress", "New Jersey", "Sam Minsky",
"Doreen A. Dixon", "Eddie Marks", "Edward Morey", "Eric Guaglione", "Erik L. Nelson", "Francine Lembi",
"Frank James Sparks", "Fred Iguchi", "Fred J. Koenekamp", "Gary Bisig", "Gary Daigler", "Gary Hellerstein",
"Gary Hymes", "General Catburd", "George Bowers", "George Stokes", "Gerald Peterson", "Glenn Campbell",
"Gordon Ecker Jr.", "Greenlite", "Greg Mires", "Gregg C. Rudloff", "Gregory Jein", "Grovers Mills", "H. Bud Otto",
"Henry Millar", "Hoyt Yeatman", "J. Michael Riva", "Jacqueline Zietlow", "James Belohovek", "James Hagedorn",
"James Keane", "James M. McCann", "James Rosin", "James Saito", "Jamie Lee Curtis", "Jane Marla Robbins",
"Jane Schwartz Jaffe", "Jerry Lewis hope2carrion", "Jerry Segal", "Jessie Lawrence Ferguson", "Joan Rowe",
"John Bracken", "John David Ashton", "John Emdall", "John Gant", "John Gomez", "John Murray", "John O'Connor",
"John Parker", "John Roesch", "John Scheele", "John T. Reitz", "John T. VanVliet", "John Valuk", "John Vigran",
"John Walter Davis", "Jonathan Banks", "Judi Rosner", "Judith Herman", "Justin De Rosa", "Kathryn Newbrough Sommer",
"Katterli Frauenfelder", "Keith Shartle", "Kenneth Karman", "Kenneth Magee", "Kent Perkins", "Kevin Rodney Sullivan",
"Kolodny Brothers", "Larry Fallick", "Laura Harrington", "Layne Bourgoyne", "Leonard Gaines", "Leslie Ekker",
"Lewis Smith", "Linda DeScenna", "Linda Fleisher", "Linda Henrikson", "Lord John Whorfin", "M. James Arnett",
"Mariclare Costello", "Mark Freund", "Mark Homer", "Mark Stetson", "Masado Banzai", "Matt Clark", "Matthew Mires",
"Mic Rodgers", "Michael Bigelow", "Michael Boddicker", "Michael Evje", "Michael G. Nathanson", "Michael Hosch",
"Michael L. Fink", "Michael Neale", "Michael Runyard", "Michael Santoro", "Mike De Luna", "Mister Wizard",
"Mrs. E. Johnson", "Neil Canton", "Peggy Priddy", "Pepe Serna", "Peter Kuran", "Phone Phreakers", "R.J. Robertson",
"Radar Blazer", "Radford Polinsky", "Raye Birk", "Reed Morgan", "Richard Carter", "Richard L. Thompson",
"Richard Marks", "Rick Heinrichs", "Rick Taylor", "Robert Gray", "Robert Hummer", "Robert Ito",
"Robert Michael Steloff", "Robert Wilcox", "Roberto Terminelli", "Robin Dean Leyden", "Rocco Gioffre",
"Rock star", "Ronald Lacey", "Rosalind Cash", "Rug Sucker", "Sal Orefice", "Samurai", "Scott Beattie",
"Scott Squires", "Selma Brown", "Senator Cunningham", "Sherman Labby", "Sidney Beckerman", "Stephen Dane",
"Stephen Robinette", "Steve Burg", "Steve Grumette", "Steve Hellerstein", "Steve LaPorte", "Terry Liebling",
"Thomas Hollister", "Thomas Pynchon", "Thomas R. Polizzi", "Tom Southwell", "Tommy J. Huff", "Tony Rivetti",
"Vincent Schiavelli", "Virginia L. Randolph", "Wayne Fitzgerald", "William G. Clevenger",
"William L. Hayward", "William Reilly", "William Traylor");

# global variables.  Don't use these at home, boys and girls!
# semi-seriously, I should put these into a calling function, but it's such a bother.

my %xlate_2_hash    = ();
my %xlate_from_hash = ();


###############################################################################

sub translate
{
    # receives the string of the entire perl script after 'use Acme::Buckaroo'.

    my $in_string = shift;

    my $out = "";
    $out = Dumper($in_string);
    print("Instring=>>$out<<\n") if $debug_mode;

    my @in_array = split(//, $in_string);
    $out = Dumper(@in_array);
    print("in_array=>>$out<<\n")  if $debug_mode;

    my $i = 0;
    my @temparray = ();
    foreach my $thischar (@in_array)
    {
        # translate each character into it's ascii value.
        my $num = unpack("c", $thischar);
        # change that ascii value into a string from the array...
        my $newchar = $xlate_array[$num];
        print("char=>>$thischar<<, num=>>$num<<, newchar=>>$newchar<<\n")  if $debug_mode;
        print("char=>>%s<<, num=>>%s<<, newchar=>>%s<<\n", $thischar, $num, $newchar)  if $debug_mode;
        push(@temparray, "$newchar");
        $i++;
        if ($i > 3)
        {
            push(@temparray, "\n");
            $i = 0;
        }
    }

    my $out_string = $header . join("\t", @temparray) . "\n";
    print("out_string=>>$out_string<<\n")  if $debug_mode;
    return $out_string;

}

################################################################################
# Normalize is called to convert the text to perl again from the encoded version.
#

sub normalize
{
    my $in_string = shift;;

    $in_string =~ s/^$header//g;

    print("normalize, got in_string>>$in_string<<\n")  if $debug_mode;

    my %revhash = ();
    my $counter = 0;
    foreach my $this_elem (@xlate_array)
    {
        $revhash{$this_elem} = $counter++;
    }

    $in_string =~ s/\t\n/\t/g;
    $in_string =~ s/\t+/\t/g;
    my @in_array  = split(/[\t]/, $in_string);
    my $in_array_dump = Dumper(@in_array);
    print("in_array_dump=>>$in_array_dump<<\n")  if $debug_mode;

    my @translate_array = ();
    my $this_elem = "";
    $counter = 1;
    foreach $this_elem (@in_array)
    {
        if (!($this_elem)) { print("Found undefined elem, counter=$counter.\n"); $counter++; next; }
        my $ascii_num = $xlate_2_hash{$this_elem} || 0;
        my $to_char = pack("c", $ascii_num);
        printf("Normalized >>%s<<, ascii_num=>>%s<<, char=>>%s<<, counter=>>%s<<\n", $this_elem, $ascii_num, $to_char, $counter)  if $debug_mode;
        push(@translate_array, $to_char);
        $counter++;
    }

    my $outtext = join('', @translate_array);
    print("Converted back to text=>>$outtext<<\n") if $debug_mode;

    return("$outtext");

}

###############################################################################

sub has_wordchars
{

    my $in_string = shift;
    my $retval = 0;

    print("In has_wordchars\n") if $debug_mode;

    if ($in_string =~ /\s/)
    {
        return $in_string;
    }
    else
    {
        return 0;
    }
}

###############################################################################

sub starts_with_header
{

    my $in_string = shift;
    my $retval = 0;

    print("In starts_with_header\n") if $debug_mode;

    if ($in_string =~ /^$header/)
    {
        return $in_string;
    }
    else
    {
        return 0;
    }

}

###############################################################################

sub import
{

    my $first           = shift;     # name of module, in this case "Buckaroo.pm"
    my $source_filename = $0;        # name of file called from (if test.pl does a 'use Acme::Buckaroo;' then this will be "test.pl")

    print("Starting \"Buckaroo\" process...\n") if $debug_mode;

    # set up some hashes to go to/from encoding scheme.
    my $i = 0;
    foreach my $this_elem (@xlate_array)
    {
        $xlate_2_hash{$this_elem} = $i;
        $xlate_from_hash{$i}      = $this_elem;
        $i++;
    }

    if (!(open(FILE_HANDLE, "<$source_filename")))
    {
        print("Can't Buckaroo again on '$0'\n");
        exit;
    }
    else
    {
        #comment this out if you don't care.
        print("Past open... ") if $debug_mode;
    }

    #read entire file in as a string.
    my @file_array = <FILE_HANDLE>;
    my $file_array_dump = Dumper(@file_array);
    print("file_array_dump=>>$file_array_dump<<")  if $debug_mode;

    my $file_string = join("",  @file_array);

    # elim anything before the 'use Acme::Buckaroo; line.
    $file_string =~ s/use\s*Acme::Buckaroo\s*;\s*\n//;

    print("Filestring=>>$file_string<<\n")  if $debug_mode;

    # no clue why we do this.  Anyone know?
    #local $SIG{__WARN__} = \&has_wordchars;

    if ( (has_wordchars($file_string)        ) &&
         (!(starts_with_header($file_string))) )
    {
        if (!(open(FILE_HANDLE, ">$0")))
        {
            print("Cannot Buckaroo '$0'\n");
            exit;
        }
        print("past open2...")  if $debug_mode;
        print(FILE_HANDLE "use Acme::Buckaroo;\n");
        my $result = translate($file_string);
        print(FILE_HANDLE $result);
        print("Done \"Buckaroo-ing!\n");
    }
    else
    {
        print("normalizing...\n")  if $debug_mode;
        my $out_string = normalize($file_string);
        print("out_string=>>$out_string<<\n")  if $debug_mode;
        my $outval = eval($out_string);
        print("Outval returned: $outval\n") if $debug_mode;
        if ($@)
        {
            print("Perl Error returned: $@\n");
        }
        print("No eval error returned.\n") if $debug_mode;
    }

    print("Finishing...\n")  if $debug_mode;

    exit;

}

###############################################################################

1;

###############################################################################

__END__

###############################################################################

=head1 NAME

Acme::Buckaroo - Buckaroo Banzai Characters Infest Your Code!

=head1 SYNOPSIS

Before Buckaroo-ing:

use Acme::Buckaroo;

print "Watch 'Buckaroo Banzai Across the 8th Dimension' Today!";

After Bucaroo-ing:

use Acme::Buckaroo;
Buckaroo Banzai Across The Eigth Dimension Buckaroo Banzai Across The Eigth Dimension
Bari Dreiband-Burman    General Catburd George Stokes   Frank James Sparks
        Gary Hellerstein        Glenn Campbell  Buckaroo Banzai Penny Priddy
        Damon Hines     New Jersey      Glenn Campbell  Doreen A. Dixon
        Francine Lembi  Buckaroo Banzai Girl Named John Scooter Lindley
        Gordon Ecker Jr.        Doreen A. Dixon Fred J. Koenekamp       New Jersey
        George Stokes   Gary Hymes      Gary Hymes      Buckaroo Banzai
        Scooter Lindley New Jersey      Gary Hellerstein        Grovers Mills
        New Jersey      Frank James Sparks      Buckaroo Banzai Sandra Banzai
        Doreen A. Dixon George Stokes   Gary Hymes      Gerald Peterson
        Gerald Peterson Buckaroo Banzai Glenn Campbell  Francine Lembi
        Edward Morey    Buckaroo Banzai Perfect Tommy   Glenn Campbell
        Francine Lembi  Buckaroo Banzai Smolensk USSR   Frank James Sparks
        Gary Daigler    Edward Morey    Gary Hellerstein        Gerald Peterson
        Frank James Sparks      Gary Hymes      Gary Hellerstein        Girl Named John
        Buckaroo Banzai Colette Emanuel Gary Hymes      Eddie Marks
        New Jersey      Gregory Jein    Defense Sec. McKinley   Penny Priddy
        Planet 10       Bari Dreiband-Burman

=head1 DESCRIPTION

The first time you run this program, the entire text of the program
after the 'use Acme::Buckaroo;' is converted (character by character)
into characters from the movie "Buckaroo Banzai Across the Eigth
Dimension" (and some other phrases, too).

The program will work (or not!) exactly as it did before it was
converted, but the code will be a somewhat endearing tribute to a
movie, instead of a clean, complete, clearly commented set of lines
of Perl code.

if you want to convert your program BACK into Perl, you must edit the
Acme::Buckaroo.pm module and turn on debugging (change the
line, "my $debug_mode = 0;" to the line, "my $debug_mode = 1;" and then
run the script again.  As it executes, it will translate the program
back.  Capture the output of this and you have your program back.

Acme::Buckaroo came about because the modules Acme::Buffy, Acme::Morse,
Acme::Pony, and Acme::Bleach were somewhat cryptically written.  This
author believes that CODE SHOULD BE SIMPLE and CLEAR to read and
understand.  Code that isn't clear is far less value.  And, since these
modules are for learning or FUN anyway, I might as well start here.

As someone who has taught beginners to use Perl, I've seen the problems
caused by using Perl idioms where typing a few more characters can make
maintenance possible and even quite easy.

=head1 DEDICATION

I'd like to dedicate this module to Mr. Damian Conway, who has bettered
Perl and the lives of those in the Perl-using community by vast amounts,
and continues to do good work.  Someday I'd like to buy him a beer.
Good book, dude!

The book, by the way, is "Object Oriented Perl", by Damian Conway
and Randall L. Schwartz, published by Manning Publications Company;
ISBN: 1884777791; (August 1999).

Also thanks to Jesse who reported a bug in this documentation
and introduced me to the CPAN bug tracking database, available
to everyone to report bugs in CPAN modules or scripts.  The address
for this is http://rt.cpan.org. If you know of a bug in a CPAN module,
report it there!

=head1 EXPORT

None by default.

=head1 SEE ALSO

Acme::Buffy, Acme::Morse, Acme::Pony, Acme::Bleach, and L<perl>.

=head1 DIAGNOSTICS

=over 4

=item C<Cannot Buckaroo '%s'>

Acme::Buckaroo could not modify the source file.  Are the file permissions set?

=item C<Cannot Buckaroo again on '%s'>

Acme::Buckaroo couldn't read the source file to execute it.  Are the file permissions set?

=back

=head1 AUTHOR

Kevin J. Rice, http://www.JustAnyone.com, E<lt>KevinRice@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2002, Kevin J. Rice.  All Rights Reserved. This module is
free software. It may be used, redistributed and/or modified under
the terms of the Perl Artistic License.
(see http://www.perl.com/perl/misc/Artistic.html for details)

=cut

###############################################################################
###############################################################################
###############################################################################
###############################################################################
