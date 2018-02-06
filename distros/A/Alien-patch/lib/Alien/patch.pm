package Alien::patch;

use strict;
use warnings;
use base qw( Alien::Base );
use Env qw( @PATH );

# ABSTRACT: Find or build patch
our $VERSION = '0.14'; # VERSION


sub exe
{
  $^O eq 'MSWin32' ? 'patch --binary' : 'patch';
}

sub _vendor
{
  shift->runtime_prop->{my_vendor};
}


sub alien_helper
{
  return {
    patch => sub {
      Alien::patch->exe;
    },
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::patch - Find or build patch

=head1 VERSION

version 0.14

=head1 SYNOPSIS

 use Alien::patch ();
 use Env qw( @PATH );
 
 unshift @PATH, Alien::patch->bin_dir;
 my $patch = Alien::patch->exe;
 system "$patch -p1 < foo.patch";

Or with L<Alien::Build::ModuleBuild>:

 use Alien::Base::ModuleBuild;
 Alien::Base::ModuleBuild->new(
   ...
   alien_bin_requires => {
     'Alien::patch' => '0.08',
   },
   alien_build_commands => {
     '%{patch} -p1 < foo.patch',
   },
   ...
 )->create_build_script;

=head1 DESCRIPTION

Many environments provide the patch command, but a few do not.
Using this module in your C<Build.PL> (or elsewhere) you can
make sure that patch will be available.  If the system provides
it, then great, this module is a no-op.  If it does not, then
it will download and install it into a private location so that
it can be added to the C<PATH> when this module is used.

This class is a subclass of L<Alien::Base>, so all of the methods documented there
should work with this class.

=head1 METHODS

=head2 exe

 my $exe = Alien::patch->exe;

Returns the command to run patch on your system.  For now it simply
adds the C<--binary> option on Windows (C<MSWin32> but not C<cygwin>)
which is usually what you want.

=head1 HELPERS

=head2 patch

 %{patch}

When used with L<Alien::Base::ModuleBuild> in a C<alien_build_commands> or C<alien_install_commands>,
this helper will be replaced by either C<patch> (Unix and cygwin) or C<patch --binary> (MSWin32).

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Zakariyya Mughal

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
