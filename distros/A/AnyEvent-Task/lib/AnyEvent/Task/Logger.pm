package AnyEvent::Task::Logger;

use common::sense;

use Log::Defer;


require Exporter;
use base 'Exporter';
our @EXPORT = qw(logger);


our $log_defer_object;


sub logger {
  if (!$log_defer_object) {
    $log_defer_object = Log::Defer->new(sub {});
  }

  return $log_defer_object;
}




1;
