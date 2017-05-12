use strict;
use warnings;

use Test::More;
use App::mirai::Future;
use Variable::Disposition;

can_ok(Future => qw(new set_label DESTROY));
is($Future::TIMES, 1, 'timing enabled');

{ # Future tracking
	is(App::mirai::Future->futures, 0, 'no futures yet');
	my $f = new_ok(Future => );
	is(App::mirai::Future->futures, 1, 'we now have a future');
	is((App::mirai::Future->futures)[0], $f, 'and it is the same future we created');
	dispose $f;
	is(App::mirai::Future->futures, 0, 'back to zero futures after throwing that one away');
}

{ # watchers
	my $w = App::mirai::Future->create_watcher;
	isa_ok($w, 'App::mirai::Watcher');
	my $count = 0;
	$w->subscribe_to_event(
		create => sub {
			my ($ev, $f) = @_;
			++$count;
			isa_ok($f, 'Future');
			ok((1 == grep $_ == $f, App::mirai::Future->futures), 'is listed in ->futures');
		},
		destroy => sub {
			my ($ev, $f) = @_;
			--$count;
			isa_ok($f, 'Future');
			ok((1 == grep $_ == $f, App::mirai::Future->futures), 'still listed in ->futures');
		}
	);
	is($count, 0, 'count starts at zero');
	my $f = new_ok('Future');
	is($count, 1, 'count now 1');
	dispose $f;
	is($count, 0, 'count now 0');
	ok((0 == grep $_ == $f, App::mirai::Future->futures), 'was removed from ->futures');
	App::mirai::Future->delete_watcher($w);
	{
		my $f = Future->new;
		is($count, 0, 'count still 0 after removing watcher');
	}
}

{ # ->done
	my $w = App::mirai::Future->create_watcher;
	$w->subscribe_to_event(
		on_ready => sub {
			my ($ev, $f) = @_;
			ok($f->is_done, 'was marked as done');
			$ev->unsubscribe;
		}
	);
	my $f = Future->new->done;
}
{ # ->fail
	my $w = App::mirai::Future->create_watcher;
	$w->subscribe_to_event(
		on_ready => sub {
			my ($ev, $f) = @_;
			ok($f->is_failed, 'was marked as failed');
			$ev->unsubscribe;
		}
	);
	my $f = Future->new->fail(1);
	$w->discard;
}
{ # ->fail
	my $w = App::mirai::Future->create_watcher;
	$w->subscribe_to_event(
		on_ready => sub {
			my ($ev, $f) = @_;
			ok($f->is_cancelled, 'was marked as cancelled');
			$ev->unsubscribe;
		}
	);
	my $f = Future->new->cancel;
	$w->discard;
}
{ # ->needs_all
	my $w = App::mirai::Future->create_watcher;
	my $count = 0;
	$w->subscribe_to_event(
		create => sub {
			my ($ev, $f) = @_;
			++$count;
		},
		destroy => sub {
			my ($ev, $f) = @_;
			--$count;
		},
		on_ready => sub {
			my ($ev, $f) = @_;
			if(exists $f->{subs}) {
				ok($f->is_failed, 'dep failed');
			} else {
				ok($f->is_cancelled, 'leaf marked as cancelled');
			}
		}
	);
	my @pending = map Future->new, 1..3;
	is($count, 3, 'created 3 futures');
	my $f = Future->needs_all(@pending);
	is($count, 4, 'created a dependent future');
	is_deeply(App::mirai::Future->future($f)->{subs}, \@pending, 'subs match');
	is_deeply(App::mirai::Future->future($_)->{deps}, [ $f ], 'listed in deps') for @pending;
	$pending[0]->cancel;
	$w->discard;
}

done_testing;

