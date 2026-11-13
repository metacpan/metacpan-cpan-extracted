package App::nup;

our $VERSION = "1.14";

1;
=encoding utf-8

=head1 NAME

nup - n-up, multi-column paged output for commands and files

=head1 SYNOPSIS

    nup [ options ] file ...
    nup -e [ options ] command ...

     -h  --help             show help
         --version          show version
     -d  --debug            debug mode
     -n  --dryrun           dry-run mode
     -e  --exec             execute command mode
         --alias=CMD=OPTS   set command alias
     -V  --parallel         parallel view mode
     -D  --document         document mode (default: on)
     -F  --no-paginate      disable page mode
     -A  --auto-paginate    auto disable page mode for single column
     -L  --lateral          all pages in one row, scrolled sideways
     -H  --filename         show filename headers (default: on)
     -C  --pane=#[,#]       number of columns, and rows (e.g., 2,2)
     -P  --page=#           page height in lines
     -S  --pane-width=#     pane width (default: 85)
    --bs --border-style=#   border style (default: heavy-box)
    --ls --line-style=#     line style (none/truncate/wrap/wordwrap)
         --runin=#          run-in width for line breaking
         --runout=#         run-out width for line breaking
         --runlen=#         set both run-in and run-out
         --boundary=#       fold boundary: word, space or none
    --cm --colormap=#       color mapping (LABEL=COLOR)
         --[no-]page-number page number on border (default: on)
         --textconv[=EXT]   textconv for non-text files
         --pager=#          pager command (empty to disable)
         --no-pager         disable pager
     -T  --device=#         output device: tty, pdf, or a paper for PDF
                            (e.g., a4, a4p, a3l)
     -o  --output=FILE      output file (PDF when it ends with .pdf)
         --pdf-opts=#       options for ansi2pdf (e.g., "-l 80")
         --geometry         print the size and the kind of the device
         --white-board      black on white board
         --black-board      white on black board
         --green-board      white on green board
         --slate-board      white on dark slate board

=head1 VERSION

Version 1.14

=cut
=head1 DESCRIPTION

B<N-up> (command: C<nup>) is a multi-column paged output tool.
It provides a convenient way to view files or run commands in
n-up layout using the L<App::optex::up> module through C<optex>.

=begin html

<p><img width="750" src="https://raw.githubusercontent.com/tecolicom/App-nup/main/images/nup.png"></p>

=end html

C<nup> automatically detects the mode based on the first argument:
if it is an existing file, n-up file view mode is used; if it is an
executable command, n-up command mode is used.  Use C<-e> option to
force command mode when needed.

In file view mode, C<nup> stops parsing its own options at the first
file name and hands the file names and everything after them to
L<ansicolumn> unchanged.  Options of C<ansicolumn> that C<nup> does
not provide can therefore be given after the file names:

    nup -C2 file1.txt file2.txt -w 170

Here C<-w 170> sets the output width for C<ansicolumn>.  To set the
width when no terminal is available, the C<COLUMNS> environment
variable works in both modes; see L</Terminal Size>.

=head1 OPTIONS

=head2 General Options

=over 4

=item B<-h>, B<--help>

Show help message.

=item B<--version>

Show version.

=item B<-d>, B<--debug>

Enable debug mode.

=item B<-n>, B<--dryrun>

Dry-run mode. Show the command without executing.

=item B<-e>, B<--exec>

Force command execution mode. Normally the mode is auto-detected,
but use this option when you want to execute a file as a command.

=item B<--alias>=I<NAME>=I<CMD> I<OPTS>...

Define command alias. When a command matches I<NAME>, it is replaced
by I<CMD> with specified I<OPTS>.  This can be used to add default
options or to substitute a different command.
Multiple C<--alias> options can be specified.

Default aliases:

    bat     bat --style=plain --color=always
    batcat  batcat --style=plain --color=always
    mdcat   mdcat --ansi
    rg      rg --color=always
    tree    tree -C

Example:

    nup --alias='grep=ggrep --color=always' grep pattern file

=item B<-V>, B<--parallel>

Enable parallel view mode for ansicolumn.  In this mode, each file
is displayed in its own column without pagination, similar to
C<--no-paginate>.  Automatically enabled when multiple files are
specified.  Single file or stdin input results in single column
output.

=item B<-D>, B<--document>

Enable document mode for ansicolumn.  This mode is optimized for
viewing documents with n-up page-based layout.  Enabled by default.
Use C<--no-document> to disable.

=for comment
--fold is accepted as an undocumented alias for backward compatibility

=item B<-F>, B<--no-paginate>

Disable page mode.  Without pagination, the entire content is
split evenly across columns.  Page mode is the default; use
B<--paginate> to re-enable if needed.

