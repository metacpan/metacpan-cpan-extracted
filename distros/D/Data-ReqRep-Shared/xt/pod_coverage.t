use strict;
use warnings;
use Test::More;

plan skip_all => 'Test::Pod::Coverage required'
    unless eval { require Test::Pod::Coverage; 1 };

# Public API is documented in prose, not per-method =head/=item entries;
# add new methods here as they're added.
my $api = qr/^(
    DESTROY|AUTOLOAD|import|BEGIN
  | new | new_memfd | new_from_fd
  | recv | recv_wait | recv_multi | recv_wait_multi | drain
  | reply | send | send_wait | send_notify | send_wait_notify
  | get  | get_wait  | req | req_wait | cancel
  | clear | size | capacity | is_empty | resp_slots | resp_size
  | pending | stats | path | memfd | unlink | sync
  | notify | eventfd | eventfd_set | eventfd_consume | fileno
  | reply_eventfd | reply_eventfd_set | reply_eventfd_consume
  | reply_fileno  | reply_notify
  | req_eventfd_set | req_fileno
  | ready_fd | ready
)$/x;

Test::Pod::Coverage::pod_coverage_ok($_, { trustme => [$api] })
    for qw(Data::ReqRep::Shared Data::ReqRep::Shared::Client
           Data::ReqRep::Shared::Int Data::ReqRep::Shared::Int::Client);

done_testing;
