package App::Greple::wordle;
use v5.14;
use warnings;
use utf8;

our $VERSION = "0.05";

use Data::Dumper;
use List::Util qw(shuffle min max);
use Getopt::EX::Colormap qw(colorize ansi_code);
use Text::VisualWidth::PP 0.05 'vwidth';
use App::Greple::wordle::word_all    qw(%word_all);
use App::Greple::wordle::word_hidden qw(@word_hidden);
use App::Greple::wordle::hint qw(&keymap &result);

our %opt = ( answer  => \( our $answer      = $ENV{WORDLE_ANSWER} ),
	     index   => \( our $index       = $ENV{WORDLE_INDEX} ),
	     count   => \( our $count       = 6 ),
	     max     => \( our $max         = 30 ),
	     random  => \( our $random      = 0 ),
	     seed    => \( our $seed        = 0 ),
	     compat  => \( our $compat      = 0 ),
	     keymap  => \( our $keymap      = 1 ),
	     result  => \( our $result      = 1 ),
	     correct => \( our $msg_correct = "\N{U+1F389}" ), # PARTY POPPER
	     wrong   => \( our $msg_wrong   = "\N{U+1F4A5}" ), # COLLISION SYMBOL
	   );
my $try = 0;
my @answers;

sub respond {
    local $_ = $_;
    my $chomped = chomp;
    print ansi_code("{CHA}{CUU}") if $chomped;
    print ansi_code(sprintf("{CHA}{CUF(%d)}", max(8, vwidth($_) + 2)));
    print s/(?<=.)\z/\n/r for @_;
}

sub setopt {
    my %arg = @_;
    for (keys %opt) {
	defined $arg{$_} or next;
	if (ref $opt{$_}) {
	    ${$opt{$_}} = $arg{$_};
	} else {
	    $opt{$_} = $arg{$_};
	}
    }
    ();
}

sub finalize {
    my($mod, $argv) = @_;
    push @$argv, '--interactive', ('/dev/stdin') x $max
	if -t STDIN;
}

sub days {
    use Date::Calc qw(Delta_Days);
    my($mday, $mon, $year, $yday) = (localtime(time))[3,4,5,7];
    Delta_Days(2021, 6, 19, $year + 1900, $mon + 1, $mday);
}

sub wordle_patterns {
    $index   = rand(@word_hidden) if $random;
    $index //= days;
    $index  += days if $index < 0;
    if (not $compat) {
	srand($seed);
	@word_hidden = shuffle @word_hidden;
    }
    $answer ||= $word_hidden[ $index ];
    $answer =~ /^[a-z]{5}$/i or die "$answer: wrong word\n";

    my $green  = join '|', map sprintf("(?<=^.{%d})%s", $_, substr($answer, $_, 1)), 0..4;
    my $yellow = "[$answer]";
    my $black  = "(?=[a-z])[^$answer]";

    map { ( '--re' => $_ ) } $green, $yellow, $black;
}

sub show_answer {
    say colorize('#6aaa64', uc $answer);
}

sub show_result {
    printf("\n%s %d%s %d/%d\n\n",
	   $compat ? 'Wordle?' : 'Greple::wordle',
	   $index,
	   $compat || $seed == 0 ? '' : "($seed)",
	   $try + 1, $count);
    say result($answer, @answers);
}

sub check {
    my $it = lc s/\n//r;
    if (not $word_all{$it}) {
	respond $msg_wrong;
	$_ = '';
    } else {
	push @answers, $it;
	print ansi_code '{CUU}';
    }
}

sub inspect {
    my $it = lc s/\n//r;
    if (lc $it eq lc $answer) {
	respond $msg_correct x ($count - $try);
	show_result if $result;
	exit 0;
    }
    length or return;
    if (++$try >= $count) {
	show_answer;
	exit 1;
    }
    $keymap and respond keymap($answer, @answers);
}

1;

__DATA__

mode function

builtin count=i $count
builtin keymap! $keymap
builtin result! $result

option --wordle &wordle_patterns
option --answer &setopt(answer=$<shift>)
option --index  &setopt(index=$<shift>)
option --series &setopt(seed=$<shift>)
option --random &setopt(random=1)
option --compat &setopt(compat=1)

define GREEN  #6aaa64
define YELLOW #c9b458
define BLACK  #787c7e

option default \
	-i --need 1 --no-filename \
	--cm 555/GREEN  \
	--cm 555/YELLOW \
	--cm 555/BLACK  \
	$<move> \
	--wordle

# --interactive is set in initialize() when stdin is a tty

option --interactive \
       --if 'head -1' \
       --begin    __PACKAGE__::check   \
       --end      __PACKAGE__::inspect \
       --epilogue __PACKAGE__::show_answer
