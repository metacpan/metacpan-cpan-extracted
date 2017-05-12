# $Id: $ $Revision: $ $Source: $ $Date: $

package Apache::Session::Generate::UUID;

use strict;
use warnings;

use Data::UUID;

our $VERSION = '0.2';

sub generate {
    my ($session) = @_;
    return $session->{'data'}->{'_session_id'} = Data::UUID->new->create_str();
}

sub validate {
    my ($session) = @_;
    if ($session->{'data'}->{'_session_id'} !~ /^[a-fA-F0-9\-]+$/xm) { die; }
    return 1;
}

1;
__END__

=pod

=head1 NAME

Apache::Session::Generate::UUID - UUID for session ID generation

=head1 SYNOPSIS

  use Apache::Session::Flex;

  tie %session, 'Apache::Session::Flex', $id, {
      Store     => 'MySQL',
      Lock      => 'Null',
      Generate  => 'UUID',
      Serialize => 'Storable',
  };

=head1 DESCRIPTION

Apache::Session::Generate::UUID extends Apache::Session to allow you to create
UUID based session ids. This module fits well with long-term sessions, so
better using RDBMS like MySQL for its storage.

=head1 CONFIGURATION

There are no configuration options.

=head1 FUNCTIONS

=head2 generate

=head2 validate

=head1 AUTHOR

Nick Gerakines, C<< <nick at socklabs.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-apache-session-generate-uuid at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Apache-Session-Generate-UUID>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Apache::Session::Generate::UUID

You can also look for information at:

=over 4

=item * Wikipedia: UUID

L<http://en.wikipedia.org/wiki/UUID>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Apache-Session-Generate-UUID>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Apache-Session-Generate-UUID>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache-Session-Generate-UUID>

=item * Search CPAN

L<http://search.cpan.org/dist/Apache-Session-Generate-UUID>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 Nick Gerakines, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
