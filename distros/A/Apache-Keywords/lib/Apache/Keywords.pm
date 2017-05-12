package Apache::Keywords;
    
# Copyright 2000 Magnus Cedergren, mace@lysator.liu.se
#
# This library is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use Apache::Constants qw(:common);
use Apache::Cookie;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

#Items to export to callers namespace
@EXPORT = qw();

$VERSION = '0.1';

=head1 NAME

Apache::Keywords - Store keywords as a personal profile in a cookie.

=head1 CONTENTS

The package Apache::Keywords contains:

    Makefile.PL
    lib/Apache/Keywords.pm
    README
    MANIFEST

=head1 PREREQUISITES

You need Apache::Constants and Apache::Cookie to use Apache::Keywords.

=head1 INSTALLATION

    tar zxf Apache-Keywords-0.1.tar.gz
    perl Makefile.PL
    make
    make install

=head1 SYNOPSIS

In a dynamic mod_perl source-file:

    use Apache::Keywords;

    # Create a keywords object
    $k = new Apache::Keywords;

    # Set different parameters
    $k->name('PersonalProfile');
    $k->expires('+1M');
    $k->path("/");
    $k->domain('xxx.com');

    # Get parameters
    print $k->expires;
    print $k->path;
    ...

    # Add new keywords to the profile
    $k->new_keywords($r,"horse, dog");
    # Special version for Apache::ASP
    $k->new_keywords_asp($Request,"cars, motorcycles");

    # Return the content of the cookie profile
    $hashref = $k->profile($r);
    print $hashref->{'horse'};
    %hash = %$hashref;
    # Special version for Apache::ASP
    $k->profile_asp($Request);
    

In a the .htaccess for apache static-files, e.g. .html-files:
    <Files ~ (\.html)>
        SetHandler perl-script
        PerlFixupHandler Apache::Keywords
        PerlSetVar KeywordsName "PersonalProfile"
        PerlSetVar KeywordsExpires "+1M"
        PerlSetVar KeywordsPath "/"
        PerlSetVar KeywordsDomain "xxx.com"
    </Files>

=head1 DESCRIPTION

An Apache::Keywords class object will generate/update a cookie. The cookie
contains a personal profile, e.g. counts the different keywords that are added 
to it. The module could be configured as a "PerlFixupHandler" for a
static file in mod_perl, e.g. HTML-files. It could also be used in web scripts,
like mod_perl scripts that uses Apache::ASP or Apache::Registry. In the 
static version, Apache::Keywords fetches the keywords from phrases
like <META NAME="keywords" CONTENT="cars, motorcycles">.

=head1 METHODS

The following methods could be use in dynamic web scripts:

=over

=item $k = new Apache::Keywords;

Make a new Apache::Keywords object and return it.

=cut

sub new {
    my $self = {};
    $self->{EXPIRES} = undef;
    $self->{PATH} = undef;
    $self->{DOMAIN} = undef;
    bless($self);
    return $self;
}

=item $k->name(<name>);

Sets the name of the cookie that is used for the personal profile. 
Without argument, the function returns the name of the cookie.

=cut

sub name {
    my $self = shift;
    if (@_) { $self->{NAME} = shift }
    return $self->{NAME};
}

=item $k->expires(<expiration time>);

Sets the cookie parameter for expiration. Without argument, the function
returns the expiration time already set.

=cut

sub expires {
    my $self = shift;
    if (@_) { $self->{EXPIRES} = shift }
    return $self->{EXPIRES};
}

=item $k->path(<path>);

Sets the path to be associated with the cookie. Without argument, 
the function returns the path already set.

=cut

sub path {
    my $self = shift;
    if (@_) { $self->{PATH} = shift }
    return $self->{PATH};
}

=item $k->domain(<domain name>);

Sets the domain name to be associated with the cookie. 
Without argument, the function returns the domain name already set.

=cut

sub domain {
    my $self = shift;
    if (@_) { $self->{DOMAIN} = shift }
    return $self->{DOMAIN};
}

# Handler be configured as a "PerlFixupHandler" in the Apache configuration.
# Automates the handling of keywords from a static file, e.g. <META KEYWORDS...
# from normal HTML-files.
sub handler {
    my ($r) = @_;
    local (*FILE,$keywords,$new_keywords);
    $new_keywords = "";
    return DECLINED if
	!$r->is_main
	    || $r->content_type ne "text/html"
		|| !open(FILE,$r->filename);
    # If it is possible, fetch the keywords for the Meta-tag of the
    # document
    my $expires = $r->dir_config('KeywordsExpires');
    my $domain = $r->dir_config('KeywordsDomain');
    my $path = $r->dir_config('KeywordsPath');
    my $name = $r->dir_config('KeywordsName');
    while(<FILE>) {
	last if m!<BODY>|</HEAD>!i;
	if (m/META\s+(NAME|HTTP-EQUIV)="Keywords"\s+CONTENT="([^"]+)"/i) {
	    $new_keywords = $2;
	}
    }
    close(FILE);
    # "Touch" the file, so that the ContentHandler really sends the file
    # (including the updated cookie)
    my $now = time;
    utime $now,$now,$r->filename;
    # If there are any new keywords from this document, update the user's
    # profile and re-store it in the cookie
    # Get old "keywords" cookie
    if (!defined($name) || $name eq "") {
        $name = "Keywords";
    }
    my $cookie = Apache::Cookie->new($r);
    $keywords = $cookie->get($name);
    # Make profile
    $keywords = make_profile($keywords,$new_keywords);
    if (defined($expires)) {
	$cookie->set(-expires => $expires);
    }
    if (defined($domain)) {
	$cookie->set(-domain => $domain);
    }
    if (defined($path)) {
        $cookie->set(-path => $path);
    }
    $cookie->set(-name => $name, -value => $keywords);
    return OK;
}

