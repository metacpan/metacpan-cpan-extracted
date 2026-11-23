package App::optex::up;

our $VERSION = "1.23";

=encoding utf-8

=head1 NAME

up - optex module for multi-column paged output

=head1 SYNOPSIS

    optex -Mup command ...

    optex -Mup -C2 -- command ...

    optex -Mup -C2,2 -- command ...

=head1 DESCRIPTION

B<up> is a module for the B<optex> command that pipes the output
through L<App::ansicolumn> for multi-column formatting and a pager.
The name comes from the printing term "n-up" (2-up, 3-up, etc.) which
refers to printing multiple pages on a single sheet.

The module automatically calculates the number of columns based on the
terminal width divided by the pane width (default 85 characters).
The terminal size is taken from the controlling terminal (C</dev/tty>);
when it is not available, the C<COLUMNS> environment variable gives the
width (default 80), and C<LINES> gives the height (default 24) used
when the number of rows is set, as in C<-C2,2>.

Both stdout and stderr are merged and passed through the filter, so
error messages are also displayed in the multi-column paged output.

The pager command is taken from the C<NUP_PAGER> environment variable
if set, otherwise defaults to C<less -F +Gg>.  When page mode is
active, the C<NUP_PAGE_PAGER> environment variable is consulted
first.
The environment variables are named after the L<nup> command, a
wrapper for this module.  The C<PAGER> variable is not used to avoid
an infinite loop when C<PAGER> is set to C<nup>.  Use the C<--pager>
option to specify a different pager on the command line.

The C<-F> option causes C<less> to exit immediately if the output
fits on one screen.  C<+Gg> causes C<less> to read all input before
displaying, which may take time for large output, but prevents empty
trailing pages from being shown.
The C<--file-size> option of C<less> 590 (June 2021) and later does
the same as C<+Gg>; it is not the default because older versions,
such as the C<less> 581 that comes with macOS, do not have it and
print an error message for it.  Set C<NUP_PAGER> to use it:

    export NUP_PAGER="less --file-size"

=head1 OPTIONS

Module options must be specified before C<--> separator.

=over 4

=item B<-C> I<C>[,I<R>], B<--pane>=I<C>[,I<R>]

Set the number of columns (panes) directly, and the number of rows
when it is given after a comma.  For example, C<-C2> creates 2
columns, and C<-C2,3> creates a 2-column, 3-row layout (6-up).  The
page height is calculated by dividing the terminal height by the
number of rows.

=item B<-R> I<N>, B<--row>=I<N>

Set the number of rows.
This option is kept for compatibility and may be removed in the
future.

=item B<-G> I<CxR>, B<--grid>=I<CxR>

Set the grid layout.  C<--grid=2x3> or C<--grid=2,3> is equivalent to
C<-C2,3>.
This option is kept for compatibility and may be removed in the
future.

=item B<-S> I<N>, B<--pane-width>=I<N>

Set the pane width in characters.  Default is 85.  When B<--pane> is
not specified, the number of panes is calculated by dividing the
terminal width by this value.

=item B<--bs>=I<STYLE>, B<--border-style>=I<STYLE>

Set the border style for ansicolumn.  Default is C<heavy-box>.
See L<App::ansicolumn> for available styles.

=item B<--no-paginate>

Disable page mode.  Without pagination, the entire content is
split evenly across columns.  Page mode is the default.

Note that L<App::ansicolumn> uses parallel layout when multiple
files are given, which has no page structure.  Specify this option
in such cases so that C<NUP_PAGE_PAGER> is not used (the L<nup>
command does this automatically).

=item B<-A>, B<--auto-paginate>

Automatically disable page mode when only one column fits the
terminal.

=item B<-L>, B<-->[B<no->]B<lateral>

Put all the pages in one row, however wide it becomes.  The screen
shows as many panes as without this option, as many as fit or the
number given by C<-C>, and the row goes on to the right: the panes
are given to C<ansicolumn> by their width (C<-S>), the width of the
screen divided by that number, in a very large output width.

