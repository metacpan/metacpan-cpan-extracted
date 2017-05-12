package App::Xssh::Config;

use strict;
use warnings;

use Moose;
use Config::General;

use version; our $VERSION = qv("v1.0.0");

=head1 NAME

App::Xssh::Config - Encapsulates the configuration for xssh - using Config::General

=head1 SYNOPSYS

	use App::Xssh::Config;
	
	my $config = App::Xssh::Config->new();
	my $data = $config->read();
	
	$config->add(["location","path","setting"],"value");

	print $config->show();
	$config->write();
=cut

=head1 METHODS

=over

=item new()

Construcor, just used to provide an object with access to the methods
=cut

sub _configFilename {
  return "$ENV{HOME}/.xsshrc";
}

sub _openConfig {
  my ($self) = @_;

  if ( ! $self->{ConfigGeneral} ) {
    my $filename = _configFilename();

    if ( ! -f $filename ) {
      if ( ! open(my $temp, ">", $filename) ) {
        return;
      }
    }
    $self->{ConfigGeneral} = Config::General->new($filename);
  }

  return $self->{ConfigGeneral};
}

=item read()

Reads the config file into memory, returns a hashref pointing to the config data
=cut
sub read {
  my ($self) = @_;

  if ( ! $self->{data} ) {
    if ( my $conf = $self->_openConfig() ) {
        $self->{data} = { $conf->getall() };
    }
  }

  return $self->{data};
}

=item add($path,$value)

Adds a data to the existing config data - in memory.   

=over

=item $path

An arrayref to the location of the atrribute to be stored.

=item $value

A string to be stored at that location.

=back
=cut
sub add {
  my ($self,$path,$value) = @_;

  my $attr = pop @$path;

  my $config = $self->read();
  for my $key ( @$path ) {
    if ( ! defined($config->{$key}) ) {
      $config->{$key} = {};
    }
    $config = $config->{$key};
  }
  $config->{$attr} = $value;
}

=item delete($path)

Deletes data from the existing config data - in memory.   

=over

=item $path

An arrayref to the location of the atrribute to be deleted.

=back
=cut
sub delete {
  my ($self,$path) = @_;

  my $attr = pop @$path;

  my $config = $self->read();
  for my $key ( @$path ) {
    if ( ! defined($config->{$key}) ) {
      $config->{$key} = {};
    }
    $config = $config->{$key};
  }
  delete $config->{$attr};
}

=item show()

Wanders through the config data, and returns a string to describe the
data hierachy
=cut
sub show {
  my ($self) = @_;

  my $sub = sub {
    my ($sub,$prefix,$data) = @_;

    my $rv = "";
    for my $key ( sort keys %$data ) {
      if ( ref($data->{$key}) ) {
        $rv .= "$prefix$key\n";
        $rv .= $sub->($sub,"$prefix  ",$data->{$key});
      } else {
        $rv .= "$prefix$key: $data->{$key}\n";
      }
    }
    return $rv;
  };

  my $data = $self->read();
  return $sub->($sub,"",$data);
}

=item write()

Writes the current config data back to a config file on disk.  Completely overwrites the existinng file.
=cut
sub write{
  my ($self) = @_;

  my $data = $self->read();
  if ( my $conf = $self->_openConfig() ) {
    $conf->save_file(_configFilename(),$data);
    return 1;
  }
}

=back

=head1 COPYRIGHT & LICENSE

Copyright 2010-2013 Evan Giles.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
=cut

1; # End of App::Xssh::Config
