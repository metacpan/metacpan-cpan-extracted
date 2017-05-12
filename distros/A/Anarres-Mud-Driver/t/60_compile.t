#!/usr/bin/perl

use strict;
use warnings;
use Devel::Peek;
use Data::Dumper;

my ($source, $local);
BEGIN { $source = 'local/test.C'; $local = -r $source; }

use Test::More tests => ($local ? 9 : 4);

select STDERR;
$|++;
select STDOUT;
$|++;

$Data::Dumper::Indent = 1;

use_ok('Anarres::Mud::Driver::Program');
use_ok('Anarres::Mud::Driver::Compiler');
use_ok('Anarres::Mud::Driver::Efun::Core');

my $compiler = new Anarres::Mud::Driver::Compiler;
ok(defined($compiler), 'We constructed a compiler');

exit unless $local;

my $program = $compiler->compile($source);
ok(defined($program), 'Got a return value from compile() ...');
ok(ref($program) =~ m/::Program$/, '... which looks like a program');

# print $program->dump;

ok($program->dump, 'Program appears to dump');

my $ch;
eval {
	$ch = $program->check;
	ok($ch, 'Typechecked program');
};
die "TYPECHECK ERROR: $@" if $@;
# print $program->dump, "\n";

ok($program->dump, 'Program still appears to dump');

# print Dumper($program);

print $program->dump, "\n";
