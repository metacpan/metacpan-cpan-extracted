#######################################################################
# Apache::ParseLog
#
#    Module to parse and process the Apache log files
#
#    See the manpage for the usage
#    
#    Written by Akira Hangai
#    For comments, suggestions, opinions, etc., 
#    email to: akira@discover-net.net
#
#    Copyright 1998 by Akira Hangai. All rights reserved. 
#    This program is free software; You can redistribute it and/or 
#    modify it under the same terms as Perl itself. 
#######################################################################
package Apache::ParseLog;

require 5.004;
use Carp;
use vars qw($VERSION);
$VERSION = "1.02";

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(countryByCode statusByCode sortHashByValue);
@EXPORT_OK = qw(countryByCode statusByCode sortHashByValue);

=head1 NAME

Apache::ParseLog - Object-oriented Perl extension for parsing Apache log files

=head1 SYNOPSIS

    use Apache::ParseLog;
    $base = new Apache::ParseLog();
    $transferlog = $base->getTransferLog();
    %dailytransferredbytes = $transferlog->bytebydate();
    ...

=head1 DESCRIPTION

Apache::ParseLog provides an easy way to parse the Apache log files, 
using object-oriented constructs. The data obtained using this module
are generic enough that it is flexible to use the data for your own  
applications, such as CGI, simple text-only report generater, feeding 
RDBMS, data for Perl/Tk-based GUI application, etc.

=head1 FEATURES

=over 4

=item 1

B<Easy and Portable Log-Parsing Methods>

Because all of the work (parsing logs, constructing regex, matching and 
assigning to variables, etc.) is done inside this module, you can easily 
create log reports (unless your logs need intense scrutiny). Read on this
manpage as well as the L<"EXAMPLES"> section to see how easy it is to
create log reports with this module. 

Also, this module does not require C compiler, and it can (should) run on 
any platforms supported by Perl. 

=item 2

B<Support for LogFormat/CustomLog>

The Apache Web Server 1.3.x's new LogForamt/CustomLog feature (with 
mod_log_config) is supported. 

The log format specified with Apache's F<LogFormat> directive in the 
F<httpd.conf> file will be parsed and the regular expressions will be 
created dynamically inside this module, so re-writing your existing 
code will be minimal when the log format is changed. 

=item 3

B<Reports on Unique Visitor Counts>

Tranditionally, the hit count is calculated based on the number of B<files>
requested by visitors (the simplest is the the total number of lines of
the log file calculated as the "total hit"). 

As such, the hit count obviously can be misleading in the sense of "how
many visitors have actually visited my site?", especially if the
pages of your site contain many images (because each image is counted as
one hit). 

Apache::ParseLog provides the methods to obtain such traditional data, 
because those data also are very important for monitoring your web
site's activities. However, this module also provides the methods to
obtain the B<unique visitor counts>, i.e., the actual number of "people"
(well, IP or hostname) who visited your site, by date, time, and date 
and time. 

See the L<"LOG OBJECT METHODS"> for details about those methods. 

=item 4

B<Pre-Compiled Regex>

The new pre-compiled regex feature introduced by Perl 5.005 is used (if
you have the version installed on your machine). 

For the pre-compiled regex and the new quote-like assignment operator (qr), 
see perlop(1) and perlre(1) manpages. 

=back

=cut

#######################################################################
# Local variables
local($HOST, $LOGIN, $DATETIME, $REQUEST, $OSTATUS, $LSTATUS, $BYTE, $FILENAME, $ADDR, $PORT, $PROC, $SEC, $URL, $HOSTNAME, $REFERER, $UAGENT);

my(%COUNTRY_BY_CODE) = map { 
    chomp; 
    my(@line) = split(/:/); 
    $line[0] => $line[1] 
} <DATA>;

my(%STATUS_BY_CODE) = (
    100 => "Continue",
    101 => "Switching Protocols",
    200 => "OK",
    201 => "Created",
    202 => "Accepted",
    203 => "Non-Authoritative Information",
    204 => "No Content",
    205 => "Reset Content",
    206 => "Partial Content",
    300 => "Multiple Choices",
    301 => "Moved Permanently",
    302 => "Moved Temporarily",
    303 => "See Other",
    304 => "Not Modified",
    305 => "Use Proxy",
    400 => "Bad Request",
    401 => "Unauthorized",
    402 => "Payment Required",
    403 => "Forbidden",
    404 => "Not Found",
    405 => "Method Not Allowed",
    406 => "Not Acceptable",
    407 => "Proxy Authentication Required",
    408 => "Request Time-out",
    409 => "Conflict",
    410 => "Gone",
    411 => "Length Required",
    412 => "Precondition Failed",
    413 => "Request Entity Too Large",
    414 => "Request-URI Too Large",
    415 => "Unsupported Media Type",
    500 => "Internal Server Error",
    501 => "Not Implemented",
    502 => "Bad Gateway",
    503 => "Service Unavailable",
    504 => "Gateway Time-out",
    505 => "HTTP Version not supported",
);

my(%M2N) = (
    'Jan' => '01',
    'Feb' => '02',
    'Mar' => '03',
    'Apr' => '04',
    'May' => '05',
    'Jun' => '06',
    'Jul' => '07',
    'Aug' => '08',
    'Sep' => '09',
    'Oct' => '10',
    'Nov' => '11',
    'Dec' => '12',
);

#######################################################################
# Constructor
#######################################################################
=pod

=head1 CONSTRUCTOR

To construct an Apache::ParseLog object,B<new()> method is available
just like other modules. 

The C<new()> constructor returns an Apache::ParseLog base object with
which to obtain basic server information as well as to construct 
B<log objects>.

=cut

#######################################################################
# new([$path_to_httpd.conf]); returns ParseLog object
=pod

=head2 New Method

B<C<new([$path_to_httpd_conf[, $virtual_host]]);>>

With the B<C<new()>> method, an Apache::ParseLog object can be created
in three different ways. 

=over 4

=item 1

C<$base = new Apache::ParseLog();>

This first method creates an empty object, which means that the fields of 
the object are undefined (C<undef>); i.e., the object does not know 
what the server name is, where the log files are, etc. It is useful 
when you need to parse log files that are B<not> created on the local 
Apache server (e.g., the log files FTP'd from elsewhere). 

You have to use the B<C<config()>> method (see below) to call any 
other methods. 

=item 2

C<$base = new Apache::ParseLog($httpd_conf);>

This is the second way to create an object with necessary information
extracted from the I<$httpd_conf>. I<$httpd_conf> is a scalar string 
containing the absolute path to the F<httpd.conf> file; e.g., 

    $httpd_conf = "/usr/local/httpd/conf/httpd.conf";

This method tries to extract the information from I<$httpd_conf>, 
specified by the following Apache directives: 
F<ServerName>, F<Port>, F<ServerAdmin>, F<TransferLog>, F<ErrorLog>, 
F<AgentLog>, F<RefererLog>, and any user-defined F<CustomLog> along
with F<LogFormat>.

If any of the directives cannot be found or commented out in the 
I<$httpd_conf>, then the field(s) for that directive(s) will be
empty (C<undef>), and corresponding methods that use the particular fields
return an empty string when called, or error out (for B<log object 
methods>, refer to the section below). 

=item 3

C<$base = new Apache::ParseLog($httpd_conf, $virtual_host);>

This method creates an object just like the second method, but for the
VirtualHost specified by I<$virtual_host> B<only>. The Apache directives
and rules not specified within the <VitualHost xxx> and </VirtualHost>
tags are parsed from the "regular" server section in the F<httpd.conf> file. 

Note that the I<$httpd_conf> B<must> be specified in order to create an
object for the I<$virtual_host>.

=back

=cut

sub new {
    my($package) = shift;
    my($httpd_conf) = shift;
    my($virtual_host) = shift;
    my(%ARG);
    my($METHOD) = "Apache::ParseLog::new";
    if (defined($httpd_conf)) { 
        unless (-e $httpd_conf) {
            croak "$METHOD: $httpd_conf does not exist. Exiting...";
        } else {
            %ARG = populate($httpd_conf, $virtual_host);
        }
    }
    return config($package, %ARG);
}

#######################################################################
# BASE OBJECT METHODS
#######################################################################
=pod

=head1 BASE OBJECT METHODS

This section describes the methods available for the base object created
by the B<C<new()>> construct described above. 

Unless the object is created with an empty argument, the Apache::ParseLog
module parses the basic information configured in the F<httpd.conf> file 
(as passed as the first argument). The object uses the information
to construct the B<log object>. 

The available methods are (return values are in parentheses):

    $base->config([%fields]); # (object)
    $base->version(); # (scalar)
    $base->serverroot(); # (scalar)
    $base->servername(); # (scalar)
    $base->httpport(); # (scalar)
    $base->serveradmin(); # (scalar)
    $base->transferlog(); # (scalar)
    $base->errorlog(); # (scalar)
    $base->agentlog(); # (scalar)
    $base->refererlog(); # (scalar)
    $base->customlog(); # (array)
    $base->customlogLocation($name); # (scalar)
    $base->customlogExists($name); # (scalar boolean, 1 or 0)
    $base->customlogFormat($name); # (scalar)
    $base->getTransferLog(); # (object)
    $base->getErrorLog(); # (object)
    $base->getRefererLog(); # (object)
    $base->getAgentLog(); # (object)
    $base->getCustomLog(); # (object)

=over 4

=cut


#######################################################################
# config($ParseLog, %arg); returns ParseLog object
=pod

=item *

C<config(%fields]);>

    $base = $base->config(field1 => value1,
                          field2 => valud2,
                          fieldN => valueN);

This method configures the Apache::ParseLog object. Possible fields are:

    Field Name                     Value
    ---------------------------------------------------------
    serverroot  => absolute path to the server root directory
    servername  => name of the server, e.g., "www.mysite.com"
    httpport    => httpd port, e.g., 80
    serveradmin => the administrator, e.g., "admin@mysite.com"
    transferlog => absolute path to the transfer log
    errorlog    => absolute path to the error log
    agentlog    => absolute path to the agent log
    refererlog  => absolute path to the referer log

This method should be called after the empty object is created 
(C<new()>, see above). However, you can override the value(s) for any 
fields by calling this method even if the object is created with defined 
I<$httpd_conf> and I<$virtual_host>. (Convenient if you don't have any
httpd server running on your machine but have to parse the log files 
transferred from elsewhere.) 

Any fields are optional, but at least one field should be specified
(otherwise why use this method?). 

When this method is called from the empty object, and B<not> all the fields
are specified, the empty field still will be empty (thereby not being able
to use some corresponding methods). 

When this method is called from the already configured object (with 
C<new($httpd_conf[, $virtual_host])>), the fields specified in 
this C<config()> method will override the existing field values, and 
the rest of the fields inherit the pre-existing values. 

B<NOTE 1:> This method B<returns a newly configured object>, so make sure
to use the assignment operator to create the new object 
(see examples below).

B<NOTE 2:> You B<cannot> (re)configure F<CustomLog> values. It is to alleviate 
the possible broken log formats, which would render the parsed results
unusable. 

