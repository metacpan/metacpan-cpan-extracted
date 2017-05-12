#############################################################################
#
#	Copyright (C) 2000-2002 David Castro, Azusa Pacific University
#
#   This program is free software; you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the Free
#   Software Foundation; either version 2 of the License, or (at your option)
#   any later version.
#   
#   This program is distributed in the hope that it will be useful, but WITHOUT
#   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#   FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
#   more details.
#   
#   You should have received a copy of the GNU General Public License along
#   with this program; if not, write to the Free Software Foundation, Inc., 59
#   Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
#############################################################################
#
#	Description
#
#	Add the following to VirtualHost configs:
#
#	<VirtualHost ...>
#		ServerAdmin root@localhost.localdomain
#		# some document root...empty or whatever you want to be seen if mod_perl
#		# gets disabled or something similar
#		DocumentRoot /var/www/html
#		# domain with a wildcard subdomain alias (ooo...tricky)
#		ServerName somedomain.com
#		ServerAlias *.somedomain.com
#		# OR simply this (depending on your needs/preference)
#		ServerName *.somedomain.com
#	
#		SetHandler  perl-script
#		PerlHandler Apache::FilteringProxy
#		PerlSetVar FilteringProxyMode normal  # 'normal' or 'admin'
#		PerlSetVar  FilteringProxyConfig /some/absolute/path/to/config.xml
#	</VirtualHost>
#
#	TODO
#	external processing filters
#	additional optimizations
#	add in a configurable static header to all proxied content?
#	translate any IPs from the proxied server to our local IP?
#	anything your heart desires (or at least convince me to add)
#
#############################################################################
#

# We're an Apache class; subclass of LWP::UserAgent
package Apache::FilteringProxy;

# make sure we make our lives and everyone else's life easier when trying to
# decipher this code (it may still be a challenge)
use strict;
use diagnostics;
use vars qw(@ISA $VERSION $config_modification $logging $mode $local_servername $resource_domain);
# mode - used to store the value of FilteringProxyMode
# local_servername - store the local servername override
#     allows you to create "admin.yourdomain.com" for administrative mode
#     then set the local_servername to "yourdomain.com", so that "admin"
#     becomes this resource id, since we require a resource id

use Apache::Constants qw(:common :response);
use LWP::UserAgent;
use Apache::URI;	# parsing all parts of a uri, $uri = $r->parsed_uri()
use XML::EasyOBJ;

# subclass and override any methods we want to
@ISA = qw(LWP::UserAgent);
$VERSION = '0.1';
$mode = "";
$local_servername = "";
$resource_domain = "";

# return 0 from LWP::UserAgent::redirect_ok subroutine, so LWP won't try to
# handle redirects itself.  We want to see any redirects, filter their content,
# and then pass the filtered header back to the client.
#
sub redirect_ok {0}

