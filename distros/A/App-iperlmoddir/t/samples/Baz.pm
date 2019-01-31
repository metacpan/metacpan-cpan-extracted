package Baz;

# Sample module with some constants

use lib '.';
use parent 'Foo';

use constant SEC           => 0;
use constant lowercase     => 1;
use constant MINIMAL_MATCH => 0.5;

sub new {
    my $class = shift;
    my $self  = {@_};
    return bless $self, $class;
}

sub some_attr {
    'val';
}

sub print_info {
    print 'Some info';
}

sub LOOKS_LIKE_CONSTANT {
    1;
}

1;
