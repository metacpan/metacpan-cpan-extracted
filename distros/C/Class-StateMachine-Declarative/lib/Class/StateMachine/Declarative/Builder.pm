package Class::StateMachine::Declarative::Builder;

use strict;
use warnings;
use Carp;
use 5.010;
use Scalar::Util ();

use Class::StateMachine;
*debug = \$Class::StateMachine::debug;
*_debug = \&Class::StateMachine::Private::_debug;
our $debug;

sub new {
    my ($class, $target_class) = @_;
    my $top = Class::StateMachine::Declarative::Builder::State->_new;
    my $self = { top => $top,
                 states => { '/' => $top },
                 class => $target_class };
    bless $self, $class;
    $self;
}

sub _bad_def {
    my ($self, $state, @msg) = @_;
    croak "@msg on definition of state '$state->{name}' for class '$self->{class}'";
}

sub _is_hash  { UNIVERSAL::isa($_[0], 'HASH') }
sub _is_array { UNIVERSAL::isa($_[0], 'ARRAY') }

sub _ensure_list {
    my $ref = shift;
    ( UNIVERSAL::isa($ref, 'ARRAY') ? @$ref : $ref );
}

sub parse_state_declarations {
    my $self = shift;
    $self->_parse_state_declarations($self->{top}, @_);
    $self->_merge_any;
    $self->_resolve_advances($self->{top});
    $self->_resolve_transitions($self->{top}, []);
    # $self->_propagate_transitions($self->{top});
}

sub _parse_state_declarations {
    my $self = shift;
    my $parent = shift;
    while (@_) {
        my $name = shift // $self->_bad_def($parent, "undef is not valid as a state name");
        my $decl = shift;
        _is_hash($decl) or $self->_bad_def($parent, "HASH expected for substate '$name' declaration");
        $self->_add_state($name, $parent, %$decl);
    }
}

sub _add_state {
    my ($self, $name, $parent, @decl) = @_;
    my $secondary;
    if ($name =~ /^\((.*)\)$/) {
        $name = $1;
        $secondary = 1;
    }
    my $state = Class::StateMachine::Declarative::Builder::State->_new($name, $parent);
    $self->_handle_attr_secondary($state, 1) if $secondary;
    while (@decl) {
        my $k = shift @decl;
        my $method = $self->can("_handle_attr_$k") or $self->_bad_def($state, "bad declaration '$k'");
        if (defined (my $v = shift @decl)) {
            $debug and $debug & 16 and _debug($self, "calling handler for attribute $k with value $v");
            $method->($self, $state, $v);
        }
    }
    $self->{states}{$state->{full_name}} = $state;
    $state;
}

sub _ensure_event_is_free {
    my ($self, $state, $event, $current) = @_;
    my $seen;
    for (qw(transitions on)) {
        $seen = $_ if defined $state->{$_}{$event};
    }
    for (qw(delay ignore)) {
        $seen = $_ if grep $_ eq $event, @{$state->{$_}};
    }
    if ($seen) {
        unless (defined $current) {
            $current = (caller 1)[3];
            $current =~ s/^_handle_attr_//;
        }
        $seen and $self->_bad_def($state, "event '$event' appears on '$seen' and '$current' declarations");
    }
}

sub _handle_attr_enter {
    my ($self, $state, $v) = @_;
    $state->{enter} = $v;
}

sub _handle_attr_leave {
    my ($self, $state, $v) = @_;
    $state->{leave} = $v;
}

sub _handle_attr_jump {
    my ($self, $state, $v) = @_;
    $state->{jump} = $v;
}

sub _handle_attr_advance {
    my ($self, $state, $v) = @_;
    $state->{advance} = $v;
}

sub _handle_attr_delay {
    my ($self, $state, $v) = @_;
    my @events = _ensure_list($v);
    $self->_ensure_event_is_free($state, $_) for @events;
    push @{$state->{delay}}, @events;
}

sub _handle_attr_ignore {
    my ($self, $state, $v) = @_;
    my @events = _ensure_list($v);
    $self->_ensure_event_is_free($state, $_) for @events;
    push @{$state->{ignore}}, @events;
}

sub _handle_attr_secondary {
    my ($self, $state, $v) = @_;
    $state->{secondary} = !!$v;
}

sub _handle_attr_before {
    my ($self, $state, $v) = @_;
    _is_hash($v) or $self->_bad_def($state, "HASH expected for 'before' declaration");
    while (my ($event, $action) = each %$v) {
        $state->{before}{$event} = $action if defined $action;
    }
}

