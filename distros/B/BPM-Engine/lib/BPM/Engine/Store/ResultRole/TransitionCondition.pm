package BPM::Engine::Store::ResultRole::TransitionCondition;
BEGIN {
    $BPM::Engine::Store::ResultRole::TransitionCondition::VERSION   = '0.01';
    $BPM::Engine::Store::ResultRole::TransitionCondition::AUTHORITY = 'cpan:SITETECH';
    }

use namespace::autoclean;
use Moose::Role;
use BPM::Engine::Types      qw/ArrayRef CodeRef Exception/;
use BPM::Engine::Exceptions qw/throw_condition throw_expression/;
use BPM::Engine::Util::ExpressionEvaluator;

has 'validators' => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => ArrayRef[CodeRef],
    default => sub { [] },
    handles => {
        add_validator    => 'push',
        clear_validators => 'clear',
        all_validators   => 'elements',
        }
    );

before apply => sub {
    my ($self, $instance, @params) = @_;
    my $state = $instance->activity;

    unless ($state->has_transition($self)) {
        die($self->transition_uid . ' is not in ' . 
            $instance->activity->activity_uid . '\'s current state');
        }

    $self->clear_validators;

    if($self->condition_type eq 'CONDITION') {
        $self->add_validator( sub {
            my ($transition, $activity_instance, @args) = @_;
            my $pi = $activity_instance->process_instance;
            #my %attr = map { $_->name => $_->value } $pi->attributes->all;
            my $activity = $activity_instance->activity;
            my $evaluator = BPM::Engine::Util::ExpressionEvaluator->load(
                process           => $pi->process,
                process_instance  => $pi,
                activity          => $activity,
                activity_instance => $activity_instance,
                transition        => $transition,
                #attributes        => \%attr,
                arguments         => [@args],
                );
            my $res = $evaluator->evaluate($transition->condition_expr);
            undef $evaluator;
            return $res;
            } );
        }
    };

around apply => sub {
    my $next = shift;
    my ($self, $instance, @args) = @_;
    
    $self->validate($instance, @args);
    
    return $self->$next($instance, @args);
    };

sub validate {
    my ($self, $instance, @args) = @_;
    
    foreach my $validator($self->all_validators) {
        my $ok = eval { $self->$validator($instance, @args) };
        my $error = $@;
        if($error) {
            is_Exception($error) ? 
                $error->rethrow() : throw_expression(error => $error);
            }
        elsif(!$ok) {
            throw_condition error => 'Condition (boolean) false';
            }
        }
    
    return 1;
    }

no Moose::Role;

1;
__END__

# ABSTRACT: Role for Transition condition evaluation