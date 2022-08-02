package Alien::libdeflate;

use strict;
use warnings;
use base qw{ Alien::Base };

our $VERSION = '0.03';

1;

__END__

=pod

=encoding UTF-8

=begin html

<a href="https://www.perl.org/get.html">
  <img src="https://img.shields.io/badge/perl-5.8.9+-blue.svg"
       alt="Requires Perl 5.8.9+" />
</a>
<!-- CPAN -->
<a href="https://metacpan.org/pod/Alien::libdeflate">
  <img src="https://img.shields.io/cpan/v/Alien-libdeflate.svg"
       alt="CPAN" />
</a>
<!-- GitHub Actions -->
<a href="https://github.com/kiwiroy/alien-libdeflate/actions/workflows/ci.yml">
  <img src="https://github.com/kiwiroy/alien-libdeflate/actions/workflows/ci.yml/badge.svg"
       alt="Build Status" />
</a>

=end html

=head1 NAME

Alien::libdeflate - Fetch/build/stash the libdeflate headers and libs for
L<libdeflate|https://github.com/ebiggers/libdeflate>

=head1 SYNOPSIS

In your C<Makefile.PL> with L<ExtUtils::MakeMaker>.

  use Alien::libdeflate;
  use ExtUtils::MakeMaker;
  use Alien::Base::Wrapper qw( Alien::libdeflate !export );
  use Config;

  WriteMakefile(
    # ...
    Alien::Base::Wrapper->mm_args,
    # ...
    );

In your script or module.

  use Alien::libdeflate;
  use Env qw( @PATH );

  unshift @PATH, Alien::libdeflate->bin_dir;

=head1 DESCRIPTION

Download, build, and install the libdeflate C headers and libraries into a
well-known location, C<<< Alien::libdeflate->dist_dir >>>, from whence other
packages can make use of them.

The version installed will be the latest release on the master branch from
the libdeflate GitHub L<repository|https://github.com/ebiggers/libdeflate>.

=head2 Influential Environment Variables

=over 4

=item ALIEN_LIBDEFLATE_PROBE_CFLAGS

If I<libdeflate> is installed system wide in an alternate location than the
default search paths, set this variable to add the B<include> directory using
C<-I/path/to/system/libdeflate/include>

=item ALIEN_LIBDEFLATE_PROBE_LDFLAGS

If I<libdeflate> is installed system wide in an alternate location than the
default search paths, set this variable to add the B<lib> directory using
C<-L/path/to/system/libdeflate/lib>

=back

=head1 AUTHORS

Roy Storey (kiwiroy@cpan.org)

Zakariyya Mughal <zmughal@cpan.org>

=cut