#
# handler
#
# PerlHandler function that:
#   1) checks for requests that are unproxied
#   2) reads in the configuration file, if it has been modified since last read
#   3) pushes a new content handler that will handle the entire request
#
sub handler {
	# get our request and log object
	my $r = shift;

	# If this is an already proxied request, decline the request.
	if ($r->proxyreq) {
		$r->warn("DEBUG: determining if this is already a proxied request...yes");
		return DECLINED;
	} else {
		$r->warn("DEBUG: determining if this is already a proxied request...no");
	}

	# get the path to the configuration file
	my $config_file;
	if (!($config_file = $r->dir_config("FilteringProxyConfig"))) {
		$r->warn("FilteringProxyConfig not set");
		return DECLINED;
	}

	# get the path to the configuration file
	if (!($mode = $r->dir_config("FilteringProxyMode"))) {
		$mode = "normal";
		$r->warn("FilteringProxyMode not set, defaulting to normal mode");
	} else {
		$mode = lc($mode);
		$r->warn("FilteringProxy mode set to '$mode'");
	}

	# FilteringProxyServername is only for admin mode to override the local servername
	if (($mode eq "admin") or ($mode eq "mirror")) {
		if (!($local_servername = $r->dir_config("FilteringProxyServername"))) {
			my $s = $r->server;
			$local_servername = $s->server_hostname();
			$r->warn("FilteringProxyServername not set, defaulting to '$local_servername'");
		} else {
			$r->warn("FilteringProxy local_servername set to '$local_servername'");
		}
	} else {
		my $s = $r->server;
		$local_servername = $s->server_hostname();
	}

	# get the path to the configuration file
	if (!($resource_domain = $r->dir_config("FilteringProxyResourceDomain"))) {
		$resource_domain = $local_servername;
		$r->warn("FilteringProxyResourceDomain not set, defaulting to servername '$local_servername'");
	} else {
		$resource_domain = lc($resource_domain);
		$r->warn("FilteringProxyResourceDomain set to '$resource_domain'");
	}

	### XML CONFIGURATION
	# get the modification time of the configuration file
	# dev,ino,mode,nlink,uid,gid,rdev,size,atime,mtime,ctime,blksize,blocks
	my @stat;
	unless ((-r $config_file) and (@stat = stat($config_file))) {
		$r->warn("could not stat '$config_file' ( FilteringProxyConfig )");
	} else {
		$r->warn("DEBUG: entering XML configuration");

		my $mtime = $stat[9];

		# only update our cached configuration if the config file has been modififed
		if (!defined($Apache::FilteringProxy::config_modification) or 
		   ($mtime > $Apache::FilteringProxy::config_modification)) 
		{
			$r->warn("DEBUG: updating XML configuration");

			# get our XML from the config file
			open(CONFIG, "<$config_file") || $r->warn("couldn't open configuration file '$config_file'");
			undef $/;
			my $xml_source = <CONFIG>;
			$/ = "\n";
			close(CONFIG);

			# create parser object and parse configuration from our string
			my $config = new XML::EasyOBJ(-type => 'string', -param => $xml_source);
			#my $config = my $doc = new XML::EasyOBJ(-type => 'file', -param => $config_file);

			# we have just modified our file, so let's set our modification
			# date to the new mod time so we don't keep causing ourself to
			# reread the config
			@stat = stat($config_file);
			$mtime = $stat[9];

			# log the configuration file modification stats 
			if (defined($Apache::FilteringProxy::config_modification)) {
				$r->warn("config: modification time: current=$mtime,last=$Apache::FilteringProxy::config_modification");
			} else {
				$r->warn("config: modification time: current=$mtime,last=none");
			}

			$Apache::FilteringProxy::config_modification = $mtime;

			my @resources = $config->resource;
			my @filter_types = $config->getElement("filter-type")->type();
			my @strip_headers = $config->getElement("strip-headers")->name();
			my @strip_cookies = $config->getElement("strip-cookies")->name();
			my @type_translations = $config->getElement("type-translations")->item();
			my @translations = $config->translations()->item();
			my $default_url = $config->getElement("default-url")->getAttr("value");
			my $proxy_url = $config->getElement("proxy-url")->getAttr("value");
			my $logging = $config->logging()->getAttr("value");

			# see if we have logging enabled
			#
			# logging levels
			# 	0 - critical
			#	1 - verbose
			#	2 - debug with headers
			#	3 - debug with headers & source
			if ($logging) {
				$Apache::FilteringProxy::logging = $logging;
				$r->warn("config: logging level set to '".$logging."'");
			} else {
				$Apache::FilteringProxy::logging = 0;
			}

			# get admin database configuration
			$Apache::FilteringProxy::db_hostname = $config->getElement("admin-database")->hostname->getString() || "localhost";
			$Apache::FilteringProxy::db_hostport = $config->getElement("admin-database")->hostport->getString() || "5432";
			$Apache::FilteringProxy::db_username = $config->getElement("admin-database")->username->getString() || "user";
			$Apache::FilteringProxy::db_password = $config->getElement("admin-database")->password->getString() || "pass";
			$Apache::FilteringProxy::db_database = $config->getElement("admin-database")->database->getString() || "default";
			$Apache::FilteringProxy::db_driver   = $config->getElement("admin-database")->getElement("dbi-dbd")->getString() || "Pg";
			$r->warn("config: admin db hostname: " . $Apache::FilteringProxy::db_hostname) unless ($Apache::FilteringProxy::logging < 1);
			$r->warn("config: admin db hostport: " . $Apache::FilteringProxy::db_hostport) unless ($Apache::FilteringProxy::logging < 1);
			$r->warn("config: admin db username: " . $Apache::FilteringProxy::db_username) unless ($Apache::FilteringProxy::logging < 1);
			$r->warn("config: admin db password: " . (($Apache::FilteringProxy::db_password) ? "*not empty*" : "*empty*")) unless ($Apache::FilteringProxy::logging < 1);
			$r->warn("config: admin db database: " . $Apache::FilteringProxy::db_database) unless ($Apache::FilteringProxy::logging < 1);
			$r->warn("config: admin db driver: " . $Apache::FilteringProxy::db_driver) unless ($Apache::FilteringProxy::logging < 1);

			# the proxy that will be used in all requests made by LWP to
			# retrieve content from a remote server
			if ($proxy_url) {
				$Apache::FilteringProxy::proxy_url = $proxy_url;
				$r->warn("config: proxy url: $proxy_url");
			} else {
				$Apache::FilteringProxy::proxy_url = "";
			}

			# the url that a user will be sent to when they try to access
			# an unconfigured resource - set in the configuration file
			if ($default_url) {
				$Apache::FilteringProxy::default_url = $default_url;
				$r->warn("config: default url: $default_url");
			} else {
				$Apache::FilteringProxy::default_url = "http://www.slashdot.org/";
			}

			# get all of the content types that we want to filter
			undef $Apache::FilteringProxy::filter_types;
			my $filter_type;
			foreach $filter_type (@filter_types) {
				$Apache::FilteringProxy::filter_types{$filter_type->getString()} = 1;
				$r->warn("config: filter type: ".$filter_type->getString()) unless ($Apache::FilteringProxy::logging < 1);
			}

			# get all of the headers that we want to strip
			undef $Apache::FilteringProxy::strip_headers;
			my $strip_header;
			foreach $strip_header (@strip_headers) {
				$Apache::FilteringProxy::strip_headers{$strip_header->getString()} = 1;
				$r->warn("config: strip header: ".$strip_header->getString()) unless ($Apache::FilteringProxy::logging < 1);
			}

			# get all of the cookies types that we want strip
			undef $Apache::FilteringProxy::strip_cookies;
			my $strip_cookie;
			foreach $strip_cookie (@strip_cookies) {
				$Apache::FilteringProxy::strip_cookies{$strip_cookie->getString()} = 1;
				$r->warn("config: strip cookie: ".$strip_cookie->getString()) unless ($Apache::FilteringProxy::logging < 1);
			}

			# get all of the content-type translations we need to perform
			# e.g. translating "text-html" to "text/html"
			undef %Apache::FilteringProxy::type_translations;
			my $type_translation;
			foreach $type_translation (@type_translations) {
				if ($type_translation->match()->getString() && $type_translation->replace()->getString()) {
					my $match = $type_translation->match()->getString();
					my $replace = $type_translation->replace()->getString();

					$Apache::FilteringProxy::type_translations{$match} = $replace;

					$r->warn("config: type-translation: $match=>$replace") unless ($Apache::FilteringProxy::logging < 1);
				}
			}

			# get all of the translations we need to make
			undef %Apache::FilteringProxy::translations;
			my $translation;
			foreach $translation (@translations) {
				if ($translation->match()->getString() && $translation->replace()->getString()) {
					my $match = $translation->match()->getString();
					my $replace = $translation->replace()->getString();

					$Apache::FilteringProxy::translations{$match} = $replace;

					$r->warn("config: translation: $match=>$replace") unless ($Apache::FilteringProxy::logging < 1);
				}
			}

			# get all of the resources and hash them by resource id
			undef $Apache::FilteringProxy::proxy_domain_include_list;
			undef $Apache::FilteringProxy::proxy_host_include_list;
			undef $Apache::FilteringProxy::proxy_domain_exclude_list;
			undef $Apache::FilteringProxy::proxy_host_exclude_list;
			undef $Apache::FilteringProxy::filter_cookie_list;
			my $resource;
			foreach $resource (@resources) {
				my $id = $resource->getAttr('id');
				$r->warn("config: resources: id => $id") unless ($Apache::FilteringProxy::logging < 1);

				if ($resource->getAttr('url')) {
					$Apache::FilteringProxy::url{$id} = $resource->getAttr('url');
				}

				$r->warn("config: resources: url => $Apache::FilteringProxy::url{$id}") unless ($Apache::FilteringProxy::logging < 1);

				if ($resource->getAttr('filter-cookies')) {
					$Apache::FilteringProxy::filter_cookie_list{$id} = $resource->getAttr('filter-cookies');
				} else {
					# default to filtering cookies
					$Apache::FilteringProxy::filter_cookie_list{$id} = 1;
				}

				$r->warn("config: resources: filter-cookies => $Apache::FilteringProxy::filter_cookie_list{$id}") unless ($Apache::FilteringProxy::logging < 1);

				my @domain_include = $resource->getElement('domain-include');
				foreach (@domain_include) {
					push(@{$Apache::FilteringProxy::proxy_domain_include_list{$id}}, $_->getString());

					$r->warn("adding domain-include '".$_->getString()."' to resource '$id'") unless ($Apache::FilteringProxy::logging < 1);
				}

				my @host_include = $resource->getElement('host-include');
				foreach (@host_include) {
					push(@{$Apache::FilteringProxy::proxy_host_include_list{$id}}, $_->getString());

					$r->warn("adding host-include '".$_->getString()."' to resource '$id'") unless ($Apache::FilteringProxy::logging < 1);
				}

				my @domain_exclude = $resource->getElement('domain-exclude');
				foreach (@domain_exclude) {
					push(@{$Apache::FilteringProxy::proxy_domain_exclude_list{$id}}, $_->getString());

					$r->warn("adding domain-exclude '".$_->getString()."' to resource '$id'") unless ($Apache::FilteringProxy::logging < 1);
				}

				my @host_exclude = $resource->getElement('host-exclude');
				foreach (@host_exclude) {
					push(@{$Apache::FilteringProxy::proxy_host_exclude_list{$id}}, $_->getString());

					$r->warn("adding host-exclude '".$_->getString()."' to resource '$id'") unless ($Apache::FilteringProxy::logging < 1);
				}
			}
		} else {
			$r->warn("XML CONFIG CACHED") unless ($Apache::FilteringProxy::logging < 1);
		}
	} # END CONFIGURATION

	$r->filename ($r->document_root() or '/dev/null');

	# setup the filteringproxy_handler function to be a handler
	$r->push_handlers (PerlHandler => \&filteringproxy_handler);

	return OK;
}

