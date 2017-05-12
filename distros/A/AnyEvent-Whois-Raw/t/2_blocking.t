#!/usr/bin/env perl

use strict;
use Test::More;
use AnyEvent::Whois::Raw;

if( $^O eq 'MSWin32' ) {
	plan skip_all => 'Fork ~~ Windows -> False';
}

my %rules = (
	'google.com' => {
		sleep => 2,
		info => 'Google Inc.'
	},
	'mail.com' => {
		sleep => 10,
		info => 'PSI-USA, Inc.'
	},
	'www.com' => {
		sleep => 0,
		info => 'Diagonal Axis Limited'
	},
	'2gis.com' => {
		sleep => 1,
		info => '"DoubleGIS" Ltd'
	},
	'academ.org' => {
		sleep => 3,
		info => 'Pervaya Milya'
	}
);

my ($pid, $host, $port) = make_whois_server(%rules);
my $start = time();
my $cv = AnyEvent->condvar;
$cv->begin for 1..scalar(keys %rules);

delete $rules{'mail.com'};
whois 'mail.com', "$host:$port", timeout => 3, sub {
	my ($info, $srv) = @_;
	is($info, '', 'mail.com timeout');
	ok(time()-$start < 10, 'mail.com timed out');
	$cv->end;
};

while (my ($domain, $rule) = each(%rules)) {
	whois $domain, "$host:$port", sub {
		my ($info, $srv) = @_;
		is($info, $rule->{info}, "$domain info");
		ok(time()-$start < $rule->{sleep}+2, "$domain was not blocked ");
		$cv->end;
	};
}

$cv->recv;
kill 15, $pid;
done_testing();

sub make_whois_server {
	my %rules = @_;
	my $serv = IO::Socket::INET->new(Listen => 3)
		or die $@;
	
	my $child = fork();
	die 'fork: ', $! unless defined $child;
	
	if ($child == 0) {
		my @childs;
		local $SIG{TERM} = sub { kill 9, @childs; exit };
		local $/ = "\012";
		while (1) {
			my $client = $serv->accept()
				or next;
			
			my $child = fork();
			die 'subfork: ', $! unless defined $child;
			
			if ($child == 0) {
				my $domain = <$client>;
				$domain =~ s/\s*$//;
				if (exists $rules{$domain}) {
					sleep $rules{$domain}{sleep};
					print $client $rules{$domain}{info};
				}
				exit;
			}
			else {
				push @childs, $child;
			}
		}
		
		exit;
	}
	
	return ($child, $serv->sockhost eq '0.0.0.0' ? '127.0.0.1' : $serv->sockhost, $serv->sockport);
}
