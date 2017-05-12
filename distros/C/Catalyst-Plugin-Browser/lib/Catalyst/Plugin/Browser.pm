package Catalyst::Plugin::Browser;
BEGIN {
  $Catalyst::Plugin::Browser::AUTHORITY = 'cpan:FLORA';
}
BEGIN {
  $Catalyst::Plugin::Browser::VERSION = '0.08';
}
# ABSTRACT: DEPRECATED: Browser Detection

use Moose::Role;
use CatalystX::RoleApplicator ();
use namespace::autoclean;

after setup_finalize => sub {
    my ($app) = @_;

    # yeah, i know. sue me.
    CatalystX::RoleApplicator->init_meta(for_class => $app);

    $app->apply_request_class_roles(qw/
        Catalyst::TraitFor::Request::BrowserDetect
    /);
};

1;


__END__
=pod

=encoding utf-8

=head1 NAME

Catalyst::Plugin::Browser - DEPRECATED: Browser Detection

=head1 SYNOPSIS

    use Catalyst qw[Browser];

    if ( $c->request->browser->windows && $c->request->browser->ie ) {
        # do something
    }

=head1 DESCRIPTION

Extends your applications request class with browser detection.

=head1 DEPRECATED

This module should no longer be used in new applications.
L<Catalyst::TraitFor::Request::BrowserDetect> is the replacement.

=head1 METHODS

=over 4

=item browser

Returns an instance of L<HTTP::BrowserDetect>, which lets you get
information of the client's user agent.

=back

=head1 SEE ALSO

L<HTTP::BrowserDetect>, L<Catalyst::TraitFor::Request::BrowserDetect>, L<Catalyst::Request>.

=head1 AUTHORS

=over 4

=item *

Christian Hansen <ch@ngmedia.com>

=item *

Marcus Ramberg <mramberg@cpan.org>

=item *

Florian Ragwitz <rafl@debian.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Christian Hansen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

