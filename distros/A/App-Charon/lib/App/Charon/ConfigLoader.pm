package App::Charon::ConfigLoader;
$App::Charon::ConfigLoader::VERSION = '0.001003';
use utf8;
use Moo;
use warnings NONFATAL => 'all';

use JSONY;
use IO::All;
use Try::Tiny;
use Module::Runtime 'use_module';
use namespace::clean;

has _env_key => (
   is => 'ro',
   init_arg => 'env_key',
   required => 1,
);

has _location => (
   is => 'ro',
   init_arg => undef,
   lazy => 1,
   default => sub {
      my $self = shift;
      $ENV{$self->_env_key . '_CONFLOC'} || $self->__location
   },
);

has __location => (
   is => 'ro',
   init_arg => 'location',
);

has _config_class => (
   is => 'ro',
   init_arg => 'config_class',
   required => 1,
);

sub _io { io->file(shift->_location) }

sub _read_config_from_file {
   my $self = shift;
   try {
      JSONY->new->load($self->_io->all)
   } catch {
      {}
   }
}

sub _read_config_from_env {
   my $k_re = '^' . quotemeta($_[0]->_env_key) . '_(.+)';

   +{
      map {; m/$k_re/; lc $1 => $ENV{$_[0]->_env_key . "_$1"} }
      grep m/$k_re/,
      keys %ENV
   }
}

sub _read_config {
   {
      %{$_[0]->_read_config_from_file},
      %{$_[0]->_read_config_from_env},
   }
}

sub load { use_module($_[0]->_config_class)->new($_[0]->_read_config) }

1;
