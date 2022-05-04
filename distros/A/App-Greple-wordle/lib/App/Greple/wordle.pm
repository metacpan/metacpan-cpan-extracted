package App::Greple::wordle;
use v5.14;
use warnings;
use utf8;

our $VERSION = "0.11";

use Data::Dumper;
use List::Util qw(shuffle max);
use Try::Tiny;
use Getopt::EX::Colormap qw(colorize ansi_code);
use Text::VisualWidth::PP 0.05 'vwidth';
use App::Greple::wordle::word_all    qw(@word_all %word_all);
use App::Greple::wordle::word_hidden qw(@word_hidden);
use App::Greple::wordle::game;
use App::Greple::wordle::util qw();

use Getopt::EX::Hashed; {
    has answer  => '   =s ' , default => $ENV{WORDLE_ANSWER} ;
    has index   => ' n =i ' , default => $ENV{WORDLE_INDEX} ;
    has try     => ' x =i ' , default => 6 ;
    has total   => '   =i ' , default => 30 ;
    has random  => '   !  ' , default => 0 ;
    has series  => ' s =i ' , default => 1 ;
    has compat  => '      ' , action  => sub { $_->{series} = 0 } ;
    has keymap  => '   !  ' , default => 1 ;
    has result  => '   !  ' , default => 1 ;
    has correct => '   =s ' , default => "\N{U+1F389}" ; # PARTY POPPER
    has wrong   => '   =s ' , default => "\N{U+1F4A5}" ; # COLLISION SYMBOL
    has debug   => '   !  ' ;
}
no Getopt::EX::Hashed;

sub parseopt {
    my $app = shift;
    my $argv = shift;
    use Getopt::Long qw(GetOptionsFromArray Configure);
    Configure qw(bundling no_getopt_compat pass_through);
    $app->getopt($argv) || die "Option parse error.\n";
    $app;
}

sub _days {
    use Date::Calc qw(Delta_Days);
    my($mday, $mon, $year, $yday) = (localtime(time))[3,4,5,7];
    Delta_Days(2021, 6, 19, $year + 1900, $mon + 1, $mday);
}

sub setup {
    my $app = shift;
    for ($app->{index}) {
	$_   = int rand @word_hidden if $app->{random};
	$_ //= _days;
	$_  += _days if /^[-+]/;
    }
    if (my $answer = $app->{answer}) {
	$app->{index} = undef;
	$word_all{$answer} or die "$answer: wrong word\n";
    } else {
	if ($app->{series} > 0) {
	    srand($app->{series});
	    @word_hidden = shuffle @word_hidden;
	}
	$app->{answer} = $word_hidden[ $app->{index} ];
    }
}

sub patterns {
    my $app = shift;
    my $answer = $app->{answer};
    my @re = map
	    { sprintf "(?<=^.{%d})%s", $_, substr($answer, $_, 1) }
	    0 .. length($answer) - 1;
    my $green  = join '|', @re;
    my $yellow = "[$answer]";
    my $black  = "(?=[a-z])[^$answer]";
    map { ( '--re' => $_ ) } $green, $yellow, $black;
}

sub title {
    my $app = shift;
    my $label = 'Greple::wordle';
    return $label if not defined $app->{index};
    sprintf('%s %s%s',
	    $label,
	    $app->{series} == 0 ? '' : sprintf("%d-", $app->{series}),
	    $app->{index});
}

######################################################################

my $app = __PACKAGE__->new or die;
my $game;
my $interactive;

sub prompt {
    sprintf '%d: ', $game->attempt + 1;
}

sub initialize {
    my($mod, $argv) = @_;
    $app->parseopt($argv)->setup;
    $game = App::Greple::wordle::game->new(answer => $app->{answer});
    push @$argv, $app->patterns;
    if ($interactive = -t STDIN) {
	push @$argv, '--interactive', ('/dev/stdin') x $app->{total};
	select->autoflush;
	say $app->title;
	print prompt();
    }
}

sub respond {
    local $_ = $_;
    my $chomped = chomp;
    print ansi_code("{CHA}{CUU}") if $chomped;
    print ansi_code(sprintf("{CHA(%d)}",
			    max(11, vwidth($_) + length(prompt()) + 2)));
    print s/(?<=.)\z/\n/r for @_;
}

sub show_answer {
    say colorize('#6aaa64', uc $game->answer);
}

sub show_result {
    printf "\n%s %d/%d\n\n", $app->title, $game->attempt, $app->{try};
    say $game->result;
}

sub check {
    my $word = lc s/\n//r;
    if (not $word_all{$word}) {
	command($word) or respond $app->{wrong};
	$_ = '';
    } else {
	$game->try($word);
    }
}

sub command {
    my $word = shift;
    my @cmd = split ' ', $word or return;
    my @word = @word_all;
    state @remember;
    $cmd[0] =~ /^u(niq)?$/ and unshift @cmd, 'hint';

    while (@cmd) {
	local $_ = shift @cmd;
	try {
	    if    ($_ eq '|')   {}
	    elsif (/^d$/)       {
		$app->{debug} ^= 1;
		printf 'Debug %s', $app->{debug} ? 'on' : 'off';
		return;
	    }
	    elsif (/^\?$/)      { help(); return }
	    elsif (/^!!$/)      { @word = @remember }
	    elsif (/^h(int)?$/) { @word = choose($game->hint, @word) }
	    elsif (/^u(niq)?$/) { @word = grep { !/(.).*\1/i } @word }
	    elsif (/^=(.+)/)    { @word = choose(includes($1), @word) }
	    elsif (/^!(.+)/)    { @word = choose("^(?!.*[$1])", @word) }
	    elsif (/\W/)        { @word = choose($_, @word); }
	    else  { return }
	    1;
	} or do {
	    warn "ERROR: $_" if $app->{debug};
	    return /^[a-z]+$/i ? 0 : 1;
	};
    }
    if (@word == 0) {
	warn "No match\n";
	return 1;
    }
    @remember = @word;
    do {
	local $, = ' ';
	say $game->hint_color(@word);
    };
    1;
}

sub help {
    my $message = << "    END";
#   d      debug
    ?      help
    h      show hint
    u      uniq
    !!     repeat last result
    =<str> include characters
    !<str> exclude characters
    END
    print $message =~ s/^\s*(#.*)\n//gr;
}

sub includes {
    '^' . join '', map { "(?=.*$_)" } $_[0] =~ /./g;
}

sub choose {
    my $p = shift;
    $p =~ s/([A-Z])/[^$1]/g;
    warn "> $p\n" if $app->{debug};
    grep /$p/, @_;
}

sub inspect {
    if ($game->solved) {
	respond $app->{correct} x ($app->{try} - $game->attempt + 1);
	show_result if $app->{result};
	exit 0;
    }
    if (length) {
	if ($game->attempt >= $app->{try}) {
	    show_answer;
	    exit 1;
	}
	$app->{keymap} and respond $game->keymap;
    }
    print prompt();
}

1;

__DATA__

mode function

define GREEN  #6aaa64
define YELLOW #c9b458
define BLACK  #787c7e

option default \
	-i --need 1 --no-filename \
	--cm 555/GREEN  \
	--cm 555/YELLOW \
	--cm 555/BLACK

# --interactive is set in initialize() when stdin is a tty

option --interactive \
       --if 'head -1' \
       --begin    __PACKAGE__::check   \
       --end      __PACKAGE__::inspect \
       --epilogue __PACKAGE__::show_answer
