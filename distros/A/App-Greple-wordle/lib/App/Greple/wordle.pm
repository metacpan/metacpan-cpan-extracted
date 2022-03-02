package App::Greple::wordle;
use v5.14;
use warnings;
use utf8;

our $VERSION = "0.03";

use Data::Dumper;
use List::Util qw(shuffle);
use Date::Calc qw(Delta_Days);
use charnames ':full';
use Getopt::EX::Colormap qw(colorize ansi_code);
use App::Greple::wordle::word_all    qw(%word_all);
use App::Greple::wordle::word_hidden qw(@word_hidden);
use App::Greple::wordle::hint qw(&keymap);

our %opt = ( answer  => \( our $answer      = $ENV{WORDLE_ANSWER} ),
	     count   => \( our $try         = 6 ),
	     max     => \( our $max         = 30 ),
	     random  => \( our $random      = 0 ),
	     seed    => \( our $seed        = 42 ),
	     compat  => \( our $compat      = 0 ),
	     keymap  => \( our $keymap      = 1 ),
	     correct => \( our $msg_correct = "\N{PARTY POPPER}" ),
	     wrong   => \( our $msg_wrong   = "\N{COLLISION SYMBOL}" ),
	   );
my @answers;

sub respond {
    print ansi_code("{CUU}{CUF(8)}");
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

sub wordle_patterns {
    my($mday, $mon, $year, $yday) = (localtime(time))[3,4,5,7];
    my $index = Delta_Days(2021, 6, 19, $year + 1900, $mon + 1, $mday);
    if (not $compat) {
	srand($seed) if not $random;
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

sub check {
    chomp;
    if (not $word_all{lc $_}) {
	respond $msg_wrong;
	$_ = '';
    } else {
	push @answers, $_;
	$try--;
    }
}

sub inspect {
    if (lc $_ eq $answer) {
	respond $msg_correct;
	exit 0;
    }
    if ($try <= 0) {
	show_answer;
	exit 1;
    }
    if (length and $keymap) {
	respond keymap($answer, @answers);
    }
}

1;

__DATA__

mode function

builtin keymap! $keymap

option --wordle &wordle_patterns
option --answer &setopt(answer=$<shift>)
option --count  &setopt(count=$<shift>)
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
