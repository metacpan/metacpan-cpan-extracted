package Catalyst::View::Image::Empty;

use strict;
use warnings;

use Moose;

extends 'Catalyst::View';

use Image::Empty;

has format   => ( is => 'ro', isa => 'Str', default => 'gif' );
has filename => ( is => 'ro', isa => 'Str' );

=head1 NAME

Catalyst::View::Image::Empty - View to return a 1x1 empty GIF or PNG, for building tracking URLs.

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';

$VERSION = eval $VERSION;

=head1 SYNOPSIS

=head3 Create View

 script/myapp_create.pl view My::Image::Empty Image::Empty

=head3 In Your Controller

 sub tracker :Local
 {
         my ( $self, $c ) = @_;
         
         $c->detach('View::My::Image::Empty');
 }

=cut

=head1 DESCRIPTION

Catalyst::View::Image::Empty is a view that returns a 1x1 empty GIF or PNG, for building tracking URLs.

GIF is default.
 
You can switch to PNG by specifying the C<format> in the config.

 package MyApp::View::Image::Empty;
 
 use strict;
 use warnings;
 
 use base 'Catalyst::View::Image::Empty';
 
 __PACKAGE__->config(
         format => 'png',
 );

C<filename> is another config option you can change, the default filename you would see if you "Save Page As..." in a browser.

=cut

sub process
{
	my ( $self, $c ) = @_;

	my $format = $self->format;
		
	my $empty = Image::Empty->$format;
	
	$empty->filename( $self->filename ) if $self->filename;
   
	$c->response->content_type( $empty->type );
	$c->response->content_length( $empty->length );
	$c->response->header( 'Content-Disposition' => $empty->disposition . '; filename="' . $empty->filename . '"' );

	$c->response->body( $empty->content ); 
}

=head1 SEE ALSO

L<Image::Empty>

=head1 AUTHOR

Rob Brown, C<< <rob at intelcompute.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-catalyst-view-image-empty at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-View-Image-Empty>.  I will be notified, and then you will
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::View::Image::Empty


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-View-Image-Empty>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-View-Image-Empty>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-View-Image-Empty>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-View-Image-Empty/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Rob Brown.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;

