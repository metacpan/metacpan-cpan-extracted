=encoding utf-8

=head1 NAME

App::Greple::wordle - wordle module for greple

=head1 SYNOPSIS

greple -Mwordle

=head1 VERSION

Version 1.00

=head1 DESCRIPTION

App::Greple::wordle is a greple module that implements the Wordle game.
Answer correctness is checked by regular expression.

This module supports multiple word datasets. Use the B<--data> option to
choose different word datasets such as the original Wordle word list
or the New York Times Wordle word list.

Rules are almost the same as the original game, but answers are different.
Use the B<--compat> option to get answers compatible with the original game.

=begin html

<p><img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-wordle/main/images/screen-6.png">

=end html

=head1 OPTIONS

=over 7

=item B<--data>=I<dataset>

Choose the word dataset.  Default is C<NYT>.

Available datasets:

=over 4

=item C<ORIGINAL>

The original word list from the initial Wordle game.  It contains the
classic Wordle word list.

=item C<NYT>

The New York Times Wordle word list, which includes words used by NYT
Wordle.  It may contain different words than the original.  This is
the default dataset.

When option B<--compat> is given and the answer for the index is not
included in the dataset, it is fetched from the New York Times web
site.  If it cannot be fetched, an answer is selected as described
in B<--index>.  Fetching requires L<IO::Socket::SSL>.

=back

Dataset modules are dynamically loaded from C<App::Greple::wordle::>
namespace with uppercase dataset name.

=item B<--series>=#,  B<-s>#

=item B<--compat>

Choose a different answer series.  Default is 1.  Series zero is the same as
the original game and option B<--compat> is a shortcut for
B<--series=0>.  If it is not zero, the answer set is shuffled by
pseudo-random numbers using the series number as an initial seed.

=item B<--index>=#, B<-n>#

Specify the answer index. The default index is calculated from days since
2021/06/19.  If the value is negative, you can get yesterday's
question by specifying -1.

=begin comment

Environment variable C<WORDLE_INDEX> is used as the default.

=end comment

If the specified index exceeds the available answer list, the answer
at the index modulo the number of answers is used.  A warning message
is shown for series zero, because the answer differs from the
original game.

Answer for option B<-s0n0> is C<cigar>.

=item B<-->[B<no->]B<result>

Show result when successful.  Default is true.

=item B<-->[B<no->]B<history>

Show previous attempts above the latest one, so that all attempts are
listed together.  Default is true.

=item B<--random>

Generate a random index every time.

=item B<--trial>=#, B<-x>#

Set the trial count.  Default is 6.

=begin comment

=item B<--answer>=I<word>

Set answer word.  For debug purpose.  Environment variable
C<WORDLE_ANSWER> is used as the default.

=item B<--total>=#

Set the maximum number of inputs, including commands and words not in
the word list.  Default is 30.

=item B<-->[B<no->]B<keymap>

Show the keymap next to the latest attempt.  Default is true.

=item B<--correct>=I<string>

Set the string shown when the answer is correct.  It is repeated by
the number of remaining attempts plus one.  Default is U+1F389 (PARTY
POPPER).

=item B<--wrong>=I<string>

Set the string shown for a word not in the word list or an unknown
command.  Default is U+1F4A5 (COLLISION SYMBOL).

=item B<-->[B<no->]B<debug>

Show regular expressions used by commands and command errors.  It can
be toggled by command B<d>.

=end comment

=back

=head1 COMMANDS

A five-letter word is processed as an answer.  Other input is taken
as a command.

=over 7

=item B<h>, B<hint>

List possible words.

=item B<u>, B<uniq>

List possible words made of unique characters.

=item B<=>I<chars>

If starting with equal (C<=>), list words that include all I<chars>.

=item B<!>I<chars>

If starting with exclamation mark (C<!>), list words that do not
include any of I<chars>.

=item I<regex>

Any other string including a non-alphabetical character will be taken as a
regular expression to filter words.

=item B<!!>

Recall the word list produced by the last command execution.

=begin comment

=item B<?>

Show help message.

=item B<d>

Toggle debug mode.  See option B<--debug>.

=end comment

=back