sub _handle_attr_on {
    my ($self, $state, $v) = @_;
    _is_hash($v) or $self->_bad_def($state, "HASH expected for 'on' declaration");
    while (my ($event, $action) = each %$v) {
        if (defined $action) {
            $self->_ensure_event_is_free($state, $event);
            $state->{on}{$event} = $action;
        }
    }
}

sub _handle_attr_transitions {
    my ($self, $state, $v) = @_;
    _is_hash($v) or $self->_bad_def($state, "HASH expected for 'transitions' declaration");
    while (my ($event, $target) = each %$v) {
        if (defined $target) {
            $self->_ensure_event_is_free($state, $event);
            $state->{transitions}{$event} = $target;
        }
    }
}

sub _handle_attr_substates {
    my ($self, $state, $v) = @_;
    $state->{full_name} eq '/__any__' and $self->_bad_def($state, "pseudo state __any__ can not contain substates");
    _is_array($v) or $self->_bad_def($state, "ARRAY expected for substate declarations");
    $self->_parse_state_declarations($state, @$v);
}

sub _merge_any {
    my $self = shift;
    my $top = $self->{top};
    $top->{name} = '__any__';
    if (defined(my $any = delete $self->{states}{'/__any__'})) {
        my $ss = $self->{top}{substates};
        @$ss = grep { $_->{name} ne '__any__' } @$ss;
        delete $top->{$_} for qw(before transitions on);
        $top->{$_} //= $any->{$_} for keys %$any;
        $top->{$_} = $any->{$_} for qw(ignore delay);
    }
}

sub _resolve_advances {
    my ($self, $state, $event) = @_;
    my @ss = @{$state->{substates}};
    if (@ss) {
        $event = $state->{advance} // $event;
        $self->_resolve_advances($_, $event) for @ss;
        if (defined $event) {
            while (@ss) {
                my $current_state = shift @ss;
                if (my ($next_state) = grep { not $_->{secondary} } @ss) {
                    $current_state->{transitions}{$event} //= $next_state->{full_name};
                }
            }
        }
    }
}

sub _resolve_transitions {
    my ($self, $state, $path) = @_;
    my @path = (@$path, $state->{short_name});
    my %transitions_abs;
    my %transitions_rev;
    while (my ($event, $target) = each %{$state->{transitions}}) {
        my $target_abs = $self->_resolve_target($target, \@path);
        $transitions_abs{$event} = $target_abs;
        push @{$transitions_rev{$target_abs} ||= []}, $event;
    }
    $state->{transitions_abs} = \%transitions_abs;
    $state->{transitions_rev} = \%transitions_rev;

    my $jump = $state->{jump};
    my $ss = $state->{substates};
    if (not defined $jump and not defined $state->{enter} and @$ss) {
        if (my ($main) = grep { not $_->{secondary} } @$ss) {
            $jump //= $main->{full_name};
        }
        else {
            $self->_bad_def($state, "all the substates are secondary");
        }
    }

    $state->{jump_abs} = $self->_resolve_target($jump, \@path) if defined $jump;

    $self->_resolve_transitions($_, \@path) for @$ss;
}

# sub _propagate_transitions {
#     my ($self, $state) = @_;
#     my $t = $state->{transitions_abs};
#     for my $ss (@{$state->{substates}}) {
#         my $ss_t = $ss->{transitions_abs};
#         $ss_t->{$_} //= $t->{$_} for keys %$t;
#         $self->_propagate_transitions($ss);
#     }
# }

sub _resolve_target {
    my ($self, $target, $path) = @_;
    # $debug and $debug & 32 and _debug($self, "resolving target '$target' from '".join('/',@$path)."'");
    if ($target =~ m|^__(\w+)__$|) {
        return $target;
    }
    if ($target =~ m|^/|) {
        return $target if $self->{states}{$target};
        $debug and $debug & 32 and _debug($self, "absolute target '$target' not found");
    }
    else {
        my @path = @$path;
        while (@path) {
            my $target_abs = join('/', @path, $target);
            if ($self->{states}{$target_abs}) {
                $debug and $debug & 32 and _debug($self, "target '$target' from '".join('/',@$path)."' resolved as '$target_abs'");
                return $target_abs;
            }
            pop @path;
        }
    }

    my $name = join('/', @$path);
    $name =~ s|^/+||;
    croak "unable to resolve transition target '$target' from state '$name'";
}

sub generate_class {
    my $self = shift;
    $self->_generate_state($self->{top});
}

