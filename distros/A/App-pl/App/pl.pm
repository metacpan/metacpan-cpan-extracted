package App::pl;

warn "This is a just dummy package to own the namespace.  Please run the script 'pl' directly!\n";

1;

# Copied from pl to where CPAN expects it:

=head1 NAME

pl - Swiss Army Knife of Perl One-Liners

=head1 SYNOPSIS

Just one small script extends C<perl -E> with many bells & whistles: Various
one-letter commands & magic variables (with meaningful aliases too) and more
nifty loop options take Perl programming to the command line.  List::Util is
fully imported.  Unless you pass a program on the command line, starts a
simple Perl Shell.

How to C<e(cho)> values, including from C<@A(RGV)>, with single C<$q(uote)> &
double C<$Q(uote)>.  Same for hard-to-print values:

    pl 'e "${q}Perl$q", "$Q@A$Q"' one liner
    pl 'e \"Perl", \@A, undef' one liner

Print up to 3 matching lines, resetting count (and C<$.>) for each file:

    pl -rP3 '/Perl.*one.*liner/' file1 file2 file3

Loop over args, printing each with line ending.  And same, shouting:

    pl -opl '' Perl one liner
    pl -opl '$_ = uc' Perl one liner

Count hits in magic statistics hash C<%n(umber)>:

    pl -n '++$n{$1} while /(Perl|one|liner)/g' file1 file2 file3

Even though the point here is to make things even easier, most Perl one-liners
from the internet work, just by omitting C<-e> or C<-E>.  Known minor
differences are: don't C<goto LINE>, but C<next LINE> is fine.  In B<-n>
C<last> goes straight to the next file instead of being like C<exit>.  And
shenanigans with unbalanced braces won't work.

Windows note: Do yourself a favour and get a real Shell, e.g. from Cygwin or
MSYS.  Any help for getting this to work in PowerShell is welcome!  If you
can't avoid command.com or cmd.exe, you will have to first convert all inner
quotes to C<qq>.  Then convert the outer single quotes to double quotes:

    pl "e qq{${q}Perl$q}, qq{$Q@A$Q}" one liner

=head1 DESCRIPTION

Pl follows Perl's philosophy for one-liners: the one variable solely used in
one-liners, C<@F>, is single-lettered.  Because not everyone may like that, Pl
has it both ways.  Everything is aliased both as a word and as a single
letter, including Perl's own C<@F> & C<*ARGV>.

C<-b> doesn't do a C<BEGIN> block.  Rather it is in the same scope as your main
PERLCODE.  So you can use it to initialise C<my> variables.  Whereas, if you
define a my variable in a B<-n>, B<-p>, B<-o> or B<-O> loop, it's a new
variable each time.  This echoes "a c" because -e emulates an B<END> block, as
a closure of the first C<$inner> variable:

    pl -Ob 'my $outer'  -e 'echo $inner, $outer'  'my $inner = $outer = $ARGV' a b c

=head1 EXAMPLES

Only some of these are original.  Many have been adapted from the various Perl
one-liner pages on the internet.  This is no attempt to appropriate ownership,
just to show how things are even easier and more concise with pl.

All examples use the long names and are repeated for short names, where applicable.

=head2 Looking at Perl

=over

=item VERSION of a File

Print the first line where the substitution was successful:

    pl -P1 's/.+\bVERSION\s*=\s*[v$Quote$quote]([0-9.]+).+/$1/' pl
    pl -P1 's/.+\bVERSION\s*=\s*[v$Q$q]([0-9.]+).+/$1/' pl

For multple files, add the filename, and reset B<-P> count for each file:

    pl -rP1 's/.+\bVERSION\s*=\s*[v$Quote$quote]([0-9.]+).+/$ARGV: $1/' *.pm
    pl -rP1 's/.+\bVERSION\s*=\s*[v$Q$q]([0-9.]+).+/$A: $1/' *.pm

=item Only POD or non-POD

You can extract either parts of a Perl file, with these commands.  Note that
they don't take the empty line before into account.  If you want that, and
you're sure the files adheres strictly to this convention, use the option
B<-00P> instead (not exactly as desired, the empty line comes after things,
but still, before next thing).  If you want only the 1st POD (e.g. NAME &
SYNOPSIS) use the option B<-P1> or B<-00P1>:

    pl -P '/^=\w/../^=cut/' file
    pl -P 'not /^=\w/../^=cut/' file

