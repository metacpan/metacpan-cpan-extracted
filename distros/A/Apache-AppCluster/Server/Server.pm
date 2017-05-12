package Apache::AppCluster::Server;
use strict;
use Apache;
use Apache::Constants qw( :common );
use Storable qw( freeze thaw );
use Digest::MD5 qw( md5_hex );
use Time::HiRes;

use constant SRV_SUCCESS => 7;
use constant SRV_COULD_NOT_UNDERSTAND_REQ => 8;
use constant SRV_NO_SUCH_METHOD => 6;
use constant SRV_METHOD_RETURNED_ERROR => 9;

use vars qw( $VERBOSE $VERSION );

$VERSION = '0.02';

$VERBOSE = 0;

BEGIN
{
	my $begin_r = Apache->request();
	my $module_list = $begin_r->dir_config('AppCModules');
	$module_list =~ s/[\t\s\n\r]//g;
	$module_list =~ s/;$//; #remove trailing ; if found
	my @mods = split(';', $module_list);

	my $lib_list = $begin_r->dir_config('AppCLibs');
	$lib_list =~ s/[\t\s\n\r]//g;
	$lib_list =~ s/;$//; #remove trailing ; if found
	my @libs = split(';', $lib_list);


	foreach my $lib (@libs)
	{
		warn "AppCluster adding library directory: $lib" if($VERBOSE);
		my $p_code = "use lib '$lib';";
		eval $p_code;
		warn "A problem occured in Apache::AppCluster::Server while parsing your library directories: $@" if ($@);
	}

	foreach my $module (@mods)
	{
		warn "AppCluster adding module $module" if($VERBOSE);
		my $p_code = "use $module;";
		eval $p_code;
		warn "A problem occured in Apache::AppCluster::Server while parsing your modules: $@" if($@);
	}
	
}



sub handler
{
	my $r = shift @_;
	$r->send_http_header('text/html');
	if($r->method() eq 'POST')
	{
		my ($buf, $input);
		while($r->read($buf, $r->header_in('Content-Length')))
		{
			$input .= $buf;
		}
		my $response = {};
		if($input =~ m/<frozen>(.*)<\/frozen>/s)
		{
			my $data = $1;
			my $digest = substr($data, 0, 31);
			my $froz = substr($data, 32);
			if($digest == md5_hex($froz) )
			{
				my $struct = thaw($froz);
				my $func_name;
				if($struct->{method} =~ m/(.*?)(?:\(\)|$)/)
				{
					$func_name = $1;
					my $func_found = 0;
					if($func_name =~ m/(.*::)(.*)/)
					{
						no strict 'vars';
						no strict 'refs';
						my $sym_tbl = $1;
						my $func = $2;
						*stash = *{$sym_tbl};
						local (*alias) = $stash{$func};
						
						if(!defined &alias)
						{
							warn "Could not find function: $func_name" if($VERBOSE);
						} else
						{
							$func_found = 1;
						}
						
					}

					if($func_found) #Seperate block, so strict is back in effect
					{

						my $passable_param = $struct->{params};
						my $p_code = '$method_result = ' . $func_name . '($passable_param);';
						my $method_result;
						warn "Executing perl: $p_code" if($VERBOSE);
						my $eval_result = eval $p_code;
						if($@)
						{
							$response->{data} = undef;
							$response->{method_error} = $@;
							$response->{status} = SRV_METHOD_RETURNED_ERROR;
							warn "Perl eval generated error: $@" if($VERBOSE);
						} else
						{
							warn "Perl eval succesfully." if($VERBOSE);
							$response->{data} = $method_result;
							$response->{status} = SRV_SUCCESS;
						}
					} else
					{
						$response->{data} = undef;
						$response->{status} = SRV_NO_SUCH_METHOD;
					}

				}

			} else
			{
				$response->{data} = undef;
				$response->{status} = SRV_COULD_NOT_UNDERSTAND_REQ;

			}
		} else
		{
			$response->{status} = SRV_COULD_NOT_UNDERSTAND_REQ;
			$response->{data} = undef;
		}
		
		my $f_response = freeze($response);
		my $r_digest = md5_hex($f_response);
		my $r_text = '<frozen>' . $r_digest . $f_response . '</frozen>';
		print $r_text;
		return OK;
		
	} else
	{
		print "This server is not available for public access!\n";
	}
	return OK;
}

1;



=head1 NAME

Apache::AppCluster::Client

=head1 SYNOPSIS

#Make sure Apache has mod_perl compiled in
#Your httpd.conf should look like this:

 <Location "/my_app">
    SetHandler perl-script
    PerlSetVar AppCLibs "/usr/local/my_libs; \
    			/www/stuff/more_libs;"
    PerlSetVar AppCModules "Some::Module; \
    		AnotherModule; Test::Module;"
    PerlHandler Apache::AppCluster::Server
 </Location>

=head1 DESCRIPTION

Apache::AppCluster::Server sets up your apache httpd to act as a mod_perl
application server for Apache::AppCluster::Client. Most of the work happens
on the client side (see related docs). All you need to do on the server side
is install the module and set up your httpd.conf correctly as above. 

Apache spawns several child processes (up to 255) which handle multiple 
requests as they come in. This module allows your server to process 
multiple concurrent remote method calls from a client while taking
advantage of the persistence and other performance benifits mod_perl has
to offer. 

=head1 CONFIGURATION

You configure the server using PerlSetVar statements followed by the 
variable followed by the value. Your value can span multiple lines provided
you end each line with a \ character. Each value must be enclosed in double
quotes.

=over 4

=item AppCLibs

AppCLibs is used to specify any directories that contain modules you will
be calling from Apache::AppCluster::Client. Directories must be seperated
by semi-colons. Each directory specified is added to @INC when the server
is started in preparation for the 'use' statement called for each module
in AppCModules.

=item AppCModules

AppCModules is used to specify all modules you will be calling from
Apache::AppCluster::Client. Modules are seperated by semi-colons and
their full names must be specified as if you were including the name
in a 'use' statement. Check the apache error_log for warnings about
not being able to 'use' modules you've specified in AppCModules.
Modules are parsed by the server when it is started up to take advantage
of mod_perl's persistence. 

=back

=head1 MISC

Your Apache::AppCluster::Server needs to be configured to 
handle a specific uri. You can use any location you like:

 <Location "/blah">
   #config info - see SYNOPSIS for an example
 </Location>

Your Apache::AppCluster::Client must then set the url for 
each request registered to point to that uri. See the Client
documentation for details.


=head1 BUGS

None known. Please send any to the author.

=head1 SEE ALSO

Apache::AppCluster::Client

=head1 AUTHOR

Mark Maunder <mark@swiftcamel.com> - Any problems, suggestions, bugs etc.. are welcome.

=cut
