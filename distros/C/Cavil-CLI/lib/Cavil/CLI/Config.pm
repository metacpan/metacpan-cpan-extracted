# SPDX-FileCopyrightText: SUSE LLC
# SPDX-License-Identifier: GPL-2.0-or-later

package Cavil::CLI::Config;
use Mojo::Base -base, -signatures;

use Mojo::File qw(path);
use Mojo::JSON qw(from_json to_json);

# Persistent per-user settings (the Cavil URL and API token) so they need not be passed on every run. Under
# XDG_CONFIG_HOME, and written 0600 because it holds a credential.

has dir => sub { path($ENV{XDG_CONFIG_HOME} || (($ENV{HOME} // '.') . '/.config'))->child('cavil-cli') };

sub file ($self) { return $self->dir->child('config.json') }

sub load ($self) {
  my $file = $self->file;
  return {} unless -f $file;
  my $data = eval { from_json($file->slurp) };
  return ref $data eq 'HASH' ? $data : {};
}

sub save ($self, $data) {
  $self->dir->make_path unless -d $self->dir;
  my $file = $self->file;
  $file->spew(to_json($data));
  chmod 0600, $file->to_string;
  return $self;
}

1;
