package Authorize::Rule;
# ABSTRACT: Rule-based authorization mechanism
$Authorize::Rule::VERSION = '0.009';
use strict;
use warnings;
use Carp 'croak';

sub new {
    my $class = shift;
    my %opts  = @_;

    defined $opts{'rules'}
        or croak 'You must provide rules';

    my $rules = $opts{'rules'};
    ref($rules) eq 'HASH'
        or croak 'attribute rules must be a hashref';

    # expand entity groups to their entities
    if ( $opts{'entity_groups'} ) {
        ref( $opts{'entity_groups'} ) eq 'HASH'
            or croak 'attribute entity_groups must be a hashref';

        foreach my $group ( keys %{ $opts{'entity_groups'} } ) {
            my $group_rules = delete $rules->{$group}
                or next;

            $rules->{$_} = $group_rules
                for @{ $opts{'entity_groups'}{$group} };
        }
    }

    # expand resource groups to their entities
    if ( $opts{'resource_groups'} ) {
        ref( $opts{'resource_groups'} ) eq 'HASH'
            or croak 'attribute resource_groups must be a hashref';

        # populate
        foreach my $entity ( keys %{$rules} ) {
            foreach my $resource ( keys %{ $rules->{$entity} } ) {
                my $in_rsrc = $opts{'resource_groups'}{$resource}
                    or next;

                $rules->{$entity}{$_} = $rules->{$entity}{$resource}
                    for @{$in_rsrc};
            }
        }

        # delete
        foreach my $entity ( keys %{$rules} ) {
            delete $rules->{$entity}{$_}
                for keys %{ $opts{'resource_groups'} };
        }
    }

    return bless {
        default => 0, # deny by default
        %opts,
    }, $class;
}

sub default {
    my $self = shift;
    @_ and croak 'default() is a ro attribute';
    return $self->{'default'};
}

sub entity_groups {
    my $self = shift;
    @_ and croak 'entity_groups() is a ro attribute';
    return $self->{'entity_groups'};
}

sub resource_groups {
    my $self = shift;
    @_ and croak 'resource_groups() is a ro attribute';
    return $self->{'resource_groups'};
}

sub rules {
    my $self = shift;
    @_ and croak 'rules() is a ro attribute';
    return $self->{'rules'};
}

sub is_allowed {
    my $self = shift;
    return $self->allowed(@_)->{'action'};
}

sub allowed {
    my $self         = shift;
    my $entity       = shift;
    my $req_resource = shift;
    my $req_params   = shift || {};
    my $default      = $self->default;
    my $rules        = $self->rules;
    my %result       = (
        entity   => $entity,
        resource => ($req_resource || ''),
        params   => $req_params,
    );

    my $perms              = $rules->{$entity} || {};
    my $all_entities_perms = $rules->{''}      || {};

    # deny entities that aren't in the rules
    $perms || $all_entities_perms
        or return { %result, action => $default };

    # the requested and default
    my $main_ruleset = $perms->{$req_resource} || [];
    my $def_ruleset  = $perms->{''}            || [];

    # perm for all the entities. Lower priority than main&def ruleset
    # we don't need to check $all_entities_perms->{''} because we have $default
    my $all_entities_ruleset = $all_entities_perms->{$req_resource} || [];

    # if neither, return default action
    @{ $main_ruleset } || @{ $def_ruleset } || @{ $all_entities_ruleset }
        or return { %result, action => $default };

    foreach my $rulesets ( $main_ruleset, $def_ruleset, $all_entities_ruleset) {
        my $ruleset_idx = 0;
        my $label;

      R_SET: foreach my $ruleset ( @{$rulesets} ) {
            if ( ! ref $ruleset ) {
                $label = $ruleset;
                next R_SET;
            }

            $ruleset_idx++;

            my $action = $self->match_ruleset( $ruleset, $req_params );

            if ( defined $action ) {
                my %full_result = (
                    %result,
                    ruleset_idx => $ruleset_idx,
                  ( label       => $label        )x!! $label,
                );

                $full_result{'action'} = ref $action eq 'CODE'      ?
                                         $action->( \%full_result ) :
                                         $action;

                return \%full_result;
            }

            undef $label;
        }
    }

    return { %result, action => $default };
}

