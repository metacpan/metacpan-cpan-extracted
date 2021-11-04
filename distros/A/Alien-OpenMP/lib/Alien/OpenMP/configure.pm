package Alien::OpenMP::configure;
use strict;
use warnings;
use Config;

our $CCNAME = $ENV{CC} || $Config::Config{ccname};
our $OS     = $^O;

my $checked   = 0;
my $supported = {
  gcc   => {cflags => ['-fopenmp'],            libs => ['-fopenmp']},
  clang => {cflags => ['-Xclang', '-fopenmp'], libs => ['-lomp']},      # this could be -Xpreprocessor
};

sub cflags {
  shift->_update_supported;
  return join ' ', @{$supported->{$OS}{cflags} || $supported->{$CCNAME}{cflags} || []};
}

sub is_known {
  shift->_update_supported;
  return !!(exists($supported->{$OS}) || exists($supported->{$CCNAME}));
}

sub lddlflags { __PACKAGE__->libs }

sub libs {
  shift->_update_supported;
  return join ' ', @{$supported->{$OS}{libs} || $supported->{$CCNAME}{libs} || []};
}

sub unsupported {
  my ($self, $build) = (shift, shift);

  # build an array of messages
  my @msg = ("This version of $CCNAME does not support OpenMP");
  if ($CCNAME eq 'gcc' and $OS ne 'darwin') {
    push @msg, "This could be a bug, please record and issue https://github.com/oodler577/p5-Alien-OpenMP/issues";
  }

  if ($OS eq 'darwin') {
    push @msg, "Support can be enabled by using Homebrew or Macports (https://clang-omp.github.io)";
    push @msg, "    brew install libomp (Homebrew https://brew.sh)";
    push @msg, "    port install libomp (Macports https://www.macports.org)";
  }

  # report messages using appropriate method
  if (ref($build)) {
    return if $build->install_prop->{alien_openmp_compiler_has_openmp};
    unshift @msg, "phase = @{[$build->meta->{phase}]}";
    $build->log($_) for @msg;
  }
  elsif ($build && (my $log = $build->can('log'))) {
    unshift @msg, "phase = @{[$build->meta->{phase}]}";
    $log->($_) for @msg;
  }
  else {
    warn join q{>}, __PACKAGE__, " $_\n" for @msg;
  }
  print "OS Unsupported\n";
}

# test support only
sub _reset { $checked = 0; }

sub _update_supported {
  return if $checked;
  if ($OS eq 'darwin') {
    require File::Which;
    require Path::Tiny;

    # The issue here is that ccname=gcc and cc=cc as an interface to clang
    $supported->{darwin} = {cflags => ['-Xclang', '-fopenmp'], libs => ['-lomp'],};
    if (my $mp = File::Which::which('port')) {

      # macports /opt/local/bin/port
      my $mp_prefix = Path::Tiny->new($mp)->parent->parent;
      push @{$supported->{darwin}{cflags}}, "-I$mp_prefix/include/libomp";
      unshift @{$supported->{darwin}{libs}}, "-L$mp_prefix/lib/libomp";
    }
    else {
      # homebrew has the headers and library in /usr/local
      push @{$supported->{darwin}{cflags}}, "-I/usr/local/include";
      unshift @{$supported->{darwin}{libs}}, "-L/usr/local/lib";
    }
  }
  $checked++;
}

1;

=encoding utf8

=head1 NAME

Alien::OpenMP::configure - Install time configuration helper

=head1 SYNOPSIS

  # alienfile
  use Alien::OpenMP::configure;

  if (!Alien::OpenMP::configure->is_known) {
    Alien::OpenMP::configure->unsupported(__PACKAGE__);
    exit;
  }

  plugin 'Probe::CBuilder' => (
    cflags  => Alien::OpenMP::configure->cflags,
    libs    => Alien::OpenMP::configure->libs,
    ...
  );

=head1 DESCRIPTION

L<Alien::OpenMP::configure> is storage for the compiler flags required for multiple compilers on multiple systems and
an attempt to intelligently support them.

This module is designed to be used by the L<Alien::OpenMP::configure> authors and contributors, rather than end users.

=head1 METHODS

L<Alien::OpenMP::configure> implements the following methods.

=head2 cflags

Obtain the compiler flags for the compiler and architecture suitable for passing as C<cflags> to
L<Alien::Build::Plugin::Probe::CBuilder>.

=head2 is_known

Return a Boolean to indicate whether the compiler is known to this module.

=head2 lddlflags

A synonym for L</"libs">.

=head2 libs

Obtain the compiler flags for the compiler and architecture suitable for passing as C<libs> to
L<Alien::Build::Plugin::Probe::CBuilder>.

=head2 unsupported

Report using L<Alien::Build::Log> or L<warn|https://metacpan.org/pod/perlfunc#warn-LIST> that the compiler/architecture
combination is unsupported and provide minimal notes on any solutions. There is little to no guarding of the actual
state of support in this function.

=cut
