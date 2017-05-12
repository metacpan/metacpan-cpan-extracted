# ============================================================================
package CatalystX::I18N::Role::PosixLocale;
# ============================================================================

use namespace::autoclean;
use Moose::Role;
requires qw(set_locale);

use POSIX qw();

our $ORIGINAL_LOCALE;

after 'set_locale' => sub {
    my ($c,$locale) = @_;
    
    my $category = $c->i18n_posix_category;
    
    # Save original locale
    $ORIGINAL_LOCALE ||= POSIX::setlocale($category);
    
    # Set locale
    my $set_locale = $locale.'.UTF-8';
    
    my $set_locale_result = POSIX::setlocale( $category, $set_locale);
    unless (defined $set_locale_result
        && $set_locale eq $set_locale_result) {
        $set_locale_result = POSIX::setlocale( $category, $locale);
        unless (defined $set_locale_result) {
            $c->log->warn(sprintf("Could not setlocale '%s' or '%s' (do you have this locale installed?)",$set_locale,$locale))
                if $c->debug;
        }
    }
};

sub i18n_posix_category {
    my ($c,$category_string) = @_;
    
    $category_string ||= $c->config->{I18N}{posix_category};
    $category_string ||= 'LC_ALL';
    $category_string = uc($category_string);
    
    return 0
        unless grep  { $category_string eq $_ } qw(LC_ALL LC_COLLATE LC_MONETARY LC_NUMERIC);
    
    no strict 'refs';
    return &{"POSIX::".uc($category_string)};
}

after finalize => sub {
    my ($c) = @_;
    
    my $category = $c->i18n_posix_category;
    # Restore original locale
    POSIX::setlocale( $category, $ORIGINAL_LOCALE )
        if defined $ORIGINAL_LOCALE;
};

1;

=encoding utf8

=head1 NAME

CatalystX::I18N::Role::PosixLocale - Sets the POSIX locale

=head1 SYNOPSIS

 # In your catalyst base class
 package MyApp::Catalyst;
 
 use Catalyst qw/MyPlugins 
    CatalystX::I18N::Role::Base
    CatalystX::I18N::Role::PosixLocale/;

 sub action : Local {
     my ($self,$c) = @_;
     
     $c->locale('sk_SK')
     # POSIX LC_COLLATE locale is 'sk_SK.UTF-8' now
 }

=head1 DESCRIPTION

This role sets the POSIX locales for each request.

=head1 METHODS

=head3 i18n_posix_category 

Helper method that returns the value of the requested POSIX locale category
(LC_ALL, LC_COLLATE, LC_NUMERIC, LC_MONETARY). The POSIX category that should 
be used can be set in the I18N config. 

 __PACKAGE__->config( 
     I18N    => {
         posix_category     => 'LC_COLLATE',
     }
 );

Default is LC_ALL

=head CAVEATS

POSIX locale is set for the whole process, and might affect other modules
outside of Catalyst' scope. This role is also known to cause problems if
used in conjunction with the L<CatalystX::I18N::TraitFor::ViewTT> role

=head1 SEE ALSO

L<POSIX>, L<perllocale>

=head1 AUTHOR

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com
    
    L<http://www.k-1.com>