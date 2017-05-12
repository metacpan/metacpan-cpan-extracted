package t::Object::Singleton::MissingConstructor;
use strict;
use Class::InsideOut qw( public register :singleton );

BEGIN {
    public name => my %name; 
}

my $self = register( bless \(my $s), __PACKAGE__);

# weirdly named constructor
sub get_it {
    return $self
}

1;

