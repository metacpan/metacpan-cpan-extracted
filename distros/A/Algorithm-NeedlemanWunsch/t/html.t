#!/usr/bin/perl

use strict;
use warnings;

use Algorithm::NeedlemanWunsch;
use Test::More tests => 6;

my @haystack = qw(div span font /font /span a /a table tr td font span /span a /a br span a /a /span br br span /span nobr a /a /nobr /font /td /tr /table /div);

my @needle = qw(div a /a table tr td font br span /span nobr a /a a /a /nobr /font /td /tr /table /div);

my @background;
my @foreground;

sub score_sub {
    my ($a, $b) = @_;

    return ($a eq $b) ? 1 : -2;
}

sub prepend_align {
    my ($i, $j) = @_;

    unshift @background, $haystack[$i];
    unshift @foreground, $needle[$j];
}

sub prepend_first_only {
    my $i = shift;

    unshift @background, $haystack[$i];
    unshift @foreground, '-';
}

sub prepend_second_only {
    my $j = shift;

    unshift @background, '-';
    unshift @foreground, $needle[$j];
}

my $matcher = Algorithm::NeedlemanWunsch->new(\&score_sub, -1);
$matcher->local(1);
my $score = $matcher->align(\@haystack, \@needle,
			    {
			     align => \&prepend_align,
			     shift_a => \&prepend_first_only,
			     shift_b => \&prepend_second_only
			    });
is($score, 5);
is_deeply(\@background,
	  [ 'div', 'span', 'font', '/font', '/span', '-', 'a', '/a',
	    'table', 'tr', 'td', 'font', '-', 'span', '/span',
	    'a', '/a', 'br', 'span', 'a', '/a', '/span', 'br', 'br',
	    'span', '/span', 'nobr', 'a', '/a', '/nobr', '/font',
	    '/td', '/tr', '/table', '/div' ]);
is_deeply(\@foreground,
	  [ '-', '-', '-', '-', '-', 'div', 'a', '/a', 'table', 'tr',
	    'td', 'font', 'br', 'span', '/span', '-', '-', '-',
	    'nobr', 'a', '/a', '-', '-', '-', '-', '-', '-', 'a',
	    '/a', '/nobr', '/font', '/td', '/tr', '/table', '/div' ]);

@background = ();
@foreground = ();
$matcher = Algorithm::NeedlemanWunsch->new(\&score_sub);
$matcher->local(1);
$matcher->gap_open_penalty(-2);
$matcher->gap_extend_penalty(-1);
$score = $matcher->align(\@haystack, \@needle,
			 {
			  align => \&prepend_align,
			  shift_a => \&prepend_first_only,
			  shift_b => \&prepend_second_only
			 });
is($score, 3);
is_deeply(\@background,
	  [ 'div', 'span', 'font', '/font', '/span', 'a', '/a',
	    'table', 'tr', 'td', 'font', 'span', '/span',
	    'a', '/a', 'br', 'span', '-', 'a', '/a', '-', '-', '/span',
	    'br', 'br', 'span', '/span', 'nobr', '-', '-', 'a', '/a',
	    '/nobr', '/font', '/td', '/tr', '/table', '/div' ]);
is_deeply(\@foreground,
	  [ '-', '-', '-', '-', '-', '-', '-', '-', '-', '-', '-', '-',
	    '-', '-', '-', '-', '-', 'div', 'a', '/a', 'table', 'tr', 
	    'td', 'font', 'br', 'span', '/span', 'nobr', 'a', '/a',
	    'a', '/a', '/nobr', '/font', '/td', '/tr', '/table',
	    '/div' ]);
