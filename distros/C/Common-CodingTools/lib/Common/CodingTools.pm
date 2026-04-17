package Common::CodingTools;

use strict;
no strict 'subs'; # Needed for constants

=encoding utf8

=head1 NAME

Common::CodingTools - Common constants and functions for programmers

=head1 SYNOPSIS

 ## Global Tag
 # :all

 ## Constants Tags
 # :contants
 # :boolean
 # :toggle
 # :activity
 # :health
 # :expiration
 # :cleanliness
 # :emotion
 # :success
 # :want
 # :pi

 ## Functions Tags
 # :functions
 # :file
 # :trim
 # :schwartz
 # :weird
 # :string

 use Common::CodingTools qw(:all);

=head1 DESCRIPTION

Something to use for just about any Perl project, as typical as "use strict".  It pre-defines some constants for easy boolean checks and has available functions Perl should have included by default.

=head2 IMPORT CONSTANTS

In addition to the defaults, you can use constants that better reflect the purpose of the code

Positive names (equals 1)

=over 4

=item TRUE

=item SUCCESS

=item SUCCESSFUL

=item SUCCEEDED

=item HAPPY

=item CLEAN

=item EXPIRED

=item HEALTHY

=item ON

=item ACTIVE

=item WANTED

=back

Negative names (equals 0)

=over 4

=item FALSE

=item FAILURE

=item FAILED

=item FAIL

=item SAD

=item ANGRY

=item DIRTY

=item NOTEXPIRED

=item UNHEALTHY

=item OFF

=item INACTIVE

=item UNWANTED

=back

=head2 IMPORT FUNCTIONS

Helpful functions you can import into your code

=over 4

=item slurp_file

=item ltrim

=item rtrim

=item trim

=item tfirst

=item uc_lc

=item center

=item schwartzian_sort

=back

=head2 IMPORT TAGS

All parameters are prefixed with :

=head3 CONSTANTS

=over 4

=item :all

Imports all functions, constants and tags

=item :functions

Imports all functions

=item :constants

Imports all contants

=item :boolean

Inports the constants TRUE and FALSE

=item :toggle

Imports the constants ON and OFF

=item :activity

Imports the constants ACTIVE and INACTIVE

=item :health

Imports the constants HEALTHY and UNHEALTHY

=item :expiration

Imports the constants EXPIRED and NOTEXPIRED

=item :cleanliness

Imports the constants CLEAN and DIRTY

=item :emotion

Imports the constants HAPPY, UNHAPPY, SAD and ANGRY

=item :success

Imports the constants SUCCESS, SUCCESSFUL, SUCCEEDED, FAILURE, FAILED and FAIL

=item :want

Imports the constants WANTED and UNWANTED

=item :pi

Imports the constant PI (the mathematical value of pi)

=back

=head3 FUNCTIONS

=over 4

=item :file

Imports the function "slurp_file"

=item :trim

Imports the functions "ltrim", "rtrim" and "trim"

=item :schwarts

Import the function "schwartzian_sort"

=item :weird

Import the function "uc_lc"

=item :string

Import the functions/tags ":trim", ":weird-case" and "center"

=back

=cut

use List::Util qw(max);
use constant {
    FALSE      => 0,
    TRUE       => 1,
    ON         => 1,
    OFF        => 0,
    ACTIVE     => 1,
    INACTIVE   => 0,
    SUCCESS    => 1,
    SUCCEEDED  => 1,
    SUCCESSFUL => 1,
    FAILURE    => 0,
    FAILED     => 0,
    FAIL       => 0,
    WANTED     => 1,
    UNWANTED   => 0,
    HAPPY      => 1,
    UNHAPPY    => 0,
    SAD        => 0,
    ANGRY      => 0,
    CLEAN      => 1,
    DIRTY      => 0,
    EXPIRED    => 1,
    NOTEXPIRED => 0,
    HEALTHY    => 1,
    UNHEALTHY  => 0,
    PI         => (4 * atan2(1, 1)),
};

