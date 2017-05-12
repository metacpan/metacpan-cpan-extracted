# NAME

Catalyst::TraitFor::Controller::CAPTCHA - authenticate human by create and validate captcha

# VERSION

version 1.2

# SYNOPSIS

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

# SUMMARY

This Catalyst::Controller role provides `Private` methods that deal with the generation and validation of captcha.

## CONFIGURATION

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

## DESCRIPTION

This controller's private methods will create and validate captcha.This module is based/altered from [Catalyst::Plugin::Captcha](https://metacpan.org/pod/Catalyst::Plugin::Captcha) because that shouldn't be a Catalyst::Plugin.Now it is a base controller like [Catalyst::TraitFor::Controller::reCAPTCHA](https://metacpan.org/pod/Catalyst::TraitFor::Controller::reCAPTCHA).It uses [GD::SecurityImage](https://metacpan.org/pod/GD::SecurityImage) and requires a session plugins like [Catalyst::Plugin::Session](https://metacpan.org/pod/Catalyst::Plugin::Session).

## METHODS

### generate\_captcha : Private

This will create and respond the captcha.
 

    $c->forward('generate_captcha');

### validate\_captcha : Private

This will validate the given string  against the Captcha image that has been generated earlier.
 

    if ( $c->forward('validate_captcha',[$posted_string]) ) {
      #do something based on the CAPTCHA passing
    }

# SEE ALSO

- [Catalyst::TraitFor::Controller::reCAPTCHA](https://metacpan.org/pod/Catalyst::TraitFor::Controller::reCAPTCHA)
- [Catalyst::Controller](https://metacpan.org/pod/Catalyst::Controller) 
- [Catalyst](https://metacpan.org/pod/Catalyst)
- [GD::SecurityImage](https://metacpan.org/pod/GD::SecurityImage)

# ACKNOWLEDGEMENTS

This module is almost copied from Diego Kuperman [Catalyst::Plugin::Captcha](https://metacpan.org/pod/Catalyst::Plugin::Captcha).

# AUTHOR

Baskar Nallathambi <baskarmusiri@gmail.com>,<baskar@exceleron.com>

# COPYRIGHT AND LICENSE

This is free module.You can do anything to this module under
the same terms as the Perl 5 programming language system itself.
