# THIS IS BORROWED FROM Gantry::Utils::Crypt
# He did not have Crypt::CBC listed as a dependency, and didn't fix it
# even though it was listed as a bug several years ago. Thus, I have copied
# this into my package so that installation will work. Also, since this was a
# part of the Gantry web Framework, it would install a lot of unnecessary modules
# not needed for DBIx::Raw. So I have copied this here for my own use. If you are
# interested in using this crypt functionality, please see Gantry::Utils::Crypt instead
# of using this module
package DBIx::Raw::Crypt;
use strict;

use Crypt::CBC;
use MIME::Base64;
use Digest::MD5 qw( md5_hex );

sub new {
    my ( $class, $opt ) = @_;

    my $self = { options => $opt };
    bless( $self, $class );

    my @errors;
    foreach( qw/secret/ ) {
        push( @errors, "$_ is not set properly" ) if ! $opt->{$_};
    }

    if ( scalar( @errors ) ) {
        die join( "\n", @errors );
    }
    
    # populate self with data from site
    return( $self );

} # end new

#-------------------------------------------------
# decrypt()
#-------------------------------------------------
sub decrypt { 
    my ( $self, $encrypted ) = @_;

    $encrypted ||= '';
    $self->set_error( undef );
    
    local $^W = 0;
    
    my $c;
    eval {
        $c = new Crypt::CBC ( {    
            'key'         => $self->{options}{secret},
            'cipher'      => 'Blowfish',
            'padding'     => 'null',
        } );
    };
    if ( $@ ) {
        my $error = (
            "Error building CBC object are your Crypt::CBC and"
            . " Crypt::Blowfish up to date?  Actual error: $@"
        );
        
        $self->set_error( $error );   
        die $error;
    }

    my $p_text = $c->decrypt( MIME::Base64::decode( $encrypted ) );
    
    $c->finish();
    
    my @decrypted_values = split( ':;:', $p_text );
    my $md5              = pop( @decrypted_values );
    my $omd5             = md5_hex( join( '', @decrypted_values ) ) || '';

    if ( $omd5 eq $md5 ) {
        if ( wantarray ) { 
            return @decrypted_values;
        }
        else {
            return join( ' ', @decrypted_values );            
        } 
    }
    else {
        $self->set_error( 'bad encryption' );
    }

} # END decrypt_cookie

#-------------------------------------------------
# encrypt
#-------------------------------------------------
sub encrypt {
    my ( $self, @to_encrypt ) = @_;

    local $^W = 0;    
    $self->set_error( undef );
    
    my $c;
    eval {
        $c = new Crypt::CBC( {    
            'key'         => $self->{options}{secret},
            'cipher'     => 'Blowfish',
            'padding'    => 'null',
        } );
    };
    if ( $@ ) {
        my $error = (
            "Error building CBC object are your Crypt::CBC and"
            . " Crypt::Blowfish up to date?  Actual error: $@"
        );

        $self->set_error( $error );
        die $error;
    }

    my $md5 = md5_hex( join( '', @to_encrypt ) );
    push ( @to_encrypt, $md5 );
    
    my $str      = join( ':;:', @to_encrypt );    
    my $encd     = $c->encrypt( $str );    
    my $c_text   = MIME::Base64::encode( $encd, '' );

    $c->finish();
 
    return( $c_text );
    
} # END encrypt

#-------------------------------------------------
# set_error()
#-------------------------------------------------
sub set_error {
    my $self = shift;
    $self->{__error__} = shift;

    return $self->{__error__};
}

#-------------------------------------------------
# get_error()
#-------------------------------------------------
sub get_error {
    my $self = shift;
    return $self->{__error__};
}

# EOF
1;

__END__
