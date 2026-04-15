package TestClass::Excludes::Fail;
use Class;
with 'TestRole::Basic', 'TestRole::Excludes'; # Conflict here!


1;
