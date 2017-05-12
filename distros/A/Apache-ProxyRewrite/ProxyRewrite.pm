# $Id: ProxyRewrite.pm,v 1.14 2002/01/16 15:49:48 cgilmore Exp $
#
# Author          : Christian Gilmore
# Created On      : Nov 10 12:04:00 CDT 2000
# Status          : Functional
#
# PURPOSE
#    Proxy requests and rewrite embedded URLs according to configuration
#
###############################################################################
#
# IBM Public License Version 1.0
#
# THE ACCOMPANYING PROGRAM IS PROVIDED UNDER THE TERMS OF THIS IBM
# PUBLIC LICENSE ("AGREEMENT"). ANY USE, REPRODUCTION OR
# DISTRIBUTION OF THE PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF
# THIS AGREEMENT.
#
# 1. DEFINITIONS
#
# "Contribution" means:
#
#   a) in the case of International Business Machines Corporation
#   ("IBM"), the Original Program, and
#
#   b) in the case of each Contributor,
#
#   i) changes to the Program, and
#
#   ii) additions to the Program;
#
#   where such changes and/or additions to the Program originate from
#   and are distributed by that particular Contributor. A Contribution
#   'originates' from a Contributor if it was added to the Program by
#   such Contributor itself or anyone acting on such Contributor's
#   behalf. Contributions do not include additions to the Program
#   which: (i) are separate modules of software distributed in
#   conjunction with the Program under their own license agreement,
#   and (ii) are not derivative works of the Program.
#
# "Contributor" means IBM and any other entity that distributes the
# Program.
#
# "Licensed Patents " mean patent claims licensable by a Contributor
# which are necessarily infringed by the use or sale of its
# Contribution alone or when combined with the Program.
#
# "Original Program" means the original version of the software
# accompanying this Agreement as released by IBM, including source
# code, object code and documentation, if any.
#
# "Program" means the Original Program and Contributions.
#
# "Recipient" means anyone who receives the Program under this
# Agreement, including all Contributors.
#
# 2. GRANT OF RIGHTS
#
#   a) Subject to the terms of this Agreement, each Contributor hereby
#   grants Recipient a non-exclusive, worldwide, royalty-free
#   copyright license to reproduce, prepare derivative works of,
#   publicly display, publicly perform, distribute and sublicense the
#   Contribution of such Contributor, if any, and such derivative
#   works, in source code and object code form.
#
#   b) Subject to the terms of this Agreement, each Contributor hereby
#   grants Recipient a non-exclusive, worldwide, royalty-free patent
#   license under Licensed Patents to make, use, sell, offer to sell,
#   import and otherwise transfer the Contribution of such
#   Contributor, if any, in source code and object code form. This
#   patent license shall apply to the combination of the Contribution
#   and the Program if, at the time the Contribution is added by the
#   Contributor, such addition of the Contribution causes such
#   combination to be covered by the Licensed Patents. The patent
#   license shall not apply to any other combinations which include
#   the Contribution. No hardware per se is licensed hereunder.
#
#   c) Recipient understands that although each Contributor grants the
#   licenses to its Contributions set forth herein, no assurances are
#   provided by any Contributor that the Program does not infringe the
#   patent or other intellectual property rights of any other entity.
#   Each Contributor disclaims any liability to Recipient for claims
#   brought by any other entity based on infringement of intellectual
#   property rights or otherwise. As a condition to exercising the
#   rights and licenses granted hereunder, each Recipient hereby
#   assumes sole responsibility to secure any other intellectual
#   property rights needed, if any. For example, if a third party
#   patent license is required to allow Recipient to distribute the
#   Program, it is Recipient's responsibility to acquire that license
#   before distributing the Program.
#
#   d) Each Contributor represents that to its knowledge it has
#   sufficient copyright rights in its Contribution, if any, to grant
#   the copyright license set forth in this Agreement.
#
# 3. REQUIREMENTS
#
# A Contributor may choose to distribute the Program in object code
# form under its own license agreement, provided that:
#
#   a) it complies with the terms and conditions of this Agreement;
#
# and
#
#   b) its license agreement:
#
#   i) effectively disclaims on behalf of all Contributors all
#   warranties and conditions, express and implied, including
#   warranties or conditions of title and non-infringement, and
#   implied warranties or conditions of merchantability and fitness
#   for a particular purpose;
#
#   ii) effectively excludes on behalf of all Contributors all
#   liability for damages, including direct, indirect, special,
#   incidental and consequential damages, such as lost profits;
#   iii) states that any provisions which differ from this Agreement
#   are offered by that Contributor alone and not by any other party;
#   and
#
#   iv) states that source code for the Program is available from such
#   Contributor, and informs licensees how to obtain it in a
#   reasonable manner on or through a medium customarily used for
#   software exchange.
#
# When the Program is made available in source code form:
#
#   a) it must be made available under this Agreement; and
#
#   b) a copy of this Agreement must be included with each copy of the
#   Program.
#
# Each Contributor must include the following in a conspicuous
# location in the Program:
#
#   Copyright © {date here}, International Business Machines
#   Corporation and others. All Rights Reserved.
#
# In addition, each Contributor must identify itself as the originator
# of its Contribution, if any, in a manner that reasonably allows
# subsequent Recipients to identify the originator of the
# Contribution.
#
# 4. COMMERCIAL DISTRIBUTION
#
# Commercial distributors of software may accept certain
# responsibilities with respect to end users, business partners and
# the like. While this license is intended to facilitate the
# commercial use of the Program, the Contributor who includes the
# Program in a commercial product offering should do so in a manner
# which does not create potential liability for other Contributors.
# Therefore, if a Contributor includes the Program in a commercial
# product offering, such Contributor ("Commercial Contributor") hereby
# agrees to defend and indemnify every other Contributor ("Indemnified
# Contributor") against any losses, damages and costs (collectively
# "Losses") arising from claims, lawsuits and other legal actions
# brought by a third party against the Indemnified Contributor to the
# extent caused by the acts or omissions of such Commercial
# Contributor in connection with its distribution of the Program in a
# commercial product offering. The obligations in this section do not
# apply to any claims or Losses relating to any actual or alleged
# intellectual property infringement. In order to qualify, an
# Indemnified Contributor must: a) promptly notify the Commercial
# Contributor in writing of such claim, and b) allow the Commercial
# Contributor to control, and cooperate with the Commercial
# Contributor in, the defense and any related settlement negotiations.
# The Indemnified Contributor may participate in any such claim at its
# own expense.
#
# For example, a Contributor might include the Program in a commercial
# product offering, Product X. That Contributor is then a Commercial
# Contributor. If that Commercial Contributor then makes performance
# claims, or offers warranties related to Product X, those performance
# claims and warranties are such Commercial Contributor's
# responsibility alone. Under this section, the Commercial Contributor
# would have to defend claims against the other Contributors related
# to those performance claims and warranties, and if a court requires
# any other Contributor to pay any damages as a result, the Commercial
# Contributor must pay those damages.
#
# 5. NO WARRANTY
#
# EXCEPT AS EXPRESSLY SET FORTH IN THIS AGREEMENT, THE PROGRAM IS
# PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
# ANY KIND, EITHER EXPRESS OR IMPLIED INCLUDING, WITHOUT LIMITATION,
# ANY WARRANTIES OR CONDITIONS OF TITLE, NON-INFRINGEMENT,
# MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. Each Recipient
# is solely responsible for determining the appropriateness of using
# and distributing the Program and assumes all risks associated with
# its exercise of rights under this Agreement, including but not
# limited to the risks and costs of program errors, compliance with
# applicable laws, damage to or loss of data, programs or equipment,
# and unavailability or interruption of operations.
#
# 6. DISCLAIMER OF LIABILITY
#
# EXCEPT AS EXPRESSLY SET FORTH IN THIS AGREEMENT, NEITHER RECIPIENT
# NOR ANY CONTRIBUTORS SHALL HAVE ANY LIABILITY FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING WITHOUT LIMITATION LOST PROFITS), HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
# TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
# THE USE OR DISTRIBUTION OF THE PROGRAM OR THE EXERCISE OF ANY RIGHTS
# GRANTED HEREUNDER, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
# DAMAGES.
#
# 7. GENERAL
#
# If any provision of this Agreement is invalid or unenforceable under
# applicable law, it shall not affect the validity or enforceability
# of the remainder of the terms of this Agreement, and without further
# action by the parties hereto, such provision shall be reformed to
# the minimum extent necessary to make such provision valid and
# enforceable.
#
# If Recipient institutes patent litigation against a Contributor with
# respect to a patent applicable to software (including a cross-claim
# or counterclaim in a lawsuit), then any patent licenses granted by
# that Contributor to such Recipient under this Agreement shall
# terminate as of the date such litigation is filed. In addition, If
# Recipient institutes patent litigation against any entity (including
# a cross-claim or counterclaim in a lawsuit) alleging that the
# Program itself (excluding combinations of the Program with other
# software or hardware) infringes such Recipient's patent(s), then
# such Recipient's rights granted under Section 2(b) shall terminate
# as of the date such litigation is filed.
#
# All Recipient's rights under this Agreement shall terminate if it
# fails to comply with any of the material terms or conditions of this
# Agreement and does not cure such failure in a reasonable period of
# time after becoming aware of such noncompliance. If all Recipient's
# rights under this Agreement terminate, Recipient agrees to cease use
# and distribution of the Program as soon as reasonably practicable.
# However, Recipient's obligations under this Agreement and any
# licenses granted by Recipient relating to the Program shall continue
# and survive.
#
# IBM may publish new versions (including revisions) of this Agreement
# from time to time. Each new version of the Agreement will be given a
# distinguishing version number. The Program (including Contributions)
# may always be distributed subject to the version of the Agreement
# under which it was received. In addition, after a new version of the
# Agreement is published, Contributor may elect to distribute the
# Program (including its Contributions) under the new version. No one
# other than IBM has the right to modify this Agreement. Except as
# expressly stated in Sections 2(a) and 2(b) above, Recipient receives
# no rights or licenses to the intellectual property of any
# Contributor under this Agreement, whether expressly, by implication,
# estoppel or otherwise. All rights in the Program not expressly
# granted under this Agreement are reserved.
#
# This Agreement is governed by the laws of the State of New York and
# the intellectual property laws of the United States of America. No
# party to this Agreement will bring a legal action under this
# Agreement more than one year after the cause of action arose. Each
# party waives its rights to a jury trial in any resulting litigation.
#
###############################################################################