#
# filteringproxy_handler
#
# this handler is installed as a substitute for the above handler() subroutine.
# It acts like a regular proxy except for content filtering it provides.  It:
#   1) does the actual content fetching from the remote, "proxied", server
#   2) filters all of the content and headers by translating all URLs that need
#      to continue to be proxied appropriately.
#   3) returns the filtered data to the client
#
sub filteringproxy_handler {
	my $tmp;
	my $r = shift;

	# get the local server information to use for determining what resource
	# the user is trying to access
	my $s = $r->server;
	my $local_hostname = $r->hostname();
    my $local_port = $s->port() ? ($s->port()) : '';

	# find our remote servername, port and resource id from the hostname
	$local_hostname =~ m/(.*)$local_servername$/;
	my $remote_string = $1 || "";
	my ($remote_servername, $remote_port, $resource_id);
	if ($remote_string) {
		if ($remote_string =~ m/(.*)\.port(\d{1,5})\.([^.]+)\.$/) {
			$remote_servername = $1;
			$remote_port = $2;
			$resource_id = $3;
		} else {
			$remote_string =~ s/(^|\.)([^.]+)\.$//;
			$resource_id = $2;
			$remote_servername = $remote_string;
			$remote_port = 80;
		}

		$r->warn("DEBUG: resource id '$resource_id' found") unless ($Apache::FilteringProxy::logging < 3);
	} else {
		$r->warn("no server name: local hostname: $local_hostname, local servername: $local_servername");
		# could print out some pretty HTML message here
		return FORBIDDEN;
	}

	# this will be used when only the resource name is specified with the
	# resource subdomain.  We will default redirect the user to the url
	# specified for the resource.
	if ($resource_id and !$remote_servername) {
		if (defined($Apache::FilteringProxy::url{$resource_id}) and 
		    ($Apache::FilteringProxy::url{$resource_id} ne ""))
		{
			my $url = $Apache::FilteringProxy::url{$resource_id};

			if ($url =~ 
			m@
				(http:\/\/)					# http://
				([A-Za-z0-9\.\-]+)	 		# hostname
				(:([0-9]{1,5}))? 			# :port
				(\/.*|$)					# the path
			@ix) {
				my $http_string = $1;
				my $hostname = $2;
				my $port = $4 || "80";
				my $path = $5 || "";

				$r->warn("DEBUG: redirecting user to '$http_string$hostname.port$port.$resource_id.$local_servername$path'") unless ($Apache::FilteringProxy::logging < 2);
				$r->header_out("Location" => "$http_string$hostname.port$port.$resource_id.$local_servername$path");
				return REDIRECT;
			} else {
				$r->warn("DEBUG: no valid url (specified: '$url') to redirect user to for resource '$resource_id'") unless ($Apache::FilteringProxy::logging < 2);
				# we could do something like print some nice HTML error here
				return FORBIDDEN;
			}
		} else {
			$r->warn("DEBUG: no url to redirect user to for resource '$resource_id'") unless ($Apache::FilteringProxy::logging < 2);
			# we could do something like print some nice HTML error here
			return FORBIDDEN;
		}
	}

	# in admin mode, we want to rewrite every host we encounter
	if ($mode eq "admin") {
		# let's add the remote server to our list of hosts/domains we want to
		# configure for proxying
		$r->warn("ADMIN: adding hostname for resource") unless ($Apache::FilteringProxy::logging < 2);

		use DBI;
		my $dbh = DBI->connect("dbi:$Apache::FilteringProxy::db_driver:dbname=$Apache::FilteringProxy::db_database;host=$Apache::FilteringProxy::db_hostname;port=$Apache::FilteringProxy::db_hostport",$Apache::FilteringProxy::db_username,$Apache::FilteringProxy::db_password,{ RaiseError => 1, AutoCommit => 1 });

		# get all current hosts in admin to make sure we dont add the
		# hostname a second time.  The admin tool clears old entries
		# out before starting, so we know all entries in the db are valid
		my $sth = $dbh->prepare("SELECT hostname from admin;");
		$sth->execute();

		# make list of hosts
		my @hostname_list;
		my $hostname;
		$sth->bind_columns(\$hostname);
		while ($sth->fetch()) {
			push(@hostname_list, $hostname);
		}
		if (!grep(/^$remote_servername$/,@hostname_list)) {
			my $sth = $dbh->prepare("INSERT INTO admin (id, hostname) VALUES (nextval('admin_id_seq'), '$remote_servername');");
			$sth->execute();
		}
		$sth->finish();
		$dbh->disconnect();
	}

	# grab the uri that was requested and prepare it to be used to request
	# the document on the remote server
	my $uri = $r->parsed_uri;
	my $path = $uri->path();
	my $unparsed = $uri->unparse();
	my $query = $uri->query || "";
	if ($query) {
		$path .= "?$query";
	} elsif ($unparsed =~ /\?$/) {
		$path .= "?";
	}

	# no remote servername and no resource was caught above, so we redirect
	# user to the default_url page
	if (!$remote_servername) {
		$r->warn("DEBUG: no servername, redirecting to default url '$Apache::FilteringProxy::default_url'") unless ($Apache::FilteringProxy::logging < 2);
		$r->header_out("Location" => $Apache::FilteringProxy::default_url);
		return REDIRECT;
	}

	# in admin mode we want all hosts, not just configured ones to be proxied
	if ($mode ne "admin") {
		# used to make sure all kinds of other domains can't be directly accessed
		# through this script unless they are in the list of configured host or
		# domains
		my $found = 0;
		if (!grep(/^$remote_servername$/, @{$Apache::FilteringProxy::proxy_host_include_list{$resource_id}})) {
			foreach (@{$Apache::FilteringProxy::proxy_domain_include_list{$resource_id}}) {
				$r->warn("DEBUG: testing '$remote_servername' against domain include '$_'") unless ($Apache::FilteringProxy::logging < 2);
				if ($remote_servername =~ m/([A-Za-z0-9\.\-]+\.)*$_$/i) {
					$found = 1;
					last;
				}
			}

			# we didn't find the host in the host include list or domain
			# include list for this resource
			if (!$found) {
				$r->warn("REDIRECTING: a document on an unconfigured host ('$remote_servername') for resource ('$resource_id') has been requested") unless ($Apache::FilteringProxy::logging < 1);
				if (defined($Apache::FilteringProxy::proxy_host_include_list{$resource_id})) {
					$r->warn("REDIRECTING: included hosts for this resource are: ".join(',',@{$Apache::FilteringProxy::proxy_host_include_list{$resource_id}})) unless ($Apache::FilteringProxy::logging < 2);
				}
				if (defined($Apache::FilteringProxy::proxy_domain_include_list{$resource_id})) {
					$r->warn("REDIRECTING: included domains for this resource are: ".join(',',@{$Apache::FilteringProxy::proxy_domain_include_list{$resource_id}})) unless ($Apache::FilteringProxy::logging < 2);
				}
				if (defined($Apache::FilteringProxy::proxy_host_exclude_list{$resource_id})) {
					$r->warn("REDIRECTING: excluded hosts for this resource are: ".join(',',@{$Apache::FilteringProxy::proxy_host_exclude_list{$resource_id}})) unless ($Apache::FilteringProxy::logging < 2);
				}
				if (defined($Apache::FilteringProxy::proxy_domain_exclude_list{$resource_id})) {
					$r->warn("REDIRECTING: excluded domains for this resource are: ".join(',',@{$Apache::FilteringProxy::proxy_domain_exclude_list{$resource_id}})) unless ($Apache::FilteringProxy::logging < 2);
				}

				$r->header_out("Location" => "http://$remote_servername/");
				return REDIRECT;
			}
			
			if (grep(/^$remote_servername$/i, @{$Apache::FilteringProxy::proxy_host_exclude_list{$resource_id}})) {
				$r->warn("REDIRECTING: a document on an excluded host has been requested") unless ($Apache::FilteringProxy::logging < 1);

				$r->header_out("Location" => "http://$remote_servername/");
				return REDIRECT;
			} else {
				foreach (@{$Apache::FilteringProxy::proxy_domain_exclude_list{$resource_id}}) {
					if ($remote_servername =~ m/([A-Za-z0-9\.\-]+.)*$_$/i) {
						$r->warn("REDIRECTING: a document in an excluded domain has been requested") unless ($Apache::FilteringProxy::logging < 1);

						$r->header_out("Location" => "http://$remote_servername/");
						return REDIRECT;
					}
				}
			}
		} else {
			$r->warn("DEBUG: '$remote_servername' was in host include list") unless ($Apache::FilteringProxy::logging < 2);
		}
	}

	# some servers actually barf with a port of 80 specified...let it default =P 
	my $port_string = "";
	if ($remote_port ne "80") {
		$port_string = ":$remote_port";
	}

	$r->warn("requesting document 'http://$remote_servername$port_string$path' via '".$r->method()."' method") unless ($Apache::FilteringProxy::logging < 2);

	# Create a request object to use to fetch data from the remote server
	my $request = HTTP::Request->new ($r->method, "http://$remote_servername$port_string$path");

	# Copy the headers the client gave us into the new request object
	$r->headers_in->do (sub {
		my $name = shift;
		my $value = shift || "";

		$r->warn("client header: '$name'='$value'") unless ($Apache::FilteringProxy::logging < 2);

		my $bad_header = 0;
		foreach (keys %Apache::FilteringProxy::strip_headers) {
			if ($name =~ /$_/) {
				$bad_header = 1;
			}
		}

		if ($bad_header) {
			# these are headers we have in our config file to strip
			$r->warn("stripping header '$name'='$value'") unless ($Apache::FilteringProxy::logging < 2);
		} elsif ($name =~ m/^((proxy-)?authorization)$/i) {
			# we don't want to send these to the server
			$r->warn("ignoring header '$name'='$value'") unless ($Apache::FilteringProxy::logging < 2);
		} elsif ($name =~ /^referer$/i) {
			my $new_value = $value;
			$new_value =~ s/(\.port[0-9]{1,5})?\.[^.]+\.$local_servername([^a-zA-Z0-9\-\.])/$2/;

			$r->warn("translating referer '$value' => '$new_value'") unless ($Apache::FilteringProxy::logging < 2);

			$request->header ('Referer', $new_value);
		} elsif ($name =~ /^(accept)$/i) {
			# FIXME - any mangling required for accept header?
			$request->header ($name, $value);
		} elsif ($name =~ /^(host)$/i) {
			# note - LWP automatically adds a host header
			my $new_value = $value;
			$new_value =~ s/(\.port[0-9]{1,5})?\.[^.]+\.$local_servername$//;

			$r->warn("translating hostname '$value' => '$new_value'") unless ($Apache::FilteringProxy::logging < 2);

			$request->header ('Host', $new_value);
		} elsif ($name =~ /^(cookie)$/i) {
			# strip session cookie information here if needed we don't want to
			# send cookies that were delivered to us by the browser because the
			# cookie is in our domain.  Strip anything that wasn't intended for
			# the remote domain we are proxying

			my %cookiehash;
			my @cookies = split(/\s*;\s*/, $value);
			foreach (@cookies) {
				$_ =~ /(\S*)\s*=\s*(\S*)/;
				$cookiehash{$1} = $2;
			}

			foreach (keys %Apache::FilteringProxy::strip_cookies) {
				$r->warn("stripping any cookies with name '$_'") unless ($Apache::FilteringProxy::logging < 2);
				if (exists($cookiehash{$_})) {
					$r->warn("stripped cookie '$_'='$cookiehash{$_}'") unless ($Apache::FilteringProxy::logging < 2);
					delete($cookiehash{$_});
				}
			}

			$value = "";
			foreach (keys %cookiehash) {
				$value .= "$_=".$cookiehash{$_}."; ";
			}

			$r->warn("new cookie data is '$name'='$value'") unless ($Apache::FilteringProxy::logging < 2);

			# Cookie headers may occur multiple times
			if ($value =~ /\S/) {
				$request->push_header ($name, $value);
			}
		} else {
			# push remaining headers as long as they aren't in our bad
			# list, because some of them will cause problems
			#
			# user-agent      - we will set this later
			# accept-encoding - we don't want to get encoded (gzip, compressed)
			#                   content & try to filter it
			# don't need to be kept by a proxy (affect only the immediate
			# connection)
			#     connection, keep-alive, TE, Trailers, Transfer-Encoding,
			#     Upgrade, Proxy-Authenticate, Proxy-Authorization
			if ($name !~ m/^(connection|keep-alive|user-agent|te|trailers|transfer-encoding|accept-encoding|upgrade|proxy-authenticate|proxy-authorization)$/i) {
				$request->header ($name, $value)
			} else {
				$r->warn("ignoring header '$name'='$value'") unless ($Apache::FilteringProxy::logging < 2);
			}
		}

		return 1;
	});

	# set this X-header so that aware developers/servers can be intelligent
	# when working with us.  May need to be removed if at some point this is
	# used by someone to deny access/foil our attempts to proxy.
	$request->header('X-FilteringProxy', '1');

	# If method is POST, we have to grab the posted data and stick it into
	# the request object to be sent with the request to the remote server
	if ($r->method eq 'POST') {
		my $len = $r->header_in('Content-length');
		my $content;
		$r->read($content, $len);
		$request->content($content);
	}

	# create our user agent object to prepare our request to the remote server
	my $ua = __PACKAGE__->new;

	# if we have defined a proxy, then make the actual requests using that
	# proxy by telling our user agent object what proxy to use
	if (defined($Apache::FilteringProxy::proxy_url) && $Apache::FilteringProxy::proxy_url) {
		$ua->proxy('http', $Apache::FilteringProxy::proxy_url);
	}

	# set our user agent to be the user agent that the client told us it was
	my $agent = $r->header_in ('User-agent');
	$ua->agent ($agent ? $agent : '');

	# now initiate a transation with the remote server (get the data).
	# we will take the data retrieved, read it in and send the data back to
	# the client, after filtering it if we are supposed to.
	my $response = $ua->request ($request);

	$r->warn("response code is '".$response->code."'") unless ($Apache::FilteringProxy::logging < 2);

	if ($response->is_error()) {
		# something died (remote server, network, etc.)
		# send back the HTTP::Response object's error_as_HTML() message.
		$r->content_type ('text/html');
		$r->print($response->error_as_HTML());
		$r->rflush;

		$r->warn("there was an error retreiving the document, dumping error: '".$response->error_as_HTML()."'") unless ($Apache::FilteringProxy::logging < 1);

		return OK;
	}

	# set our status and status line
	$r->status ($response->code());
	$r->status_line ($response->status_line());

	$r->warn("response code/message/status_line: '".$response->code()."','".$response->message()."','".$response->status_line()."'") unless ($Apache::FilteringProxy::logging < 2);

	# now we copy headers from the request back into our $r request object
	# for the client after filtering/modifying appropriate data..
	$response->scan (sub {
		my $name = shift;
		my $value = shift || "";

		# get filtered header data
		my $new_value = filter_header($r, $name, $value);

		# we only send the header back to the client if it is defined.  an
		# undefined value indicated that our filter_header function told us
		# that we should remove it from the list
		if (defined($new_value)) {
			$r->warn("server headers: '$name'='$value' => '$new_value'") unless ($Apache::FilteringProxy::logging < 2);

			if (($name =~ /^pragma$/i) and ($new_value =~ /^no-cache$/i)) {
				$r->warn("setting no_cache(1) since we recieved a pragma='no-cache' header") unless ($Apache::FilteringProxy::logging < 2);

				# indirectly set the no-cache headers for the client
				$r->no_cache(1);
			} elsif ($name =~ m/^(location|content-type|transfer-encoding|last-modified|set-cookie)$/i) {
				$r->warn("setting CGI header '$name'='$new_value'") unless ($Apache::FilteringProxy::logging < 2);

				$r->cgi_header_out($name, $new_value);
			} else {
				$r->warn("setting header '$name'='$new_value'") unless ($Apache::FilteringProxy::logging < 2);

				$r->header_out($name, $new_value);
			}
		} else {
			# not sending this header back
			$r->warn("server headers: '$name'='$value' => 'undefined'") unless ($Apache::FilteringProxy::logging < 2);
		}
	});

	# Initialize $content here 
	my $content_ref = $response->content_ref();
	if (!defined($$content_ref)) {
		$$content_ref = "";
	}

	my $content_type = $response->content_type() || "";

	if ($r->header_only) {
		# send headers, but no body.  Because we can't know whether this page
		# is going to be altered or not, after filtering, we can't tell the
		# client whether to accept ranges or not.  So strip out accept-ranges
		# headers when this is a content type that is supposed to be filtered
		if ($Apache::FilteringProxy::filter_types{$r->content_type()}) {
			$r->headers_out->unset('Accept-ranges');
		}

		$r->send_http_header();
		return OK;
	}

	# if we want to filter this type of content and there is content
	if ($content_type and $$content_ref and
        $Apache::FilteringProxy::filter_types{$content_type})
	{
		# filter the content
		filter_data($r, $content_ref);

		# reset the content-length header to make sure we have accurate
		# length, which may have changed after filtering
		$r->header_out('Content-length', length($$content_ref));

		# can't use ranges or xsums if we're messing with content, so remove
		$r->headers_out->unset('Accept-ranges');
		$r->headers_out->unset('Content-MD5');
	}

	$r->warn("----- DEBUG HEADER REQUEST-----\n".$r->as_string()."\n-------------------------\n") unless ($Apache::FilteringProxy::logging < 2);
	$r->warn("----- DEBUG HEADER TRANSLATED REQUEST -----\n".$request->as_string()."\n-------------------------\n") unless ($Apache::FilteringProxy::logging < 2);
	$r->warn("----- DEBUG SOURCE -----\n".$$content_ref."\n-------------------------\n") unless ($Apache::FilteringProxy::logging < 3);

	$r->send_http_header();
	$r->print ($$content_ref);
	$r->rflush;

	return OK;
}

