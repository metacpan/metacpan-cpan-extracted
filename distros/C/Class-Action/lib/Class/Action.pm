package Class::Action;

use warnings;
use strict;

$Class::Action::VERSION = '0.4';

sub new {
    my ( $class, $args_hr ) = @_;

    my $self = bless {
        'auto_rollback' => exists $args_hr->{'auto_rollback'} && defined $args_hr->{'auto_rollback'} ? $args_hr->{'auto_rollback'} : 1,
        'last_errstr' => undef,
        'current_step' => undef,                                                                      # N == index, undef == not started, '' == finished
        'step_stack'   => ref $args_hr->{'step_stack'} eq 'ARRAY' ? $args_hr->{'step_stack'} : [],
        'exec_stack'   => [],
        '_needs_reset' => 0,
        'global_data'  => ref $args_hr->{'global_data'} eq 'HASH' ? $args_hr->{'global_data'} : {},
        'enable_cwd' => $args_hr->{'enable_cwd'} || 0,
    }, $class;

    # for my $name qw(set_steps_from_class append_steps_from_class prepend_steps_from_class) {
    #     if ( exists $args_hr->{$name} ) {
    #         $self->$name( ref $args_hr->{$name} eq 'ARRAY' ? @{ $args_hr->{$name} } : $args_hr->{$name} );
    #     }
    # }
    if ( exists $args_hr->{'set_steps_from_class'} ) {
        $self->set_steps_from_class( ref $args_hr->{'set_steps_from_class'} eq 'ARRAY' ? @{ $args_hr->{'set_steps_from_class'} } : $args_hr->{'set_steps_from_class'} );
    }

    return $self;
}

sub set_steps {
    my ( $self, @steps ) = @_;
    @{ $self->{'step_stack'} } = @steps == 1 && ref $steps[0] eq 'ARRAY' ? @{ $steps[0] } : @steps;
    return @{ $self->{'step_stack'} };
}

sub set_steps_from_class {
    my ( $self, $class, @args ) = @_;

    if ( !ref($class) && $class =~ m/\A[a-zA-Z0-9_]+(?:\:\:[a-zA-Z0-9_]+)*\z/ ) {
        eval qq{ require $class; 1 };
    }

    if ( $class->can('get_class_action_steps') ) {
        $self->set_steps( $class->get_class_action_steps(@args) );
    }
    else {
        $self->set_steps();
        require Carp;
        Carp::carp("$class does not implement get_class_action_steps()");
        return;
    }

    return @{ $self->{'step_stack'} };
}

sub get_steps {
    my ($self) = @_;
    return @{ $self->{'step_stack'} };
}

sub append_steps {
    my ( $self, @steps ) = @_;
    push @{ $self->{'step_stack'} }, @steps == 1 && ref $steps[0] eq 'ARRAY' ? @{ $steps[0] } : @steps;
    return @{ $self->{'step_stack'} };
}

sub append_steps_from_class {
    my ( $self, $class, @args ) = @_;

    if ( !ref($class) && $class =~ m/\A[a-zA-Z0-9_]+(?:\:\:[a-zA-Z0-9_]+)*\z/ ) {
        eval qq{ require $class; 1 };
    }

    if ( $class->can('get_class_action_steps') ) {
        $self->append_steps( $class->get_class_action_steps(@args) );
    }
    else {
        require Carp;
        Carp::carp("$class does not implement get_class_action_steps()");
        return;
    }

    return @{ $self->{'step_stack'} };
}

sub prepend_steps {
    my ( $self, @steps ) = @_;
    unshift @{ $self->{'step_stack'} }, @steps == 1 && ref $steps[0] eq 'ARRAY' ? @{ $steps[0] } : @steps;
    return @{ $self->{'step_stack'} };
}

sub prepend_steps_from_class {
    my ( $self, $class, @args ) = @_;

    if ( !ref($class) && $class =~ m/\A[a-zA-Z0-9_]+(?:\:\:[a-zA-Z0-9_]+)*\z/ ) {
        eval qq{ require $class; 1 };
    }

    if ( $class->can('get_class_action_steps') ) {
        $self->prepend_steps( $class->get_class_action_steps(@args) );
    }
    else {
        require Carp;
        Carp::carp("$class does not implement get_class_action_steps()");
        return;
    }

    return @{ $self->{'step_stack'} };
}

sub clone {
    my ($self) = @_;
    my $class = ref($self);
    return if !$class;

    my %copy = %{$self};    # copy data
    my @step_list;

    # get your own fresh stack
    for my $step ( @{ $copy{'step_stack'} } ) {
        push @step_list, $step->clone_obj();
    }
    $copy{'step_stack'}  = \@step_list;
    $copy{'global_data'} = {};
    $copy{'exec_stack'}  = [];

    my $clone = bless \%copy, $class;
    return $clone->reset;    # reset the internal state so that it is fresh
}

# sub commit {
#     my ($self, @step_args) = @_;
#     local $self->{'auto_rollback'} = 1;
#     return $self->execute(@step_args);
# }

