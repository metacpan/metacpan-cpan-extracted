package App::Greple::frame;

our $VERSION = "1.04";

=encoding utf-8

=head1 NAME

App::Greple::frame - Greple frame output module

=head1 SYNOPSIS

greple -Mframe --style=fold -- ...

greple -Mframe --frame ...

=head1 VERSION

Version 1.04

=head1 DESCRIPTION

Greple -Mframe module provide a capability to put surrounding frames
for each blocks.

C<top>, C<middle> and C<bottom> frames are printed for blocks.

By default B<--join-blocks> option is enabled to collect consecutive
lines into a single block.  If you don't like this, override it by
B<--no-join-blocks> option.

=head1 MODULE OPTIONS

Options placed between B<-Mframe> and B<--> belong to the module, so
their names do not conflict with the options of B<greple> or of other
modules.

    greple -Mframe --style=cols -- pattern file

    greple -Mframe --style=fold --width=80 -- pattern file

When B<--> is given, everything before it must be a module option, so
C<< -Mframe --frame pattern -- file >> is an error.  Options of
B<greple> and the pattern come after it.

=over 7

=item B<--style>=I<name>

Select the output style.  An unknown name is an error.

=over 7

=item B<fold>

=begin html

<p><img width="75%" src="https://raw.githubusercontent.com/kaz-utashiro/greple-frame/main/images/terminal-3.png">

=end html

Set frame and fold long lines with frame-friendly prefix string.
Folding width is taken from the terminal.  Or you can specify the
width with the B<--width> option.

=item B<cols>

Output results in multi-column format to fit the width of the
terminal.  The number of columns is automatically calculated from the
terminal width.

=item B<pages>

Output results in multi-column and paginated format.

=begin html

<p><img width="75%" src="https://raw.githubusercontent.com/kaz-utashiro/greple-frame/main/images/terminal-frame-pages.png">

=end html

=back

=item B<--width>=I<n>

Output width.  It takes the place of the terminal width, and accepts
RPN as described in L</CONFIGURATION>.

=back

The next options mean the same as the options of the same name of
L<App::ansicolumn> and L<App::ansifold>.

=over 7

=item B<--pane>=I<n>

Number of columns of B<cols> and B<pages> styles.  By default, as many
columns as fit in the output width with text of 80 columns.

=item B<--pane-width>=I<n>

Width of a column of B<cols> and B<pages> styles, including the border.
The number of columns is calculated from it unless B<--pane> is given,
and the columns are not widened to the output width.

B<--pane> and B<--pane-width> accept RPN, starting with the output
width.

=item B<--boundary>=C<none>|C<word>|C<space>

Where to fold long lines.

=item B<--linebreak>=C<none>|C<all>|C<runin>|C<runout>

Line-break mode.

=item B<--runin>=I<n>, B<--runout>=I<n>, B<--runlen>=I<n>

Run-in and run-out width.  B<--runlen> sets both, and B<--runin> and
B<--runout> take priority over it.  B<cols> and B<pages> styles keep the
run-in width free in the column, so the text area gets shorter.

=back

B<cols> and B<pages> styles use C<--boundary=none>,
C<--linebreak=all> and C<--runlen=0> by default.  B<fold> style gives
them to B<ansifold> only when they are specified.

=over 7

=item B<--config> I<name>=I<value>,...

Set parameters of L</CONFIGURATION>.

=back

=head1 COMMAND OPTIONS

These options work as options of the B<greple> command, and do not need
B<-->.  They are kept for compatibility and may be removed in the
future.  Use L</MODULE OPTIONS>.

=over 7

=item B<--frame>

=for comment
=item B<--frame-fold>

Same as B<--style=fold>.

=begin comment

=item B<--frame-simple>

Set frame without folding.

=end comment

=item B<--frame-cols>

Same as B<--style=cols>.

=item B<--frame-pages>

Same as B<--style=pages>.

=item B<--set-frame-width>=I<#>

Same as B<--width>.  You have to put this option before B<--frame>
option.

=back

=begin comment

Put next line in your F<~/.greplerc> to autoload B<App::Greple::frame> module.

    autoload -Mframe --frame

Then you can use B<--frame> option whenever you want.

=end comment

=head1 CONFIGURATION

Module parameters are set with L<Getopt::EX::Config> by the B<config>
function.  The B<--config> module option sets the same parameters.

