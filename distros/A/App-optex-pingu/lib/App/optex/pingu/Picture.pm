package App::optex::pingu::Picture;

use v5.24;
use warnings;
use utf8;

use Exporter 'import';
our @EXPORT_OK = qw(&load);

use Data::Dumper;
use List::Util qw(pairs zip reduce);
use Term::ANSIColor::Concise qw(ansi_color);
$Term::ANSIColor::Concise::NO_RESET_EL = 1;

use constant {
    THB => "\N{UPPER HALF BLOCK}",
    BHB => "\N{LOWER HALF BLOCK}",
    LHB => "\N{LEFT HALF BLOCK}",
    RHB => "\N{RIGHT HALF BLOCK}",
    QUL => "\N{QUADRANT UPPER LEFT}",
    QUR => "\N{QUADRANT UPPER RIGHT}",
    QLL => "\N{QUADRANT LOWER LEFT}",
    QLR => "\N{QUADRANT LOWER RIGHT}",
    FB  => "\N{FULL BLOCK}",
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
	read_asc2($_);
    }
}

sub read_asc {
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
	if ($x && $x->[0] eq $b->[0] && $x->[1] eq $b->[1]) {
	    $x->[2]++;
	} else {
	    $b->[2] = 1;
	    push @$a, $b;
	}
	$a;
    } [], @_;
}

my $use_FB  = 0; # use FULL BLOCK when upper/lower are same
my $use_BHB = 0; # use LOWER HALF BLOCK to show lower part

sub stringify {
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

sub read_asc2 {
    my $data = shift;
    my @data = grep !/^\s*#/, $data =~ /.+/g;
    @data % 2 and die "Data format error.\n";
    my @image;
    for (pairs @data) {
	my($hi, $lo) = @$_;
	my @data = squeeze zip [ $hi =~ /\X/g ], [ $lo =~ /\X/g ];
	my $line = join '', map stringify($_), @data;
	push @image, $line;
    }
    wantarray ? @image : join('', map "$_\n", @image);
}

1;
