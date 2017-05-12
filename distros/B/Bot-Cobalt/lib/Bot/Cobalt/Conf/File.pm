package Bot::Cobalt::Conf::File;
$Bot::Cobalt::Conf::File::VERSION = '0.021003';
use v5.10;
use strictures 2;
use Carp;

use Bot::Cobalt::Common ':types';
use Bot::Cobalt::Serializer;

use Try::Tiny;

use Types::Path::Tiny -types;

use List::Objects::WithUtils;
use List::Objects::Types -types;

use Moo;
with 'Bot::Cobalt::Conf::Role::Reader';


has cfg_path => (
  required  => 1,
  is        => 'rwp',
  isa       => Path,
  coerce    => 1,
);

has cfg_as_hash => (
  lazy      => 1,
  is        => 'rwp',
  isa       => HashObj,
  coerce    => 1,
  builder   => '_build_cfg_hash',
);

has debug => (
  is        => 'rw',
  isa       => Bool,
  builder   => sub { 0 },
);

sub BUILD {
  my ($self) = @_;
  $self->cfg_as_hash
}

sub _build_cfg_hash {
  my ($self) = @_;

  if ($self->debug) {
    warn 
      ref $self, " (debug) reading cfg_as_hash from ", $self->cfg_path, "\n"
  }
  
  my $cfg = $self->readfile( $self->cfg_path );

  my $err; try {
    $self->validate($cfg)
  } catch {
    $err = $_;
    undef
  } or croak "Conf validation failed for ". $self->cfg_path .": $err";

  $cfg
}

sub rehash {
  my ($self) = @_;
  
  $self->_set_cfg_as_hash( $self->_build_cfg_hash )
}

sub validate {
  my ($self, $cfg) = @_;
  
  1
}

1;
__END__

=pod

=head1 NAME

Bot::Cobalt::Conf::File - Base class for Bot::Cobalt cfg files

=head1 SYNOPSIS

  ## Subclass for a particular cfg file:
  package MyPackage::Conf;
  use Moo;
  extends 'Bot::Cobalt::Conf::File';

  # An attribute filled from loaded YAML cfg_as_hash:
  has opts => (
    lazy => 1,
    
    is  => 'rwp',

    default => sub {
      my ($self) = @_;

      $self->cfg_as_hash->{Opts}
    },
  );

  # Override validate() to check for correctness:
  around 'validate' => sub {
    my ($orig, $self, $cfg_hash) = @_;
    
    die "Missing directive: Opts"
      unless defined $cfg_hash->{Opts};

    1
  };

  ## Use cfg file elsewhere:
  package MyPackage;
  
  my $cfg = MyPackage::Conf->new(
    cfg_path => $path_to_yaml_cfg,
  );

  my $opts = $cfg->opts;

=head1 DESCRIPTION

This is the base class for L<Bot::Cobalt> configuration files.
It consumes the Bot::Cobalt::Conf::Role::Reader role and loads a 
configuration hash from a YAML file specified by the required B<cfg_path> 
attribute.

The B<validate> method is called at load-time and passed the 
configuration hash before it is loaded to the B<cfg_as_hash> attribute; 
this method can be overriden by subclasses to do some load-time checking 
on a configuration file.

=head2 cfg_path

The B<cfg_path> attribute is required at construction-time; this is the 
actual path to the YAML configuration file.

=head2 cfg_as_hash

The B<cfg_as_hash> attribute returns the loaded file as a hash reference. 
This is normally used by subclasses to fill attributes, and not used 
directly.

=head2 rehash

The B<rehash> method attempts to reload the current
B<cfg_as_hash> from B<cfg_path>.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
