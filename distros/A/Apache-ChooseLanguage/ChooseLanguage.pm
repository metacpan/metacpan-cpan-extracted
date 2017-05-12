package Apache::ChooseLanguage;

######################################
#                                    #
#  Copyright (c) Nadeau Consultants  #
#  Billy Nadeau, bill@sanac.net      #
#                                    #
#  Updated: 09/11/2000               #
#  Last updated: 10/16/2002          #
#                                    #
######################################


use strict;
use CGI::Cookie ();
use Apache::Constants qw(:common);

our $VERSION = '1.02';

sub handler
{
    my $r = shift;
    my $uri = $r->uri;

    my $root = $r->dir_config('ChooseRoot');
    my $Cookie = $r->dir_config('ChooseCookie') or 0;

    return DECLINED unless( $uri eq $root or $Cookie );

    my $Browser = $r->dir_config('ChooseBrowser') or 1;
    my $Fuzzy = $r->dir_config('ChooseFuzzy') or 1;
    my $NoCache = $r->dir_config('ChooseNoCache') or 0;

    my %indexes = split /\s*(?:=>|,)\s*/s, $r->dir_config('ChooseIndexes');

    if( $Cookie )
    {
	my $language = "";
	my $setCookie = 0;
	
	while (  my ($key, $value) = each %indexes )
	{
	    if ( $uri eq $value )
	    {
		$setCookie = 1;
		$language = $key;
		last;
	    }
	}
	
	my %cookies = CGI::Cookie->parse($r->header_in('Cookie'));

	my $lang_cookie = $cookies{'LANGUAGE'}->value if defined $cookies{'LANGUAGE'};
	
	if ( $setCookie and $language ne $lang_cookie )
	{
	    my $domain = $r->dir_config('ChooseDomain')
		or warn "Apache::Choose : No domain for cookie\n";
	    my $expire = $r->dir_config('ChooseExpire') || "+1M";
	    
	    my $newcookie = CGI::Cookie->new( -name => 'LANGUAGE',
					      -value => $language,
					      -domain => $domain,
					      -path => '/',
					      -expires => $expire);
	    
	    $r->header_out( 'Set-Cookie' => $newcookie );
	    return DECLINED;
	}
	elsif ( $uri eq $root and $lang_cookie )
	{
	    $r->no_cache($NoCache);
	    $r->uri( $indexes{$lang_cookie} );
	    return DECLINED;
	}
    }

    if( $uri eq $root and $Browser )
    {
	my @lang_accept = split /\s*,\s*/, $r->header_in("Accept-Language");

	foreach my $lang ( @lang_accept )
	{
	    $lang = substr( $lang, 0, 2 ) if $Fuzzy;

	    if( defined $indexes{$lang} )
	    {
		$r->no_cache($NoCache);
		$r->uri( $indexes{$lang} );
		return( DECLINED );
	    }
	}
    }

    # Nothing found? send choosepage
    my $choosepage = $r->dir_config('ChoosePage') or return DECLINED;

    if( $uri eq $root )
    {
	$r->no_cache($NoCache);
	$r->uri($choosepage);
    }
    return DECLINED;
}

1;

__END__

=head1 NAME

ChooseLanguage - Perl extension for accessing different versions of a website based on the user preferred language

=head1 SYNOPSIS

=head2 In apache's startup.pl:

  use Apache::ChooseLanguage;

=head2 In apache's httpd.conf:

  # Initialise the language chooser handler
  PerlTransHandler Apache::ChooseLanguage

  # Behaviour flags ( 0 = no, 1 = yes )
  PerlSetVar	ChooseBrowser	1 # Use the browser's language preference
  PerlSetVar	ChooseFuzzy	1 # Use fuzzy language selection
          	           	  # ( treat en-US as en, fr-CA as fr )
  PerlSetVar	ChooseCookie	1 # Set a cookie to remember the user choice
  PerlSetVar    ChooseNoCache   1 # Prevent the browser from caching "ChooseRoot"

  # Cookie settings
  PerlSetVar	ChooseDomain	"www.yourdomain.com"
  PerlSetVar	ChooseExpire	"+1M"

  # Root URL for this handler to react
  PerlSetVar	ChooseRoot	"/" # This URL has to be typed exactly for
          	          	    # the handler to react

  # What's the language selection page
  PerlSetVar	ChoosePage	"/index.html"

  # Define a perl hash, languages as keys and URLs as values
  PerlSetVar	ChooseIndexes	"en => /en/index.html,\
          	             	 fr => /fr/bienvenue.html"

=head2 In your chooser page (named in the ChoosePage var)

  <H2>Please choose your prefered language</H2>

  <!-- If activated, the cookie sender will be activated by the following links -->
  <A HREF="/en/index.html">English</A>
  <A HREF="/fr/bienvenue.html>Francais</A>

=head1 DESCRIPTION

This is an Apache translation handler.  It will react to ChooseRoot URL requests, and it always return DECLINED to let the normal (or your own) handler find the actual file to return.

Depending on your config, this module will check the client's browser language preference and/or our cookie.  The fuzzy flag (recommended for most setups) will allow you to treat all sub-languages or regional versions as a single general language.

Setting ChooseNoCache to a true value will prevent the broser from caching the pages sent by this handler.  If unset, the client may see the previously selected page after choosing a different one.

If using cookies, you have to manually set your domain and expiration data.  The language cookie will be sent when:
  1- A page refered by the ChooseIndexes PerlVar is accessed
  2- The ChooseCookie PerlVar is set
  3- This cookie dosen't already exists and contain the correct value

Both index (language choice and language-specific) should be relative to your document root, since apache's translation handler will do it's job after this one.

=head1 AUTHOR

Billy Nadeau E<lt>bill@sanac.netE<gt>

=cut
