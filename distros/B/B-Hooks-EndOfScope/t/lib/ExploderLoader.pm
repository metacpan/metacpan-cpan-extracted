package ExploderLoader;
use B::Hooks::EndOfScope;
BEGIN { on_scope_end { require Exploder } }
1;
