#
# App::Foca::Server:HTTP
#
# Author(s): Pablo Fischer (pablo@pablo.com.mx)
# Created: 06/13/2012 01:44:57 AM UTC 01:44:57 AM
package App::Foca::Server::HTTP;

=head1 NAME

App::Foca::Server::HTTP - Foca HTTP server

=head1 DESCRIPTION

This class is just a sub-class of L<HTTP::Daemon>, why creating a new
subclass? To change the 'Server:' header so we can identify this
application.

=cut
use strict;
use warnings;
use HTTP::Daemon;
use base qw(HTTP::Daemon);

=head1 Methods

=head2 B<product_tokens()>

Overrides C<product_tokens()> of L<HTTP::Daemon> by making clear this web
server is 'Foca'.

=cut
sub product_tokens {
    my ($self) = @_;
    my $parent_token = $self->SUPER::product_tokens();
    return "Foca_Server-$parent_token";
}

=head1 COPYRIGHT

Copyright (c) 2010-2012 Yahoo! Inc. All rights reserved.

=head1 LICENSE

This program is free software. You may copy or redistribute it under
the same terms as Perl itself. Please see the LICENSE file included
with this project for the terms of the Artistic License under which 
this project is licensed.

=head1 AUTHORS

Pablo Fischer (pablo@pablo.com.mx)

=cut
1;

