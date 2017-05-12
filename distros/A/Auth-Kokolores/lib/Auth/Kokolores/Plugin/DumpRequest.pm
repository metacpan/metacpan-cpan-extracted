package Auth::Kokolores::Plugin::DumpRequest;

use Moose;

# ABSTRACT: kokolores plugin for debugging
our $VERSION = '1.01'; # VERSION

extends 'Auth::Kokolores::Plugin';


has 'success' => ( is => 'rw', isa => 'Int', default => 0);
has 'hide_server_obj' => ( is => 'rw', isa => 'Int', default => 1);

use Data::Dumper;

sub authenticate {
  my ( $self, $r ) = @_;
  my $sort_keys_backup;

  if( $self->hide_server_obj ) {
    $sort_keys_backup = $Data::Dumper::Sortkeys;
    $Data::Dumper::Sortkeys = sub {
      my ($hash) = @_;
      return [ grep { $_ ne 'server' } keys %$hash ];
    };
  }

  $r->log(4, 'request data: '.Dumper($r) );

  if( $self->hide_server_obj ) {
    $Data::Dumper::Sortkeys = $sort_keys_backup;
  }

  return $self->success;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Auth::Kokolores::Plugin::DumpRequest - kokolores plugin for debugging

=head1 VERSION

version 1.01

=head1 DESCRIPTION

This plugin dumps the requests data to the debug log.

=head1 USAGE

  <Plugin debug>
    module="DumpRequest"
    success=1
  </Plugin>

=head1 PARAMETERS

=head2 success (default:0)

When set to 0 returns failure, if set to 1 returns success.

=head2

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
