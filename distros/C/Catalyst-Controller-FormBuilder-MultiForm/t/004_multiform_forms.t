# t/004_multiform_forms.t
#   verify that we can access and submit multiple forms by name using 
#   MultiForm functionality

use Test::More tests => 18;
use FindBin;

use lib "$FindBin::Bin/lib";
use Test::WWW::Mechanize::Catalyst 'TestApp';

my $mech = Test::WWW::Mechanize::Catalyst->new;
my $page = "test/two_forms";

$mech->get_ok( "http://localhost/$page", "GET /$page" );

my $foo_form = $mech->form_name('foo');
ok( $foo_form, "First form found" ) or BAIL_OUT( "Cannot locate first MultiForm form, unable to continue tests" );

my $foo_one = $foo_form->find_input( 'foo_one' );
ok( $foo_one, "First input field in first MultiForm form found");

my $foo_two = $foo_form->find_input( 'foo_two' );
ok( $foo_two, "Second input field in first MultiForm form found");

$foo_one->value('foo_one_value');
is( $foo_one->value, 'foo_one_value', "Set first input field value in first MultiForm form" );

$foo_two->value('foo_two_value');
is( $foo_two->value, 'foo_two_value', "Set second input field value in first MultiForm form" );

$mech->submit;

like( $mech->content, qr/form:foo/, "First MultiForm form submitted" );
like( $mech->content, qr/foo_one:foo_one_value/, "First input value in first MultiForm form submitted" );
like( $mech->content, qr/foo_two:foo_two_value/, "Second input value in first MultiForm form submitted" );


$mech->get_ok( "http://localhost/$page", "GET /$page" );

my $bar_form = $mech->form_name('bar');
ok( $bar_form, "Second form found" ) or BAIL_OUT( "Cannot locate second MultiForm form, unable to continue tests" );

my $bar_one = $bar_form->find_input( 'bar_one' );
ok( $bar_one, "First input field in second MultiForm form found");

my $bar_two = $bar_form->find_input( 'bar_two' );
ok( $bar_two, "Second input field in second MultiForm form found");

$bar_one->value('bar_one_value');
is( $bar_one->value, 'bar_one_value', "Set first input field value in second MultiForm form" );

$bar_two->value('bar_two_value');
is( $bar_two->value, 'bar_two_value', "Set second input field value in second MultiForm form" );

$mech->submit;

like( $mech->content, qr/form:bar/, "Second MultiForm form submitted" );
like( $mech->content, qr/bar_one:bar_one_value/, "First input value in second MultiForm form submitted" );
like( $mech->content, qr/bar_two:bar_two_value/, "Second input value in second MultiForm form submitted" );