Example 1

    # Create an empty object first
    $base = new Apache::ParseLog();
    # Configure the transfer and error fields only, for the files
    # transferred from your Web site hosting service
    $logs = "/home/webmaster/logs";
    $base = $base->config(transferlog => "$logs/transfer_log",
                          errorlog    => "$logs/error_log");

Example 2

    # Create an object with $httpd_conf
    $base = new Apache::ParseLog("/usr/local/httpd/conf/httpd.conf");
    # Overrides some fields
    $logs = "/usr/local/httpd/logs";
    $base = $base->config(transferlog => "$logs/old/trans_199807",
                          errorlog    => "$logs/old/error_199807",
                          agentlog    => "$logs/old/agent_199807",
                          refererlog  => "$logs/old/refer_199807");

=cut

sub config {
    my($this, %arg) = @_;
    my($root, $servername, $port, $admin, $transfer, $error, $agent, $referer, %customlog);
    $serverroot = $arg{'serverroot'} || $this->{'serverroot'};
    $servername = $arg{'servername'} || $this->{'servername'};
    $httpport = $arg{'httpport'} || $this->{'httpport'};
    $serveradmin = $arg{'serveradmin'} || $this->{'serveradmin'};
    $transferlog = $arg{'transferlog'} || $this->{'transferlog'};
    $errorlog = $arg{'errorlog'} || $this->{'errorlog'};
    $agentlog = $arg{'agentlog'} || $this->{'agentlog'};
    $refererlog = $arg{'refererlog'} || $this->{'refererlog'};
    $customlog = $arg{'customlog'} || $this->{'customlog'};
    return bless {
        'serverroot'  => $serverroot,
        'servername'  => $servername,
        'httpport'    => $httpport,
        'serveradmin' => $serveradmin,
        'transferlog' => $transferlog,
        'errorlog'    => $errorlog,
        'agentlog'    => $agentlog,
        'refererlog'  => $refererlog,
        'customlog'   => $customlog,
    }
}