=item B<-A>, B<--auto-paginate>

Automatically disable page mode when only one column fits the
terminal.  This is useful when using C<nup> as C<MANPAGER>,
where single-column page splitting wastes space.

=item B<-L>, B<--lateral>

Put all the pages in one row, however wide it becomes, instead of
filling the screen with as many panes as fit and going on below.
The row is as high as the screen, and it is seen by scrolling
sideways in the pager.

The screen shows the same number of panes as without this option:
as many as fit, or the number given by C<-C>.  With C<-C4>, four
pages are on the screen at a time, each a quarter of it wide.

When the pager is C<less>, C<nup> adds C<< -S --shift=I<N> --rscroll=- >>
to it, where I<N> is the width of a pane: the lines are
not wrapped, and the right and left arrow keys move by one page.
C<h> and C<l> move to the left and to the right as well, and C<H>
and C<L> go to the left end and to the right end of the row: C<nup>
sets the C<LESSKEY_CONTENT> environment variable to

    h left-scroll;l right-scroll;H no-scroll;L end-scroll

when it is not set.  C<h> and C<H> are the help of C<less>, which
is not on a key then: set C<LESSKEY_CONTENT> yourself to keep it.  The
options are added to C<NUP_PAGER>, C<NUP_PAGE_PAGER> and C<--pager>
as well when the command is C<less>; another pager is used as it is,
and has to be told not to wrap the lines.

What works depends on the version of C<less>, and the build of
C<less> in tecolicom/tap keeps the panes at the edge of the screen in
a search as well; see L</LESS>.

    nup -L man perlfunc
    nup -L -C4 README.md

This is for the pages of one input.  It cannot be used with more
than one file, C<--parallel>, C<--no-paginate>, rows (C<-R>,
C<-C2,2>, C<-G>) or PDF output (C<-T>, C<-o> with C<.pdf>).  C<--auto-paginate> is ignored.  The pages are laid out
once, for the height of the terminal at that time.

=item B<-H>, B<--filename>

Show filename headers in file view mode. Enabled by default.
Use C<--no-filename> to disable.

=back

=head2 Layout Options

=over 4

=item B<-C> I<C>[,I<R>], B<--pane>=I<C>[,I<R>]

Set the number of columns (panes), and the number of rows when it is
given after a comma.  For example, C<-C2> creates 2 columns, and
C<-C2,3> creates 2 columns and 3 rows.

=item B<-R> I<N>, B<--row>=I<N>

Set the number of rows.
This option is kept for compatibility and may be removed in the
future.

=item B<-G> I<CxR>, B<--grid>=I<CxR>

Set grid layout.  C<-G2x3> is equivalent to C<-C2,3>.
This option is kept for compatibility and may be removed in the
future.

=item B<-P> I<N>, B<--page>=I<N>

Set the page height in lines.

=item B<-S> I<N>, B<--pane-width>=I<N>

Set the pane width in characters. Default is 85.

=back

=head2 Style Options

=over 4

=item B<--bs>=I<STYLE>, B<--border-style>=I<STYLE>

Set the border style. Default is C<heavy-box>.

=item B<--ls>=I<STYLE>, B<--line-style>=I<STYLE>

Set the line style. Available: C<none>, C<truncate>, C<wrap>, C<wordwrap>.

=item B<--runin>=I<N>, B<--runout>=I<N>, B<--runlen>=I<N>

Set the run-in and run-out widths that L<ansicolumn> uses for line
breaking (kinsoku) when it folds long lines.  C<--runlen> sets both.
They are given to ansicolumn after the values in F<~/.ansicolumnrc>,
so they take precedence.  Without them, ansicolumn uses the values in
F<~/.ansicolumnrc>, or 2.

=item B<--boundary>=C<word>|C<space>|C<none>

Set where L<ansicolumn> may break a line when it folds long lines, as
its C<--boundary> option: C<word> does not break inside an
alphanumeric word, C<space> not inside a sequence of non-space
characters, and C<none> breaks anywhere.  Like C<--runin>, it is
given to ansicolumn after F<~/.ansicolumnrc>.  Without it, ansicolumn
uses the value in the rc file, or C<word> in document mode.

=item B<--cm>=I<SPEC>, B<--colormap>=I<SPEC>

Set color mapping. Specify as C<LABEL=COLOR> (e.g., C<--cm=BORDER=R>).
Available labels: C<TEXT>, C<BORDER>.

=item B<-->[B<no->]B<page-number>

Show page number on the bottom border of each column.  Enabled by
default.  Use C<--no-page-number> to disable.

