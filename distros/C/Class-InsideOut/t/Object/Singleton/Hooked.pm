package t::Object::Singleton::Hooked;
use strict;
use Class::InsideOut qw( public register id :singleton );

public name => my %name; 

use vars qw/$self/;

sub get_instance { 
    $self ||= register( bless \(my $s), shift);
    return $self;
}

sub ATTACH {
    my ($class, $cloning, $data) = @_;
    if ( $self ) {
        return $self;
    }
    else {
        my $obj = $class->get_instance();
        my $package = __PACKAGE__;
        $name{ id $obj } = $data->{properties}{$package}{name};
        return $obj;
    }
}

1;

