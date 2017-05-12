package Bot::Cobalt::Conf::Role::Reader;
$Bot::Cobalt::Conf::Role::Reader::VERSION = '0.021003';
use Carp;
use strictures 2;

use Try::Tiny;

use Bot::Cobalt::Common -types;
use Bot::Cobalt::Serializer;

use Moo::Role;

has _serializer => (
  is        => 'ro',
  isa       => InstanceOf['Bot::Cobalt::Serializer'],
  builder   => sub { Bot::Cobalt::Serializer->new },
);

sub readfile {
  my ($self, $path) = @_;

  confess "readfile() needs a path to read"
    unless defined $path;

  my $err;
  my $thawed_cf = try {
    $self->_serializer->readfile( $path )
  } catch {
    $err = $_
  };

  confess "Serializer readfile() failed for $path; $err"
    if defined $err;

  $thawed_cf
}


1;
__END__