When the pager is C<less>, C<< -S --shift=I<N> --rscroll=- >> is
added to it, where I<N> is the width of a pane, so that the lines are
not wrapped and the arrow keys move by one page.  Keys are added to
C<LESSKEY_CONTENT> (less 661 or later), after the keys of the user,
or those of C<NUP_LESSKEY> in their place, none when it is empty:
C<h> and C<l>, C<,> and C<.>, and ESC-( and ESC-), move by one page
as the arrow keys, C<H> and C<L> go to the left and the right end,
and so do C<g> and C<G>, C<E<lt>> and C<E<gt>>, and space, C<f> and C<b>
move to the right and to the left by the panes on the screen, as do
C<j> and C<k>, the down and up arrows, C<d> and C<u>, C<^D> and
C<^U>, and the return key, and C<J> and C<K> go to the right and the
left end.  With less 710 or
later, C<l>, C<.>, the right arrow and ESC-) stop at the right end.
The build of less in tecolicom/tap does more; see
L<nup/"LESS INTEGRATION">.

With C<--no-paginate>, it is for the files side by side, as the
L<nup> command gives it for more than one file: each file is a column
of its own, the columns go on to the right, and only C<h>, C<l>, C<,>,
C<.>, the arrow keys, ESC-( and ESC-), C<H>, C<L>, C<E<lt>> and
C<E<gt>> are put in C<LESSKEY_CONTENT>.  One input without pages
makes a column of each line.

It cannot be used with rows (C<-R>, C<-C2,2>, C<-G>) or PDF output,
and C<--auto-paginate> is ignored.

Without this option, when the output has pages and the pager is
C<less>, C<j> and C<k>, the down and up arrows, C<d> and C<u>, C<^D>
and C<^U>, and the return key are put in C<LESSKEY_CONTENT> to move by the screen as space and C<b> do, and
C<J> and C<K> to go to the last and the first page, unless
C<NUP_LESSKEY> is set.

=item B<--pager>=I<COMMAND>

Set the pager command, overriding the environment variables.
Default is C<NUP_PAGE_PAGER> (page mode only), C<NUP_PAGER>, or
C<less -F +Gg>.

=item B<--no-pager>

Disable pager.  Output goes directly to stdout.

=item B<--device>=I<DEVICE>, B<-T> I<DEVICE>

Set the device to show the output on.  The default is C<tty>, the
terminal.  Any other device is a paper, and the output is printed to
PDF by C<ansi2pdf>.  The name of a paper is the one for the C<-p>
option of C<ansi2pdf>, as C<a4> or C<a3>, and C<p> or C<l> after it
gives the orientation, as C<a4p> for A4 in portrait.  A paper without
it is used in landscape.  The device C<pdf> is the default paper of
C<ansi2pdf>.

The size of a sheet of paper in columns and lines, which
C<ansi2pdf --geometry> tells, is used in place of the terminal size,
and C<ansi2pdf> is used in place of the pager.  Each screen is
printed on a sheet as it is.

=item B<--output>=I<FILE>, B<-o> I<FILE>

Write the output to I<FILE>.  When the name ends with C<.pdf>, the
output is PDF without C<--device> as well.  Otherwise, what is shown
on the terminal is written to the file as it is, with the ANSI
sequences, and the pager is not used.

The page height given by C<-P> (C<--page>) is the number of lines of
a page here too: a sheet has that many lines for each row.  The width
given by C<-w> (C<--width>) is the number of columns of a sheet.  The
font size follows them, and the one that is not given is decided to
fill the sheet.  The default is 60 lines on a sheet.

=item B<--geometry>

Print the size of the device in columns and lines and its kind,
C<tty> or C<pdf>, as C<206 60 pdf>, and exit without running the
command.  For a paper, the size is that of a sheet, which follows
C<--device>, C<--output>, C<--page>, C<--width>, the number of rows
and C<--pdf-opts>.  For the terminal, it is the size of the terminal.

=item B<--pdf-opts>=I<OPTIONS>

Give other options to C<ansi2pdf>, such as C<-l 80> for the number
of lines on a sheet and C<-m 15> for the margin.  They are given
after the paper, so they take precedence.

=item B<--highlight>=I<NAME>

