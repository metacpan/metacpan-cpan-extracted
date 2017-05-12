#The contents of the file Bar.pm
package t::Bar;
use strict;

use Ambrosia::Meta;

class
{
    extends => [qw/t::Foo/],
    public => [qw/bar_pub1 bar_pub2/],
    protected => [qw/bar_pro1 bar_pro2 list_pro/],
    private => [qw/bar_pri1 bar_pri2 list_pri/],
};
    
sub _init
{
    my $self = shift;
    $self->SUPER::_init(foo_pri1 => 'value for bar foo_pri1');#Ignore all input parameters
    $self->bar_pub1 = 'bar_pub1';
    $self->bar_pub2 = 'bar_pub2';
    $self->bar_pri1 = 'bar_pri1';
    $self->bar_pri2 = 'bar_pri2';
    $self->bar_pro1 = 'bar_pro1';
    $self->bar_pro2 = 'bar_pro2';
    $self->list_pro = [];
    push @{$self->list_pro}, (  new t::Foo(foo_pub1=>'pro list1.1',foo_pub2=>'pro list1.2'),
                                new t::Foo(foo_pub1=>'pro list2.1',foo_pub2=>'pro list2.2')
                            );
    $self->list_pri = [];
    push @{$self->list_pri}, (  new t::Foo(foo_pub1=>'Plist1.1',foo_pub2=>'Plist1.2'),
                                new t::Foo(foo_pub1=>'Plist2.1',foo_pub2=>'Plist2.2')
                            );
}

sub Pub
{
    my $self = shift;
    $self->bar_pub1;
}

sub Pro
{
    my $self = shift;
    $self->bar_pro1;
}

sub Pri
{
    my $self = shift;
    $self->bar_pri1;
}

sub Free
{
    my $self = shift;
    1;
}

sub get_list_pri
{
    my $self = shift;
    return $self->list_pri;
}

sub get_list_pro
{
    my $self = shift;
    return $self->list_pro;
}

sub get_list_pri_ex
{
    my $self = shift;
    return $self->{list_pri};
}

sub get_list_pro_ex
{
    my $self = shift;
    return $self->{list_pro};
}

sub el_pro
{
    my $self = shift;
    my $count = shift||0;
    return $self->{list_pro}->[$count];
}

1;
