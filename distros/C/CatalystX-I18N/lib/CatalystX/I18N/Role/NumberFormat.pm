# ============================================================================
package CatalystX::I18N::Role::NumberFormat;
# ============================================================================

use namespace::autoclean;
use utf8;

use Moose::Role;

use Number::Format;
use CatalystX::I18N::TypeConstraints;

use POSIX qw();

has 'i18n_numberformat' => (
    is          => 'rw',
    isa         => 'Number::Format',
    lazy_build  => 1,
    builder     => '_build_i18n_numberformat',
    clearer     => '_clear_i18n_numberformat',
);

sub _build_i18n_numberformat {
    my ($c) = @_;
    
    my $locale = $c->locale.'.UTF-8';
    my $config = $c->i18n_config;
    my $lconv = {};
    
    # Get lconv from POSIX
    # TODO: Get lconv setting only once at Catalyst startup
    {
        use locale;
        no strict 'refs';
        my %original;
        
        # Set locale 
        foreach my $category (qw(LC_NUMERIC LC_MONETARY)) {
            my $current_locale = POSIX::setlocale(&{"POSIX::".uc($category)});
            if ($current_locale ne $locale) {
                $original{$category} = $current_locale;
                POSIX::setlocale(&{"POSIX::".uc($category)},$locale);
            }
        }
        
        $lconv = POSIX::localeconv();
        
        # Reset locale to original state
        while (my ($category,$locale) = each %original) {
            POSIX::setlocale(&{"POSIX::".uc($category)},$locale);
        }
    }
    
    # Build custom defined for 5.8
    my $defined_or = sub {
        foreach (@_) {
            return $_
                if defined $_;
        }
    };
    
    # Set number format
    my $numberformat = Number::Format->new(
        -int_curr_symbol    => $defined_or->($config->{int_curr_symbol},$lconv->{int_curr_symbol},'EUR'),
        -currency_symbol    => $defined_or->($config->{currency_symbol},$lconv->{currency_symbol},'€'),
        -mon_decimal_point  => $defined_or->($config->{mon_decimal_point},$lconv->{mon_decimal_point},'.'),
        -mon_thousands_sep  => $defined_or->($config->{mon_thousands_sep},$lconv->{mon_thousands_sep},','),
        -mon_grouping       => $defined_or->($config->{mon_grouping},$lconv->{mon_grouping}),
        -positive_sign      => $defined_or->($config->{positive_sign},$lconv->{positive_sign},''),
        -negative_sign      => $defined_or->($config->{negative_sign},$lconv->{negative_sign},'-'),
        -int_frac_digits    => $defined_or->($config->{int_frac_digits},$lconv->{int_frac_digits},2),
        -frac_digits        => $defined_or->($config->{frac_digits},$lconv->{frac_digits},2),
        -p_cs_precedes      => $defined_or->($config->{p_cs_precedes},$lconv->{p_cs_precedes},1),
        -p_sep_by_space     => $defined_or->($config->{p_sep_by_space},$lconv->{p_sep_by_space},1),
        -n_cs_precedes      => $defined_or->($config->{n_cs_precedes},$lconv->{n_cs_precedes},1),
        -n_sep_by_space     => $defined_or->($config->{n_sep_by_space},$lconv->{n_sep_by_space},1),
        -p_sign_posn        => $defined_or->($config->{p_sign_posn},$lconv->{p_sign_posn},1),
        -n_sign_posn        => $defined_or->($config->{n_sign_posn},$lconv->{n_sign_posn},1),

        -thousands_sep      => $defined_or->($config->{thousands_sep},$lconv->{thousands_sep},','),
        -decimal_point      => $defined_or->($config->{decimal_point},$lconv->{decimal_point},'.'),
#        -grouping           => ($config->{grouping},$lconv->{grouping}),
        
        -decimal_fill       => $defined_or->($config->{decimal_fill},0),
        -neg_format         => $defined_or->($config->{negative_sign},$lconv->{negative_sign},'-').'x',
        -decimal_digits     => $defined_or->($config->{frac_digits},$lconv->{frac_digits},2),
    );
    
    return $numberformat;
}

after 'set_locale' => sub {
    my ($c,$locale) = @_;
    $c->_clear_i18n_numberformat();
};

no Moose::Role;
1;

=encoding utf8

=head1 NAME

CatalystX::I18N::Role::NumberFormat - Support for I18N number formating

=head1 SYNOPSIS

 package MyApp::Catalyst;
 
 use Catalyst qw/MyPlugins 
    CatalystX::I18N::Role::Base
    CatalystX::I18N::Role::NumberFormat/;

 package MyApp::Catalyst::Controller::Main;
 
 use strict;
 use warnings;
 use parent qw/Catalyst::Controller/;
 
 sub action : Local {
     my ($self,$c) = @_;
     
     $c->stash->{total} = $c->i18n_numberformat->format_price(102.34);
 }

=head1 DESCRIPTION

This role add support for localised numbers to your Catalyst application.

All methods are lazy. This means that the values will be only calculated
upon the first call of the method.

=head1 METHODS

=head3 i18n_numberformat

 my $number_format = $c->i18n_numberformat;
 $number_format->format_price(27.03);

Returns a L<Number::Format> object for your current locale. 

The L<Number::Format> settings will be taken from L<POSIX::localeconv> but 
can be overdriven in your Catalyst I18N configuration:

 # Add some I18N configuration
 __PACKAGE__->config( 
     name    => 'MyApp', 
     I18N    => {
         default_locale          => 'de_AT',
         locales                 => {
             'de_AT'                 => {
                 int_curr_symbol        => 'EURO',
             },
         }
     },
 );

Of course fetching the default locale settings via L<POSIX::localeconv> works
only if you have the requested locales installed.

The following configuration options are available (see L<Number::Format> for
detailed documentation):

=over

=item * int_curr_symbol

=item * currency_symbol

=item * mon_decimal_point

=item * mon_thousands_sep

=item * mon_grouping

=item * positive_sign

=item * negative_sign

=item * int_frac_digits

=item * frac_digits

=item * p_cs_precedes

=item * p_sep_by_space

=item * n_cs_precedes

=item * n_sep_by_space

=item * p_sign_posn

=item * n_sign_posn

=item * thousands_sep

=item * decimal_point

=item * decimal_fill

=item * neg_format

=item * decimal_digits

=back

=head1 SEE ALSO

L<Number::Format>

=head1 AUTHOR

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com
    
    L<http://www.k-1.com>