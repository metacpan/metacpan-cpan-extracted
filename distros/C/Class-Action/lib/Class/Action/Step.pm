package Class::Action::Step;

use warnings;
use strict;

$Class::Action::Step::VERSION = '0.4';

# get a collection of step objects:

sub get_class_action_steps {
    my ( $class, @args ) = @_;
    return $class->_not_imp('get_class_action_steps');
}

# basic functionality convienience shortcut:

# turn X=>sub {}, Y=>sub {} into CALLER::NS::X::execute() && CALLER::NS::Y::execute()
# return list sutiable for get_class_action_steps() return value

sub setup_class_execute_and_get_class_action_steps {
    my $class = shift;
    $class = ref($class) if ref($class);

    no strict 'refs';

    my @nss;

    # no warnings 'redefine'; # we want to warn since it doesn't make
    # much sense to pass an NS that already has execute() to this method

    my $ar;    # re-use buffer, cheaper on memory
    for $ar (@_) {
        if ( $ar->[0] !~ m/\A[A-Za-z_][A-Za-z_0-9]*\z/ ) {
            require Carp;
            Carp::carp('Invalid string for use in a namespace');
            @nss = ();
            last;
        }
        if ( ref( $ar->[1] ) ne 'CODE' ) {
            require Carp;
            Carp::carp('Not a CODE reference');
            @nss = ();
            last;
        }

        push @{ $class . "::$ar->[0]" . '::ISA' }, $class;
        *{ $class . "::$ar->[0]" . '::execute' } = $ar->[1];

        if ( ref($ar->[2]) eq 'CODE' ) {
            *{ $class . "::$ar->[0]" . '::undo' } = $ar->[2];
        }
        
        push @nss, $class . "::$ar->[0]";
    }

    return @nss;
}

# basic functionality convienience shortcut:

sub get_action_object {
    require Class::Action;
    my $action = Class::Action->new();
    $action->set_steps_from_class(@_);
    return $action;
}

#### mandatory step object methods ##

sub new {
    my ($step_obj) = @_;
    return $step_obj->_not_imp('new');

    # my ($step_obj, @args_to_execute) = @_;
}

sub clone_obj {
    my ($step_obj) = @_;
    return $step_obj->_not_imp('clone_obj');

    # return a cloned $step_obj
}

sub state {
    my ($step_obj) = @_;
    return $step_obj->_not_imp('state');

    # return string/data struct representing any important messages and status that you might want to examine after reset_obj_state() has wiped the object clean
}

sub reset_obj_state {
    my ($step_obj) = @_;
    return $step_obj->_not_imp('reset_obj_state');

    # my ($step_obj) = @_;
    # resets the intrnal state of the obj
    # void context
}

sub execute {
    my ($step_obj) = @_;
    $step_obj->_not_imp('execute');
    return 1;

    # my ($step_obj, $global_data_hr, @args_to_execute) = @_;
    # return 1 if what it does worked
    # return;
}

#### optional step object methods ##

sub retry_execute {
    return;

    # my ($step_obj, $global_data_hr, @args_to_execute) = @_;
    # Address $step_obj->execute() failure as needed
    # return 1 if $retry; # i.e. we should try $step_obj->execute() again
    # return;
}

sub clean_failed_execute {
    return;

    # my ($step_obj, $global_data_hr, @args_to_execute) = @_;
    # final $step_obj->execute() cleanup since the $step_obj->execute() failed and we are not retrying
    # void context
}

# same idea as the execute equivalents (sans that undo() is optional)

sub undo {
    return 1;

    # my ($step_obj, $global_data_hr, @args_to_execute) = @_;
    # return 1 if what it does worked
    # return;
}

sub retry_undo {
    return;

    # my ($step_obj, $global_data_hr, @args_to_execute) = @_;
    # Address $step_obj->undo() failure as needed
    # return 1 if $retry; # i.e. we should try $step_obj->undo() again
    # return;
}

sub clean_failed_undo {
    return;

    # my ($step_obj, $global_data_hr, @args_to_execute) = @_;
    # final $step_obj->undo() cleanup since the $step_obj->undo() failed and we are not retrying
    # void context
}

sub exec_stack_runtime_handler {
    return;

    # my ($step_obj, $current_exec_stack_entry_hr) = @_;
    # void context
}

#### Internal ##

sub _not_imp {
    my ( $step_obj, $method ) = @_;
    require Carp;
    local $Carp::CarpLevel = $Carp::CarpLevel + 1;
    Carp::carp( ( ref($step_obj) || $step_obj ) . " does not implement $method()" );
    return;
}

1;
