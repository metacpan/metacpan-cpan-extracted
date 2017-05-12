use strict;
use warnings;
use App::CPAN::Dependents 'find_all_dependents';
use HTTP::Tiny;
use Test::More;
use Test::RequiresInternet 'clientinfo.metacpan.org' => 'https';

my $http = HTTP::Tiny->new;

my $invalid_module = 'asdf::asdf';
my $invalid_dist = 'asdf-asdf';

my ($deps, $err);

eval { $deps = find_all_dependents(module => $invalid_module, http => $http); 1 } or chomp($err = $@);
ok(defined $err, "Nonexistent module error: $err");

undef $err;
eval { $deps = find_all_dependents(dist => $invalid_dist, http => $http); 1 } or chomp($err = $@);
ok(defined $err, "Nonexistent distribution error: $err");

done_testing;