The B<set> function does the same as B<config>.  It is kept only for
compatibility and will be removed in the future.

=over 7

=item B<config>(B<width>=I<n>)

Set terminal width to I<n>.  Use like this:

    greple -Mframe::config(width=80) ...

    greple -Mframe::config=width=80 ...

If non-digit character is found in the value part, it is considered as
a Reverse Polish Notation, starting terminal width pushed on the
stack.  RPN C<2/3-> means C<terminal-width / 2 - 3>.

You can use like this:

    greple -Mframe::config=width=2/3- --frame --uc '(\w+::)+\w+' --git | ansicolumn -PC2

With B<cols> and B<pages> styles, the whole output has this width, and
the width and the number of the columns are calculated from it.

An unknown parameter is an error.

=begin html

<p><img width="75%" src="https://raw.githubusercontent.com/kaz-utashiro/greple-frame/main/images/terminal-column.png">

=end html

=item B<config>(B<style>=I<name>)

=item B<config>(B<pane>=I<n>), B<config>(B<pane_width>=I<n>)

=item B<config>(B<boundary>=I<name>), B<config>(B<linebreak>=I<name>)

=item B<config>(B<runin>=I<n>), B<config>(B<runout>=I<n>), B<config>(B<runlen>=I<n>)

Same as the module options of the same name.

=back

=head1 SEE ALSO

L<App::ansifold>

L<App::ansicolumn>

L<Math::RPN>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2022-2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use v5.26;
use warnings;
use utf8;
use Data::Dumper;
use Getopt::EX::Config qw(config set);

my($mod, $argv);
my($head, $blockend, $file_start, $file_end);
my $frame_width;		# of a column, set by pane()

# set() is kept only for compatibility and will be removed in the future.
# Values may be RPN, which is calculated when the value is used (see param).
my $config = Getopt::EX::Config->new(
    style      => undef,
    width      => undef,
    pane       => undef,
    pane_width => undef,
    boundary   => undef,
    linebreak  => undef,
    runin      => undef,
    runout     => undef,
    runlen     => undef,
    fold       => '',
);

sub terminal_width {
    use Term::ReadKey;
    my $default = 80;
    my @size;
    if (open my $tty, ">", "/dev/tty") {
	# Term::ReadKey 2.31 on macOS 10.15 has a bug in argument handling
	# and the latest version 2.38 fails to install.
	# This code should work on both versions.
	@size = GetTerminalSize $tty, $tty;
    }
    $size[0] or $default;
}

sub finalize {
    ($mod, $argv) = @_;
    $config->deal_with($argv, "style=s", "width=s", "pane=s", "pane_width=s",
		       "boundary=s", "linebreak=s",
		       "runin=i", "runout=i", "runlen=i");
    if (my @extra = $config->argv) {
	die "@extra: unexpected argument before --\n";
    }
    # The default gets the definition, not the name: an autoload of that
    # name in the rc file would load the module again, which inserts the
    # default once more and the frame comes out twice.
    if (my $style = $config->{style}) {
	my @opt = $mod->getopt("--frame-$style")
	    or die "$style: unknown style\n";
	$mod->setopt(default => [ @opt ]);
    }
}

my %frame_base = (
    top    => '      ┌─' ,
    middle => '    ⋮ ├╶' ,
    bottom => '──────┴─' ,
);

sub opt_frame {
    my $pos = shift;
    my $width = $frame_width // param('width') // ($config->{width} = terminal_width);
    local $_ = $frame_base{$pos} or die;
    if ((my $rest = $width - length) > 0) {
	$_ .= (substr($_, -1, 1) x $rest);
    }
    $_;
}

