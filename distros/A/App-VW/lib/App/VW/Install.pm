package App::VW::Install;
use strict;
use warnings;
use base 'App::VW::Command';
use File::Copy;
use File::ShareDir 'module_dir';

sub options {
  my ($class) = @_;
  (
    $class->SUPER::options,
  );
}

our %systems;
$systems{debian} = {};
$systems{ubuntu} = $systems{debian};
$systems{gentoo} = undef;
$systems{centos} = undef;

sub post_installation_message {
my ($self) = @_;
qq|---

The installation of vw was successful.

To start, stop, and restart vw:

  sudo /etc/init.d/vw start
  sudo /etc/init.d/vw stop
  sudo /etc/init.d/vw restart

To make vw start upon bootup:

  sudo update-rc.d vw defaults

To disable vw from starting upon boot:

  sudo update-rc.d -f vw remove

|;
};

sub run {
  my ($self) = @_;
  my $src = module_dir('App::VW') . "/etc/init.d/vw-ubuntu";
  my $dst = "/etc/init.d/vw";
  $self->verbose("Copying $src to $dst .\n");
  copy($src, $dst) || die "Can't copy file to $dst:  $!";
  $self->verbose("Making $dst executable.\n");
  chmod(0755, $dst) || die "Can't make $dst executable: $!";
  $self->verbose("Creating /etc/vw .\n");
  if (! -d "/etc/vw" ) {
    mkdir "/etc/vw" || die "Can't create /etc/vw: $!";
  }
  print $self->post_installation_message;
  return;
}

1;

=head1 NAME

App::VW::Install - install init script and config dir for vw

=head1 SYNOPSIS

Installing the init script and creating the config directory

  sudo vw install

=head1 DESCRIPTION

Running the install command will copy an init script into
F</etc/init.d/vw> and it will create a config directory in
F</etc/vw> that C<vw setup> will populate with YAML files.

The format of these YAML files is described in the documentation
for L<App::VW>.

=cut