=item B<--white-board>, B<--black-board>, B<--green-board>, B<--slate-board>

Predefined color schemes for board-style display.

=back

=head2 Text Conversion

=over 4

=item B<--textconv>[=I<EXT,...>]

Enable text conversion for non-text files using
L<App::optex::textconv>.  When any of the specified file extensions
are found in the arguments, the C<textconv> module is loaded to
convert them to text before display.

Default extensions:
C<pdf,docx,docm,pptx,pptm,xlsx,xlsm,jpg,jpeg>.

Use C<--textconv=none> to disable.

=back

=head2 Pager Options

=over 4

=item B<--pager>=I<COMMAND>

Set the pager command. Default is C<NUP_PAGER> or C<less -F +Gg>.
When page mode is active, C<NUP_PAGE_PAGER> takes precedence over
C<NUP_PAGER>.
Viewing multiple files (or C<-V> parallel view) produces parallel
layout which has no page structure, so C<nup> disables page mode
and C<NUP_PAGE_PAGER> is not used there.
The C<PAGER> variable is not used to avoid an infinite loop when
C<PAGER> is set to C<nup>.
C<+Gg> makes C<less> read all input before displaying, so that C<-F>
and the percentage work; see L</LESS> for the settings of C<less>.

Use C<--pager=> (empty) or C<--no-pager> to disable pager.

=item B<--no-pager>

Disable pager.

=back

=head2 PDF Output

=over 4

=item B<-T> I<DEVICE>, B<--device>=I<DEVICE>

Set the device to show the output on.  The default is C<tty>, the
terminal.  Any other device is a paper, and the output is printed to
PDF by C<ansi2pdf>, instead of being shown on the terminal.

The name of a paper is the one for the C<-p> option of C<ansi2pdf>,
such as C<a4>, C<a3>, C<b5> or C<letter>.  A paper is used in
landscape orientation.  The letter C<p> or C<l> after the name gives
the orientation: C<a4p> is A4 in portrait, and C<a4l> is A4 in
landscape.  The device C<pdf> is the default paper of C<ansi2pdf>, A4.

    nup -T a4 man nup > nup.pdf     # A4, landscape
    nup -T a4p -C1 man nup | lpr    # A4, portrait

A sheet of paper takes the place of the terminal, and C<ansi2pdf>
takes the place of the pager.  The size of a sheet in columns and
lines is asked to C<ansi2pdf>, the output is formatted for that size
in the same way as for a terminal, and each screen is printed on a
sheet as it is.  The default is a landscape A4 sheet of 60 lines,
which has room for two panes of the default width.

=item B<-o> I<FILE>, B<--output>=I<FILE>

Write the output to I<FILE>.  When the name ends with C<.pdf>, the
output is PDF without C<-T> as well.

    nup -o nup.pdf man nup          # A4, landscape
    nup -T a3 -o nup.pdf man nup    # A3, landscape

Otherwise, what is shown on the terminal is written to the file as it
is, with the ANSI sequences and in the size of the terminal, and the
pager is not used.  C<-T tty> does so for a name ending with C<.pdf>
as well.

    nup -o nup.txt man nup          # the same as --no-pager > nup.txt

=item B<--geometry>

Print the size of the device in columns and lines and its kind,
C<tty> or C<pdf>, and exit.  No file is read and no command is run.

    $ nup -T a4p --geometry
    100 60 pdf
    $ nup -o nup.pdf -P 80 --geometry
    275 80 pdf

For a paper, the size is that of a sheet, which follows C<-T>, C<-o>,
C<-P>, the number of rows, C<--pdf-opts> and C<-w> of C<ansicolumn>
given after the file names.  For the terminal, it is the size of the
terminal.  This is for a program that formats text before giving it
to C<nup>, as L<mdee(1)|App::mdee> does.

=item B<--pdf-opts>=I<OPTIONS>

Give other options to C<ansi2pdf>, such as the number of lines on a
sheet, the margin and the fonts.  They are given after the paper, so
they take precedence.

    nup -o nup.pdf --pdf-opts='-l 80 -m 15' man nup

=back

The C<-P> option sets the number of lines of a page for PDF as well:
a sheet has that many lines for each row.  The C<-w> option of
C<ansicolumn>, given after the files or the command, sets the number
of columns of a sheet.  The font size follows them, and the one that
is not given is decided to fill the sheet.  With neither of them, a
sheet has 60 lines.

    nup -o nup.pdf -P 80 man nup         # 80 lines on a sheet
    nup -o nup.pdf -C2,2 -P 40 man nup   # 2x2 pages of 40 lines
    nup -o nup.pdf -C3 file -w 300       # 300 columns on a sheet

=head2 Terminal Size

