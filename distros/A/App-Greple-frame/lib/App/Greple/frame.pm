package App::Greple::frame;

our $VERSION = "0.07";

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

Set frame and fold long lines with frame-friendly prefix string.
Folding width is taken from the terminal.  Or you can specify the
width by calling B<set> function with module option.

=item B<--set-frame-width>=I<#>

Set frame width.  You have to put this option before B<--frame>
option.  See B<set> function in L</FUNCTION> section.

=begin comment

=item B<--frame-simple>

Set frame without folding.

=end comment

=back

=begin comment

Put next line in your F<~/.greplerc> to autoload B<App::Greple::frame> module.

    autoload -Mframe --frame

Then you can use B<--frame> option whenever you want.

=end comment

=begin html

<p><img width="75%" src="https://raw.githubusercontent.com/kaz-utashiro/greple-frame/main/images/terminal-3.png">

=end html

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

L<Math::RPN>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2022 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use 5.014;
use warnings;
use utf8;
use Data::Dumper;

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

option --ansifold-with-width \
       --pf "ansifold -x --discard=EL --padding --prefix '      │ ' $<shift> --width=$<shift>"

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
option --frame-classic-fold  --frame-classic-plain &opt_ansifold
option --frame-classic       --frame-classic-fold

##
## EXPERIMENTAL: --frame-pages
##

define $FRAME_WIDTH 3
define $COL_WIDTH   80:8+:$FRAME_WIDTH+
define $PREFIX      '      │ '
define $FOLD        ansifold -x --discard=EL --padding --prefix $PREFIX
define $COLUMN      ansicolumn --border=box -P
define $FOLD_COLUMN $FOLD $<shift> --width=$<shift> | $COLUMN -C $<shift>

option --frame-column-with-param \
       --pf $FOLD_COLUMN

option --frame-pages \
       &set(width=DUP:$COL_WIDTH/:INT:DUP:1:GE:EXCH:1:IF:/:$FRAME_WIDTH-) \
       &set(column=$COL_WIDTH/:INT:DUP:1:GE:EXCH:1:IF) \
       --frame-plain \
       --frame-column-with-param &get(fold,width) &get(column)
