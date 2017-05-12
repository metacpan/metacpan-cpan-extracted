package Cache::FastMemoryBackend;

use strict;
use warnings;
use base qw(Cache::MemoryBackend);

sub restore
{
  my ( $self, $p_namespace, $p_key ) = @_;

  return $self->_get_store_ref( )->{ $p_namespace }{ $p_key };
}

1;

__END__

=pod

=head1 NAME

Cache::FastMemoryBackend - The backend to Cache::FastMemoryCache.

=head1 SYNOPSIS

See Cache::Backend for the usage synopsis.

=head1 DESCRIPTION

This is an internal module used by Cache::FastMemoryCache.
It is not intended to be instaniated or manipulated by the
end-user.

=head1 AUTHOR

John Millaway E<lt>millaway@acm.orgE<gt>

=head1 SEE ALSO

Cache::Backend, Cache::MemoryBackend, Cache::ShareMemoryBackend

=cut

