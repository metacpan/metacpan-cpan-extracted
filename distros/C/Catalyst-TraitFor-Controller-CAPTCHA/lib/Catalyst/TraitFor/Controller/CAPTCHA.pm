package Catalyst::TraitFor::Controller::CAPTCHA;

use Moose::Role;
use MooseX::MethodAttributes::Role;
use namespace::autoclean;

use GD::SecurityImage;
use HTTP::Date;

our $VERSION = '1.2';

use MRO::Compat;

sub generate_captcha : Private  {
    my ($self,$c)     = @_;

    my $conf  = $c->config->{captcha};

    my $new = $conf->{gd_config}        ||= {};
    my $create = $conf->{create}        ||= [];
    my $particle = $conf->{particle}    ||= [];
    my $out = $conf->{out}              ||= {};
    my $sname = $conf->{session_name}   ||= 'captcha_string';

    my $image = GD::SecurityImage->new( %{ $new } );

    $image->random();
    $image->create( @{ $create } );
    $image->particle( @{ $particle } );

    my ( $image_data, $mime_type, $random_string ) = $image->out( %{ $out } );

    #Store the captcha string to session for validation
    $c->session->{ $sname } = $random_string;

    $c->res->headers->expires( time() );
    $c->res->headers->header( 'Last-Modified' => HTTP::Date::time2str );
    $c->res->headers->header( 'Pragma'        => 'no-cache' );
    $c->res->headers->header( 'Cache-Control' => 'no-cache' );

    $c->res->content_type("image/$mime_type");
    $c->res->output($image_data);
}


sub validate_captcha : Private {
    my ($self, $c , $posted_string ) = @_;
    
    my $conf = $c->config->{captcha};
    my $sname = $conf->{session_name}   ||= 'captcha_string';

    my $string = $c->session->{ $sname };

    #Clear the Captcha 
    $c->session->{ $sname } = undef;

    return ( $posted_string && $string && $posted_string eq $string );

}

1;

__END__
=pod

=head1 NAME

Catalyst::TraitFor::Controller::CAPTCHA - authenticate human by create and validate captcha

=head1 VERSION

version 1.2

=head1 SYNOPSIS

In your controller

    package MyApp::Controller::MyController;
    use Moose;
    use namespace::autoclean;

    BEGIN { extends 'Catalyst::Controller' }
    with 'Catalyst::TraitFor::Controller::CAPTCHA';

    sub captcha_image  : Local :Args(0) {
        my ( $self, $c ) = @_;
        $c->forward('generate_captcha');
    }

    #Now <img src="/captcha_image" /> will have captcha and 
    #<input name="captcha_text" type="text"> will prompt user to enter captcha text 
    #and this should be embed into your form that needs to be validated.

    sub form_post : Local {
        my ($self,$c) = @_;
    
        my $posted_string = $c->req->body_params('captcha_text');    

        if ( $c->forward('validate_captcha',[$posted_string]) ) {
            #Allowed 
        }else {
            #Not Allowed 
        }
    }

    1;

=head1 SUMMARY

This Catalyst::Controller role provides C<Private> methods that deal with the generation and validation of captcha.

=head2 CONFIGURATION

In MyApp.pm (or equivalent in config file):

 __PACKAGE__->config->{captcha} = {
    session_name => 'captcha_string',
    #Refer GD::SecurityImage for additonal configuration  
    gd_config => {
        width => 100,
        height => 50,
        lines => 5,
        gd_font => 'giant',
    },
    create => [qw/normal rect/],
    particle => [10],
    out => {force => 'jpeg'}
};

=head2 DESCRIPTION

This controller's private methods will create and validate captcha.This module is based/altered from L<Catalyst::Plugin::Captcha> because that shouldn't be a Catalyst::Plugin.Now it is a base controller like L<Catalyst::TraitFor::Controller::reCAPTCHA>.It uses L<GD::SecurityImage> and requires a session plugins like L<Catalyst::Plugin::Session>.

=head2 METHODS

=head3 generate_captcha : Private

This will create and respond the captcha.
 
 $c->forward('generate_captcha');

=head3 validate_captcha : Private

This will validate the given string  against the Captcha image that has been generated earlier.
 
 if ( $c->forward('validate_captcha',[$posted_string]) ) {
   #do something based on the CAPTCHA passing
 }

=head1 REPOSITORY

L<https://github.com/Virendrabaskar/Catalyst-TraitFor-Controller-CAPTCHA>

=head1 SEE ALSO

=over 4

=item *

L<Catalyst::TraitFor::Controller::reCAPTCHA>

=item *

L<Catalyst::Controller> 

=item *

L<Catalyst>

=item *

L<GD::SecurityImage>

=back

=head1 ACKNOWLEDGEMENTS

This module is almost copied from Diego Kuperman L<Catalyst::Plugin::Captcha>.

=head1 AUTHOR

Baskar Nallathambi <baskarmusiri@gmail.com>,<baskar@exceleron.com>

=head1 COPYRIGHT AND LICENSE

This is free module.You can do anything to this module under
the same terms as the Perl 5 programming language system itself.

=cut
