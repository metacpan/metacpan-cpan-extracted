# $Id: 02-methods.t 2 2010-06-25 14:41:40Z twilde $


use Test::More tests => 8;
use strict;

BEGIN { 
    use_ok('Data::CGIForm'); 
}

use t::FakeRequest;

my %data = (
	number => 5,
	letter => 'a',
	ws     => ' ',
	hex    => '0f',
);

my $r = t::FakeRequest->new(\%data);

my %spec = (
	number => qr/^(\d+)$/,
	hex => {
		regexp => qr/^([\da-f]+)$/i,
		filter => [qw(strip_leading_ws strip_trailing_ws)],
	},
	letter => {
		regexp   => qr/^([a-z])$/,
		filter   => sub { ${$_[0]} =~ s/\s//g },
		optional => 1,
	},
	ws => {
		regexp  => qr/^(\s+)$/,
		errors  => {
			invalid => q|That's not whitespace: %s|,
		}
	},
);

my $form;

eval { $form = Data::CGIForm->new(datasource => $r, spec => \%spec); };

ok($form, 'Form got made');
   diag("$@") unless $form;

#
# check $form->params
#
my $params = [ $form->params ];

is_deeply($params, [qw(hex letter number ws)], 'params() appears to be sane');

#
# check $form->param
#
while (my ($k, $v) = each %data) {
	is($form->param($k), $v, "$k is right");
}

#
# make sure that $form->param calls $form->params when given no args. 
#
is_deeply([$form->param], $params, '$form->param() matches $form->params');