# Package name
package Apache::ProxyRewrite;


# Required libraries
use strict;
use Apache;
use Apache::Constants qw(OK AUTH_REQUIRED DECLINED DONE);
use Apache::Log;
use Apache::URI;
use LWP::UserAgent;
use Socket;
use URI::Escape qw(uri_unescape);


# Global variables
$Apache::ProxyRewrite::VERSION = '0.17';
$Apache::ProxyRewrite::PRODUCT = 'ProxyRewrite/' .
  $Apache::ProxyRewrite::VERSION;
my %LINK_ELEMENTS =
( # These represent all the possible valid tags that have links in them
 'a'       => 'href',
 'applet'  => {
               'archive'    => 1,
               'code'       => 1,
               'codebase'   => 1,
              },
 'area'    => 'href',
 'base'    => 'href',
 'body'    => 'background',
 'embed'   => 'src',
 'form'    => 'action',
 'frame'   => 'src',
 'img'     => {
               'src'        => 1,
               'lowsrc'     => 1,
               'usemap'     => 1,
              },
 'input'   => 'src',
 'isindex' => 'action',
 'link'    => {
               'href'       => 1,
               'src'        => 1,
              },
 'meta'    => {
               'content'    => 1,
               'http-equiv' => 1,
              },
 'object'  => {
               'classid'    => 1,
               'codebase'   => 1,
               'data'       => 1,
               'name'       => 1,
               'usemap'     => 1,
              },
 'script'  => 'src',
 'td'      => 'background',
 'th'      => 'background',
 'tr'      => 'background',
);


