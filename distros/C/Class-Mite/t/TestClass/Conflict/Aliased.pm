package TestClass::Conflict::Aliased;
use Class;
with
    'TestRole::Basic',
    {
        role => 'TestRole::Conflicting',
        alias => { common_method => 'conflicting_method_aliased' }
    };


1;