#######################################################################
# populate($path_to_httpd.conf[, $virtualHost]); return %arg; private
sub populate {
    my($conf) = shift;
    my($virtualhost) = shift;
    my($VIRTUAL) = ($virtualhost ? 1 : 0);
    my(%arg, $fh, $line, $serverroot, $servername, $httpport, $serveradmin, $transferlog, $errorlog, $agentlog, $refererlog, $customlog, @nickname, %location, %format);
    $fh = openFile($conf);
    while(defined($line = <$fh>)) {
        chomp($line);
        if ($line =~ /^ServerRoot\s+(.+)$/) { 
            $serverroot = $1;
        } elsif ($line =~ /^Port\s+(.+)$/) { 
            $httpport = $1;
        } elsif ($line =~ /^LogFormat\s+"(.+)"\s+(\w+)$/) {
            $format{$2} = $1;
        }
        unless ($VIRTUAL) {        # check only when $VIRTUAL == 0
            if ($line =~ /^ServerName\s+(.+)$/) { 
                $servername = $1;
            } elsif ($line =~ /^ServerAdmin\s+(.+)$/) { 
                   $serveradmin = $1;
            } elsif ($line =~ /^TransferLog\s+(.+)$/) {
                $transferlog = $1; 
            } elsif ($line =~ /^ErrorLog\s+(.+)$/) {
                $errorlog =  $1;
            } elsif ($line =~ /^AgentLog\s+(.+)$/) {
                $agentlog = $1;
            } elsif ($line =~ /^RefererLog\s+(.+)$/) {
                $refererlog = $1;
            } elsif ($line =~ /^CustomLog\s+(.+)\s+(\w+)$/) {
                my($loc) = $1;
                push(@nickname, $2);
                if ($loc =~ m#\|#) { undef $loc }
                elsif ($loc !~ m#^/#) { $loc = "$serverroot/$loc" }
                $location{$2} = $loc;
            } 
        }
        if (defined($virtualhost)) {
            if ($line =~ m#^<VirtualHost\s+(.+)?>#) {
                if ($1 =~ /$virtualhost/i) {   # if matches, 0
                    $VIRTUAL = 0;
                }
            } elsif ($line =~ m#^</VirtualHost>#) {
                $VIRTUAL = 1;                  # if matches, 0
            }
        } else {
            if ($line =~ m#^<VirtualHost#) {
                $VIRTUAL = 1;
            } elsif ($line =~ m#^</VirtualHost>#) {
                $VIRTUAL = 0;
            }
        }
    }
    close($fh);
    $arg{'serverroot'} = $serverroot || undef;
    $arg{'servername'} = $servername || undef;
    $arg{'httpport'} = $httpport || undef;
    $arg{'serveradmin'} = $serveradmin || undef;
    if ($transferlog) {
        if ($transferlog !~ m#^/#) { 
            $transferlog = "$serverroot/$transferlog" 
        } elsif ($transferlog =~ m#\|#) { 
            undef $transferlog 
        }
    }
    $arg{'transferlog'} = $transferlog;
    if ($errorlog) {
        if ($errorlog !~ m#^/#) { 
            $errorlog = "$serverroot/$errorlog" 
        } elsif ($errorlog =~ m#\|#) { 
            undef $errorlog 
        }
    }
    $arg{'errorlog'} = $errorlog;
    if ($agentlog) {
        if ($agentlog !~ m#^/#) { 
            $agentlog = "$serverroot/$agentlog" 
        } elsif ($agentlog =~ m#\|#) { 
            undef $agentlog 
        }
    }
    $arg{'agentlog'} = $agentlog;
    if ($refererlog) {
        if ($refererlog !~ m#^/#) { 
            $refererlog = "$serverroot/$refererlog" 
        } elsif ($refererlog =~ m#\|#) { 
            undef $refererlog 
        }
    }
    $arg{'refererlog'} = $refererlog;
    $customlog = {
        'nickname' => [ @nickname ],
        'format'   => { %format },
        'location' => { %location },
    };
    $arg{'customlog'} = $customlog;
    return %arg;
}

#######################################################################
# serverroot(); returns $serverroot
=pod

=item *

C<serverroot();>

    print $base->serverroot(), "\n";    

Returns a scalar containing the root of the Web server as specified 
in the F<httpd.conf> file, or C<undef> if the object is not specified.

=cut

sub serverroot {
    my($this) = shift;
    return $this->{'serverroot'} || undef;
}

#######################################################################
# servername(); returns $servername
=pod

=item *

C<servername();>

    print $base->servername(), "\n";

Returns a scalar containing the name of the Web server, or C<undef>  
if server name is not specified. 

=cut

sub servername {
    my($this) = shift;
    return $this->{'servername'} || undef;
}

#######################################################################
# httpport(); returns $port
=pod

=item *

C<httpport();>

    print $base->httpport(), "\n";

Returns a scalar containing the port number used for the httpd, or C<undef> 
if not specified. (By default, httpd uses port 80.)

=cut

sub httpport {
    my($this) = shift;
    return $this->{'httpport'} || undef;
}

#######################################################################
# serveradmin(); returns $serveradmin
=pod

=item *

C<serveradmin();>

    print $base->serveradmin(), "\n";

Returns a scalar containing the name of the server administrator, 
or C<undef> if not specified.

=cut

sub serveradmin {
    my($this) = shift;
    return $this->{'serveradmin'} || undef;
}

#######################################################################
# transferlog(); returns $transferlog
=pod

=item *

C<transferlog();>

     die "$!\n" unless -e $base->transferlog();

Returns a scalar containing the absolute path to the transfer log file, 
or C<undef> if not specified.

=cut

sub transferlog {
    my($this) = shift;
    return $this->{'transferlog'} || undef;
}

#######################################################################
# errorlog(); returns $errorlog
=pod

=item *

C<errorlog();>

     die "$!\n" unless -e $base->errorlog();

Returns a scalar containing the absolute path to the error log file, 
or C<undef> if not specified.

=cut

sub errorlog {
    my($this) = shift;
    return $this->{'errorlog'} || undef;
}

#######################################################################
# agentlog(); returns $agentlog
=pod

=item *

C<agentlog();>

    die "$!\n" unless -e $base->agentlog();

Returns a scalar containing the absolute path to the agent log file, 
or C<undef> if not specified.

=cut

sub agentlog {
    my($this) = shift;
    return $this->{'agentlog'} || undef;
}

#######################################################################
# refererlog(); returns $refererlog
=pod

=item *

C<refererlog();>

    die "$!\n" unless -e $base->refererlog();

Returns a scalar containing the absolute path to the referer log file, 
or C<undef> if not specified.

=cut

sub refererlog {
    my($this) = shift;
    return $this->{'refererlog'} || undef;
}

#######################################################################
# customlog(); returns @customlog
=pod

=item *

C<customlog();>

    @customlog = $base->customlog();

Returns an array containing "nicknames" of the custom logs defined in
the I<$httpd_conf>. 

=cut

sub customlog {
    my($this) = shift;
    return @{ ${$this->{'customlog'}}{'nickname'} };
}

#######################################################################
# customlogDefined($customlog_nickname); returns 1 or 0; private
sub customlogDefined {
    my($this) = shift;
    my($nickname) = shift;
    my($switch) = 0;
    my(@logs) = customlog($this);
    foreach (@logs) { 
        if ($_ eq $nickname) {
            $switch++;
            last;
        }
    }
    return $switch;
}

#######################################################################
# customlogLocation($customlog_nickname); returns path to the log
=pod

=item *

C<customlogLocation($log_nickname);>

    print $base->customlogLocation($name), "\n";

Returns a scalar containing the absolute path to the custom log I<$name>. 
If the custom log I<$name> does not exist, it will return C<undef>. 

This method should be used for debugging purposes only, since you can call
C<getCustomLog()> to parse the logs, making it unnecessary to manually open
the custom log file in your own script. 

=cut

sub customlogLocation {
    my($this) = shift;
    my($nickname) = shift;
    my($root) = serverroot($this);
    if (customlogDefined($this, $nickname)) {
        return ${ ${$this->{'customlog'}}{'location'} }{$nickname};
    } else {
        return undef;
    }
}

#######################################################################
# customlogExists($customlog_nickname); returns 1 or 0
=pod

=item *

C<customlogExists($log_nickname);>

    if ($base->customlogExists($name)) {
        $customlog = $base->getCustomLog($name);
    }

Returns C<1> if the custom log I<$name> (e.g., B<common>, B<combined>)
is defined in the I<$httpd_conf> file B<and> the log file exists, 
or C<0> otherwise. 

You do B<not> have to call this method usually because this is internally 
called by the C<getCustomLog($name)> method. 

=cut

sub customlogExists {
    my($this) = shift;
    my($nickname) = shift;
    my($switch) = 0;
    $switch++ if -e customlogLocation($this, $nickname);
    return $switch;
}

#######################################################################
# customlogFormat($customlog_nickname); returns the format
=pod

=item *

C<customlogFormat($log_nickname);>

    print $base->customlogFormat($name), "\n";
    
Returns a scalar containing the string of the "LogFormat" for the
custom log I<$name>, as specified in I<$httpd_conf>. This method 
is meant to be used internally, as well as for debugging purpose. 

=cut

sub customlogFormat {
    my($this) = shift;
    my($nickname) = shift;
    if (customlogExists($this, $nickname)) {
        return ${ ${$this->{'customlog'}}{'format'} }{$nickname};
    } else {
        return undef;
    }
}

#######################################################################
# getTransferLog(); returns a blessed ref object for TransferLog 
=pod

=item *

C<getTransferLog();>

    $transferlog = $base->getTransferLog();

Returns an object through which to access the information
parsed from the F<TransferLog> file. See the L<"LOG OBJECT METHODS"> below 
for methods to access the log information.  

=cut

sub getTransferLog {
    my($this) = shift;
    my($METHOD) = "Apache::ParseLog::getTransferLog";
    my($logfile) = $this->{'transferlog'};
    croak "$METHOD: $logfile does not exist. Exiting " unless -e $logfile;
    my($FORMAT) = '(\\S+)\\s(\\S+)\\s(\\S+)\\s\\[(\\d{2}/\\w+/\\d{4}\\:\\d{2}\\:\\d{2}\\:\\d{2}\\s+.+?)\\]\\s\\"(\\w+\\s\\S+\\s\\w+\\/\\d+\\.\\d+)\\"\\s(\\d+)\\s(\\d+|-)';
    my(@elements) = qw/HOST LOGIN USER DATETIME REQUEST LSTATUS BYTE/;
    return scanLog($this, $logfile, $FORMAT, @elements);
}

#######################################################################
# getRefererLog(); returns a blessed ref object for RefererLog
=pod

=item *

C<getRefererLog();>

    $refererlog = $base->getRefererLog();

Returns an object through which to access the information 
parsed from the F<RefererLog> file. See the L<"LOG OBJECT METHODS"> below
for methods to access the log information.  

=cut

sub getRefererLog {
    my($this) = shift;
    my($METHOD) = "Apache::ParseLog::getRefererLog";
    my($logfile) = $this->{'refererlog'};
    croak "$METHOD: $logfile does not exist. Exiting " unless -e $logfile;
    my($FORMAT) = '(\\S+)\\s\\-\\>\\s(\\S+)';
    my(@elements) = qw/REFERER URL/;
    return scanLog($this, $logfile, $FORMAT, @elements);
}

#######################################################################
# getAgentLog(); returns a blessed ref object for AgentLog
=pod

=item *

C<getAgentLog();>

    $agentlog = $base->getAgentLog();

This method returns an object through which to access the information 
parsed from the F<AgentLog> file. See the L<"LOG OBJECT METHODS"> below
for methods to access the log information.  

=cut

sub getAgentLog {
    my($this) = shift;
    my($METHOD) = "Apache::ParseLog::getAgentLog";
    my($logfile) = $this->{'agentlog'};
    croak "$METHOD: $logfile does not exist. Exiting " unless -e $logfile;
    my($FORMAT) = '(.+)';
    my(@elements) = qw/UAGENT/;
    return scanLog($this, $logfile, $FORMAT, @elements);
}

#######################################################################
# getErrorLog(); returns a blessed ref object for ErrorLog
=pod

=item *

C<getErrorLog();>

    $errorlog = $base->getErrorLog();

This method returns an object through which to access the information
parsed from the F<ErrorLog> file. See the L<"LOG OBJECT METHODS"> below
for methods to access the log information.  

=cut

sub getErrorLog {
    my($this) = shift;
    my($METHOD) = "Apache::ParseLog::getErrorLog";
    my($logfile) = $this->{'errorlog'};
    croak "$METHOD: $logfile does not exist. Exiting " unless -e $logfile;
    my($FORMAT) = '\\[(?:\\S+)\\s+(\\S+)\\s+(\\d+)\\s+(\\S+)\\s+(\\d{4})\\]\\s+(\\[(\\w+)\\])?';
    my($regex) = $FORMAT;
    my($line, %count,  %allbydate, %allbytime, %allbydatetime, %allmessage, %errorbydate, %errorbytime, %errorbydatetime, %errormessage, %noticebydate, %noticebytime, %noticebydatetime, %noticemessage, %warnbydate, %warnbytime, %warnbydatetime, %warnmessage);
    my($fh) = openFile($logfile);
    while (defined($line = <$fh>)) {
        chomp($line);
        if ($line =~ m/^\[/) {
            $line =~ m#$regex#;
            my($m) = $M2N{$1};
            my($d) = $2;
            my($time) = $3;
            my($y) = $4;
            my($keyword) = $6;
            $d = "0" . $d if $d =~ m/^\d$/;
            my($date) = "$m/$d/$y";
            $time =~ s/:.+$//;
            my($datetime) = "$date-$time";
            $line =~ s/^.+\]\s+//;
            if ($keyword eq "error") {
                $count{'error'}++;
                $errorbydate{$date}++;
                $errorbytime{$time}++;
                $errorbydatetime{$datetime}++;
                $errormessage{$line}++;
            } elsif ($keyword eq "notice") {
                $count{'notice'}++;
                $noticebydate{$date}++;
                $noticebytime{$time}++;
                $noticebydatetime{$datetime}++;
                $noticemessage{$line}++;
            } elsif ($keyword eq "warn") {
                $count{'warn'}++;
                $warnbydate{$date}++;
                $warnbytime{$time}++;
                $warnbydatetime{$datetime}++;
                $warnmessage{$line}++;
            }
            $allbydate{$date}++;
            $allbytime{$time}++;
            $allbydatetime{$datetime}++;
            $allmessage{$line}++ if $line;
            $count{'dated'}++;
        } else {
            $count{'nodate'}++;
            $allmessage{$line}++ if $line;
        }
        $count{'Total'}++;
    }
    close($fh);
    my(@methods) = qw/count allbydate allbytime allbydatetime allmessage errorbydate errorbytime errorbydatetime errormessage noticebydate noticebytime noticebydatetime noticemessage warnbydate warnbytime warnbydatetime warnmessage/;
    return bless {
        'allbydate'             => { %allbydate },
        'allbytime'             => { %allbytime },
        'allbydatetime'         => { %allbydatetime },
        'allmessage'            => { %allmessage },
        'errorbydate'           => { %errorbydate },
        'errorbytime'           => { %errorbytime },
        'errorbydatetime'       => { %errorbydatetime },
        'errormessage'          => { %errormessage },
        'noticebydate'          => { %noticebydate },
        'noticebytime'          => { %noticebytime },
        'noticebydatetime'      => { %noticebydatetime },
        'noticemessage'         => { %noticemessage },
        'warnbydate'            => { %warnbydate },
        'warnbytime'            => { %warnbytime },
        'warnbydatetime'        => { %warnbydatetime },
        'warnmessage'           => { %warnmessage },
        'count'                 => { %count },
        'methods'               => [ @methods ],
    };
}

#######################################################################
# getCustomLog($nickname); returns $customlog object
=pod

=item *

C<getCustomLog($log_nickname);>

    $customlog = $base->getCustomLog($name);

This method returns an object through which to access the information
parsed from the F<CustomLog> file I<$name>. See the L<"LOG OBJECT METHODS"> 
below for methods for methods to access the log information.  

=back

=cut

sub getCustomLog {
    my($this) = shift;
    my($nickname) = shift;
    my($METHOD) = "Apache::ParseLog::getCustomLog";
    croak "$METHOD: $nickname does not exist, Exiting " unless customlogExists($this, $nickname);
    my($logfile) = customlogLocation($this, $nickname);
    croak "$METHOD: $logfile does not exist. Exiting " unless -e $logfile;
    # Variables preparation
    my($host_rx) = '(\\S+)';            # %h (host, visitor IP/hostname)
    my($log_rx) = '(\\S+)';             # %l (login, login name)
    my($user_rx) = '(\\S+)';            # %u (user, user name)
    my($time_rx) = '\\[(\\d{2}/\\w+/\\d{4}\\:\\d{2}\\:\\d{2}\\:\\d{2}\\s+.+?)\\]';                                     # %t (datetime, date/time)
    my($req_rx) = '(\\w+\\s\\S+\\s\\w+\\/\\d+\\.\\d+)';
                                        # %r (request, method, file, proto)
    my($ost_rx) = '(\\d+)';             # %s (ostatus, original status)
    my($lst_rx) = '(\\d+)';             # %>s (lstatus, last status)
    my($byte_rx) = '(\\d+|-)';          # %b (byte, bytes)
    my($file_rx) = '(\\S+)';            # %f (filename, filename)
    my($addr_rx) = '(\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3})'; 
                                        # %a (addr, IP)
    my($port_rx) = '(\\d+)';            # %p (port, port)
    my($proc_rx) = '(\\d+)';            # %p (proc, proc ID)
    my($sec_rx) = '(\\d+)';             # %T (sec, time in sec)
    my($url_rx) = '(\\S+)';             # %U (url, URL)
    my($hname_rx) = '(\\S+)';           # %v (hostname, hostname)
    my($referer_rx) = '(\\S+)';         # %{Referer}i (referer, referer)
    my($uagent_rx) = '(.+?)';           # %{User-agent}i (uagent, browser)
    my($space) = '\\s';                 # white space
    my($FORMAT) = customlogFormat($this, $nickname);
    my($temp) = $FORMAT . " "; # add the last space for the $temp regex below
    my(@regex, @elements);
    # Create the pre-compiled regex sting dynamically here
    while ((length($temp)) > 0) {
        $temp =~ s/^(\\?\")?(.+?)(\\?\")?\s+//;
        my($match) = $2;
        if ($2 eq '%h') { 
            push(@regex, $host_rx);    push(@elements, 'HOST');
        } elsif ($2 eq '%l') { 
            push(@regex, $log_rx);     push(@elements, 'LOGIN');
        } elsif ($2 eq '%u') { 
            push(@regex, $user_rx);    push(@elements, 'USER');
        } elsif ($2 eq '%t') { 
            push(@regex, $time_rx);    push(@elements, 'DATETIME');
        } elsif ($2 eq '%r') { 
            push(@regex, $req_rx);     push(@elements, 'REQUEST');
        } elsif ($2 eq '%s') { 
            push(@regex, $ost_rx);     push(@elements, 'OSTATUS');
        } elsif ($2 eq '%>s') { 
            push(@regex, $lst_rx);     push(@elements, 'LSTATUS');
        } elsif ($2 eq '%b') { 
            push(@regex, $byte_rx);    push(@elements, 'BYTE');
        } elsif ($2 eq '%f') { 
            push(@regex, $file_rx);    push(@elements, 'FILENAME');
        } elsif ($2 eq '%a') { 
            push(@regex, $addr_rx);    push(@elements, 'ADDR'); 
        } elsif ($2 eq '%p') { 
            push(@regex, $port_rx);    push(@elements, 'PORT');
        } elsif ($2 eq '%P') { 
            push(@regex, $proc_rx);    push(@elements, 'PROC');
        } elsif ($2 eq '%T') { 
            push(@regex, $sec_rx);     push(@elements, 'SEC');
        } elsif ($2 eq '%U') { 
            push(@regex, $url_rx);     push(@elements, 'URL');
        } elsif ($2 eq '%v') { 
            push(@regex, $hname_rx);   push(@elements, 'HOSTNAME');
        } elsif ($2 =~ /Referer/i) { 
            push(@regex, $referer_rx); push(@elements, 'REFERER');
        } elsif ($2 =~ /User-agent/i) { 
            push(@regex, $uagent_rx);  push(@elements, 'UAGENT'); 
        } else { 
            my($unknown) = $2; 
            $unknown =~ s|(\W)|\\$1|g;
            push(@regex, $unknown);
        }
        $FORMAT =~ s/$match/$regex[$#regex]/;
    }
    $FORMAT =~ s/\s/$space/g;
    # Parse the log finally
    return scanLog($this, $logfile, $FORMAT, @elements);
}

#######################################################################
# scanLog($path_to_logfile, $regex_format, @elments); 
# returns a blessed object; private
sub scanLog {
    my($this) = shift;    # package
    my($logfile) = shift; # path to the log
    my($FORMAT) = shift;   # regex
    my(@elements) = @_;   # array containing what's in the regex
    # create an array containing the uc name of placeholders
    my($hostswitch) = 1;    # off with host defined
    my($visitorswitch) = 0; # on with host defined
    my($visitordone) = 0;   # on with visitor added to @methods
    my($dtswitch) = 0;      # on with datetime defined
    my($dtbyteswitch) = 0;  # on with datetime or byte defined
    my($fileswitch) = 0;    # on with filename or request or url defined
    my(@METHODS) = map { 
        if ((m"^HOST") && ($hostswitch)) {
            $hostswitch--;
            $visitorswitch++;
            if (($dtswitch) && (! $visitordone)) {
                ($_, "TOPDOMAIN", "SECDOMAIN", "VISITORBYDATE", "VISITORBYTTME", "VISITORBYDATETIME")
            } else {
                ($_, "TOPDOMAIN", "SECDOMAIN")
            }
        } elsif (((m"DATETIME") || (m"BYTE")) && (! $dtbyteswitch)) {
            $dtbyteswitch++;
            if (m"DATETIME") {
                $dtswitch++; 
                if ($visitorswitch) {
                    $visitorswitch = 0;
                    $visitordone++;
                    ("VISITORBYDATE", "VISITORBYTIME", "VISITORBYDATETIME", "HITBYDATE", "HITBYTIME", "HITBYDATETIME") 
                } else {
                    ("HITBYDATE", "HITBYTIME", "HITBYDATETIME")
                }
            } else {
                $_
            }
        } elsif (((m"DATETIME") || (m"BYTE")) && ($dtbyteswitch)) {
            if (m"DATETIME") { 
                $dtswitch++;
                if ($visitorswitch) {
                    $visitorswitch = 0;
                    $visitordone++;
                    ("VISITORBYDATE", "VISITORBYTIME", "VISITORBYDATETIME", "HITBYDATE", "HITBYTIME", "HITBYDATETIME", "BYTEBYDATE", "BYTEBYTIME", "BYTEBYDATETIME") 
                } else {
                    ("HITBYDATE", "HITBYTIME", "HITBYDATETIME", "BYTEBYDATE", "BYTEBYTIME", "BYTEBYDATETIME") 
                }
            } else { 
                ($_, "BYTEBYDATE", "BYTEBYTIME", "BYTEBYDATETIME") 
            }
        } elsif (m"REQUEST") {
            $fileswitch++;
            ("METHOD", "FILE", "QUERYSTRING", "PROTO")
        } elsif ((m"FILENAME") || (m"URL")) {
            $fileswitch++;
            $_
        } elsif ((m"SEC") && ($fileswitch)) {
            $_
        } elsif (m"UAGENT") {
            ($_, "UAVERSION", "BROWSER", "PLATFORM", "BROWSERBYOS")
        } elsif (m"REFERER") {
            ($_, "REFERERDETAIL")
        } else { 
            $_ 
        }
    } @elements;
    push(@METHODS, "HIT");  # the hit => { %hit } is always there
    @METHODS = map { lc } @METHODS;
    ### reports placeholders
    my(%host);               # hosts (visitors)
    my(%topdomain);          # top domains
    my(%secdomain);          # secondary domains
    my(%login);              # logins
    my(%user);               # users
    my(%visitorbydate);      # unique visitors (hosts) by date
    my(%visitorbytime);      # unique visitors by time
    my(%visitorbydatetime);  # unique visitors by date/time
    my(%hitbydate);          # hits by date
    my(%hitbytime);          # hits by time
    my(%hitbydatetime);      # hits by date/time
    my(%method);             # methods (get, post, etc.)
    my(%file);               # files
    my(%querystring);        # Query String
    my(%proto);              # protos (HTTP/1.0, etc.)
    my(%ostatus);            # original status (..)
    my(%lstatus);            # last status (use with %STATUS_BY_CODE)
    my(%byte);               # Bytes transferred (* containts one key "total")
    my(%bytebydate);         # bytes by date
    my(%bytebytime);         # bytes by time
    my(%bytebydatetime);     # bytes by date/time
    my(%filename);           # filenames (= files)
    my(%addr);               # IPs (=~ hosts)
    my(%port);               # ports
    my(%proc);               # procs
    my(%sec);                # seconds (time in sec)
    my(%url);                # URLs (=~ files)
    my(%hostname);           # hostnames (=~ hosts)
    my(%referer);            # referer (site only)
    my(%refererdetail);      # referer (detail)
    my(%uagent);             # agents
    my(%uaversion);          # uagent w/ versions (Mozilla/4.04, Slurp/2.0)
    my(%browser);            # browsers w/ version
    my(%platform);           # platforms only
    my(%browserbyos);        # browsers w/ platforms
    my(%hit);                # Total number of hits (lines)
    ### Routine
    if ((scalar(@elements) == 1) && ($elements[0] eq "UAGENT")) { 
        $FORMAT =~ s#\?## 
    }
    my($regex) = $FORMAT;
    my($line);
    my($fh) = openFile($logfile);
    while (defined($line = <$fh>)) { 
        chomp($line);
        $line =~ m#$regex#;
        # Scan each match
        for ($i = 0; $i < scalar(@elements); $i++) {
            my($mi) = $i + 1;          # index for match; $1, $2,...
            ${$elements[$i]} = ${$mi}; # assign the back ref
        }
        my($date, $time, $method, $file, $proto);
        ### create reports ###
        { # HOST RELATED BLOCK
            # HOST
            $host{$HOST}++ if $HOST;
            # HOSTNAME
            $hostname{$HOSTNAME}++ if $HOSTNAME;
            my($domain) = ($HOST ? $HOST : $HOSTNAME);
            # (TOP|SEC)DOMAIN
            if ($domain) {
                if ($domain !~ /^\d{1,3}(?:\.\d{1,3}){3}$/) {
                    if ($domain =~ m/\.([A-Za-z0-9\-]+\.)(\w+)$/) {
                        my($secdomain) = $1;
                        my($topdomain) = $2;
                        $topdomain{$topdomain}++;
                        $secdomain = $secdomain . $topdomain;
                        $secdomain{$secdomain}++;
                    } else {
                        $topdomain{$domain}++;
                        $secdomain{$domain}++;
                    }
                } else {
                    $topdomain{'unknown'}++;
                    $secdomain{'unknown'}++;
                }
            }
        }
        # LOGIN
        $login{$LOGIN}++ if $LOGIN;
        # USER
        $user{$USER}++ if $USER;
        # DATETIME
        if ($DATETIME) {
            $DATETIME =~ m#^(\d+)/(\w+)/(\d+)\:(\d{2})\:\d{2}\:\d{2}#;
            my($d) = ($1 =~ /^\d$/ ? '0' . $1 : $1);
            my($m) = $M2N{$2};
            my($y) = $3;
            my($t) = $4;
            my($date) = "$m/$d/$y";
            $hitbydate{$date}++;
            $hitbytime{$t}++;
            my($dt) = "$date-$t";
            $hitbydatetime{$dt}++;
            if (($BYTE) && ($BYTE =~ m#^\d+$#)) {
                $bytebydate{$date} += $BYTE;
                $bytebytime{$t} += $BYTE;
                $bytebydatetime{$dt} += $BYTE;
            }
            my($visitor);
            if ($HOST) { $visitor = $HOST } 
            elsif ($HOSTNAME) { $visitor = $HOSTNAME } 
            elsif ($ADDR) { $visitor = $HOSTNAME }
            ${$date}{$visitor}++;
            ${$t}{$visitor}++;
            ${$dt}{$visitor}++;
        }
        # STATUS
        if ($OSTATUS) {
            my($key) = "$OSTATUS $STATUS_BY_CODE{$OSTATUS}";
            $ostatus{$key}++;
        }
        if ($LSTATUS) {
            my($key) = "$LSTATUS $STATUS_BY_CODE{$LSTATUS}";
            $lstatus{$key}++;
        }
        # FILENAME
        $filename{$FILENAME}++ if $FILENAME;
        # ADDR
        $addr{$ADDR}++ if $ADDR;
        # PORT
        $port{$PORT}++ if $PORT;
        # PROC
        $proc{$PROC}++ if $PROC;
        { # BEGIN FILE RELATED BLOCK
            my($FILE);
            # REQUEST
            if ($REQUEST) {
                $REQUEST =~ m#^(\w+)\s(\S+)\s(\S+)$#;
                my($method) = $1;
                my($file) = $2;
                my($proto) = $3;
                $method{$method}++;
                if ($file =~ m#\?(.+)$#) {
                    $querystring{$1}++;    # query string
                }
                $file =~ s#\?.+$##;        # trim query_string
                $file =~ s#/\./#/#g;         # same-dir duplicates
                $file =~ s#/\s+?/\.\./#/#g;  # same-upper-dir duplicates
                $file{$file}++;
                $proto{$proto}++;
                $FILE = $file;   
            }
            # URL
            if ($URL) {
                $url{$URL}++;
                $FILE = $URL;
            }
            # FILE
            $FILE = $FILENAME unless $FILE;
            # SEC
            SEC: if ($SEC) {
                last SEC unless $FILE;
                if (exists($sec{$FILE})) {
                    $sec{$FILE} = "$SEC" if $SEC > $sec{$FILE};
                } else {
                    $sec{$FILE} = "$SEC";
                }
            }
            # BYTE
            if (($BYTE) && ($BYTE =~ m#^\d+$#)) {
                $byte{'Total'} += $BYTE;
                last unless $FILE;
                $FILE =~ m#\.(\w+)$#;
                if ($1) {
                    $byte{$1} += $BYTE;
                    $hit{$1}++;
                } else {
                    $byte{'OtherTypes'} += $BYTE;
                    $hit{'OtherTypes'}++;
                }
            }
            # REFERER
            if ($REFERER) {
                my($refered);
                if ($URL) { $refered = $URL }
                elsif ($FILE) { $refered = $FILE }
                elsif ($FILENAME) { $refered = $FILENAME }
                my($ref) = (($refered) ? "$REFERER -> $refered" : $REFERER);
                $refererdetail{$ref}++;
                if ($REFERER =~ m#http://(\S+?)[/?]#) { $referer{$1}++ }
                elsif ($REFERER =~ m#^-$#) { $referer{'bookmark'}++ }
                else { $referer{'unknown'}++ }
            }
        } # END FILE RELATED BLOCK 
        # UAGENT
        if ($UAGENT) {
            $uagent{$UAGENT}++;
            $UAGENT =~ m#^(\S+)\s*(.+)?$#;
            my($parser) = $1;
            my($rest) = $2;
            $uaversion{$parser}++ if $parser;
            my($browser);
            if (($UAGENT =~ m/^Mozilla/)
            && (($rest =~ m/(Webtv.+?)[;)]/) 
            || ($rest =~ m/(AOL.+?)[;)]/) 
            || ($rest =~ m/(MSN.+?)[;)]/) 
            || ($rest =~ m/(MSIE.+?)[;)]/))) {
                $browser = $1;
                $browser{$1}++;
            } elsif (($UAGENT =~ m/Mozilla/) && ($rest =~ m/compatible\;\s+(.+?)[;)]/)) {
                $browser = $1;
                $browser{$1}++;
            } else {
                $browser = $parser;
                $browser{$browser}++;
            }
            my($plat);
            if ($rest =~ m/(Win.+?)[;)]/) {
                $plat = $1;
                $platform{$1}++;
            } elsif ($rest =~ m/(Mac.+?)[;)]/) {
                $plat = $1;
                $platform{$1}++;
            } elsif ($rest =~ m/X11\;\s+.+?\;\s+(.+?)[;)]/) {
                $plat = $1;
                $platform{$1}++;
            } else {
                $plat = $rest;
                $plat =~ s#(?:\(|\)|\;)##g;
                $platform{$plat}++;
            }
            my($bandp) = "$browser ($plat)";
            $browserbyos{$bandp}++;
        }
        # hit
        $hit{'Total'}++;
    }
    close($fh);
    # Construct %visitorxxx hashes
    %visitorbydate = map { $_ => scalar(keys %{$_}), } keys %hitbydate;
    %visitorbytime = map { $_ => scalar(keys %{$_}), } keys %hitbytime;
    %visitorbydatetime = map { $_ => scalar(keys %{$_}), } keys %hitbydatetime;
    return bless { 
        'host'               => { %host },
        'topdomain'          => { %topdomain },
        'secdomain'          => { %secdomain },
        'login'              => { %login },
        'user'               => { %user },
        'hitbydate'          => { %hitbydate },
        'hitbytime'          => { %hitbytime },
        'hitbydatetime'      => { %hitbydatetime },
        'visitorbydate'      => { %visitorbydate },
        'visitorbytime'      => { %visitorbytime },
        'visitorbydatetime'  => { %visitorbydatetime },
        'method'             => { %method },
        'file'               => { %file },
        'querystring'        => { %querystring },
        'proto'              => { %proto },
        'ostatus'            => { %ostatus },
        'lstatus'            => { %lstatus },
        'byte'               => { %byte },
        'bytebydate'         => { %bytebydate },
        'bytebytime'         => { %bytebytime },
        'bytebydatetime'     => { %bytebydatetime },
        'filename'           => { %filename },
        'addr'               => { %addr },
        'port'               => { %port },
        'proc'               => { %proc },
        'sec'                => { %sec },
        'url'                => { %url },
        'hostname'           => { %hostname },
        'referer'            => { %referer },
        'refererdetail'      => { %refererdetail },
        'uagent'             => { %uagent },
        'uaversion'          => { %uaversion },
        'browser'            => { %browser },
        'platform'           => { %platform },
        'browserbyos'        => { %browserbyos },
        'hit'                => { %hit },
        'methods'            => [ @METHODS ],
    };
}