These commands can be connected in series.  For example, the following command
shows possible words starting with letter C<z>.

    hint ^z

The next example shows all words that do not include any letter of C<audio> and
C<rents>, and are made of unique characters.

    !audio !rents u

=head1 EXAMPLE

=head2 Basic gameplay

    1: solid                    # try word "solid"
    2: panic                    # try word "panic"
    3: hint                     # show hint
    3: !solid !panic =eft uniq  # search word exclude(solidpanic) include(eft)
    3: wheft                    # try word "wheft"
    4: hint                     # show hint
    4: datum                    # try word "datum"
    5: tardy                    # try word "tardy"

=head2 Using different datasets

    greple -Mwordle --data=NYT            # Use NYT Wordle word list (default)
    greple -Mwordle --data=ORIGINAL       # Use original word list
    greple -Mwordle --data=NYT -s0n0      # First word in NYT dataset (cigar)

=begin html

<p><img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-wordle/main/images/hint-1.png">

=end html

=head1 BUGS

A character in the wrong position is always colored yellow, even if it
appears in green elsewhere.

=head1 INSTALL

=head2 CPANMINUS

    $ cpanm App::Greple::wordle

=head1 SEE ALSO

L<App::Greple::wordle>, L<https://github.com/kaz-utashiro/greple-wordle>

L<App::Greple>, L<https://github.com/kaz-utashiro/greple>

L<https://qiita.com/kaz-utashiro/items/ba6696187f2ce902aa39>

L<https://github.com/alex1770/wordle>

L<https://wordfinder.yourdictionary.com/wordle/answers/>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2022-2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

#  LocalWords:  greple wordle localtime COMPAT Kazumasa Utashiro

package App::Greple::wordle;
use v5.14;
use warnings;
use utf8;

our $VERSION = "1.00";

use List::Util qw(shuffle max);
use Try::Tiny;
use Getopt::EX::Colormap qw(colorize ansi_code);
use Text::VisualWidth::PP 0.05 'vwidth';
use App::Greple::wordle::game;

use Getopt::EX::Hashed; {
    Getopt::EX::Hashed->configure( DEFAULT => [ is => 'rw' ] );
    has data    => '   =s ' , default => 'NYT' ;
    has answer  => '   =s ' , default => $ENV{WORDLE_ANSWER} ;
    has index   => ' n =i ' , default => $ENV{WORDLE_INDEX} ;
    has trial   => ' x =i ' , default => 6 ;
    has total   => '   =i ' , default => 30 ;
    has random  => '   !  ' , default => 0 ;
    has series  => ' s =i ' , default => 1 ;
    has compat  => '      ' , action  => sub { $_->series = 0 } ;
    has keymap  => '   !  ' , default => 1 ;
    has result  => '   !  ' , default => 1 ;
    has history => '   !  ' , default => 1 ;
    has correct => '   =s ' , default => "\N{U+1F389}" ; # PARTY POPPER
    has wrong   => '   =s ' , default => "\N{U+1F4A5}" ; # COLLISION SYMBOL
    has debug   => '   !  ' ;
}
no Getopt::EX::Hashed;

sub parseopt {
    my $app = shift;
    my $argv = shift;
    # GetOptionsFromArray is called in this package by Getopt::EX::Hashed
    use Getopt::Long qw(GetOptionsFromArray Configure);
    Configure qw(bundling no_getopt_compat pass_through);
    $app->getopt($argv) || die "Option parse error.\n";
    $app;
}

sub _days {
    use Date::Calc qw(Delta_Days);
    my($mday, $mon, $year) = (localtime(time))[3,4,5];
    Delta_Days(2021, 6, 19, $year + 1900, $mon + 1, $mday);
}

my(@word_all, %word_all, @word_hidden);

