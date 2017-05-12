package Catalyst::Engine::Apache2::MP20;
BEGIN {
  $Catalyst::Engine::Apache2::MP20::AUTHORITY = 'cpan:BOBTFISH';
}
BEGIN {
  $Catalyst::Engine::Apache2::MP20::VERSION = '1.16';
}
# ABSTRACT: Catalyst Apache2 mod_perl 2.x Engine

use strict;
use warnings;
use base 'Catalyst::Engine::Apache2';

use Apache2::Connection  ();
use Apache2::Const       -compile => qw(OK);
use Apache2::RequestIO   ();
use Apache2::RequestRec  ();
use Apache2::RequestUtil ();
use Apache2::Response    ();
use Apache2::URI         ();
use APR::Table           ();

# We can use Apache2::ModSSL to better detect if we're running in SSL mode
eval { require Apache2::ModSSL };

sub ok_constant { Apache2::Const::OK }

sub unescape_uri {
    my ( $self, $str ) = @_;

    $str =~ s/\+/ /g;
    return Apache2::URI::unescape_url($str);
}

1;


__END__
=pod

=encoding utf-8

=head1 NAME

Catalyst::Engine::Apache2::MP20 - Catalyst Apache2 mod_perl 2.x Engine

=head1 SYNOPSIS

    # Set up your Catalyst app as a mod_perl 2.x application in httpd.conf
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

This is the Catalyst engine specialized for Apache2 mod_perl version 2.x.

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

    MyApp->handle_request( Apache2::RequestUtil->request );

=head1 METHODS

=head2 ok_constant

=head1 OVERLOADED METHODS

This class overloads some methods from C<Catalyst::Engine>.

=over 4

=item unescape_uri

=back

=head1 OVERLOADED METHODS

This class overloads some methods from C<Catalyst::Engine>.

=over 4

=item unescape_uri

=back

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

