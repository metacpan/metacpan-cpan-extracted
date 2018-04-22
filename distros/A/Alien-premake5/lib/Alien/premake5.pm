package Alien::premake5;
# ABSTRACT: Build or find premake5

our $VERSION = '0.003';

use strict;
use warnings;
use base 'Alien::Base';

sub exe {
  my ($class) = @_;
  $class->runtime_prop->{command};
}

sub alien_helper {
  return +{ premake5 => sub { Alien::premake5->exe } }
}

1;

__END__

=encoding utf8

=head1 NAME

Alien::premake5 - Build or find premake5

=head1 SYNOPSIS

    use Alien::premake5;
    use Env qw( @PATH );

    unshift @ENV, Alien::premake5->bin_dir;
    my $premake = Alien::premake5->exe;
    system $premake, 'gmake';

=head1 DESCRIPTION

Premake is a build tool that allows a software project to be described with a
single common build script, which can then be used to generate project files
for building under a wide variety of build environments.

B<Alien::premake5> uses L<Alien::Build> to make it easier to use premake in a
Perl application or project.

This distribution will find an available version of C<premake5>, or attempt to
build one from source.

=head1 METHODS

=over 4

=item B<exe>

    my $premake = Alien::premake5->exe;

Returns the name of the premake executable. Currently, this should be
C<premake5>.

When using the executable compiled by this distribution, you
will need to make sure that the directories returned by C<bin_dir> are added
to your C<PATH> environment variable. For more info, check the documentation
of L<Alien::Build>.

=back

=head1 HELPERS

=over 4

=item B<premake5>

The C<%{premake5}> string will be interpolated by Alien::Build into the name
of the premake5 executable (as returned by B<exe>);

=back

=head1 SEE ALSO

=over 4

=item * L<https://premake.github.io/>

=back

=head1 CONTRIBUTIONS AND BUG REPORTS

Contributions of any kind are most welcome!

The main repository for this distribution is on
L<Github|https://github.com/jjatria/Alien-premake5>, which is where patches
and bug reports are mainly tracked. Bug reports can also be sent through the
CPAN RT system, or by mail directly to the developers at the addresses below,
although these will not be as closely tracked.

Development uses L<Dist::Zilla>, and is tracked in the C<master> branch of the
code repository. Code contributions can be made directly on that branch (which
will likely require you to use Dist::Zilla), or on the C<build> branch of the,
which holds the built code and has no need for development tools.

=head1 AUTHOR

=over 4

=item * José Joaquín Atria <jjatria@cpan.org>

=back

=head1 ACKNOWLEDGEMENTS

Special thanks to Graham Ollis for his help in the preparation of this
distribution.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by José Joaquín Atria.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
