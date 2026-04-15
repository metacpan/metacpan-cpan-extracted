package TestRole::Excludes;
use Role;

excludes qw(TestRole::Basic); # Excludes TestRole::Basic

sub excluded_method { "Excluded" }

1;
