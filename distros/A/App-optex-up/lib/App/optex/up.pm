package App::optex::up;

our $VERSION = "1.04";

=encoding utf-8

=head1 NAME

up - optex module for multi-column paged output

=head1 SYNOPSIS

    optex -Mup command ...

    optex -Mup -C2 -- command ...

    optex -Mup -G2x2 -- command ...

=head1 DESCRIPTION

B<up> is a module for the B<optex> command that pipes the output
through L<App::ansicolumn> for multi-column formatting and a pager.
The name comes from the printing term "n-up" (2-up, 3-up, etc.) which
refers to printing multiple pages on a single sheet.

The module automatically calculates the number of columns based on the
terminal width divided by the pane width (default 85 characters).

Both stdout and stderr are merged and passed through the filter, so
error messages are also displayed in the multi-column paged output.

The pager command is taken from the C<$PAGER> environment variable if
set, otherwise defaults to C<less>.  When using C<less>, C<-F +Gg>
options are automatically appended.  C<-F> causes C<less> to exit
immediately if the output fits on one screen.  C<+Gg> causes C<less>
to read all input before displaying, which may take time for large
output, but prevents empty trailing pages from being shown.

=head1 OPTIONS

Module options must be specified before C<--> separator.

=over 4

=item B<-C> I<N>, B<--pane>=I<N>

Set the number of columns (panes) directly.

=item B<-R> I<N>, B<--row>=I<N>

Set the number of rows.  The page height is calculated by dividing
the terminal height by this value.

=item B<-G> I<CxR>, B<--grid>=I<CxR>

Set the grid layout.  For example, C<--grid=2x3> or C<--grid=2,3>
creates a 2-column, 3-row layout (6-up).  This is equivalent to
C<-C2 -R3>.

=item B<-S> I<N>, B<--pane-width>=I<N>

Set the pane width in characters.  Default is 85.  When B<--pane> is
not specified, the number of panes is calculated by dividing the
terminal width by this value.

=item B<--bs>=I<STYLE>, B<--border-style>=I<STYLE>

Set the border style for ansicolumn.  Default is C<heavy-box>.
See L<App::ansicolumn> for available styles.

=item B<-F>, B<--fold>

Enable fold mode (disable page mode).  In fold mode, the entire
content is split evenly across columns without pagination.  Page
mode is the default.

=item B<--pager>=I<COMMAND>

Set the pager command.  Default is C<$PAGER> or C<less>.

=item B<--no-pager>

Disable pager.  Output goes directly to stdout.

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

<p><img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/optex-up/main/images/perldoc.png">

=end html

List files in multiple columns with pager:

    optex -Mup ls -l

Use 2 columns:

    optex -Mup -C2 -- ls -l

Set pane width to 100:

    optex -Mup -S100 -- ls -l

Use 2 rows (upper and lower):

    optex -Mup -R2 -- ls -l

Use 2x2 grid (4-up):

    optex -Mup -G2x2 -- ls -l

Fold mode (no pagination):

    optex -Mup -F -- man perl

Use a different border style:

    optex -Mup --bs=round-box -- ls -l

Output without pager (useful for piping):

    optex -Mup --no-pager -C2 -- ls -l | head

Truncate long lines:

    optex -Mup --ls=truncate -- ps aux

=head1 INSTALL

=head2 CPANMINUS

    cpanm App::optex::up

=head1 SEE ALSO

L<App::optex>, L<https://github.com/kaz-utashiro/optex>

L<App::optex::up>, L<https://github.com/kaz-utashiro/optex-up>

L<App::ansicolumn>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2025 Kazumasa Utashiro.

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

my $config = Getopt::EX::Config->new(
    'grid'         => undef,
    'pane-width'   => 85,
    'pane'         => undef,
    'row'          => undef,
    'border-style' => 'heavy-box',
    'fold'         => undef,
    'pager'        => $ENV{PAGER} || 'less',
    'no-pager'     => undef,
);

sub finalize {
    my($mod, $argv) = @_;
    $config->configure('pass_through')->deal_with($argv,
        'grid|G=s', 'pane-width|S=i', 'pane|C=i', 'row|R=i',
        'border-style|bs=s', 'fold|F', 'pager:s', 'no-pager|nopager');
    my @passthru = $config->argv;

    if (my $grid = $config->{grid}) {
        my($c, $r) = $grid =~ /^(\d+)[x,](\d+)$/
            or die "Invalid grid format: $grid (expected CxR or C,R)\n";
        $config->{pane} //= $c;
        $config->{row}  //= $r;
    }

    my($term_width, $term_height) = term_size();
    $term_width  ||= $ENV{COLUMNS} || 80;
    $term_height ||= $ENV{LINES}   || 24;

    my $pane_width   = $config->{'pane-width'};
    my $cols         = $config->{pane} // max(1, int($term_width / $pane_width));
    my $rows         = $config->{row};
    my $height       = defined $rows ? int(($term_height - 1) / $rows) : undef;
    my $border_style = $config->{'border-style'};
    my $pager        = $config->{pager};
    $pager .= ' -F +Gg' if $pager =~ /\bless\b/;

    # Build default ansicolumn options
    my @ac_opts = ("-w$term_width", "--bs=$border_style", "--cm=BORDER=L13", "-DBP", "-C$cols");
    push @ac_opts, "--height=$height" if defined $height;
    push @ac_opts, "--no-page"        if $config->{fold};
    push @ac_opts, @passthru;

    # If command is ansicolumn, apply default options and pager
    if (@$argv && $argv->[0] eq 'ansicolumn') {
        # Insert defaults after 'ansicolumn', so user options take precedence
        splice @$argv, 1, 0, @ac_opts;
        if ($config->{'no-pager'} || $pager eq '') {
            return;  # No filter needed
        }
        $mod->setopt(default => "-Mutil::filter --of='$pager' --ef='>&1'");
        return;
    }

    my $column = join ' ', 'ansicolumn', map { shell_escape($_) } @ac_opts;
    my $filter = ($config->{'no-pager'} || $pager eq '') ? $column : "$column|$pager";
    $mod->setopt(default => "-Mutil::filter --of='$filter' --ef='>&1'");
}

1;
