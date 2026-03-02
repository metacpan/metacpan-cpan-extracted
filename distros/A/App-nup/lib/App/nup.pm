package App::nup;

our $VERSION = "1.07";

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
     -H  --filename         show filename headers (default: on)
     -G  --grid=#           grid layout (e.g., 2x3)
     -C  --pane=#           number of columns
     -R  --row=#            number of rows
     -P  --page=#           page height in lines
     -S  --pane-width=#     pane width (default: 85)
    --bs --border-style=#   border style (default: heavy-box)
    --ls --line-style=#     line style (none/truncate/wrap/wordwrap)
    --cm --colormap=#       color mapping (LABEL=COLOR)
         --[no-]page-number page number on border (default: on)
         --textconv[=EXT]   textconv for non-text files
         --pager=#          pager command (empty to disable)
         --no-pager         disable pager
         --white-board      black on white board
         --black-board      white on black board
         --green-board      white on green board
         --slate-board      white on dark slate board

=head1 VERSION

Version 1.07

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

=item B<-H>, B<--filename>

Show filename headers in file view mode. Enabled by default.
Use C<--no-filename> to disable.

=back

=head2 Layout Options

=over 4

=item B<-C> I<N>, B<--pane>=I<N>

Set the number of columns (panes).

=item B<-R> I<N>, B<--row>=I<N>

Set the number of rows.

=item B<-G> I<CxR>, B<--grid>=I<CxR>

Set grid layout. For example, C<-G2x3> creates 2 columns and 3 rows.

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
The C<PAGER> variable is not used to avoid an infinite loop when
C<PAGER> is set to C<nup>.
Use C<--pager=> (empty) or C<--no-pager> to disable pager.

=item B<--no-pager>

Disable pager.

=back

=head2 Less Environment Variables

C<nup> sets the following environment variables when they are not
already defined, to ensure proper display with C<less>:

=over 4

=item C<LESS>

Default: C<-R>.  Required for ANSI color sequences.

=item C<LESSANSIENDCHARS>

Default: C<mK>.  Recognizes SGR (C<m>) and erase line (C<K>)
sequences.

=back

=head1 EXAMPLES

Typical n-up usage:

    nup man nup                # view manual in n-up layout
    nup -C2 man perl           # 2 columns
    nup -G2x2 man perl         # 2x2 grid (4-up layout)
    nup -F man perl            # no pagination
    nup file1.txt file2.txt    # view files side by side
    nup -e ./script.sh         # force command mode for a file

Using C<nup> as a C<MANPAGER>:

    export MANPAGER="nup -A"

=head1 INSTALLATION

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