The terminal size is taken from the controlling terminal
(C</dev/tty>).  When it is not available, as when C<nup> is run
without a terminal, the C<COLUMNS> environment variable gives the
width (default 80), and C<LINES> gives the height (default 24) used
to split the screen when the number of rows is set, as in C<-C2,2>:

    COLUMNS=170 nup -C2 file1.txt file2.txt

=head1 LESS

C<nup> is made to be used with C<less>.  It sets environment
variables for C<less>, and adds options to it for C<-L>.  Some of them
need a recent version, and a patched build of C<less> does more for
the pages of C<nup>.

=head2 Environment Variables

C<nup> sets the following environment variables when they are not
already defined, to ensure proper display with C<less>:

=over 4

=item C<LESS>

Default: C<-R>.  Required for ANSI color sequences.

=item C<LESSANSIENDCHARS>

Default: C<mK>.  Recognizes SGR (C<m>) and erase line (C<K>)
sequences.

=back

=head2 Versions

=over 4

=item C<less> 590

C<--file-size> makes C<less> read all input before displaying, as
C<+Gg> of the default pager does.  The C<less> 581 of macOS does not
have it, so C<+Gg> is the default.  Set C<NUP_PAGER> to use it:

    export NUP_PAGER="less --file-size"

=item C<less> 661

C<LESSKEY_CONTENT> is read, which C<-L> uses to put the keys C<h>,
C<l>, C<H> and C<L>.  An older C<less> ignores it.

=item C<less> 710

C<right-limit-scroll> stops at the right end of the lines.  C<-L>
puts it on C<l>, in place of C<right-scroll>, which goes on past the
end.

=back

C<-L> runs C<less --align-shift --version> to see the version of
C<less>, and whether it has the option below.

=head2 The Build in tecolicom/tap

L<tecolicom/tap|https://github.com/tecolicom/homebrew-tap> has a build
of C<less> with patches for the pages of C<nup>
(L<kaz-utashiro/less|https://github.com/kaz-utashiro/less>).  It adds
two options:

=over 4

=item B<--align-record>=I<N>

A search shows the whole record (page) that has the match from the
top of the screen, instead of the matching line, so that the pages
stay in place.  I<N> is the lines of a record; C<-1> is the height
of the screen less the prompt line, which is the height of the pages
of C<nup>.  A repeated search goes on from the next record.

=item B<--align-shift>

The horizontal shift stays at a multiple of the C<--shift> amount, the
width of a pane with C<-L>.  A search, and the right end, keep the
panes at the edge of the screen, and C<n> and C<N> go through the
panes that have a match, one by one.  C<-L> adds this option when the
C<less> has it.

=back

Install it with Homebrew.  It cannot be installed together with the
C<less> of Homebrew itself, which has the same command name:

    brew install tecolicom/tap/less

Then use C<--align-record> for the pages:

    export NUP_PAGER="less --file-size"
    export NUP_PAGE_PAGER="less --file-size --align-record=-1"

=head1 EXAMPLES

Typical n-up usage:

    nup man nup                # view manual in n-up layout
    nup -C2 man perl           # 2 columns
    nup -C2,2 man perl         # 2x2 grid (4-up layout)
    nup -F man perl            # no pagination
    nup -L man perl            # one row of pages, scrolled sideways
    nup -L -C4 man perl        # four pages on the screen at a time
    nup file1.txt file2.txt    # view files side by side
    nup -C2 a.txt b.txt -w 170 # 2 columns, width 170 (ansicolumn -w)
    nup -e ./script.sh         # force command mode for a file
    nup -o nup.pdf man nup     # print to PDF (requires ansi2pdf)
    nup -T a4p -C1 file | lpr  # print on A4 in portrait

Using C<nup> as a C<MANPAGER>:

    export MANPAGER="nup -A"

=head1 INSTALLATION

=head2 Homebrew

Use L<tecolicom/tap|https://github.com/tecolicom/homebrew-tap>:

    brew tap tecolicom/tap
    brew install app-nup

See L</LESS> for the build of C<less> in the same tap.

=head2 CPAN

Using L<cpanminus|https://metacpan.org/pod/App::cpanminus>:

    cpanm -n App::nup

=head1 DIAGNOSTICS

Both stdout and stderr of the command are merged and passed through
the n-up output filter.  Error messages will appear in the paged output.

=head1 EXIT STATUS

The exit status of the executed command is not preserved because
the output is passed through a filter pipeline.

=head1 SEE ALSO

L<App::optex::up> (bundled), L<optex>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2025-2026 Kazumasa Utashiro.

This software is released under the MIT License.
L<https://opensource.org/licenses/MIT>

=cut
