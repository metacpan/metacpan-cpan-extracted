package Alien::Editline;

use strict;
use warnings;
use base qw( Alien::Base );

# ABSTRACT: Build and make available Editline (libedit)
our $VERSION = '0.10'; # VERSION








1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Editline - Build and make available Editline (libedit)

=head1 VERSION

version 0.10

=head1 SYNOPSIS

In your Makefile.PL:

 use ExtUtils::MakeMaker;
 use Alien::Base::Wrapper ();

 WriteMakefile(
   Alien::Base::Wrapper->new('Alien::Editline')->mm_args2(
     # MakeMaker args
     NAME => 'Kafka::Librd',
     ...
   ),
 );

In your Build.PL:

 use Module::Build;
 use Alien::Base::Wrapper qw( Alien::Editline !export );

 my $builder = Module::Build->new(
   ...
   configure_requires => {
     'Alien::Editline' => '0',
     ...
   },
   Alien::Base::Wrapper->mb_args,
   ...
 );

 $build->create_build_script;

In your L<FFI::Platypus> script or module:

 use FFI::Platypus;
 use Alien::Editline;

 my $ffi = FFI::Platypus->new(
   lib => [ Alien::Editline->dynamic_libs ],
 );

=head1 DESCRIPTION

This distribution installs Editline so that it can be used by other Perl distributions.  If already
installed for your operating system, and it can be found, this distribution will use the Editline
that comes with your operating system, otherwise it will download it from the Internet, build and
install it fro you.

=head1 SEE ALSO

L<Alien>, L<Alien::Base>, L<Alien::Build::Manual::AlienUser>

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Tom Hukins (TOMHUKINS)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014-2020 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
