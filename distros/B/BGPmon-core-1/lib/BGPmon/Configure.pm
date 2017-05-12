package BGPmon::Configure;
our $VERSION = '1.092';

use 5.006;
use strict;
use warnings;
use Getopt::Long;

require Exporter;
our %EXPORT_TAGS = ( "all" => [ qw(configure parameter_value 
                                   parameter_set_by set_parameter 
                                   get_error_code get_error_message
                                   get_error_msg  ) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @ISA = qw(Exporter);

# --- The Name For The Configuration File Command Line Option ---
# The recommended command line option is -config_file,  but you can change the 
# option name to something else by setting the constant below
use constant CONFIG_FILE_PARAMETER_NAME => "config_file";

# --- constants used to indicate who set a parameter ---
use constant NOT_SET => 0;
use constant DEFAULT => 1;
use constant COMMAND_LINE => 2;
use constant CONFIG_FILE => 3;
use constant SET_FUNCTION => 4;
use constant SET_ERROR => 5;
my @SETBY_VALUES = (NOT_SET, DEFAULT, COMMAND_LINE, CONFIG_FILE, SET_FUNCTION);

# --- The Supported Parameter Types ---
use constant ADDRESS => 0;
use constant PORT => 1;
use constant FILE => 2;
use constant BOOLEAN => 3;
use constant STRING => 4;
use constant UNSIGNED_INT => 5;
my @SUPPORTED_TYPES = (ADDRESS, PORT, FILE, BOOLEAN, STRING,  UNSIGNED_INT);

# if you add a new parameter type,   you must
#   1.  define a name for the new type above
#   2. add the new type to @SUPPORTED_TYPES array above
#   3. add a string that will be displayed in the usage messag by setting  
#     $USAGE_MSG_FOR_TYPE{$YOUR_NEW_TYPE} 
#   4 add a string that tells GetOpt what type of command line arguement is 
#     expected by setting GETOPT_PARAM_FOR_TYPE{$YOUR_NEW_TYPE} 
#   - modify set_parameter_by_value to handle error checking for you new type 

# usage messages for each type
my %USAGE_MSG_FOR_TYPE;
$USAGE_MSG_FOR_TYPE{ADDRESS()} = "IP_adddress";
$USAGE_MSG_FOR_TYPE{PORT()} = "port";
$USAGE_MSG_FOR_TYPE{FILE()} = "filename";
$USAGE_MSG_FOR_TYPE{BOOLEAN()} = "";
$USAGE_MSG_FOR_TYPE{STRING()} = "string";
$USAGE_MSG_FOR_TYPE{UNSIGNED_INT()} = "non_negative_number";

# GetOpt paramater for each type
my %GETOPT_PARAM_FOR_TYPE;
$GETOPT_PARAM_FOR_TYPE{ADDRESS()} = "=s";
$GETOPT_PARAM_FOR_TYPE{PORT()} = "=i";
$GETOPT_PARAM_FOR_TYPE{FILE()} = "=s";
$GETOPT_PARAM_FOR_TYPE{BOOLEAN()} = "!";
$GETOPT_PARAM_FOR_TYPE{STRING()} = "=s";
$GETOPT_PARAM_FOR_TYPE{UNSIGNED_INT()} = "=i";
 
# --- constants used to indicate error codes and messages---
use constant NO_ERROR_CODE => 0;
use constant NO_ERROR_MSG => 
    'No Error';
use constant NO_FUNCTION_SPECIFIED_CODE => 1;
use constant NO_FUNCTION_SPECIFIED_MSG => 
    'Error reporting function called without specifying the function.';
use constant INVALID_FUNCTION_SPECIFIED_CODE => 2;
use constant INVALID_FUNCTION_SPECIFIED_MSG => 
    'Error reporting function called with invalid function name';
use constant NO_PARAMETER_SPECIFIED_CODE => 3;
use constant NO_PARAMETER_SPECIFIED_MSG => 
    'No parameter name specified';
use constant NOT_A_VALID_PARAMETER_CODE => 4;
use constant NOT_A_VALID_PARAMETER_MSG => 
    'Invalid parameter name';
use constant NO_VALUE_ASSIGNED_CODE => 5;
use constant NO_VALUE_ASSIGNED_MSG => 
    'No value has been assigned to this parameter';
use constant UNDEFINED_SETBY_CODE => 6;
use constant UNDEFINED_SETBY_MSG => 
    'The SetBy field of the parameter is undefined';
use constant INVALID_SETBY_CODE => 7;
use constant INVALID_SETBY_MSG => 
    'The SetBy field of the parameter is invalid.';
use constant INVALID_VALUE_CODE => 8;
use constant INVALID_VALUE_MSG => 
    'Invalid value for parameter';
use constant PARAMETER_CREATION_ERROR_CODE => 9;
use constant PARAMETER_CREATION_ERROR_MSG => 
    'Error creating the paramter - missing parameter hash';
use constant PARAMETER_CREATION_MISSING_NAME_CODE => 10;
use constant PARAMETER_CREATION_MISSING_NAME_MSG => 
    'Error creating the paramter - parameter name is missing';
use constant PARAMETER_CREATION_MISSING_TYPE_CODE => 11;
use constant PARAMETER_CREATION_MISSING_TYPE_MSG => 
    'Error creating the paramter - parameter name is missing';
use constant PARAMETER_CREATION_INVALID_TYPE_CODE => 12;
use constant PARAMETER_CREATION_INVALID_TYPE_MSG => 
    'Error creating the paramter - invalid type ';
use constant PARAMETER_CREATION_INVALID_ELEMENT_CODE => 13;
use constant PARAMETER_CREATION_INVALID_ELEMENT_MSG => 
    'Error creating the paramter - invalid element ';
use constant PARAMETER_CREATION_INVALID_DEFAULT_CODE => 14;
use constant PARAMETER_CREATION_INVALID_DEFAULT_MSG => 
    'Error creating the paramter - invalid default value ';
use constant PARAMETER_CREATION_NO_H_OPT_CODE => 15;
use constant PARAMETER_CREATION_NO_H_OPT_MSG => 
    'Error creating the paramter - parameter name -h and -help are reserved';
use constant PARAMETER_CREATION_INVALID_CONFIG_FILE_TYPE_CODE => 16;
use constant PARAMETER_CREATION_INVALID_CONFIG_FILE_TYPE_MSG => 
    'Error creating the paramter - config file must be type FILE';
use constant COMMAND_LINE_USAGE_CONSTRUCTION_ERROR_CODE => 17;
use constant COMMAND_LINE_USAGE_CONSTRUCTION_ERROR_MSG => 
    'Unable to construct usage message for command line';
use constant NO_CONFIG_FILE_SPECIFIED_CODE => 18;
use constant NO_CONFIG_FILE_SPECIFIED_MSG => 
    'No configuration file specified';
use constant CONFIG_FILE_NOT_FOUND_CODE => 19;
use constant CONFIG_FILE_NOT_FOUND_MSG => 
    'Configuration file not found';
use constant CONFIG_FILE_OPEN_FAILED_CODE => 20;
use constant CONFIG_FILE_OPEN_FAILED_MSG => 
    'Failed to open configuration file';
use constant CONFIG_FILE_INVALID_LINE_CODE => 21;
use constant CONFIG_FILE_INVALID_LINE_MSG => 
    'Invalid line in configuration file: ';

# --- error code/message ---
my %error_code; 
my %error_msg; 
# init the error codes for all functions
my @function_names = ("configure", "parameter_value", 
                      "parameter_set_by", "set_parameter", 
                      "set_parameter_to_value", "create_param", 
                      "read_config", "read_file" ); 
for my $function_name (@function_names) {
    $error_code{$function_name} = NO_ERROR_CODE;
    $error_msg{$function_name} = NO_ERROR_MSG;
}

# ---  hash arrays for storing the parameters
my %Value;    		# current parameter value
my %Type;     		# parameter type (port, address, boolean, string, file)
my %Default;  		# the default value, command line/config_file overrides
my %Description;  	# description of the parameter for usage message.   
my %SetBy; 		# indicates how the parameter was set.   

=head1 NAME

BGPmon::Configure - BGPmon Client Configuration

This module sets initial configuration variables from a combination of default 
values,  configuration file parameters, and command line options.   

=cut

=head1 SYNOPSIS

The module allows one to specify a set of configuration parameters and the 
module sets these parameters based on a cominbation of default vaules,  
command line options,  and configuration file settings.   The module does the 
work of parsing the commmand line,  generating any usage messages,  and 
reading a configuration file.    You simply specify the input paramters you 
would like to allow in the configuation file and on the commmand line.   

To specify a parameter,  you must provide a parameter Name and parameter Type.    
Possible Types are ADDRESS,  PORT, FILE, BOOLEAN, STRING, and UNSIGNED_INT.    

Once you have specified the paramters,   the configure function will take 
care of generating command line arguements and will generate any usage errors 
if the user does not specify correct command line options.  

You may optionally specify a Description and your description text will appear 
after this option in any Usage message.

The configure function will also read from a configuration file.  Note that 
values set by the command line take precedence and over-ride any settings 
found in the configuration file.  The user can specify the configuration file 
with -c file or with -config_file file.   

You may also specify a Default configuration file or specify a Default for any 
other option.  Settings found in the configutaion file and command line take 
precedence over any default settings.

Once you have specified your parameters and called configure(%your_params),  
you can use get_paramter("param_name") to get the value of any paramter.   
You can also call parameter_set_by("param_name") to see if the parameter 
was set using the default,  the config file,  or the command line 
(or was not set at all).    

Finally,  if you want to later over-ride any parameter,  you can set it to 
a value using set_parameter("param_name", value).   This is not recommended.   
You should rely on your defaults,  the config file, and the command line 
to set your parameters.  But set_parameter is provided as option in case 
special cases need it.

Example:

use BGPmon::Configure;
# lets define some parameters for my program
my @params = (
    {
        Name     => BGPmon::Configure::CONFIG_FILE_PARAMETER_NAME,
        Type   => BGPmon::Configure::FILE,
        Default => "./foo",
        Description => "this is the configuration file name",
    },
    {
        Name     => "server",
        Type   => BGPmon::Configure::ADDRESS,
        Default => "127.0.0.1",
        Description => "this is the server address",
    },
    {
        Name     => "port",
        Type   => BGPmon::Configure::PORT,
        Default => 50002,
        Description => "this is the server port",
    },
    {
        Name     => "output_file",
        Type   => BGPmon::Configure::FILE,
        Default => "/tmp/file",
        Description => "My Output File",
    },
    {
        Name     => "use_syslog",
        Type   => BGPmon::Configure::BOOLEAN,
        Description => "Use Syslog for error checking",
    },
    {
        Name     => "somestring",
        Type   => BGPmon::Configure::STRING,
        Default => "This is a string used for something",
    },
    {
        Name     => "log_level",
        Type   => BGPmon::Configure::UNSIGNED_INT,
        Default => 7,
    }
);

# now tell the module to set those parameters

if (BGPmon::Configure::configure(@params) ) {
    my $code = BGPmon::Configure::get_error_code("configure");
    my $msg = BGPmon::Configure::get_error_message("configure");
    print "Error Code is $code and message is $msg \n";
    exit;
}

# let's see what parameter "server" got set to

my $srv = BGPmon::Configure::parameter_value("server");
if (defined($srv)) {
    print "The server parameter was set to $srv\n";
}

# let's see how parameter "server" was set

my $setby = BGPmon::Configure::parameter_set_by("server");
if ($setby == BGPmon::Configure::NOT_SET) {
    print "The server parameter has not been set\n";
} elsif ($setby == BGPmon::Configure::DEFAULT) {
    print "The server parameter was set to the default value \n";
} elsif ($setby == BGPmon::Configure::COMMAND_LINE) {
    print "The user set the server parameter from the command line\n";
} elsif ($setby == BGPmon::Configure::CONFIG_FILE) {
    print "The server parameter was set in the configuration file\n";
} elsif ($setby == BGPmon::Configure::SET_ERROR) {
    print "something went wrong...  the parameter has an error\n";
}

# this is not recommended,  but we can over-ride that setting and 
change the parameter value

my $new_srv = "127.0.0.1";

if (BGPmon::Configure::set_parameter("server", $new_srv) ) {
    my $code = BGPmon::Configure::get_error_code("set_parameter");
    my $msg = BGPmon::Configure::get_error_message("set_parameter");
    print "Error Code is $code and message is $msg \n";
    exit;
}

if (BGPmon::Configure::parameter_set_by("server") == 
    BGPmon::Configure::SET_FUNCTION ) {
    print "I over-rode everything and set the server parameter to $new_srv\n";
} 

=head1 EXPORT

configure
parameter_value
parameter_set_by
set_parameter

=head1 SUBROUTINES/METHODS

=head2 configure

set initial configuration variables from a combination of default values,   
configuration file parameters,  and command line options

Input : an array of hashes that specify the configuration parameters.    
        Each configuration parameter is represented by one hash with elements:
       1. Name - (required) the name of the paramter 
             as it will appear in the command line and configuration file
       2. Type - (required) the type of value associated with this name.   
             supported types include address, port, boolean, unsigned integer.  
       3. Default (optional) - the default value to associate with this 
              parameter if it is not found in the config file or command line
       4. Description (optional) - A description to appear in a usage message 

Output:  0 on success,  1 on error and error code and error message are set 
=cut
sub configure {
    my @params = @_;
 
    # set function name for error reporting
    my $function_name = $function_names[0];

    # run through all the parameters and set up the default values 
    # (if default is present)
    for my $i ( 0 .. $#params ) {
        if (create_param(($params[$i])) ) {
            $error_code{$function_name} = $error_code{$function_names[4]};
            $error_msg{$function_name} = $error_msg{$function_names[4]};
            return 1;
        }
    }
    if (read_command_line()) {
        $error_code{$function_name} = $error_code{$function_names[5]};
        $error_msg{$function_name} = $error_msg{$function_names[5]};
        return 1;
    }
    if (read_config_file()) {
        $error_code{$function_name} = $error_code{$function_names[6]};
        $error_msg{$function_name} = $error_msg{$function_names[6]};
        return 1;
    }

    $error_code{$function_name} = NO_ERROR_CODE;
    $error_msg{$function_name} = NO_ERROR_MSG;
    return 0; 
 }


=head2 parameter_value 

Return the  setting for a configuraion parameter

Input : the name of the paramter

Output:  the value of the parameter.    
         if the input name does not correspond to a parameter, 
         the function returns undef and sets error code and error message 
=cut
sub parameter_value {
    my $name = shift;

    # set function name for error reporting
    my $function_name = $function_names[1];

    # check we got a the name of some parameter
    if (!defined($name)) {
        $error_code{$function_name} = NO_PARAMETER_SPECIFIED_CODE;
        $error_msg{$function_name} = NO_PARAMETER_SPECIFIED_MSG;
        return undef;
    }

    # check the name matches a parameter for this program
    # note a parameter may or may not have an assigned value,
    # but every valid parameter must have a type
    if (!defined($Type{$name}) ) {
        $error_code{$function_name} = NOT_A_VALID_PARAMETER_CODE;
        $error_msg{$function_name} = NOT_A_VALID_PARAMETER_MSG;
        return undef;
    }

    # if there is a value for this parameter, return it
    if (defined($Value{$name}) ) {
        $error_code{$function_name} = NO_ERROR_CODE;
        $error_msg{$function_name} = NO_ERROR_MSG;
        return $Value{$name};
    }

    # parameter exists, but no value has been assigned
    $error_code{$function_name} = NO_VALUE_ASSIGNED_CODE;
    $error_msg{$function_name} = NO_VALUE_ASSIGNED_MSG;
    return undef;
}

=head2 parameter_set_by

 indicates how the parameter value was set.   
Input : the name of the paramter
Output:  one of the following codes indicating how the parameter was set:
    - not set at all (NOT_SET), 
    - set to a default value (DEFAULT), 
    - set by the command line (COMMAND_LINE),  
    - set by the configuraiton file (CONFIG_FILE),  
    - set externally using the set_paramater function (SET_FUNCTION)
    - or  on error,  (SET_ERROR) and the error_code and error_message are set
=cut
sub parameter_set_by {
    my $name = shift;

    # set function name for error reporting
    my $function_name = $function_names[2];

    # check we got a the name of some parameter
    if (!defined($name)) {
        $error_code{$function_name} = NO_PARAMETER_SPECIFIED_CODE;
        $error_msg{$function_name} = NO_PARAMETER_SPECIFIED_MSG;
        return SET_ERROR;
    }

    # check the name matches a parameter for this program
    # note a parameter may or may not have an assigned value,
    # but every valid parameter must have a type
    if (!defined($Type{$name}) ) {
        $error_code{$function_name} = NOT_A_VALID_PARAMETER_CODE;
        $error_msg{$function_name} = $name.NOT_A_VALID_PARAMETER_MSG;
        return SET_ERROR;
    }

    # the SetBy value is initially NOT_SET and should always be defined
    if (!defined($SetBy{$name}) ) {
        $error_code{$function_name} = UNDEFINED_SETBY_CODE;
        $error_msg{$function_name} = UNDEFINED_SETBY_MSG;
        return SET_ERROR;
    }

    # if the value doesn't matches any of our SetBY values,  return an error
    if (invalidSetByField($SetBy{$name}) ) {
        $error_code{$function_name} = INVALID_SETBY_CODE;
        $error_msg{$function_name} = INVALID_SETBY_MSG.$SetBy{$name};
        return SET_ERROR;
    }
    
    # the SetBy value does not match any of our expected values....
    $error_code{$function_name} = NO_ERROR_CODE;
    $error_msg{$function_name} = NO_ERROR_MSG;
    return $SetBy{$name};
}
    
=head2 set_parameter

 Sets a parameter to the specified value.  

 Configuration parameters are typically set by a combination of default value,  
 command line options, and configuration file options.   This function allows 
 the caller to over-ride all this and force a parameter to the specified value.

Input : the name of the paramter and the value for the paramter
Output: 0 on success,  1 on error and sets error_code and error_message
=cut
sub set_parameter {
    my ($name, $value) = @_;

    # set function name for error reporting
    my $function_name = $function_names[3];

    # check we got a the name of some parameter
    if (!defined($name)) {
        $error_code{$function_name} = NO_PARAMETER_SPECIFIED_CODE;
        $error_msg{$function_name} = NO_PARAMETER_SPECIFIED_MSG;
        return 1;
    }

    # check the name matches a parameter for this program
    # note a parameter may or may not have an assigned value,
    # but every valid parameter must have a type
    if (!defined($Type{$name}) ) {
        $error_code{$function_name} = NOT_A_VALID_PARAMETER_CODE;
        $error_msg{$function_name} = $name.NOT_A_VALID_PARAMETER_MSG;
        return 1;
    }

    # note the value may be undefined and we set the variable to undef
    
    # set the parameter to this value
    if (set_parameter_to_value($name, SET_FUNCTION(), $value) ) {
        $error_code{$function_name} = INVALID_VALUE_CODE;
        $error_msg{$function_name} = INVALID_VALUE_MSG;
        return 1;
    }

    # return the valid SetBy value
    $error_code{$function_name} = NO_ERROR_CODE;
    $error_msg{$function_name} = NO_ERROR_MSG;
    return 0;
}

=head2 get_error_code

Get the error code
Input : the name of the function whose error code we should report
Output: the function's error code 
        or NO_FUNCTION_SPECIFIED if the user did not supply a function
        or INVALID_FUNCTION_SPECIFIED if the user provided an invalid function
=cut
sub get_error_code {
    my $function = shift;

    # check we got a function name
    if (!defined($function)) {
        return NO_FUNCTION_SPECIFIED_CODE;
    }

    # check this is one of our exported function names
    if (!defined($error_code{$function}) ) {
        return INVALID_FUNCTION_SPECIFIED_CODE;
    }

    my $code = $error_code{$function};
    return $code;

}

=head2 get_error_message

Get the error message
Input : the name of the function whose error message we should report
Output: the function's error message
        or NO_FUNCTION_SPECIFIED if the user did not supply a function
        or INVALID_FUNCTION_SPECIFIED if the user provided an invalid function
=cut
sub get_error_message {
    my $function = shift;

    # check we got a function name
    if (!defined($function)) {
        return NO_FUNCTION_SPECIFIED_MSG;
    }

    # check this is one of our exported function names
    if (!defined($error_msg{$function}) ) {
        return INVALID_FUNCTION_SPECIFIED_MSG."$function";
    }

    my $msg = $error_msg{$function};
    return $msg;
}

=head2 get_error_msg

Get the error message

This function is identical to get_error_message
=cut
sub get_error_msg {
    my $msg = shift;
    return get_error_message($msg);
}

###  ------------------   These functions are not exported -------------

# initialize a parameter and set its default value,  if default was provided
sub create_param {
    my $params = shift;

    # set function name for error reporting
    my $function_name = $function_names[4];

    # check we have some parameter to create
    if (!defined($params)) {
        $error_code{$function_name} = PARAMETER_CREATION_ERROR_CODE;
        $error_msg{$function_name}= PARAMETER_CREATION_ERROR_MSG;
        return 1;
    }
    
    # convert our input to a hash
    my %new_param = %$params;

    # check the parameter has a name
    my $name = $new_param{"Name"};
    if (!defined($name) ) {
        $error_code{$function_name} = PARAMETER_CREATION_MISSING_NAME_CODE;
        $error_msg{$function_name}= PARAMETER_CREATION_MISSING_NAME_MSG;
        return 1;
    }

    # check the parameter name is not a reserved name
    if ((lc($name) eq "h") || (lc($name) eq "help") ) {
        $error_code{$function_name} = PARAMETER_CREATION_NO_H_OPT_CODE;
        $error_msg{$function_name}= PARAMETER_CREATION_NO_H_OPT_MSG;
        return 1;
    }

    # check the parameter has a type
    my $type = $new_param{"Type"};
    if (!defined($type) ) {
        $error_code{$function_name} = PARAMETER_CREATION_MISSING_TYPE_CODE;
        $error_msg{$function_name} = PARAMETER_CREATION_MISSING_TYPE_MSG;
        return 1;
    }

    # special handling for the config file.   it is already set default, but 
    # the user can specify a default or description
    if ((lc($name) eq "c") || (lc($name) eq CONFIG_FILE_PARAMETER_NAME) ) {
        if ($new_param{"Type"} != FILE ) { 
            $error_code{$function_name} = 
                PARAMETER_CREATION_INVALID_CONFIG_FILE_TYPE_CODE;
            $error_msg{$function_name}= 
                PARAMETER_CREATION_INVALID_CONFIG_FILE_TYPE_MSG;
            return 1;
        }
    }

    # make sure the type is valid and set the type
    if (set_type($name, $new_param{"Type"}) ) {
        $error_code{$function_name} = PARAMETER_CREATION_INVALID_TYPE_CODE;
        $error_msg{$function_name} = PARAMETER_CREATION_INVALID_TYPE_MSG;
        return 1;
    } 

    # note the parameter value is not yet set
    $SetBy{$name} = NOT_SET;


    # extract optional elements for the parameter
    for my $element ( keys %new_param ) {
        if ($element eq "Description") {
            $Description{$name} = $new_param{$element};
        } elsif ($element eq "Default") {
            $Default{$name} = $new_param{$element};
            if (set_parameter_to_value($name, DEFAULT(), $Default{$name}) ) {
                $error_code{$function_name} = 
                    PARAMETER_CREATION_INVALID_DEFAULT_CODE;
                $error_msg{$function_name} = 
                    PARAMETER_CREATION_INVALID_DEFAULT_MSG;
                return 1;
            }
            $SetBy{$name} = DEFAULT;
        } elsif (( $element ne "Name" ) && ($element ne "Type") ) {
            $error_code{$function_name} = 
                PARAMETER_CREATION_INVALID_ELEMENT_CODE;
            $error_msg{$function_name} = 
                PARAMETER_CREATION_INVALID_ELEMENT_MSG;
            return 1;
        }
    }
    
    # successfully created the new parameter and set the default value 
    $error_code{$function_name} = NO_ERROR_CODE;
    $error_msg{$function_name} = NO_ERROR_MSG;
    return 0;
}


# read the command line and set the parameters based on command line settings
#  print a usage message and exit if the command line parameters are invalid 
sub read_command_line {

    # set function name for error reporting
    my $function_name = $function_names[5];

    # construct the options for GetOpt
    # automaticaly include [-h] [-help] [-c CONFIG_FILE_PARAMETER_NAME]  
    my $help;
    my %cli_value;
    my %cli = ('h|help' => \$help, 
               'c|'.CONFIG_FILE_PARAMETER_NAME().'=s' 
                 => \$cli_value{CONFIG_FILE_PARAMETER_NAME()} );

    # construct the usage message
    # automaticaly include [-h] [-help] [-c configfile] in the usage message  
    my $usage = "Usage: ".$0." [-h] [-c configuration_file]";
    my $description = "";

    # for each parameter,  add it to the options for GetOpt and the usage
    my $next_option;
    for my $name ( keys %Type ) {
        # every Type should have a GetOpt Parameter
        if (!defined($GETOPT_PARAM_FOR_TYPE{$Type{$name}} ) ) {
            $error_code{$function_name} = 
                COMMAND_LINE_USAGE_CONSTRUCTION_ERROR_CODE;
            $error_msg{$function_name} = 
                COMMAND_LINE_USAGE_CONSTRUCTION_ERROR_MSG;
            return 1;
        }
        $next_option = $name.$GETOPT_PARAM_FOR_TYPE{$Type{$name}}; 
        $cli{$next_option} = \$cli_value{$name};
 
        # every Type should have a string to display in the usage message
        if (!defined($USAGE_MSG_FOR_TYPE{$Type{$name}} ) ) {
            $error_code{$function_name} = 
                COMMAND_LINE_USAGE_CONSTRUCTION_ERROR_CODE;
            $error_msg{$function_name} = 
                COMMAND_LINE_USAGE_CONSTRUCTION_ERROR_MSG;
            return 1;
        }
        # add this parameter along with its type to the usage message
        $usage .= " [-$name ".$USAGE_MSG_FOR_TYPE{$Type{$name}}."]";
        # if this paramater has a description,  add that as well
        if (defined($Description{$name}) ) {
            $description .= "   [-$name ".$USAGE_MSG_FOR_TYPE{$Type{$name}}.
                            "] ".$Description{$name};
            # if it has a description and default value,  add the default 
            if (defined($Default{$name}) ) {
                $description .= " (Default is ".$Default{$name}.")";
            }
            # each description message is one line 
            $description .= "\n"; 
        }
    }
    # append the descriptions to our usage message
    $usage .= "\n\n".$description;

    # call Get Options with our parameters and usage message
    my $result = GetOptions (%cli);
    if ($result == 0 || defined($help) ) {
        die $usage;
    }
    
    # for each command line option set, try to set its value to the users value
    for my $opt ( keys %cli_value ) {
        # if the user supplied a value on the command line
        if (defined($cli_value{$opt}) ) {
            # set the parameter to this value
            if (set_parameter_to_value($opt,COMMAND_LINE(),$cli_value{$opt})){
                $error_code{$function_name} = INVALID_VALUE_CODE;
                $error_msg{$function_name} = INVALID_VALUE_MSG;
                return 1;
            }
            $SetBy{$opt} = COMMAND_LINE;
        }
    }

    # succesfully read and set all the CLI values
    $error_code{$function_name} = NO_ERROR_CODE;
    $error_msg{$function_name} = NO_ERROR_MSG;
    return 0;
}

# read the config file and set the parameters accordingly   
sub read_config_file {
    # set function name for error reporting
    my $function_name = $function_names[6];

    # make sure we have a config file
    if (!defined($Value{CONFIG_FILE_PARAMETER_NAME()}) ) {
        $error_code{$function_name} = NO_CONFIG_FILE_SPECIFIED_CODE;
        $error_msg{$function_name} = NO_CONFIG_FILE_SPECIFIED_MSG;
        return 1;
    }

    # if the config file doesn't exist
    if (!-e $Value{CONFIG_FILE_PARAMETER_NAME()}) {
        $error_code{$function_name} = CONFIG_FILE_NOT_FOUND_CODE;
        $error_msg{$function_name} = CONFIG_FILE_NOT_FOUND_MSG;
        return 1;
    }

    # open the config file for reading
    my $conf_fh;
    if (!open($conf_fh, $Value{CONFIG_FILE_PARAMETER_NAME()})) {
        $error_code{$function_name} = CONFIG_FILE_OPEN_FAILED_CODE;
        $error_msg{$function_name} = CONFIG_FILE_OPEN_FAILED_MSG;
        return 1;
    }

    # Start reading the file.
    my $line;
    my $line_count = 0;
    my @line_elements;
    my $name;
    my $value;
    while ($line = <$conf_fh>) {
        $line_count++;

        # Remove any trailing white space.
        chomp($line);
        $line =~ s/^\s+//g;

        # If the line starts with a #, skip it.
        if ($line =~ /^\s*#/) {
            next;
        }

        # If the line is blank, skip it.  
        if ($line =~ /^$/) {
            next;
        }


        # Split line to get parameter and value.
        @line_elements = split(/\=/, $line);

        if (@line_elements != 2) {
            $error_code{$function_name} = CONFIG_FILE_INVALID_LINE_CODE;
            $error_msg{$function_name} = CONFIG_FILE_INVALID_LINE_MSG.
               "at line $line_count,file $Value{CONFIG_FILE_PARAMETER_NAME()}";
            close($conf_fh);
            return 1;
        }
         
        $name = $line_elements[0];
        $value = $line_elements[1];

        # Remove any spaces before and after the = sign.
        $name =~ s/\s+$//g;
        $value =~ s/^\s+//g;

        # check the name matches a parameter for this program
        if (!defined($SetBy{$name}) ) {
            $error_code{$function_name} = NOT_A_VALID_PARAMETER_CODE;
            $error_msg{$function_name} = $name.NOT_A_VALID_PARAMETER_MSG;
            return 1;
        }
 
        # command line always takes precedence over the config file setting
        if ($SetBy{$name} == COMMAND_LINE) {
            next;
        }

        # set the parameter to this value
        if (set_parameter_to_value($name, CONFIG_FILE(), $value) ) {
            $error_code{$function_name} = INVALID_VALUE_CODE;
            $error_msg{$function_name} = INVALID_VALUE_MSG;
            return 1;
        }
        $SetBy{$name} = CONFIG_FILE;

    }

    # close the file and return success
    close($conf_fh);
    $error_code{$function_name} = NO_ERROR_CODE;
    $error_msg{$function_name} = NO_ERROR_MSG;
    return 0;
}

# determine if a SetBy number is valid
# return 0 if the SetBy number is allowed/valid,   
# return 1 if not allowed/invalid
sub invalidSetByField{
    my $value = shift;

    # make sure we have a possible value to check
    if (!defined($value)) {
	return 1;
    }

    # check against all of our approved SetBy values
    for my $approved ( @SETBY_VALUES ) {
        if ($value == $approved) {
            return 0;
        }
    }

    # didn't match any approved values so return not allowed/invalid 
    return 1;
}

# set the type for a parameter. 
# check the type is a supported value and return 0,  return 1 on error
sub set_type {
    my ($name, $type) = @_;

    # make sure we have the parameter name
    if (!defined($name)) {
	return 1;
    }

    # make sure we have a proposed type
    if (!defined($type)) {
	return 1;
    }

    # make sure the type is a number 
    if ($type =~ /\D/) {
	return 1;
    }

    # if the type matches any of our SUPPORTED TYPES,  set the Type value
    for my $approved ( @SUPPORTED_TYPES ) {
        if ($type == $approved) {
            $Type{$name} = $type;
            return 0;
        }
    }

    # the proposed type did not match any SUPPORTED TYPES,  return error
    return 1;
}

# set the value of a parameter and its corresponding SetBy field
# the function will make sure this is a valid value for this type of parameter
# return 0 on success and 1 on error
sub set_parameter_to_value {
    my ($name, $setby, $value) = @_;

    # set function name for error reporting
    my $function_name = $function_names[7];

    # make sure we have the parameter name
    if (!defined($name)) {
        $error_msg{$function_name} = "No parameter name given";
	return 1;
    }

    # make sure this parameter has a type
    if (!defined($Type{$name})) {
        $error_msg{$function_name} = "Parameter doesn't have a type";
	return 1;
    }

    # make sure we have a valid SetBy field
    if (invalidSetByField($setby)) {
        $error_msg{$function_name} = "Parameter has an invalid SetBy value";
	return 1;
    }

    # we can always set the value to undef...
    if (!defined($value)) {
        # indicate who has set the value for this parameter
        $SetBy{$name} = $setby;
        $Value{$name} = undef;
        $error_msg{$function_name} = NO_ERROR_MSG;
        return 0;
    }

    $SetBy{$name} = $setby;
    # set the value based on the type
    if ($Type{$name} == ADDRESS) {
        return set_address($name, $value);
    } elsif ($Type{$name} == PORT) {
        return set_port($name, $value);
    } elsif ($Type{$name} == FILE) {
        return set_file($name, $value);
    } elsif ($Type{$name} == BOOLEAN) {
        return set_boolean($name, $value);
    } elsif ($Type{$name} == STRING) {
        return set_string($name, $value);
    } elsif ($Type{$name} == UNSIGNED_INT) {
        return set_uint($name, $value);
    } else {
        # unsupported type
        $error_msg{$function_name} = "Parameter has an unsupported type";
        return 1;
    }

    # this code should never be reached...
    return 1;
}

# set an address value for this parameter
# verify this really is an IP address.   return 0 on succcess and 1 on failure
sub set_address {
    my ($name, $value) = @_;

    # set function name for error reporting
    my $function_name = $function_names[7];

    # make sure we have the parameter name
    if (!defined($name)) {
        $error_msg{$function_name} = "No parameter name given";
	return 1;
    }

    # make sure we have a value
    if (!defined($value)) {
        $error_msg{$function_name} = "No parameter value given";
	return 1;
    }

    # the Perl::Net module has nice address checkers, but we wanted to 
    # avoid a dependency....

    # check if we are an IPv4 address
    if ($value =~ /\./) {
        my @v4 = split(/\./, $value); 
        # we should have 4 elements (0, 1, 2, and 3)
        if ($#v4 != 3) { 
            $error_msg{$function_name}="IPv4 address must be in form A.B.C.D.";
            return 1;
        }
        # make sure each is a number between 0 and 255
        foreach my $v4num (@v4) { 
            if ($v4num =~ /\D/) {
                # not a number or out of range
                $error_msg{$function_name} = 
                    "IPv4 address contains a non-integer.";
                return 1;
            }
            # make sure it is in range
            if ( ($v4num < 0) || ($v4num > 255) ) {
                $error_msg{$function_name} = 
                     "IPv4 octets must be between 0 and 255.";
                return 1;
            }
        }
        # we have A.B.C.D where A, B, C, D are all numbers between 0 and 255
        $Value{$name} = $value;
        $error_msg{$function_name} = NO_ERROR_MSG;
        return 0;
    } 
    
    # check if we are a valid IPv6 address
    if ($value =~ /\:/) {
        my @v6 = split(/\:/, $value); 
        # we might be an IPv6 address,  make sure each element is a hex number
        foreach my $v6num (@v6) { 
            # check we have less than 4 chars per nibble
            my $len = length($v6num);
            if ($len > 4)  {
                $error_msg{$function_name} = 
                    "IPv6 nibble must be at most 4 chars long.";
                return 1;
            }
            # check the nibble is a hex value
            if ($v6num !~  /[0-9a-f]{$len}/i) {
                # not a number or out of range
                $error_msg{$function_name} = 
                    "Possible IPv6 address, but nibble is not hex value.";
                return 1;
             }
        }
        # we have hex numbers seperated by : values so call it valid v6
        $Value{$name} = $value;
        $error_msg{$function_name} = NO_ERROR_MSG;
        return 0;
     }

    # the value is not valid IPv4 or IPv6
    $error_msg{$function_name} = 
        "Address must be an IPv4 address or an IPv6 address.";
    return 1;
}

# set a port value for this parameter
# verify this really is a valid port.   return 0 on succcess and 1 on failure
sub set_port {
    my ($name, $value) = @_;

    # set function name for error reporting
    my $function_name = $function_names[7];

    # make sure we have the parameter name
    if (!defined($name)) {
        $error_msg{$function_name} = "No parameter name given";
	return 1;
    }

    # make sure we have a value
    if (!defined($value) ) {
        $error_msg{$function_name} = "No parameter value given";
	return 1;
    }

    # make sure it is a number
    if ($value =~ /\D/) {
        # not a number or out of range
        $error_msg{$function_name} = "Port must be a positive number.";
        return 1;
    }
    
    # make sure it is in range
    if ( ($value < 0) || ($value > 65535) ) {
        $error_msg{$function_name} = "Port must be in the range 0 to 65,536.";
        return 1;
    }

    # the value is valid so set it
    $Value{$name} = $value;
    $error_msg{$function_name} = NO_ERROR_MSG;
    return 0;
}

# set a file value for this parameter
# verify this really is a file or directory.   
# return 0 on succcess and 1 on failure
sub set_file {
    my ($name, $value) = @_;

    # set function name for error reporting
    my $function_name = $function_names[7];

    # make sure we have the parameter name
    if (!defined($name)) {
        $error_msg{$function_name} = "No parameter name given";
	return 1;
    }

    # make sure we have a value
    if (!defined($value) ) {
        $error_msg{$function_name} = "No parameter value given";
	return 1;
    }

    # we accept any string at all...

    # the value is valid so set it
    $Value{$name} = $value;
    $error_msg{$function_name} = NO_ERROR_MSG;
    return 0;
}

# set a boolean value for this parameter
# verify this really is a boolean value. return 0 on succcess and 1 on failure
sub set_boolean {
    my ($name, $value) = @_;

    # set function name for error reporting
    my $function_name = $function_names[7];

    # make sure we have the parameter name
    if (!defined($name)) {
        $error_msg{$function_name} = "No parameter name given";
	return 1;
    }

    # make sure we have a value
    if (!defined($value) ) {
        $error_msg{$function_name} = "No parameter value given";
	return 1;
    }

    # make sure it is a number
    if ($value =~ /\D/) {
        # not a number or out of range
        $error_msg{$function_name} = "Boolean must be 0 or 1.";
        return 1;
    }
    
    # the value could be false...
    if ($value == 0) {
        $Value{$name} = 0;
        $error_msg{$function_name} = NO_ERROR_MSG;
        return 0;
    }

    # or the value could be true...
    if ($value == 1) {
        $Value{$name} = 1;
        $error_msg{$function_name} = NO_ERROR_MSG;
        return 0;
    }

    # or the value is invalid...
    $error_msg{$function_name} = "Boolean must be 0 or 1.";
    return 1;
}

# set a string value for this parameter
# verify this really is a string value. return 0 on succcess and 1 on failure
sub set_string {
    my ($name, $value) = @_;

    # set function name for error reporting
    my $function_name = $function_names[7];

    # make sure we have the parameter name
    if (!defined($name)) {
        $error_msg{$function_name} = "No parameter name given";
	return 1;
    }

    # make sure we have a value
    if (!defined($value)) {
        $error_msg{$function_name} = "No parameter value given";
	return 1;
    }

    # we accept any string at all...

    # this is a valid value
    $Value{$name} = $value;
    $error_msg{$function_name} = NO_ERROR_MSG;
    return 0;
}

# set an unsigned integer  value for this parameter
# verify this really is an unsigned interger value.   
# return 0 on succcess and 1 on failure
sub set_uint {
    my ($name, $value) = @_;

    # set function name for error reporting
    my $function_name = $function_names[7];

    # make sure we have the parameter name
    if (!defined($name)) {
        $error_msg{$function_name} = "No parameter name given";
	return 1;
    }

    # make sure we have a value
    if (!defined($value) ) {
        $error_msg{$function_name} = "No parameter value given";
	return 1;
    }

    # make sure it is a number
    if ($value =~ /\D/) {
        # not a number or out of range
        $error_msg{$function_name} = "Unsigned Int must be a postive number";
        return 1;
    }
    
    # make sure it is in range
    if ($value < 0) {
        $error_msg{$function_name} = "Unsiged Int must not be less than 0.";
        return 1;
    }

    # the value is valid so set it
    $Value{$name} = $value;
    $error_msg{$function_name} = NO_ERROR_MSG;
    return 0;
}

=head2 RETURN VALUES AND ERROR CODES

configure and set_parameter return 0 on success and 1 on error.

parameter_value returns the value on success and undef on error.

parameter_set_by returns an integer indicating who set the value
 and on error it returns BGPmon::Configure::SET_ERROR

In the event of an error,   an error code and error
message can be obtained using 
  $code = get_error_code("function_name");
  $msg = get_error_msg("function_name");

The following error codes are defined:

 0 - No Error
    'No Error';

 1 - No Function Specified in get_error_code/get_error_msg
    'Error reporting function called without specifying the function.';

 2 - Invalid Funtion in get_error_code/get_error_msg
    'Error reporting function called with invalid function name';

use constant NO_PARAMETER_SPECIFIED_CODE => 3;
use constant NO_PARAMETER_SPECIFIED_MSG => 
    'No parameter name specified';
use constant NOT_A_VALID_PARAMETER_CODE => 4;
use constant NOT_A_VALID_PARAMETER_MSG => 
    'Invalid parameter name';
use constant NO_VALUE_ASSIGNED_CODE => 5;
use constant NO_VALUE_ASSIGNED_MSG => 
    'No value has been assigned to this parameter';
use constant UNDEFINED_SETBY_CODE => 6;
use constant UNDEFINED_SETBY_MSG => 
    'The SetBy field of the parameter is undefined';
use constant INVALID_SETBY_CODE => 7;
use constant INVALID_SETBY_MSG => 
    'The SetBy field of the parameter is invalid.';
use constant INVALID_VALUE_CODE => 8;
use constant INVALID_VALUE_MSG => 
    'Invalid value for parameter';
use constant PARAMETER_CREATION_ERROR_CODE => 9;
use constant PARAMETER_CREATION_ERROR_MSG => 
    'Error creating the paramter - missing parameter hash';
use constant PARAMETER_CREATION_MISSING_NAME_CODE => 10;
use constant PARAMETER_CREATION_MISSING_NAME_MSG => 
    'Error creating the paramter - parameter name is missing';
use constant PARAMETER_CREATION_MISSING_TYPE_CODE => 11;
use constant PARAMETER_CREATION_MISSING_TYPE_MSG => 
    'Error creating the paramter - parameter name is missing';
use constant PARAMETER_CREATION_INVALID_TYPE_CODE => 12;
use constant PARAMETER_CREATION_INVALID_TYPE_MSG => 
    'Error creating the paramter - invalid type ';
use constant PARAMETER_CREATION_INVALID_ELEMENT_CODE => 13;
use constant PARAMETER_CREATION_INVALID_ELEMENT_MSG => 
    'Error creating the paramter - invalid element ';
use constant PARAMETER_CREATION_INVALID_DEFAULT_CODE => 14;
use constant PARAMETER_CREATION_INVALID_DEFAULT_MSG => 
    'Error creating the paramter - invalid default value ';
use constant PARAMETER_CREATION_NO_H_OPT_CODE => 15;
use constant PARAMETER_CREATION_NO_H_OPT_MSG => 
    'Error creating the paramter - parameter name -h and -help are reserved';
use constant PARAMETER_CREATION_INVALID_CONFIG_FILE_TYPE_CODE => 16;
use constant PARAMETER_CREATION_INVALID_CONFIG_FILE_TYPE_MSG => 
    'Error creating the paramter - config file must be type FILE';
use constant COMMAND_LINE_USAGE_CONSTRUCTION_ERROR_CODE => 17;
use constant COMMAND_LINE_USAGE_CONSTRUCTION_ERROR_MSG => 
    'Unable to construct usage message for command line';
use constant NO_CONFIG_FILE_SPECIFIED_CODE => 18;
use constant NO_CONFIG_FILE_SPECIFIED_MSG => 
    'No configuration file specified';
use constant CONFIG_FILE_NOT_FOUND_CODE => 19;
use constant CONFIG_FILE_NOT_FOUND_MSG => 
    'Configuration file not found';
use constant CONFIG_FILE_OPEN_FAILED_CODE => 20;
use constant CONFIG_FILE_OPEN_FAILED_MSG => 
    'Failed to open configuration file';
use constant CONFIG_FILE_INVALID_LINE_CODE => 21;
use constant CONFIG_FILE_INVALID_LINE_MSG => 
    'Invalid line in configuration file: ';


#1234567891123456789112345678911234567891123456789112345678911234567891123456789

=head1 AUTHOR

Dan Massey, C<< <massey at cs.colostate.edu> >>

=head1 BUGS

Please report any bugs or feature requests to C<< bgpmon@netsec.colostate.edu> >>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc BGPmon::Configure
=cut

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012 Colorado State University

    Permission is hereby granted, free of charge, to any person
    obtaining a copy of this software and associated documentation
    files (the "Software"), to deal in the Software without
    restriction, including without limitation the rights to use,
    copy, modify, merge, publish, distribute, sublicense, and/or
    sell copies of the Software, and to permit persons to whom
    the Software is furnished to do so, subject to the following
    conditions:

    The above copyright notice and this permission notice shall be
    included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
    OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
    NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
    HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
    OTHER DEALINGS IN THE SOFTWARE.\

    File: Configure.pm

    Authors: Dan Massey
    Date: June 22, 2012
=cut

1;
