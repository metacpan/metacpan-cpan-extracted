requires 'perl', '5.008001';
requires 'strict';
requires 'warnings';
requires 'Carp';
requires 'POSIX';
requires 'AnyEvent', '6.01';
requires 'YAML::Tiny';

recommends 'EV';
recommends 'Guard';
recommends 'Async::Interrupt';

on configure => sub {
	requires 'Module::Build';
};

on build => sub {
	requires 'Test::Deep';
	requires 'Test::Fatal';
	requires 'Test::More', '0.98';
};
