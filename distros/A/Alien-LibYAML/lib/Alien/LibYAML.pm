package Alien::LibYAML;

use strict;
use warnings;
use 5.008001;
use base qw(Alien::Base);

our $VERSION = '2.04'; # VERSION
# ABSTRACT: Build and install libyaml, a C-based YAML parser and emitter



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::LibYAML - Build and install libyaml, a C-based YAML parser and emitter

=head1 VERSION

version 2.04

=head1 SYNOPSIS

In your Build.PL:

 use Module::Build;
 use Alien::LibYAML;
 my $builder = Module::Build->new(
   ...
   configure_requires => {
     'Alien::LibYAML' => '0',
     ...
   },
   extra_compiler_flags => Alien::LibYAML->cflags,
   extra_linker_flags   => Alien::LibYAML->libs,
   ...
 );
 
 $build->create_build_script;

In your Makefile.PL:

 use ExtUtils::MakeMaker;
 use Config;
 use Alien::LibYAML;
 
 WriteMakefile(
   ...
   CONFIGURE_REQUIRES => {
     'Alien::LibYAML' => '0',
   },
   CCFLAGS => Alien::LibYAML->cflags . " $Config{ccflags}",
   LIBS    => [ Alien::LibYAML->libs ],
   ...
 );

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

=head1 AUTHOR

Original author: Richard Simões (RSIMOES)

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013-2018 by Richard Simões.

This is free software, licensed under:

  The MIT (X11) License

=cut
