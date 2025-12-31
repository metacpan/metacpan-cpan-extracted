package App::nup;

our $VERSION = "0.9906";

1;
=encoding utf-8

=head1 NAME

nup - N-up multi-column paged output for commands and files

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
     -F  --fold             fold mode (disable page mode)
     -H  --filename         show filename headers (default: on)
     -G  --grid=#           grid layout (e.g., 2x3)
     -C  --pane=#           number of columns
     -R  --row=#            number of rows
     -P  --page=#           page height in lines
     -S  --pane-width=#     pane width (default: 85)
    --bs --border-style=#   border style (default: heavy-box)
    --ls --line-style=#     line style (none/truncate/wrap/wordwrap)
    --cm --colormap=#       color mapping (LABEL=COLOR)
         --pager=#          pager command (empty to disable)
         --no-pager         disable pager
         --white-board      black on white board
         --black-board      white on black board
         --green-board      white on green board
         --slate-board      white on dark slate board

=head1 VERSION

Version 0.9906

=cut
=head1 DESCRIPTION

B<nup> is a simple wrapper script for C<optex -Mup>.  It provides a
convenient way to view files or run commands with N-up output
formatting using the L<App::optex::up> module.

=begin html

<p><img width="750" src="https://raw.githubusercontent.com/tecolicom/App-nup/main/images/nup.png"></p>

=end html

B<nup> automatically detects the mode based on the first argument:
if it is an existing file, file view mode is used; if it is an
executable command, command mode is used.  Use C<-e> option to
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
C<--fold>.  Automatically enabled when multiple files are
specified.  Single file or stdin input results in single column
output.

=item B<-D>, B<--document>

Enable document mode for ansicolumn.  This mode is optimized for
viewing documents with page-based layout.  Enabled by default.
Use C<--no-document> to disable.

=item B<-F>, B<--fold>

Enable fold mode (disable page mode).  In fold mode, the entire
content is split evenly across columns without pagination.  Page
mode is the default.

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

=item B<--white-board>, B<--black-board>, B<--green-board>, B<--slate-board>

Predefined color schemes for board-style display.

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

=head1 EXAMPLES

    nup man nup                # view manual in multi-column
    nup -C2 man perl           # 2 columns
    nup -G2x2 man perl         # 2x2 grid (4-up)
    nup -F man perl            # fold mode (no pagination)
    nup file1.txt file2.txt    # view files side by side
    nup -e ./script.sh         # force command mode for a file

=head1 INSTALLATION

Using L<cpanminus|https://metacpan.org/pod/App::cpanminus>:

    cpanm -n App::nup

=head1 DIAGNOSTICS

Both stdout and stderr of the command are merged and passed through
the output filter.  Error messages will appear in the paged output.

=head1 EXIT STATUS

The exit status of the executed command is not preserved because
the output is passed through a filter pipeline.

=head1 SEE ALSO

L<App::optex::up>, L<optex>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2025 Kazumasa Utashiro.

This software is released under the MIT License.
L<https://opensource.org/licenses/MIT>

=cut
