package AudioFile::Info::Build;

use strict;
use warnings;

use base 'Module::Build';

use YAML qw(LoadFile DumpFile);

sub ACTION_install {
  my $self = shift;

  $self->SUPER::ACTION_install(@_);

  require AudioFile::Info;

  die "Can't find the installation of AudioFile::Info\n" if $@;

  my $pkg = $self->notes('package');

  my $path = $INC{'AudioFile/Info.pm'};

  $path =~ s/Info.pm$/plugins.yaml/;

  my $config;

  if (-f $path) {
    $config = LoadFile($path);
  }

  $config->{$pkg} = $self->notes('config');

  # calculate "usefulness" score

  my ($score);
  my @types = qw[ogg mp3];
  my @modes = qw[read write];

  for my $type (@types) {
    for my $mode (@modes) {
      $score->{$type} += 50 if $config->{$pkg}{"${mode}_${type}"};
    }
  }

  # prefer non-perl implementations
  unless ($config->{$pkg}{pure_perl}) {
    for (@types) {
      $score->{$_} += 10 if $score->{$_};
    }
  }

  # if no default set and this plugin has a score, or if this plugin
  # score higher than the existing default, then set default
  for (@types) {
    if ($score->{$_} and (not exists $config->{default}{$_}
       or $score->{$_} >= $config->{default}{$_}{score})) {
      $config->{default}{$_} = { name => $pkg, score => $score->{$_} };
      warn "AudioFile::Info - Default $_ handler is now $pkg\n";
    }
  }

  DumpFile($path, $config);
}

1;

=head1 NAME

AudioFile::Info::Build - Build utilities for AudioFile::Info.

=head1 DESCRIPTION

This is a module which is used as part of the build system for
AudioFile::Info plugins.

See L<AudioFile::Info> for more details.

=head1 METHODS

=head2 ACTION_install

Overrides the ACTION_install method from Module::Build.

=head1 AUTHOR

Dave Cross, E<lt>dave@perlhacks.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Dave Cross

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

