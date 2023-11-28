package Alien::zix;
$Alien::zix::VERSION = '0.02';
use strict;
use warnings;
use base qw( Alien::Base );
use 5.008004;

use File::Spec;
use ExtUtils::PkgConfig;

sub pkg_config_path {
	my ($class) = @_;
	if( $class->install_type eq 'share' ) {
		return File::Spec->catfile( File::Spec->rel2abs($class->dist_dir), qw(lib pkgconfig) );
	} else {
		return ExtUtils::PkgConfig->variable('zix-0', 'pcfiledir');
	}
}

1;

=head1 NAME

Alien::zix - Find or build Zix C99 data structure library

=head1 SYNOPSIS

From L<ExtUtils::MakeMaker>:

 use ExtUtils::MakeMaker;
 use Alien::Base::Wrapper ();

 WriteMakefile(
   Alien::Base::Wrapper->new('Alien::zix')->mm_args2(
     NAME => 'FOO::XS',
     ...
   ),
 );

From L<Module::Build>:

 use Module::Build;
 use Alien::Base::Wrapper qw( Alien::zix !export );
 use Alien::zix;

 my $build = Module::Build->new(
   ...
   configure_requires => {
     'Alien::Base::Wrapper' => '0',
     'Alien::zix' => '0',
     ...
   },
   Alien::Base::Wrapper->mb_args,
   ...
 );

 $build->create_build_script;

From L<Inline::C> / L<Inline::CPP> script:

 use Inline 0.56 with => 'Alien::zix';

From L<Dist::Zilla>

 [@Filter]
 -bundle = @Basic
 -remove = MakeMaker

 [Prereqs / ConfigureRequires]
 Alien::zix = 0

 [MakeMaker::Awesome]
 header = use Alien::Base::Wrapper qw( Alien::zix !export );
 WriteMakefile_arg = Alien::Base::Wrapper->mm_args

From L<FFI::Platypus>:

 use FFI::Platypus;
 use Alien::zix;

 my $ffi = FFI::Platypus->new(
   lib => [ Alien::zix->dynamic_libs ],
 );

=head1 DESCRIPTION

This distribution provides Zix so that it can be used by other
Perl distributions that are on CPAN.  It does this by first trying to
detect an existing install of Zix on your system.  If found it
will use that.  If it cannot be found, the source code will be downloaded
from the internet and it will be installed in a private share location
for the use of other modules.

=head1 SEE ALSO

=over 4

=item L<https://gitlab.com/drobilla/zix>

Zix repo

=item L<Alien>

Documentation on the Alien concept itself.

=item L<Alien::Base>

The base class for this Alien.

=item L<Alien::Build::Manual::AlienUser>

Detailed manual for users of Alien classes.

=back

=cut
