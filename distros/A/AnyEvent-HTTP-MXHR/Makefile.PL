use inc::Module::Install;
name 'AnyEvent-HTTP-MXHR';
all_from 'lib/AnyEvent/HTTP/MXHR.pm';

requires 'AnyEvent' => '6.01';
requires 'AnyEvent::Handle';
requires 'AnyEvent::HTTP';

test_requires 'AnyEvent::Socket';
test_requires 'JSON';
test_requires 'Test::TCP';

WriteAll;