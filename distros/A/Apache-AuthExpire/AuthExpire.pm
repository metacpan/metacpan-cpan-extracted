package Apache::AuthExpire;
#file Apache/AuthExpire.pm
#
#	Author: J. J. Horner
#	Version: 0.36 (09/07/2001)
#	Usage:  see documentation
#	Description:
#		Small mod_perl handler to provide Athentication phase time outs for 
#		sensitive areas, per realm.  Still has a few issues, but nothing too 
#		serious.

use strict;
use Carp;
use Apache::Constants qw(:common);
use Apache::Log;

our $VERSION = '0.36';

sub handler {

    my $current_time = time();    # Time will be used here :)

    my $r = shift;
    my $log = $r->log;
	return DECLINED unless $r->is_initial_req;

    #grab debug value from config files.
    #Sends 'debug' level messages to error_log when set. 
    my $DEBUG;

    if (defined ($r->dir_config('TIMEOUT_DEBUG'))) { 
        $DEBUG = $r->dir_config('TIMEOUT_DEBUG'); 
        $log->notice("Debug value set to $DEBUG.");
    }

    my ($res, $sent_pw) = $r->get_basic_auth_pw;
    return $res if $res != OK;  # return not OK status if not OK

    my ($limit, $default, $time_to_die);
    my $request_line = $r->the_request;

    # Grab TimeLimit from .htaccess file (if available)
    # or use DefaultLimit if TimeLimit not set or if
    # TimeLimit greater than default.  Can't have longer
    # time limits than max set by policy.
    
    $limit = $r->dir_config('TimeLimit') if (defined($r->dir_config('TimeLimit')) && $r->dir_config('TimeLimit') > 1);
    $default = $r->dir_config('DefaultLimit');
    $log->notice("Default Limit set to $default.") if ($DEBUG);

	if (defined($limit)) {
    	$time_to_die = ($limit < $default) ? $limit : $default;
		$log->notice("Time Limit for $request_line set to $limit") if ($DEBUG);
	} else {
		$time_to_die = $default;
	}	
	
    # Do nothing if MODE set to 'Off'.
    return DECLINED if ($r->dir_config('MODE') eq 'Off');

    my $user = $r->connection->user;
    my $realm = $r->auth_name();
    $realm =~ s/\s+/_/g;
    $realm =~ s/\//_/g;
    my $host = $r->get_remote_host();
    my $time_file = $r->server_root_relative("conf/times/$realm-$host.$user");
    $log->notice("Time file set to $time_file") if ($DEBUG);
    if (-e $time_file) {   # if timestamp file exists, check time difference
        my $last_time = (stat($time_file))[9] 
            || $log->warn("Unable to get last modtime from file: $!");

        my $time_delta = ($current_time - $last_time); # Determine time since last access
        if ($time_to_die >  $time_delta) {
        	# time delta = specified time limit
            open (TIME, ">$time_file") 
                || $log->warn("Can't update timestamp on $time_file: $!");
            close TIME;
            return OK;

        } else {  # time delta greater than TimeLimit
            $log->notice("Time since last access: $time_delta") if ($DEBUG);
            $r->note_basic_auth_failure;
            unlink($time_file) or $log->warn("Can't unlink file: $!");
            return AUTH_REQUIRED;
        }

    } else {  
    # previous time delta greater than TimeLimit so file was unlinked
    # or first time checking into server.
        
        open (TIME, ">$time_file") || $log->crit("Unable to create $time_file: $!\n");
        close TIME;
        return OK;
    }
}

1;
__END__

=head1 NAME

Apache::AuthExpire - mod_perl handler to provide Authentication time limits on .htaccess protected pages.

=head1 SYNOPSIS

  In httpd.conf file:
	PerlAuthenHandler Apache::AuthExpire
	PerlSetVar DefaultLimit <timeout in seconds>

  Optional httpd.conf file entry:
	PerlSetVar TIMEOUT_DEBUG <0 || 1>
	   Turns debugging on to print messages to server error_log

  Optional .htaccess entries: 
	PerlSetVar TimeLimit <time>
	    or
	PerlSetVar MODE Off        # to turn off timeouts
                                # Will provide further methods later.

=head1 DESCRIPTION

  Simple mod_perl handler for the AUTHENTICATION phase to set a limit on user inactivity.
  Will provide timeouts to any file under the protection of an .htaccess file, unless the 
  'MODE' option set to anything other than 0 in the .htaccess file.  The 'DefaultLimit' is
  set via the httpd.conf file, and unless the user specified 'TimeLimit' is set and less 
  than the 'DefaultLimit', determines the length of time a user can be inactive.  This 
  handler can be set anywhere an AUTHENTICATION handler can be specified.

=head2 Caveats

  Does not work well with all browsers at this stage, please see
  mod_perl guide for more information.
  
=head1 EXPORT

None by default.


=head1 AUTHOR

J. J. Horner jjhorner@bellsouth.net

=head1 SEE ALSO

perl and mod_perl.

=head1 LOCATION

Can be downloaded from
http://www.2jnetworks.com/~jhorner/Apache-AuthExpire.tar.gz

=head1 CREDITS

plaid and merlyn from http://perlmonks.org/ for general help and debugging.

=cut
