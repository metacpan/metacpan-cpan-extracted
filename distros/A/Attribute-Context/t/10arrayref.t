use Test::More tests => 8;
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
is_deeply($results, \@array,
    '... and calling it in scalar context should return an arrayref');

lives_ok {foo(@array)}
    '... and calling it in void context should not throw an exception';

throws_ok {bar(@array)}
    qr/^You may not call [^(]+\(\) in void context/,
    'Calling a NOVOID sub in void context should die';

ok(bar(@array), '... but calling it in a non-void context should live');

{
    my $warning;
    local $SIG{__WARN__} = sub { $warning = shift };
    my $foo = baz(@array);
    ok(!$warning, 'Calling a WARNVOID sub normally will not generate a warning');
    baz(@array);
    like($warning, qr/^Useless use of main::baz\(\) in void context/,
        '... but it will if you call it in void context');
}

sub foo : Arrayref           { return @_ }
sub bar : Arrayref(NOVOID)   { return @_ }
sub baz : Arrayref(WARNVOID) { return @_ }
