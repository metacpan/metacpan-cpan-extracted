use strict;
use Test::More tests => 6;

BEGIN { use_ok('Attribute::Profiled') }

package Catch;
sub TIEHANDLE {
    my $class = shift;
    bless { caught => '' }, $class;
}

sub PRINTF {
    my($self, $fmt, @list) = @_;
    $self->{caught} .= sprintf $fmt, @list;
}

sub PRINT {
    my($self, @list) = @_;
    $self->{caught} .= "@list";
}


package SomeClass;

sub new {
    bless {}, shift;
}

sub method : Profiled {
    my $self = shift;
    return 'foo';
}

sub method2 : Profiled {
    my $self = shift;
    return (1, 2, 3);
}

sub method3 : Profiled {
    my $self = shift;
    return scalar caller;
}

package main;

my $catch = tie *STDERR, 'Catch';

my $foo = SomeClass->new;
is $foo->method, 'foo', 'retvalue preserved';

$foo->method for (1..10);

my @ret = $foo->method2;
ok eq_array(\@ret, [ 1, 2, 3 ]), 'wantarray check';

my $caller = $foo->method3;
is $caller, __PACKAGE__, 'caller preserved';


undef $Attribute::Profiled::_Profiler;

like $catch->{caught}, qr/11 trials of SomeClass::method/, '11 method';
like $catch->{caught}, qr/1 trial of SomeClass::method2/, '1 method2';



