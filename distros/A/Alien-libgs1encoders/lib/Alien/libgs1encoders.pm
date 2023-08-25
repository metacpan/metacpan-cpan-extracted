# SPDX-License-Identifier: GPL-1.0-or-later OR Artistic-1.0-Perl

package Alien::libgs1encoders;

use strict;
use warnings;
use 5.008001;
use base qw(Alien::Base);

our $VERSION = '0.03'; # VERSION
# ABSTRACT: Build and install libgs1encoders, a C-based GS1 barcode parser



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::libgs1encoders - Build and install libgs1encoders, a C-based GS1 barcode parser

=head1 VERSION

version 0.03

=head1 SYNOPSIS

In your Makefile.PL:

 use ExtUtils::MakeMaker;
 use Alien::Base::Wrapper ();

 WriteMakefile(
   Alien::Base::Wrapper->new('Alien::libgs1encoders')->mm_args2(
     # MakeMaker args
     NAME => 'My::XS',
     ...
   ),
 );

In your Build.PL:

 use Module::Build;
 use Alien::Base::Wrapper qw( Alien::libgs1encoders !export );

 my $builder = Module::Build->new(
   ...
   configure_requires => {
     'Alien::libgs1encoders' => '0',
     ...
   },
   Alien::Base::Wrapper->mb_args,
   ...
 );

 $build->create_build_script;

=head1 DESCRIPTION

This distribution provides an alien wrapper for libgs1encoders. It requires a C
compiler. That's all!

=head1 AUTHOR

hangy

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by hangy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
