package Catalyst::ActionRole::CheckTrailingSlash;

use Moose::Role;
use namespace::autoclean;


our $VERSION = '0.01';


around execute => sub {
	my $orig = shift;
	my $self = shift;
	my ($controller, $c) = @_;
	my $uri = $c->req->uri;

	if ( $uri->path !~ m{/$} )
	{
		$uri->path( $uri->path.'/' );
		$c->res->redirect( $uri, 301 );
		return;
	}
	$self->$orig( @_ );
};

1;

=head1 NAME

Catalyst::ActionRole::CheckTrailingSlash - Test URI path for trailing slash and redirect if needed

=cut

=head1 SYNOPSIS


    package MyApp::Controller::Root

    use Moose;
    BEGIN { extends 'Catalyst::Controller::ActionRole' };

    sub info :Local :Does('CheckTrailingSlash')
    {
        my ( $self, $c ) = @_;
        ...
    }

    ...
=cut

=head1 AUTHOR

Anatoliy Lapitskiy, C<< <nuclon at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-catalyst-actionrole-checktrailingslash at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-ActionRole-CheckTrailingSlash>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::ActionRole::CheckTrailingSlash


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-ActionRole-CheckTrailingSlash>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-ActionRole-CheckTrailingSlash>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-ActionRole-CheckTrailingSlash>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-ActionRole-CheckTrailingSlash/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2010 Anatoliy Lapitskiy.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
