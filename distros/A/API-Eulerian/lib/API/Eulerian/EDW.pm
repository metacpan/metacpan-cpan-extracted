package API::Eulerian::EDW;


use strict;
use API::Eulerian::EDW::Peer::Rest();

sub new {
  my $proto = shift();
  my $class = ref($proto) || $proto;
  return bless({}, $class);
}

sub get_csv_file {
  my ($self, $rh_p, $query) = @_;

  $rh_p ||= {};
  $rh_p->{accept} = 'text/csv';
  $rh_p->{hook} = 'API::Eulerian::EDW::Hook::Noop';

  $query ||= '';

  my $peer = new API::Eulerian::EDW::Peer::Rest( $rh_p );
  if ( !defined $peer ) {
    return { error => 1, error_msg => 'unable to build object' };
  }

  my $status = $peer->request( $query );

  if ( $status->error() ) {
    return {
      error => 1,
      error_msg => $status->msg()
    };
  }

  # kill request at EDW for clean-up
  $peer->cancel();

  return { error => 0, path2file => $status->path() };
}

1;
__END__
