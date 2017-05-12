# $Id: 05-multiple.t 2 2010-06-25 14:41:40Z twilde $


use Test::More tests => 12;
use strict;

BEGIN { 
    use_ok('Data::CGIForm'); 
}

use t::FakeRequest;

my %data = (
	good =>  [1, 2, 3,   4, 5],
	bad  =>  [1, 2, 3,   4, 5],
	mixed => [1, 2, 'a', 3, 4]
);

my $r = t::FakeRequest->new(\%data);

my %spec = (
	good  => qr/^(\d+)$/,
	bad   => qr/^([a-z]+)$/,
	mixed => qr/^(\d+)$/,
);

my $form;

eval { $form = Data::CGIForm->new(datasource => $r, spec => \%spec); };

ok($form, 'Form got made');
   diag("$@") unless $form;


is_deeply([$form->param('good')],  $data{'good'}, 'Good looks good');
is_deeply([$form->param('bad')],   [],            'bad looks good');
is_deeply([$form->param('mixed')], [1, 2, 3, 4],  'mixed looks good');

ok($form->error,          'error marked');
ok(!$form->error('good'), 'good error message not set');
ok($form->error('bad'),   'bad error message set');
ok($form->error('mixed'), 'mixed error message set');

#
# Check the autoloaded methods.
#
is_deeply([$form->good],  $data{'good'}, 'autoloaded good looks good');

#
# Check methods under scalar context
#

is(scalar($form->param('good')), 1, 'scalar param() works');
is(scalar($form->good),          1, 'scalar form() works');

