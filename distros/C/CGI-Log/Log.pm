package CGI::Log;

use strict;

$CGI::Log::VERSION	= '1.00';
$CGI::Log::DEBUG_FLAG	= 1;		## undef to turn off debugging...

*Log:: = \%CGI::Log::;			## short cut for calling, so the following are equivalent:
					##   CGI::Log->debug("hi"); 
					##   Log->debug("hi");

=head1 NAME

CGI::Log - Perl extension for centralized logging of debug, error, status and success messages from scripts or other modules.

=head1 SYNOPSIS

  use CGI::Log;

  Log->debug("user: $user");		## add messages
  Log->status("Welcome $user.");
  Log->error("I'm sorry $user, but you do not have access to that area.");

  @msg = Log->get_debug();		## get messages
  @msg = Log->get_error();
  @msg = Log->get_error("UI");
  @msg = Log->get_status();

  Log->is_error;			## test for messages
  Log->is_status;
  Log->is_success;

  Log->debug_off;		## causes print() and debug() to be skipped

  Log->print();			## outputs debug and error logs in HTML
  Log->clear;			## clear all entries (current pid)

  Log->_report;			## reports the sizes of the arrays (lengths)
  Log->ui_no_error();		## turns off inclusion of $! in user error messages

=head1 DESCRIPTION

This module acts as a central repository for debug, status and error
messages.  It instantiates itself automatically (if it needs to) so you can access the
Log object functions from anywhere in you code including other modules/objects
with a simple consistent syntax.

It was written for CGI and mod_perl programming, but it could
easily be used in any perl script where there is a need for centralized
logging.  (The only function which is CGI specific is print() since it
outputs the debug and error logs with HTML formatting.)

It was originally written to just hold debugging information, but it
has been extended to hold information that you might want to return to
the user (i.e. the user-interface).

It is designed to be very painless to use.  Add the following to any script or module
where you want to log messages:

	use CGI::Log;

The CGI::Log:: namespace has been aliased to Log:: in order to save
a bit of typing when adding debugging messages.  So, to add a debug
message, enter:

	Log->debug("Your message here.");
	## note: this is equivalent to CGI::Log->debug();

To add an error message:

	Log->error("Some information about the error goes here.");

To add an success, or status message:

	Log->status("A status or informational message for the user.");
	Log->success("Something worked properly.");


The following commands all retrieve the messages you've logged:

	@msg = Log->get_debug;
	@msg = Log->get_error;
	@msg = Log->get_error("UI");
	@msg = Log->get_status;
	@msg = Log->get_success;

Note: All the get_* methods return array references when called in
scalar context.  e.g.

	$msg = Log->get_success;	## ref($msg) eq "ARRAY"

During CGI/mod_perl development it is very handy to dump all of the
debugging messages at the bottom of the HTML page.  This is done with:

	Log->print;

This can just be left at the bottom of your main script.  Logging can
be turned off (default is on), and when it is turned off Log->print()
doesn't do anything.


=head2 Types and Formats of Messages 

Each of the four types of messages (debug, error, status, success)
have slightly different logic.  The differences are as follows:

The debug messages are not designed to be visable by the user (and in fact
may be a security risk if you show the connection string for databases, etc.)
The format of a debug message is:

	[caller:line [caller:line...]] message

	where:

	caller is a method name
	line is the line number from the method 
	message is your debugging message 

An example will make this clearer:

    [file: test.pl]

    1:      use CGI::Log;
    2:      &foo;
    3:      sub foo
    4:      {
    5:            Log->debug("We are on line 5 of the method: foo");
    6:            &bar;
    7:      }
    8:      sub bar
    9:      {
    10:           Log->debug("line 10 method: bar process id: " . $$);
    11:           Log->error("Error on line 11 in the method: bar");
    12:     }
    13:     Log->print();

When run it prints:

    -- DEBUG (test.pl) (pid: 3262) --
    [main:2 main::foo:5] We are on line 5 of the method: foo
    [main:2 main::foo:6 main::bar:10] line 10 method: bar process id: 456
    [ERROR] [main:2 main::foo:6 main::bar:11] This an error being called from the method: bar (No such file or directory)
    -- ERROR --
    [main:2 main::foo:6 main::bar:11] Error on line 11 in the method: bar (No such file or directory)