# filter_header
#
# Run a given MIME header value through the filter_data subroutine
# and set $r->header_out ($name, $value) to hold the result.
#
sub filter_header {
	my $r = shift;
	my $name = shift;
	my $value = shift || "";

	$r->warn("filtering header '$name'='$value'") unless ($Apache::FilteringProxy::logging < 2);

	if ($name =~ m/^(location|content-location|content-base|uri|refresh|)$/i) {
		# filter redirects so we don't get shot off to a server not proxies
		# by us unintentionally and any other data containing domains or URLs
		my $val_ref = filter_data($r, \$value);
	} elsif ($name =~ m/^content-type$/i) {
		# here we are going to see if we need to translate any content-types
		# since it is the easiest place to do it
		my $content_type = "";
		my $charset = "";

		if (defined($value)) {
			$content_type = $value;
			if ($content_type =~ s/(;.*)//) {
				$charset = $1;	
			}
		}
		
		$r->warn("determining if content-type '".$content_type."' needs to be translated...") unless ($Apache::FilteringProxy::logging < 1);
		if (exists($Apache::FilteringProxy::type_translations{$content_type})) {
			$r->warn("content-type '".$content_type."' needs to be translated") unless ($Apache::FilteringProxy::logging < 1);
			if (defined($Apache::FilteringProxy::type_translations{$content_type})) {
				$r->warn("caught and translated type '".$content_type.$charset."' to '".$Apache::FilteringProxy::type_translations{$content_type}.$charset."'") unless ($Apache::FilteringProxy::logging < 1);
				$r->content_type($Apache::FilteringProxy::type_translations{$content_type}.$charset);
				$value = $Apache::FilteringProxy::type_translations{$content_type}.$charset;
			}
		}
	} elsif ($name =~ m/^set-cookie$/i) {
		# set the domain for this cookie to our local domain so that we can
		# intercept all these cookies and filter later
		my $s = $r->server;
		my $local_hostname = $r->hostname();
		$local_hostname =~ m/.*(\.port(\d+))?\.([^.]+)\.$local_servername$/;
		my $resource_id = $3;
		my $port = $2 || "";

		if ($port) {
			# include the port in the cookie domain setting
			$value =~ s/(^\s*|;\s*)domain\s*=\s*([^\s;]*)(\s*$|\s*;)/$1domain=$2.port$port.$resource_id.$local_servername$3/i;
		} else {
			$value =~ s/(^\s*|;\s*)domain\s*=\s*([^\s;]*)(\s*$|\s*;)/$1domain=$2.$resource_id.$local_servername$3/i;
		}

		# filter the cookie data if this resource is configured to allow it
		if ($Apache::FilteringProxy::filter_cookie_list{$resource_id}) {
			my $val_ref = filter_data ($r, \$value);
		} else {
			$r->warn("skipping cookie filtering for '$resource_id' cookie") unless ($Apache::FilteringProxy::logging < 2);
		}
	} else {
		# remove headers added by LWP (client-date, client-peer, title,
		# proxy-authenticate).  Also connection and transfer-encoding
		# settings, as apache will handle these on its own.
		if ($name =~ m/^(client-(date|peer|warning)|upgrade|proxy-authenticate)$/i) {
			$r->warn("removed header '$name'='$value'") unless ($Apache::FilteringProxy::logging < 2);

			# tell caller we want to remove this
			return undef;
		}
	}

	$r->warn("filtered header '$name'='$value'") unless ($Apache::FilteringProxy::logging < 2);

	# this may or may not be used by the caller
	return $value;
}

