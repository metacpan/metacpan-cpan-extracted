package CatalystX::FacebookURI;
use Moose::Role;
use URI::http;
requires 'facebook';

our $VERSION = '0.02';

=head1 NAME

CatalystX::FacebookURI - Automatically compose uri_for URIs to be within your Facebook application

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    package MyApp;
    use Moose;
    BEGIN {
        extends 'Catalyst';

        use Catalyst::Runtime 5.80;
        use Catalyst qw(
            ...
            Facebook
        );
        with 'CatalystX::FacebookURI';
    }

    __PACKAGE__->config(
        facebook => {
            api_key => 'my_key',
            secret  => 'my_s33krit',
            name    => 'myapp'  # Used as app name in URIs
        }
    );
    ...

    my $uri = $c->uri_for('/some/path'); # returns http://apps.facebook.com/myapp/some/path

=cut

after prepare_path => sub {
    my $c = shift;
    my $is_ajax = $c->req->param('fb_sig_is_ajax');
    my $is_frame = $c->facebook->canvas->in_frame();
    my $is_canvas = $c->facebook->canvas->in_fb_canvas();

    my $app_name = $c->config->{facebook}{name};

    $c->req->base(URI->new("http://apps.facebook.com/$app_name/"))
        if $is_ajax or $is_frame or $is_canvas;
};


=head1 AUTHOR

Michael Nachbaur, C<< <mike at nachbaur.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-catalystx-facebookuri at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CatalystX-FacebookURI>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

This project is available via Git at http://github.com/NachoMan/CatalystX-FacebookURI


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CatalystX::FacebookURI


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CatalystX-FacebookURI>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CatalystX-FacebookURI>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CatalystX-FacebookURI>

=item * Search CPAN

L<http://search.cpan.org/dist/CatalystX-FacebookURI/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2010 Michael Nachbaur.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of CatalystX::FacebookURI
