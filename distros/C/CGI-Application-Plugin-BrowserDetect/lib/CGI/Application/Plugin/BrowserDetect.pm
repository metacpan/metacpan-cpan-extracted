package CGI::Application::Plugin::BrowserDetect;

use Exporter 'import';
use HTTP::BrowserDetect ();

use vars qw($VERSION @EXPORT);
use strict;

@EXPORT = qw(browser);
$VERSION = '1.00';


sub browser
{
    my $self = shift;

    $self->{__CAP_BROWSERDETECT_OBJ} ||= HTTP::BrowserDetect->new(); 

    return $self->{__CAP_BROWSERDETECT_OBJ};
}

1;
__END__

=head1 NAME

CGI::Application::Plugin::BrowserDetect - Browser detection plugin for CGI::Application

=head1 SYNOPSIS

    use CGI::Application::Plugin::BrowserDetect;

    sub runmode
    {
        my $self    = shift;
        my $browser = $self->browser;

        if ($browser->ie)
        {
            # ...
        }

        # ...
    }

=head1 DESCRIPTION

CGI::Application::Plugin::BrowserDetect adds browser detection support to your
L<CGI::Application> modules by providing a L<HTTP::BrowserDetect> object.
Lazy loading is used when creating the object so it will not be created until
it is actually used.

See L<HTTP::BrowserDetect> for more details on what you can do with the
browser object.

=head1 METHODS

=head2 browser

This method will return the current L<HTTP::BrowserDetect> object.  The
L<HTTP::BrowserDetect> object is created on the first call to this method, and
any subsequent calls will return the same object.

    # Retrieve the browser object
    my $browser = $self->browser;

=head1 BUGS

Please report any bugs or feature requests to
C<bug-cgi-application-plugin-browserdetect at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Application-Plugin-BrowserDetect>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SEE ALSO

L<CGI::Application>, L<HTTP::BrowserDetect>

=head1 AUTHOR

Bradley C Bailey, C<< <cap-browserdetect at brad.memoryleak.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Bradley C Bailey, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
