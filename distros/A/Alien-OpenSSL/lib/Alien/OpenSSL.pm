package Alien::OpenSSL;

use strict;
use warnings;

# ABSTRACT: Alien wrapper for OpenSSL
our $VERSION = '0.14'; # VERSION







use base 'Alien::Base';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::OpenSSL - Alien wrapper for OpenSSL

=head1 VERSION

version 0.14

=head1 SYNOPSIS

In your Makefile.PL:

 use ExtUtils::MakeMaker;
 use Alien::Base::Wrapper ();

 WriteMakefile(
   Alien::Base::Wrapper->new('Alien::OpenSSL')->mm_args2(
     # MakeMaker args
     NAME => 'My::XS',
     ...
   ),
 );

In your Build.PL:

 use Module::Build;
 use Alien::Base::Wrapper qw( Alien::OpenSSL !export );

 my $builder = Module::Build->new(
   ...
   configure_requires => {
     'Alien::OpenSSL' => '0',
     ...
   },
   Alien::Base::Wrapper->mb_args,
   ...
 );

 $build->create_build_script;

=head1 DESCRIPTION

This distribution provides OpenSSL so that it can be used by other
Perl distributions that are on CPAN.  It does this by first trying to
detect an existing install of OpenSSL on your system.  If found it
will use that.  If it cannot be found, the source code will be downloaded
from the internet and it will be installed in a private share location
for the use of other modules.

=head1 SEE ALSO

L<Alien>, L<Alien::Base>, L<Alien::Build::Manual::AlienUser>

=head1 AUTHOR

Original author: Johanna Amann E<lt>johanna@icir.orgE<gt>

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Salvador Fandiño

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012-2022 by Johanna Amann.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
