#!/usr/bin/env perl
use warnings;
use strict;

# Tests for the Perl module Config::Perl
# 
# Copyright (c) 2015 Hauke Daempfling (haukex@zero-g.net).
# 
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl 5 itself.
# 
# For more information see the "Perl Artistic License",
# which should have been distributed with your copy of Perl.
# Try the command "perldoc perlartistic" or see
# http://perldoc.perl.org/perlartistic.html .

use FindBin ();
use lib $FindBin::Bin;
use Config_Perl_Testlib;

use Test::More;
use Test::Fatal 'exception';

use Config::Perl;

# A wishlist / idea collection

TODO: { todo_skip "push not yet implemented", 11*2;

test_ppconf q{ our @x=qw/a b/; push @x, "c"; }, { '@x'=>['a','b','c'] }, 'push literal';
test_ppconf q{ our @x=qw/a b/; push(@x,"c"); }, { '@x'=>['a','b','c'] }, 'push as function';
test_ppconf q{ our @x=qw/a b/; push @x, "c", "d"; }, { '@x'=>['a','b','c','d'] }, 'push 2 literals';
test_ppconf q{ our @x=qw/a b/; push @x, ("c","d","e"); }, { '@x'=>['a','b','c','d','e'] }, 'push list listerals';
test_ppconf q{ our @x=qw/a b/; push @x, qw/c d e f/; }, { '@x'=>['a','b','c','d','e','f'] }, 'push qw';
test_ppconf q{ our @x=qw/a b/; our $y='c'; push @x, $y; }, { '@x'=>['a','b','c'] }, 'push var';
test_ppconf q{ our @x=qw/a b/; our ($y,$z)=qw/c d/; push @x, $y, $z; }, { '@x'=>['a','b','c','d'] }, 'push 2 vars';
test_ppconf q{ our @x=qw/a b/; our ($y,$z)=qw/c d/; push @x, ($y, $z); }, { '@x'=>['a','b','c','d'] }, 'push list vars';
test_ppconf q{ our @x=qw/a b/; our @y=qw/c d/; push @x, @y; }, { '@x'=>['a','b','c','d'] }, 'push array';
test_ppconf q{ our @x=qw/a b/; our @y=qw/c d/; our @z=qw/e f/; push @x, @y, @z; }, { '@x'=>['a','b','c','d','e','f'] }, 'push 2 arrays';
test_ppconf q{ our @x=qw/a b/; our @y=qw/c d/; our @z=qw/e f/; push @x, (@y, @z); }, { '@x'=>['a','b','c','d','e','f'] }, 'push list arrays';

}

TODO: { todo_skip "my in blocks not yet implemented", 1*2;
	test_ppconf q{ my $foo = 123; my $bar = do { my $foo=456; $foo }; }, { '$foo'=>123, '$bar'=>456 }, '"my" in block';
}

ok exception { Config::Perl->new->parse_or_die(\q{ push @foo, "bar"; }) }, 'push unsupported';

ok exception { Config::Perl->new->parse_or_die(\q{ @foo[123] }) }, 'slice etc. unsupported 1';
ok exception { Config::Perl->new->parse_or_die(\q{ %foo[123] }) }, 'slice etc. unsupported 2';
ok exception { Config::Perl->new->parse_or_die(\q{ @foo{bar} }) }, 'slice etc. unsupported 3';
ok exception { Config::Perl->new->parse_or_die(\q{ %foo{bar} }) }, 'slice etc. unsupported 4';

#TODO Later - ideas:
# - slices?
# - pop, shift, unshift?
# - pluggable function interface (maybe with very limited prototype support?)
#   could support push and friends this way
# - . and .= concat (maybe more?)
# - $^O, %ENV, simple conditionals (?:, if eq/ne/==/!= ) ???
#   $^O, %ENV should require an option to be enabled
# - do FILE ? (should require an option to be enabled)
# - implement what assignments return in Perl
# - Support commas separating statements (as in 'our @x = qw/a b/, our @y = qw/c d/')

done_testing;

