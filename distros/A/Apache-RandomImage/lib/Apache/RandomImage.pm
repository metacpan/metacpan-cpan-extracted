package Apache::RandomImage;

use strict;
use warnings;

use DirHandle;
use mod_perl;

BEGIN {
    my $MP2 = ( exists $ENV{MOD_PERL_API_VERSION} and
                      $ENV{MOD_PERL_API_VERSION} >= 2 );

    if (defined $MP2) {
        require Apache2::RequestRec;
        require Apache2::RequestUtil;
        require Apache2::SubRequest;
        require Apache2::Log;
        require Apache2::Const;
        Apache2::Const->import(qw(OK DECLINED NOT_FOUND));
    }
    else {
        require Apache::Constants;
        Apache::Constants->import(qw(OK DECLINED NOT_FOUND));
    }
}


=head1 NAME

Apache::RandomImage - Lightweight module to randomly display images from a directory.

=head1 VERSION

Version 0.3

=cut

# http://module-build.sourceforge.net/META-spec-current.html
# Does not like v0.3 versions :-/
#use version; our $VERSION = qv('0.3');
our $VERSION = '0.3';

=head1 SYNOPSIS

  Configure this module as a response handler to activate this module. The following
  examples will result in an image being randomly selected from the "images" directory.

    #mod_perl2 (PerlResponseHandler)
    <LocationMatch "^/(.+)/images/random-image">
        SetHandler modperl
        PerlSetVar Suffixes "gif png jpg"
        PerlResponseHandler Apache::RandomImage
    </LocationMatch>

    #mod_perl1 (PerlHandler)
    <Location "/images/give-random">
        SetHandler perl-script
        PerlSetVar Suffixes "gif png jpg tif jpeg"
        PerlHandler Apache::RandomImage
    </Location>

=head1 DESCRIPTION

Apache::RandomImage will randomly select an image from the dirname of the requested location.
You need to specify a white-space separated list of B<Suffixes> with I<PerlSetVar>,
otherwise the request will be declined.

=head1 FUNCTIONS

=head2 handler

Apache response handler

=cut
sub handler {
    my $r = shift;
    my $uri = $r->uri();
    $uri =~ s|[^/]+$||x;

    my $dir = $r->document_root() . $uri;

    my $dh = DirHandle->new($dir);
    if (not $dh) {
        $r->log_error("Cannot open directory $dir: $!");
        return NOT_FOUND;
    }

    my @suffixes = split('\s+',$r->dir_config("Suffixes"));
    return DECLINED unless scalar @suffixes;

    my @images;
    foreach my $file ( $dh->read() ) {
        next unless grep { $file =~ /\.$_$/xi } @suffixes;
        push (@images, $file);
    }

    return NOT_FOUND unless scalar @images;

    my $image = $images[rand @images];
    $r->internal_redirect_handler("$uri/$image");

    return OK;
}

=head1 Imported constants

=head2 OK

See Apache::Constants or Apache2::Const documentation

=head2 DECLINED

See Apache::Constants or Apache2::Const documentation

=head2 NOT_FOUND

See Apache::Constants or Apache2::Const documentation

=head1 SEE ALSO

=over 4

=item L<mod_perl>

=item L<Apache::RandomLocation>

=back

=head1 AUTHOR

Michael Kroell, C<< <pepl at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-locale-maketext-extract-plugin-xsl at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Locale-Maketext-Extract-Plugin-XSL>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Apache::RandomImage


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache-RandomImage>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Apache-RandomImage>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Apache-RandomImage>

=item * Search CPAN

L<http://search.cpan.org/dist/Apache-RandomImage>

=back


=head1 ACKNOWLEDGEMENTS

Apache::RandomImage was inspired by L<Apache::RandomLocation>

=head1 COPYRIGHT

Copyright 2003-2009 Michael Kroell, all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Apache::RandomImage