=item Content of a Package

Pl's C<e(cho)> can print any item.  Packages are funny hashes, with two colons
at the end.  Backslashing the variable passes it as a unit to C<Data::Dumper>,
which gets loaded on demand in this case.  Otherwise all elements would come
out just separated by spaces:

    pl 'echo \%List::Util::'
    pl 'e \%List::Util::'

=item Library Loading

Where does perl load from, and what exactly has it loaded?

    pl 'echo \@INC, \%INC'
    pl 'e \@INC, \%INC'

Same, for a different Perl version, e.g. if you have F<perl5.20.0> in your
path:

    pl -V5.20.0 'echo \@INC, \%INC'
    pl -V5.20.0 'e \@INC, \%INC'

=item Configuration

You get C<%Config::Config> loaded on demand and returned by C<c(onfig)>:

    pl 'echo config'
    pl 'e c'

It returns a hash reference, from which you can lookup an entry:

    pl 'echo config->{sitelib}'
    pl 'e c->{sitelib}'

You can also return a sub-hash, of only the keys matching any regexps you
pass:

    pl 'echo config "random", qr/stream/'
    pl 'e c "random", qr/stream/'

=back

=head2 File statistics

=over

=item Count files per suffix

Find and pl both use the B<0> option to allow funny filenames, including
newlines.  Sum up encountered suffixes in sort-value-numerically-at-end hash
C<%n(umber)>:

    find -print0 |
        pl -0ln '++$number{/(\.[^\/.]+)$/ ? $1 : "none"}'
    find -print0 |
        pl -0ln '++$n{/(\.[^\/.]+)$/ ? $1 : "none"}'

=item Count files per directory per suffix

Match to last / & after a dot following something, i.e. not just a dot-file.
"" is the suffix for suffixless files.  Stores in
sort-by-key-and-stringify-at-end C<%s(tring)>.  So count in a nested hash of
directory & suffix:

    find -type f -print0 |
        pl -0ln '/^(.+)\/.+?(?:\.([^.]*))?$/; ++$string{$1}{$2}'
    find -type f -print0 |
        pl -0ln '/^(.+)\/.+?(?:\.([^.]*))?$/; ++$s{$1}{$2}'

This is the same, but groups by suffix and counts per directory:

    find -type f -print0 |
        pl -0ln '/^(.+)\/.+?(?:\.([^.]*))?$/; ++$string{$2}{$1}'
    find -type f -print0 |
        pl -0ln '/^(.+)\/.+?(?:\.([^.]*))?$/; ++$s{$2}{$1}'

This is similar, but stores in sort-by-number-at-end C<%n(umber)>.  Since this matches
suffixes optionally, a lone dot indicates no suffix.  The downside is that it
is neither sorted by directory, nor by suffix:

    find -type f -print0 |
        pl -0ln '/^(.+)\/.+?(?:\.([^.]*))?$/; ++$number{"$1 .$2"}'
    find -type f -print0 |
        pl -0ln '/^(.+)\/.+?(?:\.([^.]*))?$/; ++$n{"$1 .$2"}'

This avoids the lone dot:

    find -type f -print0 |
        pl -0ln '/^(.+)\/.+?(?:\.([^.]*))?$/; ++$number{length($2) ? "$1 .$2" : "$1 none"}'
    find -type f -print0 |
        pl -0ln '/^(.+)\/.+?(?:\.([^.]*))?$/; ++$n{length($2) ? "$1 .$2" : "$1 none"}'

=item Sum up file-sizes per suffix.

Find separates output with a dot and -F splits on that.  The C<\\> is to
escape one backslash from the Shell.  No matter how many dots the filename
contains, 1st element is the size and last is the suffix.  Sum it in C<%n(umber)>,
which gets sorted numerically at the end:

    find -name '*.*' -type f -printf "%s.%f\0" |
        pl -0lanF\\. '$number{".$FIELD[-1]"} += $FIELD[0]'
    find -name '*.*' -type f -printf "%s.%f\0" |
        pl -0lanF\\. '$n{".$F[-1]"} += $F[0]'