sub match_ruleset {
    my $self       = shift;
    my $ruleset    = shift;
    my $req_params = shift;

    my ( $action, @rules ) = @{$ruleset}
        or return;

    # an empty return() is a failure to match
    # if matching of a rule succeeds, we just move to the next rule
    foreach my $rule (@rules) {
        if ( ref $rule eq 'HASH' ) {
            # check defined params by rule against requested params
          KEY: foreach my $key ( keys %{$rule} ) {
                if ( defined $rule->{$key} ) {
                    # check if key is missing
                    defined $req_params->{$key}
                        or return;
                } else {
                    # check the key exists and value is defined
                    exists $req_params->{$key}
                        and return;

                    # don't continue checking the value in this case
                    # because it's undefined
                    next KEY;
                }

                # check matching against a code reference
                if ( ref $rule->{$key} eq 'CODE' ) {
                    $req_params->{$key} eq $rule->{$key}->($req_params)
                        or return;
                } elsif ( ref $rule->{$key} eq 'Regexp' ) {
                    $req_params->{$key} =~ $rule->{$key}
                        or return;
                } elsif ( ref $rule->{$key} ) {
                    croak 'Rule keys can only be strings, regexps, or code';
                } else {
                    # check matching against a simple string
                    $req_params->{$key} eq $rule->{$key}
                        or return; # no match
                }
            }
        } elsif ( ref $rule eq 'CODE' ) {
            $rule->($req_params)
                or return;
        } elsif ( ! ref $rule ) {
            defined $req_params->{$rule}
                or return; # no match
        } else {
            croak 'Unknown rule type';
        }
    }

    return $action;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Authorize::Rule - Rule-based authorization mechanism

=head1 VERSION

version 0.009

=head1 SYNOPSIS

This is an extensive example, showing various options:

    my $auth = Authorize::Rule->new(
        rules => {
            dev => {
                Payroll => [ [0] ], # always deny
                ''      => [ [1] ], # default allow for unknown resources
            },

            tester => {
                '' => [
                    # labeled rulesets
                    'check tester' => [
                        # all rules must apply
                        # key 'is_test' with value 1
                        # and keys test_name/test_id must exist
                        1, { is_test => 1 }, 'test_name', 'test_id'
                    ],
                    'default' => [0],
                ]
            },

            admin => {
                '' => [
                    # the admin does *not* have a passwordless ssh key
                    [ 1, { passwordless_ssh_key => undef } ],
                ],
            },

            ceo => {
                '' => [
                    [
                        # decide on the value of the return ourselves
                        # based on the resource
                        sub {
                            my $res = shift;
                            return 'Access Granted for ' . $res->{'resource'};
                        },

                        # a rule that is itself a subroutine
                        # with access to the parameters
                        sub { has_permission( $_[0]->{'resource'} ) },

                        # a rule with a key that matches the result of a sub
                        { now => sub { correct_relative_time() } },
                    ],
                ],
            },

            biz_rel => {
                Graphs    => [ [0] ],
                Databases => [
                    # access to reservations table
                    [ 1, { table => 'Reservations' } ],
                ],

                Invoices => [
                    [ 0, 'user' ],
                    [ 1         ],
                ],

                Payroll => [ [1] ],
                Revenue => [ [1] ],
                ''      => [ [0] ],
            },

            support => {
                Databases => [
                    [ 1, { table => 'Complaints' } ],
                ],

                Invoices => [ [1] ],
                ''       => [ [0] ],
            },

            sysadmins => {
                Graphs => [ [1] ],
                ''     => [ [0] ],
            },
        },

        entity_groups => {
            sysadmins => [ qw<John Jim Goat> ],
        },

        resource_groups => {
            Graphs => [ 'ThisGraphs', 'ThoseGraphs' ],
        },
    );

I<(this example is not taken from any actual code)>

=head1 DESCRIPTION

L<Authorize::Rule> allows you to provide a set of rulesets, each containing
rules, for authorizing access of entities to resources. This does not cover
authentication, or fine-grained parameter checking.

While authentication asks "who are you?", authorization asks "what are you
allowed to do?"

The system is based on decisions per entities, resources, and any optional
parameters.

=head1 ALPHA CODE

I can't promise some of this won't change in the next few versions.

Stay tuned.

=head1 SPECIFICATION

The specification covers several elements:

=over 4

=item * Entity

=item * Resource

=item * Action

=item * Optional parameters

=item * Optional label

=back

The general structure is:

    {
        ENTITY => {
            RESOURCE => [
                OPTIONAL_LABEL => [ ACTION, RULE_1, RULE_2, ...RULE_N ],
            ]
        }

    }

Allowed rules are:

    # parameters must have this key with this value
    [ $action, { key  => 'value' } ]
    [ $action, { name => 'Marge' } ]

    # parameters must not have this key
    [ $action, { key => undef } ]

    # parameters must have these keys, values aren't checked
    [ $action, 'key1', 'key2', ... ]

    # they can be seamlessly mixed
    [ $action, { Company => 'Samsung' }, { Product => 'Phone' }, 'model_id' ]

    # and yes, this is the equivalent of:
    [ $action, { Company => 'Samsung', Product => 'Phone' }, 'model_id' ]

    # a mix of keys with expected values and keys expected not to exist
    [ $action, { name => 'Marge', holding_knife => undef } ]

    # labels can be applied to rulesets:
    'verifying test account' => [ $action, { username => 'tester' } ]

    # rules can be a subroutine
    [ $action, sub { my $params = shift; ... } ]

    # keys can match to a subroutine result
    [ $action, { Company => sub { get_company( $_[0]->{'company'} ) } } ]

    # and lastly, actions can be subroutines
    [ sub { my $result_hash = shift; return 'OK' if ... }, { %params } ]

An action is either true, false, or a code reference which returns one.
The recommended values for true or false are C<1> or C<0>.
Traditionally these will be C<1> or C<0>:

    [ 1, RULES... ]
    [ 0, RULES... ]
    [ 'FAILURE', RULES... ]

    my $result = $auth->is_allowed( $entity, $resource );
    if ( $result eq 'FAILURE' ) {
        ...
    }

Or as a code reference:

    [ sub {...}, RULES... ]

The code reference receives the entire result hash as a parameter:

    [ sub {
        my $result = shift;

        # $result = {
        #     ruleset_idx => 1,
        #     params      => $PARAMS,
        #     entity      => $ENTITY,
        #     resource    => $RESOURCE,
        # }
    }, RULES... ]

Rules and rulesets are read consecutively, so you might want to position
your rules in order to exit early. When a ruleset is matches, the execution
or rulesets stops and the action is returned.

=head1 EXAMPLES

=head2 All resources

Cats think they can do everything, and they can:

    my $rules = {
        Cat => {
            # default rule for any unmatched resource
            '' => [
                # only 1 ruleset with no actual rules, just an action
                [1]
            ],
        }
    }

    my $auth = Authorize::Rule->new( rules => $rules );
    $auth->is_allowed( cats => 'kitchen' ); # 1, success
    $auth->is_allowed( cats => 'bedroom' ); # 1, success

If you don't like the example of cats (what's wrong with you?), try to think
of a department (or person) given all access to all resources in your company:

    $rules = {
        Sysadmins => {
            '' => [ [1] ],
        },

        CEO => {
            '' => [ [1] ],
        },
    }

