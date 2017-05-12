use Test::More tests => 9;

# Need CGI.pm for tests
use CGI;
use CGI::Application::Plus::Util;

# Include the test hierarchy
use lib './test';


# Prevent output to STDOUT
$ENV{CGI_APP_RETURN_ONLY} = 1;
$ENV{OLD_CGI_APP_COMPATIBLE} = 1;
BEGIN
{
  chdir './t' ;
  require 'test/TestApp6.pm'  ;
}

# Test basic cgiapp_prerun() and get_current_runmode()
{
	my $ta_obj = TestApp6->new(QUERY=>CGI->new(""));
	my $output = $ta_obj->run();

	# Did the run-mode work?
	like($output, qr/^Content\-Type\:\ text\/html/);
	like($output, qr/Hello\ World\:\ prerun\_test\ OK/);

	# Did the cgiapp_prerun work?
	is($ta_obj->param('PRERUN_RUNMODE'), 'prerun_test');

	# get_current_runmode() working?
	is($ta_obj->get_current_runmode(), 'prerun_test');
}


# Test basic prerun_mode()
{
	local($^W) = undef;  # Temporarily disable warnings

	my $ta_obj = TestApp6->new(QUERY=>CGI->new('rm=prerun_mode_test'));
	my $output = $ta_obj->run();

	# Did the run-mode work?
	like($output, qr/^Content\-Type\:\ text\/html/);

	# We will be in mode 'new_prerun_mode_test' if everything is working
	like($output, qr/Hello\ World\:\ new\_prerun\_mode\_test\ OK/);

	# get_current_runmode() working?
	is($ta_obj->get_current_runmode(), 'new_prerun_mode_test');
}


# Test fail-case for prerun_mode()
{
	my $ta_obj = TestApp6->new(QUERY=>CGI->new('rm=illegal_prerun_mode'));

	eval {
		my $output = $ta_obj->run();
	};

	my $eval_error = $@;

	# Should result in an error
	like($eval_error, qr/No run-method found for run mode/);
}


# Test fail-case for prerun_mode() called from setup()
{
	$ENV{PRERUN_IN_SETUP} = 1;

	eval {
		my $ta_obj = TestApp6->new(QUERY=>CGI->new(""));
	};

	my $eval_error = $@;

	# Should result in an error
	like($eval_error, qr/Too early to call this method/);
}


###############
####  EOF  ####
###############