#######################################################################
# LOG OBJECT METHODS
#######################################################################
=pod

=head1 LOG OBJECT METHODS

This section describes the methods available for the log object created
by any of the following base object methods: B<getTransferLog()>, 
B<getErrorLog()>, B<getRereferLog()>, B<getAgentLog()>, and 
B<getCustomLog($log_nickname)>.

This section is devided into six subsections, each of which describes 
the available methods for a certain log object. 

Note that all the methods for F<TransferLog>, F<RefererLog>, and F<AgentLog>
can be used for the object created with C<getCustomLog($name)>.

=cut

#######################################################################
# TRANSFERLOG METHODS
=pod

=head2 TransferLog/CustomLog Methods

The following methods are available for the F<TransferLog> object
(created by C<getTransferLog()> method), as well as the F<CustomLog> 
object that logs appropriate arguments to the corresponding F<LogFormat>. 

=over 4

=cut

######################################################################
# hit(); returns %hit
=pod

=item *

C<hit();>

    %hit = $logobject->hit();

Returns a hash containing at least a key 'Total' with the total 
hit count as its value, and the file extensions (i.e., html, 
jpg, gif, cgi, pl, etc.) as keys with the hit count for each key as 
values. 

=cut

sub hit {
    my($this) = shift;
    return %{($this->{'hit'} || undef)};
}

