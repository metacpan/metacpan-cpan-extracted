# t/002_formbuilder_form.t
#   verify that standard Catalyst::Controller::FormBuilder behaviour still 
#   works in MultiForm

use Test::More tests => 9;
use FindBin;

use lib "$FindBin::Bin/lib";
use Test::WWW::Mechanize::Catalyst 'TestApp';

my $mech = Test::WWW::Mechanize::Catalyst->new;
my $page = "test/standard";

$mech->get_ok( "http://localhost/$page", "GET /$page" );

my $std_form = $mech->form_name('standard');
ok( $std_form, "Form found" ) or BAIL_OUT( "Cannot locate FormBuilder form, unable to continue tests" );

my $std_one = $std_form->find_input( 'standard_one' );
ok( $std_one, "First input field found in FormBuilder form");

my $std_two = $std_form->find_input( 'standard_two' );
ok( $std_two, "Second input field found in FormBuilder form");

$std_one->value('std_one_value');
is( $std_one->value, 'std_one_value', "Set first input field value in FormBuilder form" );

$std_two->value('std_two_value');
is( $std_two->value, 'std_two_value', "Set second input field value in FormBuilder form" );

$mech->submit;

like( $mech->content, qr/form:standard/, "FormBuilder form submitted" );
like( $mech->content, qr/standard_one:std_one_value/, "First input value submitted in FormBuilder form" );
like( $mech->content, qr/standard_two:std_two_value/, "Second input value submitted in FormBuilder form" );
