package Catalyst::ActionRole::MatchHost;

use warnings;
use strict;
use Moose::Role;
use namespace::autoclean;

=head1 NAME

Catalyst::ActionRole::MatchHost - Match action against domain host name

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

Match host name

    package MyApp::Controller::Root

    use Moose;
    BEGIN { extends 'Catalyst::Controller::ActionRole' };

    sub index :Path('/') :Does('MatchHost') :Host(^mainhost$)
    {
        my ( $self, $c ) = @_;
        ...
    }

    ...

    package MyApp::Controller::NonRoot

    use Moose;
    BEGIN { extends 'Catalyst::Controller::ActionRole' };

    sub index :Path('/') :Does('MatchHost') :HostNot(^mainhost$)
    {
        my ( $self, $c ) = @_;
        ...
    }


=cut

around match => sub
{
	my $orig = shift;
	my $self = shift;
	my ( $c ) = @_;

	my $host = $c->req->uri->host;
	return 0 unless $self->check_domain_constraints( $host );

	$self->$orig( @_ );
};

sub check_domain_constraints
{
	my ( $self, $host ) = @_;

	if ( exists $self->attributes->{'Host'} )
	{
		foreach my $dom ( @{ $self->attributes->{'Host'} } )
		{
			if ( !$self->_test($host, $dom) )
			{
				return undef;
			}
		}
	}
	if ( exists $self->attributes->{'HostNot'} )
	{
		foreach my $dom ( @{ $self->attributes->{'HostNot'} } )
		{
			if ( $self->_test($host, $dom) )
			{
				return undef;
			}
		}
	}

	return 1;
}

sub _test
{
	my $self = shift;
	my ( $string, $test ) = @_;

	return $string =~ /$test/i;
}


=head1 AUTHOR

Anatoliy Lapitskiy, C<< <nuclon at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-catalyst-action-domain at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-ActionRole-MatchHost>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::ActionRole::MatchHost


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-ActionRole-MatchHost>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-ActionRole-MatchHost>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-ActionRole-MatchHost>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-ActionRole-MatchHost/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Anatoliy Lapitskiy.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut


1; # End of Catalyst::ActionRole::MatchHost
