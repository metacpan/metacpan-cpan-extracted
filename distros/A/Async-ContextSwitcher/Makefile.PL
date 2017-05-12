use inc::Module::Install;

all_from('lib/Async/ContextSwitcher.pm');
readme_from('lib/Async/ContextSwitcher.pm');

requires 'Exporter::Tiny' => '0';

test_requires 'AnyEvent';

WriteAll;