sub whole_width { param('width') // terminal_width }

my %rpn = (
    width      => { init => sub { terminal_width } },
    pane       => { init => \&whole_width },
    pane_width => { init => \&whole_width },
    );
sub rpn {
    my($k, $v) = @_;
    require Getopt::EX::RPN
	and Getopt::EX::RPN->import('rpn_calc');
    my $init = $rpn{$k}->{init} // die;
    my @init = ref $init ? $init->() : $init ? $init : ();
    int(rpn_calc(@init, $v)) or die "$v: format error\n";
}

# A value can be set at any time before it is used, by the module
# function or by an option, so the RPN is calculated here.
sub param {
    my $k = shift;
    my $v = $config->{$k};
    if (defined $v and $rpn{$k} and $v =~ /\D/) {
	$v = $config->{$k} = rpn($k, $v);
    }
    $v;
}

# Width of the line number field and of the column border.
my($LINE_FIELD, $FRAME_GAP) = (8, 3);

# For the multi-column options.  The parameters mean the same as the options
# of ansicolumn, except that the width takes the place of the terminal width
# for all of them.  The environment variables were the only way to give some
# values, and they still work as the default.  Returns the values in the order
# of $<shift> in the definitions of $FOLD and $COLS or $PAGES.
sub pane {
    my $whole = whole_width;
    my $span  = param('pane_width');
    my $text  = $ENV{GREPLE_FRAME_PAGES_WIDTH} // 80;
    my $panes = param('pane')
	|| int($whole / ($span || $text + $LINE_FIELD + $FRAME_GAP)) || 1;
    my $run = $config->{runlen} // $ENV{GREPLE_FRAME_PAGES_MARGIN} // 0;
    my $runin  = $config->{runin}  // $run;
    my $runout = $config->{runout} // $run;
    my $bound  = $config->{boundary}  // $ENV{GREPLE_FRAME_PAGES_BOUNDARY} // 'none';
    my $break  = $config->{linebreak} // 'all';
    my $width  = int(($span || $whole / $panes) - $FRAME_GAP - $runin);
    $width > 0 or die "width $whole is too small for $panes pane(s) and run-in $runin\n";
    $frame_width = $width;
    ($width, $bound, $break, $runin, $runout, $whole, $span ? "-S $span" : '', $panes);
}

# For --frame: nothing is given unless specified, so that ~/.ansifoldrc works.
sub fold_args {
    my @opt;
    for my $name (qw(boundary linebreak runin runout runlen)) {
	my $val = $config->{$name} // next;
	push @opt, "--$name=$val";
    }
    (join(' ', @opt, param('fold')), param('width'));
}

1;

__DATA__

mode function

option --set-frame-width  &config(width=$<shift>)
option --set-frame-column &config(pane=$<shift>)

option --ansifold-with-width \
       --pf "ansifold --expand --discard=EL --padding --prefix '      │ ' $<shift> --width=$<shift>"

option --ansifold \
       --ansifold-with-width &fold_args

option --frame-color-filename \
       --colormap FILE=555/CE --format FILE=' %s'

option --frame-simple \
       --line-number --join-blocks \
       --filestyle=once \
       --colormap LINE= --format LINE='%5d │ ' \
       --blockend= \
       --show-frame-middle

option --show-frame-top    --frame_top    &opt_frame(top)
option --show-frame-middle --frame_middle &opt_frame(middle)
option --show-frame-bottom --frame_bottom &opt_frame(bottom)

option --frame-plain --frame-color-filename --frame-simple
option --frame-fold  --frame-plain --ansifold
option --frame       --frame-fold

option --frame-classic-plain --frame-simple --show-frame-top --show-frame-bottom
option --frame-classic-fold  --frame-classic-plain --ansifold
option --frame-classic       --frame-classic-fold

##
## EXPERIMENTAL: --frame-pages, --frame-cols
##

define $FOLD \
       ansifold --expand --discard=EL --padding \
       --width=$<shift> \
       --prefix '      │ ' \
       --boundary=$<shift> \
       --linebreak=$<shift> --runin=$<shift> --runout=$<shift>

define $COLS \
       ansicolumn --border=box -c $<shift> $<shift> -U $<shift>

define $PAGES \
       ansicolumn --border=box -P -c $<shift> $<shift> -C $<shift>

# &pane is called when these options are expanded, so that it sees the
# width given by --set-frame-width.  It can not be in the definition of
# --frame-col and others, because --style puts them in the default option,
# where functions are not called.

option --frame-col-pf --pf "$FOLD" $<remove(0,3)>
option --frame-pages-pf --pf "$FOLD | $PAGES"
option --frame-cols-pf --pf "$FOLD | $COLS"

option --frame-col-pane --frame-col-pf &pane
option --frame-pages-pane --frame-pages-pf &pane
option --frame-cols-pane --frame-cols-pf &pane

option --frame-col --frame-col-pane --frame-plain
option --frame-pages --frame-pages-pane --frame-plain
option --frame-cols --frame-cols-pane --frame-plain

option --frame-columns --frame-cols

option --frame-pages-classic --frame-pages-pane --frame-classic-plain
