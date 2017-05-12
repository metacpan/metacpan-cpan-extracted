package Auth::Kokolores::Plugin::FailDelay;

use Moose;

# ABSTRACT: kokolores plugin which add a delay on failed authentication
our $VERSION = '1.01'; # VERSION

extends 'Auth::Kokolores::Plugin';

has 'delay' => (
  is => 'ro', isa => 'Int', default => 1,
);

sub post_process {
  my ( $self, $r, $response ) = @_;

  if( ! $response->success ) {
    sleep( $self->delay );
  }

  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Auth::Kokolores::Plugin::FailDelay - kokolores plugin which add a delay on failed authentication

=head1 VERSION

version 1.01

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