When the command is C<ansicolumn>, give it the option
C<--highlight=>I<NAME>: the files are read through the highlighter of
the name, and shown with syntax highlight.  The highlighters are
those of L<Text::ANSI::Highlight>: C<pandoc>, C<sourcehighlight>
(C<gnu>) and C<skylighting> (C<sky>).  A style of the highlighter can
be after the name and a colon (C<pandoc:breezedark>).  Nothing is done
when L<Text::ANSI::Highlight::IO> is not installed.

=item Other options

Any unrecognized options are passed through to L<App::ansicolumn>.
For example, C<--cm> option can be used to set colormap:

    optex -Mup --cm=BORDER=R -- command

See L<App::ansicolumn> for available options.

=back

=head1 EXAMPLES

Display perldoc output in multiple columns:

    optex -Mup perldoc App::optex::up

=begin html

<p><img width="750" src="https://raw.githubusercontent.com/tecolicom/App-nup/main/images/nup.png">

=end html

List files in multiple columns with pager:

    optex -Mup ls -l

Use 2 columns:

    optex -Mup -C2 -- ls -l

Set pane width to 100:

    optex -Mup -S100 -- ls -l

Use 2x2 grid (4-up):

    optex -Mup -C2,2 -- ls -l

No pagination:

    optex -Mup --no-paginate -- man perl

Use a different border style:

    optex -Mup --bs=round-box -- ls -l

Output without pager (useful for piping):

    optex -Mup --no-pager -C2 -- ls -l | head

Truncate long lines:

    optex -Mup --ls=truncate -- ps aux

=head1 INSTALL

=head2 Homebrew

Use L<tecolicom/tap|https://github.com/tecolicom/homebrew-tap>:

    brew tap tecolicom/tap
    brew install app-nup

=head2 CPANMINUS

    cpanm App::nup

=head1 SEE ALSO

L<App::nup>, L<https://github.com/tecolicom/App-nup>

L<App::optex>, L<https://github.com/kaz-utashiro/optex>

L<App::ansicolumn>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright © 2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use v5.16;
use warnings;

use List::Util qw(max);
use Getopt::EX::Config;
use Term::ReadKey;

sub term_size {
    my @size;
    if (open my $tty, ">", "/dev/tty") {
        @size = GetTerminalSize $tty, $tty;
    }
    @size;
}

