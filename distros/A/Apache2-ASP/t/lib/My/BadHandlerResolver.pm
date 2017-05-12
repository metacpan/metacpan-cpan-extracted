
package My::BadHandlerResolver;
use base 'Apache2::ASP::HTTPContext::HandlerResolver';

sub resolve_request_handler {
  die "TEST ERROR";
}

1;

