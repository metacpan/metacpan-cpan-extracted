package App::Greple::wordle::game;
use v5.14;
use warnings;

use Data::Dumper;
use List::Util qw(any uniq);
use List::MoreUtils qw(pairwise);
use Getopt::EX::Colormap qw(colorize);

use Mo qw(is required default); {
    has answer   => is => 'ro', required => 1 ;
    has attempts => [], lazy => 0 ;
    has map      => {} ;
}
no Mo;

sub try {
    my $obj = shift;
    push @{$obj->{attempts}}, @_;
    $obj->update(@_);
    $obj->solved;
}

sub attempt {
    my $obj = shift;
    int @{$obj->{attempts}};
}

sub solved {
    my $obj = shift;
    any { lc eq lc $obj->{answer} } @{$obj->{attempts}};
}

sub update {
    my $obj = shift;
    my $answer = $obj->answer;
    my %a = map { $_ => 1 } my @a = $answer =~ /./g;
    my $keys = $obj->map;
    for my $try (@_) {
	my @b = $try =~ /./g;
	pairwise { $keys->{$a} = 'G' if $a eq $b } @a, @b;
	$keys->{$_} ||= $a{$_} ? 'Y' : 'K' for @b;
    }
    $obj;
}

######################################################################
# keymap
######################################################################

my %map_color = (
    G => '555/#6aaa64',
    Y => '555/#c9b458',
    K => '#787c7e/#787c7e',
    K => 'L17/#787c7e',
    _ => '555/#787c7e',
    );

sub keycolor {
    my($kmap, $cmap, $s) = @_;
    join '', map colorize($cmap->{$kmap->{$_}//'_'}, $_), $s =~ /./g;
}

sub keymap {
    my $obj = shift;
    my $keys = keycolor $obj->map, \%map_color, join('', 'a'..'z');
    $keys;
}

######################################################################
# result
######################################################################

my %square = (
    G => "\N{U+1F7E9}", # LARGE GREEN SQUARE
    Y => "\N{U+1F7E8}", # LARGE YELLOW SQUARE
    K => "\N{U+2B1C}",  # WHITE LARGE SQUARE
    );

sub result {
    my $obj = shift;
    my @result = _result(map lc, $obj->{answer}, @{$obj->{attempts}});
    my $result = join "\n", map s/([GYK])/$square{$1}/ger, @result;
    $result;
}

sub _result {
    my $answer = shift;
    my %a = map { $_ => 1 } my @a = $answer =~ /./g;
    map {
	my @b = /./g;
	join '', pairwise {
	    $a eq $b ? 'G' : $a{$b} ? 'Y' : 'K'
	} @a, @b;
    } @_;
}

######################################################################
# hint
######################################################################

my %hint_color = (
    G => 'G',
    Y => 'Y',
    K => 'KU',
    _ => 'K',
    );

sub hint_color {
    my $obj = shift;
    map keycolor($obj->map, \%hint_color, $_), @_;
}

sub hint {
    my $obj = shift;
    my $pattern = _hint(map lc, $obj->{answer}, @{$obj->{attempts}});
}

sub _hint {
    my $answer = shift;
    my %a = map { $_ => 1 } my @a = $answer =~ /./g;
    my(@yes, @no);
    my $seen = '';
    map {
	my @b = /./g;
	for my $i (0 .. $#b) {
	    if ($a{$b[$i]}) {
		$seen .= $b[$i];
	    } else {
		$seen .= "-$b[$i]";
	    }
	    if ($a[$i] eq $b[$i]) {
		$yes[$i] = $a[$i];
	    } else {
		$no[$i] .= $b[$i];
	    }
	}
    } @_;
    my $match = join '', pairwise {
	$b = join '', uniq $b =~ /./g if $b;
	$a ? $a : "[^$b]";
    } @yes, @no;
    my $in = join '', map { "(?=.*$_)" } uniq $seen =~ /(?<!-)\w/g;
    my $ex = sprintf '(?!.*[%s])', join('', uniq $seen =~ /(?<=-)\w/g);
    $in . $ex . $match;
}

1;
