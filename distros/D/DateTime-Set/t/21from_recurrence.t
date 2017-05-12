# Tests DateTime::Set built with from_recurrence
# Copyright (c) 2009 Olivier Mengué
# License: same as DateTime-Set-0.26 or any later version

use Test::More;
use DateTime::Set;

diag('Test suite by Olivier Mengue < dolmen cpan org >');

my @set = map {
    DateTime->new(
        year   => $_->[0],
        month  => $_->[1],
        day    => $_->[2],
        hour   => $_->[3],
        minute => $_->[4],
        second => $_->[5],
      )
  }
  map { [ split /[-T:]/ ] }
  qw/
  2009-02-27T08:50:05
  2009-02-27T09:05:05
  2009-02-27T09:20:05
  2009-03-02T09:05:05
  2009-03-02T09:20:05
  2009-03-03T09:05:05
  2009-03-03T09:20:05
  /;

plan tests =>
	 ($#set+1+4)    # no span, next()
	+($#set+1+4)    # no span, previous
	+($#set+1+4)    # start, next()
	+($#set  +4)    # after, next()
	+($#set+1+4)    # end, previous()
	+($#set  +4)    # before, previous()
	+($#set+1+4)    # start, previous()
	+($#set  +4)    # after, previous()
	+($#set+1+4)    # end, next()
	+($#set  +4)    # before, next()
;

my $start = $set[0];

sub diag_sub
{
	my ($name, $sub) = (shift, shift);
	exists $INC{'Test::More'} or eval { use Test::More }; 
	return sub {
		diag("$name(", join(', ', @_), ")");
		if (wantarray) {
			my @ret = $sub->(@_);
			diag('=> ', @ret);
			return @ret
		} else {
			my $ret = $sub->(@_);
			diag('=> ', $ret);
			return $ret;
		}
	}
}

my $dts = do {
	my $idx = 0;
	DateTime::Set->from_recurrence(
		next => diag_sub(next => sub {
			return $set[($idx = 0)] if ($_[0] <=> DateTime::NEG_INFINITY) <= 0; 
			return DateTime::Infinite::Future->new if $_[0]->is_infinite or $idx == $#set;
			return $set[++$idx];
		}),
		previous => diag_sub(previous => sub {
			return $set[($idx = $#set)] if ($_[0] <=> DateTime::INFINITY) >= 0;
			return DateTime::Infinite::Past->new if $_[0]->is_infinite or $idx == 0;
			return $set[--$idx];
		})
	)
}; 



diag("no span, next()");
{
	my $it = $dts->iterator;
	# ->current is "less or equal to"
	is($it->current(DateTime::Infinite::Past->new), undef, "current(Past) is empty");
	is($it->current(DateTime::Infinite::Future->new), $set[-1], "current(Future) is $set[-1]");
	for my $d (@set) {
		is($it->next, $d, $d);
	}
	is($it->next, undef, "set end -> undef");

	# The set is now empty
	is($it->previous(DateTime::Infinite::Future->new), undef, "set is now empty");
}
	
diag("no span, previous()");
{
	my $it = $dts->iterator;
	is($it->current(DateTime::Infinite::Past->new), undef, "current(Past) is empty");
	is($it->current(DateTime::Infinite::Future->new), $set[-1], "current(Future) is $set[-1]");
	for my $d (reverse @set) {
		is($it->previous, $d, $d);
	}
	is($it->previous, undef, "end -> undef");
	# The set is now empty
	is($it->previous(DateTime::Infinite::Future->new), undef, "set is now empty");
}

diag("start, next()");
{
	my $it = $dts->iterator(start => $set[0]);
	is($it->current(DateTime::Infinite::Past->new), undef, "current(Past) is empty");
	is($it->current(DateTime::Infinite::Future->new), $set[-1], "current(Future) is $set[-1]");
	for my $d (@set) {
		is($it->next, $d, $d);
	}
	is($it->next, undef, "end -> undef");
	# The set is now empty
	is($it->previous(DateTime::Infinite::Future->new), undef, "set is now empty");
}

diag("after, next()");
{
	my $it = $dts->iterator(after => $set[0]);
	is($it->current(DateTime::Infinite::Past->new), undef, "current(Past) is empty");
	is($it->current(DateTime::Infinite::Future->new), $set[-1], "current(Future) is $set[-1]");
	for my $d (@set[1..$#set]) {
		is($it->next, $d, $d);
	}
	is($it->next, undef, "end -> undef");
	# The set is now empty
	is($it->previous(DateTime::Infinite::Future->new), undef, "set is now empty");
}

diag("end, previous()");
{
	my $it = $dts->iterator(end => $set[-1]);
	is($it->current(DateTime::Infinite::Past->new), undef, "current(Past) is empty");
	is($it->current(DateTime::Infinite::Future->new), $set[-1], "current(Future) is $set[-1]");
	for my $d (reverse @set) {
		is($it->previous, $d, $d);
	}
	is($it->previous, undef, "end -> undef");
	# The set is now empty
	is($it->previous(DateTime::Infinite::Future->new), undef, "set is now empty");
}

diag("before, previous()");
{
	my $it = $dts->iterator(before => $set[-1]);
	is($it->current(DateTime::Infinite::Past->new), undef, "current(Past) is empty");
	is($it->current(DateTime::Infinite::Future->new), $set[-2], "current(Future) is $set[-2]");
	for my $d (reverse @set[0..$#set-1]) {
		is($it->previous, $d, $d);
	}
	is($it->previous, undef, "end -> undef");
	# The set is now empty
	is($it->previous(DateTime::Infinite::Future->new), undef, "set is now empty");
}


diag("start, previous()");
{
	my $it = $dts->iterator(start => $set[0]);
	is($it->current(DateTime::Infinite::Past->new), undef, "current(Past) is empty");
	is($it->current(DateTime::Infinite::Future->new), $set[-1], "current(Future) is $set[-1]");
	for my $d (reverse @set) {
		is($it->previous, $d, $d);
	}
	is($it->previous, undef, "end -> undef");
	# The set is now empty
	is($it->previous(DateTime::Infinite::Future->new), undef, "set is now empty");
}

diag("after, previous()");
{
	my $it = $dts->iterator(after => $set[0]);
	is($it->current(DateTime::Infinite::Past->new), undef, "current(Past) is empty");
	is($it->current(DateTime::Infinite::Future->new), $set[-1], "current(Future) is $set[-1]");
	for my $d (reverse @set[1..$#set]) {
		is($it->previous, $d, $d);
	}
	is($it->previous, undef, "end -> undef");
	# The set is now empty
	is($it->previous(DateTime::Infinite::Future->new), undef, "set is now empty");
}


diag("end, next()");
{
	my $it = $dts->iterator(end => $set[-1]);
	is($it->current(DateTime::Infinite::Past->new), undef, "current(Past) is empty");
	is($it->current(DateTime::Infinite::Future->new), $set[-1], "current(Future) is $set[-1]");
	for my $d (@set) {
		is($it->next, $d, $d);
	}
	is($it->next, undef, "end -> undef");
	# The set is now empty
	is($it->previous(DateTime::Infinite::Future->new), undef, "set is now empty");
}

diag("before, next()");
{
	my $it = $dts->iterator(before => $set[-1]);
	is($it->current(DateTime::Infinite::Past->new), undef, "current(Past) is empty");
	is($it->current(DateTime::Infinite::Future->new), $set[-2], "current(Future) is $set[-2]");
	for my $d (@set[0..$#set-1]) {
		is($it->next, $d, $d);
	}
	is($it->next, undef, "end -> undef");
	# The set is now empty
	is($it->previous(DateTime::Infinite::Future->new), undef, "set is now empty");
}
