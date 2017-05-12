# ============================================================================
package CatalystX::I18N::DataLocalize;
# ============================================================================

use Moose;
extends qw(Data::Localize);

use Path::Class;
use CatalystX::I18N::TypeConstraints;
use Data::Localize::Format::Gettext;

sub gettext_formatter {
    my ($self) = @_;
    
    # Taken from Locale::Maketext
    my $numf = sub {
        my ($lang, $args) = @_;
        my $num = shift(@$args);
        
        if($num < 10_000_000_000 and $num > -10_000_000_000 and $num == int($num)) {
            $num += 0;  # Just use normal integer stringification.
            # Specifically, don't let %G turn ten million into 1E+007
        }
        else {
            $num = CORE::sprintf('%G', $num);
            # "CORE::" is there to avoid confusion with the above sub sprintf.
        }
        while( $num =~ s/^([-+]?\d+)(\d{3})/$1,$2/s ) {1}  # right from perlfaq5
        # The initial \d+ gobbles as many digits as it can, and then we
        #  backtrack so it un-eats the rightmost three, and then we
        #  insert the comma there.
        
        # This is just a lame hack instead of using Number::Format
        return $num;
    };
    
    my $numerate = sub {
        my ($lang, $args) = @_;
        my $num = shift(@$args);
        
        # return this lexical item in a form appropriate to this number
        my $s = ($num == 1);
        
        return '' 
            unless scalar(@$args);
        
        if(scalar(@$args) == 1) { # only the headword form specified
            return $s ? $args->[0] : ($args->[0] . 's'); # very cheap hack.
        }
        else { # sing and plural were specified
            return $s ? $args->[0] : $args->[1];
        }
    };
    
    my $formatter = Data::Localize::Format::Gettext->new(
        functions => {
            quant => sub {
                my ($lang, $args) = @_;
                my $num = shift(@$args);
                
                return $num if scalar(@$args) == 0; # what should this mean?
                return $args->[2] if scalar(@$args) > 2 and $num == 0; # special zeroth case
                return $numf->($lang,[$num]) . ' ' . $numerate->($lang,[$num,@$args]);
            },
            numerate => $numerate,
            numf => $numf,
        }
    );
    
    return $formatter;
}

sub add_localizers {
    my ( $self, %params ) = @_;
    
    my $locales = $params{locales} || [];
    my $directories = $params{directories};
    
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
    
    
    my $formatter;
    
    # Loop all directories
    foreach my $directory (@$directories) {
        next 
            unless defined $directory;
        
        $directory = Path::Class::Dir->new($directory)
            unless ref $directory eq 'Path::Class::Dir';
        
        next
            unless -d $directory->stringify && -e _ && -r _;
        
        $formatter ||= $self->gettext_formatter;
        
        $self->add_localizer(
            class       => "Gettext",
            path        => $directory.'/*.po',
            formatter   => $formatter,
        );
    }
    
    return;
}

1;

=encoding utf8

=head1 NAME

CatalystX::I18N::DataLocalize - Wrapper around Data::Localize

=head1 SYNOPSIS

 package MyApp::DataLocalize;
 use Moose;
 extends qw(CatalystX::I18N::DataLocalize);

=head1 DESCRIPTION

This class can be used as your Data Localize base-class. It is a wrapper around
L<Data::Localize> and provides methods for auto-loading po files.
It is designed to work toghether with L<CatalystX::Model::DataLocalize>.

You need to subclass this package in your project in order to use it.

=head1 MEDTHODS

=head3 load_lexicon

 MyApp::DataLocalize->add_localizer(
     locales        => ['de','de_AT'],              # Required
     directories    => ['/path/to/your/maketext/files'], # Required
 );

This method will search the given directories and load all available *.po
files.

This class provides only the most basic functionality and probably needs
to be re-implemented according to your specific requirements. 

=head1 SEE ALSO

L<Data::Localize>

=head1 AUTHOR

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com
    
    L<http://www.k-1.com>