sub setup {
    my $app = shift;
    my $pkg = __PACKAGE__ . '::' . uc($app->data);
    eval "use $pkg";
    if ($@) {
	die "$app->{data}: no such data set\n" if $@ =~ /Can't locate/;
	die $@;
    } else {
	no strict 'refs';
	@word_all = @{"$pkg\::WORDS"};
	@word_hidden = @{"$pkg\::HIDDEN"};
    }
    $word_all{$_} = 1 for @word_all;
    for ($app->index) {
	$_   = int rand @word_hidden if $app->random;
	$_ //= _days;
	$_  += _days if /^[-+]/;
    }
    if (my $answer = $app->answer) {
	$app->index = undef;
	$word_all{$answer} or die "$answer: wrong word\n";
    } else {
	if ($app->series > 0) {
	    srand($app->series);
	    @word_hidden = shuffle @word_hidden;
	}
	# ask the dataset for an answer which is not in the local data
	my $fetch = $app->series == 0 && $pkg->can('fetch_answer');
	if ($app->index > $#word_hidden and $fetch
	    and my $answer = $fetch->($app->index)) {
	    push @word_all, $answer unless $word_all{$answer}++;
	    $app->answer = $answer;
	    return;
	}
	my $index = $app->index;
	if ($index > $#word_hidden) {
	    $index %= @word_hidden;
	    warn sprintf "no data for %d, so use answer #%d instead\n",
		$app->index, $index if $app->series == 0;
	}
	$app->answer = $word_hidden[ $index ];
    }
}

sub patterns {
    my $app = shift;
    my $answer = $app->answer;
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
    return $label if not defined $app->index;
    sprintf('%s %s%s',
	    $label,
	    $app->series == 0 ? '' : sprintf("%d-", $app->series),
	    $app->index);
}

######################################################################

my $app = __PACKAGE__->new or die;
my $game;

sub prompt {
    sprintf '%d: ', $game->attempt + 1;
}

sub initialize {
    my($mod, $argv) = @_;
    $app->parseopt($argv)->setup;
    $game = App::Greple::wordle::game->new(answer => $app->answer);
    push @$argv, $app->patterns;
    if (-t STDIN) {
	push @$argv, '--interactive', ('/dev/stdin') x $app->total;
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
    printf "\n%s %d/%d\n\n", $app->title, $game->attempt, $app->trial;
    say $game->result;
}

sub check {
    my $word = lc s/\n//r;
    if (not $word_all{$word}) {
	command($word) or respond $app->wrong;
	$_ = '';
    } else {
	# show previous attempts above the line greple prints
	say for $app->history ? $game->guess_color(@{$game->attempts}) : ();
	$game->try($word);
	# greple matches case-insensitively, so show the word in upper case
	$_ = uc $_;
    }
}

sub command {
    my $word = shift;
    my @cmd = split ' ', $word or return;
    my @word = @word_all;
    state @remember;
    my $done;
    $cmd[0] =~ /^u(niq)?$/ and unshift @cmd, 'hint';

    while (@cmd) {
	local $_ = shift @cmd;
	# "return" in try block only leaves the block, so use $done
	try {
	    if    ($_ eq '|')   {}
	    elsif (/^d$/)       {
		$app->debug ^= 1;
		printf "Debug %s\n", $app->debug ? 'on' : 'off';
		return $done = 1;
	    }
	    elsif (/^\?$/)      { help(); return $done = 1 }
	    elsif (/^!!$/)      { @word = @remember }
	    elsif (/^h(int)?$/) { @word = choose($game->hint, @word) }
	    elsif (/^u(niq)?$/) { @word = grep { !/(.).*\1/i } @word }
	    elsif (/^=(.+)/)    { @word = choose(includes($1), @word) }
	    elsif (/^!(.+)/)    { @word = choose("^(?!.*[$1])", @word) }
	    elsif (/\W/)        { @word = choose($_, @word); }
	    else  { return }
	    1;
	} or do {
	    warn "ERROR: $_" if $app->debug;
	    return /^[a-z]+$/i ? 0 : 1;
	};
	return 1 if $done;
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
    warn "> $p\n" if $app->debug;
    grep /$p/, @_;
}

sub inspect {
    if ($game->solved) {
	respond $app->correct x ($app->trial - $game->attempt + 1);
	show_result if $app->result;
	exit 0;
    }
    if (length) {
	if ($game->attempt >= $app->trial) {
	    show_answer;
	    exit 1;
	}
	$app->keymap and respond $game->keymap;
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
