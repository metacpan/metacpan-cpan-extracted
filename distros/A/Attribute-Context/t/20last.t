use Test::More tests => 7;
use Test::Exception;
use strict;
use warnings;

our @ISA;

my $CLASS;
BEGIN {
    chdir 't' if -d 't';
    use lib '../lib';
    $CLASS = 'Attribute::Context';
    use_ok($CLASS) or die;
    @ISA = $CLASS;
}

my @array = qw/ this that the other thing/;

my @results = foo(@array);
is_deeply(\@results, \@array, 
    'Calling foo in list context should return it\'s args');

my $results = foo(@array);
is($results, $array[-1],
    '... and calling it in scalar context should return the last element');

lives_ok {foo(@array)}
    '... and calling it in void context should not throw an exception';

ok(!foo(), 'A scalar call to a Last sub which returns an empty list should return undef');

throws_ok {bar(@array)}
    qr/^You may not call [^(]+\(\) in void context/,
    'Calling a NOVOID sub in void context should die';

ok(bar(@array), '... but calling it in a non-void context should live');

sub foo : Last         { return @_ }
sub bar : Last(NOVOID) { return @_ }
