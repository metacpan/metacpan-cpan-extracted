package Data::ReqRep::Shared::Int;
use strict;
use warnings;
our $VERSION = '0.09';
use Data::ReqRep::Shared ();
1;

__END__

=head1 NAME

Data::ReqRep::Shared::Int - server-side handle for the Int request/reply channel

=head1 DESCRIPTION

Server handle for the lock-free Int request/reply channel, created via
C<< Data::ReqRep::Shared::Int->new($path, $req_cap, $resp_slots) >> (or
C<new_memfd>, C<new_from_fd>). All methods are documented in the parent module
L<Data::ReqRep::Shared>.

=cut
