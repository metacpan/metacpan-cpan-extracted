#!perl -T

use 5.008;

use strict;
use warnings;

our $VERSION = '0.29';

use Data::Roundtrip qw/:all no-unicode-escape-permanently/;
use Data::Random::Structure::UTF8;

use Test::More;

use Benchmark qw/timethese cmpthese :hireswallclock/;

my $num_repeats = 50000;

print "$0 : benchmarks...\n";

srand 42;
my $randomiser = Data::Random::Structure::UTF8->new(
	'max_depth' => 5,
	'max_elements' => 20,
)  or die 'Data::Random::Structure::UTF8->new()'.": failed";
my $pv = $randomiser->generate() or die "generate(): failed";

# shamelessly ripped off App::Benchmark
cmpthese(
  timethese($num_repeats, {
	' /e/p' => \&perl2dump_escape_permanent,
	' /ne/p' => \&perl2dump_no_escape_permanent,
	'f/e/p' => \&perl2dump_filtered_escape_permanent,
	'f/ne/p' => \&perl2dump_filtered_no_escape_permanent,
	'h/e/p' => \&perl2dump_homebrew_escape_permanent,
	'h/ne/p' => \&perl2dump_homebrew_no_escape_permanent,
  }),
);
print "KEY:\n"
 ." /e/p  : perl2dump, escape, 'no-unicode-escape-permanently' set\n"
 ." /ne/p : perl2dump, no escape, 'no-unicode-escape-permanently' set\n"
 ."f/e/p  : perl2dump_filtered, escape, 'no-unicode-escape-permanently' set\n"
 ."f/ne/p : perl2dump_filtered, no escape, 'no-unicode-escape-permanently' set\n"
 ."h/e/p  : perl2dump_homebrew, escape, 'no-unicode-escape-permanently' set\n"
 ."h/ne/p : perl2dump_homebrew, no escape, 'no-unicode-escape-permanently' set\n"
;

plan tests => 1;
pass('benchmark : '.__FILE__);

sub perl2dump_escape_permanent {
	my $x = perl2dump($pv, {'dont-bloody-escape-unicode'=>0})
}
sub perl2dump_no_escape_permanent {
	my $x = perl2dump($pv, {'dont-bloody-escape-unicode'=>1})
}
sub perl2dump_homebrew_escape_permanent {
	my $x = perl2dump_homebrew($pv, {'dont-bloody-escape-unicode'=>0})
}
sub perl2dump_homebrew_no_escape_permanent {
	my $x = perl2dump_homebrew($pv, {'dont-bloody-escape-unicode'=>1})
}
sub perl2dump_filtered_escape_permanent {
	my $x = perl2dump_filtered($pv, {'dont-bloody-escape-unicode'=>0})
}
sub perl2dump_filtered_no_escape_permanent {
	my $x = perl2dump_filtered($pv, {'dont-bloody-escape-unicode'=>1})
}

1;
__END__
