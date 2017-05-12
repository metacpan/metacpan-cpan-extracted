package Apache::CodeRed;

use strict;
use warnings;

use vars qw($VERSION);

use Apache::Constants qw(OK DECLINED FORBIDDEN);
use Mail::Sendmail;
use Net::DNS;
use Cache::FileCache;
use Time::Zone;

# ------------------------------------------------------------
# What version of the module is this?
$VERSION = 1.07;

# Set this to your favorite URL describing how to fix this problem.
my $security_url = 'http://www.microsoft.com/technet/treeview/default.asp?url=/technet/itsolutions/security/topics/codealrt.asp';

# To what address at SecurityFocus do we report the attack?
my $security_focus_address = 'aris-report@securityfocus.com';

# What "From:" header should be inserted into outgoing e-mail?
my $from_address = 'from@codered.example.com';

# Do you want to know when one of these alerts has been sent?  If so,
# put your address here.
my $cc_address = 'cc@codered.example.com';

# Define the Cache::Cache options we want to use.  If nothing else,
# indicate when the cache should expire -- the default value is one
# day (86400 seconds).
my %cache_options = ('default_expires_in' => 86400 );

# List of regexps that should be ignored by Apache::CodeRed
my @ignore_ip = ('192\.168\..*', '10\..*');

# ------------------------------------------------------------

