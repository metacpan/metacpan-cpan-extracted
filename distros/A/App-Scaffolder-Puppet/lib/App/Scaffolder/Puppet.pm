package App::Scaffolder::Puppet;
$App::Scaffolder::Puppet::VERSION = '0.004000';
# ABSTRACT: App::Scaffolder extension to scaffold Puppet modules

use strict;
use warnings;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Scaffolder::Puppet - App::Scaffolder extension to scaffold Puppet modules

=head1 VERSION

version 0.004000

=head1 DESCRIPTION

App::Scaffolder::Puppet provides commands to scaffold Puppet modules and classes.
See L<App::Scaffolder::Command::puppetmodule|App::Scaffolder::Command::puppetmodule>
and L<App::Scaffolder::Command::puppetclass|App::Scaffolder::Command::puppetclass>
for the actual commands.

L<App::Scaffolder::Puppet::Command|App::Scaffolder::Puppet::Command> is a base
class for the above commands, and is itself based on
L<App::Scaffolder::Command|App::Scaffolder::Command>.

=head1 SEE ALSO

=over

=item *

L<App::Scaffolder|App::Scaffolder>

=item *

L<App::Scaffolder::Puppet::Command|App::Scaffolder::Puppet::Command>

=item *

L<https://puppetlabs.com/puppet/puppet-open-source> - Puppet

=back

=head1 AUTHOR

Manfred Stock <mstock@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Manfred Stock.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
