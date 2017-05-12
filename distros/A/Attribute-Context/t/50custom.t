use Test::More tests => 14;
use Test::Exception;
use strict;
use warnings;

package Dummy::Class;

package Good::Class;

sub new { bless { data => $_[1] }, $_[0] }
sub pop { pop @{$_[0]->{data}} }

package main;
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

eval "sub foo : Custom";
like($@, qr/No class specified for main::ANON Custom attribute/,
    'Custom sub attributes must have a class');

eval "sub foo : Custom(No::Such::Class)";
like($@, qr{Can't locate No/Such/Class.pm in \@INC}, '... and the class must exist');

eval "sub foo : Custom(Dummy::Class) { return @_ }";
like ($@, qr/Cannot find constructor 'new' for Dummy::Class/, 
    '... and have a "new" constructor');

my @stuff = bar(@array);
is_deeply(\@stuff, \@array, 'Calling a Custom sub in array context should succeed');
my $object = bar(@array);
ok($object, 'Calling a Custom sub in scalar context should also succeed');
isa_ok($object, 'Good::Class' => '... and it object it returns');
my $thing = $object->pop;
is($thing, 'thing', '... and it should function correctly');

{
    my $warning;
    local $SIG{__WARN__} = sub { $warning = shift };
    my $foo = baz(@array);
    ok(!$warning, 'Calling a WARNVOID sub normally will not generate a warning');
    isa_ok($foo, 'Good::Class', '... and the object it returns');
    baz(@array);
    like($warning, qr/^Useless use of main::baz\(\) in void context/,
        '... but it will if you call it in void context');
}

my $foo = quux(@array);
ok($foo, 'Calling a NOVOID sub normally will not be fatal');
isa_ok($foo, 'Good::Class', '... and the object it returns');

throws_ok {quux(@array)}
    qr/^You may not call main::quux\(\) in void context/,
    '... but it will be fatal if you call it in void context';

sub bar  : Custom(Good::Class)  { return @_ }
sub baz  : Custom(class => 'Good::Class', WARNVOID => 1) { return @_ }
sub quux : Custom(class => 'Good::Class', NOVOID => 1) { return @_ }
