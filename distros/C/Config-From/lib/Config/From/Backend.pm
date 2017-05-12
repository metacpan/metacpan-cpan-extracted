package Config::From::Backend;
$Config::From::Backend::VERSION = '0.05';

use utf8;
use Moose;

has 'debug' => (
                is       => 'rw',
               );

has 'name'  => (
                is       => 'rw',
                isa      => 'Str',
            );


sub _log{
  my ($self, $msg ) = @_;

  return if ! $self->debug;

  say STDERR "[debug] $msg";
}


1;
