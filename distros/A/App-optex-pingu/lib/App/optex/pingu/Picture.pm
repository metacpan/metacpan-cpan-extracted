package App::optex::pingu::Picture;

use v5.24;
use warnings;
use utf8;

use Exporter 'import';
our @EXPORT_OK = qw(&load);

use Data::Dumper;
use List::Util qw(pairs zip reduce all);
use Term::ANSIColor::Concise qw(ansi_color);
$Term::ANSIColor::Concise::NO_RESET_EL = 1;

use constant {
    THB   => "\N{UPPER HALF BLOCK}",
    BHB   => "\N{LOWER HALF BLOCK}",
    LHB   => "\N{LEFT HALF BLOCK}",
    RHB   => "\N{RIGHT HALF BLOCK}",
    QUL   => "\N{QUADRANT UPPER LEFT}",
    QUR   => "\N{QUADRANT UPPER RIGHT}",
    QLL   => "\N{QUADRANT LOWER LEFT}",
    QLR   => "\N{QUADRANT LOWER RIGHT}",
    QULx  => "\N{U+259F}",
    QURx  => "\N{U+2599}",
    QLLx  => "\N{U+259C}",
    QLRx  => "\N{U+259B}",
    QULLR => "\N{QUADRANT UPPER LEFT AND LOWER RIGHT}",
    QURLL => "\N{QUADRANT UPPER RIGHT AND LOWER LEFT}",
    FB    => "\N{FULL BLOCK}",
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

sub read_asc_1 {
    local $_ = shift;
    s/^#.*\n//mg;
    s{ (?<str>(?<col>$color_re)\g{col}*) }{
	ansi_color($+{col}, FB x length($+{str}))
    }xge;
    /.+/g;
}

######################################################################

sub squeeze {
    map @$_, reduce {
	my $x = $a->[-1];
	if ($x && all { $x->[$_] eq $b->[$_] } 0 .. $#{$b}) {
	    $x->[-1]++;
	} else {
	    push @$a, [ @$b, 1 ];
	}
	$a;
    } [], @_;
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
	my @data = squeeze zip [ $hi =~ /\X/g ], [ $lo =~ /\X/g ];
	my $line = join '', map stringify2($_), @data;
	push @image, $line;
    }
    wantarray ? @image : join('', map "$_\n", @image);
}

######################################################################

my %elements = (
    "0"    => '',    #
    "1"    => FB,    #
    "00"   => '',    #
    "10"   => THB,   #
    "01"   => BHB,   #
    "11"   => FB,    #
    "0000" => '',    #
    "0001" => QLR,   #
    "0010" => QLL,   #
    "0011" => BHB,   #
    "0100" => QUR,   #
    "0101" => RHB,   #
    "0110" => QURLL, #
    "0111" => QULx,  #
    "1000" => QUL,   #
    "1001" => QULLR, #
    "1010" => LHB,   #
    "1011" => QURx,  #
    "1100" => THB,   #
    "1101" => QLLx,  #
    "1110" => QLRx,  #
    "1111" => FB,    #
);

sub stringify {
    my $vec = shift;
    my $n = pop @$vec;
    my $spec = join '', @$vec;
    my $fg = ($spec =~ /($color_re)/)[0] // '';
    my $bg = ($spec =~ /((?!$fg).)/)[0] // '';
    my $ch = (state $cache = {})->{$spec} //= do {
	if (!$fg) {
	    substr $spec, 0, 1;
	} else {
	    my $bit = $spec =~ s/(.)/int($1 eq $fg)/ger;
	    $elements{$bit} // die "$bit";
	}
    };
    my $s = $ch x $n || 1;
    if (my $color = $fg) {
	$color .= "/$bg" if $bg =~ /$color_re/;
	$s = ansi_color($color, $s);
    }
    $s;
}

sub read_asc {
    my $opt = ref $_[0] eq 'HASH' ? shift : {};
    my $x = $opt->{x} // 1;
    my $y = $opt->{y} // 1;
    my $data = shift;
    my @data = $data =~ /.+/g;
    @data % 2 and die;
    my @image;
    while (my @y = splice(@data, 0, $y)) {
	my @data = squeeze zip map { [ /\X{$x}/g ] } @y;
	my $line = join '', map stringify($_), @data;
	push @image, $line;
    }
    wantarray ? @image : join('', map "$_\n", @image);
}

1;
