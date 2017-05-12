# ============================================================================
package CatalystX::I18N;
# ============================================================================

use strict;
use warnings;

our $VERSION = "1.13";
our $AUTHORITY = 'cpan:MAROS';

1;

=encoding utf8

=head1 NAME

CatalystX::I18N - Catalyst internationalisation (I18N) framework

=head1 SYNOPSIS

 package MyApp::Catalyst;
 use strict;
 use warnings;
 use Catalyst qw/
     +CatalystX::I18N::Role::Base
     +CatalystX::I18N::Role::GetLocale
     +CatalystX::I18N::Role::DateTime
     +CatalystX::I18N::Role::Maketext
 /; 
 # Choose only the roles you need 
 # CatalystX::I18N::Role::All is a convinient shortcut to load all available roles
 
 # Optionally also load request and response roles (also loaded by CatalystX::I18N::Role::All)
 use CatalystX::RoleApplicator;
 __PACKAGE__->apply_request_class_roles(qw/CatalystX::I18N::TraitFor::Request/);
 __PACKAGE__->apply_response_class_roles(qw/CatalystX::I18N::TraitFor::Response/);
 
 # Add some I18N configuration
 __PACKAGE__->config( 
     name    => 'MyApp', 
     I18N    => {
         default_locale     => 'de_AT',
         locales            => {
             'de'               => {
                 format_date        => 'dd.MM.yyyy',
                 format_datetime    => 'dd.MM.yyyy HH:mm',
             },
             'de_AT'            => {
                 inherits           => 'de',
                 timezone           => 'Europe/Vienna',
                 format_datetime    => 'dd.MM.yyyy uma HH\'e\'',
             },
             'de_DE'             => {
                 inherits            => 'de',
                 timezone            => 'Europe/Berlin',
             },
         }
     },
 );

Then in your controller classes

 package MyApp::Catalyst::Controller::Main;
 use strict;
 use warnings;
 use parent qw/Catalyst::Controller/;
 
 sub auto : Private {
     my ($self,$c) = @_;
     $c->get_locale(); 
     # Tries to fetch the locale from the folloing sources in the given order
     # 1. Session
     # 2. User settings
     # 3. Browser settings
     # 4. Client address
     # 5. Default locale from config
 }
 
 sub action : Local {
     my ($self,$c) = @_;
     
     $c->stash->{title} = $c->maketext('Hello world!');
     $c->stash->{location} = $c->i18n_geocode->name;
     $c->stash->{language} = $c->language;
     $c->stash->{localtime} = $c->i18n_datetime_format_date->format_datetime(DateTime->now);
 }

If you want to load all available roles and traits you can use 
L<CatalystX::I18N::Role::All> as a shortcut.

 package MyApp::Catalyst;
 use strict;
 use warnings;
 use Catalyst qw/
     +CatalystX::I18N::Role::All
 /;

=head1 DESCRIPTION

CatalystX::I18N provides a comprehensive toolset for internationalisation 
(I18N) and localisation (L10N) of catalyst applications. This distribution 
consists of several modules that are designed to integrate seamlessly, but
can be run idependently or replaced easily if necessary.

=over

=item * L<CatalystX::I18N::Role::Base> 

Basic I18N role that glues everything toghether.

=item * L<CatalystX::I18N::Role::Maketext> 

Localize text via L<Locale::Maketext>. Prefered over 
L<CatalystX::I18N::Role::DataLocalize>

=item * L<CatalystX::I18N::Role::DataLocalize> 

Localize text via L<Data::Localize>. Alternative to 
L<CatalystX::I18N::Role::Maketext>

=item * L<CatalystX::I18N::Role::PosixLocale> 

Sets the POSIX locale

=item * L<CatalystX::I18N::Role::DateTime>

Methods for localising date and time informations.

=item * L<CatalystX::I18N::Role::NumberFormat>

Methods for localising numbers.

=item * L<CatalystX::I18N::TraitFor::Request>

Extends L<Catalyst::Request> with usefull methods to help dealing with
various I18N related information in HTTP requests.

=item * L<CatalystX::I18N::TraitFor::Response>

Adds a C<Content-Language> header to the response.

=item * L<CatalystX::I18N::Role::GetLocale> 

Tries to determine the most appropriate locale for the current request.

=item * L<CatalystX::I18N::Model::Maketext>

Provides access to L<Locale::Maketext> classes via a Catalyst model.

=item * L<CatalystX::I18N::Model::DataLocalize>

Provides access to a L<Data::Localize> class via a Catalyst model.

=item * L<CatalystX::I18N::Maketext>

Helpful wrapper around L<Locale::Maketext>. Can also be used outside of 
Catalyst.

=item * L<CatalystX::I18N::DataLocalize>

Helpful wrapper around L<Data::Localize>. Can also be used outside of 
Catalyst.

=back

=head1 CONFIGURATION

In order to work properly, CatalystX::I18N will need some values in your
Catalyst configuration

 __PACKAGE__->config( 
     name    => 'MyApp', 
     I18N    => {
         default_locale     => 'de_AT', # Fallback locale
         locales            => {
             'de'               => {
                 inactive           => 1,
                 # Mark this locale as inactive (sort of abstract locale)
                 ...
                 # Arbitrary configuration parameters
             },
             'de_AT'            => {
                 inherits           => 'de',
                 # Inherit all settings form the 'de' locale
                 ...
             },
         }
     },
 );

The configuration must be stored under the key C<I18N>. It should contain
a hashref of C<locales> and optionally a default locale (C<default_locale>).

Locales can be marked as C<inactive>. Inactive locales will not be selected
by the L<CatalystX::I18N::Role::GetLocale/get_locale> method.

Locales can inherit from other locales (C<inherits>). All configuration values
from inherited locales will be copied. If you use 
L<CatalystX::I18N::Model::Maketext> together with L<CatalystX::I18N::Maketext>
the generated lexicons will also inherit in the selected order.

Additional configuration values are defined by the various 
CatalystX::I18N::Role::* plugins.

=head1 EXTENDING

Extending the functionality of CatalystX::I18N distribution is easy.

E.g. writing a new plugin that does some processing when the locale is set

 package CatalystX::MyI18N::Role::MyPlugin;
 use Moose::Role;
 use namespace::autoclean;
 
 after 'set_locale' => sub {
     my ($c,$locale) = @_;
     $c->do_someting($c->locale);
 };
 
 1;

=head1 SEE ALSO

L<Locale::Maketext>, <Locale::Maketext::Lexicon>, L<Data::Localize>, 
L<Number::Format>, L<DateTime::Locale>, L<DateTime::Format::CLDR>, 
L<DateTime::TimeZone>, L<HTTP::BrowserDetect> and L<Locale::Geocode>

=head1 SUPPORT

Please report any bugs or feature requests to 
C<catalystx-i18n@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=CatalystX::I18N>.
I will be notified and then you'll automatically be notified of the progress 
on your report as I make changes.

=head1 AUTHOR

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com
    
    http://www.k-1.com

=head1 COPYRIGHT

CatalystX::I18N is Copyright (c) 2012 Maroš Kollár 
- L<http://www.k-1.com>

=head1 LICENCE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut