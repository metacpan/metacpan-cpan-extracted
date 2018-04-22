use strict;
use warnings;
use Test::More;

# short form of this appears to break the aggregate tests...
plan skip_all => 'no multi form support yet';

use lib 't/lib';
use Test::WWW::Mechanize::Catalyst 'TestApp';

my $mech = Test::WWW::Mechanize::Catalyst->new;

# check the initial response

$mech->get_ok('http://localhost/multiformtoken/formconfig');

my ($form) = $mech->forms;

ok($form);

is( $form->attr('id'), 'formconfig' );

ok( $form->find_input('page1') );

# submit page 1

my $uri = $form->action;

$mech->post_ok( $uri, { page1 => 'foo' } );

# get page 2's hidden value, to submit page 2

undef $form;
($form) = $mech->forms;

ok($form);

undef $uri;
$uri = $form->action;

is( $form->attr('id'), 'formconfig' );

ok( $form->find_input('page2') );
ok( $form->find_input('_multiform') );

my $hidden_value = $form->value('_multiform');

# submit page 2

$mech->post_ok(
    $uri,
    {   _multiform => $hidden_value,
        page2      => 'bar',
    }
);

# check final output

$mech->content_contains('Complete');

$mech->content_contains('page1: foo');

$mech->content_contains('page2: bar');
