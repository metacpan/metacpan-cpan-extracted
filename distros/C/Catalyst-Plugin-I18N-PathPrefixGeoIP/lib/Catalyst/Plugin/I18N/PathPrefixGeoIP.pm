package Catalyst::Plugin::I18N::PathPrefixGeoIP;

use 5.008;

use Moose::Role;
use namespace::autoclean;

requires
  # from Catalyst
  'config', 'prepare_path', 'req', 'uri_for', 'log',
  # from Catalyst::Plugin::I18N
  'languages', 'loc';

use List::Util qw(first);
use Scope::Guard;
use I18N::LangTags::List;
use Geo::IP;

our $VERSION = '0.10';

=head1 NAME

Catalyst::Plugin::I18N::PathPrefixGeoIP - A drop in for atalyst::Plugin::I18N::PathPrefix that uses GeoIP


=head1 SYNOPSIS

  # in MyApp.pm
  use Catalyst qw/
    I18N I18N::PathPrefixGeoIP
  /;
  __PACKAGE__->config('Plugin::I18N::PathPrefixGeoIP' => {
    valid_languages => [qw/en de fr/],
    fallback_language => 'en',
    language_independent_paths => qr{
        ^( votes/ | captcha/numeric/ )
    }x,
    geoip_db => 'data/GeoLiteCity.dat',
  });
  __PACKAGE__->setup;

  # now the language is selected based on requests paths:
  #
  # http://www.example.com/en/foo/bar -> sets $c->language to 'en',
  #                                      dispatcher sees /foo/bar
  #
  # http://www.example.com/de/foo/bar -> sets $c->language to 'de',
  #                                      dispatcher sees /foo/bar
  #
  # http://www.example.com/fr/foo/bar -> sets $c->language to 'fr',
  #                                      dispatcher sees /foo/bar
  

  # http://www.example.com/foo/bar    -> used GeoIP to sets $c->language
  #                                      If GeoIp dos not fain a mach it fails
  #                                      over to use language from
  #                                      Accept-Language header,
  #                                      dispatcher sees /foo/bar
  #
  # or if redirect_to_language_url == 1:
  #
  # http://www.example.com/foo/bar    -> redirect to http://www.example.com/xx/foo/bar
  #                                      where xx is language from Accept-Language header

  # in a controller
  sub language_switch : Private
  {
    # the template will display the language switch
    $c->stash('language_switch' => $c->language_switch_options);
  }

=head1 DESCRIPTION

This module allows you to put the language selector as a prefix to the path part of
the request URI without requiring any modifications to the controllers (like
restructuring all the controllers to chain from a common base controller).

(Internally it strips the language code from C<< $c->req->path >> and appends
it to C<< $c->req->base >> so that the invariant C<< $c->req->uri eq
$c->req->base . $c->req->path >> still remains valid, but the dispatcher does
not see the language code - it uses C<< $c->req->path >> only.)

Throughout this document 'language code' means ISO 639-1 2-letter language
codes, case insensitively (eg. 'en', 'de', 'it', 'EN'), just like
L<I18N::LangTags> supports them.

Note: You have to load L<Catalyst::Plugin::I18N> if you load this plugin.

Note: HTTP already have a standard way (ie. Accept-Language header) to allow
the user specify the language (s)he prefers the page to be delivered in.
Unfortunately users often don't set it properly, but more importantly Googlebot
does not really support it (but requires that you always serve documents of the
same language on the same URI). So if you want a SEO-optimized multi-lingual
site, you have to have different (sub)domains for the different languages, or
resort to putting the language selector into the URL.

=head1 CONFIGURATION

You can use these configuration options under the C<'Plugin::I18N::PathPrefixGeoIP'>
key:

=head2 valid_languages

  valid_languages => \@language_codes

The language codes that are accepted as path prefix.

=head2 fallback_language

  fallback_language => $language_code

The fallback language code used if the URL contains no language prefix and
L<Catalyst::Plugin::I18N> cannot auto-detect the preferred language from the
C<Accept-Language> header or none of the detected languages are found in
L</valid_languages>.

=head2 language_independent_paths

  language_independent_paths => $regex

If the URI path is matched by C<$regex>, do not add language prefix and ignore
if there's one (and pretend as if the URI did not contain any language prefix,
ie.  rewrite C<< $c->req->uri >>, C<< $c->req->base >> and C<< $c->req->path >>
to remove the prefix from them).

Use a regex that matches all your paths that return language independent
information.

If you don't set this config option or you set it to an undefined value, no
paths will be handled as language independent ones.

=head2 redirect_to_language_url

  redirect_to_language_url => 1