BEGIN {
    our $VERSION = 2.06;
}

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT    = qw();
our @EXPORT_OK = qw(
  TRUE FALSE
  SUCCESS SUCCESSFUL SUCCEEDED FAILURE FAILED FAIL
  HAPPY UNHAPPY SAD ANGRY
  CLEAN DIRTY
  EXPIRED NOTEXPIRED
  HEALTHY UNHEALTHY
  ON OFF
  ACTIVE INACTIVE
  WANTED UNWANTED

  PI

  slurp_file
  ltrim
  rtrim
  trim
  tfirst
  uc_lc
  leet_speak
  center
  schwartzian_sort
);
our %EXPORT_TAGS = (
    'boolean'     => [qw(TRUE FALSE)],
    'toggle'      => [qw(ON OFF)],
    'want'        => [qw(WANTED UNWANTED)],
    'activity'    => [qw(ACTIVE INACTIVE)],
    'health'      => [qw(HEALTHY UNHEALTHY)],
    'expiration'  => [qw(EXPIRED NOTEXPIRED)],
    'cleanliness' => [qw(CLEAN DIRTY)],
    'emotion'     => [qw(HAPPY UNHAPPY SAD ANGRY)],
    'success'     => [qw(SUCCESS SUCCESSFUL SUCCEEDED FAILURE FAILED FAIL)],
    'pi'          => [qw(PI)],
    'file'        => [qw(slurp_file)],
    'trim'        => [qw(ltrim rtrim trim)],
    'schwartz'    => [qw(schwartzian_sort)],
    'weird'       => [qw(uc_lc leet_speak)],
    'weird-case'  => [qw(uc_lc leet_speak)],
    'string'      => [qw(ltrim rtrim trim uc_lc leet_speak center tfirst)],
    'constants'   => [
        qw(
          ON OFF
          SUCCESS SUCCESSFUL SUCCEEDED FAILURE FAILED FAIL
          ACTIVE INACTIVE
          HEALTHY UNHEALTHY EXPIRED NOTEXPIRED
          CLEAN DIRTY
          HAPPY UNHAPPY SAD ANGRY
          WANTED UNWANTED
          PI
          TRUE FALSE
        )
    ],
    'functions' => [
        qw(
          slurp_file
          ltrim rtrim trim uc_lc leet_speak
          schwartzian_sort
          center
          tfirst
        )
    ],
    'all' => [
        qw(
          ON OFF
          SUCCESS SUCCESSFUL SUCCEEDED FAILURE FAILED FAIL
          ACTIVE INACTIVE
          HEALTHY UNHEALTHY EXPIRED NOTEXPIRED
          CLEAN DIRTY
          HAPPY UNHAPPY SAD ANGRY
          WANTED UNWANTED
          PI
          TRUE FALSE
          slurp_file
          ltrim rtrim trim uc_lc leet_speak
          schwartzian_sort
          center
          tfirst
        )
    ],
);

=head1 FUNCTIONS

X<slurp_file>
X<ltrim>
X<rtrim>
X<trim>
X<center>
X<uc_lc>
X<leet_speak>
X<schwartzian_sort>

=head2 slurp_file

Reads in a text file and returns the contents of that file as a single string.  It returns undef if the file is not found.

 my $string = slurp_file('/file/name');

=cut

sub slurp_file {
    my $file = shift;

    # Read in a text file without using open
    if (-e $file) {
        return (
            do { local (@ARGV, $/) = $file; <> }
        );
    }
    return (undef);
} ## end sub slurp_file

=head2 ltrim

Removes any spaces at the beginning of a string (the left side).

 my $result = ltrim($string);

=cut

sub ltrim {
    my $string = shift;
    if (defined($string) && $string ne '') {
        $string =~ s/^\s+//g;
    }
    return ($string);
} ## end sub ltrim