This is similar, but also deals with suffixless files:

    find -type f -printf "%s.%f\0" |
        pl -0lanF\\. '$number{@FIELD == 2 ? "none" : ".$FIELD[-1]"} += $FIELD[0]'
    find -type f -printf "%s.%f\0" |
        pl -0lanF\\. '$n{@F == 2 ? "none" : ".$F[-1]"} += $F[0]'

=item Count files per date

Incredibly, find has no ready-made ISO date, so specify the 3 parts.  If you
don't want days, just leave out C<-%Td>.  Sum up encountered dates in
sort-value-numerically-at-end hash C<%n(umber)>:

    find -printf '%TY-%Tm-%Td\n' |
        pl -ln '++$number{$_}'
    find -printf '%TY-%Tm-%Td\n' |
        pl -ln '++$n{$_}'

=item Count files per date with rollup

todo
Rollup means, additionally to the previous case
The trick here is to count both for the actual year, month and day, as well as
replacing once only the day, once also the month with "__",and once also the
year with "____".  This sorts after numbers and gives a sum for all with the
same leading numbers.

    find -printf '%TY-%Tm-%Td\n' |
        pl -ln '++$string{$_}; ++$string{$_} while s/[0-9]+(?=[-_]*$)/"_" x length $&/e'
    find -printf '%TY-%Tm-%Td\n' |
        pl -ln '++$s{$_}; ++$s{$_} while s/[0-9]+(?=[-_]*$)/"_" x length $&/e'

=back

=head2 Diff several inputs by a unique key

The function C<k(eydiff)> stores the 2nd arg or chomped C<$_> in C<%k(eydiff)>
keyed by 1st arg or C<$1> and the arg counter C<$ARGIND> or C<$I>.  Its
sibling C<K(eydiff)> does the same using 1st arg or 0 as an index into C<@F(IELD)>
for the 1st part of the key.  At the end only the rows differing between files
are shown.  If you specify B<--color> and have C<Algorithm::Diff> the exact
difference gets color-highlighted.

=over

=item Diff several csv, tsv or passwd files by 1st field

This assumes no comma in key field and no newline in any field.  Else you need
a csv-parser package.  B<-F> implies B<-a>, which implies B<-n> (even before
Perl 5.20, which introduced this idea):

    pl -F, Keydiff *.csv
    pl -F, K *.csv

This is similar, but removes the key from the stored value, so it doesn't get
repeated for each file:

    pl -n 'keydiff if s/(.+?),//' *.csv
    pl -n 'k if s/(.+?),//' *.csv

A variant of csv is tsv, with tab as separator.  Tab is C<\t>, which must be
escaped from the Shell as C<\\t>:

    pl -anF\\t Keydiff *.tsv
    pl -n 'keydiff if s/(.+?)\t//' *.tsv
    pl -anF\\t K *.tsv
    pl -n 'k if s/(.+?)\t//' *.tsv

The same, with a colon as separator, if you want to compare passwd files from
several hosts:

    pl -anF: Keydiff /etc/passwd passwd*
    pl -n 'keydiff if s/(.+?)://' /etc/passwd passwd*
    pl -anF: K /etc/passwd passwd*
    pl -n 'k if s/(.+?)://' /etc/passwd passwd*

=item Diff several zip archives by member name

This uses the same mechanism as the csv example.  Addidionally it reads the
output of C<unzip -vql> for each archive through the C<pipe> or C<p> block.
That has a fixed format, except for tiny members, which can report -200%,
screwing the column by one:

    pl -o 'piped { keydiff if / Defl:/ && s/^.{56,57}\K  (.+)// } "unzip", "-vql", $_' *.zip
    pl -o 'p { k if / Defl:/ && s/^.{56,57}\K  (.+)// } "unzip", "-vql", $_' *.zip

If you do a clean build of java, many class files will have the identical crc,
but still differ by date.  This excludes the date:

    pl -o 'piped { keydiff $2 if / Defl:/ && s/^.{31,32}\K.{16} ([\da-f]{8})  (.+)/$1/ } "unzip", "-vql", $_' *.jar
    pl -o 'p { k $2 if / Defl:/ && s/^.{31,32}\K.{16} ([\da-f]{8})  (.+)/$1/ } "unzip", "-vql", $_' *.jar