#######################################################################
# host(); returns %host
=pod

=item *

C<host();>

    %host = $logobject->host();

Returns a hash containing host names (or IPs if names are unresolved) 
of the visitors as keys, and the hit count for each key as values. 

=cut

sub host {
    my($this) = shift;
    my(%host) = %{($this->{'host'} || undef)};
    return %host;
}

#######################################################################
# topdomain(); returns %topdomain
=pod

=item *

C<topdomain();>

    %topdomain = $logobject->topdomain();

Returns a hash containing topdomain names (com, net, etc.) of the
visitors as keys, and the hit count for each key as values. 

Note that if the hostname is unresolved and remains as an IP address, 
the visitor will not be counted toward the (and the next C<secdomain()>)
returned value of this method. 

=cut

sub topdomain {
    my($this) = shift;
    return %{($this->{'topdomain'} || undef)};
}

######################################################################
# secdomain(); returns %secdomain
=pod

=item *

C<secdomain();>

    %secdomain = $logobject->secdomain();

Returns a hash containing secondary domain names (xxx.com, yyy.net, 
etc.) as keys, and the hit count for each key as values. 

For the unresolved IPs, the same rule applies as the above C<topdomain()>
method. 

=cut

sub secdomain {
    my($this) = shift;
    return %{($this->{'secdomain'} || undef)};
}

######################################################################
# login(); returns %login
=pod

=item *

C<login();>

    %login = $logobject->login();

Returns a hash containing login names (authenticated user logins)
of the visitors as keys, and the hit count for each key as values. 

Log entries for non-authenticated files have a character "-" as the 
login name. 

=cut

sub login {
    my($this) = shift;
    return %{($this->{'login'} || undef)};
}

######################################################################
# user(); returns %user
=pod

=item *

C<user();>

    %user = $logobject->user();

Returns a hash containing user names (for access-controlled directories, 
refer to the access.conf file of the Apache server) of the visitors as 
keys, and the hit count for each key as values. 

Non-access-controlled log entries have a character "-" as the user name. 

=cut

sub user {
    my($this) = shift;
    return %{($this->{'user'} || undef)};
}

######################################################################
# hitbydate(); returns %hitbydate
=pod

=item *

C<hitbydate();>

    %hitbydate = $logobject->hitbydate();

Returns a hash containing date (mm/dd/yyyy) when visitors visited the
particular file (html, jpg, etc.) as keys, and the hit count 
for each key as values. 

=cut

sub hitbydate {
    my($this) = shift;
    return %{($this->{'hitbydate'} || undef)};
}

######################################################################
# hitbytime(); returns %hitbytime
=pod

=item *

C<hitbytime();>

    %hitbytime = $logobject->hitbytime();

Returns a hash containing time (00-23) each file was visited as keys, 
and the hit count for each key as values. 

=cut

sub hitbytime {
    my($this) = shift;
    return %{($this->{'hitbytime'} || undef)};
}

######################################################################
# hitbydatetime(); returns %hitbydatetime
=pod

=item *

C<hitbydatetime();>

    %hitbydatetime = $logobject->hitbydatetime();

Returns a hash containing date/time (mm/dd/yyyy-hh)
as keys, and the hit count for each key as values. 

=cut

sub hitbydatetime {
    my($this) = shift;
    return %{($this->{'hitbydatetime'} || undef)};
}

######################################################################
# visitorbydate(); returns %visitorbydate
=pod

=item *

C<visitorbydate();>

    %visitorbydate = $logobject->visitorbydate();

Returns a hash containing date (mm/dd/yyyy) as keys, and the unique 
visitor count for each key as values. 

=cut

sub visitorbydate {
    my($this) = shift;
    return %{($this->{'visitorbydate'} || undef)};
}

######################################################################
# visitorbytime(); returns %visitorbytime
=pod

=item *

C<visitorbytime();>

    %visitorbytime = $logobject->visitorbytime();

Returns a hash containing time (00-23) as keys, and the unique visitor 
count for each key as values. 

=cut

sub visitorbytime {
    my($this) = shift;
    return %{($this->{'visitorbytime'} || undef)};
}

######################################################################
# visitorbydatetime(); returns %visitorbydatetime
=pod

=item *

C<visitorbydatetime();>

    %visitorbydatetime = $logobject->visitorbydatetime();

Returns a hash containing date/time (mm/dd/yyyy-hh)
as keys, and the unique visitor count for each key as values. 

=cut

sub visitorbydatetime {
    my($this) = shift;
    return %{($this->{'visitorbydatetime'} || undef)};
}

######################################################################
# method(); returns %method
=pod

=item *

C<method();>

    %method = $logobject->method();

Returns a hash containing HTTP method (GET, POST, PUT, etc.)
as keys, and the hit count for each key as values. 

=cut

sub method {
    my($this) = shift;
    return %{($this->{'method'} || undef)};
}

######################################################################
# file(); returns %file
=pod

=item *

C<file();>

    %file = $logobject->file();

Returns a hash containing the file names relative to the F<DocumentRoot>
of the server as keys, and the hit count for each key as values. 

=cut

sub file {
    my($this) = shift;
    return %{($this->{'file'} || undef)};
}

######################################################################
# querystring(); returns %querystring
=pod

=item *

C<querystring();>

    %querystring = $logobject->querystring();

Returns a hash containing the query string 
as keys, and the hit count for each key as values. 

=cut

sub querystring {
    my($this) = shift;
    return %{($this->{'querystring'} || undef)};
}

######################################################################
# proto(); returns %proto
=pod

=item *

C<proto();>

    %proto = $logobject->proto();

Returns a hash containing the protocols used (HTTP/1.0, HTTP/1.1, etc.)
as keys, and the hit count for each key as values. 

=cut

sub proto {
    my($this) = shift;
    return %{($this->{'proto'} || undef)};
}

######################################################################
# lstatus(); returns %lstatus
=pod

=item *

C<lstatus();>

    %lstatus = $logobject->lstatus();