=head2 All entities

All entities can access the public resource:

    my $auth = Authorize::Rule->new(
        default => 0,
        rules   => {
            'Person' => {
                'place' => [ [ 1 ] ]
            },

            '' => {
                'public' => [ [ 1 ] ],
                ''       => [ [ 1 ] ], # ignored, we have a default for that
            },
    });

=head2 Per resource

Dogs, however, provide less of a problem. Mostly if you tell them they aren't
allowed somewhere, they will comply. Dogs can't get on the table. Other than
the table, we do want them to have access everywhere.

    $rules = {
        Cat => {
            '' => [ [1] ],
        },

        Dog => {
            Table => [ [0] ], # can't go on the table
            ''    => [ [1] ], # otherwise, allow everything
        },
    }

A corporate example might refer to some departments (or persons) having access
to some resources while denied everything else, or a certain resource not
available to some while all others are.

    $rules = {
        CEO => {
            Payrolls => [ [0] ], # no access to Payrolls
            ''       => [ [1] ], # access to everything else
        },

        Support => {
            UserPreferences      => [ [1] ], # has access to this
            UserComplaintHistory => [ [1] ], # and this
            ''                   => [ [0] ], # but that's it
        },
    }

=head2 Per resource and per conditions

This is the most extensive control you can have. This allows you to set
permissions based on conditions, such as specific parameters per resource.

