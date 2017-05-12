use strict;
no strict "refs";
use warnings;
use Test::More;

# check the dependencies
BEGIN {
    use_ok( 'Getopt::Long' );
    use_ok( 'BGPmon::Configure' );
}
use BGPmon::Configure;
done_testing();

exit;


my $resp = `pwd`;
my $location = 't/';
if($resp =~ m/bgpmon-tools\/BGPmon-core\/t/){
        $location = '';
}

#---------------------   First Check For Correct Operation ---------------------

# given a list of parameters and a configuration file,  test those parameters
sub check_parameters {
    my ($params_file, $config_file) = @_;
    $config_file = $location."Configure_test_config1.txt";
    ok(-e $config_file, "Locating test configuration file $config_file");
	$params_file = "./data/Configure_test_params1.txt";
    ok(-e $config_file, "Locating test  file $config_file");
}


# sample config file to use for testing
my $config_file = $location."data/Configure_test_config1.txt";
ok(-e $config_file, "Locating test configuration file $config_file");
my $params_file = $location."data/Configure_test_params1.txt";
ok(-e $config_file, "Locating test  file $config_file");

# lets define one of each parameter type
my @params = (
    {
        Name     => BGPmon::Configure::CONFIG_FILE_PARAMETER_NAME,
        Type   => BGPmon::Configure::FILE,
        Default => $config_file,
        Description => "this is the configuration file name",
    },
    {
        Name     => "adddress",
        Type   => BGPmon::Configure::ADDRESS,
        Default => "127.0.0.1",
        Description => "this is an address",
    },
    {
        Name     => "port",
        Type   => BGPmon::Configure::PORT,
        Default => "50001",
        Description => "this is port1",
    },
    {
        Name     => "file",
        Type   => BGPmon::Configure::FILE,
        Default => "/tmp/BGPmon_Configure_Testing",
        Description => "this is a file",
    },
);

# now tell the module to set those parameters
my $ret = BGPmon::Configure::configure(@params);
my $ecode = BGPmon::Configure::get_error_code("configure");
my $emsg = BGPmon::Configure::get_error_msg("configure");
ok($ret == 0,
"Trying configure with safe parameters, result is $ecode: $emsg");


# let's see what parameter "server" got set to
my $expected = "127.0.0.1";
my $value = BGPmon::Configure::parameter_value("server");
ok(defined($value) && ($value eq $expected),
    "Parameter server expected $expected, got $value");

#1234567891123456789112345678911234567891123456789112345678911234567891123456789
# let's check the set_by value for parameter "server"
$expected = BGPmon::Configure::DEFAULT;
my $setby = BGPmon::Configure::parameter_set_by("server");
ok($setby == $expected,
    "Set_by for server expected $expected, got $setby"),

# lets check changing the parameter value
$expected = "127.0.0.2";
$ret = BGPmon::Configure::set_parameter("server", $expected);
$ecode = BGPmon::Configure::get_error_code("set_parameter");
$emsg = BGPmon::Configure::get_error_msg("set_parameter");
ok($ret == 0,
"Setting value for parameter server, result is $ecode: $emsg");

# let's see what parameter "server" got set to
$value = BGPmon::Configure::parameter_value("server");
ok(defined($value) && ($value eq $expected),
    "Parameter server expected $expected, got $value");

#1234567891123456789112345678911234567891123456789112345678911234567891123456789
# let's check the set_by value for parameter "server"
$expected = BGPmon::Configure::SET_FUNCTION,
$setby = BGPmon::Configure::parameter_set_by("server");
ok($setby == $expected,
    "Set_by for server expected $expected, got $setby"),

#---------------------   Now Check For Various Error Cases ---------------------

# try with no parameters
$ret = BGPmon::Configure::configure();
$ecode = BGPmon::Configure::get_error_code("configure");
$emsg = BGPmon::Configure::get_error_msg("configure");
ok($ret == 0,
"Configuring using no parameters, result is $ecode: $emsg");

# try with only garbage parameters
$ret = BGPmon::Configure::configure(garbage => "garbage value");
$ecode = BGPmon::Configure::get_error_code("configure");
$emsg = BGPmon::Configure::get_error_msg("configure");
ok($ret == 0,
"Configuring using garbage values, result is $ecode: $emsg");

# try with good and garbage parameters
#$params{"use_syslog"} = 0;
#$params{"garbage"} = "garbage_value";
$ret = BGPmon::Configure::configure(@params);
$ecode = BGPmon::Configure::get_error_code("configure");
$emsg = BGPmon::Configure::get_error_msg("configure");
ok($ret == 0,
"Configuring using valid and garbage values, result is $ecode: $emsg");
#delete($init_params{"garbage"});

# try checking error codes on non-existent functions
$ret = BGPmon::Configure::get_error_code();
ok($ret == BGPmon::Configure::NO_FUNCTION_SPECIFIED_CODE,
   "Calling get_error_code with no function name, result is $ret");
$ret = BGPmon::Configure::get_error_msg();
ok($ret eq BGPmon::Configure::NO_FUNCTION_SPECIFIED_MSG,
   "Calling get_error_msg with no function name, result is $ret");
$ret = BGPmon::Configure::get_error_message();
ok($ret eq BGPmon::Configure::NO_FUNCTION_SPECIFIED_MSG,
   "Calling get_error_msg with no function name, result is $ret");

# try checking error codes on invalid functions
my $invalid_name = "foo";
$ret = BGPmon::Configure::get_error_code($invalid_name);
ok($ret == BGPmon::Configure::INVALID_FUNCTION_SPECIFIED_CODE,
   "Calling get_error_code with invalid function name, result is $ret");
$ret = BGPmon::Configure::get_error_msg($invalid_name);
ok($ret eq BGPmon::Configure::INVALID_FUNCTION_SPECIFIED_MSG,
   "Calling get_error_msg with invalid function name, result is $ret");
$ret = BGPmon::Configure::get_error_message($invalid_name);
ok($ret eq BGPmon::Configure::INVALID_FUNCTION_SPECIFIED_MSG,
   "Calling get_error_msg with invalid function name, result is $ret");

#---------------------   Now Check For Various Error Cases ---------------------
# in function parameter_value


done_testing();

1;
