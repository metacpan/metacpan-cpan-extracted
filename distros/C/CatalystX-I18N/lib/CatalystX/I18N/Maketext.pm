# ============================================================================
package CatalystX::I18N::Maketext;
# ============================================================================

use strict;
use warnings;

use parent qw(Locale::Maketext);

use Locale::Maketext::Lexicon;
use CatalystX::I18N::TypeConstraints;
#use Locale::Maketext::Lexicon::Gettext;
use Path::Class;

sub load_lexicon {
    my ( $class, %params ) = @_;

    my $locales = $params{locales} || [];
    my $directories = $params{directories};
    my $gettext_style = defined $params{gettext_style} ? $params{gettext_style} : 1;
    my $inheritance = $params{inheritance} || {};
    
    $directories = [ $directories ]
        if defined $directories
        && ref $directories ne 'ARRAY';
    $directories ||= [];
    $locales = [ $locales ]
        unless ref $locales eq 'ARRAY';
    
    die "Invalid locales"
        unless defined $locales
        && scalar @$locales > 0
        && ! grep {  $_ !~ $CatalystX::I18N::TypeConstraints::LOCALE_RE } @$locales;
    
    {
        no strict 'refs';
        my $lexicon_loaded = ${$class.'::LEXICON_LOADED'};
        if (defined $lexicon_loaded
            && $lexicon_loaded == 1) {
            warn "Lexicon has already been loaded for $class";
            return;
        }
    }
    
    my $lexicondata = {
        _decode => 1,
    };
    $lexicondata->{_style} = 'gettext'
        if $gettext_style;
    
    my %locale_loaded;
    
    # Loop all directories
    foreach my $directory (@$directories) {
        next 
            unless defined $directory;
        
        $directory = Path::Class::Dir->new($directory)
            unless ref $directory eq 'Path::Class::Dir';
        
        next
            unless -d $directory->stringify && -e _ && -r _;
        
        my @directory_content =  $directory->children();
        
        # Load all avaliable message files
        foreach my $locale (@$locales) {
            my $lc_locale = lc($locale);
            $lc_locale =~ s/-/_/g;
            my @locale_lexicon;
            foreach my $content (@directory_content) {
                if ($content->is_dir) {
                    push(@locale_lexicon,'Slurp',$content->stringify)
                        if $content->basename eq $locale;
                } else {
                    my $filename = $content->basename;
                    if ($filename =~ m/^$locale\.(mo|po)$/i) {
                        push(@locale_lexicon,'Gettext',$content->stringify);
                    } elsif ($filename =~ m/^$locale\.m$/i) {
                        push(@locale_lexicon,'Msgcat',$content->stringify);
                    } elsif($filename =~ m/^$locale\.db$/i) {
                        push(@locale_lexicon,'Tie',[ $class, $content->stringify ]);
                    } elsif ($filename =~ m/^$lc_locale\.pm$/) {
                        $locale_loaded{$locale} = 1;
                        require $content->stringify;
                        # TODO transform maketext -> gettext syntax if flag is set
                        # Locale::Maketext::Lexicon::Gettext::_gettext_to_maketext
                    }
                }
            }
            $lexicondata->{$locale} = \@locale_lexicon
                if scalar @locale_lexicon;
        }
    }
    
    # Fallback lexicon
    foreach my $locale (@$locales) {
        next
            if exists $inheritance->{$locale};
        next
            if exists $locale_loaded{$locale};
        $lexicondata->{$locale} ||= ['Auto'];
    }
    
    eval qq[
        package $class;
        our \$LEXICON_LOADED = 1;
        Locale::Maketext::Lexicon->import(\$lexicondata)
    ];
    
    while (my ($locale,$inherit) = each %$inheritance) {
        my $locale_class = lc($locale);
        my $inherit_class = lc($inherit);
        $locale_class =~ s/-/_/g;
        $inherit_class =~ s/-/_/g;
        $locale_class = $class.'::'.$locale_class;
        $inherit_class = $class.'::'.$inherit_class;
        no strict 'refs';
        push(@{$locale_class.'::ISA'},$inherit_class);
    }
    
    die("Could not load Locale::Maketext::Lexicon") if $@;
    return;
}

#sub set_lexicon {
#    my ( $class, $locale, $lexicon ) = @_;
#    
#    $locale = lc($locale);
#    $locale =~ s/-/_/g;
#        
#    no strict 'refs';
#    %{$class .'::'.$locale.'::Lexicon'} = %{$lexicon};
#    return;
#}

1;

=encoding utf8

=head1 NAME

CatalystX::I18N::Maketext - Wrapper around Locale::Maketext

=head1 SYNOPSIS

 package MyApp::Maketext;
 use parent qw(CatalystX::I18N::Maketext);

=head1 DESCRIPTION

This class can be used as your Maketext base-class. It is a wrapper around
L<Locale::Maketext> and provides methods for auto-loading lexicon files.
It is designed to work toghether with L<CatalystX::Model::Maketext>.

You need to subclass this package in your project in order to use it.

=head1 MEDTHODS

=head3 load_lexicon

 MyApp::Maketext->load_lexicon(
     locales        => ['de','de_AT'],              # Required
     directories    => ['/path/to/your/maketext/files'], # Required
     gettext_style  => 0,                           # Optional, Default 1
     inheritance    => {                            # Optional
         de_AT          => 'de',
     },
 );

This method will search the given directories and load all available maketext
files for the requested locales

=over

=item * *.mo, *.po

via L<Locale::Maketext::Lexicon::Gettext>

=item * *.db

via L<Locale::Maketext::Lexicon::Tie> The files will be tied to you Maketext 
class, thus you need to implement the necessary tie methods in your class.

=item * *.m

via L<Locale::Maketext::Lexicon::Msgcat>

=item * Directories

via L<Locale::Maketext::Lexicon::Slurp>

=item * Perl Packages

Will be loaded (only lowercase locale names e.g. locale 'de_AT' will only 
load 'de_at.pm'). The packages must have a C<%Lexion> variable. 

=back

If no translation files can be found for a given locale then 
L<Locale::Maketext::Lexicon::Auto> will be loaded.

The following parameters are recognized/required

=over

=item * locales

Array reference of locales.

Required

=item * directories

Array reference of directories. Also accepts L<Path::Class::Dir> objects
and single values.

Required

=item * gettext_style

Enable gettext style. C<%quant(%1,document,documents)> instead of 
C<[quant,_1,document,documents]>

Optional, Default TRUE

=item * inheritance

Set inheritance as as HashRef (e.g. 'en_US' inherits from 'en')

Optional

=back

=head1 SEE ALSO

L<Locale::Maketext> and L<Locale::Maketext::Lexicon>

=head1 AUTHOR

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com
    
    L<http://www.k-1.com>

