# ============================================================================
package CatalystX::I18N::Role::Base;
# ============================================================================

use namespace::autoclean;
use Moose::Role;
requires qw(config response log);

use CatalystX::I18N::TypeConstraints;
use Clone qw();


has 'locale' => (
    is          => 'rw',
    isa         => 'CatalystX::I18N::Type::Locale',
    lazy_build  => 1,
    builder     => '_build_default_locale',
    predicate   => 'has_locale',
    trigger     => sub { shift->set_locale(@_) },
);

sub _build_default_locale {
    my ($c) = @_;
    
    my $locale = $c->config->{I18N}{default_locale};
    $c->set_locale($locale);
    return $locale;
}

sub i18n_config {
    my ($c) = @_;
    
    return {}
        unless defined $c->config->{I18N}{locales}{$c->locale};
    
    my $config = Clone::clone($c->config->{I18N}{locales}{$c->locale});
    $config->{locale} = $c->locale;
    
    return $config;
}

sub i18n_geocode {
    my ($c) = @_;
    
    my $territory = $c->territory;
    
    return 
        unless $territory;
    
    Class::Load::load_class('Locale::Geocode');
    
    my $lc = Locale::Geocode->new();
    return $lc->lookup($territory);
} 

sub language {
    my ($self) = @_;
    
    return 
        unless $self->locale =~ $CatalystX::I18N::TypeConstraints::LOCALE_RE;
    
    return lc($1);
}

sub territory {
    my ($self) = @_;
    
    return 
        unless $self->locale =~ $CatalystX::I18N::TypeConstraints::LOCALE_RE;
    
    return
        unless $2;
    
    return lc($2);
}

sub set_locale {
    my ($c,$value) = @_;
    
    return
        unless $value =~ $CatalystX::I18N::TypeConstraints::LOCALE_RE;
    
    my $meta_attribute = $c->meta->get_attribute('locale');
    
    my $language = $1;
    my $territory = $2;
    my $locale = lc($language);
    $locale .= '_'.uc($territory)
        if defined $territory && $territory ne '';
    
    # Check for valid locale
    if (! exists $c->config->{I18N}{locales}{$locale}
        || $c->config->{I18N}{locales}{$locale}{inactive} == 1) {
        $meta_attribute->clear_value($c);
        return;
    }
    
    # Set content language header
    $c->response->content_language($language)
        if $c->response->can('content_language');
    
    # Save locale in session
    if ($c->can('session')) {
        $c->session->{i18n_locale} = $locale
    }
    
    # Set locale
    $meta_attribute->set_raw_value($c,$locale)
        if ! $meta_attribute->has_value($c)
        || $meta_attribute->get_raw_value($c) ne $locale;
    
    return $locale;
}


after setup_finalize => sub {
    my ($app) = @_;
    
    $app->config->{I18N} ||= {};
    my $config = $app->config->{I18N};
    my $locales = $config->{locales} ||= {};
    
    my $locale_type_constraint = $app
        ->meta
        ->get_attribute('locale')
        ->type_constraint;
    
    my $default_locale = $config->{default_locale};
    if (defined $default_locale
        && ! $locale_type_constraint->check($default_locale)) {
        Catalyst::Exception->throw(sprintf("Default locale '%s' does not match %s",$default_locale,$CatalystX::I18N::TypeConstraints::LOCALE_RE));
    }
    
    # Default locale fallback
    $default_locale ||= 'en';
    
    # Enable default locale
    $locales->{$default_locale} ||= {};
    
    # Build inheritance tree
    my (%tree,$changed);
    $changed = 1;
    while ($changed) {
        $changed = 0;
        foreach my $locale (keys %$locales) {
            next
                if exists $tree{$locale};
            my $locale_config = $locales->{$locale};
            my $locale_inactive = $locale_type_constraint->check($locale) ? 0:1;
            $locale_config->{inactive} = 0
                unless defined $locale_config->{inactive};
            if ($locale_config->{inactive} == 0
                && $locale_config->{inactive} != $locale_inactive) {
                $app->log->warn(sprintf("Locale '%s' has been set inactive because it does not match %s",$locale,$CatalystX::I18N::TypeConstraints::LOCALE_RE));
                $locale_config->{inactive} = 1;
            }
            
            unless (exists $locale_config->{inherits}) {
                $locale_config->{_inherits} = [];
                $tree{$locale} = $locale_config;
                $changed = 1;
            } elsif (exists $tree{$locale_config->{inherits}}) {
                my $inactive = $locale_config->{inactive};
                my @inheritance = (@{$tree{$locale_config->{inherits}}->{_inherits}},$locale_config->{inherits});
                $tree{$locale} = $locales->{$locale} = $locale_config = Catalyst::Utils::merge_hashes($tree{$locale_config->{inherits}}, $locale_config);
                $locale_config->{_inherits} = \@inheritance;
                $locale_config->{inactive} = $inactive;
                $changed = 1;
            }
        }
    }
    # Check inheritance tree for circular references
    foreach my $locale (keys %$locales) {
        my $locale_config = $locales->{$locale};
        unless (exists $locale_config->{_inherits}) {
            Catalyst::Exception->throw(sprintf("Circular I18N inheritance detected between '%s' and '%s'",$locale,$locale_config->{inherits}))
        }
    }
};

no Moose::Role;
1;

=encoding utf8

=head1 NAME

CatalystX::I18N::Role::Base - Basic catalyst I18N support

=head1 SYNOPSIS

 package MyApp::Catalyst;
 
 use Catalyst qw/MyPlugins 
    CatalystX::I18N::Role::Base/;

 package MyApp::Catalyst::Controller::Main;
 use strict;
 use warnings;
 use parent qw/Catalyst::Controller/;
 
 sub action : Local {
     my ($self,$c) = @_;
     
     $c->locale('de_AT');
 }

=head1 DESCRIPTION

This role is required by all other roles and provides basic I18N support for
Catalyst.

=head1 METHODS

=head3 locale

 $c->locale('de_AT');
 OR
 my $locale  = $c->locale();

Get/set the current locale. Changing this value has some side-effects:

=over

=item * Stores the locale in the current session (if any)

=item * Sets the 'Content-Language' response header (if L<CatalystX::I18N::TraitFor::Response> has been loaded)

=back

=head3 set_locale

Same as C<$c-E<gt>locale($locale);>.

=head3 language

Returns the language part of the current locale

=head3 territory

Returns the territory part of the current locale

=head3 i18n_config

Returns the (cloned) I18N config hash for the current locale.

=head3 i18n_geocode

 my $lgt = $c->i18n_geocode
 say $lgt->name;

Returns a L<Locale::Geocode::Territory> object for the current territory.

=head1 SEE ALSO

L<POSIX>, L<Locale::Geocode>

=head1 AUTHOR

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com
    
    L<http://www.k-1.com>
