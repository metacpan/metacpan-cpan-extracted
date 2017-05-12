package Captcha::NocaptchaMailru;

use strict;
use warnings;
use LWP::UserAgent;
use JSON;
use URI::Escape;
require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(
    nocaptcha_generate_captcha_url
    nocaptcha_generate_captcha_tag
    nocaptcha_check
    nocaptcha_check_detailed
);
use version 0.77; our $VERSION = version->declare('v1.0.0');

use constant API_SERVER => 'https://api-nocaptcha.mail.ru';

sub _is_check_response_correct {
    my ($resp) = @_;
    return 0 unless exists($resp->{status});
    if ($resp->{status} eq 'ok') {
        return 0 unless exists($resp->{is_correct});
        return 1;
    }
    return unless exists($resp->{desc}) and exists($resp->{code});
    return 1;
}

sub _get_json_by_url {
    my $agent = LWP::UserAgent->new();
    my $resp = $agent->get($_[0]);
    return 'request failed' unless $resp->is_success;
    my $json = eval {
        decode_json($resp->decoded_content);
    };
    return 'JSON parsing failed' if $@;
    return $json;
}

sub _pack_params {
    my ($hash) = @_;
    my @pairs;
    for my $key (keys %$hash) {
        push @pairs, join('=', map { uri_escape($_) } $key, $hash->{$key});
    }
    return join('&', @pairs);
}

sub _generate_check_url {
    my ($key, $id, $val) = @_;
    return API_SERVER . '/check?' . _pack_params({'private_key' => $key,
                                                  'captcha_id' => $id,
                                                  'captcha_value' => $val});
}

sub check_detailed {
    my ($key, $id, $val) = @_;
    my $url = _generate_check_url($key, $id, $val);
    my $resp = _get_json_by_url($url);
    return {is_ok => 0, error => $resp} unless ref($resp) eq 'HASH';
    return {is_ok => 0, error => 'invalid response'} unless _is_check_response_correct($resp);
    return {is_ok => 0, error => "$resp->{status}: $resp->{desc}"} unless $resp->{status} eq 'ok';
    return {is_ok => 1, is_correct => ($resp->{is_correct} ? 1 : 0)};
}

sub check {
    my $res = check_detailed(@_);
    return 1 if $res->{is_ok} and $res->{is_correct};
    return 0;
}

sub generate_captcha_url {
    return API_SERVER . '/captcha?' . _pack_params({'public_key' => $_[0]});
}

sub generate_captcha_tag {
    return '<script type="text/javascript" src="' .
            generate_captcha_url($_[0]) . '"></script>';
}

sub nocaptcha_generate_captcha_url {
    return generate_captcha_url(@_);
}

sub nocaptcha_generate_captcha_tag {
    return generate_captcha_tag(@_);
}

sub nocaptcha_check {
    return check(@_);
}

sub nocaptcha_check_detailed {
    return check_detailed(@_);
}

1;
__END__

=head1 NAME

Captcha::NocaptchaMailru - Module for working with Nocaptcha Mail.Ru service



=head1 SYNOPSIS

    use Captcha::NocaptchaMailru;

    use constant PUBLIC_KEY => 'e5238532bf56e4c24bd5489d463ac2a0';
    use constant PRIVATE_KEY => '3cf11185476394b85bcec3fbf16c69a4';

    my $script = nocaptcha_generate_captcha_tag(PUBLIC_KEY);

    if (nocaptcha_check(PRIVATE_KEY, $form_params->{captcha_id}, $form_params->{captcha_value})) {
        print('OK');
    }
    else {
        print('ERROR');
    }



=head1 DESCRIPTION

Nocaptcha is an intelligent CAPTCHA service that can deliver a majority of real
users from solving a CAPTCHA riddle with the same protection level from spam
scripts. The service has been successfully used in our internal projects and on
sites unrelated to Mail.Ru.

This module is Perl implementation of Nocaptcha Mail.Ru service API.

Use this email for feedback: nocaptcha@corp.mail.ru

=head2 EXPORT

=over

=item nocaptcha_generate_captcha_url

Same as C<Captcha::NocaptchaMailru::generate_captcha_url>.

=item nocaptcha_generate_captcha_tag

Same as C<Captcha::NocaptchaMailru::generate_captcha_tag>.

=item nocaptcha_check

Same as C<Captcha::NocaptchaMailru::check>.

=item nocaptcha_check_detailed

Same as C<Captcha::NocaptchaMailru::check_detailed>.

=back



=head1 METHODS

=head2 generate_captcha_url

Generate URL for Nocaptcha script. It should be placed in the page header.
Take public key as parameter.

=head2 generate_captcha_tag

Generate HTML tag for Nocaptcha script. It should be placed in the page header.
Take public key as parameter.

=head2 check

Check CAPTCHA value received from user. Parameters: private key, CAPTCHA ID,
CAPTCHA value. Return 1 if value is correct or 0 in other case.

=head2 check_detailed

Check CAPTCHA value received from user. Parameters: private key, CAPTCHA ID,
CAPTCHA value. Return reference to hash with keys: is_ok, is_correct, error.
If error occur is_ok=0 and error contains error message. In other case
is_ok=1 and is_correct contains result of check.



=head1 SEE ALSO

=over

=item * Official site

L<https://nocaptcha.mail.ru>

=item * Documentation

L<https://nocaptcha.mail.ru/docs>

=item * PHP module

L<https://github.com/mailru/nocaptcha-php>

=item * Python module

L<https://github.com/mailru/nocaptcha-python>

=back



=head1 AUTHOR

Oleg Kovalev, <man0xff@gmail.com>



=head1 COPYRIGHT AND LICENSE

=for html <a rel="license" href="http://creativecommons.org/publicdomain/zero/1.0/">
<img src="http://i.creativecommons.org/p/zero/1.0/88x31.png"
style="border-style: none;" alt="CC0"></a><br>

=for text Public Domain CC0, http://creativecommons.org/publicdomain/zero/1.0/

To the extent possible under law, Mail.Ru has waived all copyright and related
or neighboring rights to Perl module for working with Nocaptcha Mail.Ru
service. This work is published from: Russian Federation. 

=cut
