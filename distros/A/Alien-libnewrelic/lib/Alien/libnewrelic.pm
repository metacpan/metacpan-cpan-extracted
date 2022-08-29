package Alien::libnewrelic;

use strict;
use warnings;
use 5.014;
use base qw( Alien::Base );

# ABSTRACT: Alien to download and install libnewrelic
our $VERSION = '0.08'; # VERSION






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::libnewrelic - Alien to download and install libnewrelic

=head1 VERSION

version 0.08

=head1 SYNOPSIS

In your Makefile.PL:

 use ExtUtils::MakeMaker;
 use Alien::Base::Wrapper ();

 WriteMakefile(
   Alien::Base::Wrapper->new('Alien::libnewrelic')->mm_args2(
     # MakeMaker args
     NAME => 'My::XS',
     ...
   ),
 );

In your Build.PL:

 use Module::Build;
 use Alien::Base::Wrapper qw( Alien::libnewrelic !export );

 my $builder = Module::Build->new(
   ...
   configure_requires => {
     'Alien::libnewrelic' => '0',
     ...
   },
   Alien::Base::Wrapper->mb_args,
   ...
 );

 $build->create_build_script;

In your L<FFI::Platypus> script or module:

 use FFI::Platypus;
 use Alien::libnewrelic;

 my $ffi = FFI::Platypus->new(
   lib => [ Alien::libnewrelic->dynamic_libs ],
 );

=head1 DESCRIPTION

This distribution provides NewRelic SDK so that it can be used by other
Perl distributions that are on CPAN.  It does this by first trying to
detect an existing install of NewRelic SDK on your system.  If found it
will use that.  If it cannot be found, the source code will be downloaded
from the internet and it will be installed in a private share location
for the use of other modules.

=head1 SEE ALSO

=over 4

=item L<NewFangle>

Perl level bindings for this SDK.

=item L<NewRelic::Agent::FFI>

This works with the older (no longer supported) NewRelic Agent SDK

=item L<NewRelic::Agent>

This is an even older XS API around the NewRelic Agent SDK, but doesn't link correctly against the NewRelic libraries.

https://github.com/aanari/NewRelic-Agent/issues/2

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
