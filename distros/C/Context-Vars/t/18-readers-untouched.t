#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Context::Vars qw($rd);

# A sub that only reads a variable is left as perl built it, and calling it
# opens no scope. Counted, not timed.

$rd = 'value';
sub reader      { $rd }
sub interp      { "<$rd>" }
sub copier      { my $y = $rd; $y }
sub passer      { length_of($rd) }
sub length_of   { length $_[0] }
sub tester      { $rd eq 'value' ? 1 : 0 }
sub defined_or  { $rd // 'none' }
sub in_list     { my @x = ($rd, $rd); scalar @x }
sub as_key      { my %h = ($rd => 1); join ',', keys %h }
sub unrelated   { my $x = 1; our $g = 2; $x + $g }
sub plain_pkg   { our $other_pkg_var = 1; $other_pkg_var }

for my $c ([reader => \&reader], [interp => \&interp], [copier => \&copier], [passer => \&passer],
           [tester => \&tester], [defined_or => \&defined_or], [in_list => \&in_list], [as_key => \&as_key],
           [unrelated => \&unrelated], [plain_pkg => \&plain_pkg]) {
    my ($name, $code) = @$c;
    is(Context::Vars::_scope_kind($code), 0, "$name has no scope");
    my $before = Context::Vars::_scopes();
    $code->() for 1 .. 3;
    is(Context::Vars::_scopes() - $before, 0, "$name: three calls opened no scope");
}

sub writer { $rd = 'w' }
my $before = Context::Vars::_scopes();
writer() for 1 .. 3;
is(Context::Vars::_scopes() - $before, 3, 'a writer, by contrast, opens one scope a call');

done_testing;
