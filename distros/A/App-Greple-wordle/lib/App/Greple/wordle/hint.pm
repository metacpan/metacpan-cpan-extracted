package App::Greple::wordle::hint;
use v5.14;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(&keymap);

use Data::Dumper;
use List::MoreUtils qw(pairwise);
use Getopt::EX::Colormap qw(colorize);

my %cmap = (
    G => '555/#6aaa64',
    Y => '555/#c9b458',
    K => '#787c7e/#787c7e',
    _ => '',
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
1;
