#!/usr/bin/perl
#
# blmanager.cgi - A very basic CGI interface to manage DNSBLs
#
# Luis E. Muñoz

# $Id: blmanager.cgi,v 1.1 2004/10/15 17:27:01 lem Exp $

use strict;
use warnings;

use DNS::BL;
use NetAddr::IP;
use DNS::BL::Entry;

use CGI qw/:standard :html3 :table/;

# Some safety nets
$ENV{PATH} = '/bin:/usr/bin:/usr/local/bin:/usr/ucb';
delete @ENV{ 'IFS', 'CDPATH', 'ENV', 'BASH_ENV' };
$CGI::POST_MAX=256;  
$CGI::DISABLE_UPLOADS = 1;  # no uploads

# Some config stuff... You must adapt this to your needs
my %lists = (
	     spam	=> 'db file /tmp/spam.db',
	     dul	=> 'db file /tmp/dul.db',
	     );

my %actions = (
	       add	=> 'Add an entry',
	       delete	=> 'Delete an entry',
	       punch	=> 'Punch a hole through one or more entries',
	       print	=> 'Print entries',
	       );

# Produce the basic dashboard

print header;
print start_html('DNS::BL Manager'),
    h1('DNS::BL Manager'),
    start_form,
    p("Choose the list you want to act upon:&nbsp;",
      popup_menu('dnsbl', [ keys %lists ], 
		 { map { $_ => "$_ list" } keys %lists } )),
    p("Choose the action you would like to do:&nbsp;",
      popup_menu('action', [ keys %actions ], 
		 (sort { $a cmp $b } keys %actions)[0], \%actions)),
    p("IP address or range (always required):&nbsp;", textfield('ip')),
    p("Return code (for add):&nbsp;", textfield('code', '127.0.0.2')),
    p("Message text (for add):&nbsp;", textfield('text')),
    submit,
    end_form, hr;

# Obtain the form parameters
my $dnsbl = param('dnsbl');
my $action = param('action');
my $ip = param('ip');
my $code = param('code');
my $text = param('text') || 'No text supplied';

# Perform error checking and actions
if (defined $ip and length $ip)
{
    my $Ip = new NetAddr::IP $ip;

    if ($Ip)
    {
	if (exists $lists{$dnsbl})
	{

	    my $bl = new DNS::BL;
	    my @r = $bl->parse('connect ' . $lists{$dnsbl});

	    if ($r[0] != &DNS::BL::DNSBL_OK)
	    {
		print h2("DNS::BL error"),
		p("DNS::BL connect returned [$r[0]] - $r[1]"),
		hr, end_html;
		return 0;
	    }

	    if ($action eq 'add')
	    {
		@r = $bl->parse(qq{add ip $Ip text "$text" code "$code"});
		print h2("DNS::BL result"),
		p("DNS::BL add returned [$r[0]] - $r[1]");

		@r = $bl->parse(qq{commit});
		print p("DNS::BL commit returned [$r[0]] - $r[1]"),
		hr;
	    }
	    elsif ($action eq 'delete')
	    {
		@r = $bl->parse(qq{delete within $Ip});
		print h2("DNS::BL result"),
		p("DNS::BL delete returned [$r[0]] - $r[1]");

		@r = $bl->parse(qq{commit});
		print p("DNS::BL commit returned [$r[0]] - $r[1]"),
		hr;
	    }
	    elsif ($action eq 'punch')
	    {
		@r = $bl->parse(qq{punch hole $Ip});
		print h2("DNS::BL result"),
		p("DNS::BL punch returned [$r[0]] - $r[1]");

		@r = $bl->parse(qq{commit});
		print p("DNS::BL commit returned [$r[0]] - $r[1]"),
		hr;
	    }
	    elsif ($action eq 'print')
	    {
		@r = $bl->parse(qq{print within $Ip as internal});
		print h2("DNS::BL result"),
		p("DNS::BL print returned [$r[0]] - $r[1]");

		for my $e (sort { $a->addr <=> $b->addr } @r[2 .. $#r])
		{
		    print p($e->addr, $e->value, "-", $e->desc, "-", 
			    scalar localtime $e->time);
		}

		print hr;
	    }
	    else
	    {
		print h2("Invalid action"),
		p("Actions must be selected from the pull-down menu above"),
		hr;
	    }
	}
	else
	{
	    print h2("Invalid DNSBL selected"),
	    p("The DNSBL you selected is not configured in this script"),
	    hr;
	}
    }
    else
    {
	print h2("Invalid IP address"),
	p("The supplied IP address cannot be properly interpreted"),
	hr;
    }
}

print end_html;