=item Diff several tarballs by member name

This is like the zip example.  But tar gives no checksum, so this is not very
reliable.  Each time a wider file size was seen columns shift right.  Reformat
the columns, so this doesn't show up as a difference:

    pl -o 'piped { s/^\S+ \K(.+?) +(\d+) (.{16}) (.+)/sprintf "%-20s %10d %s", $1, $2, $3/e; keydiff $4 } "tar", "-tvf", $_' *.tar *.tgz *.txz
    pl -o 'p { s/^\S+ \K(.+?) +(\d+) (.{16}) (.+)/sprintf "%-20s %10d %s", $1, $2, $3/e; k $4 } "tar", "-tvf", $_' *.tar *.tgz *.txz

Again without the date:

    pl -o 'piped { s/^\S+ \K(.+?) +(\d+) .{16} (.+)/sprintf "%-20s %10d", $1, $2/e; keydiff $3 } "tar", "-tvf", $_' *.tar *.tgz *.txz
    pl -o 'p { s/^\S+ \K(.+?) +(\d+) .{16} (.+)/sprintf "%-20s %10d", $1, $2/e; k $3 } "tar", "-tvf", $_' *.tar *.tgz *.txz

=item Diff ELF executables or libraries by loaded dependencies

You get the idea: you can do this for any command that outputs records with a
unique key.  This one looks at the required libraries and which file they came
from.  For a change loop with B<-O> and C<@A(RGV)> to avoid the previous
examples' confusion between outer C<$_> which are the cli args, and the inner
one, which are the read lines:

    pl -O 'piped { keydiff if s/^\t(.+\.so.*) => (.*) \(\w+\)/$2/ } ldd => $ARGV' exe1 exe2 exe3
    pl -O 'p { k if s/^\t(.+\.so.*) => (.*) \(\w+\)/$2/ } ldd => $A' exe1 exe2 exe3

It's even more useful if you use just the basename as a key, because version
numbers may change:

    pl -O 'piped { keydiff $2 if s/^\t((.+)\.so.* => .*) \(\w+\)/$1/ } ldd => $ARGV' exe1 exe2 exe3
    pl -O 'p { k $2 if s/^\t((.+)\.so.* => .*) \(\w+\)/$1/ } ldd => $A' exe1 exe2 exe3

=back

=head2 Tables

=over

=item ANSI foreground;background colour table

How to generate a table, hardly a one-liner...  You get numbers to fill into
C<"\e[FGm">, C<"\e[BGm"> or C<"\e[FG;BGm"> to get a colour and close it with
C<"\e[m">.  There are twice twice 8 different colors for dim & bright and for
foreground & background.  Hence the multiplication of escape codes and of
values to fill them.

This fills C<@A(RGV)> in C<-b>, as though it had been given on the command
line.  It maps it to the 16fold number format to print the header.  Then the
main PERLCODE loops over it with C<$A(RGV)>, thanks to C<-O>, to print the
body.  All numbers are duplicated with C<(N)x2>, once to go into the escape
sequence, once to be displayed:

    pl -Ob '@ARGV = map +($_, $_+8), 1..8; f "co:  fg;bg"."%5d"x16, @ARGV' \
        'echof "%2d:  \e[%dm%d;   ".("\e[%dm%4d "x16)."\e[m", $A, ($A + ($A > 8 ? 81 : 29))x2, map +(($_)x2, ($_+60)x2), 40..47'
    pl -Ob '@A = map +($_, $_+8), 1..8; f "co:  fg;bg"."%5d"x16, @A' \
        'ef "%2d:  \e[%dm%d;   ".("\e[%dm%4d "x16)."\e[m", $A, ($A + ($A > 8 ? 81 : 29))x2, map +(($_)x2, ($_+60)x2), 40..47'

