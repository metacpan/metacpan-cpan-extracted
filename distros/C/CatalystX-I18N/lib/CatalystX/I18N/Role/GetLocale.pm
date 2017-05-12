# ============================================================================
package CatalystX::I18N::Role::GetLocale;
# ============================================================================

use namespace::autoclean;
use Moose::Role;

use CatalystX::I18N::TypeConstraints;
use List::Util qw(first shuffle);

sub check_locale {
    my ($c,$locale) = @_;
    
    return
        unless defined $locale
        && $locale =~ m/^([a-zA-Z]{2})(?:_([a-zA-Z]{2}))?$/;
    
    $locale = lc($1);
    $locale .= '_'.uc($2)
        if defined $2;
    
    return 
        if ! exists $c->config->{I18N}{locales}{$locale}
        || $c->config->{I18N}{locales}{$locale}{inactive} == 1;
    
    return $locale;
}

sub get_locale_from_session {
    my ($c) = @_;
    
    if ($c->can('session')) {
        return $c->check_locale($c->session->{i18n_locale});
    }
    
    return;
}

sub get_locale_from_user {
    my ($c) = @_;
    
    if ($c->can('user')
        && defined $c->user
        && $c->user->can('locale')) {
        return $c->check_locale($c->user->locale);
    }
    
    return;
}

sub get_locale_from_browser  {
    my ($c) = @_;
    
    my ($languages,$territories) = ([],[]);
    
    # Get Accept-Language
    if ($c->request->can('accept_language')) {
        my $locales = $c->request->accept_language;
        # Check if Accept-Language matches a locale
        foreach my $locale (@$locales) {
            my $checked_locale = $c->check_locale($locale);
            return $checked_locale
                if $checked_locale;
            if ($locale =~ $CatalystX::I18N::TypeConstraints::LOCALE_RE) {
                push(@$languages,$1);
                push(@$territories,$2)
                    if $2;
            }
        }
    }
    
    # Get browser language
    if ($c->request->can('browser_language')) {
        my $language = $c->request->browser_language;
        if ($language) {
            unshift(@$languages,$language)
                unless grep { $language eq $_ } @$languages
        }
    }
    
    # Get client country
    if ($c->request->can('client_country')) {
        my $territory = $c->request->client_country;
        unshift(@$territories,uc($territory))
            if ($territory);
    }
    
    # Get browser territory
    if ($c->request->can('browser_territory')) {
        my $territory = $c->request->browser_territory;
        unshift(@$territories,uc($territory))
            if ($territory);
    }
    
    my $locale_config = $c->config->{I18N}{locales};
    
    # TODO: Make behaviour/preferences customizeable
    
    # Try to find best matching combination
    foreach my $territory (@$territories) {
        foreach my $language (@$languages) {
            my $key = $language.'_'.$territory;
            if (defined $locale_config->{$key}) {
                return $key;
            }
        }
    }
    
    # Try to find best matching country
    foreach my $locale (keys %$locale_config) {
        next
            if $locale_config->{$locale}{inactive};
        foreach my $territory (@$territories) {
            if ($locale =~ m/^[a-z]{2}_${territory}$/) {
                return $locale;
            }
        }
    }
    
    # Try to find best matching language
    foreach my $locale (keys %$locale_config) {
        next
            if $locale_config->{$locale}{inactive};
        foreach my $language (@$languages) {
            if ($locale =~ m/^${language}$/) {
                return $locale;
            }
        }
    }
    
    # Try to find best matching language
    foreach my $locale (keys %$locale_config) {
        next
            if $locale_config->{$locale}{inactive};
        foreach my $language (@$languages) {
            if ($locale =~ m/^${language}_[A-Z]{2}$/) {
                return $locale;
            }
        }
    }
    
    return;
}

sub get_locale {
    my ($c) = @_;
    
    my ($locale,$languages,$territory);
    my $locale_config = $c->config->{I18N}{locales};
    
    $locale = $c->get_locale_from_session();
    $locale ||= $c->get_locale_from_user();
    $locale ||= $c->get_locale_from_browser();
    
    # Default locale
    $locale ||= $c->config->{I18N}{default_locale};
    
    # Random locale
    $locale ||= first { $locale_config->{$_}{inactive} == 0 } shuffle keys %$locale_config;
    
    if ($c->can('locale')) {
        $c->locale($locale);
    }
    
    return $locale;
}

no Moose::Role;
1;

=encoding utf8

=head1 NAME

CatalystX::I18N::Role::GetLocale - Tries to determine the current users locale

=head1 SYNOPSIS

 package MyApp::Catalyst;
 
 use CatalystX::RoleApplicator;
 use Catalyst qw/MyPlugins 
    CatalystX::I18N::Role::Base
    CatalystX::I18N::Role::GetLocale/;
 
 __PACKAGE__->apply_request_class_roles(qw/CatalystX::I18N::TraitFor::Request/);
 __PACKAGE__->setup();

 package MyApp::Catalyst::Controller::Main;
 use strict;
 use warnings;
 use parent qw/Catalyst::Controller/;
 
 sub auto : Private { # Auto method will always be called first
     my ($self,$c) = @_;
     $c->get_locale();
 }

=head1 DESCRIPTION

This role provides many methods to retrieve/guess the best locale for the
current user.

=head1 METHODS

=head3 get_locale

Tries to determine the users locale in the given order

=over

=item 1. Session (via C<get_locale_from_session>)

=item 2. User (via C<get_locale_from_user>)

=item 3. Browser (via C<get_locale_from_browser>)

=item 4. Default locale from config (via C<$c-E<gt>config-E<gt>{I18N}{default_locale}>)

=item 5. Random locale

=back

Sets the winning locale (via C<$c-E<gt>locale()>) if the 
L<CatalystX::I18N::Role::Base> is loaded.

=head3 get_locale_from_browser

Tries to fetch the locale from the browser (via 
L<$c-E<gt>request-E<gt>accept_language> and 
L<$c-E<gt>request-E<gt>browser_language>). L<CatalystX::I18N::TraitFor::Request>
must be loaded.

=head3 get_locale_from_session

Tries to fetch the locale from the current session.

=head3 get_locale_from_user

Tries to fetch the locale from the user object (via 
L<$c-E<gt>user-E<gt>locale>).

=head3 check_locale

Helper method to check for a valid locale

=head1 AUTHOR

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com
    
    L<http://www.k-1.com>