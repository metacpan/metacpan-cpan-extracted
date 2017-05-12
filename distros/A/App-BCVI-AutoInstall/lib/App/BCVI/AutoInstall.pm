package App::BCVI::AutoInstall;

use warnings;
use strict;

our $VERSION = '0.1';

sub execute_wrapped_ssh {
    my ($self, $target, @args) = @_;

    if ($self->can("get_install_signature")) {
        my $sig = $self->get_install_signature($target);
        if (! defined $sig) {
          $self->install_to_host($target);
        }
    } else {
        warn "App::BCVI::AutoInstall can only function if App::BCVI::InstallManager is installed.\n";
    }
    $self->SUPER::execute_wrapped_ssh($target, @args);
}

App::BCVI->hook_client_class();

1;

__END__

=head1 NAME

App::BCVI::AutoInstall - Automatically install bcvi on a new host


=head1 DESCRIPTION

This module is a plugin for C<bcvi> (see: L<App::BCVI>).  If you are connecting
to a server for the first time it will install the required files for you.

It requires App::BCVI::InstallManager for tracking which servers you've already
installed the bcvi files on.

=head1 SUPPORT

You can look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-BCVI-AutoInstall>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-BCVI-AutoInstall>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-BCVI-AutoInstall>

=item * Search CPAN

L<http://search.cpan.org/dist/App-BCVI-AutoInstall>

=item * Git Repository

L<http://git.etc.gen.nz/cgi-bin/gitweb.cgi?p=app-bcvi-autoinstall.git>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2010 Andrew Ruthven E<lt>andrew@etc.gen.nzE<gt>

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

