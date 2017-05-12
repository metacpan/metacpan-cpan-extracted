package Alien::MSYS2;

use strict;
use warnings;
use 5.008001;
use File::Spec;
use JSON::PP ();

# ABSTRACT: Tools required for autogen scripts in Windows (MSYS2)
our $VERSION = '0.02'; # VERSION


sub new
{
  my($class) = @_;
  bless {}, $class;
}


{

  my $share;
  my $config;

  sub _share ()
  {
    $share ||= do {
      $_ = __FILE__;
      s{(MSYS2).pm}{.$1.devshare};
      my $share = -e $_
        ? do {
          require File::Basename;
          # TODO: squeeze out the updirs
          File::Spec->rel2abs(File::Spec->catdir(File::Basename::dirname("lib/Alien/MSYS2.pm"), File::Spec->updir, File::Spec->updir, "share"));
        }
        : do {
          require File::ShareDir;
          File::ShareDir::dist_dir('Alien-MSYS2');
        };
    };
  }

  sub _config ()
  {
    $config ||= do {
      my $filename = File::Spec->catfile(_share, 'alien_msys2.json');
      open my $fh, '<', $filename;
      JSON::PP::decode_json(do { local $/; <$fh> });
    };
  }
}

sub install_type
{
  _config()->{install_type};
}


sub msys2_root
{
  _config->{msys2_root} || File::Spec->catdir(_share, _config->{ptrsize} == 8 ? 'msys64' : 'msys32');
}


sub bin_dir
{
  my($class) = @_;
  return if $^O eq 'msys';
  my $dir = File::Spec->catdir( $class->msys2_root, qw( usr bin ) );
  $dir =~ s{\\}{/}g;
  if($class->install_type eq 'system')
  {
    require File::Which;
    # assume if pacman is in the path then MSYS is already in the path
    my $pacman = File::Which::which('pacman');
    return if $pacman;
    require Config;
    require File::Basename;
    # we need to make sure, with strawberry for example,
    # that Perl's c compiler is used and not the MSYS2 one.
    my $cc = File::Which::which(do { no warnings; $Config::Config{cc} });
    $cc = File::Basename::dirname $cc if $cc;
    $cc =~ s{\\}{/}g if $cc;
    return $cc ? ($cc, $dir) : ($dir);
  }
  else
  {
    return ($dir);
  }
}


sub cflags { '' }
sub libs   { '' }
sub dynamic_libs { () }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::MSYS2 - Tools required for autogen scripts in Windows (MSYS2)

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 use Alien::MSYS2;
 my $root = Alien::MSYS2->msys2_root;

=head1 DESCRIPTION

B<Please note> that this module is somewhat experimental.  I do not intend
on intentionally making breaking changes, but because of the maturity of
this module it may be unavoidable.  If you need something more battle tested
you should try L<Alien::MSYS> instead.

This L<Alien> module provides the L<MSYS2|https://msys2.github.io/> tools,
which are useful for building many open source packages on the Microsoft
Windows platform.  When this module is installed, it will generally look
for an existing C<MSYS2> install, if it is available, and if not it will
attempt to download it from the internet and install it to a share directory
so that it can be used by other Perl modules.

Here is how the detection logic works:

=over 4

=item check for user override for download

If the C<ALIEN_FORCE> environment variable is set to true, or if
C<ALIEN_INSTALL_TYPE> is set to C<share>, then L<Alien::MSYS2> will not
probe your system for an existing C<MSYS2> install, and instead download
it from the internet.

=item check for user override for system

If the C<ALIEN_MSYS2_ROOT> variable is set, L<Alien::MSYS2> will check if
that is the location of C<MSYS2> and use it.

=item check registry

If L<Alien::MSYS2> can find the uninstall registry key for C<MSYS2> it will
use this.  Typically if you installed C<MSYS2> using the GUI installer, and
haven't moved it since this should work.

=item check shortcuts

If L<Alien::MSYS2> can find appropriate start menu shortcuts that point to
a valid C<MSYS2> install, then it will use that.

=item check that download is acceptable fallback

If C<ALIEN_INSTALL_TYPE> is not set to C<system>, then L<Alien::MSYS2> will
download C<MSYS2> from the internet.  If it is set to C<system> and none of
the other methods above succeeded, the install for L<Alien::MSYS2> will fail.

=back

=head1 CONSTRUCTOR

=head2 new

 my $alien = Alien::MSYS2->new;

You can create an instance of L<Alien::MSYS2>, which you can use to call
its methods.  All of the methods for this class can also be called as
class methods, so usually you do not need to do this.

=head1 METHODS

=head2 install_type

 my $type = Alien::MSYS2->install_type;

Returns the install type for MSYS2.  This will be either the string "system"
or "share" indicating respectively either a system or a share install.

=head2 msys2_root

 my $dir = Alien::MSYS2->msys2_root

Returns the root of the MSYS2 install.

=head2 bin_dir

 my @dir = Alien::MSYS2->bin_dir;

Returns a list of directories that need to be added to the C<PATH> in order for
C<MSYS2> to operate.  Note that if C<MSYS2> is I<already> in the C<PATH>, this
will return an I<empty> list.

=head2 cflags

provided for L<Alien::Base> compatibility.  Does not do anything useful.

=head2 dynamic_libs

provided for L<Alien::Base> compatibility.  Does not do anything useful.

=head2 libs

provided for L<Alien::Base> compatibility.  Does not do anything useful.

=head1 SEE ALSO

=over 4

=item L<Alien>

Manifesto for the L<Alien> concept.

=item L<ALien::MSYS>

C<MSYS> is a project with a similar name and feature set to C<MSYS2>, but despite the name they
are different projects, not different versions of the same project.  L<Alien::MSYS> provides
C<MSYS>.

=item L<Alien::Base>

base class useful for writing L<Alien> modules.

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