Redirect users to url with language prefix.

Without redirect_to_language_url users may access your site using bout urls with a 
language selector and without. This may be bad for search engine optimization because 
search engines will have a hard time determine the original source for documents. 
Setting redirect_to_language_url will redirect users to a url with language prefix.

=head2 debug

  debug => $boolean

If set to a true value, L</prepare_path_prefix> logs its actions (using C<<
$c->log->debug(...) >>).

=head1 METHODS

=cut

=head2 setup_finalize

Overridden (wrapped with an an C<after> modifier) from
L<Catalyst/setup_finalize>.

Sets up the package configuration.

=cut

after setup_finalize => sub {
  my ($c) = (shift, @_);

  my $config = $c->config->{'Plugin::I18N::PathPrefixGeoIP'};

  $config->{fallback_language} = lc $config->{fallback_language};

  my @valid_language_codes = map { lc $_ }
    @{ $config->{valid_languages} };

  # fill the hash for quick lookups
  @{ $config->{_valid_language_codes}}{ @valid_language_codes } = ();

  if (!defined $config->{language_independent_paths}) {
    $config->{language_independent_paths} = qr/(?!)/; # never matches anything
  }

  # Load GeoIP db
  if (!$config->{geoip_db}) {
    die ("Pleas set the geoip_db config option for Plugin::I18N::PathPrefixGeoIP.");
  }

  $config->{geoip} = Geo::IP->open($config->{geoip_db}) or die("Can not open GeiIP db '" . $config->{geoip_db} . "'");

};

=head2 prepare_path

Overridden (wrapped with an an C<after> modifier) from
L<Catalyst/prepare_path>.

Calls C<< $c->prepare_path_prefix >> after the original method.

=cut

after prepare_path => sub {
  my ($c) = (shift, @_);

  $c->prepare_path_prefix;
};

=head2 prepare_path_prefix

  $c->prepare_path_prefix()

Returns: N/A

If C<< $c->req->path >> is matched by the L</language_independent_paths>
configuration option then calls C<< $c->set_languages_from_language_prefix >>
with the value of the L</fallback_language> configuration option and
returns.

Otherwise, if C<< $c->req->path >> starts with a language code listed in the
L</valid_languages> configuration option, then splits language prefix from C<<
$c->req->path >> then appends it to C<< $c->req->base >> and calls C<<
$c->set_languages_from_language_prefix >> with this language prefix.

Otherwise, it tries to select an appropriate language code:

=over

=item *

It picks the first language code C<< $c->languages >> that is also present in
the L</valid_languages> configuration option.

=item *

If no such language code, uses the value of the L</fallback_language>
configuration option.

=back

Then appends this language code to C<< $c->req->base >> and the path part of
C<< $c->req->uri >>, finally calls C<< $c->set_languages_from_language_prefix >>
with that language code.

=cut

sub prepare_path_prefix
{
  my ($c) = (shift, @_);

  my $config = $c->config->{'Plugin::I18N::PathPrefixGeoIP'};

  my $language_code = $config->{fallback_language};

  my $valid_language_codes = $config->{_valid_language_codes};

  my $req_path = $c->req->path;

  if ($req_path !~ $config->{language_independent_paths}) {
    my ($prefix, $path) = split m{/}, $req_path, 2;
    $prefix = lc $prefix if defined $prefix;
    $path   = '' if !defined $path;

    if (defined $prefix && exists $valid_language_codes->{$prefix}) {
      $language_code = $prefix;

      $c->_language_prefix_debug("found language prefix '$language_code' "
        . "in path '$req_path'");

      # can be a language independent path with surplus language prefix
      if ($path =~ $config->{language_independent_paths}) {
        $c->_language_prefix_debug("path '$path' is language independent");

        # bust the language prefix completely
        $c->req->uri->path($path);

        $language_code = $config->{fallback_language};
      }
      else {
        # replace the language prefix with the known lowercase one in $c->req->uri
        $c->req->uri->path($language_code . '/' . $path);

        # since $c->req->path returns such a string that satisfies
        # << $c->req->uri->path eq $c->req->base->path . $c->req->path >>
        # this strips the language code prefix from $c->req->path
        my $req_base = $c->req->base;
        $req_base->path($req_base->path . $language_code . '/');
      }
    }
    else {
      my $detected_language_code;

      my $geocountry = _ip2contry($config->{geoip}, $c->req->address);

      if ($geocountry && exists $valid_language_codes->{$geocountry}) {
        $detected_language_code = $geocountry;
        $c->_language_prefix_debug("Detected valid language by GeoIP. Ip: " . $c->req->address . " -> Country: '$detected_language_code'");
      }
      else {
        $c->_language_prefix_debug("Did not find valid language by GeoIP. Failing over to languages request header. Ip Address: " . $c->req->address);
         $detected_language_code =
        first { exists $valid_language_codes->{$_} }
          map { lc $_ }
            @{ $c->languages };
      }

      $c->_language_prefix_debug("detected language: "
        . ($detected_language_code ? "'$detected_language_code'" : "N/A"));

      $language_code = $detected_language_code if $detected_language_code;

      # fake that the request path already contained the language code prefix
      my $req_uri = $c->req->uri;
      $req_uri->path($language_code . $req_uri->path);

      # so that it strips the language code prefix from $c->req->path
      my $req_base = $c->req->base;
      $req_base->path($req_base->path . $language_code . '/');

      if ($config->{redirect_to_language_url}) {
         $c->_language_prefix_debug("redirect to language url '$req_uri'");   
         $c->response->redirect( $req_uri ); 
         return;
      }
      else {
        $c->_language_prefix_debug("set language prefix to '$language_code'");
      }
    }

    $c->req->_clear_path;
  }
  else {
    $c->_language_prefix_debug("path '$req_path' is language independent");
  }

  $c->set_languages_from_language_prefix($language_code);
}


