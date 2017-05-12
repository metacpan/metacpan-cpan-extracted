package Dancer::Plugin::reCAPTCHA;
# ABSTRACT: Easily integrate reCAPTCHA into your Dancer applications
{
    $Dancer::Plugin::reCAPTCHA::VERSION = '0.4';
}


use Dancer ':syntax';
use Dancer::Plugin;
use Captcha::reCAPTCHA;

my $rc = Captcha::reCAPTCHA->new;


register recaptcha_display => sub {
    my $conf = plugin_setting();
    return $rc->get_html( 
        $conf->{ public_key },
        undef,
        $conf->{ use_ssl },
        { theme =>  $conf->{ theme }},
    );
};


register recaptcha_check => sub {
    my ( $challenge, $response ) = @_;
    my $conf = plugin_setting();
    return $rc->check_answer(
        $conf->{ private_key },
        request->remote_address,
        $challenge,
        $response,
    );
};


register_plugin;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Plugin::reCAPTCHA - Easily integrate reCAPTCHA into your Dancer applications

=head1 VERSION

version 0.4

=head1 METHODS

=head2 recaptcha_display( )

Generates the HTML needed to display the CAPTCHA.  This HTML is returned as
a scalar value, and can easily be plugged into the template system of your 
choice.

Using Template Toolkit as an example, this might look like:

    # Code
    return template 'accounts/create', { 
        recaptcha => recaptcha_display(),
    };

    # In your accounts/create template
    [% recaptcha %]

=head2 recaptcha_check( $$ )

Verify that the value the user entered matches what's in the CAPTCHA.  This
methods takes two arguments: the challenge string and the response string.  
These are returned to your Dancer application as two parameters: 
F< recaptcha_challenge_field > and F< recaptcha_response_field >.

For example:

    my $challenge = param( 'recaptcha_challenge_field' );
    my $response  = param( 'recaptcha_response_field' );
    my $result    = recaptcha_check(
        $challenge, 
        $response,
    );
    die "User didn't match the CAPTCHA" unless $result->{ is_valid };

See L<Captcha::reCAPTCHA> for a description of the result hash.

=head1 SYNOPSIS
    # In your config.yml
    plugins:
      reCAPTCHA:
        public_key: "public key goes here"
        private_key: "private key goes here"
        theme: "clean"
        use_ssl: 0

    # In your application
    use Dancer::Plugin::reCAPTCHA;

    # In your form display....
    return template 'accounts/create', { 
        recaptcha => recaptcha_display(),
    };

    # In your template (TT2)
    [% recaptcha %]

    # In your validation code....
    my $challenge = param( 'recaptcha_challenge_field' );
    my $response  = param( 'recaptcha_response_field' );
    my $result    = recaptcha_check(
        $challenge, 
        $response,
    );
    die "User didn't match the CAPTCHA" unless $result->{ is_valid };

=head2 TODO

Add a real test suite.

=head1 SEE ALSO

=over 4

=item *

L<Captcha::reCAPTCHA>

=item *

L<Dancer::Plugin>

=item *

L<Dancer>

=back

=head1 AUTHOR

Jason A. Crome <cromedome@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jason A. Crome.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
