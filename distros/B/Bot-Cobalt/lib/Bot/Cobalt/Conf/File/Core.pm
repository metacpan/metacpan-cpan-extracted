package Bot::Cobalt::Conf::File::Core;
$Bot::Cobalt::Conf::File::Core::VERSION = '0.021003';
use v5.10;
use strictures 2;

use Carp;

use Bot::Cobalt::Common ':types';

use Moo;
extends 'Bot::Cobalt::Conf::File';

has language => (
  lazy      => 1,
  is        => 'rwp',
  isa       => Str,
  default   => sub {
    my ($self) = @_;
    $self->cfg_as_hash->{Language} // 'english' ;
  },
);

has paths => (
  lazy      => 1,
  weak_ref  => 1,
  is        => 'rwp',
  isa       => HashRef,
  default   => sub {
    my ($self) = @_;
    ref $self->cfg_as_hash->{Paths} eq 'HASH' ?
      $self->cfg_as_hash->{Paths}
      : {}
  },
);

has irc => (
  lazy      => 1,
  weak_ref  => 1,
  is        => 'rwp',
  isa       => HashRef,
  default   => sub {
    my ($self) = @_;
    $self->cfg_as_hash->{IRC}
  },
);

has opts => (
  lazy      => 1,
  weak_ref  => 1,
  is        => 'rwp',
  isa       => HashRef,
  default   => sub {
    my ($self) = @_;
    $self->cfg_as_hash->{Opts}
  },
);

around 'validate' => sub {
  my ($orig, $self, $cfg) = @_;

  my $path = $self->cfg_path;

  for my $expected_hash (qw/ IRC Opts /) {
    unless (defined $cfg->{$expected_hash}) {
      die "Directive '$expected_hash' not found; should be a hash\n"
    }

    unless (ref $cfg->{$expected_hash} eq 'HASH') {
      die "Directive '$expected_hash' should be a hash\n"
    }
    
    if (defined $cfg->{Paths} && ref $cfg->{Paths} ne 'HASH') {
      die "Directive 'Paths' specified but not a hash\n"
    }
  }

  1
};


1;
__END__

=pod

=head1 NAME

Bot::Cobalt::Conf::File::Core - Bot::Cobalt core config

=head1 SYNOPSIS

  my $core_cfg = Bot::Cobalt::Conf::File::Core->new(
    cfg_path => $path_to_cobalt_cf,
  );
  
  my $paths_hash = $core_cfg->paths;
  my $lang = $core_cfg->language;
  my $irc_hash  = $core_cfg->irc;
  my $opts_hash = $core_cfg->opts;

=head1 DESCRIPTION

This is the L<Bot::Cobalt::Conf::File> subclass for "cobalt.conf" (the 
core L<Bot::Cobalt> configuration file).

From a L<Bot::Cobalt> plugin instance it would normally be accessed 
something like:

  use Bot::Cobalt;
  my $core_cfg = core()->get_core_cfg;

=head2 irc

Returns the 'IRC:' directive as a HASH.

=head2 language

Returns the 'Language:' directive as a string.

=head2 opts

Returns the 'Opts:' directive as a HASH.

=head2 paths

Returns the 'Paths:' directive as a HASH.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