# filter_data
#
# much fun taking data and translating all absolute URLs to the format we need
# to do all sorts of nifty handling later.  We translate all URLs that are
# supposed to be caught by our proxy by taking on our subdomain to the domain
# of the URL and add in port information to be processed later.
#
sub filter_data {
	my $r = shift;
	my $data_ref = shift;
	my $s = $r->server;

	# check first for empty data
	if (not $$data_ref) {
		return "";
	}

	# get the local server information to use for determining what resource
	# the user is trying to access
	my $server = $r->server;
	my $local_hostname = $r->hostname();
    my $local_port = $s->port() ? ($s->port()) : '';

	# find our remote servername, port and resource id from the hostname
	$local_hostname =~ m/(.*)$local_servername$/;
	my $remote_string = $1 || "";
	my ($remote_servername, $remote_port, $resource_id);
	if ($remote_string) {
		if ($remote_string =~ m/(.*)\.port(\d{1,5})\.([^.]+)\.$/) {
			$remote_servername = $1;
			$remote_port = $2;
			$resource_id = $3;
		} else {
			$remote_string =~ s/\.([^.]+)\.$//;
			$resource_id = $1;
			$remote_servername = $remote_string;
			$remote_port = 80;
		}
	}
	
	# filtering for all hosts specifically allowed
	my $host;
	if ($mode ne "admin") {
		foreach $host (@{$Apache::FilteringProxy::proxy_host_include_list{$resource_id}}) {
			$r->warn("DEBUG: translating host_include '$host' for '$resource_id'") unless ($Apache::FilteringProxy::logging < 3);
			$$data_ref =~ 
				s@
					((http(:|%3A)(/|%2F)+) 						# http://
					($host)  									# hostname
					((:|%3A)([0-9]{1,5}))?      				# :port
					(?!%3A|%2E|%2D|%5F|[A-Za-z0-9:\.\-_]))		# make sure we have end of host/port
				@
					my $url = $1;
					my $http_string = $2;
					my $hostname = $5;
					my $port_string = $6 || "";
					my $port = $8 || "";

					# make sure we don't proxy anything that is a part of
					# this local domain
					if ($hostname !~ /^(.*\.)?$local_servername$/) {
						$r->warn("DEBUG: translating url '$url' => '$http_string$hostname".($port ? ".port$port" : "") . ".$resource_id.$local_servername' for '$resource_id'") unless ($Apache::FilteringProxy::logging < 4);

						"$http_string$hostname" .				# http://hostname
						($port ? ".port$port" : "") .			# .port12345
						".$resource_id.$local_servername"
					} else {
						$r->warn("DEBUG: translating url '$url' => '$http_string$hostname$port_string' for '$resource_id'") unless ($Apache::FilteringProxy::logging < 4);

						"$http_string$hostname$port_string"
					}
				@xiges;
		}
	} elsif ($mode eq "mirror") {
		foreach my $resource (keys %Apache::FilteringProxy::proxy_host_include_list) {
			foreach $host (@{$Apache::FilteringProxy::proxy_host_include_list{$resource}}) {
				$r->warn("DEBUG: translating host_include '$host' for '$resource'") unless ($Apache::FilteringProxy::logging < 3);
				$$data_ref =~ 
					s@
						((http(:|%3A)(/|%2F)+) 						# http://
						($host)  									# hostname
						((:|%3A)([0-9]{1,5}))?      				# :port
						(?!%3A|%2E|%2D|%5F|[A-Za-z0-9:\.\-_]))		# make sure we have end of host/port
					@
						my $url = $1;
						my $http_string = $2;
						my $hostname = $5;
						my $port_string = $6 || "";
						my $port = $8 || "";

						# make sure we don't proxy anything that is a part of
						# this local domain
						if (($hostname !~ /^(.*\.)?$local_servername$/) and
						    ($hostname !~ /^(.*\.)?$resource_domain$/))
						{
							$r->warn("DEBUG: translating url '$url' => '$http_string$hostname".($port ? ".port$port" : "") . ".$resource.$resource_domain' for '$resource'") unless ($Apache::FilteringProxy::logging < 4);

							"$http_string$hostname" .				# http://hostname
							($port ? ".port$port" : "") .			# .port12345
							".$resource.$resource_domain"
						} else {
							$r->warn("DEBUG: translating url '$url' => '$http_string$hostname$port_string' for '$resource'") unless ($Apache::FilteringProxy::logging < 4);

							"$http_string$hostname$port_string"
						}
					@xiges;
			}
		}
	} else {
		$$data_ref =~ 
			s@
				((http(:|%3A)(/|%2F)+) 						# http://
				([A-Za-z0-9\.\-]+)  									# hostname
				((:|%3A)([0-9]{1,5}))?      				# :port
				(?!%3A|%2E|%2D|%5F|[A-Za-z0-9:\.\-_]))		# make sure we have end of host/port
			@
				my $url = $1;
				my $http_string = $2;
				my $hostname = $5;
				my $port_string = $6 || "";
				my $port = $8 || "";

				# make sure we don't proxy anything that is a part of
				# this local domain
				if ($hostname !~ /^(.*\.)?$local_servername$/) {
					$r->warn("DEBUG: translating url '$url' => '$http_string$hostname".($port ? ".port$port" : "") . ".$resource_id.$local_servername' for '$resource_id'") unless ($Apache::FilteringProxy::logging < 4);

					"$http_string$hostname" .				# http://hostname
					($port ? ".port$port" : "") .			# .port12345
					".$resource_id.$local_servername"
				} else {
					$r->warn("DEBUG: translating url '$url' => '$http_string$hostname$port_string' for '$resource_id'") unless ($Apache::FilteringProxy::logging < 4);

					"$http_string$hostname$port_string"
				}
			@xiges;
	}

	# determine if a host is excluded via the host/domain exclude lists for
	# this resource
	sub excluded () {
		my $hostname = shift;
		my $resource_id = shift;
		my $excluded = 0;

		if (!grep(/^$hostname$/, @{$Apache::FilteringProxy::proxy_host_exclude_list{$resource_id}})) {
			# domains we are excluding
			foreach (@{$Apache::FilteringProxy::proxy_domain_exclude_list{$resource_id}}) {
				my $exclude_domain = $_;
				if ("$hostname" =~ /(^|.*\.)$exclude_domain$/i) {
					$excluded = 1;
					last;
				}
			}
		}

		return $excluded;
	}

	# filtering for all hosts included in domains that are specifically
	# allowed and not specifically denied
	my $domain;

	if (($mode ne "admin") and ($mode ne "mirror")) {
		foreach $domain (@{$Apache::FilteringProxy::proxy_domain_include_list{$resource_id}}) {
			$$data_ref =~ 
				s@
					(http(:|%3a|%3A)(\/|%2f|%2F)+) 							# http://
					(?![A-Za-z0-9\.\-]*\.$local_servername)					# don't rewrite previously rewritten URLs
					([A-Za-z0-9\.\-]*\.)?$domain  							# hostname
					((:|%3a|%3A)([0-9]{1,5}))?      						# :port
					(?!%3a|%3A|%2e|%2E|%2d|%2D|%5f|%5F|[A-Za-z0-9:\.\-])	# signaling the host/port end
				@
					my $http_string = $1;
					my $hostname = $4 || "";
					my $port_string = $5 || "";
					my $port = $7 || "";

					if (!&excluded("$hostname$domain", $resource_id)) {
						if ($port) {
							$r->warn("DEBUG: translated '$http_string$hostname$domain$port_string'=>'$http_string$hostname$domain.port$port.$resource_id.$local_servername' for '$resource_id'") unless ($Apache::FilteringProxy::logging <= 2);
							"$http_string$hostname$domain.port$port.$resource_id.$local_servername"
						} else {
							$r->warn("DEBUG: translated '$http_string$hostname$domain$port_string'=>'$http_string$hostname$domain.$resource_id.$local_servername' for '$resource_id'") unless ($Apache::FilteringProxy::logging <= 2);
							"$http_string$hostname$domain.$resource_id.$local_servername"
						}
					} else {
						$r->warn("DEBUG: excluded '$hostname$domain' for resource '$resource_id'") unless ($Apache::FilteringProxy::logging < 2);
						"$http_string$hostname$domain$port_string"
					}
				@xiges;
		}
	} elsif ($mode eq "mirror") {
		$r->warn("DEBUG: mirror: translating domains in mirror mode") unless ($Apache::FilteringProxy::logging <= 2);
		foreach my $resource (keys %Apache::FilteringProxy::proxy_domain_include_list) {
			$r->warn("DEBUG: mirror: translating domains for resource '$resource'") unless ($Apache::FilteringProxy::logging <= 2);
			foreach $domain (@{$Apache::FilteringProxy::proxy_domain_include_list{$resource}}) {
				$$data_ref =~ 
					s@
						(http(:|%3a|%3A)(\/|%2f|%2F)+) 							# http://
						(?![A-Za-z0-9\.\-]*\.$local_servername)					# don't rewrite previously rewritten URLs
						(?![A-Za-z0-9\.\-]*\.$resource_domain)					# don't rewrite previously rewritten URLs
						([A-Za-z0-9\.\-]*\.)?$domain  							# hostname
						((:|%3a|%3A)([0-9]{1,5}))?      						# :port
						(?!%3a|%3A|%2e|%2E|%2d|%2D|%5f|%5F|[A-Za-z0-9:\.\-])	# signaling the host/port end
					@
						my $http_string = $1;
						my $hostname = $4 || "";
						my $port_string = $5 || "";
						my $port = $7 || "";

						if (!&excluded("$hostname$domain", $resource)) {
							if ($port) {
								$r->warn("DEBUG: translated '$http_string$hostname$domain$port_string'=>'$http_string$hostname$domain.port$port.$resource.$resource_domain' for '$resource'") unless ($Apache::FilteringProxy::logging <= 2);
								"$http_string$hostname$domain.port$port.$resource.$resource_domain"
							} else {
								$r->warn("DEBUG: translated '$http_string$hostname$domain$port_string'=>'$http_string$hostname$domain.$resource.$resource_domain' for '$resource'") unless ($Apache::FilteringProxy::logging <= 2);
								"$http_string$hostname$domain.$resource.$resource_domain"
							}
						} else {
							$r->warn("DEBUG: excluded '$hostname$domain' for resource '$resource'") unless ($Apache::FilteringProxy::logging < 2);
							"$http_string$hostname$domain$port_string"
						}
					@xiges;
			}
		}
	}

	# perform all translations specified in the configuration file
	if (defined(%Apache::FilteringProxy::translations)) {
		my ($key, $value);

		# replace all occurences of "match" with "replace" in data
		foreach $key (keys %Apache::FilteringProxy::translations) {
			$value = $Apache::FilteringProxy::translations{$key};
			$$data_ref =~ s/$key/$value/gs
		}

		# replace all occurences of "match" with "replace" in data,
		# accounting for urlencoded data
		foreach $key (keys %Apache::FilteringProxy::translations) {
			$value = $Apache::FilteringProxy::translations{$key};
			$value = quotemeta($value);

			# FIXME - better translation.  determine encoded/non-encoded use
			# and then encode ours the same way.  probably need more
			# configuration options for this down the line

			# create a regex to compensate for possible urlencoded data
			# that needs translating
			$key =~ s/ /(+| )/;
			$key =~ s/([^a-zA-Z0-9])/'('.quotemeta($1).'|%'.unpack("H2",$1).')'/gse;

			eval("\$\$data_ref =~ s/$key/$value/s");
		}
	}

	# finally done
	return $data_ref;
}

