use strict;
use warnings;
use Test::More;

my $inst = Inst->new('foo');
my $str = 'foo';
is $str, $inst;

done_testing;

package Inst;

use overload (
    q[""]    => \&stringify,
    fallback => 1,
);

sub new {
    my ($class, $content) = @_;

    bless +{
        content => $content,
    };
}

sub stringify {
    my ($self) = @_;
    return $self->{content};
}
