package Data::Tersify::Plugin::Test::Subclasses;

use strict;
use warnings;

sub handles            { 'TestObject::Subclassable' }
sub handles_subclasses { return 1 }

sub tersify {
    my ($class, $object) = @_;

    if (ref($object) eq 'TestObject::Subclassable') {
        return 'Base class: ' . $object->id;
    }
    my ($subclass_part) = ref($object) =~ m{^TestObject::Subclassable:: (.+) $}x;
    $subclass_part ||= 'Something completely different';
    return $subclass_part . ': ' . $object->id;
}

1;
