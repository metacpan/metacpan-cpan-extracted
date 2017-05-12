use MooseX::Declare;
use Class::MOP;
use Moose::Meta::Class;

role CatalystX::Declare::Controller::DetermineActionClass
    with CatalystX::Declare::Controller::QualifyClassNames {

    around create_action (%args) {
        my ($action_class) = @{ $args{attributes}{CatalystX_Declarative_ActionClass} || [] };
        $action_class ||= 'Catalyst::Action';

        my $fq_class = $self->_qualify_class_name('Action', $action_class);
        Class::MOP::load_class($fq_class);
        Moose::Meta::Class->initialize($fq_class);

        $args{attributes}{ActionClass} ||= [$fq_class];
        return $self->$orig(%args);
    }
}

1;
