package Data::ReqRep::Shared::Client;
use strict;
use warnings;
our $VERSION = '0.06';
use Data::ReqRep::Shared ();
1;

__END__

=head1 NAME

Data::ReqRep::Shared::Client - client-side handle for the Str request/reply channel

=head1 DESCRIPTION

Client handle for the Str request/reply channel, created via
C<< Data::ReqRep::Shared::Client->new($path) >> (or C<new_from_fd>). All methods
are documented in the parent module L<Data::ReqRep::Shared>.

=cut