sub shell_escape {
    $_[0] =~ s/([<>&|;'"\$`\\ ])/\\$1/gr;
}

# Take the number given to an option (-X N, -XN, --name N, --name=N) out
# of the options for ansicolumn, and return it.
sub take_option {
    my($argv, $short, $long) = @_;
    my $value;
    for (my $i = 0; $i < @$argv; $i++) {
        if ($argv->[$i] =~ /^(?:-$short|--$long)$/
            and $i < $#$argv and $argv->[$i + 1] =~ /^\d+$/) {
            (undef, $value) = splice @$argv, $i--, 2;
        }
        elsif ($argv->[$i] =~ /^(?:-$short|--$long=)(\d+)$/) {
            $value = $1;
            splice @$argv, $i--, 1;
        }
    }
    $value;
}

my $config = Getopt::EX::Config->new(
    'grid'         => undef,
    'pane-width'   => 85,
    'pane'         => undef,
    'row'          => undef,
    'border-style' => 'heavy-box',
    'paginate'     => 1,
    'auto-paginate' => undef,
    'lateral'      => undef,
    'pager'        => undef,
    'no-pager'     => undef,
    'device'       => undef,
    'output'       => undef,
    'pdf-opts'     => '',
    'geometry'     => undef,
    'highlight'    => undef,
);

# The number of panes that the row of --lateral has room for.
our $LATERAL_PANES = 10000;

# What the less command knows: its version, and whether it has the
# --align-shift option of the build in tecolicom/tap.  Both are told by
# one run with --version, since an unknown option does not make less
# fail, but only gives a message.
# Add the keys to LESSKEY_CONTENT.  They go after those of the user,
# in a #command section of their own: the later of the same keys wins,
# and the keys of ~/.lesskey are read before LESSKEY_CONTENT.
sub add_lesskey {
    my $keys = shift;
    return if $keys eq '';
    my $user = $ENV{LESSKEY_CONTENT} // '';
    $ENV{LESSKEY_CONTENT} = $user eq '' ? $keys : "$user\n#command\n$keys";
}

sub less_features {
    my $less = shift;
    my $pid = open(my $fh, '-|') // return (0, 0);
    if ($pid == 0) {
        open STDERR, '>&', \*STDOUT;
        open STDIN, '<', '/dev/null';
        exec $less, '--align-shift', '--version' or exit 1;
    }
    my $out = do { local $/; <$fh> } // '';
    close $fh;
    my($version) = $out =~ /^less (\d+)/m or return (0, 0);
    ($version, $out !~ /There is no -*align-shift option/);
}

# Size of a sheet of paper in columns and lines, asked to ansi2pdf.
sub pdf_size {
    my $command = shift;
    my $geometry = qx($command --geometry) // '';
    $geometry =~ /^(\d+) (\d+)$/
        or die "Failed to get the page geometry from ansi2pdf.\n";
    ($1, $2);
}

sub finalize {
    my($mod, $argv) = @_;
    $config->configure('pass_through')->deal_with($argv,
        'grid|G=s', 'pane-width|S=i', 'pane|C=s', 'row|R=i',
        'border-style|bs=s', 'paginate!',
        'auto-paginate|autopaginate|A',
        'lateral|L!',
        'pager:s', 'no-pager|nopager',
        'device|T=s', 'output|o=s',
        'pdf-opts=s', 'geometry', 'highlight=s');
    my @passthru = $config->argv;

    ##
    ## Panes and rows: -C C[,R] and -G CxR
    ##

    if (defined(my $pane = $config->{pane})) {
        my($c, $r) = $pane =~ /^(\d+)(?:,(\d+))?$/
            or die "Invalid pane format: $pane (expected C or C,R)\n";
        $config->{pane} = $c;
        $config->{row} //= $r;
    }

    if (my $grid = $config->{grid}) {
        my($c, $r) = $grid =~ /^(\d+)[x,](\d+)$/
            or die "Invalid grid format: $grid (expected CxR or C,R)\n";
        $config->{pane} //= $c;
        $config->{row}  //= $r;
    }

    ##
    ## Device: -T and -o
    ##
    ## The device is the terminal (tty), or a paper (a4, a4p, ... or
    ## "pdf" for the default one).  For a paper, a sheet takes the
    ## place of the screen and ansi2pdf that of the pager.  A file
    ## name ending with .pdf chooses PDF by itself.
    ##

    my $device = $config->{device};
    my $output = $config->{output};
    $device //= 'pdf' if defined $output and $output =~ /\.pdf$/i;
    $device //= 'tty';

    # -o with the terminal: write what would be shown on it
    if (defined $output and $device eq 'tty' and not $config->{geometry}) {
        $config->{pager} = 'cat > ' . shell_escape($output);
        $config->{'no-pager'} = undef;
    }

    ##
    ## --lateral
    ##
    ## All the pages are in one row, scrolled sideways by the pager.
    ## Without pages (--no-paginate), each file is a column of the row.
    ## There are no rows and no sheet of paper.
    ##

    my $lateral = $config->{lateral};
    if ($lateral) {
        my $with = defined $config->{row}  ? 'the number of rows (-R, -C, -G)'
                 : $device ne 'tty'        ? 'PDF output (-T, -o)'
                 : undef;
        die "--lateral cannot be used with $with.\n" if $with;
    }

    ##
    ## ansi2pdf command, for a paper
    ##

    my $ansi2pdf;
    if ($device ne 'tty') {
        $ansi2pdf = join ' ', 'ansi2pdf -C1 --no-border -L',
            ($device eq 'pdf' ? () : '-p ' . shell_escape($device)),
            $config->{'pdf-opts'};

        # -P (lines of a page) and -w (columns of a sheet) decide the
        # size of a sheet; ansi2pdf decides the one not given.  They
        # are among the options of this module, or among the arguments
        # of ansicolumn in file view mode (nup FILE -w 100).
        my @lists = (\@passthru,
                     @$argv && $argv->[0] eq 'ansicolumn' ? $argv : ());
        my($page)  = grep defined, reverse map take_option($_, 'P', 'page'),  @lists;
        my($width) = grep defined, reverse map take_option($_, 'w', 'width'), @lists;
        $ansi2pdf .= ' -l ' . $page * ($config->{row} || 1) if $page;
        $ansi2pdf .= " -w $width" if $width;
    }

    ##
    ## Size of the screen or the sheet, and the layout in it
    ##

    my($term_width, $term_height) = $ansi2pdf ? pdf_size($ansi2pdf) : term_size();
    $term_width  ||= $ENV{COLUMNS} || 80;
    $term_height ||= $ENV{LINES}   || 24;

    my $pane_width   = $config->{'pane-width'};
    my $cols         = $config->{pane} // max(1, int($term_width / $pane_width));
    my $rows         = $config->{row};
    my $height       = defined $rows ? int(($term_height - 1) / $rows) : undef;

    if ($ansi2pdf) {
        # a sheet has no line for the pager, and the pages fill it
        $height = int($term_height / ($rows || 1));
        my $lines = $height * ($rows || 1);
        $config->{pager} = "$ansi2pdf -w $term_width -l $lines"
            . (defined $output ? ' -o ' . shell_escape($output) : '');
        $config->{'no-pager'} = undef;
    }

    ##
    ## --geometry: print the size and the kind of the device, and exit
    ##

    if ($config->{geometry}) {
        my $lines = $ansi2pdf ? $height * ($rows || 1) : $term_height;
        say join ' ', $term_width, $lines, $ansi2pdf ? 'pdf' : 'tty';
        exit 0;
    }

    ##
    ## Pager
    ##

    my $border_style = $config->{'border-style'};
    my $no_page      = !$config->{paginate}
        || ($config->{'auto-paginate'} && $cols <= 1 && !$lateral);

    # +Gg makes less read all the input first, so that -F and the
    # percentage work.  less 590 has --file-size for this, but the
    # less 581 of macOS does not: +Gg is the default.
    my $pager        = $config->{pager} //
        ((!$no_page && $ENV{NUP_PAGE_PAGER}) || $ENV{NUP_PAGER} || 'less -F +Gg');

    ##
    ## --lateral with less: options and keys
    ##
    ## less shows the row without wrapping (-S), and shifts it by the
    ## width of a pane (--shift).  --rscroll=- shows the text in the
    ## last column, where less puts a mark for the lines that go on.
    ##
    ## What less can do, by its version:
    ##
    ##   661  reads LESSKEY_CONTENT (an older one ignores it, and H is
    ##        the help as usual)
    ##   710  has right-limit-scroll, which stops at the right end (an
    ##        older one takes the name for an error: use right-scroll)
    ##   tap  the build in tecolicom/tap has --align-shift, which keeps
    ##        the shift at the boundaries of the panes
    ##

    my $lateral_width = max(1, int($term_width / $cols));

    if ($lateral and $pager =~ m{^\s*((?:\S*/)?less)(?:\s|$)}) {
        my($version, $align_shift) = less_features($1);

        # +Gg is not for the row: g and G are its keys below, and G,
        # the key of noaction with --align-shift, would come after g
        # and leave less at the right end.
        $pager =~ s/\s\+Gg(?=\s|$)//;
        $pager .= " -S --shift=$lateral_width --rscroll=-";
        $pager .= " --align-shift" if $align_shift;

        # one page to the right: l, ., the right arrow and ESC-)
        my $right = $version >= 710 ? 'right-limit-scroll' : 'right-scroll';

        # The panes on the screen to the right and to the left: space
        # and b.  With --align-shift, it is a count given to the key;
        # without, a count would change the shift, so the key is typed
        # as many times.  The key is ESC-) or ESC-(, because the arrow
        # keys cannot be written in the string of noaction.
        my $n = max(1, int($term_width / $lateral_width));
        my($fwd, $back) = map { $align_shift ? "$n$_" : $_ x $n } '\e)', '\e(';

        # The right end: G and >.  With --align-shift, the count makes
        # the last screen the same as without --lateral.
        my $end = $align_shift ? "noaction ${n}L" : 'end-scroll';

        # NUP_LESSKEY gives the keys in place of these; an empty one
        # gives none.
        my $keys = $ENV{NUP_LESSKEY} // join ';',

            # one page: h l , . and the arrows
            "h left-scroll;l $right;, left-scroll;. $right",
            "\\kl left-scroll;\\kr $right;\\e( left-scroll;\\e) $right",

            # the ends of the row
            "H no-scroll;L end-scroll",

            $config->{paginate} ? (

                # with pages: g G < > go to the ends as H and L
                "g no-scroll;G $end;< no-scroll;> $end",

                # the panes on the screen: space, f and b, and the keys
                # to go down and up, since a page has the height of
                # the screen and there is nothing below it
                "\\  noaction $fwd;f noaction $fwd;b noaction $back",
                "j noaction $fwd;k noaction $back",
                "\\kd noaction $fwd;\\ku noaction $back",
                "d noaction $fwd;u noaction $back",
                "^D noaction $fwd;^U noaction $back",
                "\\r noaction $fwd;\\n noaction $fwd",

                # the ends, in the direction of j and k
                "J $end;K no-scroll",

            ) : (

                # without pages: the columns go on downward, and the
                # keys move up and down as usual.  g and G are the
                # first and the last line; < and > go to the ends.
                "< no-scroll;> end-scroll",

            );

        add_lesskey($keys);
    }

    ##
    ## Pages without --lateral, with less: keys
    ##
    ## The pages fill the screen and go on below.  The keys to go down
    ## and up move by the screen, as space and b do: a line down would
    ## show the pages cut in the middle.  NUP_LESSKEY is for --lateral,
    ## and when it is set, these keys are not added.
    ##

    elsif (!$lateral and !$no_page and !defined $ENV{NUP_LESSKEY}
           and $pager =~ m{^\s*(?:\S*/)?less(?:\s|$)}) {
        add_lesskey(join ';',
                    "j forw-screen;k back-screen",
                    "\\kd forw-screen;\\ku back-screen",
                    "d forw-screen;u back-screen",
                    "^D forw-screen;^U back-screen",
                    "\\r forw-screen;\\n forw-screen",
                    # the last and the first page
                    "J goto-end;K goto-line");
    }

    ##
    ## ansicolumn options
    ##
    ## With --lateral, the panes are given by their width in a row
    ## wide enough for any number of them: ansicolumn puts all the
    ## pages in one row.
    ##

    my @ac_opts = ("--bs=$border_style", "--cm=BORDER=L13", "-DBP",
                   $lateral ? ("-w" . $lateral_width * $LATERAL_PANES, "-S$lateral_width")
                            : ("-w$term_width", "-C$cols"));
    push @ac_opts, "--height=$height" if defined $height;
    push @ac_opts, "--no-page"        if $no_page;
    push @ac_opts, @passthru;

    ##
    ## The command is ansicolumn (file view mode of nup): give it the
    ## options, and filter its output by the pager
    ##

    if (@$argv && $argv->[0] eq 'ansicolumn') {

        # --highlight=NAME: ansicolumn reads the files in the colors
        # of the highlighter of the name, by Text::ANSI::Highlight::IO.
        # Without the module, ansicolumn fails by the option: look for
        # it, without loading.
        if (my $name = $config->{highlight}) {
            unshift @ac_opts, "--highlight=$name"
                if $name =~ /\A\w+(?::\S+)?\z/	# NAME, or NAME:STYLE
                and grep { !ref and -f "$_/Text/ANSI/Highlight/IO.pm" } @INC;
        }

        # the options go before those of the user, which win
        splice @$argv, 1, 0, @ac_opts;

        if ($config->{'no-pager'} || $pager eq '') {
            return;  # No filter needed
        }
        $mod->setopt(default => "-Mutil::filter --of='$pager' --ef='>&1'");
        return;
    }

    ##
    ## Any other command: filter its output by ansicolumn and the pager
    ##

    my $column = join ' ', 'ansicolumn', map { shell_escape($_) } @ac_opts;
    my $filter = ($config->{'no-pager'} || $pager eq '') ? $column : "$column|$pager";
    $mod->setopt(default => "-Mutil::filter --of='$filter' --ef='>&1'");
}

1;
