package CGI::Untaint::to_countrycode;
use warnings;
use strict;
use base 'CGI::Untaint::printable';
use Locale::Country();

sub is_valid {
    my ( $self ) = @_;
    
    my $codeset = $self->_codeset;

    # name in, code out
    if ( my $code = Locale::Country::country2code( $self->value, $codeset ) )
    {
        return $self->value( $code );
    }
    
    return;
}

sub _codeset { Locale::Constants::LOCALE_CODE_ALPHA_2 }

1;