1;
__END__

=head1 NAME

Apache::FilteringProxy - A configurable rewriting proxy module for HTTP
servers in mod_perl.

=head1 SYNOPSIS

Add the following to an Apache VirtualHost config:

    <VirtualHost ...>
        # domain with a wildcard subdomain alias (ooo...tricky)
        ServerName *.resources.somedomain.com

        ServerAdmin root@localhost.localdomain

        # some document root...empty or whatever you want to be seen if
        # mod_perl gets disabled or something similar
        DocumentRoot /var/www/html

        SetHandler  perl-script
        PerlHandler Apache::FilteringProxy
        PerlSetVar FilteringProxyMode normal
        PerlSetVar FilteringProxyConfig /some/absolute/path/to/config.xml

        ErrorLog /var/log/httpd/resources.somedomain.com-error_log
        CustomLog /var/log/httpd/resources.somedomain.com-access_log \
                  combined
    </VirtualHost>

Modify resources in the configuration file specified in
FilteringProxyConfig.

    # make slashdot.org available via myslashdot.resources.somedomain.com
    <resource id="myslash" name="MySlash" url="http://www.slashdot.org">
        <host-include>slashdot.org</host-include>
        <domain-include>someotherdomain.com</domain-include>
    </resource>

Three modes are offered with this module (normal, admin, and mirror).
    