(Note: the HTML in the output has been removed for clarity.)

There are some things to note:

=over 4

=item 

Each debug message includes the context of how it came to
be called.  This allows for your debug messages to be very short -- often just stating a
simple fact such as "a is undefined" or showing the value of a variable.

=item 

Error messages are duplicated in the error and debug arrays,
so that you can determine how your error message got called,
and its relation to any debugging messages.

=item 

Error messages in the debug list have "[ERROR]" prepended
to them.

=item 

Error messages include the contents of the error variable
$! in brackets.  This saves you from having to remember to
include this variable in your error message.

=back


Log messages of type "status" and "success" are not manipulated or modified.
Whatever you put in is what you get back.

Log messages of type "error" are stored in two formats.  The first is the
format that in the output above.  The second is suitable for returning to
the user.  (It doesn't include the call trace.)  By default it includes
the error message from the variable $!.  If this is not desirable,
call Log->ui_no_error()


=head1 TIPS/TRICKS

=over 4

=item

It is nice to be able to add as many debugging messages without having
to worry about slowing down your application when it gets deployed.
Calling Log->debug_off will set the instance variable DEBUG_FLAG to
undefined, and will prevent any messages in the current process from
being stored.  e.g.

	if ($config{DEBUG} eq "Off")	## pretend %config holds global
	{				##   configuration info
		Log->debug_off;
	}
	Log->debug("this debug message won't be saved because debugging is off.");

=item

Even though the debug() function won't do anything when debugging is
turned off (it returns immediately), there is still the overhead of a
function call for each debug message.  If you really want to get obsessive
about performance you can try redefining the debug() method.  e.g.

	use CGI::Log;
	sub CGI::Log::debug () { 1 };		## redefine with prototype so it gets inlined
						## note: I haven't tested the efficiency of this!
						##
						## note: prototypes are from perl 5.002 +


=item

It is very handy to be able to turn on debugging from the URL.  e.g.

	http://somewhere.com/cgi-bin/test.pl?debug=secret

In your perl code you could have:

	if ($param{debug} ne "secret" 		## $param{debug} holds the CGI variable "debug" 
		|| $DEBUG != 1)			## $DEBUG is a config variable
	{
		Log->debug_off();
	}

This can be a huge timesaver if access to the webserver is difficult.
This can be huge trouble if you have confidential or security related
information in your debugging messages.  (That is why "debug" in the above
example is the string "secret" and not "1" or something easy to guess.)

=item

You can add nice status messages to your web application by doing something like:


	if (Log->is_error)
	{
		print "<font color=\"#ff0000\">ERROR</font><BR>\n";
		for (Log->get_error) { print $_ . "<BR>\n"; }
	}
	elsif (Log->is_success)
	{
		print "<img src=\"smiley_face.gif\">";
		for (Log->get_success) { print $_ . "<BR>\n"; }
	}

	for (Log->get_status) { print $_ . "<BR>\n"; }

=item

Make sure you have "Log" and not "log" or you will get the run-time error:

	Can't take log of 0

=item

At the end of your script (whether a CGI or mod_perl) you will almost always want a:

	Log->clear;

=back


Documentation for CGI::Log was created by h2xs. 

=head1 BUGS

- too much noise in the debug call tracing under mod_perl. e.g.

	[main:0 (eval):0 Apache::Registry::handler:141 (eval):141 Apache::ROOT::perl::test_5flog_2epl::handler:16] debug message.

- not thread-safe.

- if you are using mod_perl and you do not remember to clean out the log with Log->clean(), 
you will waste lots of memory.

- CGI::Log takes the Log:: namespace by default.  This might be seen as rude, or cause
problems if it is already being used.  (Check if %Log:: is defined???)


=head1 AUTHOR

Jason Moore, 1998 <jmoore@sober.com>

=head1 SEE ALSO

perl(1). 

modperl(1).

=cut

##################################################
sub	new
##
##      - initialize a CGI::Log object
##      - creates instance variables using PID
##
##      - note: you generally don't want to call this directly, as it
##        is called automatically by the other methods if required.
##
## returns: Log::CGI object ref
##
##################################################
{
	my $class = shift;
	my $self = {};
	bless $self;

	## defaults

	$self->{DEBUG_FLAG} = $CGI::Log::DEBUG_FLAG;

	## the following are defined here even though there would be vifified/created
	## automatically when called, since there are errors if i try to access
	## the anon array if it hasn't been defined.

	## e.g. looking at @{$self->{ERROR}} gives the error:
	##      Can't use an undefined value as an ARRAY reference 
	##

	$self->{DEBUG}		= [];		# programmer
	$self->{ERROR}		= [];			

	$self->{UI_ERROR}	= [];		# user/user-interface
	$self->{SUCCESS}	= [];
	$self->{STATUS}		= [];

	return($self);
}

##################################################
##
sub debug_off
##  
##   - sets DEBUG_FLAG so that calls to Log->debug() return without doing
##     anything.  Also, calls to Log->print() return without doing anything.
{
	my($self) = @_;
	
	if (!ref($self))		## not instantiated
	{
		CGI::Log->_find_self(\$self);
	}

	$self->{DEBUG_FLAG} = undef;
	return(1);
}

##################################################
##
sub debug
##
##
{
	return(1) if !defined($CGI::Log::DEBUG_FLAG);

	my($self, $debug) = @_;

	CGI::Log->_find_self(\$self);			## $self is now an instantiated Log object

	my $t = $self->_trace();

	push(@{$self->{DEBUG}}, $t . " " . $debug);

	return(1);
}

##################################################
##
sub error
##
##
{
	my($self, $err) = @_;

	CGI::Log->_find_self(\$self);			## $self is now an instantiated Log object

	my $t = $self->_trace();

	## errors get put into DEBUG, UI_ERROR and ERROR

	my $ui_err;
	if (!defined($self->{NO_UI_ERROR}))
	{
		$ui_err = " ($!)"; 
	}

	push(@{$self->{DEBUG}}, "[ERROR] " . $t . " " . $err . " ($!)");
	push(@{$self->{ERROR}}, $t . " " . $err . " ($!)");
	push(@{$self->{UI_ERROR}}, $err . $ui_err);

	return(1);
}

##################################################
##
sub status
##
##
{
	my($self, $msg) = @_;

	CGI::Log->_find_self(\$self);
	push(@{$self->{STATUS}}, $msg);
	return(1);
}

##################################################
##
sub success
##
##   - adds a "success" message
##
{
	my($self, $msg) = @_;

	CGI::Log->_find_self(\$self);
	push(@{$self->{SUCCESS}}, $msg);
	return(1);
}

##################################################
##
sub get_debug
##
##   returns: array (or array ref in scalar context) of "debug" messages
## 
{
	my($self) = @_;
	return( CGI::Log->_get("DEBUG") );
}

##################################################
##
sub get_error
##
##   0:
##   1: "UI" will return the error messages suitable to return to the user
##   returns: array (or array ref in scalar context) of "error" messages
## 
{
	my($self, $what) = @_;
	if (uc($what) eq "UI")
	{
		$what = "UI_ERROR";
	}
	else
	{
		$what = "ERROR";	
	}

	return( CGI::Log->_get($what) );
}

##################################################
##
sub get_success
##
##   - returns: array (or array ref in scalar context) of "success" messages
## 
{
	my($self) = @_;
	return( CGI::Log->_get("SUCCESS") );
}

##################################################
##
sub get_status
##
##   - returns: array (or array ref in scalar context) of "success" messages
## 
{
	my($self) = @_;

	return( CGI::Log->_get("STATUS") );
}

##################################################
##
sub _get
{
	my($self, $what) = @_;
	CGI::Log->_find_self(\$self);			## $self is now an instantiated Log object
	return($self->{$what}) if !wantarray;
	return(@{$self->{$what}});
}

##################################################
##
sub is_error
##
##   - returns: number of errors
##
{
	my($self) = @_;
	CGI::Log->_find_self(\$self);			## $self is now an instantiated Log object

	return( scalar(@{$self->{ERROR}}) );
}

##################################################
##
sub is_success
##
##   - returns: number of "success" messages
##
{
	my($self) = @_;
	CGI::Log->_find_self(\$self);			## $self is now an instantiated Log object

	return( scalar(@{$self->{SUCCESS}}) );
}

##################################################
##
sub is_status
##
##   - returns: number of status messages 
##
{
	my($self) = @_;
	CGI::Log->_find_self(\$self);

	return( scalar(@{$self->{STATUS}}) );
}



##################################################
##
sub print
##
##   - if debugging is on, prints out contents of debug array
##
##
{
	my($self) = @_;

	CGI::Log->_find_self(\$self);

	if (!$self->{DEBUG_FLAG})
	{
		# print "Log print OFF.\n";
		return(1);
	}

	print "-- DEBUG ($0) (pid: $$) --<BR>\n";

	my $m;
	for $m (@{$self->{DEBUG}})
	{
		print $m . "<BR>\n";
	}

	if ($self->is_error)
	{
		print "<BR>\n-- ERROR --<BR>\n";
	
		for $m (@{$self->{ERROR}})
		{
			print $m . "<BR>\n";
		}
	}
}


##################################################
##
sub ui_no_error
{
	my($self) = @_;
	CGI::Log->_find_self(\$self);
	$self->{NO_UI_ERROR} = 1;
}

##################################################
##
sub _find_self
##
##   - returns the Log object for this process id (pid)
##   - private method 
##   - automatically instantiates the Log object for 
##     the current process id if required. 
##
##
##
{
	my($self, $new_self) = @_;

	if (defined($new_self) &&
		## $$new_self eq "CGI::Log")		## it's bad to assume the name of the caller object
		!ref($$new_self) )			## just checking for a ref is better
	{
		## find the Log object for this pid

		if (!defined($CGI::Log::instance))
		{
			# print "instantiated object does not exist. creating.\n";
			$$new_self = new CGI::Log;
			$CGI::Log::instance = $$new_self;
		}
		else
		{
			$$new_self = $CGI::Log::instance;
			# print "object exists. self is: $self object: $$new_self\n";
		}
	}

	return(1);			## value of reference is edited, so just return true.
}


##################################################
##
sub _trace
##
##   - traces up from a function call.  Output is in the format:
##        function:line [function:line]
##   - the output moves from the top down to the caller.. (i.e. starts at "main") 
##
##
##
{
        my($self) = @_;

	## CGI::Log->_find_self(\$self);		## we have "found outselves" (what object
							## reference we are, by the time we get here.)

        my @call = caller(1);
        my $line = $call[2];
        my $cnt = 2;

        my @stack;

        while (defined($call[0]))
        {
                my $caller = $call[0];
                @call = caller($cnt);
                $call[3] = $caller if (!defined($call[3]));
                unshift(@stack, $call[3] . ":" . $line);
                $line = $call[2];
                $cnt++;
        }
        return("[" . join(" ", @stack) . "]");
}

##################################################
##
sub _report
{
##   report on how many Log objects there are, and size of 
##   arrays in each object.
##
##   returns: scalar

	my $c = 0;
	my($self) = @_;
	my($out);

	CGI::Log->_find_self(\$self);

	$out = "Log Report (PID: $$)\n<ul>\n";

	for ("DEBUG", "ERROR", "UI_ERROR", "SUCCESS", "STATUS")
	{
		$out .= $_ . ": " . scalar(@{$self->{$_}}) . " <BR>\n";
	}
	$out .= "</ul>\n";
	return($out);
}

##################################################
##
sub clear 
##
##   clears/resets all the arrays
##
{
	my($self) = @_;
	CGI::Log->_find_self(\$self);

	$self->{DEBUG}		= [];
	$self->{ERROR}		= [];
	$self->{UI_ERROR}	= [];
	$self->{STATUS}		= [];
	$self->{SUCCESS}	= [];
}

##################################################
##
#sub DESTROY 
##
#{
#}



1;

