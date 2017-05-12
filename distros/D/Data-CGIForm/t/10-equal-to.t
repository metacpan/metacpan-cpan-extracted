# $Id: 10-equal-to.t 2 2010-06-25 14:41:40Z twilde $


use Test::More tests => 13;
use strict;

BEGIN { 
    use_ok('Data::CGIForm'); 
}

use t::FakeRequest;

#
# Test the start_param option
#

my $good_r = t::FakeRequest->new({
	a  => 1,
	b  => 1,
});

my $bad_r = t::FakeRequest->new({
	a  => 1,
	b  => 2,
});

my %spec = (
	a => qr/^(\d+)$/,
	b => {
		equal_to => 'a',
		errors => {
			unequal => 'a != b',
		}
	},
);

my $form;

eval { $form = Data::CGIForm->new(datasource => $good_r, spec => \%spec); };

ok($form, 'Form got made');
   diag("$@") unless $form;
   
ok(!$form->error,        'no error marked');
is($form->param('a'), 1, 'a correct');
is($form->param('b'), 1, 'b correct');

undef $form;

eval { $form = Data::CGIForm->new(datasource => $bad_r, spec => \%spec); };
use Data::Dumper;
ok($form, 'Form got made');
   diag("$@") unless $form;

ok($form->error,             'error marked');
is($form->param('a'), '',    'a correct');
is($form->param('b'), undef, 'b correct');

ok($form->error('a'),  'a error marked');
ok($form->error('b'),  'b error marked');

is($form->error('a'), 'a != b');
is($form->error('b'), 'a != b');