=head1 DESCRIPTION

The I<Apache::FilteringProxy> module provides a rewriting proxy for HTTP
servers.  This module was originally created to allow remote access of
resources that are restricted to using IP-based authentication.

=head2 Requirements

Perl modules:
    LWP::UserAgent
    XML::EasyOBJ
    DBI (for admin mode)

The ability to configure a wildcard subdomain
    i.e.  *.subdomain.apu.edu (example use below)

=head2 Modes

Three modes are offered with this module (normal, admin, and mirror).
    
"normal" mode is used for a specific resource that will be limited to
proxying a finite number of hosts/domains.

"admin" mode is used to configure a resource that will proxy every
host/domain that it encounters by rewriting *all* HTTP URLs.  The
main purpose for this mode is to allow for interactive additions of
new resources.  It is used by the administrative tool bundled with the
module.

"mirror" mode is used for a site that contains URLs you need to have
rewritten into the proper proxied URLs.  For instance, you have a page
that contains URLs for slashdot (e.g. http://slashdot.org/) and you
have configured a resource named "myslashdot" which includes the domain
"slashdot.org".  All instances of http://slashdot.org/blah would be
rewritten to ~ http://myslashdot.resources.somedomain.com/blah.  So if
perchance you have multiple resources with the same host or domain
specified in their configuration, then the first will be used.

=head2 Examples

Example configuration for a normal proxied site:

    <VirtualHost ...>
        # domain with a wildcard subdomain alias (ooo...tricky)
        ServerName *.resources.somedomain.com

        ServerAdmin root@localhost.localdomain

        # some document root...empty or whatever you want to be seen if
        # mod_perl gets disabled or something similar
        DocumentRoot /var/www/html

        SetHandler  perl-script
        PerlHandler Apache::FilteringProxy
        PerlSetVar FilteringProxyMode normal
        PerlSetVar FilteringProxyConfig /some/absolute/path/to/config.xml

        ErrorLog /var/log/httpd/resources.somedomain.com-error_log
        CustomLog /var/log/httpd/resources.somedomain.com-access_log \
                  combined
    </VirtualHost>

Example configuration for a mirror proxied site:

    <VirtualHost ...>
        # domain with a wildcard subdomain alias (ooo...tricky)
        ServerName *.mirror.somedomain.com
        ServerAlias mirror.somedomain.com

        ServerAdmin root@localhost.localdomain

        # some document root...empty or whatever you want to be seen if
        # mod_perl gets disabled or something similar
        DocumentRoot /var/www/html

        SetHandler  perl-script
        PerlHandler Apache::FilteringProxy
        PerlSetVar FilteringProxyMode mirror
        PerlSetVar FilteringProxyServername somedomain.com
        PerlSetVar FilteringProxyResourceDomain resources.somedomain.com
        PerlSetVar FilteringProxyConfig /some/absolute/path/to/config.xml

        ErrorLog /var/log/httpd/mirror.somedomain.com-error_log
        CustomLog /var/log/httpd/mirror.somedomain.com-access_log \
                  combined
    </VirtualHost>

Example configuration for an admin proxied site:

    <VirtualHost ...>
        # domain with a wildcard subdomain alias (ooo...tricky)
        ServerName *.admin.somedomain.com

        ServerAdmin root@localhost.localdomain

        # some document root...empty or whatever you want to be seen if
        # mod_perl gets disabled or something similar
        DocumentRoot /var/www/html

        SetHandler  perl-script
        PerlHandler Apache::FilteringProxy
        PerlSetVar FilteringProxyMode admin
        PerlSetVar FilteringProxyServername somedomain.com
        PerlSetVar FilteringProxyConfig /some/absolute/path/to/config.xml

        ErrorLog /var/log/httpd/admin.somedomain.com-error_log
        CustomLog /var/log/httpd/admin.somedomain.com-access_log \
                  combined
    </VirtualHost>

=head1 NOTES

Why we use a subdomain and not URI mapping:

    Much easier to translate all absolute (http://) URLs we run into
    than it is to try and catch all root relative (/) URLs

Why we use a wildcard subdomain:

    Who wants to have a hundred vhosts for proxying and have to restart 
    apache on every change?  Both multiple vhosts and multiple ports
    get old pretty quick.

=head1 COMPATIBILITY

This module still does not yet implement caching abilites and may never do so.
Configure it to use a real proxy if this is important to you.

=head1 SEE ALSO

=head2 HTTP 1.1 RFC

http://www.w3.org/Protocols/rfc2616/rfc2616.html

=head2 mod_perl Documentation

http://perl.apache.org/

=head1 AUTHOR

David Castro <dcastro@apu.edu>

=head1 COPYRIGHT

Copyright (C) 2000-2002 David Castro <dcastro@apu.edu>
Azusa Pacific University

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 
59 Temple Place, Suite 330, Boston, MA 02111-1307 USA


=cut
