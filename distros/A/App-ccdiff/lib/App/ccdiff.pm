package App::ccdiff;

our $VERSION = "0.21";

use strict;
use warnings

1;

__END__

=head1 NAME

ccdiff - Colored character diff

=head1 SYNOPSIS

 ccdiff [options] file1|- file2|-

 ccdiff --help
 ccdiff --man
 ccdiff --info

=head1 DESCRIPTION

=head1 OPTIONS

=head2 Command line options

=over 2

=item --help -?

Show a summary op the available command-line options and exit.

=item --version -V

Show the version and exit.

=item --man

Show this manual using pod2man and nroff.

=item --info

Show this manual using pod2text.

=item --utf-8 -U

All I/O (streams to compare and standard out) are in UTF-8.

=item --unified[=3] -u [3]

Generate a unified diff. The number of context lines is optional. When omitted
it defaults to 3. Currently there is no provision of dealing with overlapping
diff chunks. If the common part between two diff chunks is shorter than twice
the number of context lines, some lines may show twice.

The default is to use traditional diff:

 5,5c5,5
 < Sat Dec 18 07:00:33 1993,I.O.D.U.,,756194433,1442539
 ---
 > Sat Dec 18 07:08:33 1998,I.O.D.U.,,756194433,1442539

a unified diff (-u1) would be

 5,5c5,5
   Tue Sep  6 05:43:59 2005,B.O.Q.S.,,1125978239,1943341
 - Sat Dec 18 07:00:33 1993,I.O.D.U.,,756194433,1442539
 + Sat Dec 18 07:08:33 1998,I.O.D.U.,,756194433,1442539
   Mon Feb 23 10:37:02 2004,R.X.K.S.,van,1077529022,1654127

=item --verbose[=1] -v[1]

Show an additional line for each old or new section in a change chunk (not for
added or deleted lines) that shows the hexadecimal value of each character. If
C<--utf-8> is in effect, it will show the Unicode character name(s).

This is a debugging option, so invisible characters can still be "seen".

C<--verbose> accepts an optional verbosity-level. On level 2 and up, all
horizontal changes get left-and-right markers inserted to enable seeing the
location of the ZERO WIDTH or invisible characters.

=item --markers -m

Use markers under each changed character in change-chunks.

C<--markers> is especially useful if the terminal does not support colors, or
if you want to copy/paste the output to (ASCII) mail. See also C<--ascii>

=item --ascii -a

Use (colored) ASCII indicators instead of Unicode. The default indicators are
Unicode characters that stand out better.

For the positional indicators, I did consider using U+034e (COMBINING UPWARDS
ARROW BELOW), but as most terminals are probably unable to show it due to line
height changes, I did not pursue the idea.

=item --pink -p

Change the default C<red> for deleted text to the color closest to pink that
is supported by L<Term::ANSIColor>: C<magenta>.

=item --reverse -r

Reverse the foreground and background for the colored indicators.

If the foreground color has C<bold>, it will be stripped from the new background
color.

=item --list-colors

List available colors and exit.

=item --old=color

Define the foreground color for deleted text.

=item --new=color

Define the foreground color for added text.

=item --bg=color

Define the background color for changed text.

=item --index --idx -I

Prefix position indicators with an index.

If a positive number is passed (C<--index=4> or C<-I 4>), display just the
chunk with that index. This is useful in combination with C<--verbose>.

=item --ignore-case -i

Ignore case on comparison.

=item --ignore-all-space -w 

Ignore all white-space changes. This will set all options C<-b>, C<-Z>, C<-E>,
and C<-B>.

=item --ignore-trailing-space -Z 

