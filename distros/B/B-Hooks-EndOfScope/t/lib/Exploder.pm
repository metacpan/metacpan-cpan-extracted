package Exploder;
use B::Hooks::EndOfScope;
BEGIN { on_scope_end { die "crap" } }
1;