Returns a hash containing HTTP codes and messages (e.g. "404 Not Found")
for the last status (i.e., when the httpd finishes processing that 
request) as keys, and the hit count for each key as values. 

=cut

sub lstatus {
    my($this) = shift;
    return %{($this->{'lstatus'} || undef)};
}

######################################################################
# byte(); returns %byte
=pod

=item *

C<byte();>

    %byte = $logobject->byte();

Returns a hash containing at least a key 'Total' with the total 
transferred bytes as its value, and the file extensions (i.e., html, 
jpg, gif, cgi, pl, etc.) as keys, and the transferred bytes for each 
key as values. 

=cut

sub byte {
    my($this) = shift;
    return %{($this->{'byte'} || undef)};
}

######################################################################
# bytebydate(); returns %bytebydate
=pod

=item *

C<bytebydate();>

    %bytebydate = $logobject->bytebydate();

Returns a hash containing date (mm/dd/yyyy) as keys, and the hit 
count for each key as values. 

=cut

sub bytebydate {
    my($this) = shift;
    return %{($this->{'bytebydate'} || undef)};
}

######################################################################
# bytebytime(); returns %bytebytime
=pod

=item *

C<bytebytime();>

    %bytebytime = $logobject->bytebytime();

Returns a hash containing time (00-23) as keys, and the hit count 
for each key as values. 

=cut

sub bytebytime {
    my($this) = shift;
    return %{($this->{'bytebytime'} || undef)};
}

######################################################################
# bytebydatetime(); returns %bytebydatetime
=pod

=item *

C<bytebydatetime();>

    %bytebydatetime = $logobject->bytebydatetime();

Returns a hash containing date/time (mm/dd/yyyy-hh) as keys, and the 
hit count for each key as values. 

=back

=cut

sub bytebydatetime {
    my($this) = shift;
    return %{($this->{'bytebydatetime'} || undef)};
}

#######################################################################
# ERRORLOG METHODS
=pod

=head2 ErrorLog Methods

Until the Apache version 1.2.x, each error log entry was just an error, 
meaning that there was no distinction between "real" errors (e.g., File 
Not Found, malfunctioning CGI, etc.) and non-significant errors (e.g., 
kill -1 the httpd processes, etc.). 

Starting from the version 1.3.x, the Apache httpd logs the "type" of
each error log entry, namely "error", "notice" and "warn". 

If you use Apache 1.2.x, the C<errorbyxxx()>, C<noticebyxxx()>, 
and C<warnbyxxx()> should not be used, because those methods for 
that are for 1.3.x only will merely return an empty hash. 
The C<allbyxxx()> methods will return desired results. 

The following methods are available for the F<ErrorLog> object
(created by C<getErrorLog()> method).

=over 4

=cut

#######################################################################
# total(); returns $total;
=pod

=item *

C<count();>

    %errors = $errorlogobject->count();

Returns a hash containing count for each type of messages
logged in the error log file. 

The keys and values are: 'Total' (total number of errors), 'error' 
(total number of errors of type "error"), 'notice' total number of 
errors of type "notice"),  'warn' (total number of errors of type 
"warn"), 'dated' (total number of error entries with date logged), 
and 'nodate' (total number of error entires with no date logged). 
So:

    print "Total Errors: ", $errors{'Total'}, "\n";
    print "Total 1.3.x Errors: ", $errors{'error'}, "\n";
    print "Total 1.3.x Notices: ", $errors{'notice'}, "\n";
    print "Total 1.3.x Warns: ", $errors{'warn'}, "\n";
    print "Total Errors with date: ", $errors{'dated'}, "\n";
    print "Total Errors with no date: ", $errors{'nodate'}, "\n";

Note that with the F<ErrorLog> file generated by Apache version 
before 1.3.x, the value for 'error', 'notice', and 'warn' will
be zero. 

=cut

sub count {
    my($this) = shift;
    return %{($this->{'count'} || undef)};
}

#######################################################################
# allbydate(); returns %allbydate;
=pod

=item *

C<allbydate();>

    %allbydate = $errorlogobject->allbydate();

Returns a hash containing date (mm/dd/yyyy) when the error was logged 
as keys, and the number of error occurrances as values. 

=cut

sub allbydate {
    my($this) = shift;
    return %{($this->{'allbydate'} || undef)};
}

#######################################################################
# allbytime(); returns %allbytime;
=pod

=item *

C<allbytime();>

    %allbytime = $errorlogobject->allbytime();

Returns a hash containing time (00-23) as keys and the number
of error occurrances as values. 

=cut

sub allbytime {
    my($this) = shift;
    return %{($this->{'allbytime'} || undef)};
}

#######################################################################
# allbydatetime(); returns %allbydatetime;
=pod

=item *

C<allbydatetime();>

    %allbydatetime = $errorlogobject->allbydatetime();

Returns a hash containing date/time (mm/dd/yyyy-hh) as keys and the 
number of error occurrances as values. 

=cut

sub allbydatetime {
    my($this) = shift;
    return %{($this->{'allbydatetime'} || undef)};
}

#######################################################################
# allmessage(); returns %allmessage;
=pod

=item *

C<allmessage();>

    %allmessage = $errorlogobject->allmessage();

Returns a hash containing error messages as keys and the number of
occurrances as values. 

=cut

sub allmessage {
    my($this) = shift;
    return %{($this->{'allmessage'} || undef)};
}

#######################################################################
# errorbydate(); returns %errorbydate;
=pod

=item *

C<errorbydate();> 

    %errorbydate = $errorlogobject->errorbydate();

Returns a hash containing date (mm/dd/yyyy) as keys and the number
of error occurrances as values. For the Apache 1.3.x log only.

=cut

sub errorbydate {
    my($this) = shift;
    return %{($this->{'errorbydate'} || undef)};
}

#######################################################################
# errorbytime(); returns %errorbytime;
=pod

=item *

C<errorbytime();>

    %errorbytime = $errorlogobject->errorbytime();

Returns a hash containing time (00-23) as keys and the number
of error occurrances as values. For the Apache 1.3.x log only. 

=cut

sub errorbytime {
    my($this) = shift;
    return %{($this->{'errorbytime'} || undef)};
}

#######################################################################
# errorbydatetime(); returns %errorbydatetime;
=pod

=item *

C<errorbydatetime();> 

    %errorbydatetime = $errorlogobject->errorbydatetime();

Returns a hash containing date/time (mm/dd/yyyy-hh) as keys and the 
number of error occurrances as values. For the Apache 1.3.x log only.

=cut

sub errorbydatetime {
    my($this) = shift;
    return %{($this->{'errorbydatetime'} || undef)};
}

#######################################################################
# errormessage(); returns %errormessage;
=pod

=item *

C<errormessage();>

    %errormessage = $errorlogobject->errormessage();

Returns a hash containing error messages as keys and the number of
occurrances as values. For the Apache 1.3.x log only.

=cut

sub errormessage {
    my($this) = shift;
    return %{($this->{'errormessage'} || undef)};
}

#######################################################################
# noticebydate(); returns %noticebydate;
=pod

=item *

C<noticebydate();>

    %noticebydate = $errorlogobject->noticebydate();

Returns a hash containing date (mm/dd/yyyy) as keys and the number
of error occurrances as values. For the Apache 1.3.x log only.

=cut

sub noticebydate {
    my($this) = shift;
    return %{($this->{'noticebydate'} || undef)};
}

#######################################################################
# noticebytime(); returns %noticebytime;
=pod

=item *

C<noticebytime();>

    %noticebytime = $errorlogobject->noticebytime();

Returns a hash containing time (00-23) as keys and the number
of error occurrances as values. For the Apache 1.3.x log only.

=cut

sub noticebytime {
    my($this) = shift;
    return %{($this->{'noticebytime'} || undef)};
}

#######################################################################
# noticebydatetime(); returns %noticebydatetime;
=pod

=item *

C<noticebydatetime();>

    %noticebydatetime = $errorlogobject->noticebydatetime();

Returns a hash containing date/time (mm/dd/yyyy-hh) as keys and the 
number of error occurrances as values. For the Apache 1.3.x log only.

=cut

sub noticebydatetime {
    my($this) = shift;
    return %{($this->{'noticebydatetime'} || undef)};
}

#######################################################################
# noticemessage(); returns %noticemessage;
=pod

=item *

C<noticemessage();>

    %noticemessage = $errorlogobject->noticemessage();

Returns a hash containing notice messages as keys and the number of
occurrances as values. For the Apache 1.3.x log only. 

=cut

sub noticemessage {
    my($this) = shift;
    return %{($this->{'noticemessage'} || undef)};
}

#######################################################################
# warnbydate(); returns %warnbydate;
=pod

=item *

C<warnbydate();>

    %warnbydate = $errorlogobject->warnbydate();

Returns a hash containing date (mm/dd/yyyy) as keys and the number
of error occurrances as values. For the Apache 1.3.x only. 

=cut

sub warnbydate {
    my($this) = shift;
    return %{($this->{'warnbydate'} || undef)};
}

#######################################################################
# warnbytime(); returns %warnbytime;
=pod

=item *

C<warnbytime();>

    %warnbytime = $errorlogobject->warnbytime();

Returns a hash containing time (00-23) as keys and the number
of error occurrances as values. For the Apache 1.3.x only. 

=cut

sub warnbytime {
    my($this) = shift;
    return %{($this->{'warnbytime'} || undef)};
}

#######################################################################
# warnbydatetime(); returns %warnbydatetime;
=pod

=item *

C<warnbydatetime();>

    %warnbydatetime = $errorlogobject->warnbydatetime();

Returns a hash containing date/time (mm/dd/yyyy-hh) as keys and the 
number of error occurrances as values. For the Apache 1.3.x only. 

=cut

sub warnbydatetime {
    my($this) = shift;
    return %{($this->{'warnbydatetime'} || undef)};
}

#######################################################################
# warnmessage(); returns %warnmessage;
=pod

=item *

C<warnmessage();>

    %warnmessage = $errorlogobject->warnmessage();

Returns a hash containing warn messages as keys and the number of
occurrances as values. For the Apache 1.3.x only. 

=back

=cut

sub warnmessage {
    my($this) = shift;
    return %{($this->{'warnmessage'} || undef)};
}

#######################################################################
# REFERERLOG METHODS
=pod

=head2 RefererLog/CustomLog Methods

The following methods are available for the F<RefererLog> object
(created by C<getRefererLog()> method), as well as the F<CustomLog>
object that logs C<%{Referer}i> to the corresponding F<LogFormat>. 

=over 4

=cut

######################################################################
# referer(); returns %referer
=pod

=item *

C<referer();>

    %referer = $logobject->referer();

Returns a hash containing the name of the web site the visitor comes from
as keys, and the hit count for each key as values. 

Note that the returned data from this method contains B<only> the
site name of the referer, e.g. "www.altavista.digital.com", so if you want to
obtain the full details of the referer as well as the referred files, 
use C<refererdetail()> method described below. 

=cut

sub referer {
    my($this) = shift;
    return %{($this->{'referer'} || undef)};

}

#######################################################################
# refererdetail(); returns %refererdetail
=pod

=item *

C<refererdetail();>

