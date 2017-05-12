=head1 NAME

Dancer::Plugin::Captcha::AreYouAHuman - Easily integrate AreYouAHuman captcha into your Dancer applications

=head1 SYNOPSIS

 use Dancer::Plugin::Captcha::AreYouAHuman "is_a_human";

 # in config.yml
 plugins:
    Captcha::AreYouAHuman:
        publisher_key: BAADBEEFBAADBEEF
        scoring_key: BEEFBEEFBEEFBEEF

 # before template render
 human_checker true;
 template "file.tt";

 # In your template (TT2)
 [% are_you_a_human %]

 # In your validation code....
 if ( is_a_human ) {
     print "You're a human!\n";
 }
 else {
     print "Not a human\n":
 }

=head1 METHODS

=head2 human_checker

set ture when you need it.

but by default is false

Enable the directive "are_you_a_human" in the template

e.g.: human_checker true;

=head2 is_a_human

check the inputs are coming from a human visitor or not.

return value is 1 or 0 or undef

=head2 [% are_you_a_human %]

template directive to print out the validating html

=head2 TODO
 
 Add a real test suite.

=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer-plugin-captcha-areyouahuman at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer::Plugin::Captcha::AreYouAHuman>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::Captcha::AreYouAHuman

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer-Plugin-Captcha-AreYouAHuman>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer-Plugin-Captcha-AreYouAHuman>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer-Plugin-Captcha-AreYouAHuman>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer-Plugin-Captcha-AreYouAHuman>

=item * GIT Respority

L<https://bitbucket.org/mvu8912/p5-dancer-plugin-captcha-areyouahuman>

=back

=head1 SEE ALSO
 
=over 4
 
=item *
 
L<Captcha::AreYouAHuman>
 
=item *
 
L<Dancer::Plugin>
 
=item *
 
L<Dancer>
 
=back

=head1 AUTHOR

Michael Vu, C<< <micvu at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

package Dancer::Plugin::Captcha::AreYouAHuman;
{
  $Dancer::Plugin::Captcha::AreYouAHuman::VERSION = '1';
}
use Dancer ":syntax";
use Dancer::Plugin;
use Captcha::AreYouAHuman;

hook before_template_render => sub {
    if ( !human_checker() ) { return }
    my $stash = shift;
    my $ayah  = _ayah();
    my $html  = $ayah->getPublisherHTML;
    my $code  = _conversion_code();
    $stash->{ayah}                 = $ayah;
    $stash->{ayah_publisher_html}  = $html;
    $stash->{ayah_conversion_code} = $code;
    $stash->{are_you_a_human}      = $html . $code;
};

register human_checker => sub {
    my $set = shift;
    if ( defined $set ) {
        var use_ayah_form => $set;
    }
    return var "use_ayah_form";
};

register is_a_human => sub {
    my $session_secret = _session_secret()
      or return;
    my $client_ip = request->env->{REMOTE_ADDR}
      or return;
    return _ayah()->scoreResult(
        session_secret => $session_secret,
        client_ip      => $client_ip,
    );
};

sub _conversion_code {
    my $session_secret = _session_secret()
      or return q{};
    return _ayah()->recordConversion( session_secret => $session_secret );
};

sub _session_secret {
    return param "session_secret";
}

sub _ayah {
    var("ayah") or _build_ayah();
}

sub _build_ayah {
    my $setting       = plugin_setting;
    my $publisher_key = $setting->{publisher_key}
      or die "Missing publisher_key";
    my $scoring_key = $setting->{scoring_key}
      or die "Missing scoring_key";
    my $captcha = Captcha::AreYouAHuman->new(
        publisher_key => $publisher_key,
        scoring_key   => $scoring_key,
    );
    return var ayah => $captcha;
}

register_plugin;

