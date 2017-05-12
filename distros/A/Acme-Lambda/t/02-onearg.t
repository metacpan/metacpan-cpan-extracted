#!/usr/bin/env perl
use strict;
use warnings;

use Test::More qw(no_plan);

=head1 DESCRIPTION

Test the use of $_ to access the lambda's first argument

=cut

use Acme::Lambda;

my $square = lambda { $_ * $_ };
is($square->(4), 16);

use utf8;
my $cube = λ {$_ * $_ * $_};
is($cube->(3), 27);

# Make sure lambda doesn't clobber $_
$_ = "something";
lambda{$_}->('else');
is($_, "something");
