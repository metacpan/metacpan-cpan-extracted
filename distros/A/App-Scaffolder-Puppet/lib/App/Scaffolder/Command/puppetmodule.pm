package App::Scaffolder::Command::puppetmodule;
{
  $App::Scaffolder::Command::puppetmodule::VERSION = '0.002001';
}
use parent qw(App::Scaffolder::Puppet::Command);

# ABSTRACT: Scaffold a Puppet module

use strict;
use warnings;


1;


__END__
=pod

=head1 NAME

App::Scaffolder::Command::puppetmodule - Scaffold a Puppet module

=head1 VERSION

version 0.002001

=head1 SYNOPSIS

	# Create scaffold to install the 'vim' package:
	$ scaffolder puppetmodule --template package --name vim

	# Create scaffold to install the 'apache2' package and setup the corresponding service:
	$ scaffolder puppetmodule --template service --name apache2

=head1 DESCRIPTION

App::Scaffolder::Command::puppetmodule scaffolds Puppet modules. By default, it
provides the following templates:

=over

=item *

C<package>: Create Puppet module to install a package.

=item *

C<service>: Create Puppet module to setup a service.

=back

=head1 SEE ALSO

=over

=item *

L<https://docs.puppetlabs.com/puppet/latest/reference/modules_fundamentals.html> - Module Fundamentals

=item *

L<App::Scaffolder::Command::puppetclass|App::Scaffolder::Command::puppetclass>

=back

=head1 AUTHOR

Manfred Stock <mstock@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Manfred Stock.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

