#!/usr/bin/env perl

use strict;
use warnings;
use WWW::RT::CPAN;	# FIXME: use a REST client
use Data::Dumper;
use Test::Most tests => 3;

NOBUGS: {
	SKIP: {
		if($ENV{AUTHOR_TESTING}) {
			if(my @rc = @{WWW::RT::CPAN::list_dist_active_tickets(dist => 'DateTime-Format-Genealogy')}) {
				ok($rc[0] == 200);
				ok($rc[1] eq 'OK');
				my @tickets = @{$rc[2]};

				if(scalar(@tickets)) {
					foreach my $ticket(@tickets) {
						diag($ticket->{id}, ': ', $ticket->{title}, ', broken since ', $ticket->{'broken_in'}[0]);
					}
				}
				ok(scalar(@tickets) == 0);
			} else {
				diag("Can't connect to rt.cpan.org");
				skip("Can't connect to rt.cpan.org", 3);
			}
		} else {
			diag('Author tests not required for installation');
			skip('Author tests not required for installation', 3);
		}
	}
}
