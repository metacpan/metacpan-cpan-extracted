package Apache::FakeCookie;

use vars qw($VERSION);
$VERSION = do { my @r = (q$Revision: 0.08 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

# Oh!, we really don't live in this package

package Apache::Cookie;
use vars qw($Cookies);
use strict;

$Cookies = {};

# emluation is fairly complete
# cookies can be created, altered and removed
#
sub fetch { return wantarray ? %{$Cookies} : $Cookies; }
sub path {&do_this;}
sub secure {&do_this;}
sub name {&do_this;}
sub domain {&do_this;}
sub value {
  my ($self, $val) = @_;
  $self->{-value} = $val if defined $val;
  if (defined $self->{-value}) {
    return wantarray ? @{$self->{-value}} : $self->{-value}->[0]
  } else {
    return wantarray ? () : '';
  }
}
sub new {
  my $proto = shift;	# bless into Apache::Cookie
  shift;		# waste reference to $r;
  my @vals = @_;
  my $self = {@vals};
  my $class = ref($proto) || $proto;
# make sure values are in array format
  my $val = $self->{-value};;
  if (defined $val) {
    $val = $self->{-value};
    if (ref($val) eq 'ARRAY') {
      @vals = @$val;
    } elsif (ref($val) eq 'HASH') {
      @vals = %$val;
    } elsif (!ref($val)) {
      @vals = ($val);	# it's a plain SCALAR
    }	# hmm.... must be a SCALAR ref or CODE ref
    $self->{-value} = [@vals];
  }
  $self->{-expires} = _expires($self->{-expires})
	if exists $self->{-expires} && defined $self->{-expires};
  bless $self, $class;
  return $self;
}
sub bake {
  my $self = shift;
  if ( defined $self->{-value} ) {
    $Cookies->{$self->{-name}} = $self;
  } else {
    delete $Cookies->{$self->{-name}};
  }
}
sub parse {		# adapted from CGI::Cookie v1.20 by Lincoln Stein
  my ($self,$raw_cookie) = @_;
  if ($raw_cookie) {
    my $class = ref($self) || $self;
    my %results;

    my(@pairs) = split("; ?",$raw_cookie);
    foreach (@pairs) {
      s/\s*(.*?)\s*/$1/;
      my($key,$value) = split("=",$_,2);
    # Some foreign cookies are not in name=value format, so ignore
    # them.
      next if !defined($value);
      my @values = ();
      if ($value ne '') {
        @values = map unescape($_),split(/[&;]/,$value.'&dmy');
        pop @values;
      }
      $key = unescape($key);
      # A bug in Netscape can cause several cookies with same name to
      # appear.  The FIRST one in HTTP_COOKIE is the most recent version.
      $results{$key} ||= $self->new(undef,-name=>$key,-value=>\@values);
    }
    $self = \%results;
    bless $self, $class;
    $Cookies = $self;
  }
  @_ = ($self);
  goto &fetch;
}
sub expires {
  my $self = shift;
  $self->{-expires} = _expires(shift)
	if @_;
  return (exists $self->{-expires} &&
	  defined $self->{-expires})
	? $self->{-expires} : undef;
}
# Adapted from CGI::Cookie v1.20 by Lincoln Stein
# This internal routine creates date strings suitable for use in
# cookies and HTTP headers.  (They differ, unfortunately.)
# Thanks to Mark Fisher for this.
sub _expires {
    my($time) = @_;
    my(@MON)=qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/;
    my(@WDAY) = qw/Sun Mon Tue Wed Thu Fri Sat/;

    # pass through preformatted dates for the sake of expire_calc()
    $time = _expire_calc($time);
    return $time unless $time =~ /^\d+$/;
    my $sc = '-';
    my($sec,$min,$hour,$mday,$mon,$year,$wday) = gmtime($time);
    $year += 1900;
    return sprintf("%s, %02d$sc%s$sc%04d %02d:%02d:%02d GMT",
                   $WDAY[$wday],$mday,$MON[$mon],$year,$hour,$min,$sec);
}
# Copied directly from CGI::Cookie v1.20 by Lincoln Stein
# This internal routine creates an expires time exactly some number of
# hours from the current time.  It incorporates modifications from 
# Mark Fisher.
sub _expire_calc {
    my($time) = @_;
    my(%mult) = ('s'=>1,
                 'm'=>60,
                 'h'=>60*60,
                 'd'=>60*60*24,
                 'M'=>60*60*24*30,
                 'y'=>60*60*24*365);
    # format for time can be in any of the forms...
    # "now" -- expire immediately
    # "+180s" -- in 180 seconds
    # "+2m" -- in 2 minutes
    # "+12h" -- in 12 hours
    # "+1d"  -- in 1 day
    # "+3M"  -- in 3 months
    # "+2y"  -- in 2 years
    # "-3m"  -- 3 minutes ago(!)
    # If you don't supply one of these forms, we assume you are
    # specifying the date yourself
    my($offset);
    if (!$time || (lc($time) eq 'now')) {
        $offset = 0;
    } elsif ($time=~/^\d+/) {
        return $time;
    } elsif ($time=~/^([+-]?(?:\d+|\d*\.\d*))([mhdMy]?)/) {
        $offset = ($mult{$2} || 1)*$1;
    } else {
        return $time;
    }
    return (time+$offset);
}
sub remove {
  my ($self,$name) = @_;
  if ($name) {
    delete $Cookies->{$name} if exists $Cookies->{$name};
  } else {
    delete $Cookies->{$self->{-name}}
	if exists $Cookies->{$self->{-name}};
  }
}
sub as_string {
  my $self = shift;
  return '' unless $self->name;
  my %cook = %$self;
  my $cook = ($cook{-name}) ? escape($cook{-name}) . '=' : '';
  if ($cook{-value}) {
    my $i = '';
    foreach(@{$cook{-value}}) {
      $cook .= $i . escape($_);
      $i = '&'; 
    }
  }  
  foreach(qw(domain path)) {
    $cook .= "; $_=" . $cook{"-$_"} if $cook{"-$_"};
  }
  $cook .= "; expires=$_" if ($_ = expires(\%cook));
  $cook .= ($cook{-secure}) ? '; secure' : '';
}

### helpers
sub do_this {
  (caller(1))[3] =~ /[^:]+$/;
  splice(@_,1,0,'-'.$&);
  goto &cookie_item;
}
# get or set a named item in cookie hash
sub cookie_item {
  my($self,$item,$val) = @_;
  if ( defined $val ) {
#
# Darn! this modifies a cookie item if user is generating
# a replacement cookie and has not yet "baked" it... 
# Don't see how this can hurt in the real world...  MAR 9-2-02
    if ( $item eq '-name' &&
	 exists $Cookies->{$self->{-name}} ) {
      $Cookies->{$val} = $Cookies->{$self->{-name}};
      delete  $Cookies->{$self->{-name}};
    }
    $self->{$item} = $val;
  }
  return (exists $self->{$item}) ? $self->{$item} : '';
}
sub escape {
  my ($x) = @_;
  return undef unless defined($x);
  $x =~ s/([^a-zA-Z0-9_.-])/uc sprintf("%%%02x",ord($1))/eg;
  return $x;
}
# unescape URL-data, but leave +'s alone
sub unescape {  
  my ($x) = @_;
  return undef unless defined($x);
  $x =~ tr/+/ /;       # pluses become spaces
  $x =~ s/%([0-9a-fA-F]{2})/pack("c",hex($1))/ge;
  return $x;
}
1
__END__

=head1 NAME

  Apache::FakeCookie - fake request object for debugging

=head1 SYNOPSIS

  use Apache::FakeCookie;

  loads into Apache::Cookie namespace

=head1 DESCRIPTION

This module assists authors of Apache::* modules write test suites that 
would use B<Apache::Cookie> without actually having to run and query
a server to test the cookie methods. Loaded in the test script after the
author's target module is loaded, B<Apache::FakeCookie>

Usage is the same as B<Apache::Cookie>

=head1 METHODS

Implements all methods of Apache::Cookie

See man Apache::Cookie for details of usage.

=over 4

=item remove	-- new method

Delete the given named cookie or the cookie represented by the pointer

  $cookie->remove;

  Apache::Cookie->remove('name required');

  $cookie->remove('some name');
	for test purposes, same as:
    $cookie = Apache::Cookie->new($r,
	-name	=> 'some name',
    );
    $cookie->bake;

=item new

  $cookie = Apache::Cookie->new($r,
	-name	 => 'some name',
	-value	 => 'my value',
	-expires => 'time or relative time,
	-path	 => 'some path',
	-domain	 => 'some.domain',
	-secure	 => 1,
  );

The B<Apache> request object, B<$r>, is not used and may be undef.

=item bake

  Store the cookie in local memory.

  $cookie->bake;

=item fetch

  Return cookie values from local memory

  $cookies = Apache::Cookie->fetch;	# hash ref
  %cookies = Apache::Cookie->fetch;

=item as_string

  Format the cookie object as a string, 
  same as Apache::Cookie

=item parse

  The same as fetch unless a cookie string is present.

  $cookies = Apache::Cookie->fetch(raw cookie string);
  %cookies = Apache::Cookie->fetch(raw cookie string)

  Cookie memory is cleared and replaced with the contents
  of the parsed "raw cookie string".

=item name, value, domain, path, secure

  Get or set the value of the designated cookie.
  These are all just text strings for test use,
  "value" accepts SCALARS, HASHrefs, ARRAYrefs

=item expires

  Sets or returns time in the same format as Apache::Cookie 
  and CGI::Cookie. See their man pages for details

=back

=head1 SEE ALSO

Apache::Cookie(3)

=head1 AUTHORS

Michael Robinton michael@bizsystems.com
Inspiration and code for subs (expires, expires_calc, parse)
from CGI::Util by Lincoln Stein

=head1 COPYRIGHT and LICENSE

  Copyright 2003 Michael Robinton, BizSystems.

This module is free software; you can redistribute it and/or modify it
under the terms of either:

  a) the GNU General Public License as published by the Free Software
  Foundation; either version 1, or (at your option) any later version,
  
  or

  b) the "Artistic License" which comes with this module.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of 
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
the GNU General Public License or the Artistic License for more details.

You should have received a copy of the Artistic License with this
module, in the file ARTISTIC.  If not, I'll be glad to provide one.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

=cut
