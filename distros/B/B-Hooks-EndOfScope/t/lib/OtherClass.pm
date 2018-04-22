package OtherClass;
use B::Hooks::EndOfScope;
BEGIN { on_scope_end { 1 } }

use YetAnotherClass;

1;
