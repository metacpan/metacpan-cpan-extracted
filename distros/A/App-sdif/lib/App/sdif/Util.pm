package App::sdif::Util;

use v5.14;
use warnings;
use Carp;

use Exporter 'import';

our @EXPORT = qw(
    &read_unified_sub &read_unified &read_unified_2
    );

our @EXPORT_OK = qw(
    &read_unified_3
    );

use Data::Dumper;
use List::Util qw(sum);

our $MINILLA_CHANGES = 1;
our $NO_WARNINGS = 0;

sub read_unified_2 {
    map {
	[ $_->collect(qr/[\t ]/) ], # common
	[ $_->collect('-') ], # old
	[ $_->collect('+') ], # new
    } &read_unified;
}

sub nth_re {
    state @regex;
    my $n = shift;
    $regex[$n] //= do {
	my $regex = sprintf "^(?:.{%d}-|(?=.*\\+).{%d}[ ])", $n, $n;
	qr/$regex/;
    };
}

sub read_unified_3 {
    map {
	[ $_->collect(q/  /    ) ], # common
	[ $_->collect(nth_re(0)) ], # old ^(?:.{0}-|(?=.*\+).{0}[ ])
	[ $_->collect(nth_re(1)) ], # new ^(?:.{1}-|(?=.*\+).{1}[ ])
	[ $_->collect(qr/\+/   ) ], # merge
    } &read_unified;
}

sub read_unified_sub {
    my $column = shift;
    my @re = ( ' ' x ($column - 1),
	       map(nth_re($_), 0 .. $column - 2),
	       qr/\+/ );
    sub {
	map {
	    my $ent = $_;
	    map { [ $ent->collect($_) ] } @re;
	} &read_unified;
    }
}

sub read_unified {
    # Option: prefix, ORDER, NOWARN
    my $opt = ref $_[0] eq 'HASH' ? shift : {};
    my $FH = shift;
    my $column = @_;
    my $total = sum @_;
    my $prefix = $opt->{prefix} // '';

    use App::sdif::LabelStack;

    my $mark_length = $column - 1;
    my $start_label = ' ' x $mark_length;
    my @lsopt = do {
	map  { $_->[0] => $_->[1] }
	grep { $_->[1] }
	( [ START => $start_label  ],
	  [ ORDER => $opt->{ORDER} ] );
    };

    state $marklines = sub {
	local $_ = shift;
	tr/-/-/ || tr/ / / + 1;
    };

    my @stack = App::sdif::LabelStack->new(@lsopt);
    while (<$FH>) {
	if ($prefix) {
	    s/^\Q$prefix// or do {
		warn "Unexpected: $_" unless $NO_WARNINGS;
	    };
	    if ($MINILLA_CHANGES) {
		# Minilla removes single space mark in git commit message.
		# This is not perfect but mostly works.
		s/^(?![-+ ])/ /;
	    }
	}
	# `git diff' produces message like this:
	# "\ No newline at end of file"
	/^([-+ ]{$mark_length}|\t)/p or do {
	    unless (/^\\ /) {
		warn "Unexpected line: $_" unless $NO_WARNINGS;
	    }
	    next;
	};
	my $mark = $1;
	if (($mark ne $stack[-1]->lastlabel) and
	    ($stack[-1]->exists($mark)
	     # all +
	     or $stack[-1]->lastlabel !~ /[^+]/
	     # no + after +
	     or ($stack[-1]->lastlabel =~ /[+]/ and $mark !~ /[+]/))) {
	    push @stack, App::sdif::LabelStack->new(@lsopt);
	}
	$stack[-1]->append($mark, $_);
	$total -= $mark =~ /^\t/ ? $column : $marklines->($mark);
	last if $total <= 0;
    }
    @stack;
}

1;
