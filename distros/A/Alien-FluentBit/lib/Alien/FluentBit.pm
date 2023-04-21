package Alien::FluentBit;
our $VERSION = '0.01'; # VERSION
use strict;
use warnings;
use parent qw( Alien::Base );
require File::Spec::Functions;

# ABSTRACT: Locate libfluent-bit.so and fluent-bit binaries, or install from source

sub fluentbit {
   return File::Spec::Functions::catfile( Alien::FluentBit->bin_dir, 'fluent-bit' );
}

1;

__END__

=head1 SYNOPSIS

To Install fluent-bit from source:

  $ apt-get install cmake flex bison m4  # not required but saves time
  $ cpanm Alien::FluentBit

To install fluent-bit from official binary release:

  $ curl https://raw.githubusercontent.com/fluent/fluent-bit/master/install.sh | sh
  $ export LD_PRELOAD=/lib/fluent-bit/libfluent-bit.so # see below
  $ cpanm Alien::FluentBit

To use:

  use Alien::FluentBit;
  say "Commandline tool is ".Alien::FluentBit->fluentbit;
  say "Compile flags are ".Alien::FluentBit->cflags;
  say "Link flags are ".Alien::FluentBit->libs;

See the Makefile.PL of Fluent::LibFluentBit for a full example.

=head1 DESCRIPTION

This distribution either finds fluent-bit installed on your system (currently only at the
slightly odd locations used by the binary dist for Debian systems) or builds it from source.

Currently only building from source works properly, as the binary dist library conflucts with
perl related to TLS allocations, and needs pre-loaded.  Pre-loading a giant library like this
into every program you invoke is not ideal, so the from-source build is recommended.

Note that this module currently provides a custom minimal "fluent-bit.h" because the one from
upstream is broken.  This minimal header is also available as "fluent-bit-minimal.h"

=head1 ATTRIBUTES

(these are class attributes, not object attributes)

=over

=item version

The version of fluent-bit and libfluent-bit.so

=item fluentbit

The path of the fluent-bit executable

=item cflags

The C compiler flags

=item libs

The C linker flags and libraries

I<< ( this module does not yet support static linking ) >>

=back

See L<Alien::Base> for additional inherited attributes and methods.

=head1 SEE ALSO

=over

=item L<Alien>

Description of the Alien concept.

=item L<Fluent::LibFluentBit>

Perl-friendly XS wrapper around libfluent-bit.so

=back
