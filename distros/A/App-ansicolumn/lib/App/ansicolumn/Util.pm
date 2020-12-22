package App::ansicolumn;

use v5.14;
use warnings;
use utf8;

######################################################################
# Object interface
######################################################################

sub border {
    my $border = shift->{BORDER} or return "";
    $border->get(@_);
}

sub border_width {
    use List::Util qw(sum);
    my $obj = shift;
    sum map length($obj->border($_)), @_;
}

use Text::ANSI::Fold qw(:constants);

my %lb_flag = (
    ''     => LINEBREAK_NONE,
    none   => LINEBREAK_NONE,
    runin  => LINEBREAK_RUNIN,
    runout => LINEBREAK_RUNOUT,
    all    => LINEBREAK_ALL,
    );

sub lb_flag {
    $lb_flag{shift->{linebreak}};
}

sub runin {
    my $obj = shift;
    return 0 if not $lb_flag{$obj->{linebreak}} & LINEBREAK_RUNIN;
    $obj->{runin};
}

sub margin_width {
    shift->runin;
}

sub term_size {
    @{ shift->{term_size} //= [ terminal_size() ] };
}

sub term_width {
    (shift->term_size)[0];
}

sub term_height {
    (shift->term_size)[1];
}

sub width {
    my $obj = shift;
    $obj->{output_width} || $obj->term_width;
}

sub foldobj {
    my $obj = shift;
    my $width = shift;
    use Text::ANSI::Fold;
    my $fold = Text::ANSI::Fold->new(
	width     => $width,
	boundary  => $obj->{boundary},
	linebreak => $obj->lb_flag,
	runin     => $obj->{runin},
	runout    => $obj->{runout},
	ambiguous => $obj->{ambiguous},
	padchar   => $obj->{padchar},
	padding   => 1,
	);
    if ($obj->{discard_el}) {
	$fold->configure(discard => [ 'EL' ] );
    }
    $fold;
}

sub foldsub {
    my $obj = shift;
    my $width = shift;
    my $fold = $obj->foldobj($width);
    if ((my $ls = $obj->{linestyle}) eq 'truncate') {
	sub { ($fold->fold($_[0]))[0] };
    } elsif ($ls eq 'wrap') {
	sub {  $fold->text($_[0])->chops };
    } else {
	undef;
    }
}

sub layout {
    my $obj = shift;
    my $dp = shift;
    $obj->space_layout($dp);
    $obj->fillup($dp);
    $obj->insert_border($dp);
}

sub space_layout {
    my $obj = shift;
    my($dp) = @_;
    my $height = $obj->{height} - $obj->{border_height};
    for (my $page = 0; (my $top = $page * $height) < @$dp; $page++) {
	if ($height >= 4 and $top > 2 and !$obj->{isolation}) {
	    if ($dp->[$top - 2] !~ /\S/ and
		$dp->[$top - 1] =~ /\S/ and
		$dp->[$top    ] =~ /\S/
		) {
		splice @$dp, $top - 1, 0, '';
		next;
	    }
	}
	if (not $obj->{white_space}) {
	    while ($top < @$dp and $dp->[$top] !~ /\S/) {
		splice @$dp, $top, 1;
	    }
	}
    }
    @$dp;
}

sub fillup {
    my $obj = shift;
    my $dp = shift;
    my $height = $obj->{height} - $obj->{border_height};
    defined $obj->{fillup} and $obj->{fillup} !~ /^(?:no|none)$/
	or return;
    $obj->{fillup} ||= 'pane';
    my $line = $height;
    $line *= $obj->{panes} if $obj->{fillup} eq 'page';
    if (my $remmant = @$dp % $line) {
	push @$dp, ($obj->{fillup_str}) x ($line - $remmant);
    }
}

sub insert_border {
    my $obj = shift;
    my $dp = shift;
    my $height = $obj->{height};
    my $span = $obj->{span};
    my($bdr_top, $bdr_btm) = map { $obj->border($_) x $span } qw(top bottom);
    $bdr_top or $bdr_btm or return;
    for (my $page = 0; (my $top = $page * $height) < @$dp; $page++) {
	if ($bdr_top) {
	    splice @$dp, $top, 0, $bdr_top;
	}
	my $bottom_line = $top + $height - 1;
	if ($bdr_btm and $bottom_line <= @$dp) {
	    splice @$dp, $bottom_line, 0, $bdr_btm;
	}
    }
    @$dp;
}

######################################################################

sub newlist {
    my %arg = (count => 0);
    while (@_ and not ref $_[0]) {
	my($name, $value) = splice(@_, 0, 2);
	$arg{$name} = $value;
    }
    my @list = ($arg{default}) x $arg{count};
    while (my($index, $value) = splice(@_, 0, 2)) {
	$index = [ $index ] if not ref $index;
	@list[@$index] = ($value) x @$index;
    }
    @list;
}

sub div {
    use integer;
    my($a, $b) = @_;
    ($a + $b - 1) / $b;
}

sub roundup ($$;$) {
    use integer;
    my($a, $b, $c) = @_;
    return $a if $b == 0;
    div($a + ($c // 0), $b) * $b;
}

sub terminal_size {
    use Term::ReadKey;
    my @default = (80, 24);
    my @size;
    if (open my $tty, ">", "/dev/tty") {
	# Term::ReadKey 2.31 on macOS 10.15 has a bug in argument handling
	# and the latest version 2.38 fails to install.
	# This code should work on both versions.
	@size = GetTerminalSize $tty, $tty;
    }
    @size ? @size : @default;
}

sub zip {
    my @zipped;
    my @orig = map { [ @$_ ] } @_;
    while (my @l = grep { @$_ > 0 } @orig) {
	push @zipped, [ map { shift @$_ } @l ];
    }
    @zipped;
}

sub insert_space {
    use List::Util qw(reduce);
    map { @$_ } reduce {
	[ @$a, (@$a && $a->[-1] ne '' && $b ne '' ? '' : ()), $b ]
    } [], @_;
}

1;
