package App::Greple::frame;
our $VERSION = "0.06";

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

=begin comment

=item B<--frame-simple>

Set frame without folding.

=end comment

=back

Put next line in your F<~/.greplerc> to autoload B<App::Greple::frame> module.

    autoload -Mframe --frame

Then you can use B<--frame> option whenever you want.

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

my($mod, $argv);
my $width;
my($head, $blockend, $file_start, $file_end);

my %param = (
    width => undef,
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
    $width = $param{width} || terminal_width;
    if ($width =~ /\D/) {
	require App::Greple::frame::RPN
	    and App::Greple::frame::RPN->import('rpn_calc');
	$width = int(rpn_calc(terminal_width, $width)) or die "$width: format error\n";
    }

    my $frame_top    = '      ┌─' ;
    my $frame_middle = '    ⋮ ├╶' ;
    my $frame_bottom = '──────┴─' ;

    for ($frame_top, $frame_middle, $frame_bottom) {
	if ((my $rest = $width - length) > 0) {
	    $_ .= (substr($_, -1, 1) x $rest);
	}
    }

    $mod->setopt('--show-frame-top',    '--frame-top'    => "'$frame_top'");
    $mod->setopt('--show-frame-middle', '--frame-middle' => "'$frame_middle'");
    $mod->setopt('--show-frame-bottom', '--frame-bottom' => "'$frame_bottom'");
    $mod->setopt(
	'--ansifold',
	'--pf' => "'ansifold -x --width=$width --prefix \"      │ \"'",
	);
}

sub set {
    while (my($k, $v) = splice(@_, 0, 2)) {
	exists $param{$k} or next;
	$param{$k} = $v;
    }
    ();
}

1;

__DATA__

option --frame-color-filename \
	--colormap FILE=555/CE --format FILE=' 📂 %s'

option --frame-simple \
	--line-number --join-blocks \
	--filestyle=once \
	--colormap LINE=       --format LINE='%5d │ ' \
	--blockend= \
	--show-frame-middle

option --frame-fold \
	--frame-color-filename \
	--frame-simple --ansifold

option --frame --frame-fold

option --frame-classic \
	--frame-simple \
	--show-frame-top --show-frame-bottom
