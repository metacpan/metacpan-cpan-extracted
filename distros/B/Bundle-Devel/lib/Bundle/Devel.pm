package Bundle::Devel;

use vars qw{$VERSION};
BEGIN {
	$VERSION = 0.2;
}

1;

__END__

=head1 NAME

Bundle::Devel - A bundle to install the main set of Devel:: modules

=head1 SYNOPSIS

C<perl -MCPAN -e 'install Bundle::Devel'>

=head1 CONTENTS

Devel::DProf    - Profiling tool

Devel::Profile  - Another profiler

Devel::Cover    - Currently the prefered coverage tool

Devel::Coverage - Newer, but somewhat imature coverage tool

=head1 DESCRIPTION

Let's just say I'm sick of installing the Devel:: modules on at a time.
This bundle installs most of the common Devel:: modules in one go.

That's the basics for me, but if you want something added, just let
me know, or better file a bug against the package.

=head1 SUPPORT

For general comments, contact the author.

To file a bug against this module, in a way you can keep track of, see the CPAN
bug tracking system.

http://rt.cpan.org/

=head1 AUTHOR

    Adam Kennedy
    cpan@ali.as
    http//ali.as/

=head1 SEE ALSO

L<Devel::DProf>, L<Devel::Cover>, L<Devel::Coverage>

=head1 COPYRIGHT

Copyright (c) 2003 Adam Kennedy. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

