package BackPAN::Index::Role::Log;

use Mouse::Role;

has debug =>
  is		=> 'ro',
  isa		=> 'Bool',
  default	=> 0;

sub _log {
    my $self = shift;
    return unless $self->debug;
    print STDERR @_, "\n";
}

1;