=item $k->new_keywords($r,<string with keywords>);

Add the new keywords of this HTTP-call. The argument is a string with the
different words separated with space. $r is the Apache mod_perl request
object.

=cut

# Must be called instead of the automated handler if your webpage is delivered
# dynamically. 
sub new_keywords {
    my ($self,$r,$new_keywords) = @_;
    my ($expires,$domain,$path,$name,$keywords);
    if (length($new_keywords) > 1) {
	if (defined($self->{NAME})) {
	    $name = $self->{NAME};
	} elsif ($r) {
	    $name = $r->dir_config('KeywordsName');
	} else {
	    $name = "Keywords";
	}
	if (defined($self->{EXPIRES})) {
	    $expires = $self->{EXPIRES};
	} elsif ($r) {
	    $expires = $r->dir_config('KeywordsExpires');
	}
	if (defined($self->{DOMAIN})) {
	    $domain = $self->{DOMAIN};
	} elsif ($r) {
	    $domain = $r->dir_config('KeywordsDomain');
	}
	if (defined($self->{PATH})) {
	    $path = $self->{PATH};
	} elsif ($r) {
	    $path = $r->dir_config('KeywordsPath');
	}
        # Get old "keywords" cookie
	my $cookie = Apache::Cookie->new($r);
	$keywords = $cookie->get($name);
        # Make profile
        $keywords = make_profile($keywords,$new_keywords);
        # Replace the old cookie with a new one
	if (!defined($expires) || length($expires) <= 0) {
	    $expires = undef;
	}
	if (!defined($domain) || length($domain) <= 0) {
	    $domain = undef;
	}
	if (!defined($path) || length($path) <= 0) {
	    $path = "/";
	}
	$cookie->set(-name => $name, -value => $keywords);
	if (defined($expires)) {
	    $cookie->set(-expires => $expires);
	}
	if (defined($domain)) {
	    $cookie->set(-domain => $domain);
	}
	if (defined($path)) {
	    $cookie->set(-path => $path);
	}
	return $keywords;
   }
}

=item $k->new_keywords_asp($Request,<string with keywords>);

A special version of new_keywords() suited for Apache::ASP. The $Request
object is special for Apache::ASP.

=cut

# Version of new_keywords for use with "Apache::ASP"
sub new_keywords_asp {
    my ($self,$Request,$new_keywords) = @_;
    new_keywords($self,$Request->{r},$new_keywords);
}

# Take a content profile e.g. from a page, and updated the profile from
# fetched from a users profile (stored in a cookie)
sub make_profile
{
    # Two arguments:
    my ($keywords, # e.g. "football: 3, hockey: 2"
	$new_keywords) # e.g. "fotball, swimming"
	= @_;
    local (%keywords,@keywords,@new_keywords,$i,
	   $key,$value,$row,@pair,$mx);
    $new_keywords = lc($new_keywords); # All keywords lower case
    $new_keywords =~ tr [ÅÄÖÜÉÆØ] [åäöüéæø]; # Special for Scandinavian
    # Store keywords as a hash
    @new_keywords = split(/\, */,$new_keywords);
    @keywords = split(/\, */,$keywords);
    %keywords = ();
    foreach $keyword (@keywords) {
	@pair = split(/: */,$keyword);
	if ($pair[0]) {
	    if (length($pair[1]) < 1) {	
		$pair[1] = 1;
	    }
	    $keywords{$pair[0]} = $pair[1];
	}
    }
    # Update profile with the new data
    foreach $new_keyword (@new_keywords) {
	$keywords{$new_keyword}++;
    }
    # Sort
    @keywords = ();
    while (($key,$value) = each %keywords) {
	$row = sprintf "%06d %s",$value,$key;
	@keywords = (@keywords,$row);
    }
    $keywords = "";
    @keywords = sort {$b cmp $a} @keywords;
    # Build the new profile (to be stored as a cookie)
    if ($#keywords > 200) {
	$mx = 200;
    } else {
	$mx = $#keywords;
    }
    for ($i=0;$i<=$mx;$i++) {
	$keywords[$i] = substr($keywords[$i],7);
	$keywords .= $keywords[$i].": ".$keywords{$keywords[$i]};
	if ($i < $mx) {
	    $keywords .= ", ";
	}
    }
    return $keywords;
}

=item $k->profile;

Return the profile in a hash reference, e.g. profile->{'horse'} == 3, 
profile->{'dog'} == 2.

=cut

# Return the profile in a hash
sub profile {
    my ($self,$r) = @_;
    my ($keywords,$cookie,@k,@item,$i);
    my %ret = ();
    my $cookie = Apache::Cookie->new($r);
    my $name = $self->name;
    if (!defined($name) || $name eq "") {
        $name = "Keywords";
    }
    $cookie = Apache::Cookie->new($r);
    $keywords = $cookie->get($name);
    @k = split(/\,\s*/,$keywords);
    for ($i=0;$i<=$#k;$i++) {
	@item = split(/\:\s*/,$k[$i]);
	$ret{$item[0]} = $item[1];
    }
    return \%ret;
}

=item $k->profile_asp

A special version of profile() suited for Apache::ASP. The $Request
is special for Apache::ASP.

=cut

# Version of profile for use with "Apache::ASP"
sub profile_asp {
    my ($self,$Request) = @_;
    return profile($self,$Request->{r});
}

1;

=back

=head1 AUTHOR

Copyright 2000 Magnus Cedergren, mace@lysator.liu.se

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

__END__