sub _generate_state {
    my ($self, $state) = @_;
    my $class = $self->{class};
    my $name = $state->{name};
    my $parent = $state->{parent};
    my $parent_name = ($parent ? $parent->{name} : undef);
    $debug and $debug & 16 and _debug("generating subs for class $class, state $name, parent: ". ($parent_name // '<undef>'));

    if ($parent and $parent_name ne '__any__') {
        Class::StateMachine::set_state_isa($class, $name, $parent_name);
    }

    for my $when ('enter', 'leave') {
        if (defined (my $action = $state->{$when})) {
            Class::StateMachine::install_method($class,
                                                "${when}_state",
                                                sub { shift->$action },
                                                $name);
        }
    }

    if (!defined $state->{enter} and $name ne '__any__') {
        if (defined (my $jump = $state->{jump_abs})) {
            my $name = $state->{name};
            my $jump_name = $self->{states}{$jump}{name};
            $debug and $debug & 32 and _debug(__PACKAGE__, "installing handler for jump(=> $jump_name) at $class/$name");
            Class::StateMachine::install_method($class,
                                                'enter_state',
                                                sub {
                                                    my $self = shift;
                                                    if ($self->state eq $name) {
                                                        $debug and $debug & 64 and _debug($self, "jumping to state $jump_name");
                                                        $self->state($jump_name)
                                                    }
                                                    else {
                                                        $debug and $debug & 64 and
                                                            _debug(64, "skipping jump to state $jump_name set for state $name");
                                                    }
                                                },
                                                $name);
        }
    }

    for my $event (keys %{$state->{before}}) {
        my $action = $state->{before}{$event};
        my $event1 = $event;
        my $sub = sub {
            my $self = shift;
            if (my $method = $self->next::can) {
                $self->state_changed_on_call($method, $self) and return;
            }
            $self->$action;
        };
        $debug and $debug & 32 and _debug(__PACKAGE__, "installing handler for before($event1 => $action) at $class/$name");
        Class::StateMachine::install_method($class,
                                            "$event/before",
                                            $sub,
                                            $name);
    }

    for my $event (@{$state->{delay}}) {
        my $event1 = $event;
        $debug and $debug & 32 and _debug(__PACKAGE__, "installing handler for delay($event1) at $class/$name");
        Class::StateMachine::install_method($class,
                                            $event,
                                            sub {
                                                my $self = shift;
                                                $debug and $debug & 64 and _debug($self, "event $event1 received (delay)");
                                                $self->delay_until_next_state($event1) },
                                            $name);
    }

    for my $event (keys %{$state->{on}}) {
        my $action = $state->{on}{$event};
        my $before = "$event/before";
        my $event1 = $event;
        my $sub = sub {
            my $self = shift;
            $debug and $debug & 64 and _debug($self, "event $event1 received (on target: $action)");
            if (my $method = $self->can($before)) {
                $self->state_changed_on_call($method, $self, @_) and return;
            }
            $self->$action(@_);
        };
        $debug and $debug & 32 and _debug(__PACKAGE__, "installing handler for on($event1 => $action) at $class/$name");
        Class::StateMachine::install_method($class, $event, $sub, $name);
    }

    for my $event (@{$state->{ignore}}) {
        my $before = "$event/before";
        my $event1 = $event;
        my $sub = sub {
            my $self = shift;
            $debug and $debug & 64 and _debug($self, "event $event1 received (ignore)");
            my $method = $self->can($before);
            $self->$method(@_) if $method;
        };
        Class::StateMachine::install_method($class, $event, $sub, $name);
    }

    while (my ($target, $events) = each %{$state->{transitions_rev}}) {
        my $target = $self->{states}{$target}{name};
        for my $event (@$events) {
            my $before = "$event/before";
            my $event1 = $event;
            my $sub = sub {
                my $self = shift;
                $debug and $debug & 64 and _debug($self, "event $event1 received (transition target: $target)");
                if (my $method = $self->can($before)) {
                    $self->state_changed_on_call($method, $self, @_) and return;
                }
                $self->state($target);
            };
            $debug and $debug & 32 and _debug(__PACKAGE__, "installing handler for transition($event1 => $target) at $class/$name");
            Class::StateMachine::install_method($class, $event, $sub, $name);
        }
    }

    $self->_generate_state($_) for @{$state->{substates}};
}

package Class::StateMachine::Declarative::Builder::State;

sub _new {
    my ($class, $name, $parent) = @_;
    $name //= '';
    my $full_name = ($parent ? "$parent->{full_name}/$name" : $name);
    my $final_name = $full_name;
    $final_name =~ s|^/+||;
    my $state = { short_name => $name,
                  full_name => $full_name,
                  name => $final_name,
                  parent => $parent,
                  substates => [],
                  transitions => {},
                  before => {},
                  on => {},
                  ignore => [],
                  delay => [] };
    bless $state, $class;
    push @{$parent->{substates}}, $state if $parent;
    Scalar::Util::weaken($state->{parent});
    $state;
}

1;
