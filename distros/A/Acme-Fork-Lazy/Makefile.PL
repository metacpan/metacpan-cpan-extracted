use inc::Module::Install;

name 'Acme-Fork-Lazy';
license 'perl';
all_from 'lib/Acme/Fork/Lazy.pm';

requires 'Exporter';
requires 'IO::Pipe';
requires 'YAML';

requires   'Scalar::Defer'; 
# alternatives:
recommends 'Scalar::Lazy'; 
recommends 'Data::Thunk'; 

test_requires 'Test::More';

WriteAll;