Returns a hash containing the full URL of the referer as keys, and the
hit count for each key as values. 

The standard log format for the F<RefererLog> is <I<referer> -> I<URL>>.
With the F<CustomLog> object, the object attempts to use the URL first, 
and if the URL is not logged, then the relative path, and then the absolute 
path to create the key for the returned data I<%referer>. If none of the URL, 
relative or absolute paths are logged, the object will use only the referer 
URL itself (without refererd files) as the key. 

=back

=cut

sub refererdetail {
    my($this) = shift;
    return %{($this->{'refererdetail'} || undef)};
}

#######################################################################
# AGENTLOG METHODS
=pod

=head2 AgentLog/CustomLog Methods

This subsection describes the methods available for the F<AgentLog> object
(created by C<getAgentLog()> method), as well as the F<CustomLog>
object that logs C<%{User-agent}i> to the corresponding F<LogFormat>. 

=over 4

=cut

######################################################################
# uagent(); returns %uagent
=pod

=item *

C<uagent();>

    %uagent = $logobject->uagent();

Returns a hash containing the user agent (the "full name", as you 
see in the log file itself) as keys, and the hit count for each 
key as values. 

=cut

sub uagent {
    my($this) = shift;
    return %{($this->{'uagent'} || undef)};
}

######################################################################
# uaversion(); returns %uaversion
=pod

=item *

C<uaversion();>

    %uaversion = $logobject->uaversion();

Returns a hash containing the most basic and simple information about
the user agent (the first column in the agent log file, e.g. 
"C<Mozilla/4.06>") as keys, and the hit count for each 
key as values. Useful to collect the information about the parser engine 
and its version, to determine which specs of HTML and/or JavaScript to
deploy, for example. 

=cut

sub uaversion {
    my($this) = shift;
    return %{($this->{'uaversion'} || undef)};
}

######################################################################
# browser(); returns %browser
=pod

=item *

C<browser();>

    %browser = $logobject->browser();

Returns a hash containing the actual browsers (as logged in the file) 
as keys, and the hit count for each key as values. 

For example, Netscape Navigator/Communicator will (still) be reported as 
"C<Mozilla/I<version>>", Microsoft Internet Explorer  as "C<MSIE I<version>>", 
and so on. 

=cut

sub browser {
    my($this) = shift;
    return %{($this->{'browser'} || undef)};
}

######################################################################
# platform(); returns %platform
=pod

=item *

C<platform();>

    %platform = $logobject->platform();

Returns a hash containing the names of OS (and possibly its version, 
hardware architecture, etc.) as keys, and the hit count for each 
key as values. 

For example, Solaris 2.6 on UltraSPARC will be reported as 
"C<SunOS 5.6 sun4u>", 

=cut

sub platform {
    my($this) = shift;
    return %{($this->{'platform'} || undef)};
}

######################################################################
# browserbyos(); returns %browserbyos
=pod

=item *

C<browserbyos();>

    %browserbyos = $logobject->browserbyos();

Returns a hash containing the browser names with OS (in the form, 
I<browser (OS)>) as keys, and the hit count for each key as values. 

=back

=cut

sub browserbyos {
    my($this) = shift;
    return %{($this->{'browserbyos'} || undef)};
}

#######################################################################
# CUSTOMLOG METHODS
=pod

=head2 CustomLog Methods

This subsection describes the methods available only for the F<CustomLog>
object. See each method for what Apache directive is used for each
returned result. 

=over 4

=cut

######################################################################
# addr(); returns %addr
=pod

=item *

C<addr();>

    %addr = $logobject->addr();

Returns a hash containing the IP addresses of the B<web site> (instead of
the F<ServerName>) visited as keys, and the hit count for each key as 
values. (LogFormat C<%a>)

=cut

sub addr {
    my($this) = shift;
    return %{($this->{'addr'} || undef)};
}

######################################################################
# filename(); returns %filename
=pod

=item *

C<filename();>

    %filename = $logobject->filename();

Returns a hash containing the absolute paths to the files as keys, and 
the hit count for each key as values. (LogFormat C<%f>)

=cut

sub filename {
    my($this) = shift;
    return %{($this->{'filename'} || undef)};
}

######################################################################
# hostname(); returns %hostname
=pod

=item *

C<hostname();>

    %hostname = $logobject->hostname();

Returns a hash containing the hostnames of the visitors as keys, and 
the hit count for each key as values. (LogFormat C<%v>)

=cut

sub hostname {
    my($this) = shift;
    return %{($this->{'hostname'} || undef)};
}

######################################################################
# ostatus(); returns %ostatus
=pod

=item *

C<ostatus();>

    %ostatus = $logobject->ostatus();

Returns a hash containing HTTP codes and messages (e.g. "404 Not Found")
for the original status (i.e., when the httpd starts processing that 
request) as keys, and the hit count for each key as values. 

=cut

sub ostatus {
    my($this) = shift;
    return %{($this->{'ostatus'} || undef)};
}

######################################################################
# port(); returns %port
=pod

=item *

C<port();>

    %port = $logobject->port();

Returns a hash containing the port used for the transfer as keys, and 
the hit count for each key as values (there will probably be the only 
one key-value pair value for each server). (LogFormat C<%p>)

=cut

sub port {
    my($this) = shift;
    return %{($this->{'port'} || undef)};
}

######################################################################
# proc(); returns %proc
=pod

=item *

C<proc();>

    %proc = $logobject->proc();

Returns a hash containing the process ID of the server used for
each file transfer as keys, and the hit count for each key as values. 
(LogFormat C<%P>)

=cut

sub proc {
    my($this) = shift;
    return %{($this->{'proc'} || undef)};
}

######################################################################
# sec(); returns %sec
=pod

=item *

C<sec();>

    %sec = $logobject->sec();

Returns a hash containing the file names (either relative paths, 
absolute paths, or the URL, depending on your log format)
as keys, and the maximum seconds it takes to finish the process
as values. Thus, note that the values are not accumulated results, 
but rather the highest number of seconds it took to process the file.
(LogFormat C<%T>)

=cut

sub sec {
    my($this) = shift;
    return %{($this->{'sec'} || undef)};
}

######################################################################
# url(); returns %url
=pod

=item *

C<url();>

    %url = $logobject->url();