Ignore changes in trailing white-space (TAB's and spaces).

=item --ignore-ws|ignore-space-change -b 

Ignore changes in horizontal white-space (TAB's and spaces). This does not
include white-space changes that splits non-white-space or removes white-space
between two non-white-space elements.

=item --ignore-tab-expansion -E 

NYI

=item --ignore-blank-lines -B 

B<Just Partly Implemented> (WIP)

=back

=head2 Configuration files

In order to be able to overrule the defaults set in C<ccdiff>, one can set
options specific for this login. The following option files are looked for
in this order:

 - $HOME/ccdiff.rc
 - $HOME/.ccdiffrc
 - $HOME/.config/ccdiff

and evaluated in that order. Any options specified in a file later in that
chain will overwrite previously set options.

Option files are only read and evaluated if it is not empty and not writable
by others than the owner.

The syntax of the file is one option per line. where leading and trailing
white-space is ignored. If that line then starts with one of the options
listed below, followed by optional white-space followed by either an C<=> or
a C<:>, followed by optional white-space and the values, the value is assigned
to the option. The values C<no> and C<false> (case insensitive) are aliases
for C<0>. The values C<yes> and C<true> are aliases to C<-1> (C<-1> being a
true value).

Between parens is the corresponding command-line option.

=over 2

=item markers (-m)

 markers : false

defines if markers should be used under changed characters. The default is to
use colors only. The C<-m> command line option will toggle the option when set
from a configuration file.

=item ascii (-a)

 ascii   : false

defines to use ASCII markers instead of Unicode markers. The default is to use
Unicode markers.

=item reverse (-r)

 reverse : false

defines if changes are displayed as foreground-color over background-color
or background-color over foreground-color. The default is C<false>, so it will
color the changes with the appropriate color (C<new> or C<old>) over the
default background color.

=item new (--new)

 new     : green

defines the color to be used for added text. The default is C<green>.

any color accepted by L<Term::ANSIColor> is allowed. Any other color will
result in a warning. This option can include C<bold> either as prefix or
as suffix.

This option may also be specified as

 new-color
 new_color
 new-colour
 new_colour

=item old (--old)

 old     : red

defines the color to be used for delete text. The default is C<red>.

any color accepted by L<Term::ANSIColor> is allowed. Any other color will
result in a warning. This option can include C<bold> either as prefix or
as suffix.

This option may also be specified as

 old-color
 old_color
 old-colour
 old_colour

=item bg (--bg)

 bg      : white

defines the color to be used as background for changed text. The default is
C<white>.

any color accepted by L<Term::ANSIColor> is allowed. Any other color will
result in a warning. The C<bold> attribute is not allowed.

This option may also be specified as

 bg-color
 bg_color
 bg-colour
 bg_colour
 background
 background-color
 background_color
 background-colour
 background_colour

=item verbose

 verbose : cyan

defines the color to be used as color for the verbose tag. The default is
C<cyan>. This color will only be used under C<--verbose>.

any color accepted by L<Term::ANSIColor> is allowed. Any other color will
result in a warning.

This option may also be specified as

 verbose-color
 verbose_color
 verbose-colour
 verbose_colour

=item utf8 (-U)

 utf8    : yes

defines whether all I/O is to be interpreted as UTF-8. The default is C<no>.

This option may also be specified as

 unicode
 utf
 utf-8

=item index (-I)

 index   : no

defines if the position indication for a change chunk is prefixed with an
index number. The default is C<no>. The index is 1-based.

Without this option, the position indication would be like

 5,5c5,5
 19,19d18
 42a42,42

with this option, it would be

 [001] 5,5c5,5
 [002] 19,19d18
 [005] 42a42,42

When this option contains a positive integer, C<ccdiff> will only show diff
the diff chunk with that index.

=back

=head1 SEE ALSO

L<Algorithm::Diff>, L<Text::Diff>

=head1 AUTHOR

H.Merijn Brand

=head1 COPYRIGHT AND LICENSE

 Copyright (C) 2018-2018 H.Merijn Brand.  All rights reserved.

This library is free software;  you can redistribute and/or modify it under
the same terms as The Artistic License 2.0.

=for elvis
:ex:se gw=75|color guide #ff0000:

=cut

