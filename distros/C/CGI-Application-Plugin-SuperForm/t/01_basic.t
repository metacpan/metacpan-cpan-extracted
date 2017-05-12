use Test::More tests => 8;
use lib './t';
use strict;

$ENV{CGI_APP_RETURN_ONLY} = 1;

use CGI;
use TestApp1;
my $t1_obj =
  TestApp1->new(
	QUERY => CGI->new("text=text_test_text;textarea=textarea_test_text;select=2;rm=test_form") );
my $t1_output = $t1_obj->run();




diag("Test sticky forms");
like( $t1_output, qr/name="text"/, "text field created" );
like( $t1_output, qr/name="textarea"/, "textarea field created" );
like( $t1_output, qr/name="select"/, "select field created" );
like( $t1_output, qr/value="text_test_text"/, "text field populated" );
like( $t1_output, qr/textarea_test_text/, "textarea field populated" );
like( $t1_output, qr/value="2" selected/, "select field preselected" );


{
	use UNIVERSAL (qw/can/);
	ok( $t1_obj->can('superform'), "has superform method" );
	ok( $t1_obj->can('sform'),     "has sform method" );

}
