# ============================================================================
package CatalystX::I18N::Role::Collate;
# ============================================================================

use utf8;

use namespace::autoclean;
use Moose::Role;
use namespace::autoclean;

use CatalystX::I18N::TypeConstraints;
use Unicode::Collate::Locale;

has 'i18n_collator' => (
    is          => 'rw',
    isa         => 'Unicode::Collate',
    lazy_build  => 1,
    builder     => '_build_i18n_collator',
    clearer     => '_clear_i18n_collator',
);

sub _build_i18n_collator {
    my ($c) = @_;
    
    my $language = $c->language;
    my $config = $c->i18n_config;
    $config->{collate} ||= {};
    
    my $collator = Unicode::Collate::Locale->new( locale => $language, %{$config->{collate}} );
    
    return $collator;
}

sub i18n_sort {
    my ($c,@arguments) = @_;
    
    @arguments = @{$arguments[0]}
        if scalar(@arguments) == 0 && ref($arguments[0]) eq 'ARRAY';
    
    my @results = $c->i18n_collator->sort(@arguments);
    
    return wantarray ? @results : \@results;
}

after 'set_locale' => sub {
    my ($c,$locale) = @_;
    $c->_clear_i18n_collator();
};

no Moose::Role;
1;

=encoding utf8

=head1 NAME

CatalystX::I18N::Role::Collate - Support for localised collation

=head1 SYNOPSIS

 package MyApp::Catalyst;
 
 use Catalyst qw/MyPlugins 
    CatalystX::I18N::Role::Base
    CatalystX::I18N::Role::Collate/;

 package MyApp::Catalyst::Controller::Main;
 use strict;
 use warnings;
 use parent qw/Catalyst::Controller/;
 
 sub action : Local {
     my ($self,$c) = @_;
     
     $c->locale('de');
     @sorted_names = $c->i18n_sort(qw/Algerien Ägypten Armenien Argentinien Äthiopien Afganistan Aserbaidschan/);
     
     $c->stash->{names} = \@sorted_names;
 }

=head1 DESCRIPTION

This role adds support for localised collation your Catalyst application.

 my @german_alphabeth = (A..Z,a..z,'ä','Ä','ü','Ü','ö','Ö','ß');
 
 $sort = join(',',sort @german_alphabeth);
 # $sort_no_collate is 'A,B,C,[...],Z,a,b,c,[...],z,Ä,Ö,Ü,ß,ä,ö,ü'
 
 $sort_localised = join(',',$c->i18n_sort(@german_alphabeth));
 # $sort_no_collate is 'a,A,ä,Ä,b,B,c,C,[...],s,S,ß,t,T,u,U,ü,Ü,v,V,w,[...],z,Z'

All methods are lazy. This means that the values will be only calculated
upon the first call of the method.

=head1 METHODS

=head3 i18n_sort

 my @sorted = $c->i18n_sort(@list);
 OR
 my $sorted = $c->i18n_sort(\@list);

Sorts the given list or arrayref with the current locale and returns a 
list or arrayref.

=head3 i18n_collator

  my $collator = $c->i18n_collator();

Returns a L<Unicode::Collate::Locale> object with the current language used
as the locale. The collator settings can be configured in your Catalyst I18N 
configuration:

 # Add some I18N configuration
 __PACKAGE__->config( 
     name    => 'MyApp', 
     I18N    => {
         default_locale => 'de_AT',
         locales        => {
             'de_AT'        => {
                 collate        => {
                     level          => 3,
                     variable       => 'Non-Ignorable',
                     ...
                 },
             },
         }
     },
 );

The following configuration options are available (see L<Unicode::Collate> for
detailed documentation):

=over

=item * UCA_Version

=item * alternate

=item * backwards

=item * entry

=item * hangul_terminator

=item * ignoreChar

=item * katakana_before_hiragana

=item * level

=item * normalization

=item * overrideCJK

=item * overrideHangul

=item * preprocess

=item * rearrange

=item * suppress

=item * table

=item * undefName

=item * undefChar

=item * upper_before_lower

=item * variable

=back

=head1 SEE ALSO

L<Unicode::Collate>

=head1 AUTHOR

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com
    
    L<http://www.k-1.com>