use strict;
use warnings;
use Test::More;

eval {
    require HTML::FormFu::MultiForm;
};
if ($@) {
    plan skip_all => 'HTML::FormFu::MultiForm required for MultiForm tests';
    die $@;
}

plan tests => 12;

use lib 't/lib';
use Test::WWW::Mechanize::Catalyst 'TestApp';

my $mech = Test::WWW::Mechanize::Catalyst->new;

# check the initial response

$mech->get_ok('http://localhost/multiform/file_upload');

my ($form) = $mech->forms;

ok($form);

is( $form->attr('id'), 'file-upload' );

ok( $form->find_input('image1') );

# submit page 1

my $uri = $form->action;

my $response = $mech->post(
    $uri,
    Content_Type => 'form-data',
    Content      => [ image1 => ['t/btn_88x31_built.png'], ],
);

is( $mech->status, '200' );

# get page 2's hidden value, to submit page 2

undef $form;
($form) = $mech->forms;

ok($form);

undef $uri;
$uri = $form->action;

is( $form->attr('id'), 'file-upload' );

ok( $form->find_input('image2') );
ok( $form->find_input('_multiform') );

my $hidden_value = $form->value('_multiform');

# submit page 2

$mech->post(
    $uri,
    Content_Type => 'form-data',
    Content      => [
        _multiform => $hidden_value,
        image2     => ['t/btn_120x50_built.png'],
    ],
);

# check final output

$mech->content_contains('Complete');

$mech->content_contains(
    'param: image1, size: 2517, filename: btn_88x31_built.png, type: image/png'
);

$mech->content_contains(
    'param: image2, size: 3826, filename: btn_120x50_built.png, type: image/png'
);
