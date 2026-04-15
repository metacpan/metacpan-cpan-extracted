package TestClass::Requires::Success;
use Class;
with 'TestRole::Requires';

sub implemented_method { "Implemented" }
sub mandatory_method { "Mandatory" } # Required by TestRole::Requires

1;
