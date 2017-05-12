use strict;
use warnings FATAL => "all";
use Test::More;

###########

package Person;

sub new {
    my ($class, $name) = @_;
    return bless { name => $name }, $class;
}

sub name {
    my ($self, $v) = @_;
    $self->{name} = $v if @_ > 1;
    return $self->{name};
}

package main;
use Data::Focus qw(focus);
use Data::Focus::Lens::Accessor;

my $target = Person->new("john");
my $name_lens = Data::Focus::Lens::Accessor->new(method => "name");

is focus($target)->get($name_lens), "john";
focus($target)->set($name_lens, "JOHN");

is $target->name, "JOHN";


#########

done_testing;
