# $Id: 07-options.t 2 2010-06-25 14:41:40Z twilde $


use Test::More tests => 8;
use strict;

BEGIN { 
    use_ok('Data::CGIForm'); 
}

use t::FakeRequest;

#
# Test the start_param option
#

my %started = (
	started => 1,
	number  => 2,
	letter  => 'a',
	ws      => '#',
);	

my %unstarted = (
	started => 0,
	number  => 2,
	letter  => 'a',
	ws      => '#',
);	

my $r         = t::FakeRequest->new(\%unstarted);
my $r_started = t::FakeRequest->new(\%started);

my %spec = (
	started => qr/^(1)$/,
	number  => qr/^(\d+)$/,
	letter  => qr/^([a-z]+)$/i,
	ws      => qr/^(\s+)$/,
);

my ($started, $unstarted);

eval { $started = Data::CGIForm->new(datasource => $r_started, spec => \%spec, start_param => 'started'); };

ok($started, 'started got made');
   diag("$@") unless $started;


eval { $unstarted = Data::CGIForm->new(datasource => $r, spec => \%spec, start_param => 'started'); };

ok($unstarted, 'unstarted got made');
   diag("$@") unless $unstarted;


ok($started->error,    'unstarted was not checked');
ok(!$unstarted->error, 'unstarted was');

is($unstarted->letter,  '', 'letter is an empty string');
is($unstarted->number,  '', 'number is an empty string');

#
# Make sure that bails if the start_param isn't in the spec;
# 

my $form;
eval { $form = Data::CGIForm->new(datasource => $r, spec => \%spec, start_param => 'form'); };
ok($@, 'Invalid start_param detected');
