use strict;
use warnings;

use Test::More tests => 3;

use lib 't/lib';
use Test::WWW::Mechanize::Catalyst 'TestApp';

my $mech = Test::WWW::Mechanize::Catalyst->new;

$mech->get_ok('http://localhost/basic/form');

my ($form) = $mech->forms;

ok($form);

ok( $form->find_input('basic_form') );
