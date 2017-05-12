package Alien::LibYAML;

use strict;
use warnings;
use 5.008001;
use base qw(Alien::Base);

our $VERSION = '2.01'; # VERSION
# ABSTRACT: Build and install libyaml, a C-based YAML parser and emitter

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::LibYAML - Build and install libyaml, a C-based YAML parser and emitter

=head1 VERSION

version 2.01

=head1 SYNOPSIS

In your C<Build.PL>:

    use Alien::LibYAML;
    use Module::Build;
    
    Module::Build->new(
      ...
      extra_compiler_flags => Alien::LibYAML->cflags,
      extra_linker_flags   => Alien::LibYAML->libs,
      ...
    )->create_build_script;

=head1 DESCRIPTION

This distribution provides an alien wrapper for libyaml. It requires a C
compiler. That's all!

=head1 SEE ALSO

=over

=item L<YAML::XS>

Perl bindings for libyaml (library bundled with distribution).

=back

=head1 COPYRIGHT AND LICENSE

Copyright © 2014 Richard Simões. libyaml written and copyrighted by Kirill
Simonov. Both libyaml and this distribution are released under the terms of the
B<MIT License> and may be modified and/or redistributed under the same or any
compatible license.

=head1 AUTHORS

=over 4

=item *

Richard Simões <rsimoes AT cpan DOT org>

=item *

Graham Ollis <plicease@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Richard Simões.

This is free software, licensed under:

  The MIT (X11) License

=cut
