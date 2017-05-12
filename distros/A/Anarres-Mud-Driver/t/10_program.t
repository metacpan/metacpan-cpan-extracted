use strict;
use Data::Dumper;
use Test::More tests => 3;

use_ok('Anarres::Mud::Driver::Program');

my $program = new Anarres::Mud::Driver::Program(
				Path	=> '/tmp/foo',
					);
ok(defined($program), 'We constructed something ...');
ok(ref($program) =~ m/::Program$/, '... which looks like a program');
