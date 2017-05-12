# $Id: 09-extra-test.t 2 2010-06-25 14:41:40Z twilde $


use Test::More tests => 14;
use strict;

BEGIN { 
    use_ok('Data::CGIForm'); 
}

use t::FakeRequest;

#
# Test the start_param option
#

my %data = (
	onesub  => 10,
	twosubs => 10,
	fail    => 100,
);	

my $onesub;
my $twosubs;
my $fail;

my $r = t::FakeRequest->new(\%data);

my %spec = (
	onesub => {
		regexp     => qr/^(\d+)$/,
		extra_test => sub { $onesub++; ${$_[0]} < 20 ? 1 : 0 },
	},
	twosubs => {
		regexp => qr/^(\d+)$/,
		extra_test => [
			sub { $twosubs++; ${$_[0]} < 20 ? 1 : 0 },
			sub { $twosubs++; ${$_[0]} > 0 ? 1 : 0 },
		],
	},
	fail => {
		regexp     => qr/^(\d+)$/,
		extra_test => sub { $fail++; ${$_[0]} < 20 ? 1 : 0 },
	}
);

my $form;

eval { $form = Data::CGIForm->new(datasource => $r, spec => \%spec); };

ok($form, 'Form got made');
   diag("$@") unless $form;
   
ok($form->error, 'form error marked');
   
is($form->onesub,  10,   'onesub looks good');
is($form->twosubs, 10,   'twosubs looks good');
ok($form->error('fail'), 'fail failed');

is($form->fail, undef,   'fail really failed');
ok(!grep { $_ eq 'fail'} $form->param, 'fail is not in params list');

is($onesub,  1, 'onesub ran');
is($twosubs, 2, 'twosubs ran (twice!)');
is($fail,    1, 'fail ran');

#
# Test that we get the parameters we say we do.
# Also make sure we can set the error message, as we advertise this.
#
my @args;
%data = (
	foo  => 10,
	bar  => 10,
);	

$r = t::FakeRequest->new(\%data);

%spec = (
	foo => {
		regexp     => qr/^(\d+)$/,
		extra_test => sub { @args = @_; return 1; },
	},
	bar => {
		regexp     => qr/^(\d+)$/,
		extra_test => sub { $_[1]->error(bar => 'error set'); },
	},	
);

undef $form;

eval { $form = Data::CGIForm->new(datasource => $r, spec => \%spec); };

ok($form, 'Form got made');
   diag("$@") unless $form;
   
is_deeply(\@args, [\('10'), $form, 'foo'], 'extra tests are passed the right args');
is($form->error('bar'), 'error set',       'setting error messages works');
