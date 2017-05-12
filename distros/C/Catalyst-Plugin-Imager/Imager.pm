package Catalyst::Plugin::Imager;

use strict;
use warnings;

use Catalyst::Exception;
use Imager;

our $VERSION = "0.01";

=pod
=head1 NAME

Catalyst::Plugin::Imager - Imager Plugin for Catalyst

=head1 SYNOPSIS

This is a thin interface for the L<Imager> library adapted for Catalyst.


    # In your application class	
    use Catalyst qw/Imager/;


    # Use Imager objects in your Catalyst application
    my $image = $c->imager(); # Will return an Imager object
    $image->read(file => $file) or die $image->errstr();
 
See the L<Imager> library documentation if you want to know what to do after that.
Imager provides a lot of image manipulation functionality, such as resizing,
cropping, stretching, and applying many common filters.

=head1 METHODS

=over 4

=item imager

Returns a L<Imager> object.  If params are argued they will be passed to the 
C<< Imager->new() >> method.  Exceptions thrown by L<Imager> will be caught by
L<Catalyst::Exception>.

=back

=cut

sub imager {
	my $c = shift;
	my %params = @_;

	# use params if argued
	if (%params) {
		return Imager->new(\%params);
	}
	else {
		return Imager->new;
	}
}
 
1;

=pod

=head1 DESCRIPTION

This module's intention is to make the wonders of L<Imager> easily accesible within
a L<Catalyst> application via the L<Catalyst::Plugin> interface. 

It adds the method C<imager> to the C<Catalyst> namespace.

=head1 AUTHOR

Daniel Ambar L<dambar@gmail.com>

=head1 SEE ALSO

L<Catalyst>, L<Imager>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2006 the aforementioned author(s). All rights
    reserved. This program is free software; you can redistribute
    it and/or modify it under the same terms as Perl itself.

=cut


