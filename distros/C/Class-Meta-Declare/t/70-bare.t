#!perl

use strict;
use warnings;

use Test::More tests => 10;
#use Test::More qw/no_plan/;
use Test::Exception;

BEGIN {
    chdir 't' if -d 't';
    use lib '../lib';
    use_ok('Class::Meta::Declare');
}

my $declare;
{

    package MyApp::Thingy;
    use Class::Meta::Declare ':all';

    $declare = Class::Meta::Declare->new(
        constructors => [
            new  => {},
        ],
        attributes => [
            foo => {},
            bar => {},
        ],
        methods => [ 
            inc => { 
                code => sub { 
                    my ($self, $num) = @_;
                    return ++$num;
                } 
            }
        ]
    );
}

my $CLASS = 'MyApp::Thingy';
can_ok $CLASS=> 'new';
ok my $thing = $CLASS->new, '... and we should be able to create a new object';
isa_ok $thing, $CLASS, '... and the object it returns';

can_ok $thing, 'foo';
ok !defined $thing->foo, '... and its initial value should be undefined';
ok $thing->foo('aaa'), '... but we should be able to set it';
is $thing->foo, 'aaa', '... and get the value back';

can_ok $thing, 'inc';
is $thing->inc(3), 4, '... and it should behave correctly';
