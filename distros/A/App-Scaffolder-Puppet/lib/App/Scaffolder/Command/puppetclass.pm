package App::Scaffolder::Command::puppetclass;
{
  $App::Scaffolder::Command::puppetclass::VERSION = '0.002001';
}
use parent qw(App::Scaffolder::Puppet::Command);

# ABSTRACT: Scaffold one or more related Puppet classes

use strict;
use warnings;


1;


__END__
=pod

=head1 NAME

App::Scaffolder::Command::puppetclass - Scaffold one or more related Puppet classes

=head1 VERSION

version 0.002001

=head1 SYNOPSIS

	# Create scaffold to install the 'vim-puppet' package in module created with
	# puppetmodule command and 'package' template:
	$ scaffolder puppetclass --template subpackage --name vim::puppet --package vim-puppet

	# Create scaffold to install the 'apache2-doc' package in module created with
	# puppetmodule command and 'service' template:
	$ scaffolder puppetclass --template subpackage --name apache2::doc --package apache2-doc

=head1 DESCRIPTION

App::Scaffolder::Command::puppetclass scaffolds one or more related Puppet
classes. It does not create a complete Puppet module (see
L<App::Scaffolder::Command::puppetmodule|App::Scaffolder::Command::puppetmodule>
for this), it just adds additional (usually closely related) classes to an
existing module. By default, it provides the following templates:

=over

=item *

C<subpackage>: Create class to install a 'sub package'. This is intended to be
used after using the C<package> or C<service> templates of the
L<App::Scaffolder::Command::puppetmodule|App::Scaffolder::Command::puppetmodule>
command to add an additional package to the module (eg. C<apache2-doc> to the
C<apache2> service). This must be used inside the module directory created before,
and you will have to add a variable with the actual package name to the existing
C<manifests/params.pp> file. The name of the variable can be seen in the newly
created files below C<manifests>.

=back

=head1 SEE ALSO

=over

=item *

L<App::Scaffolder::Command::puppetmodule|App::Scaffolder::Command::puppetmodule>

=back

=head1 AUTHOR

Manfred Stock <mstock@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Manfred Stock.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