This does exactly the same, but explicitly loops over lists C<@co & @bg>:

    pl '@co = map +($_, $_+8), 1..8; @bg = map +(($_)x2, ($_+60)x2), 40..47;
        echof "co:  fg;bg"."%5d"x16, @co;
        echof "%2d:  \e[%dm%d;   ".("\e[%dm%4d "x16)."\e[m", $_, ($_ + ($_ > 8 ? 81 : 29))x2, @bg for @co'
    pl '@co = map +($_, $_+8), 1..8; @bg = map +(($_)x2, ($_+60)x2), 40..47;
        ef "co:  fg;bg"."%5d"x16, @co;
        ef "%2d:  \e[%dm%d;   ".("\e[%dm%4d "x16)."\e[m", $_, ($_ + ($_ > 8 ? 81 : 29))x2, @bg for @co'

=back

=head2 Miscellaneous

=over

=item Split up numbers with commas, dots or underscores

Loop and print with line-end (B<-opl>) over remaining args in C<$_>.  If
reading from stdin or files, instead of arguments, use only B<-pl>.  After a
decimal dot, insert a comma before each 4th comma-less digit.  Then do the
same backwards from end or decimal dot:

    pl -opl '1 while s/[,.]\d{3}\K(?=\d)/,/; 1 while s/\d\K(?=\d{3}(?:$|[.,]))/,/' \
        12345678 123456789 1234567890 1234.5678 3.141 3.14159265358

The same for languages with a decimal comma, using either a dot or a space as spacer:

    pl -opl '1 while s/[,.]\d{3}\K(?=\d)/./; 1 while s/\d\K(?=\d{3}(?:$|[.,]))/./' \
        12345678 12345678 1234567890 1234,5678 3,141 3,141592653589
    pl -opl '1 while s/[, ]\d{3}\K(?=\d)/ /; 1 while s/\d\K(?=\d{3}(?:$|[ ,]))/ /' \
        12345678 12345678 1234567890 1234,5678 3,141 3,141592653589

The same for Perl style output:

    pl -opl '1 while s/[._]\d{3}\K(?=\d)/_/; 1 while s/\d\K(?=\d{3}(?:$|[._]))/_/' \
        12345678 123456789 1234567890 1234.5678 3.141 3.14159265358

=item Generate a random UUID

This gives a hex number with the characteristic pattern of dashes:

    pl '$x = "%04x"; echof "$x$x-$x-$x-$x-$x$x$x", map rand 0x10000, 0..7'
    pl '$x = "%04x"; ef "$x$x-$x-$x-$x-$x$x$x", map rand 0x10000, 0..7'

To be RFC 4122 conformant, the 4 version & 2 variant bits need to have
standard values.  Note that Shell strings can span more than one line:

    pl '@u = map rand 0x10000, 0..7; ($u[3] /= 16) |= 0x4000; ($u[4] /= 4) |= 0x8000;
        $x = "%04x"; echof "$x$x-$x-$x-$x-$x$x$x", @u'
    pl '@u = map rand 0x10000, 0..7; ($u[3] /= 16) |= 0x4000; ($u[4] /= 4) |= 0x8000;
        $x = "%04x"; ef "$x$x-$x-$x-$x-$x$x$x", @u'

=item DNS lookup

The C<h(osts)> function deals with the nerdy C<gethost...> etc. and outputs as
a hosts file.  The file is sorted by address type (localhost, link local,
private, public), version (IPv4, IPv6) and address.  You tack on any number of
IP-addresses or hostnames, either as Perl arguments or on the command-line via
C<@A(RGV)>:

    pl 'hosts qw(perl.org 127.0.0.1 perldoc.perl.org cpan.org)'
    pl 'hosts @ARGV' perl.org 127.0.0.1 perldoc.perl.org cpan.org
    pl 'h qw(perl.org 127.0.0.1 perldoc.perl.org cpan.org)'
    pl 'h @A' perl.org 127.0.0.1 perldoc.perl.org cpan.org

If you don't want it to be sorted, call C<h(osts)> for individual addresses:

    pl 'hosts for qw(perl.org 127.0.0.1 perldoc.perl.org cpan.org)'
    pl -o hosts perl.org 127.0.0.1 perldoc.perl.org cpan.org
    pl 'h for qw(perl.org 127.0.0.1 perldoc.perl.org cpan.org)'
    pl -o h perl.org 127.0.0.1 perldoc.perl.org cpan.org

If your input comes from a file, collect it in a list and perform at end:

    pl -lne 'hosts @list' 'push @list, $_' file
    pl -lne 'h @list' 'push @list, $_' file

=back
