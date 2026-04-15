package TestRole::Requires;
use Role;

requires qw(implemented_method mandatory_method);

sub required_method_body { "Required" }

1;
