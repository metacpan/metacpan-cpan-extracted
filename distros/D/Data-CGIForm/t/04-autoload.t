# $Id: 04-autoload.t 2 2010-06-25 14:41:40Z twilde $


use Test::More tests => 7;
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
	hex    => qr/^([\da-f]+)$/i,
	letter => qr/^([a-z])$/,
	ws     => qr/^(\s+)$/,
);

my $form;

eval { $form = Data::CGIForm->new(datasource => $r, spec => \%spec); };

ok($form, 'Form got made');
   diag("$@") unless $form;



is($form->number,  5,    'number() works');
is($form->letter,  'a',  'letter() works');
is($form->ws,      ' ',  'ws() works');
is($form->hex,     '0f', 'hex() works');

#
# Make sure we bitch when given a bad method name
# 
eval { $form->this_method_does_not_exist };

ok($@, 'invalid methods are caught');
