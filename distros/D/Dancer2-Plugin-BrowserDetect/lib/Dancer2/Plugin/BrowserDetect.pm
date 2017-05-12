#
# This file is part of Dancer2-Plugin-BrowserDetect
#
# This software is copyright (c) 2016 by Natal Ngétal.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Dancer2::Plugin::BrowserDetect;
$Dancer2::Plugin::BrowserDetect::VERSION = '1.163590';
use strict;
use warnings;

use Dancer2::Plugin 0.200000;

use HTTP::BrowserDetect ();
use Scalar::Util ();

#ABSTRACT: Provides an easy to have info of the browser.


sub BUILD {
    my $plugin = shift;
    # Create a weakened plugin that we can close over to avoid leaking.
    Scalar::Util::weaken( my $weak_plugin = $plugin );
    $plugin->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'before_template',
            code => sub {
                my $tokens = shift;
                $tokens->{browser_detect} = $weak_plugin->browser_detect;
            },
        )
    );
}

plugin_keywords 'browser_detect';

sub browser_detect {
    my $plugin = shift;
    my $useragent = $plugin->app->request->env->{HTTP_USER_AGENT};
    my $browser   = HTTP::BrowserDetect->new($useragent);

    return $browser;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::BrowserDetect - Provides an easy to have info of the browser.

=head1 VERSION

version 1.163590

=head1 SYNOPSIS

    use Dancer2;
    use Dancer2::Plugin::BrowserDetect;

    get '/' => sub {
        my $browser = browser_detect();

        if ( $browser->windows && $browser->ie && $browser->major() < 6 ) {
            return "You have big failed, change your os, browser, and come back late.";
        }
    };

    dance;

=head1 DESCRIPTION

Provides an easy to have info of the browser.
keyword within your L<Dancer> application.

=head1 METHODS

=head2 browser_detect

    browser_detect()
or
    <% browser_detect %>

To have info of the browser

    input: none
    output: A HTTP::BrowserDetect object

=head1 CONTRIBUTING

This module is developed on Github at:

L<https://github.com/hobbestigrou/Dancer2-Plugin-Browser>

Feel free to fork the repo and submit pull requests

=head1 BUGS

Please report any bugs or feature requests in github.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer2::Plugin::BrowserDetect

=head1 SEE ALSO

L<Dancer>
L<HTTP::BrowserDetect>
L<Catalyst::TraitFor::Request::BrowserDetect>
L<Mojolicious::Plugin::BrowserDetect>
L<Dancer::Plugin::Browser>

=head1 AUTHOR

Natal Ngétal

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Natal Ngétal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
