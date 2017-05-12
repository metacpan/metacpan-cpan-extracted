use Test::More 'no_plan';
use_ok("Bryar::Collector");

# Test the collect method exists
ok(Bryar::Collector->can("collect"), "We can call collect");
# Test the collect_current method exists
ok(Bryar::Collector->can("collect_current"), "We can call collect_current");

