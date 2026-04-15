package TestRole::Conflicting;
use Role;

sub common_method { "Conflicting" } # Conflicts with TestRole::Basic
sub exclusive_method { "Exclusive" }

1;