Suppose we have no problem for the dogs to walk on that one table we don't
like?

    my $rules => {
        Dog => {
            Table => [
                # if the table is owned by someone else, it's okay
                [ 1, { owner => 'someone-else' } ],

                # otherwise, no
                [0],
            ],

            '' => [ [1] ], # but generally dogs can go everywhere
        }
    };

    my $auth = Authorize::Rule->new( rules => $rules );
    $auth->is_allowed( Dog => 'Table', { owner => 'me' } ); # 0, fails

You can also specify just the existence (and C<define>ss) of keys:

    my $rules = {
        Support => {
            ClientTable => [
                [ 1, 'user_id' ], # must have a user id to access the table
                [0],              # otherwise, access denied
            ]
        }
    };

=head2 OR conditions

If you want to create an B<OR> condition, all you need is to provide another
ruleset:

    my $rules = {
        Dog => {
            Table => [
                [ 1, { carer => 'Jim'  } ], # if Jim takes care of the dog
                [ 1, { carer => 'John' } ], # or if John does
                [0],                        # otherwise, no
            ]
        }
    };

    $auth->is_allowed( Dog => 'Table', { owner => 'me'   } ); # 0, fails
    $auth->is_allowed( Dog => 'Table', { owner => 'Jim'  } ); # 1, succeeds
    $auth->is_allowed( Dog => 'Table', { owner => 'John' } ); # 1, succeeds

=head2 AND conditions

