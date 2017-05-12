package App::mirai::Subprocess;
$App::mirai::Subprocess::VERSION = '0.003';
use strict;
use warnings;

use Scalar::Util qw(refaddr);

use App::mirai::Future;

sub setup {
	my ($class, $notify) = @_;
	my $w = App::mirai::Future->create_watcher;
	$w->subscribe_to_event(
		create => sub {
			my ($ev, $f) = @_;
			my $info = App::mirai::Future->future($f);
			my $copy = { %$info };
			delete $copy->{future};
			$notify->(create => {
				%$copy,
				id => refaddr($f),
				class => ref($f),
				deps => [ map refaddr($_), @{ $f->{deps} || [] } ],
				subs => [ map refaddr($_), @{ $f->{subs} || [] } ],
			});
		},
		label => sub {
			my ($ev, $f) = @_;
			$notify->(label => {
				id => refaddr($f),
				class => ref($f),
				label => $f->label,
			});
		},
		on_ready => sub {
			my ($ev, $f) = @_;
			my $info = App::mirai::Future->future($f);
			$notify->(ready => {
				id => refaddr($f),
				class => ref($f),
				elapsed => $f->elapsed,
				status => $info->{status},
				ready_at => $info->{ready_at},
				ready_stack => $info->{ready_stack},
			});
		},
		destroy => sub {
			my ($ev, $f) = @_;
			return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
			my $info = App::mirai::Future->future($f);
			$notify->(destroy => {
				id => refaddr($f),
				class => ref($f),
			});
		},
	);
	$w
}

1;

