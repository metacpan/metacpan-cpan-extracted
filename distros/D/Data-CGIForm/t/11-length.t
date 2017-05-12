# $Id: 11-length.t 2 2010-06-25 14:41:40Z twilde $


use Test::More tests => 20;
use strict;

BEGIN { 
    use_ok('Data::CGIForm'); # 1
}

use t::FakeRequest;

#
# Test the start_param option
#

my $r = t::FakeRequest->new({
	1 => '.',
	2 => '..',
	3 => '...',
});

my %exact_spec = (
	1 => {
		regexp => qr/^(\.+)$/,
		length => 1,
	},
	2 => {
		regexp => qr/^(\.+)$/,
		length => 2,
	},
	3 => {
		regexp => qr/^(\.+)$/,
		length => 3,
	},
);

my %too_long = (
	1 => {
		regexp => qr/^(\.+)$/,
		max_length => 1,
	},
	2 => {
		regexp => qr/^(\.+)$/,
		max_length => 1,
	},
	3 => {
		regexp => qr/^(\.+)$/,
		max_length => 1,
	},
);

my %too_short = (
	1 => {
		regexp => qr/^(\.+)$/,
		min_length => 3,
	},
	2 => {
		regexp => qr/^(\.+)$/,
		min_length => 3,
	},
	3 => {
		regexp => qr/^(\.+)$/,
		min_length => 3,
	},
);

my $form;

eval { $form = Data::CGIForm->new(datasource => $r, spec => \%exact_spec); };

ok($form, 'Form got made'); #2
   diag("$@") unless $form;
   
ok(!$form->error,        'no error marked'); # 3
is($form->param('1'), '.',  '1 correct');    # 4
is($form->param('2'), '..', '2 correct');    # 5
is($form->param('3'), '...', '3 correct');   # 6

undef $form;

eval { $form = Data::CGIForm->new(datasource => $r, spec => \%too_long); };

ok($form, 'Form got made'); # 7
   diag("$@") unless $form;

ok($form->error,             'error marked'); #
is($form->param('1'), '.',   '1 correct');
is($form->param('2'), undef, '2 correct');
is($form->param('3'), undef, '3 correct');

ok($form->error('2'),  '2 error marked');
ok($form->error('3'),  '3 error marked');

undef $form;

eval { $form = Data::CGIForm->new(datasource => $r, spec => \%too_short); };

ok($form, 'Form got made');
   diag("$@") unless $form;

ok($form->error,             'error marked');
is($form->param('1'), undef, '1 correct');
is($form->param('2'), undef, '2 correct');
is($form->param('3'), '...', '3 correct');

ok($form->error('1'),  '1 error marked');
ok($form->error('2'),  '2 error marked');

