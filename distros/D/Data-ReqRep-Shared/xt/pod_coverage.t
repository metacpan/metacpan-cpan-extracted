use strict;
use warnings;
use Test::More;

plan skip_all => 'Test::Pod::Coverage required'
    unless eval { require Test::Pod::Coverage; 1 };

# Public API is documented in prose under =head2 Server API / Client API
# / eventfd / etc., not per-method =head/=item entries. Trust the current
# surface; add new methods here as they're added so reviews catch any
# truly undocumented additions.
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
)$/x;

Test::Pod::Coverage::pod_coverage_ok('Data::ReqRep::Shared',
    { trustme => [$api] });

Test::Pod::Coverage::pod_coverage_ok('Data::ReqRep::Shared::Client',
    { trustme => [$api] });

done_testing;
