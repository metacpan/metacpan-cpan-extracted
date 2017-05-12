package Catalyst::Engine::Apache::MP13;
BEGIN {
  $Catalyst::Engine::Apache::MP13::AUTHORITY = 'cpan:BOBTFISH';
}
BEGIN {
  $Catalyst::Engine::Apache::MP13::VERSION = '1.16';
}
# ABSTRACT: Catalyst Apache mod_perl 1.3x Engine

use strict;
use warnings;
use base 'Catalyst::Engine::Apache';

use Apache            ();
use Apache::Constants qw(OK);
use Apache::File      ();
use Apache::Util      ();

sub finalize_headers {
    my ( $self, $c ) = @_;

    $self->SUPER::finalize_headers( $c );

    $self->apache->send_http_header;

    return 0;
}

sub ok_constant { Apache::Constants::OK }

sub unescape_uri {
    my $self = shift;

    # Unlike in mod_perl 2, this method also unescapes '+' to space
    return Apache::Util::unescape_uri_info(@_);
}

1;


__END__
=pod

=encoding utf-8

=head1 NAME

Catalyst::Engine::Apache::MP13 - Catalyst Apache mod_perl 1.3x Engine

=head1 SYNOPSIS

    # Set up your Catalyst app as a mod_perl 1.3x application in httpd.conf
    <Perl>
        use lib qw( /var/www/MyApp/lib );
    </Perl>

    # Preload your entire application
    PerlModule MyApp

    <VirtualHost *>
        ServerName   myapp.hostname.com
        DocumentRoot /var/www/MyApp/root

        <Location />
            SetHandler       perl-script
            PerlHandler      MyApp
        </Location>

        # you can also run your app in any non-root location
        <Location /some/other/path>
            SetHandler      perl-script
            PerlHandler     MyApp
        </Location>

        # Make sure to let Apache handle your static files
        # (And remember to remove the Static::Simple plugin in production)
        <Location /static>
            SetHandler      default-handler
        </Location>
    </VirtualHost>

=head1 DESCRIPTION

This is the Catalyst engine specialized for Apache mod_perl version 1.3x.

=head1 Apache::Registry

While this method is not recommended, you can also run your Catalyst
application via an Apache::Registry script.

httpd.conf:

    PerlModule Apache::Registry
    Alias / /var/www/MyApp/script/myapp_registry.pl/

    <Directory /var/www/MyApp/script>
        Options +ExecCGI
    </Directory>

    <Location />
        SetHandler  perl-script
        PerlHandler Apache::Registry
    </Location>

script/myapp_registry.pl (you will need to create this):

    #!/usr/bin/perl

    use strict;
    use warnings;
    use MyApp;

    MyApp->handle_request( Apache->request );

=head1 METHODS

=head2 ok_constant

=head1 OVERLOADED METHODS

This class overloads some methods from C<Catalyst::Engine::Apache>.

=head2 $c->engine->finalize_headers

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Engine>, L<Catalyst::Engine::Apache>.

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

