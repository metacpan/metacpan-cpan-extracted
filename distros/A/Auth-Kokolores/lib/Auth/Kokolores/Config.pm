package Auth::Kokolores::Config;

use Moose;

# ABSTRACT: configuration for Auth::Kokolores
our $VERSION = '1.01'; # VERSION

use Tie::IxHash;
use Config::General qw(ParseConfig);

has 'log_level' => ( is => 'rw', isa => 'Int', default => '2' );
has 'log_file' => ( is => 'rw', isa => 'Str', default => 'Sys::Syslog' );

has 'syslog_ident' => ( is => 'rw', isa => 'Str', default => 'kokolores' );
has 'syslog_facility' => ( is => 'rw', isa => 'Str', default => 'auth' );

has 'socket_path' => ( is => 'rw', isa => 'Str', default => '/var/run/saslauthd/mux' );
has 'socket_mode' => ( is => 'rw', isa => 'Maybe[Str]' );

has 'pid_file' => ( is => 'rw', isa => 'Maybe[Str]' );

has 'user' => ( is => 'rw', isa => 'Maybe[Str]' );
has 'group' => ( is => 'rw', isa => 'Maybe[Str]' );

has 'protocol' => ( is => 'rw', isa => 'Str', default => 'CyrusSaslauthd' );

# prefork engine options
has 'min_servers' => ( is => 'rw', isa => 'Int', default => '4' );
has 'min_spare_servers' => ( is => 'rw', isa => 'Int', default => '4' );
has 'max_spare_servers' => ( is => 'rw', isa => 'Int', default => '12' );
has 'max_servers' => ( is => 'rw', isa => 'Int', default => '25' );
has 'max_requests' => ( is => 'rw', isa => 'Int', default => '1000' );

has 'satisfy' => ( is => 'rw', isa => 'Str', default => 'all' );

has 'overwrittable_attributes' => (
  is => 'ro', isa => 'ArrayRef[Str]', default => sub { [
    'log_level', 'log_file'
  ] },
);
has 'net_server_attributes' => (
  is => 'ro', isa => 'ArrayRef[Str]', default => sub { [
    'syslog_ident', 'syslog_facility', 'user', 'group',
    'min_servers', 'min_spare_servers', 'max_spare_servers', 'max_servers',
    'max_requests', 'pid_file',
  ] },
);
has 'kokolores_attributes' => (
  is => 'ro', isa => 'ArrayRef[Str]', default => sub { [
    'socket_path', 'socket_mode', 'satisfy', 'protocol',
  ] },
);

has 'Plugin' => ( is => 'rw', isa => 'HashRef', default => sub { {} } );

sub new_from_file {
  my ( $class, $file ) = @_;

  if( ! -f $file ) {
    print(STDERR 'configuration file '.$file." does not exist!\n");
    exit 1;
  }

  tie my %config_hash, "Tie::IxHash";
  %config_hash = ParseConfig(
    -AllowMultiOptions => 'no',
    -ConfigFile => $file,
    -Tie => "Tie::IxHash"
  );
  
  return $class->new( %config_hash );
}

sub apply_config {
  my ( $self, $main ) = @_;
  my $server = $main->{'server'};

  foreach my $attr ( @{$self->overwrittable_attributes}) {
    if( ! defined $server->{$attr} ) {
      $server->{$attr} = $self->$attr;
    }
  }
  foreach my $attr ( @{$self->net_server_attributes}) {
    $server->{$attr} = $self->$attr;
  }
  foreach my $attr ( @{$self->kokolores_attributes}) {
    $main->{$attr} = $self->$attr;
  }
  $main->{'kokolores_config'} = $self;

  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Auth::Kokolores::Config - configuration for Auth::Kokolores

=head1 VERSION

version 1.01

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
