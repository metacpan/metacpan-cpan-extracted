package App::Greple::wordle;
use v5.14;
use warnings;
use utf8;

our $VERSION = "0.02";

use Data::Dumper;
use Date::Calc qw(Delta_Days);
use charnames ':full';
use Getopt::EX::Colormap 'colorize';
use App::Greple::wordle::word_all    qw(%word_all);
use App::Greple::wordle::word_hidden qw(@word_hidden);

my $try = 6;
my $answer = $ENV{WORDLE_ANSWER};
my $random = $ENV{WORDLE_RANDOM};
my $compat = $ENV{WORDLE_COMPAT};
my $msg_correct = "\N{PARTY POPPER}";
my $msg_wrong   = "\N{COLLISION SYMBOL}";
my @answers;

sub initialize {
    my($mod, $argv) = @_;

    push @$argv, '--interactive', ('/dev/stdin') x 30
	if -t STDIN;

    my($mday, $mon, $year, $yday) = (localtime(time))[3,4,5,7];
    my $index = Delta_Days(2021, 6, 19, $year + 1900, $mon + 1, $mday);
    unless ($compat) {
	srand($index) unless $random;
	$index = int rand(@word_hidden);
    }
    $answer ||= $word_hidden[ $index ];
    length($answer) == 5 or die "$answer: wrong word\n";

    my $green = do {
	my @green;
	for my $n (0 .. 4) {
	    my $c = substr($answer, $n, 1);
	    push @green, "(?<=^.{$n})$c";
	}
	do { $" = '|'; qr/@green/mi };
    };
    my $yellow = qr/[$answer]/i;
    my $black  = qr/(?=[a-z])[^$answer]/i;

    $mod->setopt('--wordle',
		 qw( --cm 555/6aaa64 --re ), "$green",
		 qw( --cm 555/c9b458 --re ), "$yellow",
		 qw( --cm 555/787c7e --re ), "$black",
	);
}

sub check {
    chomp;
    if (not $word_all{lc $_}) {
	say $msg_wrong;
	$_ = '';
    } else {
	push @answers, $_;
	$try--;
    }
}

sub inspect {
    if (lc $_ eq $answer) {
	say $msg_correct;
	exit 0;
    }
    if ($try == 0) {
	show_answer();
	exit 1;
    }
}

sub show_answer {
    say colorize('555/G', uc $answer);
}

1;

__DATA__

# --wordle option is defined in initialize()

option default --need 1 --no-filename --wordle

# --interactive is set in initialize() when stdin is a tty

option --interactive \
       --if 'head -1' \
       --begin    &__PACKAGE__::check   \
       --end      &__PACKAGE__::inspect \
       --epilogue &__PACKAGE__::show_answer
