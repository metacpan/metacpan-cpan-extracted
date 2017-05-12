use strict;
use warnings FATAL => "all";
use Test::More;
use Data::Focus qw(focus);

note("--- synopsis");

{
    package Person;
    
    sub new {
        my ($class, $first_name, $last_name) = @_;
        return bless {
            first_name => $first_name,
            last_name => $last_name,
        }, $class;
    }
    
    sub first_name {
        my $self = shift;
        $self->{first_name} = $_[0] if @_;
        return $self->{first_name};
    }
    
    package Person::Lens::FirstName;
    use parent qw(Data::Focus::Lens);
    use Data::Focus::LensMaker qw(make_lens_from_accessors);
    
    sub new {
        my ($class) = @_;
        my $self;
        return bless \$self, $class;
    }
    
    sub _getter {
        my ($self, $target) = @_;
        return $target->first_name;
    }
    
    sub _setter {
        my ($self, $target, $set) = @_;
        $target->first_name($set);
        return $target;
    }
    
    make_lens_from_accessors(\&_getter, \&_setter);
}

my $person = Person->new("toshio");
my $lens = Person::Lens::FirstName->new;

is focus($person)->get($lens), "toshio", "get() ok";
is focus($person)->set($lens, "TOSHIO")->first_name, "TOSHIO", "set() ok";

done_testing;
