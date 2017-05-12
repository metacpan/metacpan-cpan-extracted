package Auth::Kokolores::Plugin;

use Moose;

# ABSTRACT: base class for kokolores plugins
our $VERSION = '1.01'; # VERSION

has 'name' => ( is => 'ro', isa => 'Str', required => 1 );

has 'server' => (
  is => 'ro',
  isa => 'Net::Server',
  required => 1,
  handles => {
    log => 'log',
  },
);

sub init {
  my ( $self ) = @_;
  return;
}

sub child_init {
  my ( $self, $server ) = @_;
  return;
}

sub pre_process {
  my ( $self, $r ) = @_;
  return;
}

sub authenticate {
  my ( $self, $r ) = @_;
  return;
}

sub post_process {
  my ( $self, $r, $response ) = @_;
  return;
}

sub shutdown {
  my ( $self ) = @_;
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Auth::Kokolores::Plugin - base class for kokolores plugins

=head1 VERSION

version 1.01

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