If you want to create an B<AND> condition, just add more rules to the
ruleset:

    my $rules = {
        Dog => {
            Table => [
                [
                    1,                     # allow if...
                    { carer => 'John'   }, # john is the carer
                    { day   => 'Sunday' }, # it's Sunday
                    { clean => 1        }, # you're clean
                    'tag_id',              # and you have a tag id
                # otherwise, no
                [0],
            ]
        }
    };

As shown in other examples above, any hash rules can be put in the same
hash, so this is equivalent:

    my $rules = {
        Dog => {
            Table => [
                [
                    1,                     # allow if...
                    {
                        carer => 'John',   # john is the carer
                        day   => 'Sunday', # it's Sunday
                        clean => 1,        # you're clean
                    },
                    'tag_id',              # and you have a tag id
                # otherwise, no
                [0],
            ]
        }
    };

The order of rules does not change anything, except how quickly it might
mismatch. If you have insane amounts of rules and conditions, it could make
a difference, but unlikely.

=head2 labeling

Optional labels can be applied in order to help structure rulesets and
understand which ruleset matched.

    my $rules = {
        Tester => {
            # Tester's rulesets for any resource
            '' => [
                # regular ruleset
                [ 1, 'test_mode' ], # if we're in test_mode

                # labeled ruleset
                'has test ID' => [ 1, 'test_id' ], # has a test ID
            ],
        },
    };

Labeled and unlabeled rulesets can be interchanged freely.

=head2 Catch all

You might ask I<what if there is no last rule at the end for any other
resource?>

The answer is simple: the C<default> clause will be used. You can find an
explanation of it under I<ATTRIBUTES>.

=head2 Callbacks

=head3 As rule

A rule can be a callback:

    my $rules = {
        Marge => {
            '' => [
                [ 1, sub {
                    my $params = shift;

                    time - $params->{'now'} < 10
                        and return 1;

                    return 0;
                } ]
            ],
        }
    };

    $auth->is_allowed( 'Marge', 'Anywhere', { now => time } );

=head3 As parameter

You can compare a parameter value to the result of a callback:

    my $rules = {
        Marge => {
            '' => [
                [ 1, { name => sub { get_name( $_[0]->{'entity'} ) } } ]
            ]
        }
    };

This will compare the C<name> value in the parameters to whatever will be
returned by C<get_name>, which gets as a first argument the C<entity> that
is used - in this case, I<Marge>.

=head3 As action

You can also set the action to be a callback, which allows to do two
interesting things:

=over 4

=item * Change the action

=item * Investigate the result hash

=back

    my $rules = {
        Marge => {
            '' => [
                [
                    sub {
                        my $result = shift;
                        return 'SucceededAt' . $result->{'resource'};
                    },
                    { time => 'now' }, # rule
                ],
            ]
        }
    };

    my $auth   = Authorize::Rule->new( rules => $rules );
    my $action = $auth->is_allowed( 'Marge', 'Somewhere', %params );
    # $action = 'SucceededAtSomewhere'

The result hash will contain information on the request and the matching,
such as the ruleset which was matched.

=head1 ATTRIBUTES

=head2 default

In case there is no matching rule for the entity/resource/conditions, what
would you like to do. The default is to deny (C<0>), but you can change it
to allow by default if there is no match.

    Authorize::Rule->new(
        default => 1, # allow by default
        rules   => {...},
    );

    Authorize::Rule->new(
        default => -1, # to make sure it's the catch-all
        rules   => {...},
    );

=head2 entity_groups

Entity groups allow you to group entities onto their own label. This means
you can set up multiple entities at the same time, while still matching
them by the entity name instead of group name.

    my $auth = Authorize::Rule->new(
        rules => {
            'My Group' => {
                Desk => [ [1] ],
            },
        },

        entity_groups => {
            'My Group' => [ qw<Sawyer Mickey> ],
        },
    );

    # OK
    $auth->is_allowed( 'Sawyer', 'Desk' );

=head2 resource_groups

Resource groups allow you to group resources onto their own label, much
like I<entity_groups>. You can set up multiple resources at the same time,
while still matching them by the resource name instead of the group name.

    my $auth = Authorize::Rule->new(
        rules => {
            Person => {
                Home => [ [1] ],
            },
        },

        resource_groups => {
            Home => [ 'Bedroom', 'Living Room', ... ],
        },
    );

    # OK
    $auth->is_allowed( 'Person', 'Bedroom' );

=head2 rules

Rules can be either:

=over 4

=item *

 A hash reference of your permissions, defined by the specification explained
above.

=item *

A key name (string) indicating this key must exist with no restriction to
the value other than it must be defined.

=item *

A callback with a result that provides the success or fail in boolean context.

=back

=head1 METHODS

=head2 is_allowed

Returns the action for the entity and resource.

Effectively, this is the C<action> key in the result coming from the
C<allowed> method described below.

=head2 allowed

    my $result = $auth->allowed( $entity, $resource, $params );

Returns an entire hash containing every piece of information that might be
helpful:

=over 4

=item * entity

=item * resource

=item * params

=item * action

=item * label

=item * ruleset_idx

The index of the ruleset, starting from 1.

=back

=head1 AUTHORS

=over 4

=item *

Sawyer X <xsawyerx@cpan.org>

=item *

Mickey Nasriachi <mickey@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Sawyer X.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