Returns a hash containing the URLs (path relative to the F<DocumentRoot>>
as keys, and the hit count for each key as values. (LogFormat C<%U>)

=back

=cut

sub url {
    my($this) = shift;
    return %{($this->{'url'} || undef)};
}

#######################################################################
# SPECIAL METHOD
=pod

=head2 Special Method

The special method described below, C<getMethods()>, can be used with
B<any> of the B<log objects> to extract the methods available for the 
calling object. 

=over 4

=cut

#######################################################################
# getMethods(); returns @methods;
=pod

=item *

C<getMethods();>

    @object_methods = $logobject->getMethods();

Returns an array containing the names of the available methods for 
that log object. Each of the elements in the array is the name of 
one of the methods described in this section. 

By using this method, you can write a I<really> simple Apache log parsing
and reporting script, like so:

    #!/usr/local/bin/perl
    $|++; # flush buffer
    use Apache::ParseLog;
    # Construct the Apache::ParseLog object
    $base = new Apache::ParseLog("/usr/local/httpd/conf/httpd.conf");
    # Get the CustomLog object for "my_custom_log"
    $customlog = $base->getCustomLog("my_custom_log");
    # Get the available methods for the CustomLog object
    @methods = $customlog->getMethods();
    # Iterate through the @methods
    foreach $method (@methods) {
        print "$method log report\n";
        # Get the returned value for each method
        %{$method} = $customlog->$method();
        # Iterate through the returned hash
        foreach (sort keys %{$method}) {
            print "$_: ${$method}{$_}\n";
        }
        print "\n";
    }
    exit;

=back

=cut

sub getMethods {
    my($this) = shift;
    return @{($this->{'methods'} || undef)};
}

#######################################################################
# MISCELLANEOUS
#######################################################################
=pod

=head1 MISCELLANEOUS

This section describes some miscellaneous methods that might be useful.

=cut

#######################################################################
# version(); returns $VERSION
=pod

=over 4

=item *

C<Version();>

Returns a scalar containing the version of the Apache::ParseLog module. 

=back

=cut

sub Version { $VERSION }

#######################################################################
# EXPORTED METHODS
=pod

=head2 Exported Methods

This subsection describes B<exported> methods provided by the 
Apache::ParseLog module. (For the information about exported methods, 
see Exporter(3).)

Note that those exported modules can be used (called) just like 
local (main package) subroutines. 

=over 4

=cut

#######################################################################
# countryByCode(); returns %COUNTRY_BY_CODE
=pod

=item *

C<countryByCode();>

    %countryByCode = countryByCode();

Returns a hash containing a hashtable of country-code top-level domain
names as keys and country names as values. Useful for creating a report
on "hits" by countries. 

=cut

sub countryByCode {
    return %COUNTRY_BY_CODE;
}

#######################################################################
# statusByCode(); returns %STATUS_BY_CODE
=pod

=item *

C<statusByCode();>

    %statusByCode = statusByCode();

Returns a hash containing a hashtable of status code of the Apache HTTPD
server, as defined by RFC2068, as keys and meanings as values. 

=cut

sub statusByCode {
    return %STATUS_BY_CODE;
}

#######################################################################
# sortHashByValue(); returns @sorted
=pod

=item *

C<sortHashByValue(%hash);>

    @sorted_keys = sortHashByValue(%hash);

Returns an array containing keys of the I<%hash> B<numerically> sorted 
by the values of the I<%hash>, by the descending order. 

Example

    # Get the custom log object
    $customlog = $log->getCustomLog("combined");
    # Get the log report on "file"
    %file = $customlog->file();
    # Sort the %file by hit counts, descending order
    @sorted_keys = sortHashByValue(%hash);
    foreach (@sorted_keys) {
        print "$_: $file{$_}\n"; # print <file>: <hitcount>
    }

=back

=cut

sub sortHashByValue {
    my(%hash) = @_;
    return sort { $hash{$b} <=> $hash{$a} } keys %hash;
}

#######################################################################
# PRIVATE METHODS
#######################################################################

#######################################################################
# openFile($any_file); returns a filehandle
sub openFile {
    my($file) = shift;
    my($METHOD) = "Apache::ParseLog::openFile";
    local(*FH);
    open(FH, "<$file") or croak "$METHOD: Cannot open $file. Exiting ";
    return *FH;
}

#######################################################################
# ADDITIONAL DOCUMENTATION
#######################################################################
=pod

=head1 EXAMPLES

The most basic, easiest way to create reports is presented as an
example in the C<getMethods()> section above, but the format of the
output is pretty crude and less user-friendly. 

Shown below are some other examples to use Apache::ParseLog. 

=head2 Example 1: Basic Report

The example code below checks the F<TransferLog> and F<ErrorLog> 
generated by the Apache 1.2.x, and prints the reports to STDOUT. 
(To run this code, all you have to do is to change the I<$conf>
value.)

    #!/usr/local/bin/perl
    $|++;
    use Apache::ParseLog;

    $conf = "/usr/local/httpd/conf/httpd.conf"; 
    $base = new Apache::ParseLog($conf);

    print "TransferLog Report\n\n";
    $transferlog = $base->getTransferLog();

    %hit = $transferlog->hit();
    %hitbydate = $transferlog->hitbydate();
    print "Total Hit Counts: ", $hit{'Total'}, "\n";
    foreach (sort keys %hitbydate) {
        print "$_:\t$hitbydate{$_}\n"; # <date>: <hit counts>
    }
    $hitaverage = int($hit{'Total'} / scalar(keys %hitbydate));
    print "Average Daily Hits: $hitaverage\n\n";

    %byte = $transferlog->byte();
    %bytebydate = $transferlog->bytebydate();
    print "Total Bytes Transferred: ", $byte{'Total'}, "\n";
    foreach (sort keys %bytebydate) {
        print "$_:\t$bytebydate{$_}\n"; # <date>: <bytes transferred>
    }
    $byteaverage = int($byte{'Total'} / scalar(keys %bytebydate));
    print "Average Daily Bytes Transferred: $byteaverage\n\n";

    %visitorbydate = $transferlog->visitorbydate();
    %host = $transferlog->host();
    print "Total Unique Visitors: ", scalar(keys %host), "\n";
    foreach (sort keys %visitorbydate) {
        print "$_:\t$visitorbydate{$_}\n"; # <date: <visitor counts>
    }
    $visitoraverage = int(scalar(keys %host) / scalar(keys %visitorbydate));
    print "Average Daily Unique Visitors: $visitoraverage\n\n";
    
    print "ErrorLog Report\n\n";
    $errorlog = $base->getErrorLog();

    %count = $errorlog->count();
    %allbydate = $errorlog->allbydate();
    print "Total Errors: ", $count{'Total'}, "\n";
    foreach (sort keys %allbydate) {
        print "$_:\t$allbydate{$_}\n"; # <date>: <error counts>
    }
    $erroraverage = int($count{'Total'} / scalar(keys %allbydate));
    print "Average Daily Errors: $erroraverage\n\n";

    exit;

=head2 Example 2: Referer Report

The F<RefererLog> (or F<CustomLog> with referer logged) contains the 
referer for every single file requested. It means that everytime a page 
that contains 10 images is requested, 11 lines are added to the 
F<RefererLog>, one line for the actual referer (where the visitor
comes from), and the other 10 lines for the images with the 
I<just refererd> page containing the 10 images as the referer, 
which is probably a little too much more than what you want to know. 

The example code below checks the F<CustomLog> that contains referer, 
(among other things), and reports the names of the referer sites that 
are not the local server itself. 

    #!/usr/local/bin/perl
    $|++;
    use Apache::ParseLog;

    $conf = "/usr/local/httpd/conf/httpd.conf"; 
    $base = new Apache::ParseLog($conf);

    $localserver = $base->servername();

    $log = $base->getCustomLog("combined");
    %referer = $log->referer();
    @sortedkeys = sortHashByValue(%referer);

    print "External Referers Report\n";
    foreach (@sortedkeys) {
        print "$_:\t$referer{$_}\n" unless m/$localserver/i or m/^\-/;
    }

    exit;

=head2 Example 3: Access-Controlled User Report

Let's suppose that you have a directory tree on your site that is
access-controlled by F<.htaccess> or the like, and you want to check
how frequently the section is used by the users. 

    #!/usr/local/bin/perl
    $|++;
    use Apache::ParseLog;

    $conf = "/usr/local/httpd/conf/httpd.conf";
    $base = new Apache::ParseLog($conf);

    $log = $base->getCustomLog("common");
    %user = $log->user();

    print "Users Report\n";
    foreach (sort keys %user) {
        print "$_:\t$user{$_}\n" unless m/^-$/;
    }

    exit;

=head1 SEE ALSO

perl(1), perlop(1), perlre(1), Exporter(3)

=head1 BUGS

The reports on lesser-known browsers returned from the F<AgentLog> methods 
are not always informative. 

The data returned from the C<referer()> method for F<RefererLog> may 
be irrelvant if the referred files are not accessed via HTTP (i.e., 
the referer does not start with "http://" string). 

If the base object is created with the I<$virtualhost> specified, 
unless the F<ServerAdmin> and F<ServerName> are specified within
the <VirtualHost xxx> ... </VirtualHost>, those values specified
in the global section of the I<httpd.conf> are not shared with
the I<$virtualhost>. 

=head1 TO DO

Increase the performance (speed). 

=head1 VERSION

Apache::ParseLog 1.01 (10/01/1998).

=head1 AUTHOR

Apache::ParseLog was written and is maintained by Akira Hangai 
(akira@discover-net.net)

For the bug reports, comments, suggestions, etc., please email me. 

=head1 COPYRIGHT

Copyright 1998, Akira Hangai. All rights reserved. 

This program is free software; You can redistribute it and/or modify 
it under the same terms as Perl itself. 

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful for
many web administrators/webmasters who are too busy to write their own
programs to analyze the Apache log files. However, this package is
so distributed WITHOUT ANY WARRANTY in that any use of the data
generated by this package must be used at the user's own discretion, 
and the author shall not be held accountable for any results
from the use of this package. 

=cut

#######################################################################
# DATA 
#######################################################################
__DATA__
ad:Andorra
ae:United Arab Emirates
af:Afghanistan
ag:Antigua and Barbuda
ai:Anguilla
al:Albania
am:Armenia
an:Netherlands Antilles
ao:Angola
aq:Antarctica
ar:Argentina
as:American Samoa
at:Austria
au:Australia
aw:Aruba
az:Azerbaijan
ba:Bosnia and Herzegovina
bb:Barbados
bd:Bangladesh
be:Belgium
bf:Burkina Faso
bg:Bulgaria
bh:Bahrain
bi:Burundi
bj:Benin
bm:Bermuda
bn:Brunei Darussalam
bo:Bolivia
br:Brazil
bs:Bahamas
bt:Bhutan
bv:Bouvet Island
bw:Botswana
by:Belarus
bz:Belize
ca:Canada
cc:Cocos (Keeling) Islands
cf:Central African Republic
cg:Congo
ch:Switzerland
ci:Cote D'Ivoire (Ivory Coast)
ck:Cook Islands
cl:Chile
cm:Cameroon
cn:China
co:Colombia
cr:Costa Rica
cs:Czechoslovakia (former)
cu:Cuba
cv:Cape Verde
cx:Christmas Island
cy:Cyprus
cz:Czech Republic
de:Germany
dj:Djibouti
dk:Denmark
dm:Dominica
do:Dominican Republic
dz:Algeria
ec:Ecuador
ee:Estonia
eg:Egypt
eh:Western Sahara
er:Eritrea
es:Spain
et:Ethiopia
fi:Finland
fj:Fiji
fk:Falkland Islands (Malvinas)
fm:Micronesia
fo:Faroe Islands
fr:France
fx:France Metropolitan,
ga:Gabon
gb:Great Britain (UK)
gd:Grenada
ge:Georgia
gf:French Guiana
gh:Ghana
gi:Gibraltar
gl:Greenland
gm:Gambia
gn:Guinea
gp:Guadeloupe
gq:Equatorial Guinea
gr:Greece
gs:S. Georgia and S. Sandwich Isls.
gt:Guatemala
gu:Guam
gw:Guinea-Bissau
gy:Guyana
hk:Hong Kong
hm:Heard and McDonald Islands
hn:Honduras
hr:Croatia (Hrvatska)
ht:Haiti
hu:Hungary
id:Indonesia
ie:Ireland
il:Israel
in:India
io:British Indian Ocean Territory
iq:Iraq
ir:Iran
is:Iceland
it:Italy
jm:Jamaica
jo:Jordan
jp:Japan
ke:Kenya
kg:Kyrgyzstan
kh:Cambodia
ki:Kiribati
km:Comoros
kn:Saint Kitts and Nevis
kp:Korea (North)
kr:Korea (South)
kw:Kuwait
ky:Cayman Islands
kz:Kazakhstan
la:Laos
lb:Lebanon
lc:Saint Lucia
li:Liechtenstein
lk:Sri Lanka
lr:Liberia
ls:Lesotho
lt:Lithuania
lu:Luxembourg
lv:Latvia
ly:Libya
ma:Morocco
mc:Monaco
md:Moldova
mg:Madagascar
mh:Marshall Islands
mk:Macedonia
ml:Mali
mm:Myanmar
mn:Mongolia
mo:Macau
mp:Northern Mariana Islands
mq:Martinique
mr:Mauritania
ms:Montserrat
mt:Malta
mu:Mauritius
mv:Maldives
mw:Malawi
mx:Mexico
my:Malaysia
mz:Mozambique
na:Namibia
nc:New Caledonia
ne:Niger
nf:Norfolk Island
ng:Nigeria
ni:Nicaragua
nl:Netherlands
no:Norway
np:Nepal
nr:Nauru
nt:Neutral Zone
nu:Niue
nz:New Zealand (Aotearoa)
om:Oman
pa:Panama
pe:Peru
pf:French Polynesia
pg:Papua New Guinea
ph:Philippines
pk:Pakistan
pl:Poland
pm:St. Pierre and Miquelon
pn:Pitcairn
pr:Puerto Rico
pt:Portugal
pw:Palau
py:Paraguay
qa:Qatar
re:Reunion
ro:Romania
ru:Russian Federation
rw:Rwanda
sa:Saudi Arabia
sb:Solomon Islands
sc:Seychelles
sd:Sudan
se:Sweden
sg:Singapore
sh:St. Helena
si:Slovenia
sj:Svalbard and Jan Mayen Isls.
sk:Slovak Republic
sl:Sierra Leone
sm:San Marino
sn:Senegal
so:Somalia
sr:Suriname
st:Sao Tome and Principe
su:USSR (former)
sv:El Salvador
sy:Syria
sz:Swaziland
tc:Turks and Caicos Islands
td:Chad
tf:French Southern Territories
tg:Togo
th:Thailand
tj:Tajikistan
tk:Tokelau
tm:Turkmenistan
tn:Tunisia
to:Tonga
tp:East Timor
tr:Turkey
tt:Trinidad and Tobago
tv:Tuvalu
tw:Taiwan
tz:Tanzania
ua:Ukraine
ug:Uganda
uk:United Kingdom
um:US Minor Outlying Islands
us:United States
uy:Uruguay
uz:Uzbekistan
va:Vatican City State (Holy See)
vc:Saint Vincent and the Grenadines
ve:Venezuela
vg:Virgin Islands (British)
vi:Virgin Islands (U.S.)
vn:Viet Nam
vu:Vanuatu
wf:Wallis and Futuna Islands
ws:Samoa
ye:Yemen
yt:Mayotte
yu:Yugoslavia
za:South Africa
zm:Zambia
zr:Zaire
ZW:Zimbabwe 
com:US Commercial
edu:US Educational 
gov:US Government
int:International
mil:US Military
net:Network
org:Non-Profit Organization
arpa:Old style Arpanet
nato:NATO Field
