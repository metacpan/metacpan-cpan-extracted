package Alien::MUSCLE;

use strict;
use warnings;
use base qw(Alien::Base);
use Path::Tiny 'path';

our $VERSION = '0.01';

sub muscle_binary {
  my $class = shift || __PACKAGE__;
  my @paths = path($class->bin_dir)->children(qr/^muscle/);
  return "@{[ shift @paths ]}";
}

sub muscle_dist_type {
  my $class = shift;
  return $class->runtime_prop->{muscle_dist_type};
}

1;

=encoding utf8

=head1 NAME

Alien::MUSCLE - Discover or easy install of MUSCLE

=head1 SYNOPSIS

  use Alien::MUSCLE;
  @cmd = Alien::MUSCLE->muscle_binary;
  push @cmd, (-in => 'sequences.fa', -out => 'results.afa', @opts);
  system { $cmd[0] } @cmd;

Or using L<Bio::Tools::Run::Alignment::Muscle>

  use Env qw(@PATH);
  use Bio::Tools::Run::Alignment::Muscle;
  unshift @PATH, Alien::MUSCLE->bin_dir;
  $muscle = Bio::Tools::Run::Alignment::Muscle->new(@params);
  $align = $muscle->align('sequences.fa');

=head1 DESCRIPTION

Discover or download and install L<MUSCLE|https://www.drive5.com/muscle/>.

=head1 METHODS

L<Alien::MUSCLE> inherits all the methods from L<Alien::Base> and implements the
following new ones.

=head2 muscle_binary

  # "/installed/path/to/muscle"
  $binary = Alien::MUSCLE->muscle_binary;

The full path to the installed muscle.

=head2 muscle_dist_type

  # "source"
  $type = Alien::MUSCLE->muscle_dist_type;

How the program was installed. This is either I<source>, if the source
distribution was downloaded and built, or I<binary> if the pre-built software
was downloaded and installed. The pre-built software is statically compiled.

=head1 INSTALLATION

Installing L<Alien::MUSCLE> is straight forward.

If you have L<cpanm>, you only need one line:

  cpanm Alien::MUSCLE

Otherwise, any other cpan client may be used.

=head2 INFLUENTIAL ENVIRONMENT VARIABLES

Installation may be customised to a limited extent with the following
environment variables:

=over 4

=item ALIEN_MUSCLE_FORCE_BINARY

Setting this variable to a true value will force the download of a pre-built
binary distribution of L<MUSCLE|https://www.drive5.com/muscle/>. These versions
are statically compiled and will not require a compiler on the local machine.
However there are a limited number of architectures provided and a source
install may be better in those situations.

=back

=head1 COPYRIGHT & LICENSE

This library is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHORS

Roy Storey - <kiwiroy@cpan.org>

=cut