###############################################################################
###############################################################################
# handler: hook into Apache/mod_perl API
###############################################################################
###############################################################################
sub handler {
  my $r = shift;
  my %mappings = ();
  my ($auth_info, $auth_redirect, $remote_location) = undef;

  %mappings = split(/\s*(?:=>|,)\s*/, $r->dir_config('ProxyRewrite'));
  $auth_info = $r->dir_config('ProxyAuthInfo');
  $auth_redirect = $r->dir_config('ProxyAuthRedirect') || 'Off';
  if ($r->dir_config('ProxyTo')) {
    $remote_location = $r->dir_config('ProxyTo');
  } else {
    $r->log->error("ProxyRewrite::handler: ProxyTo directive must be defined");
    return DECLINED;
  }

  # Automatically add a mapping for the remote relative URI and the
  # current location. Also capture remote site information.
  $remote_location =~ m!^([^:]+://[^/]+)(/?.*)!;
  my $remote_site = $1;
  if ($2) {
    $mappings{$2} = $r->location;
  } elsif ($r->location eq '/') {
    $mappings{'/'} = $r->location;
  } else {
    $mappings{'/'} = $r->location . '/';
  }

  $r->log->debug("handler: Remote Site - $remote_site");
  $r->log->debug("handler: Remote Location - $remote_location");
  $r->log->debug("handler: Auth Info - $auth_info");
  foreach my $map (keys(%mappings)) {
    # Standardize host on lowercase
    if ($map =~ m!([^:]+://)([^/]+)(.*)!) {
      my $mapping = $mappings{$map};
      delete $mappings{$map};
      my ($protocol, $url_host, $uri) = ($1, $2, $3);
      $url_host =~ tr/A-Z/a-z/;
      $map = $protocol . $url_host . $uri;
      $mappings{$map} = $mapping;
    }
    $r->log->debug("handler: Mapping $map to $mappings{$map}");
  }

  # fetch URL
  $r->log->info("ProxyRewrite: Preparing to fetch ", $r->uri,
		" at time ", time);
  my $response = &fetch($r, $remote_location, $remote_site,
			$auth_info, \%mappings);

  # rewrite response URIs as needed
  $r->log->info("ProxyRewrite: Preparing to rewrite URIs for ", $r->uri,
		" at time ", time);
  if ($response->header('Content-type') =~ m!^text/html!) {
    &parse($r, $remote_site, $response, \%mappings);
  }

  # respond to client
  $r->log->info("ProxyRewrite: Preparing to respond for ", $r->uri,
		" at time ", time);
  &respond($r, $remote_site, $remote_location, $auth_redirect,
	   $response, \%mappings);

  return OK;
}

###############################################################################
###############################################################################
# fetch: fetch the remote URL and return a reference to the response object
###############################################################################
###############################################################################
sub fetch {
  my ($r, $remote_location, $remote_site, $auth_info, $mapref) = @_;
  my $client_agent = '';
  my $my_uri = '';
  my ($k, $v);
  my $base = $r->location();
  my $args = $r->args();
  if ($base ne '/') {
    ($my_uri = $r->uri) =~ s/^$base//;
  } else {
    $my_uri = $r->uri;
  }
  $my_uri = $remote_location . $my_uri;
  $my_uri .= '?' . $r->args() if $args;

  my $request = HTTP::Request->new($r->method, $my_uri);

  $r->log->info("ProxyRewrite::fetch: Time proxy request method created: ", time);
  $r->log->debug("fetch: Base URI (aka location section): $base");
  $r->log->info("ProxyRewrite::fetch: Request for $my_uri with method ", $r->method);

  my(%headers_in) = $r->headers_in;
  while(($k,$v) = each %headers_in) {
    # HACK to force no Keep-Alives on the connection between proxy
    # and remote server
    $r->log->debug("fetch: IN $k: $v");
    if ($k =~ /Connection/) {
      $v = "Close";
    } elsif ($k =~ /Host/) {
      ($v) = ($remote_location =~ m!://([^/]+)!);
    } elsif ($k =~ /User-Agent/) {
      $client_agent = $v;
    }
    $v = uri_unescape($v);
    $request->header($k,$v);	
    $r->log->debug("fetch: IN-MOD $k: $v");
  }

  # If we have authorization information and it isn't already filled in
  if ($auth_info && !$request->authorization()) {
    $request->authorization($auth_info);
  }

  if ($r->method eq "POST") {
    my $content;
    if ($r->headers_in->{'Content-type'} eq 'application/x-www-form-urlencoded') {
      $content = $r->content;
    } else {
      $r->read($content, $r->headers_in->{'Content-length'});
    }
    $request->content($content);
    $r->log->debug("fetch: Request type: ", $r->method);
    $r->log->debug("fetch: Request content type: ",
		   $r->headers_in->{'Content-type'});
    $r->log->debug("fetch: Request content: $content");
  }

  $r->log->debug("fetch: Product: $Apache::ProxyRewrite::PRODUCT");
  my $ua = new LWP::UserAgent;
  if ($client_agent ne '') {
    $ua->agent("$client_agent; $Apache::ProxyRewrite::PRODUCT");
  } else {
    $ua->agent("$Apache::ProxyRewrite::PRODUCT");
  }
  my $res = $ua->simple_request($request);
  $r->log->info("ProxyRewrite::fetch: Time proxy got document: ", time);
  $r->log->info("ProxyRewrite::fetch: Original document size: ",
		length($res->content));

  return($res);
}

###############################################################################
###############################################################################
# parse: parse HTML and find all embedded URLs
###############################################################################
###############################################################################
sub parse {
  my ($r, $remote_site, $response, $mapref) = @_;
  my $buf = $response->content;
  my ($lessthanpos, $greaterthanpos, $prediff, $diff,
      $preblock, $tagblock, $lastblock);
  my $pos = 0;
  my $newbuf = '';
  my $iscomment = 0;
  my $buflen = length($buf);

  while (($lessthanpos = index($buf, "<", $pos)) > -1) {
    # Make a special case out of the comment in case there
    # are nested tags within the comment, such as javascript code
    # fragments. Not necessarily our problem, but it doesn't hurt much
    # to deal with it.
    if (substr($buf, $lessthanpos + 1, 3) eq '!--') {
      $greaterthanpos = index($buf, "-->", $lessthanpos);
      $iscomment = 1;
    } else {
      $greaterthanpos = index($buf, ">", $lessthanpos);
    }
    $prediff = $lessthanpos - $pos;
    $diff = $greaterthanpos - $lessthanpos - 1;
    $preblock = substr($buf, $pos, $prediff + 1);
    $tagblock = substr($buf, $lessthanpos + 1, $diff);
    if ($iscomment == 0) {
      $r->log->debug("parse: Dealing with tag block: $tagblock");
      &dealwithtag($r, $remote_site, \$tagblock, $mapref);
      $r->log->debug("parse: Edited tag block: $tagblock");
    } else {
      $r->log->debug("parse: Skipped comment tag block");
      $iscomment = 0;
    }
    $newbuf .= "$preblock$tagblock";
    $pos = $greaterthanpos;
    # If a tag isn't properly closed at the end of a document, we need to
    # force an end to the loop.
    last if ($pos == -1);
  }
  $lastblock = substr($buf, $pos, $buflen);
  $newbuf .= "$lastblock";

  $response->content($newbuf);
}

###############################################################################
###############################################################################
# dealwithtag: decides if there a URL in a tag and sends it to be rewritten
###############################################################################
###############################################################################
sub dealwithtag {
  my ($r, $remote_site, $tagblock, $mapref) = @_;
  my @blocks;
  my ($tag, $lctag, $key, $lckey, $value, $lcvalue, $delay, $tmp, $i);
  my $done = 0;
  my $refresh = 0;

  # Remove spaces around equal signs, eg 'src = bar' becomes 'src=bar'
  $$tagblock =~ s/\s*(=)\s*/$1/g;
  # Remove all other forms of whitespace in block
  $$tagblock =~ s/(\f|\n|\r|\t)+/ /g;
  # Remove leading spaces in block, eg < img ...> becomes <img ...>
  $$tagblock =~ s/^\s+//;
  # Remove leading and trailing whitespace within quotes
  $$tagblock =~ s/(=[\"\'])\s*/$1/g;
  $$tagblock =~ s/\s*([\"\'])/$1/g;
  @blocks = split(/\s+/, $$tagblock);
  $tag = shift(@blocks);
  $lctag = lc($tag);
  if (exists($LINK_ELEMENTS{$lctag})) {
    $$tagblock = $tag;
    for ($i = 0; $i < @blocks; $i++) {
      if ($blocks[$i] =~ /=/) {
        ($key, $value) = split(/=/, $blocks[$i], 2);
        $lckey = lc($key);
        if ($lctag =~ /(applet|img|link|meta|object)/) {
          if (exists($LINK_ELEMENTS{$lctag}{$lckey})) {
            $value =~ s/(\"|\')//g;
	    if ($lctag eq 'meta') {
	      $lcvalue = lc($value);
	      if ($lckey eq 'http-equiv') {
		if ($lcvalue eq 'refresh') {
		  $refresh = 1;
		}
		$$tagblock .= " $key=\"$value\"";
		next;
	      } else {
		# Must be a content key
		while (!$done && $i < @blocks) {
		  $value .= " $blocks[++$i]";
		  if (1 == ($value =~ s/\"//g)) {
		    $done = 1;
		  }
		}
		$done = 0;
		if ($refresh) {
		  $tmp = $value;
		  $value =~ /(\d)+\;\s*url=([^;\s]+)/i;
		  $delay = $1;
		  $value = $2;
		} else {
		  $$tagblock .= " $key=\"$value\"";
		  next;
		}
	      }
	    }
	    # deal with potential codebase issues
	    if ($lctag eq 'applet' || $lctag eq 'object') {
	      # Must deal with later
	    }
            &rewrite_url($r, $remote_site, \$value, $mapref);
	    if ($lctag eq 'meta' && $refresh) {
	      $refresh = 0;
	      $r->headers_out->{'Refresh'} = "$delay; $value";
	      $tmp =~ s/(url=)[^;\s]+/$1$value/i;
	      $value = $tmp;
	    }
	    # Handle the special case of when the value begins with a port
	    if ($value =~ /^:/) {
	      $$tagblock .= " $key=\"$remote_site$value\"";
	    } else {
	      $$tagblock .= " $key=\"$value\"";
	    }
          } else {
	    $$tagblock .= " $blocks[$i]";
	  }
        } elsif ($lckey eq $LINK_ELEMENTS{$lctag}) {
	  $value =~ s/(\"|\')//g;
	  &rewrite_url($r, $remote_site, \$value, $mapref);
	  # Handle the special case of when the value begins with a port
	  if ($value =~ /^:/) {
	    $$tagblock .= " $key=\"$remote_site$value\"";
	  } else {
	    $$tagblock .= " $key=\"$value\"";
	  }
	} else {
	  $$tagblock .= " $blocks[$i]";
	}
      } else {
        $$tagblock .= " $blocks[$i]";
      }
    }
  }
}

###############################################################################
###############################################################################
# rewrite_url: rewrite URLs as per the mappings hash
###############################################################################
###############################################################################
sub rewrite_url {
  my ($r, $remote_site, $url, $mapref) = @_;

  $r->log->debug("rewrite_url: Looking at rewriting $$url");
  $r->log->debug("rewrite_url: remote_site: $remote_site");

  # Remove remote_site from URI to get just the relative-from-root information
  if ($$url =~ s/^$remote_site//) {
    $r->log->debug("rewrite_url: Shrunk to $$url");
  }

  # Standardize host on lowercase
  if ($$url =~ m!([^:]+://)([^/]+)(.*)!) {
    my ($protocol, $url_host, $uri) = ($1, $2, $3);
    $url_host =~ tr/A-Z/a-z/;
    $$url = $protocol . $url_host . $uri;
  }

  # Ensure we go from most to least specific rewrite
  foreach my $mapping (sort { $b cmp $a } keys(%$mapref)) {
    $r->log->debug("rewrite_url: Testing match of $mapping ",
		   "($$mapref{$mapping})");
    last if ($$url =~ s/^$mapping/$$mapref{$mapping}/);
  }
}

###############################################################################
###############################################################################
# respond: respond to the client
###############################################################################
###############################################################################
sub respond {
  my ($r, $remote_site, $remote_location, $auth_redirect,
      $response, $mapref) = @_;
  my $parsed_uri = Apache::URI->parse($r);

  $r->log->debug("respond: URI: ", $r->uri);
  $r->log->debug("respond: Parsed hostinfo: ", $parsed_uri->hostinfo());

  # feed reponse back into our request_record
  $response->scan(sub {
		    my ($header, $value) = @_;
		    $r->log->debug("respond: OUT $header: $value");
		    if ($header =~ /^Set-Cookie/i) {
		      $value =~ /path=([^;]+)/i;
		      my $cookie_path = $1;
		      &rewrite_url($r, $remote_site, \$cookie_path, $mapref);
		      # Handle the special case of when the value
		      # begins with a port
		      if ($cookie_path =~ /^:/) {
			$value =~ 
			  s/(path=)([^;]+)/$1$remote_site$cookie_path/i;
		      } else {
			$value =~ s/(path=)([^;]+)/$1$cookie_path/i;
		      }
		    } elsif ($header =~/^Client-Peer/i) {
		      my $local_addr = $r->connection->local_addr;
		      my ($port, $ip) =
			Socket::unpack_sockaddr_in($local_addr);
		      $ip = Socket::inet_ntoa($ip);
		      $value = "$ip:$port";
		    }
		    $r->log->debug("respond: OUT-MOD $header: $value");
		    $r->headers_out->{$header} = $value;
		  });
  $r->content_type($response->header('Content-type'));
  $r->status($response->code);
  $r->status_line(join " ", $response->code, $response->message);

  # deal with redirects
  if ($r->status =~ /(301|302)/) {
    my $location = $response->header('Location');
    &rewrite_url($r, $remote_site, \$location, $mapref);
    # Only modify location if rewritten URL is relative
    unless ($location =~ m!://!) {
      if ($location =~ m!^/!) {
	$location = $parsed_uri->scheme . '://' . $parsed_uri->hostinfo .
	  $location;
      } else {
	my $base = $r->uri;
	$base =~ s!(/)[^/]+$!$1!;
	$location = $parsed_uri->scheme . '://' . $parsed_uri->hostinfo .
	  $base . $location;
      }
    }
    $r->log->debug("respond: Location: $location");
    $r->headers_out->{'Location'} = $location;
  }

  # deal with auth required redirects
  if ($r->status == 401 && $auth_redirect =~ /^on$/i) {
    my $base = $r->location();
    my $location = '';
    if ($base ne '/') {
      ($location = $r->uri) =~ s/^$base//;
    } else {
      $location = $r->uri;
    }
    $location = $remote_location . $location;
    $r->status('302');
    $r->status_line(join " ", '302', 'Moved Temporarily');
    $r->log->debug("respond: Location: $location");
    $r->headers_out->{'Location'} = $location;
    $response->content(undef);
  }

  if (length($response->content) != 0) {
    $r->headers_out->{'Content-length'} = length($response->content);
  } else {
    # HEAD request, must populate with what backend said
    $r->headers_out->{'Content-length'} = length($response->content);
  }

  $r->log->debug("respond: Status: ", $r->status);
  $r->log->debug("respond: Status Line: ", $r->status_line);

  $r->send_http_header();
  $r->print($response->content);
}

1;

__END__

# Documentation - try 'pod2text ProxyRewrite'

=head1 NAME

Apache::ProxyRewrite - mod_perl URL-rewriting proxy

=head1 SYNOPSIS

 <Location    />
 SetHandler   perl-script
 PerlHandler  Apache::ProxyRewrite

 PerlSetVar   ProxyTo           http://www.tivoli.com
 PerlSetVar   ProxyAuthInfo     "BASIC aGb2c3ewenQ6amF4szzmY3b="
 PerlSetVar   ProxyAuthRedirect On
 PerlSetVar   ProxyRewrite      "https://www.tivoli.com/secure => /secure"
 </Location>

 <Location    /secure>
 SetHandler   perl-script
 PerlHandler  Apache::ProxyRewrite

 PerlSetVar   ProxyTo           https://www.tivoli.com/secure
 PerlSetVar   ProxyAuthInfo     "BASIC aGb2c3ewenQ6amF4szzmY3b="
 PerlSetVar   ProxyAuthRedirect Off
 PerlSetVar   ProxyRewrite      "http://www.tivoli.com/ => /"
 </Location>

=head1 DESCRIPTION

B<Apache::ProxyRewrite> acts as a reverse-proxy that will rewrite
URLs embedded in HTML documents per apache configuration
directives.

This module was written to allow multiple backend services with
discrete URLs to be presented as one service and to allow the
proxy to do authentication on the client's behalf.

=head1 CONFIGURATION OPTIONS

The following variables can be defined within the configration of
Directory, Location, or Files blocks.

=over 4

=item B<ProxyTo>

The URL for which ProxyRewrite will proxy its requests.

=back

=over 4

=item B<ProxyAuthInfo>

Authorization information for proxied requests. This string must
conform to the credentials string defined in section 11 of RFC
2068.

=back

=over 4

=item B<ProxyAuthRedirect>

If the credentials supplied in the ProxyAuthInfo directive are
insufficient and if ProxyAuthRedirect is set to On, the proxy
server will redirect the client directly to the backend host. If
ProxyAuthRedirect is set to Off (the default), the proxy server
will challenge the client on the remote server's behalf.

=back

=over 4

=item B<ProxyRewrite>

A hash of URLs to rewrite. A note on hashes in configuration
directives from the "Writing Apache Modules with Perl and C"
book page 287:

  The only trick is to remember to put double quotes around the
  configuration value if it contains whitespace and not to allow
  your text editor to wrap it to another line. You can use
  backslash as a continuation character if you find long lines a
  pain to read.

=back

=head1 NOTES

=over 4

=item B<Automatic mappings>

ProxyRewrite automatically adds a mapping for the remote relative
URI and the current location. An example:

  ServerName   proxyhost

  <Location    /foo>
  PerlSetVar   ProxyTo   http://server1/A
  </Location>

The request for http://proxyhost/foo/B is proxied to
http://server1/A/B. Within the response from server1 is an
embedded URI /A/C. This URI is rewritten to /foo/C before being
returned to the client.

=back

=over 4

=item B<Embedded Languages>

Embedded languages such as Javascript are not parsed for embedded
URLs. The problem is NP-Complete. The best choice is to surround
all embedded languages in HTML comments to avoid possible parsing
problems.

=back

=over 4

=item B<Parser Notes>

The parser takes a single pass through each HTML document. This
method is extremely efficient, but it has possible drawbacks with
poorly constructed HTML. All known drawbacks have been
eliminated, but more may exist. Please contact the author if you
have any trouble with parsed output.

=back

=over 4

=item B<Special Thanks>

A special thanks goes to my co-authors of absent, from which much
of the rewriting code comes, Dave Korman and Avi Rubin. Absent is
a system for secure remote access to an organization's internal
web from outside its firewall. To learn more about absent, go to
http://www.research.att.com/projects/absent/.

=back

=head1 AVAILABILITY

This module is available via CPAN at
http://www.cpan.org/modules/by-authors/id/C/CG/CGILMORE/.

=head1 AUTHOR

Christian Gilmore <cag@us.ibm.com>

=head1 SEE ALSO

httpd(8), mod_perl(1)

=head1 COPYRIGHT

Copyright (C) 2002, International Business Machines Corporation
and others. All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the terms of the IBM Public License.

=cut

###############################################################################
###############################################################################
# $Log: ProxyRewrite.pm,v $
# Revision 1.14  2002/01/16 15:49:48  cgilmore
# see ChangeLog
#
# Revision 1.13  2002/01/15 22:40:02  cgilmore
# see ChangeLog for details
#
# Revision 1.12  2001/09/27 20:45:44  cgilmore
# upped to version 0.15
#
# Revision 1.11  2001/09/27 18:22:40  cgilmore
# corrected whitespace bug
#
# Revision 1.10  2001/07/17 20:08:42  cgilmore
# updated documentation
#
# Revision 1.9  2001/03/21 16:25:04  cgilmore
# See ChangeLog for details
#
# Revision 1.8  2001/03/21 16:03:19  cgilmore
# see ChangeLog for details
#
# Revision 1.7  2001/03/07 19:43:15  cgilmore
# See ChangeLog
#
# Revision 1.6  2001/03/02 21:12:32  cgilmore
# See ChangeLog. Version 0.12.
#
# Revision 1.5  2001/01/14 19:47:33  cgilmore
# added base to LINK_ELEMENT hash and upped to rev 0.11
#
# Revision 1.4  2001/01/02 23:51:20  cgilmore
# converted for publication
#
###############################################################################
###############################################################################