sub handler
{
    # Get Apache request/response object
    my $r = shift;

    # Get the server name
    my $s = $r->server();
    my $server_name = $s->server_hostname();

    # Create a DNS resolver, which we'll need no matter what.
    my $res = new Net::DNS::Resolver;

    # ------------------------------------------------------------
    # Open the cache of already-responded-to IP addresses,
    # which we're going to keep in /tmp, just for simplicity.
    my $file_cache = new Cache::FileCache(\%cache_options);

    unless ($file_cache)
    {
	$r->log_error("CodeRed: Could not instantiate FileCache.  Exiting.");
	return DECLINED;
    }

    # Get the HTTP client's IP address.  We'll use this to send mail
    # to the people who run the domain.
    my $remote_ip_address = $r->get_remote_host();

    # If we don't have the remote IP address, then we cannot send mail
    # to the remote server, can we?  Let's just stop now, while we're at it.
    unless (defined $remote_ip_address)
    {
	$r->warn("CodeRed: Undefined remote IP address!  Exiting.");
	return DECLINED;
    }

    # If we have the remote IP address, then check to see if it's in
    # our cache.
    my $last_visited = $file_cache->get($remote_ip_address);

    # If the address is in our cache, then we've already
    # sent e-mail to that person, and we'll just return FORBIDDEN.
    if ($last_visited)
    {
	$r->warn("CodeRed: Found cached IP '$remote_ip_address'.  Exiting.");
	return FORBIDDEN;
    }

    # If the remote address matches our ignore list, then ignore it
    foreach my $ignore_ip (@ignore_ip)
    {
	if ($remote_ip_address =~ /^$ignore_ip$/) {
	    $r->warn("CodeRed: Detected known '$remote_ip_address' (matched '$ignore_ip').  Exiting.");
	    return FORBIDDEN;
	}
    }

    # ------------------------------------------------------------
    # If we only have the IP address (rather than the hostname), then
    # get the hostname.  (We can't look up the MX host for a number,
    # only a name.)

    my $remote_hostname = $remote_ip_address;

    # If the IP address is numeric, then look up its name 
    if ($remote_ip_address =~ /^[\d.]+$/)
    {
	my $dns_query_response = $res->search($remote_ip_address);

	if ($dns_query_response) 
	{
	    foreach my $rr ($dns_query_response->answer)
	    {
		# All of the records we retrieve should be PTR records,
		# since we're doing an IP-to-hostname lookup.
		next unless $rr->type eq "PTR";

		# Once we know this is a PTR, we can grab its name
		$remote_hostname = $rr->rdatastr;
	    }
	}
	else
	{
	    my $dns_error = $res->errorstring;
	    $r->warn("CodeRed: Failed DNS lookup of '$remote_ip_address' ('$dns_error')");
	}
    }

    # ------------------------------------------------------------
    # Send e-mail to SecurityFocus.com, which is going to 
    # deal with all of this stuff automatically

    $r->warn("CodeRed: Sending e-mail to SecurityFocus about '$remote_ip_address'");

    my $now = scalar localtime;
    my $time_zone_name = tz_name();

    my $sf_message = "$remote_ip_address\t$now $time_zone_name

Brought to you by Apache::CodeRed $VERSION for mod_perl and Apache,
written by Reuven M. Lerner (<reuven\@lerner.co.il> and running on
'$server_name'.
";

    my %sf_mail = ( To      => $security_focus_address,
		    CC      => $cc_address,
		    From    => $from_address,
		    Subject => "CodeRed infection on '$remote_hostname': Automatic report",
		    Message => $sf_message
	       );

    my $sf_sendmail_success = sendmail(%sf_mail);
    
    if ($sf_sendmail_success)
    {
	# Cache the fact that we saw this IP address
	$file_cache->set($remote_ip_address, 1);
    }
    else
    {
	$r->warn("CodeRed: Mail::Sendmail returned '$Mail::Sendmail::error'.  Exiting.");
	return DECLINED;
    }

    # ------------------------------------------------------------
    # Get the MX for this domain.  This is trickier than you might
    # think, since some DNS servers (like my ISP's) give accurate
    # answers for domains, but not for hosts.  So www.lerner.co.il
    # doesn't have an MX, while lerner.co.il does.  So we're going to
    # do an MX lookup -- and if it doesn't work, we're going to break
    # off everything up to and including the first . in the hostname,
    # and try again.  We shouldn't have to get to the top-level
    # domain, but we'll try that anyway, just in case the others don't
    # work.

    my @mx = ();
    my @hostname_components = split /\./, $remote_hostname;
    my $starting_index = 0;

    # Loop around until our starting index begins at the same location
    # as it would end

    while ($starting_index < @hostname_components)
    {
	my $host_for_mx_lookup = 
	    join '.', 
		@hostname_components[$starting_index .. $#hostname_components];

	@mx = mx($res, $host_for_mx_lookup);
	
	if (@mx)
	{
	    last;
	}
	else
	{
	    $starting_index++;
	}
    }

    # If we still haven't found any records, then simply return FORBIDDEN,
    # and log an error message
    if (! @mx)
    {
	my $dns_error = $res->errorstring;
	$r->warn("CodeRed: No MX records for '$remote_hostname': '$dns_error'.  Exiting.");
	return FORBIDDEN;
    }

    # Grab the first MX record, and assume that it'll work.
    my $mx_host = $mx[0]->exchange;
    $r->warn("CodeRed: Using MX host '$mx_host'");

    # ------------------------------------------------------------
    # Send e-mail to the webmaster, postmaster, and administrator,
    # since the webmaster and/or postmaster addresses often doesn't
    # work.
    my $remote_webmaster_address = 
	"webmaster\@$mx_host, postmaster\@$mx_host, administrator\@$mx_host";

    # Set the outgoing message

    my $outgoing_message = <<END;

Your Microsoft IIS server (at $remote_ip_address) appears to have been
infected with a strain of the CodeRed worm.  It attempted to spread to
our Web server, despite the fact that we run Linux and Apache (which
are immune).

You should immediately download the security patch from Microsoft, from
<$security_url>.

Automatically generated by Apache::CodeRed $VERSION for mod_perl and
Apache, written by Reuven M. Lerner (<reuven\@lerner.co.il> and
running on '$server_name'.
END

    # ------------------------------------------------------------
    # Also send e-mail to the people running the offending host,
    # just in case SecurityFocus takes a while.

    $r->warn("CodeRed: Sending e-mail to '$remote_webmaster_address'");

    my %mail = ( To      => $remote_webmaster_address,
		 CC      => $cc_address,
		 From    => $from_address,
		 Subject => "CodeRed infection on '$remote_hostname': Automatic report",
		 Message => $outgoing_message
	       );

    my $sendmail_success = sendmail(%mail);
    
    if ($sendmail_success)
    {
	# Cache the fact that we saw this IP address
	$file_cache->set($remote_ip_address, 1);

	return FORBIDDEN;
    }
    else
    {
	$r->warn("CodeRed: Mail::Sendmail returned '$Mail::Sendmail::error'.  Exiting.");
	return DECLINED;
    }
}

# All modules must return a true value
1;

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

    Apache::CodeRed - Responds to CodeRed worm attacks with e-mail warnings

=head1 SYNOPSIS

    In your httpd.conf, put the following:

	PerlModule	Apache::CodeRed

	<Location /default.ida>
	    SetHandler perl-script
	    PerlHandler Apache::CodeRed
	</Location>

=head1 DESCRIPTION

    This Perl module should be invoked whenever the CodeRed or
    CodeRed2 worm attacks.  We don't have to worry about such attacks
    on Linux boxes, but we can be good Internet citizens, warning the
    webmasters on infected machines of the problem and how to solve
    it.

=head1 BUGS

    If the remote IP address fails a reverse DNS lookup, we don't send
    e-mail to anyone associated with that host.  (We do, however,
    submit the IP address to SecurityFocus.)  It would be nice to
    automatically determine which ISP is responsible for a particular
    IP address, and contact them automatically.

=head1 LICENSE

    You may distribute this module under the same license as Perl itself.

=head1 AUTHOR

    Reuven M. Lerner, reuven@lerner.co.il

    Thanks to Randal Schwartz, David Young, and Salve J. Nilsen for
    their suggestions.

=head1 SEE ALSO

L<mod_perl>.

=cut