=head2 set_languages_from_language_prefix

  $c->set_languages_from_language_prefix($language_code)

Returns: N/A

Sets C<< $c->languages >> to C<$language_code>.

Called from both L</prepare_path_prefix> and L</switch_language> (ie.
always called when C<< $c->languages >> is set by this module).

You can wrap this method (using eg. the L<Moose/after> method modifier) so you
can store the language code into the stash if you like:

  after set_languages_from_language_prefix => sub {
    my $c = shift;

    $c->stash('language' => $c->language);
  };

=cut

sub set_languages_from_language_prefix
{
  my ($c, $language_code) = (shift, @_);

  $language_code = lc $language_code;

  $c->languages([$language_code]);
}


=head2 uri_for_in_language

  $c->uri_for_in_language($language_code => @uri_for_args)

Returns: C<$uri_object>

The same as L<Catalyst/uri_for> but returns the URI with the C<$language_code>
path prefix (independently of what the current language is).

Internally this method temporarily sets the paths in C<< $c->req >>, calls
L<Catalyst/uri_for> then resets the paths. Ineffective, but you usually call it
very infrequently.

Note: You should not call this method to generate language-independent paths,
as it will generate invalid URLs currently (ie. the language independent path
prefixed with the language prefix).

Note: This module intentionally does not override L<Catalyst/uri_for> but
provides this method instead: L<Catalyst/uri_for> is usually called many times
per request, and most of the cases you want it to use the current language; not
overriding it can be a significant performance saving. YMMV.

=cut

sub uri_for_in_language
{
  my ($c, $language_code, @uri_for_args) = (shift, @_);

  $language_code = lc $language_code;

  my $scope_guard = $c->_set_language_prefix_temporarily($language_code);

  return $c->uri_for(@uri_for_args);
}


=head2 switch_language

  $c->switch_language($language_code)

Returns: N/A

Changes C<< $c->req->base >> to end with C<$language_code> and calls C<<
$c->set_languages_from_language_prefix >> with C<$language_code>.

Useful if you want to switch the language later in the request processing (eg.
from a request parameter, from the session or from the user object).

=cut

sub switch_language
{
  my ($c, $language_code) = (shift, @_);

  $language_code = lc $language_code;

  $c->_set_language_prefix($language_code);

  $c->set_languages_from_language_prefix($language_code);
}


=head2 language_switch_options

  $c->language_switch_options()

Returns: C<< { $language_code => { name => $language_name, uri => $uri }, ... } >>

Returns a data structure that contains all the necessary data (language code,
name, URL of the same page) for displaying a language switch widget on the
page.

The data structure is a hashref with one key for each valid language code (see
the L</valid_languages> config option) (in all-lowercase format) and the value
is a hashref that contains the following key-value pairs:

=over

=item name

The localized (translated) name of the language. (The actual msgid used in C<<
$c->loc() >> is the English name of the language, returned by
L<I18N::LangTags::List/name>.)

=item url

The URL of the equivalent of the current page in that language (ie. the
language prefix replaced).

=back

You can find an example TT2 HTML template for the language switch included in
the distribution.

=cut

sub language_switch_options
{
  my ($c) = (shift, @_);

  return {
    map {
      $_ => {
        name => $c->loc(I18N::LangTags::List::name($_)),
        uri => $c->uri_for_in_language($_ => '/' . $c->req->path, $c->req->params),
      }
    } map { lc $_ }
      @{ $c->config->{'Plugin::I18N::PathPrefixGeoIP'}->{valid_languages} }
  };
}


