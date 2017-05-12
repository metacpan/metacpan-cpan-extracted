package Apache::LangPrefCookie;

use strict;
use warnings;

use Apache::Constants qw(OK DECLINED);
use Apache::Request;
use Apache::Cookie;
use Apache::Log ();

our $VERSION = '1.03';

sub handler {
    my $r           = Apache::Request->new(shift);
    my %cookies     = Apache::Cookie->new($r)->parse;
    my $cookie_name = $r->dir_config('LangPrefCookieName') || 'prefer-language';
    my @ua_lang_prefs;

    # $r->log->debug("Looking for cookie: \"$cookie_name\"");

    $r->header_out( 'Vary',
                    $r->header_out('Vary') ? $r->header_out('Vary') . 'cookie'
                    :                        'cookie'
        );

    # if we have no cookie, this is none of our business
    return DECLINED
      unless exists $cookies{$cookie_name}
          and my $cookie_pref_lang = $cookies{$cookie_name}->value();

    # dont parse an empty header just to get "Use of uninitialized value
    # in" warnings
    if ( defined $r->header_in("Accept-Language")
        and length $r->header_in("Accept-Language") )
    {
        @ua_lang_prefs =
          parse_accept_language_header( $r->header_in("Accept-Language") );
    }
    else {

        # RFC 2616 states: "If no Accept-Language header is present in
        # the request, the server SHOULD assume that all languages are
        # equally acceptable."  Since we are going to fool httpd into
        # thinking there is one, we respect the original demand by
        # inserting '*'.
        @ua_lang_prefs = q/*/;
    }

    # Now: unless the cookie wants a language that would be the
    # best matching anyway, rebuild the list of language-ranges
    unless ( $cookie_pref_lang eq $ua_lang_prefs[0] ) {
        my ( $qvalue, $language_ranges ) = ( 1, '' );
        map {
            if (m/^(?:\w{1,8}(?:-\w{1,8})*|\*)$/)
            {
                $language_ranges .= "$_;q=$qvalue, ";
                $qvalue *= .9;
            }
        } ( $cookie_pref_lang, @ua_lang_prefs );
        $language_ranges =~ s/,\s*$//;
        return DECLINED unless length $language_ranges;
        $r->header_in( "Accept-Language", $language_ranges );
        $r->log->debug(
"Cookie \"$cookie_name\" requested \"$cookie_pref_lang\", set \"Accept-Language: $language_ranges\""
        );
    }
    return OK;
}

# taken and modified from Philippe M. Chiasson's Apache::Language;
# later, Aldo Calpini (dada) showed how to get rid of $`
# returns a sorted (from most to least acceptable) list of languages.
sub parse_accept_language_header {
    my $language_ranges = shift;
    my $value           = 1;
    my %pairs;
    foreach ( split( /,/, $language_ranges ) ) {
        s/\s//g;    #strip spaces
        next unless length;
        if (m/(.*?);q=([\d\.]+)/) {

            #is it in the "en;q=0.4" form ?
            $pairs{ lc $1 } = $2 if $2 > 0;
        }
        else {

            #give the first one a q of 1
            $pairs{ lc $_ } = $value;

            #and the others .001 less every time
            $value -= 0.001;
        }
    }
    return sort { $pairs{$b} <=> $pairs{$a} } keys %pairs;
}

1;
__END__

=head1 NAME

Apache::LangPrefCookie - implant a language-preference given by
cookie into httpd's representation of the Accept-Language HTTP-header.

=head1 SYNOPSIS

  <Location />
     PerlInitHandler  Apache::LangPrefCookie
  </Location>

  <Location /foo>
     # optionally set a custom cookie-name, default is "prefer-language"
     PerlSetVar LangPrefCookieName "foo-pref"
  </Location>


=head1 DESCRIPTION

This module looks for a cookie providing a language-code as its value.
This preference is then implanted into httpd's representation of the
C<Accept-Language> header, just as if the client had asked for it as #1
choice. The original preferences are still present, albeit with lowered
q-values. The cookie's name is configurable, as described in the
examples. Setting/modifying/deleting such a cookie is to be handled
separately; F<Apache::LangPrefCookie> just consumes it.

After that, it's up to httpd's mod_negotiation to choose the best
deliverable representation.

=head2 WHY?

I had demands to let users switch language I<once> for a given site.
Additionally, the availability and languages of translations offered
vary over places within this site.

In theory a user-agent should help its users to set a reasonable choice
of languages. In practice, the dialog is hidden in the 3rd level of some
menu, maybe even misguiding the user in his selections. (See
L<http://ppewww.ph.gla.ac.uk/~flavell/www/lang-neg.html>, especially the
section I<Language subset selections>, for examples.)

There might also be scenarios where one wants to let users set a
different preference just for certain realms within one site.

I dislike solutions involving virtual paths, because they normally
lengthen and multiply URIs for a given resource.

=head1 EXAMPLE COOKIE

C<prefer-language=x-klingon;expires=Saturday 31-Dec-05 24:00:00 GMT;path=/>

Optionally, the default cookie name C<prefer-language> can be overridden
by setting the C<LangPrefCookieName> variable:

C<PerlSetVar LangPrefCookieName "mypref">

C<mypref=x-klingon;expires=Saturday 31-Dec-05 24:00:00 GMT;path=/>

=head1 SEE ALSO

L<mod_perl(3)>

L<http://httpd.apache.org/docs/1.3/content-negotiation.html>

L<http://httpd.apache.org/docs/1.3/mod/mod_negotiation.html>

L<http://ppewww.ph.gla.ac.uk/~flavell/www/lang-neg.html>

L<http://www.w3.org/TR/2004/WD-webarch-20040705/#avoid-uri-aliases>

Apache2 has native means to the same end:
L<http://httpd.apache.org/docs/2.2/content-negotiation.html#better>

=head1 AUTHOR

Hansjoerg Pehofer, E<lt>hansjoerg.pehofer@uibk.ac.atE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2008 by Hansjoerg Pehofer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
