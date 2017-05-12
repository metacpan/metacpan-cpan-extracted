package Dancer2::Plugin::Github::Webhook;

use strict;
use warnings;
use Dancer2::Plugin;

our $VERSION = '0.01';

has secret => (
    is          => 'ro',
    from_config => sub { return undef },
);

plugin_keywords 'require_github_webhook_secret';

=head1 NAME

Dancer2::Plugin::Github::Webhook - Check Github Webhook secret

=head1 DESCRIPTION

This plugin can be used to verify if routes that are used as Github webhook payload URL 
use the correct secret.

=head1 SYNOPSIS

Set the secret in your app configuration if you want it global:

  plugins:
    Github::Webhook:
      secret: '|8MVY)<[2Zh@!f39=<NSoCB02Btb#LTQ6Ty0dlA*4s'

Define that a route has to be correctly signed:

    post '/githubinfo' => require_github_webhook_secret sub { do_something_with_correctly_signed_payload(); };

Define that a route has to be correctly signed with a specific secret.

    post '/otherwebhook' => require_github_webhook_secret 'KUksrZyREtM32mIPoxcV7Cqx' => sub {
        do_something_with_correctly_signed_payload();
    };

    post '/otherwebhook' => require_github_webhook_secret config->{githubwebhooks}->{otherwebhook} => sub {
        do_something_with_correctly_signed_payload();
    };

=head1 CONTROLLING ACCESS TO ROUTES

=head2 require_github_webhook_secret [ $secret ]

    post '/reload-app' => require_github_webhook_secret 'mysecret' => sub {
        ...
    };

Only executes the route's sub if the payload is correctly signed. If no secret is given, we use the one 
you configured in your config file (see above). If you need different secrets within your app, you can 
provide it here or use on from the configuration file via C<< config->{anyconfigentry} >>.

=cut

sub require_github_webhook_secret {
    my $plugin  = shift;
    my $coderef = pop;
    my $secret  = shift || $plugin->secret() || $plugin->dsl->log( error => 'No secret given!' );

    return sub {
        my $x_hub_signature = $plugin->dsl->request_header('X-Hub-Signature')
            or return $plugin->dsl->send_error( "No X-Hub-Signature found", 403 );

        require Digest::SHA;
        my $calculated_signature = 'sha1=' . Digest::SHA::hmac_sha1_hex( $plugin->dsl->request->content // '', $secret );

        return $coderef->($plugin) if $x_hub_signature eq $calculated_signature;
        $plugin->dsl->log( info => 'Github Webhook call not signed correctly: '
                . $x_hub_signature
                . ' (expected: '
                . $calculated_signature
                . ')' );
        $plugin->dsl->send_error( "Not allowed", 403 );
    };
}

=head1 AUTHOR

Dominic Sonntag, C<< <dominic at s5g.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer2-plugin-auth-extensible-rights at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer2-Plugin-Auth-Extensible-Rights>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer2::Plugin::Github::Webhook


If you want to contribute to this module, write me an email or create a
Pull request on Github: L<https://github.com/sonntagd/Dancer2-Plugin-Github-Webhook>


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Dominic Sonntag.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;    # End of Dancer2::Plugin::Github::Webhook
