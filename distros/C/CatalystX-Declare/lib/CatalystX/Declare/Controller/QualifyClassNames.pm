use MooseX::Declare;

use Class::MOP;
use Class::Inspector;

role CatalystX::Declare::Controller::QualifyClassNames {

    use Carp qw( croak );

    method _qualify_class_name (Str $type, Str $name) {

        my $app = ref($self->_application) || $self->_application;

        my @possibilities = (
            join('::', $app, $type, $name),
            join('::', 'Catalyst', $type, $name),
            $name,
        );

        for my $class (@possibilities) {

            return $class 
                if Class::MOP::is_class_loaded($class);

            return $class
                if Class::Inspector->installed($class);
        }

        croak sprintf q(Unable to locate %s %s named '%s', tried: %s),
            ($type =~ /^[aeiuo]/i ? 'an' : 'a'),
            $type,
            $name,
            join(', ', @possibilities),
            ;
    }
}

1;
