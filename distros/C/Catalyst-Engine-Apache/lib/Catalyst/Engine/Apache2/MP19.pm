package Catalyst::Engine::Apache2::MP19;
BEGIN {
  $Catalyst::Engine::Apache2::MP19::AUTHORITY = 'cpan:BOBTFISH';
}
BEGIN {
  $Catalyst::Engine::Apache2::MP19::VERSION = '1.16';
}
# ABSTRACT: Catalyst Apache2 mod_perl 1.99x Engine

use strict;
use warnings;
use base 'Catalyst::Engine::Apache2';

use Apache2             ();
use Apache::Connection  ();
use Apache::Const       -compile => qw(OK);
use Apache::RequestIO   ();
use Apache::RequestRec  ();
use Apache::RequestUtil ();
use Apache::Response    ();
use Apache::URI         ();
use APR::Table          ();

sub ok_constant { Apache::OK }

sub unescape_uri {
    my ( $self, $str ) = @_;

    $str =~ s/\+/ /g;
    return Apache::URI::unescape_url($str);
}

1;


__END__
=pod

=encoding utf-8

=head1 NAME

Catalyst::Engine::Apache2::MP19 - Catalyst Apache2 mod_perl 1.99x Engine

=head1 SYNOPSIS

    # Set up your Catalyst app as a mod_perl 1.99x application in httpd.conf
    PerlSwitches -I/var/www/MyApp/lib

    # Preload your entire application
    PerlModule MyApp

    <VirtualHost *>
        ServerName    myapp.hostname.com
        DocumentRoot  /var/www/MyApp/root

        <Location />
            SetHandler          modperl
            PerlResponseHandler MyApp
        </Location>

        # you can also run your app in any non-root location
        <Location /some/other/path>
            SetHandler          perl-script
            PerlResponseHandler MyApp
        </Location>

        # Make sure to let Apache handle your static files
        # (It is not necessary to remove the Static::Simple plugin
        # in production; Apache will bypass Static::Simple if
        # configured in this way)

        <Location /static>
            SetHandler          default-handler
        </Location>

        # If not running at a root location in a VirtualHost,
        # you'll probably need to set an Alias to the location
        # of your static files, and allow access to this location:

        Alias /myapp/static /filesystem/path/to/MyApp/root/static
        <Directory /filesystem/path/to/MyApp/root/static>
            allow from all
        </Directory>
        <Location /myapp/static>
            SetHandler default-handler
        </Location>

    </VirtualHost>

=head1 DESCRIPTION

This is the Catalyst engine specialized for Apache2 mod_perl version 1.99x.

=head1 WARNING

mod_perl 1.99 was the beta version for mod_perl 2.0.  Upgrading to 2.0 is
strongly recommended.

=head1 CGI ISSUES

In order to run Catalyst under mod_perl 1.99 you will need to downgrade L<CGI>
to version 3.07, as it has dropped support for 1.99 in later versions.

=head1 ModPerl::Registry

While this method is not recommended, you can also run your Catalyst
application via a ModPerl::Registry script.

httpd.conf:

    PerlModule ModPerl::Registry
    Alias / /var/www/MyApp/script/myapp_registry.pl/

    <Directory /var/www/MyApp/script>
        Options +ExecCGI
    </Directory>

    <Location />
        SetHandler          perl-script
        PerlResponseHandler ModPerl::Registry
    </Location>

script/myapp_registry.pl (you will need to create this):

    #!/usr/bin/perl

    use strict;
    use warnings;
    use MyApp;

    MyApp->handle_request( Apache::RequestUtil->request );

=head1 METHODS

=head2 ok_constant

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Engine>, L<Catalyst::Engine::Apache2>.

=head1 AUTHORS

=over 4

=item *

Sebastian Riedel <sri@cpan.org>

=item *

Christian Hansen <ch@ngmedia.com>

=item *

Andy Grundman <andy@hybridized.org>

=item *

Tomas Doran <bobtfish@bobtfish.net>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by The "AUTHORS".

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

