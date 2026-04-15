package TestClass::Conflict::Fatal;
use Class;
with 'TestRole::Basic', 'TestRole::Conflicting'; # Conflict on common_method


1;
