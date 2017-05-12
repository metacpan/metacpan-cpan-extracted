use Test::More tests => 31;
use Test::Exception;

use Data::Form::Elements;
 
# our test set of arguments for a bad form as a normal hash
%BAD_FORM = (
	'name'		=> '  ',
	'sort_position' => 'a',
	'description'	=> '   asdf       ',
	'email'		=> 'jasonmultiply.org'
);
 
my $bad_form = new Data::Form::Elements;

$bad_form->add_element( "name", { required => 1 } );
$bad_form->add_element( "sort_position", { required => 1, errmsg => "Please specify a sort position for this category.", constraints => qr/^\d+$/, invmsg => "The sort position must be a positive integer only." } );
$bad_form->add_element( "description", { } );
$bad_form->add_element( "email", { required => 1, errmsg => "Please specify a sort position for this category.", constraints => "email", invmsg => 'Please provide a valid email address, like username@server.com.' } );

# TODO: make a CGI param object, as well as an apache request object to test
# with
my $bogus_var = "not a form.";

dies_ok { $bad_form->validate( $bogus_var ) } "Will not validate a scalar.";
dies_ok { $bad_form->validate( %BAD_FORM ) } "Will not validate a normal hash.";

lives_ok { $bad_form->validate( \%BAD_FORM ) } "Validate hash";

ok ( !$bad_form->is_valid(), "ARGS as given should not validate." );

# check form values using param and accessor methods.
is ( $bad_form->param("name"), '  ', "Param: Name stored, but not trimmed.");
is ( $bad_form->name, '  ', "Param: Name stored, but not trimmed (accessor).");
is ( $bad_form->message("name"), 'Please fill in this field.', "Param: Name Error message OK (default)." );

is ( $bad_form->param("description"), 'asdf', "Param: Description stored and trimmed.");
is ( $bad_form->description, 'asdf', "Param: Description stored and trimmed (accessor).");
is ( $bad_form->message("description"), '', "No error message for description." );


is ( $bad_form->param("sort_position"), 'a', "Param: Sort Position stored.");
is ( $bad_form->sort_position, 'a', "Param: Sort Position stored (accessor).");
is ( $bad_form->message("sort_position"), 'The sort position must be a positive integer only.', "Proper constraint error message for sort_position." );

is ( $bad_form->param("email"), 'jasonmultiply.org', "Param: Email stored.");
is ( $bad_form->email, "jasonmultiply.org", "Param: Email stored (accessor).");
is ( $bad_form->message("email"), 'Please provide a valid email address, like username@server.com.', "Proper constraint error message for email." );


############# GOOD FORM
# our test set of arguments for a bad form as a normal hash
%GOOD_FORM = (
	'name'		=> ' Record Reviews     ',
	'sort_position' => '5',
	'description'	=> 'Jason gives you his take on modern music.',
	'email'		=> 'jason@multiply.org'
);
 
my $good_form = new Data::Form::Elements;

$good_form->add_element( "name", { required => 1 } );
$good_form->add_element( "sort_position", { required => 1, errmsg => "Please specify a sort position for this category.", constraints => qr/^\d+$/, invmsg => "The sort position must be a positive integer only." } );
$good_form->add_element( "description", { } );
$good_form->add_element( "email", { required => 1, errmsg => "Please specify a sort position for this category.", constraints => "email", invmsg => 'Please provide a valid email address, like username@server.com.' } );

# TODO: make a CGI param object, as well as an apache request object to test
# with

ok ($good_form->validate( \%GOOD_FORM ), "Validate hash" );

ok ( $good_form->is_valid(), "ARGS as given should validate." );

# check form values using param and accessor methods.
is ( $good_form->param("name"), 'Record Reviews', "Param: Name stored, but not trimmed.");
is ( $good_form->name, 'Record Reviews', "Param: Name stored, but not trimmed (accessor).");
is ( $good_form->message("name"), '', "Param: Name Error message OK (default)." );

is ( $good_form->param("description"), 'Jason gives you his take on modern music.', "Param: Description stored.");
is ( $good_form->description, 'Jason gives you his take on modern music.', "Param: Description stored (accessor).");
is ( $good_form->message("description"), '', "No error message for description." );


is ( $good_form->param("sort_position"), '5', "Param: Sort Position stored.");
is ( $good_form->sort_position, '5', "Param: Sort Position stored (accessor).");
is ( $good_form->message("sort_position"), '', "Proper constraint error message for sort_position." );

is ( $good_form->param("email"), 'jason@multiply.org', "Param: Email stored.");
is ( $good_form->email, 'jason@multiply.org', "Param: Email stored (accessor).");
is ( $good_form->message("email"), '', "Proper constraint error message for email." );

# test the accessor methods for setting
$good_form->email('no@thanks.org');
is ( $good_form->email, 'no@thanks.org', "Accessor method setter works.");
