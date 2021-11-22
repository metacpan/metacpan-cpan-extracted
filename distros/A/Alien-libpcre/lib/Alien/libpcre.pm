package Alien::libpcre;

use strict;
use warnings;
use 5.008001;
use base qw( Alien::Base );

# ABSTRACT: Find or download and install libpcre (The "Perl Compatible" Regular Expressions library)
our $VERSION = '0.02'; # VERSION






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::libpcre - Find or download and install libpcre (The "Perl Compatible" Regular Expressions library)

=head1 VERSION

version 0.02

=head1 SYNOPSIS

In your Makefile.PL:

 use ExtUtils::MakeMaker;
 use Alien::Base::Wrapper ();

 WriteMakefile(
   Alien::Base::Wrapper->new('Alien::libpcre')->mm_args2(
     # MakeMaker args
     NAME => 'My::XS',
     ...
   ),
 );

In your Build.PL:

 use Module::Build;
 use Alien::Base::Wrapper qw( Alien::libpcre !export );

 my $builder = Module::Build->new(
   ...
   configure_requires => {
     'Alien::libpcre' => '0',
     ...
   },
   Alien::Base::Wrapper->mb_args,
   ...
 );

 $build->create_build_script;

In your L<FFI::Platypus> script or module:

 use FFI::Platypus;
 use Alien::libpcre;

 my $ffi = FFI::Platypus->new(
   lib => [ Alien::libpcre->dynamic_libs ],
 );

=head1 DESCRIPTION

B<Note> that this L<Alien> is for PCRE1, the deprecated older version of the
Perl (in)Compatible Regular Expression (PCRE) library.  It exists for projects
that require the older version of PCRE.  Currently the author uses it for
source builds of L<Alien::libnewrelic> and L<NewFangle>.  If you need the
newer currently supported version of PCRE see L<Alien::PCRE2>.

This distribution provides PCRE1 so that it can be used by other
Perl distributions that are on CPAN.  It does this by first trying to
detect an existing install of pcre on your system.  If found it
will use that.  If it cannot be found, the source code will be downloaded
from the internet and it will be installed in a private share location
for the use of other modules.

=head1 SEE ALSO

L<Alien>, L<Alien::Base>, L<Alien::Build::Manual::AlienUser>

=head1 CAVEATS

The pcre, is not, as the name might suggest, actually compatible with modern Perl regular expressions.

On Debian based systems (including Ubuntu), the development package for PCRE1 is C<libpcre3-dev>, which
is quite confusing, but I am sure there was a good reason for it.  If you want to do a C<system> install
use that package not the confusingly newer C<libpcre2-dev>.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