=head2 valid_languages

  $c->valid_languages

Returns: Array of valid language codes

C<< valid_languages >> returns the language codes you configured in the valid_languages configuration.

Useful if you want to go through all valid languages. For example to make a sitemap.

=cut

sub valid_languages
{
  my ($c) = (shift, @_);

  return @{ $c->config->{'Plugin::I18N::PathPrefixGeoIP'}->{valid_languages} }
}

=begin internal

  $c->_set_language_prefix($language_code)

Sets the language to C<$language_code>: Mangles C<< $c->req->uri >> and C<<
$c->req->base >>.

=end internal

=cut

sub _set_language_prefix
{
  my ($c, $language_code) = (shift, @_);

  if ($c->req->path !~
      $c->config->{'Plugin::I18N::PathPrefixGeoIP'}->{language_independent_paths}) {
    my ($actual_base_path) = $c->req->base->path =~ m{ ^ / [^/]+ (.*) $ }x;
    $c->req->base->path($language_code . $actual_base_path);

    my ($actual_uri_path) = $c->req->uri->path =~ m{ ^ / [^/]+ (.*) $ }x;
    $c->req->uri->path($language_code . $actual_uri_path);

    $c->req->_clear_path;
  }
}


=begin internal

  my $scope_guard = $c->_set_language_prefix_temporarily($language_code)

Sets the language prefix temporarily (does the same as L</_set_language_prefix>
but returns a L<Scope::Guard> instance that resets the these on destruction).

=end internal

=cut

sub _set_language_prefix_temporarily
{
  my ($c, $language_code) = (shift, @_);

  my $old_req_uri_path = $c->req->uri->path;
  my $old_req_base_path = $c->req->base->path;

  my $scope_guard = Scope::Guard->new(sub {
    $c->req->uri->path($old_req_uri_path);
    $c->req->base->path($old_req_base_path);
  });

  $c->_set_language_prefix($language_code);

  return $scope_guard;
}


=begin internal

  $c->_language_prefix_debug($message)

Logs C<$message> using C<< $c->log->debug("Plugin::I18N::PathPrefixGeoIP: $message") >> if the
L</debug> config option is true.

=end internal

=cut

sub _language_prefix_debug
{
  my ($c, $message) = (shift, @_);

  $c->log->debug("Plugin::I18N::PathPrefixGeoIP: $message")
    if $c->config->{'Plugin::I18N::PathPrefixGeoIP'}->{debug};
}

=begin internal

  _ip2contry($geoip_obj, $ipadress)

Find contry for ip

=end internal

=cut

sub _ip2contry {
    my ($geoip, $ip) = (@_);

    if (!$ip) {return undef;} 

    my $record = $geoip->record_by_addr($ip);
    if (!$record) {return undef;} 

    my $geocountry = $record->country_code;
    if (!$geocountry) {return undef;} 

    $geocountry = lc($geocountry);

    return $geocountry;
}

=head1 SEE ALSO

L<Catalyst::Plugin::I18N::PathPrefix>, L<Catalyst::Plugin::I18N>, L<Catalyst::TraitFor::Request::PerLanguageDomains>

=head1 AUTHOR

PathPrefix: Norbert Buchmuller, C<<norbi at nix.hu>>
PathPrefixGeoIP: Runar Buvik: C<<runarb at gmail.com>>
=head1 TODO

=over

=item make L</uri_for_in_language> work on language-independent URIs

=item support locales instead of language codes

=back

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalyst-plugin-i18n-pathprefix at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Plugin-I18N-PathPrefixGeoIP>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Plugin::I18N::PathPrefixGeoIP

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Plugin-I18N-PathPrefixGeoIP>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Plugin-I18N-PathPrefixGeoIP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-Plugin-I18N-PathPrefixGeoIP>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Plugin-I18N-PathPrefixGeoIP/>

=back

=head1 ACKNOWLEDGEMENTS

Thanks for Larry Leszczynski for the idea of appending the language prefix to
C<< $c->req->base >> after it's split off of C<< $c->req->path >>
(L<http://dev.catalystframework.org/wiki/wikicookbook/urlpathprefixing>).

Thanks for Tomas (t0m) Doran <bobtfish@bobtfish.net> for the code reviews,
improvement ideas and mentoring in general.

=head1 COPYRIGHT & LICENSE

Copyright 2010 Norbert Buchmuller, Runar Buvik, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Catalyst::Plugin::I18N::PathPrefixGeoIP
