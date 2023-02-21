package Alien::CPython3;
$Alien::CPython3::VERSION = '0.01';
use strict;
use warnings;
use base qw( Alien::Base );
use 5.008004;

use Path::Tiny qw(path);

sub exe {
  my($class) = @_;
  $class->runtime_prop->{command};
}

sub bin_dir {
	my $class = shift;
  if($class->install_type('share') && defined $class->runtime_prop->{share_bin_dir_rel}) {
		my $prop = $class->runtime_prop;
		return
			map { path($_)->absolute($class->dist_dir)->stringify }
			ref $prop->{share_bin_dir_rel} ? @{ $prop->{share_bin_dir_rel} } : ($prop->{share_bin_dir_rel});
	} else {
		return $class->SUPER::bin_dir(@_);
	}
}

1;

=head1 NAME

Alien::CPython3 - Find or build Python

=head1 SYNOPSIS

From L<ExtUtils::MakeMaker>:

 use ExtUtils::MakeMaker;
 use Alien::Base::Wrapper ();

 WriteMakefile(
   Alien::Base::Wrapper->new('Alien::CPython3')->mm_args2(
     NAME => 'FOO::XS',
     ...
   ),
 );

From L<Module::Build>:

 use Module::Build;
 use Alien::Base::Wrapper qw( Alien::CPython3 !export );
 use Alien::CPython3;

 my $build = Module::Build->new(
   ...
   configure_requires => {
     'Alien::Base::Wrapper' => '0',
     'Alien::CPython3' => '0',
     ...
   },
   Alien::Base::Wrapper->mb_args,
   ...
 );

 $build->create_build_script;

From L<Inline::C> / L<Inline::CPP> script:

 use Inline 0.56 with => 'Alien::CPython3';

From L<Dist::Zilla>

 [@Filter]
 -bundle = @Basic
 -remove = MakeMaker

 [Prereqs / ConfigureRequires]
 Alien::CPython3 = 0

 [MakeMaker::Awesome]
 header = use Alien::Base::Wrapper qw( Alien::CPython3 !export );
 WriteMakefile_arg = Alien::Base::Wrapper->mm_args

Command line tool:

 use Alien::CPython3;
 use Env qw( @PATH );

 unshift @PATH, Alien::CPython3->bin_dir;

=head1 DESCRIPTION

This distribution provides Python so that it can be used by other
Perl distributions that are on CPAN.  It does this by first trying to
detect an existing install of Python on your system.  If found it
will use that.  If it cannot be found, the source code will be downloaded
from the internet and it will be installed in a private share location
for the use of other modules.

=head1 SEE ALSO

=over 4

=item L<Alien>

Documentation on the Alien concept itself.

=item L<Alien::Base>

The base class for this Alien.

=item L<Alien::Build::Manual::AlienUser>

Detailed manual for users of Alien classes.

=back

=cut