=head2 rtrim

Removes any spaces at the end of a string (the right side).

 my $result = rtrim($string);

=cut

sub rtrim {
    my $string = shift;
    if (defined($string) && $string ne '') {
        $string =~ s/\s+$//g;
    }
    return ($string);
} ## end sub rtrim

=head2 trim

Removes any spaces at the beginning and the end of a string.

 my $result = trim($string);

=cut

sub trim {
    my $string = shift;
    if (defined($string) && $string ne '') {
        $string =~ s/^\s+|\s+$//g;
    }
    return ($string);
} ## end sub trim

=head2 center

Centers a string, padding with leading spaces, in the middle of a given width.

 my $result = center($string, 80); # Centers text for an 80 column display

=cut

sub center {
    my $string = shift || '';
    my $size   = max(shift, length($string));

    my $csize  = int($size - length($string));
    my $tab    = int($csize / 2);
    my $format = '%-' . $size . 's';
    $string = ' ' x $tab . $string if ($tab > 0);
    $string = sprintf($format, $string);
    return ($string);
} ## end sub center

=head2 uc_lc

This changes text to annoying "leet-speak".

 my $result = uc_lc($string, 1);  # Second parameter determs whether to start with upper or lower-case.  You can leave out that parameter for random pick.

=cut

sub uc_lc {
    my $string = shift;
    my $start  = (scalar(@_)) ? shift : int(rand(2));

    if (defined($string) && $string ne '') {
        my $l = length($string);

        for (my $count = 0; $count < $l; $count++) {
            my $c = substr($string, $count, 1);
            if ($c =~ /\w/) {
                if ($start) {
                    substr($string, $count, 1) = uc($c);
                    $start = 0;
                } else {
                    substr($string, $count, 1) = lc($c);
                    $start = 1;
                }
            } ## end if ($c =~ /\w/)
        } ## end for (my $count = 0; $count...)
    } ## end if (defined($string) &&...)
    return ($string);
} ## end sub uc_lc

=head2 leet_speak (same as uc_lc)

This changes text to annoying "leet-speak".

 my $result = leet_speak($string, 1);  # Second parameter determs whether to start with upper or lower-case.  You can leave out that parameter for random pick.

=cut

sub leet_speak {
    return(uc_lc(@_));
}

=head2 schwartzian_sort

Sorts a rather large list with the very fast Swartzian sort.  It returns either an array or a reference to an array, depending how it was called.

 my @sorted = schwartzian_sort(@unsorted); # Can be slower with large arrays due to stack overhead.

or

 my $sorted = schwartzian_sort(\@unsorted); # Pass a reference and returns a reference (faster for large arrays)

=cut

sub schwartzian_sort {
    my $wa = wantarray;
    if (scalar(@_) == 1) {
        @_ = @{$_[0]};
    }
    my @sorted = map { $_->[1] }
        sort { $a->[0] cmp $b->[0] }
            map { [lc($_), $_] } @_;
    return(($wa) ? @sorted : \@sorted);
}

=head2 tfirst

Change text into "title ready" text with each word capitalized.

 my $title = tfirst($string);

For example:

 my $before = 'this is a string I want to turn into a title-ready string';

 my $title  = tfirst($before);

# $title is now 'This Is a String I Want To Turn Into a Title-ready String'

=cut

