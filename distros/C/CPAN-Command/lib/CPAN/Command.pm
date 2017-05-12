use 5.008_001;
use strict;
use warnings;

package CPAN::Command;
our $VERSION = '1.100840';
# ABSTRACT: Load CPAN command plugins
use CPAN;    # so the plugins have something to work with
use Module::Pluggable
  search_path => ['CPAN::Command'],
  require     => 1;
BEGIN { __PACKAGE__->plugins }    # just load them
1;


__END__
=pod

=head1 NAME

CPAN::Command - Load CPAN command plugins

=head1 VERSION

version 1.100840

=head1 SYNOPSIS

    # sudo perl -MCPAN::Command -e 'CPAN::shell()'
    # cpan> repo Foo::Bar
    # cpan> homepage Foo::Bar
    # cpan> bugtracker Foo::Bar

=head1 DESCRIPTION

This module is a plugin loader for CPAN commands in the C<CPAN::Commmand::*>
namespace.

    # sudo perl -MCPAN::Command -e 'CPAN::shell()'

will load all command plugins in that namespace, then run the CPAN shell as
usual. The pluggable commands are now available. For an example of such a
command see L<CPAN::Command::Bugtracker>.

This module also loads the L<CPAN> package so you can run, for example, its
C<shell()> function.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=CPAN-Command>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/CPAN-Command/>.

The development version lives at
L<http://github.com/hanekomu/CPAN-Command/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

