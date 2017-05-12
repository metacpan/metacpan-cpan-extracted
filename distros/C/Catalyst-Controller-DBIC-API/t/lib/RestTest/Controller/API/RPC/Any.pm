package RestTest::Controller::API::RPC::Any;
use Moose;
BEGIN { extends 'Catalyst::Controller::DBIC::API::RPC' }

use namespace::autoclean;

sub setup :Chained('/api/rpc/rpc_base') :CaptureArgs(1) :PathPart('any') {
  my ($self, $c, $object_type) = @_;

  my $config = {};
  if ($object_type eq 'artist') {
    $config->{class} = 'RestTestDB::Artist';
    $config->{create_requires} = [qw/name/];
    $config->{update_allows} = [qw/name/];
  } elsif ($object_type eq 'track') {
    $config->{class} = 'RestTestDB::Track';
    $config->{update_allows} = [qw/title position/];
  } else {
    $self->push_error($c, { message => "invalid object_type" });
    return;
  }

  $c->req->_set_class($config->{class});
  $self->_set_class($config->{class});
  $c->req->_set_current_result_set($self->stored_result_source->resultset);
  $c->stash->{$_} = $config->{$_} for keys %{$config};
}

1;
