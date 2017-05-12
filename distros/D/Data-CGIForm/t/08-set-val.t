# $Id: 08-set-val.t 2 2010-06-25 14:41:40Z twilde $


use Test::More tests => 21;
use strict;

BEGIN { 
    use_ok('Data::CGIForm'); 
}

use t::FakeRequest;

my %data = (
	number  => 2,
	letter  => 'a',
);	


my $r = t::FakeRequest->new(\%data);

my %spec = (
	number  => qr/^(\d+)$/,
	letter  => qr/^([a-z]+)$/i,
);

my $form;

eval { $form = Data::CGIForm->new(datasource => $r, spec => \%spec); };

ok($form, 'Form got made');
   diag("$@") unless $form;
   
is($form->param('number'), 2,   'param("number") right');
is($form->param('letter'), 'a', 'param("letter") right');
is($form->number,          2,   'param("number") right');
is($form->letter,          'a', 'param("letter") right');

$form->letter('b');
$form->param(number => 3);

is($form->param('number'), 3,   'param("number") right');
is($form->param('letter'), 'b', 'param("letter") right');
is($form->number,          3,   'param("number") right');
is($form->letter,          'b', 'param("letter") right');

#
# Now we check with multiple values.
#
my %mdata = (
	number  => [qw(1 2 3)],
	letter  => [qw(a b c)],
);

$r = t::FakeRequest->new(\%mdata);

undef $form;
eval { $form = Data::CGIForm->new(datasource => $r, spec => \%spec); };

ok($form, 'Form got made');
   diag("$@") unless $form;

is_deeply([$form->param('number')], [qw(1 2 3)], 'param("number") right');
is_deeply([$form->param('letter')], [qw(a b c)], 'param("letter") right');
is_deeply([$form->number],          [qw(1 2 3)], 'param("number") right');
is_deeply([$form->letter],          [qw(a b c)], 'param("letter") right');

$form->letter([qw(d e f)]);
$form->param(number => [qw(4 5 6)]);

is_deeply([$form->param('number')], [qw(4 5 6)], 'param("number") right');
is_deeply([$form->param('letter')], [qw(d e f)], 'param("letter") right');
is_deeply([$form->number],          [qw(4 5 6)], 'param("number") right');
is_deeply([$form->letter],          [qw(d e f)], 'param("letter") right');

#
# few last tests to make sure junk is ignored (and make sure 0 works, I have
# a bad track record of doing if ($foo) when I mean if (defined $foo))
#
$form->number(0);
is($form->number, 0, 'param(foo => 0) works');

eval { $form->number({number => 1}) };
ok($@, "param(foo => { stuff.. }) dies");
