package App::Greple::wordle::hint;
use v5.14;
use warnings;

use Exporter 'import';
our @EXPORT_OK;

use Data::Dumper;
use List::MoreUtils qw(pairwise);
use Getopt::EX::Colormap qw(colorize);

######################################################################
# keymap
######################################################################

push @EXPORT_OK, qw(&keymap);

my %cmap = (
    G => '555/#6aaa64',
    Y => '555/#c9b458',
    K => '#787c7e/#787c7e',
    _ => '555/#787c7e',
    );

sub keymap {
    my %keys = make_keymap(map lc, @_);
    my $keys = join '', map colorize($cmap{$keys{$_}//'_'}, $_), 'a'..'z';
    $keys;
}

sub make_keymap {
    my $answer = shift;
    my %a = map { $_ => 1 } my @a = $answer =~ /./g;
    my %keys;
    for my $try (@_) {
	my @b = $try =~ /./g;
	pairwise { $keys{$a} = 'G' if $a eq $b } @a, @b;
	$keys{$_} ||= $a{$_} ? 'Y' : 'K' for @b;
    }
    %keys;
}

######################################################################
# result
######################################################################

push @EXPORT_OK, qw(&result);

my %square = (
    G => "\N{U+1F7E9}", # LARGE GREEN SQUARE
    Y => "\N{U+1F7E8}", # LARGE YELLOW SQUARE
    K => "\N{U+2B1C}",  # WHITE LARGE SQUARE
    );

sub result {
    my @result = make_result(map lc, @_);
    my $result = join "\n", map s/([GYK])/$square{$1}/ger, @result;
    $result;
}

sub make_result {
    my $answer = shift;
    my %a = map { $_ => 1 } my @a = $answer =~ /./g;
    map {
	my @b = /./g;
	join '', pairwise {
	    $a eq $b ? 'G' : $a{$b} ? 'Y' : 'K'
	} @a, @b;
    } @_;
}

1;
