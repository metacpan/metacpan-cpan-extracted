#test that the module is loaded properly
use strict;
use warnings;
use Test::More 0.88;
plan tests => 1;
my $package = 'Convert::TBX::RNG';
my @imports = qw(generate_rng core_structure_rng);

# require $package;
# new_ok($package);
use_ok($package, @imports);

__END__