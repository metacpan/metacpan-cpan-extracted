package App::EvalServerAdvanced::Config;

our $VERSION = '0.017';

use v5.20.0;

use strict;
use warnings;
use TOML;
use Path::Tiny;

require Exporter;
our @ISA = qw/Exporter/;
our @EXPORT = qw/config/;

our $config;
our $config_dir;

sub load_config {
  my $file = path($config_dir)->child("config.toml");

  my $data = $file->slurp_utf8();

  my $makemagic = sub {
    my $value = shift;

    if (ref $value eq 'HASH') {
      my $nv = +{map {; $_ => __SUB__->($value->{$_})} keys %$value};
      return bless $nv, "App::EvalServerAdvanced::Config::_magichash";
    } elsif (ref $value eq 'ARRAY') {
      return [map {__SUB__->($_)} @$value];
    } else {
      return $value;
    }
  };
  
  $config = $makemagic->(TOML::from_toml($data));
}

sub config {
  my ($section) = @_;
  if (!defined $config) {
    load_config();
  };

  return $config;
}

package
  App::EvalServerAdvanced::Config::_magichash;
use Carp qw/croak/;

sub DESTROY {}

our $AUTOLOAD;
sub AUTOLOAD {
  my ($self) = @_;
  my $pack = __PACKAGE__;
  my $meth = $AUTOLOAD;
  $meth =~ s/^${pack}:://;

  if (exists $self->{$meth}) {
      return $self->{$meth};
  } else {
    croak "Config key [$meth] not found" if ($ENV{DEBUG});
    return undef;
  }
}

1;
