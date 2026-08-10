# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.6.2';

requires 'Carp';
requires 'Class::Simple';
requires 'Data::Reuse';   # Fails installation tests on recent Perls, RT#100461
requires 'List::Util', '1.33';   # none() added in 1.33
requires 'Params::Get', '0.15';
requires 'Readonly';
requires 'Scalar::Util';
requires 'Sub::Private', '0.05';

on 'configure' => sub {
	requires 'ExtUtils::MakeMaker', '6.64';   # Minimum version for TEST_REQUIRES
};

on 'test' => sub {
	requires 'CHI';
	requires 'Test::Carp';
	requires 'Test::DescribeMe';
	requires 'Test::Memory::Cycle';
	requires 'Test::Mockingbird';
	requires 'Test::Most';
	requires 'Test::Needs';
	requires 'Test::NoWarnings';
	requires 'Test::Returns';
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};
