package Data::ReqRep::Shared::Int::Client;
use strict;
use warnings;
our $VERSION = '0.06';
use Data::ReqRep::Shared ();
1;

__END__

=head1 NAME

Data::ReqRep::Shared::Int::Client - client-side handle for the Int request/reply channel

=head1 DESCRIPTION

Client handle for the Int request/reply channel, created via
C<< Data::ReqRep::Shared::Int::Client->new($path) >> (or C<new_from_fd>). All
methods are documented in the parent module L<Data::ReqRep::Shared>.

=cut
