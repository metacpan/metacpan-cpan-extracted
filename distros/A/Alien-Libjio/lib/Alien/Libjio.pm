package Alien::Libjio;
BEGIN {
  $Alien::Libjio::VERSION = '1.004';
}
# ABSTRACT: Utility package to install and locate libjio

use strict;
use warnings;
use Carp ();


sub new {
  my ($class, @seed) = @_;

  Carp::croak('You must call this as a class method') if ref($class);

  my $self = {
    installed => 0,
  };

  bless($self, $class);

  $self->_try_pkg_config()
    or $self->_try_liblist()
    or delete($self->{method});

  return $self;
}


sub installed {
  my ($self) = @_;

  Carp::croak('You must call this method as an object') unless ref($self);

  return $self->{installed};
}


sub version {
  my ($self) = @_;

  Carp::croak('You must call this method as an object') unless ref($self);

  return $self->{version};
}


sub ldflags {
  my ($self) = @_;

  Carp::croak('You must call this method as an object') unless ref($self);

  # Return early if called in void context
  return unless defined wantarray;

  # If calling in array context, dereference and return
  return @{ $self->{ldflags} } if wantarray;

  return $self->{ldflags};
}

# Glob to create an alias to ldflags
*linker_flags = *ldflags;


sub cflags {
  my ($self) = @_;

  Carp::croak('You must call this method as an object') unless ref($self);

  # Return early if called in void context
  return unless defined wantarray;

  # If calling in array context, dereference and return
  return @{ $self->{cflags} } if wantarray;

  return $self->{cflags};
}
*compiler_flags = *cflags;


sub method {
  my ($self) = @_;

  Carp::croak('You must call this method as an object') unless ref($self);

  return $self->{method};
}
*how = *method;

# Private methods to find & fill out information

use IPC::Open3 ('open3');

sub _get_pc {
  my ($key) = @_;

  my $read;
  my $pid = open3(undef, $read, undef, 'pkg-config', 'libjio', '--' . $key);
  # We're using blocking wait, so the return value doesn't matter
  ## no critic(RequireCheckedSyscalls)
  waitpid($pid, 0);

  # Check the exit status; 0 = success - nonzero = failure
  if (($? >> 8) == 0) {
    # The value we got back
    return <$read>;
  }
  return (undef, <$read>) if wantarray;
  return;
}

sub _try_pkg_config {
  my ($self) = @_;

  my ($value, $err) = _get_pc('cflags');
  return unless (defined $value && length $value);
  #if (defined $err && length $err) {
  #  #warn "Problem with pkg-config; using ExtUtils::Liblist instead\n";
  #  return;
  #}

  $self->{installed} = 1;
  $self->{method} = 'pkg-config';

  # pkg-config returns things with a newline, so remember to remove it
  $self->{cflags} = [ split(' ', $value) ];
  $self->{ldflags} = [ split(' ', _get_pc('libs')) ];
  $self->{version} = _get_pc('modversion');

  return 1;
}

sub _try_liblist {
  my ($self) = @_;

  use ExtUtils::Liblist ();
  local $SIG{__WARN__} = sub { }; # mask warnings

  my (undef, undef, $ldflags, $ldpath) = ExtUtils::Liblist->ext('-ljio');
  return unless (defined($ldflags) && length($ldflags));

  $self->{installed} = 1;
  $self->{method} = 'ExtUtils::Liblist';

  # Empty out cflags; initialize it
  $self->{cflags} = [];

  my $read;
  my $pid = open3(undef, $read, undef, 'getconf', 'LFS_CFLAGS');

  # We're using blocking wait, so the return value doesn't matter
  ## no critic(RequireCheckedSyscalls)
  waitpid($pid, 0);

  # Check the status code
  if (($? >> 8) == 0) {
    # This only takes the first line
    push(@{ $self->{cflags} }, split(' ', <$read>));
  }
  else {
    warn 'Problem using getconf: ', <$read>, "\n";
    push(@{ $self->{cflags} },
      '-D_LARGEFILE_SOURCE',
      '-D_FILE_OFFSET_BITS=64',
    );
  }

  # Used for resolving the include path, relative to lib
  use Cwd ();
  use File::Spec ();
  push(@{ $self->{cflags} },
    # The include path is taken as: $libpath/../include
    '-I' . Cwd::realpath(File::Spec->catfile(
      $ldpath,
      File::Spec->updir(),
      'include'
    ))
  );

  push(@{ $self->{ldflags} },
    '-L' . $ldpath,
    $ldflags,
  );

  return 1;
}


__END__
=pod

=head1 NAME

Alien::Libjio - Utility package to install and locate libjio

=head1 VERSION

version 1.004

=head1 SYNOPSIS

  use Alien::Libjio;

  my $jio = Alien::Libjio->new;
  my $ldflags = $jio->ldflags;
  my $cflags = $jio->cflags;

=head1 DESCRIPTION

To ensure reliability, some file systems and databases provide support for
something known as journalling. The idea is to ensure data consistency by
creating a log of actions to be taken (called a Write Ahead Log) before
committing them to disk. That way, if a transaction were to fail due to a
system crash or other unexpected event, the write ahead log could be used to
finish writing the data.

