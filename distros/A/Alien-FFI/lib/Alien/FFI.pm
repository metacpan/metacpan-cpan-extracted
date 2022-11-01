package Alien::FFI;

use strict;
use warnings;
use Config;
use base qw( Alien::Base );

# ABSTRACT: Build and make available libffi
our $VERSION = '0.27'; # VERSION




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::FFI - Build and make available libffi

=head1 VERSION

version 0.27

=head1 SYNOPSIS

In your Makefile.PL:

 use ExtUtils::MakeMaker;
 use Alien::Base::Wrapper ();

 WriteMakefile(
   Alien::Base::Wrapper->new('Alien::FFI')->mm_args2(
     # MakeMaker args
     NAME => 'My::XS',
     ...
   ),
 );

In your Build.PL:

 use Module::Build;
 use Alien::Base::Wrapper qw( Alien::FFI !export );

 my $builder = Module::Build->new(
   ...
   configure_requires => {
     'Alien::FFI' => '0',
     ...
   },
   Alien::Base::Wrapper->mb_args,
   ...
 );

 $build->create_build_script;

=head1 DESCRIPTION

This distribution installs libffi so that it can be used by other Perl distributions.  If already
installed for your operating system, and it can be found, this distribution will use the libffi
that comes with your operating system, otherwise it will download it from the Internet, build and
install it for you.

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus>

Write Perl bindings to non-Perl libraries without C or XS

=item L<FFI::CheckLib>

Check that a library is available for FFI

=back

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Petr Písař (ppisar)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