sub reset {
    my ($self) = @_;

    for my $step ( @{ $self->{'step_stack'} } ) {
        $step->reset_obj_state();
    }

    delete $self->{'starting_cwd'};
    delete $self->{'_execute'};
    delete $self->{'_rollback'};
    delete $self->{'_undo'};

    $self->{'current_step'} = undef;
    $self->{'last_errstr'}  = undef;
    $self->{'_needs_reset'} = 0;

    %{ $self->{'global_data'} } = ();
    @{ $self->{'exec_stack'} }  = ();

    return $self;
}

sub execute {
    my ( $self, @step_args ) = @_;

    $self->reset() if exists $self->{'_execute'} && !$self->{'_execute'};    # we've been successfully executed so reset and go again
    $self->reset() if $self->{'_needs_reset'}++;                             # called when in "examine results" state
    return if $self->{'_execute'} || $self->{'_rollback'};                   # execute() called after failed execute() or after failed rollback()

    $self->set_starting_cwd() if $self->{'enable_cwd'};

    $self->{'_execute'}++;
    my $execute_failed = 0;

    my $step;                                                                # more memory efficient than while my $var
  STEP:
    while ( $step = $self->next_step() ) {
        my $ref = ref($step);
        if (!$ref) {
            $step = $step->new(@step_args);
        }
        elsif ($ref eq 'ARRAY') {
            $step = $step->[0]->new( @{$step}[ 1 .. scalar(@{$step}) - 1 ], \@step_args );
        }
        
        delete $step->{'last_errstr'};

        if ( !$step->execute( $self->{'global_data'}, @step_args ) ) {
            if ( $step->retry_execute( $self->{'global_data'}, @step_args ) ) {
                $self->{'last_errstr'} = $step->{'last_errstr'} if exists $step->{'last_errstr'};

                push @{ $self->{'exec_stack'} }, { 'errstr' => $step->{'last_errstr'}, 'type' => 'execute', 'step' => ( $step->state || ref($step) ), 'ns' => ref($step), 'status' => undef };
                $step->exec_stack_runtime_handler( $self->{'exec_stack'}->[-1] );

                redo STEP;
            }
            else {
                $self->{'last_errstr'} = $step->{'last_errstr'} if exists $step->{'last_errstr'};

                push @{ $self->{'exec_stack'} }, { 'errstr' => $step->{'last_errstr'}, 'type' => 'execute', 'step' => ( $step->state || ref($step) ), 'ns' => ref($step), 'status' => 0 };
                $step->exec_stack_runtime_handler( $self->{'exec_stack'}->[-1] );

                $step->clean_failed_execute( $self->{'global_data'}, @step_args );
                $step->reset_obj_state();
                $execute_failed++;

                last STEP;
            }
        }
        else {
            $self->{'last_errstr'} = $step->{'last_errstr'} if exists $step->{'last_errstr'};

            push @{ $self->{'exec_stack'} }, { 'errstr' => $step->{'last_errstr'}, 'type' => 'execute', 'step' => ( $step->state || ref($step) ), 'ns' => ref($step), 'status' => 1 };
            $step->exec_stack_runtime_handler( $self->{'exec_stack'}->[-1] );
        }
    }

    if ($execute_failed) {
        $self->rollback(@step_args) if $self->{'auto_rollback'};
        return;
    }

    $self->{'_needs_reset'}--;
    $self->{'_execute'}--;
    return 1;
}

sub rollback {
    my ( $self, @step_args ) = @_;
    if ( !$self->{'__rollback_is_undo'} ) {
        return if !exists $self->{'_execute'} || !$self->{'_execute'};    # rollback() called before execute() or after a successful execute()
        return if exists $self->{'_rollback'} && !$self->{'_rollback'};   # rollback() called after successful rollback()
        return if $self->{'_rollback'}++;                                 # rollback() called after failed rollback()
    }

    my $rollback_failed = 0;

    my $step;                                                             # more memory efficient than while my $var
  UNDO:
    while ( $step = $self->prev_step() ) {
        my $ref = ref($step);
        if (!$ref) {
            $step = $step->new(@step_args);
        }
        elsif ($ref eq 'ARRAY') {
            $step = $step->[0]->new( @{$step}[ 1 .. scalar(@{$step}) - 1 ], \@step_args );
        }
        
        delete $step->{'last_errstr'};

        if ( !$step->undo( $self->{'global_data'}, @step_args ) ) {
            if ( $step->retry_undo( $self->{'global_data'}, @step_args ) ) {
                $self->{'last_errstr'} = $step->{'last_errstr'} if exists $step->{'last_errstr'};

                push @{ $self->{'exec_stack'} },
                  {
                    'errstr' => $step->{'last_errstr'},
                    'type'   => ( $self->{'_rollback_is_undo'} ? 'undo' : 'rollback' ),
                    'step' => ( $step->state || ref($step) ),
                    'ns' => ref($step),
                    'status' => undef
                  };
                $step->exec_stack_runtime_handler( $self->{'exec_stack'}->[-1] );

                redo UNDO;
            }
            else {
                $self->{'last_errstr'} = $step->{'last_errstr'} if exists $step->{'last_errstr'};

                push @{ $self->{'exec_stack'} }, { 'errstr' => $step->{'last_errstr'}, 'type' => ( $self->{'_rollback_is_undo'} ? 'undo' : 'rollback' ), 'step' => ( $step->state || ref($step) ), 'ns' => ref($step), 'status' => 0 };
                $step->exec_stack_runtime_handler( $self->{'exec_stack'}->[-1] );

                $step->clean_failed_undo( $self->{'global_data'}, @step_args );
                $step->reset_obj_state();
                $rollback_failed++;

                last UNDO;
            }
        }
        else {
            $self->{'last_errstr'} = $step->{'last_errstr'} if exists $step->{'last_errstr'};

            push @{ $self->{'exec_stack'} }, { 'errstr' => $step->{'last_errstr'}, 'type' => ( $self->{'_rollback_is_undo'} ? 'undo' : 'rollback' ), 'step' => ( $step->state || ref($step) ), 'ns' => ref($step), 'status' => 1 };
            $step->exec_stack_runtime_handler( $self->{'exec_stack'}->[-1] );
        }
    }

    return if $rollback_failed;
    $self->{'_rollback'}--;
    return 1;
}