While this functionality is often available with networked databases, it can
be a rather memory- and processor-intensive solution, even where reliable
writes are important. In other cases, the filesystem does not provide native
journalling support, so other tricks may be used to ensure data integrity,
such as writing to a separate temporary file and then overwriting the file
instead of modifying it in-place. Unfortunately, this method cannot handle
threaded operations appropriately.

Thankfully, Alberto Bertogli published a userspace C library called libjio
that can provide these features in a small (less than 1500 lines of code)
library with no external dependencies.

This package is designed to install it, and provide a way to get the flags
necessary to compile programs using it. It is particularly useful for Perl XS
programs that use it, such as B<IO::Journal>.

=head1 METHODS

=head2 Alien::Libjio->new

Creates a new C<Alien::Libjio> object, which essentially just has a few
convenience methods providing useful information like compiler and linker
flags.

Example code:

  my $jio = Alien::Libjio->new();

This method will return an appropriate B<Alien::Libjio> object or throw an
exception on error.

=head2 $jio->installed

Determine if a valid installation of libjio has been detected in the system.
This method will return a true value if it is, or undef otherwise.

Example code:

  print "okay\n" if $jio->installed;

=head2 $jio->version

Determine the installed version of libjio, as a string.

Currently versions are simply floating-point numbers, so you can treat the
version number as such, but this behaviour is subject to change.

Example code:

  my $version = $jio->version;

=head2 $jio->ldflags

=head2 $jio->linker_flags

This returns the flags required to link C code with the local installation of
libjio (typically in the LDFLAGS variable). It is particularly useful for
building and installing Perl XS modules such as L<IO::Journal>.

In scalar context, it returns an array reference suitable for passing to
other build systems, particularly L<Module::Build>. In list context, it gives
a normal array so that C<join> and friends will work as expected.

Example code:

  my $ldflags = $jio->ldflags;
  my @ldflags = @{ $jio->ldflags };
  my $ldstring = join(' ', $jio->ldflags);
  # or:
  # my $ldflags = $jio->linker_flags;

=head2 $jio->cflags

=head2 $jio->compiler_flags

This method returns the compiler option flags to compile C code which uses
the libjio library (typically in the CFLAGS variable). It is particularly
useful for building and installing Perl XS modules such as L<IO::Journal>.

Example code:

  my $cflags = $jio->cflags;
  my @cflags = @{ $jio->cflags };
  my $ccstring = join(' ', $jio->cflags);
  # or:
  # my $cflags = $jio->compiler_flags;

=head2 $jio->method

=head2 $jio->how

This method returns the method the module used to find information about
libjio. The following methods are currently used (in priority order):

=over

=item *

pkg-config: the de-facto package information tool

=item *

ExtUtils::Liblist: a utility module used by ExtUtils::MakeMaker

=back

Example code:

  if ($jio->installed) {
    print 'I found this information using: ', $jio->how, "\n";
  }

=head1 ACKNOWLEDGEMENTS

=over

=item *

Special thanks to Alberto Bertogli E<lt>albertito@blitiri.com.arE<gt> for
developing this useful library and for releasing it into the public domain.

=back

=head1 SEE ALSO

L<IO::Journal>, a Perl module that provides an interface to libjio.

L<http://blitiri.com.ar/p/libjio/>, Alberto Bertogli's page about libjio,
which explains the purpose and features of libjio.

=head1 CAVEATS

=over

=item *

This module can only search known/common paths for libjio installations.
It does try to use B<pkg-config> and B<ExtUtils::Liblist> to find a libjio
installation on your system, but it cannot predict where files might have
been installed. As a result, this package might install a duplicate copy
of libjio.

=item *

There is currently no way to save a custom library installation path for
libjio. This is likely to change in the future.

=item *

B<pkg-config> may fail if you have an insecure $ENV{PATH} variable. Due to
the way IPC::Open3 works, taintedness exceptions are suppressed and pkg-config
seems to fail for no reason. The recommended fix for this is to use a module
like L<Env::Sanctify::Auto> or to otherwise clean up the calling environment.
Another workaround is to disable taint checking, but that's not recommended.
(See: L<http://rt.perl.org/rt3/Ticket/Display.html?id=66572>)

=back

1;

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Alien-Libjio

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Jonathan Yu <jawnsy@cpan.org>

=head1 COPYRIGHT AND LICENSE

Legally speaking, this package and its contents are:

  Copyright (c) 2011 by Jonathan Yu <jawnsy@cpan.org>.

But this is really just a legal technicality that allows the author to
offer this package under the public domain and also a variety of licensing
options. For all intents and purposes, this is public domain software,
which means you can do whatever you want with it.

The software is provided "AS IS", without warranty of any kind, express or
implied, including but not limited to the warranties of merchantability,
fitness for a particular purpose and noninfringement. In no event shall the
authors or copyright holders be liable for any claim, damages or other
liability, whether in an action of contract, tort or otherwise, arising from,
out of or in connection with the software or the use or other dealings in
the software.

=cut

