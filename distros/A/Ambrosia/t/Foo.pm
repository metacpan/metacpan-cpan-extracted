#The contents of the file Bar.pm
package t::Foo;
use strict;
use warnings;

use Ambrosia::Meta;

class
{
    public => [qw/foo_pub1 foo_pub2/],
    protected => [qw/foo_pro1 foo_pro2/],
    private => [qw/foo_pri1 foo_pri2/],
};

sub _init
{
    my $self = shift;
    $self->SUPER::_init(@_);

    $self->foo_pub1 ||= 'foo_pub1';
    $self->foo_pub2 ||= 'foo_pub2';
    $self->foo_pro1 ||= 'foo_pro1';
    $self->foo_pro2 ||= 'foo_pro2';
    $self->foo_pri1 ||= 'foo_pri1';
    $self->foo_pri2 ||= 'foo_pri2';
}

my $sum = 0;
sub count() { ++$sum; }

sub twice_pro
{
    my $self = shift;
    my $delim = shift || ';';
    return $self->foo_pro1 . $delim . $self->foo_pro2;
}

sub getPro #: Public(1,2,3)
{
    shift->foo_pro1
}

sub method
{
    my $self = shift;
    return 'method: ' . join ':', $self->foo_pub1,$self->foo_pro1,$self->foo_pri1,$self->foo_pub2,$self->foo_pro2,$self->foo_pri2;
}

1;
