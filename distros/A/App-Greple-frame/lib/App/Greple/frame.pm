package App::Greple::frame;

our $VERSION = "1.03";

=encoding utf-8

=head1 NAME

App::Greple::frame - Greple frame output module

=head1 SYNOPSIS

greple -Mframe --frame ...

=head1 DESCRIPTION

Greple -Mframe module provide a capability to put surrounding frames
for each blocks.

C<top>, C<middle> and C<bottom> frames are printed for blocks.

By default B<--join-blocks> option is enabled to collect consecutive
lines into a single block.  If you don't like this, override it by
B<--no-join-blocks> option.

=head1 OPTIONS

=over 7

=item B<--frame>

=for comment
=item B<--frame-fold>

=begin html

<p><img width="75%" src="https://raw.githubusercontent.com/kaz-utashiro/greple-frame/main/images/terminal-3.png">

=end html

Set frame and fold long lines with frame-friendly prefix string.
Folding width is taken from the terminal.  Or you can specify the
width by calling B<set> function with module option.

=begin comment

=item B<--frame-simple>

Set frame without folding.

=end comment

=item B<--frame-cols>

Output results in multi-column format to fit the width of the
terminal.  The number of columns is automatically calculated from the
terminal width.

=item B<--frame-pages>

Output results in multi-column and paginated format.

=begin html

<p><img width="75%" src="https://raw.githubusercontent.com/kaz-utashiro/greple-frame/main/images/terminal-frame-pages.png">

=end html

=item B<--set-frame-width>=I<#>

Set frame width.  You have to put this option before B<--frame>
option.  See B<set> function in L</FUNCTION> section.

=back

=begin comment

Put next line in your F<~/.greplerc> to autoload B<App::Greple::frame> module.

    autoload -Mframe --frame

Then you can use B<--frame> option whenever you want.

=end comment

=head1 FUNCTION

=over 7

=item B<set>(B<width>=I<n>)

Set terminal width to I<n>.  Use like this:

    greple -Mframe::set(width=80) ...

    greple -Mframe::set=width=80 ...

If non-digit character is found in the value part, it is considered as
a Reverse Polish Notation, starting terminal width pushed on the
stack.  RPN C<2/3-> means C<terminal-width / 2 - 3>.

You can use like this:

    greple -Mframe::set=width=2/3- --frame --uc '(\w+::)+\w+' --git | ansicolumn -PC2

=begin html

<p><img width="75%" src="https://raw.githubusercontent.com/kaz-utashiro/greple-frame/main/images/terminal-column.png">

=end html

=back

=head1 SEE ALSO

L<App::ansifold>

L<App::ansicolumn>

L<Math::RPN>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2022-2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use 5.014;
use warnings;
use utf8;
use Data::Dumper;

$ENV{GREPLE_FRAME_PAGES_WIDTH}    //= '80';
$ENV{GREPLE_FRAME_PAGES_MARGIN}   //= '0';
$ENV{GREPLE_FRAME_PAGES_BOUNDARY} //= 'none';

my($mod, $argv);
my($head, $blockend, $file_start, $file_end);

my %param = (
    width  => undef,
    column => undef,
    fold   => '',
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
}

my %frame_base = (
    top    => '      ┌─' ,
    middle => '    ⋮ ├╶' ,
    bottom => '──────┴─' ,
);

sub opt_frame {
    my $pos = shift;
    my $width = $param{width} //= terminal_width;
    local $_ = $frame_base{$pos} or die;
    if ((my $rest = $width - length) > 0) {
	$_ .= (substr($_, -1, 1) x $rest);
    }
    $_;
}

my %rpn = (
    width  => { init => sub { terminal_width } },
    column => { init => sub { terminal_width } },
    );
sub rpn {
    my($k, $v) = @_;
    require Getopt::EX::RPN
	and Getopt::EX::RPN->import('rpn_calc');
    my $init = $rpn{$k}->{init} // die;
    my @init = ref $init ? $init->() : $init ? $init : ();
    int(rpn_calc(@init, $v)) or die "$v: format error\n";
}

sub set {
    while (my($k, $v) = splice(@_, 0, 2)) {
	exists $param{$k} or next;
	$v = rpn($k, $v) if $rpn{$k} and $v =~ /\D/;
	$param{$k} = $v;
    }
    ();
}

sub get {
    use List::Util qw(pairmap);
    pairmap { $param{$a} } @_;
}

1;

__DATA__

mode function

option --set-frame-width  &set(width=$<shift>)
option --set-frame-column &set(column=$<shift>)

option --ansifold-with-width \
       --pf "ansifold --expand --discard=EL --padding --prefix '      │ ' $<shift> --width=$<shift>"

option --ansifold \
       --ansifold-with-width &get(fold,width)

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

# RPN
define @TEXT_WIDTH  $ENV{GREPLE_FRAME_PAGES_WIDTH}
define @MARGIN      $ENV{GREPLE_FRAME_PAGES_MARGIN}
define @LINE_FIELD  8
define @FRAME_GAP   3
define @COL_WIDTH   @TEXT_WIDTH:@LINE_FIELD:+:@FRAME_GAP:+
define @COLUMN      @COL_WIDTH:/:INT:DUP:1:GE:EXCH:1:IF
define @WIDTH       DUP:@COLUMN:/:@FRAME_GAP:-:@MARGIN:-

define $FOLD \
       ansifold --expand --discard=EL --padding \
       --width =@WIDTH \
       --prefix '      │ ' \
       --boundary=$ENV{GREPLE_FRAME_PAGES_BOUNDARY} \
       --linebreak=all --runin=@MARGIN --runout=@MARGIN

define $COLS \
       ansicolumn --border=box -U @COLUMN

define $PAGES \
       ansicolumn --border=box -P -C @COLUMN

option --frame-set-params \
       &set(width=@WIDTH)

option --frame-col \
       --frame-set-params \
       --pf "$FOLD" \
       --frame-plain

option --frame-pages \
       --frame-set-params \
       --pf "$FOLD | $PAGES" \
       --frame-plain

option --frame-cols \
       --frame-set-params \
       --pf "$FOLD | $COLS" \
       --frame-plain

option --frame-columns --frame-cols

option --frame-pages-classic \
       --frame-set-params \
       --pf "$FOLD | $PAGES" \
       --frame-classic-plain
