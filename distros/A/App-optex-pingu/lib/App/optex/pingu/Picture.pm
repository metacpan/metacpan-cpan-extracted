package App::optex::pingu::Picture;

use v5.24;
use warnings;
use utf8;

use Exporter 'import';
our @EXPORT_OK = qw(&load);

use Data::Dumper;
use List::Util qw(pairs zip reduce all any);
use Term::ANSIColor::Concise qw(ansi_color);
$Term::ANSIColor::Concise::NO_RESET_EL = 1;

use constant {
    FB    => "\N{FULL BLOCK}",
    THB   => "\N{UPPER HALF BLOCK}",
    BHB   => "\N{LOWER HALF BLOCK}",
    LHB   => "\N{LEFT HALF BLOCK}",
    RHB   => "\N{RIGHT HALF BLOCK}",
    QUL   => "\N{QUADRANT UPPER LEFT}",
    QUR   => "\N{QUADRANT UPPER RIGHT}",
    QLL   => "\N{QUADRANT LOWER LEFT}",
    QLR   => "\N{QUADRANT LOWER RIGHT}",
    QULLR => "\N{QUADRANT UPPER LEFT AND LOWER RIGHT}",
    QURLL => "\N{QUADRANT UPPER RIGHT AND LOWER LEFT}",
    Qxx__ => "\N{UPPER HALF BLOCK}",
    Q__xx => "\N{LOWER HALF BLOCK}",
    Qx_x_ => "\N{LEFT HALF BLOCK}",
    Q_x_x => "\N{RIGHT HALF BLOCK}",
    Qx___ => "\N{QUADRANT UPPER LEFT}",
    Q_x__ => "\N{QUADRANT UPPER RIGHT}",
    Q__x_ => "\N{QUADRANT LOWER LEFT}",
    Q___x => "\N{QUADRANT LOWER RIGHT}",
    Qx__x => "\N{QUADRANT UPPER LEFT AND LOWER RIGHT}",
    Q_xx_ => "\N{QUADRANT UPPER RIGHT AND LOWER LEFT}",
    Q_xxx => "\N{QUADRANT UPPER RIGHT AND LOWER LEFT AND LOWER RIGHT}",
    Qx_xx => "\N{QUADRANT UPPER LEFT AND LOWER LEFT AND LOWER RIGHT}",
    Qxx_x => "\N{QUADRANT UPPER LEFT AND UPPER RIGHT AND LOWER RIGHT}",
    Qxxx_ => "\N{QUADRANT UPPER LEFT AND UPPER RIGHT AND LOWER LEFT}",
    Qxxxx => "\N{FULL BLOCK}",
};
my $color_re = qr/[RGBCMYKW]/i;

sub load {
    my $file = shift;
    open my $fh, '<', $file or die "$file: $!\n";
    local $_ = do { local $/; <$fh> };
    s/.*^__DATA__\n//ms;
    s/^#.*\n//mg;
    if ($file =~ /\.asc$/) {
	read_asc($_);
    }
    elsif ($file =~ /\.asc2$/) {
	read_asc({ y => 2 }, $_);
    }
    elsif ($file =~ /\.asc4$/) {
	read_asc({ x => 2, y => 2 }, $_);
    }
}

sub squash {
    map @$_, reduce {
	my $x = $a->[-1];
	if ($x && all { $x->[$_] eq $b->[$_] } keys @$b) {
	    $x->[-1]++;
	} else {
	    push @$a, [ @$b, 1 ];
	}
	$a;
    } [], @_;
}

my %element = (
    "0"    => '',    #
    "1"    => FB,    # █
    "00"   => '',    #
    "10"   => THB,   # ▀
    "01"   => BHB,   # ▄
    "11"   => FB,    # █
    "0000" => '',    #
    "0001" => Q___x, # ▗
    "0010" => Q__x_, # ▖
    "0011" => Q__xx, # ▄
    "0100" => Q_x__, # ▝
    "0101" => Q_x_x, # ▐
    "0110" => Q_xx_, # ▞
    "0111" => Q_xxx, # ▟
    "1000" => Qx___, # ▘
    "1001" => Qx__x, # ▚
    "1010" => Qx_x_, # ▄
    "1011" => Qx_xx, # ▙
    "1100" => Qxx__, # ▀
    "1101" => Qxx_x, # ▜
    "1110" => Qxxx_, # ▛
    "1111" => Qxxxx, # █
);

sub stringify {
    my $vec = shift;
    my $n = pop @$vec;
    my $spec = join '', @$vec;
    my $c1 = ($spec =~ /($color_re)/)[0] // '';
    my $c2 = ($spec =~ /((?!$c1)$color_re)/)[0] // '';
    my $ch = (state $cache = {})->{$spec} //= do {
	if ($c1) {
	    my $bit = $spec =~ s/(.)/int($1 eq $c1)/ger;
	    $element{$bit} // die "$spec -> $bit";
	} else {
	    substr $spec, 0, 1;
	}
    };
    my $s = $ch x $n || 1;
    $c1 ? ansi_color("$c1/$c2", $s) : $s;
}

sub read_asc {
    my $opt = ref $_[0] eq 'HASH' ? shift : {};
    my $x = $opt->{x} // 1;
    my $y = $opt->{y} // 1;
    my $data = shift;
    my @data = $data =~ /.+/g;
    @data % $y                  and die "data format error.";
    any { (length) % $x } @data and die "data format error.";
    my @image;
    while (my @y = splice(@data, 0, $y)) {
	my @sequence = squash zip map { [ /\X{$x}/g ] } @y;
	my $line = join '', map stringify($_), @sequence;
	push @image, $line;
    }
    wantarray ? @image : join('', map "$_\n", @image);
}

######################################################################

sub read_asc_1 {
    local $_ = shift;
    s/^#.*\n//mg;
    s{ (?<str>(?<col>$color_re)\g{col}*) }{
	ansi_color($+{col}, FB x length($+{str}))
    }xge;
    /.+/g;
}

my $use_FB  = 0; # use FULL BLOCK when upper/lower are same
my $use_BHB = 0; # use LOWER HALF BLOCK to show lower part

sub stringify_2 {
    my($hi, $lo, $c) = @{+shift};
    $c //= 1;
    if ($hi =~ $color_re) {
	my $color = $hi;
	if ($use_FB and $lo eq $hi) {
	    ansi_color($color, FB x $c);
	} else {
	    $color .= "/$lo" if $lo =~ $color_re;
	    ansi_color($color, THB x $c);
	}
    }
    elsif ($lo =~ $color_re) {
	if ($use_BHB) {
	    ansi_color($lo, BHB x $c);
	} else {
	    ansi_color("S$lo", THB x $c);
	}
    }
    else {
	$hi x $c;
    }
}

sub read_asc_2 {
    my $data = shift;
    my @data = grep !/^\s*#/, $data =~ /.+/g;
    @data % 2 and die "Data format error.\n";
    my @image;
    for (pairs @data) {
	my($hi, $lo) = @$_;
	my @data = squash zip [ $hi =~ /\X/g ], [ $lo =~ /\X/g ];
	my $line = join '', map stringify_2($_), @data;
	push @image, $line;
    }
    wantarray ? @image : join('', map "$_\n", @image);
}

######################################################################

1;
