package Apache::RandomLocation;

use strict;
use vars qw($VERSION);

use Apache::Constants qw(OK DECLINED REDIRECT SERVER_ERROR);
use CGI qw(:html2 start_form end_form submit param popup_menu);
$VERSION = '0.5';

sub handler {
  my ($r) = shift;

# determine the type requested and path information, if applicable
# $mirror will uniquely identify the <Location> directive
  my $mirror = $r->location;
  my $uri = $r->uri;
  (my $request = $uri) =~ s!$mirror(.*)!$1!;

# get ConfigFile, Type, and BaseUrl variables from PerlSetVar
  my ($configfile, $type, $site_info);


  $type = lc $r->dir_config("Type") || 'file';
  if ( $type !~ /^(file|mirror)$/ ) {
    $r->log_error("Type variable $type not recognized");
    return SERVER_ERROR;
  }

  $configfile = $r->dir_config('ConfigFile') || '';
  if ($configfile =~ m!^~!) {
    (my $home = $request) =~ s!(.*)/[^/]+!$1!;
    my $home_dir = $r->lookup_uri($home)->filename;
    $configfile =~ s!^~!$home_dir!;
    $mirror = $uri;
  }
  if ( ($type eq "mirror") and (!$configfile) ) {
    $r->log_error("A configuration file must be specified for Type mirror");
    return SERVER_ERROR;
  }

  my $baseurl = $r->dir_config('BaseURL') || '/';
  $baseurl .= "/" unless substr($baseurl, -1, 1) eq '/';

  # get the real directory from $baseurl, assuming $baseurl
  # points to a directory on the local server
  my $local_server = $r->server->server_hostname;
  my $dir;
  if ($baseurl =~ m!^~!) {
    (my $home = $request) =~ s!(.*)/[^/]+!$1!;
    $baseurl =~ s!^~!$home!;
    $dir = $r->lookup_uri($baseurl)->filename;
    $mirror = $uri;
  }
  elsif ($baseurl !~ m!^http://!) {
    $dir = $r->lookup_uri($baseurl)->filename;
  }
  elsif ($baseurl =~ m!^http://$local_server!) {
    (my $local_base = $baseurl) =~ s!^http://$local_server(.*)!$1!;
    $local_base = '/' unless ($local_base =~ m!^/!);
    $dir = $r->lookup_uri($local_base)->filename;
  }
  else {
    $dir = '';
  }

# if $main::Apache::RandomLocation::site_info doesn't exist, create it,
# using $mirror to unizuely identify it, based on the <Location> directive
  if (! $main::Apache::RandomLocation::site_info{$mirror} ) {
    unless ( read_config($r, $type, $mirror, $dir, $configfile) ) {
      $r->log_error("An error occurred in reading $configfile");
      return SERVER_ERROR;
    } 
  }
# set $site_info
  unless ($site_info = $main::Apache::RandomLocation::site_info{$mirror} ) {
    $r->log_error("Can't read \$main::Apache::RandomLocation::site_info{\$mirror}: $!");
    return SERVER_ERROR;
  }

# if param('site') exists, it came from a manual selection,
# so redirect the user there
  if ( param('site') ) {
    my $site = param('site');
    my $url = "$site_info->{$site}[0]$site/$site_info->{$site}[2]/";

# for testing purposes    
#    $r->send_http_header;
#    $r->print($url);
#    return OK;

    $r->send_cgi_header("Location: ${url}\015\012\015\012");
    return OK;
  }

# if the following is satisfied, the user wants a list of locations.
# Present a form with those listed
  elsif (  ($type eq 'mirror') and (! $request) ) {
    
    # get the host name, so the default site is one nearby
    my $host = lc $r->get_remote_host;
    if (( ! $host ) or ( $host =~ /^\d+\.\d+\.\d+\.\d+$/ )) {
      my $ip = $r->connection->remote_ip;
      $host = lc host_name($ip) || 'localhost';
    }
    my $country_code = country_code($host);
    my $default = get_site($country_code, $site_info);
    my @list =  # order the list by country code, then alphebetically
      map { $_->[0] }  
    sort { $a->[1] cmp $b->[1] or $a->[0] cmp $b->[0] } 
    map { [ $_, /.*\.(\w+)$/] }  
    keys %{$site_info};
    
    # output the form
    $r->print(start_html('-title' => 'Manual selection',
			 '-dtd' => '-//W3C//DTD HTML 3.2//EN',
			 'BGCOLOR' => '#FFFFFF',
			 'TEXT' => '#OOOOOO',
			 'LINK' => '#0000FF',
			 'VLINK' => '#000080',
			 'ALINK' => '#FF0000'),
	      h2('Manual Selection'),
	      start_form(),
	      "From this page, you can manually choose a site: ",
	      p,
	      popup_menu( '-name' => 'site',
			  '-values' => \@list,
			  '-default' => $default), 
	      p, 
	      submit('-value' => "Select site"),
	      end_form(),
	      end_html()
	     );

    
  }

# the user has specified a file or location request
  else {
    
    my $url;
    
    if ( $type eq 'file' ) {
      my $file = $site_info->[ int rand @{$site_info} ];
      $url = ($baseurl =~ m!^http://!) ? "${baseurl}${file}" : "http://${local_server}${baseurl}${file}";
# redirect the client
#      $r->send_cgi_header("Location: ${baseurl}${file}\015\012\015\012");
#      return REDIRECT;
# Instead of the preceding two lines, the following can be used.
# This saves one request to the server.

      $r->internal_redirect_handler("${baseurl}${file}");
      return OK;
    }

    else {
      my $host = lc $r->get_remote_host;
      if (( ! $host ) or ( $host =~ /^\d+\.\d+\.\d+\.\d+$/ )) {
	my $ip = $r->connection->remote_ip;
	$host = lc host_name($ip) || 'localhost';
      }
      my $country_code = country_code($host);
      my $site = get_site($country_code, $site_info);
      $url = "$site_info->{$site}[0]$site/$site_info->{$site}[2]${request}";
# redirect the client
      $r->send_cgi_header("Location: ${url}\015\012\015\012");
      return REDIRECT;
    }

# for testing purposes
#    $r->send_http_header;
#   $r->print($url);
#    return OK;

    
  }

}

# gets the country code, based on the domain name
sub country_code {
  my ($country_code) = @_;
  if (( $country_code =~ /^\d+\.\d+\.\d+\.\d+$/) or ($country_code !~ /\./) ){
    $country_code = '(com|edu|net|org|us)';
  }
  else {
    $country_code =~ s/.*\.(\w+)$/$1/;
    if (lc $country_code =~ /^(com|edu|net|org|us)$/) {
      $country_code = '(com|edu|net|org|us)';
    }
  }
  return $country_code;
}

# searches through all the available sites, and chooses a random
# one nearby. If one doesn't exist, a random site with country code
#  /^(com|edu|net|org|us)$/ is chosen
sub get_site {
  my ($country_code, $site_info) = @_;
  my (@sites, @all_sites);
  foreach my $host ( keys %{$site_info} ) {
    push @sites, $host if ($site_info->{$host}[1] =~ /^$country_code$/);
    if (!@sites) {
      push @all_sites, $host if ($site_info->{$host}[1] =~ /^(com|edu|net|org|us)$/);
    }
  }
  my $site;
  if (@sites) {
    $site = $sites[rand(@sites)];
  } 
  else {
    $site = $all_sites[rand(@all_sites)]
  }
  return $site;
}

# looks up the host name, if the ip address is given
sub host_name {
  my ($addr) = @_;
  my @b;
  
  if (@b = ($addr =~ /(\d+)\.(\d+)\.(\d+)\.(\d+)/)) {
    return scalar gethostbyaddr(pack('C4', @b), 2);
  }
  return 0;
}

# reads ConfigFile, putting the result in $site_info, which is
# then set to  $main::Apache::RandomLocation::site_info{$mirror}
# For files, $site_info is a reference to an array holding the list
# of files. For mirrors, $site_info is a reference to a hash of arrays,
# with the key being the site amd the array holding, in order, the 
# protocol, country code, and directory 
sub read_config {
  my ($r, $type, $mirror, $dir, $configfile) = @_;
  my $site_info;

  if ( ($type eq 'file') and (! $configfile) ) {
    if ( ! $dir ) {
      $r->log_error("Need to specify ConfigFile for an external BaseURL");
      return 0;
    }
    else {
      unless ( opendir(DIR, $dir)  ) {
	$r->log_error("Cannot read $dir: $!");
	return 0;
      }
      my @globs = grep {not -d and not /^\./} readdir DIR;
      unless ( closedir DIR ) {
	$r->log_error("error closing $dir: $!");
	return 0;
      }
      push @{$site_info}, @globs;
      
    }
    
  }

  else {
    
    unless ( open(FILE, $configfile)  ) {
      $r->log_error("Apache::RandomLocation: cannot read $configfile: $!");
      return 0;
    }
    my @res;
    while (<FILE>)  {
      chomp;
      next if /^\#/;
      next if /^\s*$/;
      
      if ( $type eq 'file' ) {
	my $line = (split)[0];
	if ( $line !~ m!^\s*/.*/\s*$!) {
	  push @{$site_info}, $line;
	}
	else {
	  (my $re = $_) =~ s!^\s*/(.*?)/\s*$!$1!;
	  push @res, $re;
	}
      }
      
      else { 
	my ($info, $supplied_country_code) = split;
	my ($protocol, $site, $directory) = $info =~ m!^(http://|ftp://)*([^/]+)(.*)!;
	$site_info->{$site}[0] = $protocol || 'ftp://';
	($site_info->{$site}[2] = $directory) =~ s!^/!!;
	if (! $supplied_country_code ) {
	  ($site_info->{$site}[1] = $site) =~ s!.*?\.(\w+)$!$1!;
	}
	else {
	  $site_info->{$site}[1] = $supplied_country_code;
	}
      }
      
    }
    
    unless ( close FILE ) {
      $r->log_error("error closing $configfile: $!");
      return 0;
    }

    if (($type eq 'file') and (@res) ) {
      if (! $dir) {
	$r->log_error("Cannot list files on an external BaseURL");
      }
      else {
	unless ( opendir(DIR, $dir)  ) {
	  $r->log_error("Cannot read $dir: $!");
	  return 0;
	}
	foreach my $re (@res) {
	  push @{$site_info}, grep {/$re/} readdir DIR;
	  if (scalar @res > 1) {
	    unless ( rewinddir DIR  ) {
	      $r->log_error("Cannot rewind $dir: $!");
	      return 0;
	    }
	  }
	}
	unless ( closedir DIR ) {
	  $r->log_error("error closing $dir: $!");
	  return 0;
	}
      }
      
    }
  }
  
  if ( ($type eq 'file') and (! @{$site_info}) ) {
     $r->log_error("No files were found");
     return 0;
  }	
  elsif ( ($type eq 'mirror') and (! %{$site_info} )) {
     $r->log_error("No sites were found");
     return 0;
  } 
  else {
     $main::Apache::RandomLocation::site_info{$mirror} = $site_info;
     return 1;
  }
}

1;

__END__

=head1 NAME

Apache::RandomLocation - Perl extension for mod_perl to handle random locations.

=head1 SYNOPSIS

  You can use this in your Apache *.conf files to activate this module.

  <Location /scripts/random-image>
  SetHandler perl-script
  PerlSetVar BaseURL /images/
  PerlSetVar ConfigFile /usr/local/apache/etc/sponsors.txt
  PerlHandler Apache::RandomLocation
  </Location>

  <Location /scripts/CPAN>
  SetHandler perl-script
  PerlSetVar Type mirror
  PerlSetVar ConfigFile /usr/local/apache/etc/cpan_mirrors.txt
  PerlHandler Apache::RandomLocation
  </Location>

=head1 DESCRIPTION

Given a list of locations in B<ConfigFile>, this module will instruct the
browser to redirect to one of them. The locations in B<ConfigFile>
are listed one per line, with lines beginning with # being ignored.
How the redirection is handled depends on the variable B<Type>.

If B<Type> is undefined or set to B<file>, the locations are assumed
to be files. B<BaseUrl>, which can be a full or partial URL, gives the 
location of these files. This can be used to implement, for example,
a banner in an HTML page: <IMG SRC="/scripts/random-image">. The file
chosen is random. Since after one call this image gets cached by the
client, to generate multiple random images on the same page, you could
append different bogus paths after the calling URL, as in
<IMG SRC="/scripts/random-image/1"> and <IMG SRC="/scripts/random-image/2">.

In this case, if B<BaseURL> indicates the local server is being used, 
B<ConfigFile> can contain a perl regular expression (enclosed by B</>,
as in B</\.gif$/>) which will be used to match files in  B<BaseURL>. 
If B<ConfigFile> is not defined, all files in B<BaseUrl> 
will be read. If B<BaseUrl> is undefined, the top level directory 
of the local server is assumed. 

If B<type> is set to B<mirror>, the locations in B<ConfigFile> are
assumed to be mirror sites of some set of files, giving both the
host name and the directory path (eg, ftp.mirror.edu/path/to/dir). 
In this mode the module acts like the CPAN muliplexer code of 
http://www.perl.com/CPAN; for example, 
http://my.host.edu/scripts/CPAN/src/latest.tar.gz will 
redirect to a nearby CPAN mirror to retrieve the file F<src/latest.tar.gz>.
Also like the CPAN multiplexer, a call to the URL
http://my.host.edu/scripts/CPAN (without any trailing slash) will
bring up a form from which one can manually choose a site to go to.

In this case, redirection is made to a random mirror site whose 
country code in the domain name matches that of the client. If no such
mirror exists, a random mirror with country code matching
I<(com|edu|net|org|us)> is selected. For these purposes, clients with 
country codes I<com>, I<edu>, I<org>, I<net>, and I<us> are considered 
equivalent. If a particular mirror site should be considered as having 
a different country code in this regard, add the desired code 
(separated by a space) to the end of the line containing the address 
of the mirror in B<ConfigFile>. If the address of a mirror does not begin 
with I<http://>, the I<ftp://> protocol is assumed.

Information on the locations is stored in a hash, which
survives in each child's memory for the life of the child. This
hash is uniquely associated with the given B<Location> 
directive in *.conf, so that multiple uses of Apache::RandomLocation
modules on one server with different B<Location> directives is
possible.

Like Apache's configuration files, if any changes are made in
B<ConfigFile>, the server must be restarted in order that the
changes take immediate effect; otherwise, one must wait for the
child processes to die in order that the new configuration file
be read in.

=head1 Examples

These directives in access.conf:

  <Location /scripts/random-image>
  SetHandler perl-script
  PerlSetVar BaseURL /images/
  PerlSetVar ConfigFile /usr/local/apache/etc/sponsors.txt
  PerlHandler Apache::RandomLocation
  </Location>

with the following file /usr/local/apache/etc/sponsors.txt:

  apache.jpeg
  mod_perl.jpeg
  /\.gif$/

will use the image files apache.jpeg, mod_perl.jpeg, and any gif image 
in the server location /images. A random image will then be selected with
a call to http://your.server.name/scripts/random-image.


These directives in access.conf:

  <Location /scripts/CPAN>
  SetHandler perl-script
  PerlSetVar Type mirror
  PerlSetVar ConfigFile /usr/local/apache/etc/cpan_mirrors.txt
  PerlHandler Apache::RandomLocation
  </Location>

with the following file /usr/local/apache/etc/cpan_mirrors.txt:

   ftp.funet.fi/pub/languages/perl/CPAN
   ftp.metronet.com/pub/perl
   http://www.perl.com/CPAN
   ftp.utilis.com/pub/perl/CPAN ca

can be used to redirect clients to a (hopefully) nearby random CPAN mirror:
a call to http://your.server.name/scripts/CPAN/src/latest.tar.gz 
will grab the file latest.tar.gz under the $CPAN src/ directory of the
mirror. The ftp:// protocol is assumed for all sites except www.perl.com, 
where http:// is used. For the purpose of matching the country code of the
client with that of the mirrors, ftp.utilis.com is to be considered as 
having the country code of "ca".

If a LocationMatch directive is given as, for example,

  <LocationMatch "/(physics|chemistry|biology)/random-image">
    SetHandler perl-script
    PerlSetVar BaseURL ~/images/
    PerlSetVar ConfigFile ~/images/config.txt
    PerlHandler Apache::RandomLocation
  </LocationMatch>

then the tilde character will be interpreted as the corresponding
home directory (relative to I<DocumentRoot>). For example, with
I<DocumentRoot> equal to I</usr/local/apache/htdocs>, a request
to I</biology/random-image> will use a I<BaseURL> of
I</usr/local/apache/htdocs/biology/images/> and a I<ConfigFile> of
</usr/local/apache/htdocs/biology/images/config.txt>.


=head1 AUTHORS

Matthew Darwin, matthew@davin.ottawa.on.ca

Randy Kobes, randy@theory.uwinnipeg.ca

The mirror redirection code is based on the CPAN multiplexer code
of Tom Christiansen and a similar script by Ulrich Pfeifer.

=head1 SEE ALSO

perl(1), Apache(3), mod_perl(3)

=head1 COPYRIGHT

Copyright 1998, Matthew Darwin, Randy Kobes

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=cut