sub tfirst {
    #
    # This function, tfirst, is based upon TitleCase code by the following authors:
    #
    #       10 May 2008
    #       Original version by John Gruber:
    #       http://daringfireball.net/2008/05/title_case
    #
    #       28 July 2008
    #       Re-written and much improved by Aristotle Pagaltzis:
    #       http://plasmasturm.org/code/titlecase/
    #
    #       License: http://www.opensource.org/licenses/mit-license.php
    #
    my $string = shift;
    if (defined($string) && $string ne '') {

        # Define what little words are first.
        my @little_guys = qw( (?<!q&)a an and as at(?!&t) but by en for if in of on or the to v[.]? via vs[.]? );

        # Change this into a regexp portion.
        my $little_regexp = join '|', @little_guys;

        my $psa = qr/ (?: ['’] [[:lower:]]* )? /x;

        $string =~ s{
    \b (_*) (?:
        ( [-_[:alpha:]]+ [@.:/] [-_[:alpha:]@.:/]+ $psa ) | # Internet address?
        ( (?i: $little_regexp ) $psa ) |                    #    or little word (case-insensitive)?
        ( [[:alpha:]] [[:lower:]'’()\[\]{}]* $psa ) |       #    or word without internal capitals?
  ( [[:alpha:]] [[:alpha:]'’()\[\]{}]* $psa )         #    or other type of word
  ) (_*) \b
  }{
      $1 . (
          defined $2 ? $2         # Please keep Internet specific addresses
          : defined $3 ? "\L$3"     # This is a lowercase little word
          : defined $4 ? "\u\L$4"   # Now capitalize the word without internal capitals
          : $5                      # Please preserve other type words
      ) . $6
  }exgo;

        # Further processing for little words and other unique title rules
        $string =~ s{
    (  \A [[:punct:]]*         # Title beginning
        |  [:.;?!][ ]+             #     or perhaps a subsentence?
        |  [ ]['"“‘(\[][ ]*     )  #     or perhaps a subphrase?
  ( $little_regexp ) \b      #     is it followed by little word?
  }{$1\u\L$2}xigo;

        $string =~ s{
    \b ( $little_regexp )      # The word is little
      (?= [[:punct:]]* \Z        #    are we at the end of the title?
          |   ['"’”)\]] [ ] )        #    or a subphrase?
  }{\u\L$1}xigo;
    } ## end if (defined($string) &&...)
    return ($string);
} ## end sub tfirst

1;

=head1 AUTHOR

Richard Kelsch <rich@rk-internet.com>

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 VERSION

Version 2.06 (April 15, 2026)

=head1 BUGS

Please report any bugs or feature requests to bug-commoncodingtools at rt.cpan.org, or through the web interface at http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CommonCodingTools. I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

perldoc Common::CodingTools

You can also look for information at:

=over 4

=item RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Common-CodingTools>

=item AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Common-CodingTools>

=item CPAN Ratings

L<http://cpanratings.perl.org/d/Common-CodingTools>

Not exactly a reliable and fair means of rating modules. Modules are updated and improved over time, and what may have been a poor or mediocre review at version 0.04, may not remotely apply to current or later versions. It applies ratings in an arbitrary manner with no ability for the author to add their own rebuttals or comments to the review, especially should the review be malicious or inapplicable.

More importantly, issues brought up in a mediocre review may have been addressed and improved in later versions, or completely changed to allieviate that issue.

So, check the reviews AND the version number when that review was written.

=item Search CPAN

L<http://search.cpan.org/dist/Common-CodingTools/>

=item GitHub

L<https://github.com/richcsst/Common-CodingTools>

=back

=head1 COPYRIGHT

Copyright (C) 2016 Richard Kelsch,
All Rights Reserved

The B<tfirst> subroutine is Copyright (C) 2008 John Gruber as "TitleCase"

=head1 LICENSES

=over 4

=item B<Artistic License 2.0>

=back

=over 4

This program is free software; you can redistribute it and/or modify it under the terms of the the Artistic License (2.0). You may obtain a copy of the full license at:

L<https://perlfoundation.org/artistic-license-20.html>

=back

=over 4

=item B<MIT License>

=back

=over 4

The B<tfirst> routine only, is under the MIT license as "TitleCase".

L<http://www.opensource.org/licenses/mit-license.php>

=back

=cut

__END__

######################## Perl Cheat Sheet #########################
#  CONTEXTS  SIGILS  ref        ARRAYS        HASHES
#  void      $scalar SCALAR     @array        %hash
#  scalar    @array  ARRAY      @array[0, 2]  @hash{'a', 'b'}
#  list      %hash   HASH       $array[0]     $hash{'a'}
#            &sub    CODE
#            *glob   GLOB       SCALAR VALUES
#                    FORMAT     number, string, ref, glob, undef
#  REFERENCES
#  \      reference       $$foo[1]       aka $foo->[1]
#  $@%&*  dereference     $$foo{bar}     aka $foo->{bar}
#  []     anon. arrayref  ${$$foo[1]}[2] aka $foo->[1]->[2]
#  {}     anon. hashref   ${$$foo[1]}[2] aka $foo->[1][2]
#  \()    list of refs
#                         SYNTAX
#  OPERATOR PRECEDENCE    foreach (LIST) { }     for (a;b;c) { }
#  ->                     while   (e) { }        until (e)   { }
#  ++ --                  if      (e) { } elsif (e) { } else { }
#  **                     unless  (e) { } elsif (e) { } else { }
#  ! ~ \ u+ u-            given   (e) { when (e) {} default {} }
#  =~ !~
#  * / % x                 NUMBERS vs STRINGS  FALSE vs TRUE
#  + - .                   =          =        undef, "", 0, "0"
#  << >>                   +          .        anything else
#  named uops              == !=      eq ne
#  < > <= >= lt gt le ge   < > <= >=  lt gt le ge
#  == != <=> eq ne cmp ~~  <=>        cmp
#  &
#  | ^             REGEX MODIFIERS       REGEX METACHARS
#  &&              /i case insensitive   ^      string begin
#  || //           /m line based ^$      $      str end (bfr \n)
#  .. ...          /s . includes \n      +      one or more
#  ?:              /x /xx ign. wh.space  *      zero or more
#  = += last goto  /p preserve           ?      zero or one
#  , =>            /a ASCII    /aa safe  {3,7}  repeat in range
#  list ops        /l locale   /d  dual  |      alternation
#  not             /u Unicode            []     character class
#  and             /e evaluate /ee rpts  \b     boundary
#  or xor          /g global             \z     string end
#                  /o compile pat once   (p)    capture
#  DEBUG                                 (?:p)  no capture
#  -MO=Deparse     REGEX CHARCLASSES     (?#t)  comment
#  -MO=Terse       .   [^\n]             (?=p)  ZW pos ahead
#  -D##            \s  whitespace        (?!p)  ZW neg ahead
#  -d:Trace        \w  word chars        (?<=p) ZW pos behind \K
#                  \d  digits            (?<!p) ZW neg behind
#  CONFIGURATION   \pP named property    (?>p)  no backtrack
#  perl -V:ivsize  \h  horiz.wh.space    (?|p|p)branch reset
#                  \R  linebreak         (?<n>p)named capture
#                  \S \W \D \H negate    \g{n}  ref to named cap
#                                        \K     keep left part
#  FUNCTION RETURN LISTS
#  stat      localtime    caller         SPECIAL VARIABLES
#   0 dev    0 second      0 package     $_    default variable
#   1 ino    1 minute      1 filename    $0    program name
#   2 mode   2 hour        2 line        $/    input separator
#   3 nlink  3 day         3 subroutine  $\    output separator
#   4 uid    4 month-1     4 hasargs     $|    autoflush
#   5 gid    5 year-1900   5 wantarray   $!    sys/libcall error
#   6 rdev   6 weekday     6 evaltext    $@    eval error
#   7 size   7 yearday     7 is_require  $$    process ID
#   8 atime  8 is_dst      8 hints       $.    line number
#   9 mtime                9 bitmask     @ARGV command line args
#  10 ctime               10 hinthash    @INC  include paths
#  11 blksz               3..10 only     @_    subroutine args
#  12 blcks               with EXPR      %ENV  environment
###################################################################
