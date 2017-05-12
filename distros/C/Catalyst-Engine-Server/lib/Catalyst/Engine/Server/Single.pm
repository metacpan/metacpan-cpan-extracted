package Catalyst::Engine::Server::Single;

use strict;
use base 'Catalyst::Engine::Server::Base';

=head1 NAME

Catalyst::Engine::Server::Single - Catalyst Server Engine

=head1 SYNOPSIS

A script using the Catalyst::Engine::Server::Single module might look like:

    #!/usr/bin/perl -w

    BEGIN { 
       $ENV{CATALYST_ENGINE} = 'Server::Single';
    }

    use strict;
    use lib '/path/to/MyApp/lib';
    use MyApp;

    MyApp->run;

=head1 DESCRIPTION

This Catalyst engine specialized for standalone deployment.

=head1 OVERLOADED METHODS

This class overloads some methods from C<Catalyst::Engine::Server::Base>.

=over 4

=item $c->run

=cut

sub run {
    my $class = shift;

    my $server = Catalyst::Engine::Server::Net::Server::Single->new;
    $server->application($class);
    $server->run(@_);
}

=back

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Engine::Server::Base>, L<Net::Server::Single>.

=head1 AUTHOR

Christian Hansen, C<ch@ngmedia.com>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

package Catalyst::Engine::Server::Net::Server::Single;

use strict;
use base qw[Catalyst::Engine::Server::Net::Server Net::Server::Single];

1;
