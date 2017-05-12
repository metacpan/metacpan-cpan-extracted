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

  foreach my $ext (qw(mp4 m4a m4p 3gp)) {
    my $tmp;
    for (qw(read write)) {
      $tmp += 50 if $config->{$pkg}{"${_}_mp4"};
    }


    # prefer non-perl implementations
    unless ($config->{$pkg}{pure_perl}) {
      $tmp += 10 if $tmp;
    }

    # if no default set and this plugin has a score, or if this plugin
    # score higher than the existing default, then set default
    if (! exists $config->{default}{$ext} and $tmp
       or $tmp and $tmp >= $config->{default}{$ext}{score}) {
      $config->{default}{$ext} = { name => $pkg, score => $tmp };
      warn "AudioFile::Info - Default $ext handler is now $pkg\n";
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

Dave Cross, E<lt>dave@dave.org.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Dave Cross

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