sub undo {
    my ( $self, @step_args ) = @_;

    return if !exists $self->{'_execute'} || $self->{'_execute'} || !$self->is_at_end();    # succesful execute() has happened

    $self->{'__rollback_is_undo'} = 1;
    $self->{'_undo'}++;
    my $rc = $self->rollback(@step_args);
    delete $self->{'__rollback_is_undo'};
    $self->{'_undo'}-- if $rc;
    return 1 if $rc;
    return;
}

sub execute_failed {
    return 1 if $_[0]->{'_execute'};
    return;
}

sub execute_called {
    return 1 if exists $_[0]->{'_execute'};
    return;
}

sub rollback_failed {
    return 1 if $_[0]->{'_rollback'};
    return;
}

sub rollback_called {
    return 1 if exists $_[0]->{'_rollback'};
    return;
}

sub undo_failed {
    return 1 if $_[0]->{'_undo'};
    return;
}

sub undo_called {
    return 1 if exists $_[0]->{'_undo'};
    return;
}

sub get_enable_cwd { $_[0]->{'enable_cwd'} }

sub set_enable_cwd { $_[0]->{'enable_cwd'} = $_[1] }

sub get_starting_cwd {
    return if !exists $_[0]->{'starting_cwd'};
    return $_[0]->{'starting_cwd'};
}

sub set_starting_cwd {
    require Cwd;
    my $current = $_[0]->{'starting_cwd'};
    $_[0]->{'starting_cwd'} = Cwd::cwd();
    return $current if $current;
    return 1;
}

sub next_step {
    my ($self) = @_;

    my $stack_length = @{ $self->{'step_stack'} };

    if ( !$stack_length ) {
        require Carp;
        local $Carp::CarpLevel = $Carp::CarpLevel + 1;
        Carp::carp('This action has no steps.');
        return;
    }

    # why would this happen? (i.e. !used via while()) carp ?
    return if $self->is_at_end();

    if ( $self->is_at_start() ) {
        $self->{'current_step'} ||= -1;    # first time next_step() is called set current_step to 0 - 1 numeric index
    }

    $self->{'current_step'}++;
    if ( $self->{'current_step'} == ( $stack_length - 1 ) ) {
        my $current_step = $self->{'current_step'};
        $self->{'current_step'} = '';
        return $self->{'step_stack'}->[$current_step];
    }
    return $self->{'step_stack'}->[ $self->{'current_step'} ];
}

sub prev_step {
    my ($self) = @_;

    my $stack_length = @{ $self->{'step_stack'} };

    # why would this happen? (i.e. none set) carp ?
    if ( !$stack_length ) {
        require Carp;
        local $Carp::CarpLevel = $Carp::CarpLevel + 1;
        Carp::carp('This action has no steps.');
        return;
    }

    # why would this happen? (i.e. !used via while()) carp ?
    return if $self->is_at_start();

    if ( $self->is_at_end() ) {
        $self->{'current_step'} = ( $stack_length - 1 );    # first time prev-step() is called set current_step to $stack_length numeric index
    }

    my $current_step = $self->{'current_step'};
    $self->{'current_step'}--;

    if ( $self->{'current_step'} < 0 ) {

        $self->{'current_step'} = undef;
        return $self->{'step_stack'}->[$current_step];
    }

    return $self->{'step_stack'}->[$current_step];
}

sub is_at_start {
    return 1 if !defined $_[0]->{'current_step'};
    return;
}

sub is_at_end {
    return 1 if defined $_[0]->{'current_step'} && $_[0]->{'current_step'} eq '';
    return;
}

sub get_current_step { $_[0]->{'current_step'} }

sub get_errstr { $_[0]->{'last_errstr'} }

sub set_errstr { $_[0]->{'last_errstr'} = $_[1] }

sub get_auto_rollback { $_[0]->{'auto_rollback'} }

sub set_auto_rollback { $_[0]->{'auto_rollback'} = $_[1] }

sub get_execution_state { return [ @{ $_[0]->{'exec_stack'} } ] }

1;
