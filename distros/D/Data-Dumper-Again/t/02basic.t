#perl -T 

use Test::More 'no_plan';

BEGIN { use_ok('Data::Dumper::Again'); }

{
my $dumper = Data::Dumper::Again->new;
isa_ok($dumper, 'Data::Dumper::Again');

my $s = $dumper->dump(1);
is ($s, "\$VAR = 1;\n", q{dump(1) returns "\$VAR = 1;\n"});

my $s2 = $dumper->dump(1, 2);
my $expected2 = <<'DUMP';
@VAR = (
         1,
         2
       );
DUMP
is ($s2, $expected2, q{dump(1, 2) returns "\@VAR = (1, 2)\n"});

my $s3 = $dumper->dump(); # the empty list edge case
is ($s3, "\@VAR = ();\n", q{dump(1, 2) returns "\@VAR = ()\n"});

# don't remember seen data structures between dump invocations, 
# at least by default
my $var = [ qw(a b) ];

is($dumper->dump($var), <<'DUMP', 'dumping an array ref');
$VAR = [
         'a',
         'b'
       ];
DUMP
my $var2 = [ $var, qw(c) ];
is($dumper->dump($var2), <<'DUMP', 'dumping an array ref, containing the former');
$VAR = [
         [
           'a',
           'b'
         ],
         'c'
       ];
DUMP

}

