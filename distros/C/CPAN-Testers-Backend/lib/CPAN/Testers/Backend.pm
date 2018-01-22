package CPAN::Testers::Backend;
our $VERSION = '0.004';
# ABSTRACT: Backend processes for CPAN Testers data and operations

#pod =head1 DESCRIPTION
#pod
#pod This distribution contains various backend scripts (inside runnable
#pod modules) that process CPAN Testers data to support the APIs and website.
#pod
#pod The runnable modules are all in the C<CPAN::Testers::Backend::> namespace,
#pod and are configured into executable tasks by L<Beam::Wire> configuration files
#pod located in C<etc/container>. The tasks are run using L<Beam::Runner>, which
#pod contains the L<beam> command.
#pod
#pod =head1 OVERVIEW
#pod
#pod =head2 Logging
#pod
#pod All processes should use L<Log::Any> to log important information. Logs will
#pod be directed to syslog using L<Log::Any::Adapter::Syslog>, configured by
#pod C<etc/container/common.yml>.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Beam::Runner>, L<Beam::Wire>
#pod
#pod =cut

use strict;
use warnings;



1;

__END__

=pod

=head1 NAME

CPAN::Testers::Backend - Backend processes for CPAN Testers data and operations

=head1 VERSION

version 0.004

=head1 DESCRIPTION

This distribution contains various backend scripts (inside runnable
modules) that process CPAN Testers data to support the APIs and website.

The runnable modules are all in the C<CPAN::Testers::Backend::> namespace,
and are configured into executable tasks by L<Beam::Wire> configuration files
located in C<etc/container>. The tasks are run using L<Beam::Runner>, which
contains the L<beam> command.

=head1 OVERVIEW

=head2 Logging

All processes should use L<Log::Any> to log important information. Logs will
be directed to syslog using L<Log::Any::Adapter::Syslog>, configured by
C<etc/container/common.yml>.

=head1 SEE ALSO

L<Beam::Runner>, L<Beam::Wire>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 CONTRIBUTORS

=for stopwords James E Keenan Joel Berger Mohammad S Anwar

=over 4

=item *

James E Keenan <jkeenan@cpan.org>

=item *

Joel Berger <joel.a.berger@gmail.com>

=item *

Mohammad S Anwar <mohammad.anwar@yahoo.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
