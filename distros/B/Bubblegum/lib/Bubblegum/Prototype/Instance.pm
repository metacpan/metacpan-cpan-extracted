# Bubblegum Prototype Instance Base Class
package Bubblegum::Prototype::Instance;

use namespace::autoclean;

use Bubblegum::Class;
use Bubblegum::Prototype::Package;

use Moo ();
use Moo::Role ();

use Class::Load 'is_class_loaded';

*proto = *prototype = sub {
    return Bubblegum::Prototype::Package->new(
        name => ref shift
    )
};

my $c = 0;
my $m = 0;
sub DEMOLISH {
    my $self  = shift;
    my $class = ref $self;

    is_class_loaded 'Class::MOP' and $c++ if !$c;
    Class::MOP::remove_metaclass_by_name($class) if $c;
    is_class_loaded 'Moo' and $m++ if !$m;
    delete $Moo::MAKERS{$class} if $m;

    unless ($class eq __PACKAGE__) {
        no strict 'refs';
        my $table = "${class}::";
        my %symbols = %$table;
        for my $symbol (keys %symbols) {
            next if $symbol =~ /\A[^:]+::\z/;
            delete $symbols{$symbol};
        }
        my $file = join('/', split('::', $class)) . 'pm';
        delete $INC{$file};
    }

    return 1;
}

1;
