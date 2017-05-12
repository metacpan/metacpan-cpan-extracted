package Anansi::DatabaseComponent;


=head1 NAME

Anansi::DatabaseComponent - A manager template for database drivers.

=head1 SYNOPSIS

    package Anansi::Database::Example;

    use base qw(Anansi::DatabaseComponent);

    sub connect {
        my ($self, $channel, %parameters) = @_;
        return $self->SUPER::connect(
            undef,
            INPUT => [
                'some text',
                {
                    NAME => 'someParameter',
                }, {
                    INPUT => [
                        'more text',
                        {
                            NAME => 'anotherParameter',
                        },
                        'yet more text',
                    ]
                }, {
                    DEFAULT => 'abc',
                    NAME => 'yetAnotherParameter',
                },
            ],
            (%parameters),
        );
    }

    sub validate {
        my ($self, $channel, %parameters) = @_;
        $parameters{DRIVER} = 'Example';
        return Anansi::DatabaseComponent::validate(undef, %parameters);
    }

    Anansi::Component::addChannel('Anansi::Database::Example', 'AUTOCOMMIT' => 'Anansi::DatabaseComponent::autocommit');
    Anansi::Component::addChannel('Anansi::Database::Example', 'COMMIT' => 'Anansi::DatabaseComponent::commit');
    Anansi::Component::addChannel('Anansi::Database::Example', 'CONNECT' => 'connect');
    Anansi::Component::addChannel('Anansi::Database::Example', 'DISCONNECT' => 'Anansi::DatabaseComponent::disconnect');
    Anansi::Component::addChannel('Anansi::Database::Example', 'FINISH' => 'Anansi::DatabaseComponent::finish');
    Anansi::Component::addChannel('Anansi::Database::Example', 'HANDLE' => 'Anansi::DatabaseComponent::handle');
    Anansi::Component::addChannel('Anansi::Database::Example', 'PREPARE' => 'Anansi::DatabaseComponent::prepare');
    Anansi::Component::addChannel('Anansi::Database::Example', 'ROLLBACK' => 'Anansi::DatabaseComponent::rollback');
    Anansi::Component::addChannel('Anansi::Database::Example', 'STATEMENT' => 'Anansi::DatabaseComponent::statement');
    Anansi::Component::addChannel('Anansi::Database::Example', 'VALIDATE_AS_APPROPRIATE' => 'validate'); 

    1;

    package main;

    use Anansi::Database;

    my $database = Anansi::Database->new();
    my $component = $database->addComponent(undef,
        DRIVER => 'Example',
    );
    if(defined($component)) {
        if($database->connect(
            undef,
            $component,
            someParameter => 'some data',
            anotherParameter => 'more data',
            yetAnotherParameter => 'further data',
        )) {
            my $result = $database->statement(
                undef,
                $component,
                SQL => 'SELECT someThing FROM someTable where modified = ?;',
                INPUT => [
                    {
                        NAME => 'modified',
                    },
                ],
                modified => '2011-02-22 00:21:46',
            );
            if(!defined($result)) {
            } elsif(ref($result) =~ /^ARRAY$/i) {
                foreach my $record (@{$result}) {
                    next if(ref($record) !~ /^HASH$/i);
                    print 'someThing: "'.${$record}{someThing}.'"'."\n";
                }
            }
        }
    }

    1;

=head1 DESCRIPTION

Manages a database connection providing generic processes to allow it's opening,
closing and various SQL interactions.  Uses L<Anansi::Actor>.

=cut


our $VERSION = '0.04';

use base qw(Anansi::Component);

use Anansi::Actor;


=head1 METHODS

=cut


=head2 Anansi::Class

See L<Anansi::Class|Anansi::Class> for details.  A parent module of L<Anansi::Component|Anansi::Component>.

=cut


=head3 DESTROY

See L<Anansi::Class::DESTROY|Anansi::Class/"DESTROY"> for details.

=cut


=head3 finalise

See L<Anansi::Class::finalise|Anansi::Class/"finalise"> for details.  Overridden by L<Anansi::DatabaseComponent::finalise|Anansi::DatabaseComponent/"finalise">.  A virtual method.

=cut


=head3 implicate

See L<Anansi::Class::implicate|Anansi::Class/"implicate"> for details.  A virtual method.

=cut


=head3 import

See L<Anansi::Class::import|Anansi::Class/"import"> for details.

=cut


=head3 initialise

See L<Anansi::Class::initialise|Anansi::Class/"initialise"> for details.  A virtual method.

=cut


=head3 new

See L<Anansi::Class::new|Anansi::Class/"new"> for details.

=cut


=head3 old

See L<Anansi::Class::old|Anansi::Class/"old"> for details.

=cut


=head3 used

See L<Anansi::Class::used|Anansi::Class/"used"> for details.

=cut


=head3 uses

See L<Anansi::Class::uses|Anansi::Class/"uses"> for details.

=cut


=head3 using

See L<Anansi::Class::using|Anansi::Class/"using"> for details.

=cut


=head2 Anansi::Component

See L<Anansi::Component|Anansi::Component> for details.  A parent module of L<Anansi::DatabaseComponent|Anansi::DatabaseComponent>.

=cut


=head3 Anansi::Class

See L<Anansi::Class|Anansi::Class> for details.  A parent module of L<Anansi::Component|Anansi::Component>.

=cut


=head3 addChannel

See L<Anansi::Component::addChannel|Anansi::Component/"addChannel"> for details.

=cut


=head3 channel

See L<Anansi::Component::channel|Anansi::Component/"channel"> for details.

=cut


=head3 componentManagers

See L<Anansi::Component::componentManagers|Anansi::Component/"componentManagers"> for details.

=cut


=head3 removeChannel

See L<Anansi::Component::removeChannel|Anansi::Component/"removeChannel"> for details.

=cut


=head2 autoCommit

    if(1 == Anansi::DatabaseComponent::autocommit($OBJECT, undef));

    if(1 == Anansi::DatabaseComponent::channel($OBJECT, 'AUTOCOMMIT'));

    if(1 == $OBJECT->autocommit(undef));

    if(1 == $OBJECT->channel('AUTOCOMMIT'));

=over 4

=item self I<(Blessed Hash, Required)>

An object of this namespace.

=item channel I<(String, Required)>

The abstract identifier of a subroutine.

=item parameters I<(Hash, Optional)>

Named parameters.

=back

Attempts to perform a database autocommit.  Returns B<1> I<(one)> on success and
B<0> I<(zero)> on failure.

=cut


sub autocommit {
    my ($self, $channel, %parameters) = @_;
    return 0 if(ref($self) =~ /^(|ARRAY|CODE|FORMAT|GLOB|HASH|IO|LVALUE|REF|Regexp|SCALAR|VSTRING)$/i);
    my $autocommit;
    eval {
        $autocommit = $self->{HANDLE}->autocommit();
        1;
    } or do {
        return 0;
    };
    return 0 if(!defined($autocommit));
    return 0 if(ref($autocommit) !~ /^$/);
    return 0 if($autocommit !~ /^[\+\-]?\d+$/);
    return 1 if($autocommit);
    return 0;
}

Anansi::Component::addChannel('Anansi::DatabaseComponent', 'AUTOCOMMIT' => 'autocommit');


=head2 bind

    if(Anansi::DatabaseComponent::bind($OBJECT,
        HANDLE => $HANDLE,
        INPUT => [
            {
                NAME => 'someParameter'
            }, {
                DEFAULT => 123,
                NAME => 'anotherParameter'
            }
        ],
        VALUE => {
            someParameter => 'abc'
        }
    ));

    if($OBJECT->bind(
        HANDLE => $HANDLE,
        INPUT => [
            {
                NAME => 'yetAnotherParameter',
                TYPE => 'TEXT'
            }
        ],
        VALUE => [
            yetAnotherParameter => 456
        ]
    ));

=over 4

=item self I<(Blessed Hash B<or> String, Required)>

Either an object or a string of this namespace.

=item parameters I<(Hash, Optional)>

Named parameters.

=over 4

=item HANDLE I<(DBI::st, Required)>

The database statement handle.

=item INPUT I<(Array, Required)>

An array of hashes.  Each element of the array corresponds to an equivalent B<?>
I<(Question mark)> within the prepared SQL statement.  Each hash contains a
I<NAME> key with a value that represents a possible key within the I<VALUE>
parameter.  Each hash may also contain a I<DEFAULT> key which contains the value
to use if the equivalent I<VALUE> parameter does not exist and a I<TYPE> key
which contains the SQL type to associate with the assigned value.  When no
corresponding I<VALUE> parameter key exists and no I<DEFAULT> key has been
defined then an empty string is used for the value.

=item VALUE I<(Hash, Required)>

A hash of values to assign in the order specified by the I<INPUT> parameter.

=back

=back

Attempts to use the supplied parameters to assign values to a SQL statement that
has already been prepared to accept them.  Returns B<0> I<(zero)> on failure and
the database statement handle on success.

=cut


sub bind {
    my ($self, %parameters) = @_;
    return 0 if(!defined($parameters{HANDLE}));
    return 0 if(!defined($parameters{INPUT}));
    return 0 if(ref($parameters{INPUT}) !~ /^ARRAY$/i);
    return 0 if(!defined($parameters{VALUE}));
    return 0 if(ref($parameters{VALUE}) !~ /^HASH$/i);
    my $index = 1;
    foreach my $input (@{$parameters{INPUT}}) {
        if(defined(${$parameters{VALUE}}{${$input}{NAME}})) {
            if(defined(${$input}{TYPE})) {
                $parameters{HANDLE}->bind_param($index, ${$parameters{VALUE}}{${$input}{NAME}}, ${$input}{TYPE});
            } else {
                $parameters{HANDLE}->bind_param($index, ${$parameters{VALUE}}{${$input}{NAME}});
            }
        } elsif(defined(${$input}{DEFAULT})) {
            if(defined(${$input}{TYPE})) {
                $parameters{HANDLE}->bind_param($index, ${$input}{DEFAULT}, ${$input}{TYPE});
            } else {
                $parameters{HANDLE}->bind_param($index, ${$input}{DEFAULT});
            }
        } elsif(defined(${$input}{TYPE})) {
            $parameters{HANDLE}->bind_param($index, '', ${$input}{TYPE});
        } else {
            $parameters{HANDLE}->bind_param($index, '');
        }
        $index++;
    }
    return $parameters{HANDLE};
}


=head2 binding

    if(1 == Anansi::DatabaseComponent::binding($OBJECT));

    if(1 == $OBJECT->binding());

=over 4

=item self I<(Blessed Hash B<or> String, Required)>

Either an object or a string of this namespace.

=item parameters I<(Array, Optional)>

An array of hashes.  Each hash should contain a I<NAME> key with a string value.

=back

Verifies that the supplied parameters are all hashes and that they each contain
a I<NAME> key with a string value.  Returns B<1> I<(one)> when validity is
confirmed and B<0> I<(zero)> when an invalid structure is determined.  Used to
validate the I<INPUT> parameter of the B<bind> method.

=cut


sub binding {
    my ($self, @parameters) = @_;
    foreach my $parameter (@parameters) {
        return 0 if(ref($parameter) !~ /^HASH$/i);
        return 0 if(!defined(${$parameter}{NAME}));
        return 0 if(ref(${$parameter}{NAME}) !~ /^$/);
        return 0 if(${$parameter}{NAME} !~ /^[a-zA-Z_]+(\s*[a-zA-Z0-9_]+)*$/);
    }
    return 1;
}


=head2 commit

    if(1 == Anansi::DatabaseComponent::commit($OBJECT, undef));

    if(1 == Anansi::DatabaseComponent::channel($OBJECT, 'COMMIT'));

    if(1 == $OBJECT->commit(undef));

    if(1 == $OBJECT->channel('COMMIT'));

=over 4

=item self I<(Blessed Hash B<or> String, Required)>

Either an object or a string of this namespace.

=item channel I<(String, Required)>

The abstract identifier of a subroutine.

=item parameters I<(Hash, Optional)>

Named parameters.

=back

Attempts to perform a database commit.  Returns B<1> I<(one)> on success and
B<0> I<(zero)> on failure.

=cut


sub commit {
    my ($self, $channel, %parameters) = @_;
    return 0 if(ref($self) =~ /^(|ARRAY|CODE|FORMAT|GLOB|HASH|IO|LVALUE|REF|Regexp|SCALAR|VSTRING)$/i);
    return 0 if(!defined($self->{HANDLE}));
    return 1 if($self->autocommit());
    my $commit;
    eval {
        $commit = $self->{HANDLE}->commit();
        1;
    } or do {
        $self->rollback();
        return 0;
    };
    return 0 if(!defined($commit));
    return 0 if(ref($commit) !~ /^$/);
    return 0 if($commit !~ /^[\+\-]?\d+$/);
    return 1 if($commit);
    return 0;
}

Anansi::Component::addChannel('Anansi::DatabaseComponent', 'COMMIT' => 'commit');


=head2 connect

    if(1 == Anansi::DatabaseComponent::connect($OBJECT, undef
        INPUT => [
            'some text',
            {
                NAME => 'someParameter'
            }, {
                INPUT => [
                    'more text',
                    {
                        NAME => 'anotherParameter'
                    },
                    'yet more text'
                ]
            }, {
                DEFAULT => 'abc',
                NAME => 'yetAnotherParameter'
            }
        ],
        someParameter => 12345,
        anotherParameter => 'blah blah blah'
    ));

    if(1 == Anansi::DatabaseComponent::channel($OBJECT, 'CONNECT',
        INPUT => [
            'blah blah blah',
            {
                DEFAULT => 123,
                NAME => 'someParameter',
            }
        ],
        someParameter => 'some text'
    ));

    if(1 == $OBJECT->connect(undef,
        INPUT => [
            {
                INPUT => [
                    'some text',
                    {
                        NAME => 'someParameter'
                    },
                    'more text'
                ]
            }
        ],
        someParameter => 'in between'
    ));

    if(1 == $OBJECT->channel('CONNECT',
        INPUT => [
            {
                INPUT => [
                    {
                        NAME => 'abc'
                    }, {
                        NAME => 'def'
                    }
                },
                REF => 'HASH'
            }
        ]
    ));

=over 4

=item self I<(Blessed Hash, Required)>

An object of this namespace.

=item channel I<(String, Required)>

The abstract identifier of a subroutine.

=item parameters I<(Hash, Required)>

Named parameters.

=over 4

=item HANDLE I<(DBI::db, Optional)>

The database handle of an existing database connection.  Used in preference to
the I<INPUT> parameter.

=item INPUT I<(Array B<or> Scalar, Optional)>

An array or single value containing a description of each parameter in the order
that it is passed to the database driver's I<connect> method.  Used when the
I<HANDLE> parameter does not exist.

=over 4

=item I<(Non-Hash)>

An element that does not contain a hash value will be used as the corresponding
I<connect> method's parameter value.

=item I<(Hash)>

An element that contains a hash value is assumed to be a description of how to
generate the corresponding I<connect> method's parameter value.  when a value
can not be generated, an B<undef> value will be used.

=over 4

=item DEFAULT I<(Optional)>

The value to use if no other value can be determined.

=item INPUT I<(Array B<or> Scalar, Optional)>

Contains a structure like that given in I<INPUT> above with the exception that
any further I<INPUT> keys will be ignored.  As this key is only valid when
I<NAME> is undefined and I<REF> either specifies a string or a hash, it's value
will be either a concatenation of all the calculated strings or a hash
containing all of the specified keys and values.

=item NAME I<(String, Optional)>

The name of the parameter that contains the value to use.

=item REF I<(Array B<or> String, Optional)>

The data types used to validate the value to use.

=back

=back

=back

=back

Either uses an existing database connection or attempts to perform a database
connection using the supplied parameters.  Returns B<1> I<(one)> on success and
B<0> I<(zero)> on failure.

=cut


sub connect {
    my ($self, $channel, %parameters) = @_;
    return 0 if(ref($self) =~ /^(|ARRAY|CODE|FORMAT|GLOB|HASH|IO|LVALUE|REF|Regexp|SCALAR|VSTRING)$/i);
    $self->disconnect();
    if(defined($parameters{HANDLE})) {
        return 0 if(ref($parameters{HANDLE}) !~ /^DBI::db$/);
        $self->{HANDLE} = $parameters{HANDLE};
        $self->{MANAGE_HANDLE} = 0;
    } elsif(!defined($parameters{INPUT})) {
        return 0;
    } elsif(ref($parameters{INPUT}) !~ /^ARRAY$/i) {
        return 0;
    } else {
        my @inputs;
        foreach my $input (@{$parameters{INPUT}}) {
            if(ref($input) !~ /^HASH$/i) {
                push(@inputs, $input);
                next;
            }
            my $value = undef;
            $value = ${$input}{DEFAULT} if(defined(${$input}{DEFAULT}));
            if(!defined(${$input}{NAME})) {
                if(!defined(${$input}{INPUT})) {
                } elsif(ref(${$input}{INPUT}) !~ /^ARRAY$/i) {
                } elsif(!defined(${$input}{REF})) {
                } elsif(ref(${$input}{REF}) !~ /^$/i) {
                } elsif('' eq ${$input}{REF}) {
                    my @subInputs;
                    for(my $index = 0; $index < scalar(@{${$input}{INPUT}}); $index++) {
                        if(ref(${${$input}{INPUT}}[$index]) =~ /^$/i) {
                            push(@subInputs, ${${$input}{INPUT}}[$index]);
                            next;
                        } elsif(ref(${${$input}{INPUT}}[$index]) !~ /^HASH$/) {
                            next;
                        }
                        my $subValue = '';
                        $subValue = ${${${$input}{INPUT}}[$index]}{DEFAULT} if(defined(${${${$input}{INPUT}}[$index]}{DEFAULT}));
                        if(!defined(${${${$input}{INPUT}}[$index]}{NAME})) {
                        } elsif(ref(${${${$input}{INPUT}}[$index]}{NAME}) !~ /^$/) {
                        } elsif(defined($parameters{${${${$input}{INPUT}}[$index]}{NAME}})) {
                            if(!defined(${${${$input}{INPUT}}[$index]}{REF})) {
                                $subValue = $parameters{${${${$input}{INPUT}}[$index]}{NAME}} if('' eq ref($parameters{${${${$input}{INPUT}}[$index]}{NAME}}));
                            } elsif(ref(${${${$input}{INPUT}}[$index]}{REF}) !~ /^$/) {
                            } elsif('' ne ${${${$input}{INPUT}}[$index]}{REF}) {
                            } elsif('' ne ref($parameters{${${${$input}{INPUT}}[$index]}{NAME}})) {
                            } else {
                                $subValue = $parameters{${${${$input}{INPUT}}[$index]}{NAME}};
                            }
                        }
                        push(@subInputs, $subValue);
                    }
                    $value = join('', @subInputs);
                } elsif(${$input}{REF} =~ /^HASH$/i) {
                    my %subInputs;
                    foreach my $subInput (@{${$input}{INPUT}}) {
                        next if(ref($subInput) !~ /^HASH$/i);
                        my $subValue = undef;
                        $subValue = ${$subInput}{DEFAULT} if(defined(${$subInput}{DEFAULT}));
                        if(!defined(${$subInput}{NAME})) {
                        } elsif(ref(${$subInput}{NAME}) !~ /^$/) {
                        } elsif(defined($parameters{${$subInput}{NAME}})) {
                            if(!defined(${$subInput}{REF})) {
                            } elsif(ref(${$subInput}{REF}) =~ /^ARRAY$/i) {
                                my %refs = map { $_ => 1 } (@{${$subInput}{REF}});
                                $subValue = $parameters{${$subInput}{NAME}} if(defined($refs{ref($parameters{${$subInput}{NAME}})}));
                            } elsif(ref(${$subInput}{REF}) !~ /^$/) {
                            } elsif(${$subInput}{REF} ne ref($parameters{${$subInput}{NAME}})) {
                            } else {
                                $subValue = $parameters{${$subInput}{NAME}};
                            }
                        }
                        $subInputs{${$subInput}{NAME}} = $subValue;
                    }
                    $value = \%subInputs;
                }
            } elsif(ref(${$input}{NAME}) !~ /^$/) {
            } elsif(defined($parameters{${$input}{NAME}})) {
                if(!defined(${$input}{REF})) {
                } elsif(ref(${$input}{REF}) =~ /^ARRAY$/i) {
                    my %refs = map { $_ => 1 } (@{${$input}{REF}});
                    if(!defined($refs{ref($parameters{${$input}{NAME}})})) {
                    } elsif(ref($parameters{${$input}{NAME}}) !~ /^HASH$/i) {
                        $value = $parameters{${$input}{NAME}};
                    } else {
                        if(!defined(${$input}{INPUT})) {
                            $value = $parameters{${$input}{NAME}};
                        } elsif(ref(${$input}{INPUT}) !~ /^HASH$/i) {
                            $value = $parameters{${$input}{NAME}};
                        } else {
                            my %subInputs;
                            foreach my $subInput (keys(%{${$input}{INPUT}})) {
                                if(ref($subInput) !~ /^HASH$/i) {
                                    $subInputs{$subInput} = $subInput;
                                    next;
                                }
                                my $subValue = undef;
                                $value = ${${${$input}{INPUT}}{$subInput}}{DEFAULT} if(defined(${${${$input}{INPUT}}{$subInput}}{DEFAULT}));
                                if(!defined(${${${$input}{INPUT}}{$subInput}}{NAME})) {
                                } elsif(ref(${${${$input}{INPUT}}{$subInput}}{NAME}) !~ /^$/) {
                                } elsif(defined($parameters{${${${$input}{INPUT}}{$subInput}}{NAME}})) {
                                    if(!defined(${${${$input}{INPUT}}{$subInput}}{REF})) {
                                    } elsif(ref(${${${$input}{INPUT}}{$subInput}}{REF}) =~ /^ARRAY$/i) {
                                        my %refs = map { $_ => 1 } (@{${${${$input}{INPUT}}{$subInput}}{REF}});
                                        $subValue = $parameters{${${${$input}{INPUT}}{$subInput}}{NAME}} if(defined($refs{ref($parameters{${${${$input}{INPUT}}{$subInput}}{NAME}})}));
                                    } elsif(ref(${${${$input}{INPUT}}{$subInput}}{REF}) !~ /^$/) {
                                    } elsif(${${${$input}{INPUT}}{$subInput}}{REF} ne ref($parameters{${${${$input}{INPUT}}{$subInput}}{NAME}})) {
                                    } else {
                                        $subValue = $parameters{${${${$input}{INPUT}}{$subInput}}{NAME}};
                                    }
                                }
                                $subInputs{$subInput} = $subValue;
                            }
                            $value = \%subInputs;
                        }
                    }
                } elsif(ref(${$input}{REF}) !~ /^$/) {
                } elsif(${$input}{REF} ne ref($parameters{${$input}{NAME}})) {
                } elsif(ref($parameters{${$input}{NAME}}) !~ /^HASH$/i) {
                    $value = $parameters{${$input}{NAME}};
                } else {
                    if(!defined(${$input}{INPUT})) {
                        $value = $parameters{${$input}{NAME}};
                    } elsif(ref(${$input}{INPUT}) !~ /^HASH$/i) {
                        $value = $parameters{${$input}{NAME}};
                    } else {
                        my %subInputs;
                        foreach my $key (keys(%{${$input}{INPUT}})) {
                            if(ref($subInput) !~ /^HASH$/i) {
                                push(@subInputs, $subInput);
                                next;
                            }
                            my $subValue = undef;
                            $value = ${${${$input}{INPUT}}{$subInput}}{DEFAULT} if(defined(${${${$input}{INPUT}}{$subInput}}{DEFAULT}));
                            if(!defined(${${${$input}{INPUT}}{$subInput}}{NAME})) {
                            } elsif(ref(${${${$input}{INPUT}}{$subInput}}{NAME}) !~ /^$/) {
                            } elsif(defined($parameters{${${${$input}{INPUT}}{$subInput}}{NAME}})) {
                                if(!defined(${${${$input}{INPUT}}{$subInput}}{REF})) {
                                } elsif(ref(${${${$input}{INPUT}}{$subInput}}{REF}) =~ /^ARRAY$/i) {
                                    my %refs = map { $_ => 1 } (@{${${${$input}{INPUT}}{$subInput}}{REF}});
                                    $subValue = $parameters{${${${$input}{INPUT}}{$subInput}}{NAME}} if(defined($refs{ref($parameters{${${${$input}{INPUT}}{$subInput}}{NAME}})}));
                                } elsif(ref(${${${$input}{INPUT}}{$subInput}}{REF}) !~ /^$/) {
                                } elsif(${${${$input}{INPUT}}{$subInput}}{REF} ne ref($parameters{${${${$input}{INPUT}}{$subInput}}{NAME}})) {
                                } else {
                                    $subValue = $parameters{${${${$input}{INPUT}}{$subInput}}{NAME}};
                                }
                            }
                            $subInputs{$subInput} = $subValue;
                        }
                        $value = \%subInputs;
                    }
                }
            }
            push(@inputs, $value);
        }
        return 0 if(0 == scalar(@inputs));
        my $handle = DBI->connect(@inputs);
        return 0 if(!defined($handle));
        $self->{HANDLE} = $handle;
        $self->{MANAGE_HANDLE} = 1;
    }
    return 1;
}

Anansi::Component::addChannel('Anansi::DatabaseComponent', 'CONNECT' => 'connect');


=head2 disconnect

    if(1 == Anansi::DatabaseComponent::disconnect($OBJECT, undef));

    if(1 == Anansi::DatabaseComponent::channel($OBJECT, 'DISCONNECT'));

    if(1 == $OBJECT->disconnect(undef));

    if(1 == $OBJECT->channel('DISCONNECT'));

=over 4

=item self I<(Blessed Hash B<or> String, Required)>

Either an object or a string of this namespace.

=item channel I<(String, Required)>

The abstract identifier of a subroutine.

=item parameters I<(Hash, Optional)>

Named parameters.

=back

Attempts to perform a database disconnection.  Returns B<1> I<(one)> on success
and B<0> I<(zero)> on failure.

=cut


sub disconnect {
    my ($self, $channel, %parameters) = @_;
    return 0 if(ref($self) =~ /^(|ARRAY|CODE|FORMAT|GLOB|HASH|IO|LVALUE|REF|Regexp|SCALAR|VSTRING)$/i);
    return 0 if(!defined($self->{HANDLE}));
    if(!defined($self->{MANAGE_HANDLE})) {
        $self->{MANAGE_HANDLE} = 0;
    } elsif(1 == $self->{MANAGE_HANDLE}) {
        $self->{HANDLE}->disconnect();
        $self->{MANAGE_HANDLE} = 0;
        delete $self->{HANDLE};
    } else {
        delete $self->{HANDLE};
    }
    return 1;
}

Anansi::Component::addChannel('Anansi::DatabaseComponent', 'DISCONNECT' => 'disconnect');


=head2 finalise

Overrides L<Anansi::Class::finalise|Anansi::Class/"finalise">.  A virtual method.

=cut


sub finalise {
    my ($self, %parameters) = @_;
    $self->finish();
    $self->disconnect();
}


=head2 finish

    if(1 == Anansi::DatabaseComponent::finish($OBJECT, undef));

    if(1 == Anansi::DatabaseComponent::channel($OBJECT, 'FINISH'));

    if(1 == $OBJECT->finish(undef));

    if(1 == $OBJECT->channel('FINISH'));

=over 4

=item self I<(Blessed Hash, Required)>

Either an object or a string of this namespace.

=item channel I<(String, Required)>

The abstract identifier of a subroutine.

=item parameters I<(Hash, Optional)>

Named parameters.

=over 4

=item STATEMENT I<(String, Optional)>

The name associated with a prepared SQL statement.

=back

=back

Either releases the named SQL statement preparation or all of the SQL statement
preparations.  Returns B<1> I<(one)> on success and B<0> I<(zero)> on failure.

=cut


sub finish {
    my ($self, $channel, %parameters) = @_;
    return 0 if(ref($self) =~ /^(|ARRAY|CODE|FORMAT|GLOB|HASH|IO|LVALUE|REF|Regexp|SCALAR|VSTRING)$/i);
    if(!defined($self->{STATEMENTS})) {
        return 0;
    } elsif(0 == scalar(keys(%{$self->{STATEMENTS}}))) {
        return 0;
    }
    if(!defined($parameters{STATEMENT})) {
        foreach my $statement (keys(%{$self->{STATEMENTS}})) {
            if(defined(${${$self->{STATEMENTS}}{$statement}}{HANDLE})) {
                eval {
                    ${${$self->{STATEMENTS}}{$statement}}{HANDLE}->finish();
                    1;
                };
            }
            delete ${$self->{STATEMENTS}}{$statement};
        }
    } elsif(ref($parameters{STATEMENT}) !~ /^$/) {
        return 0;
    } elsif(!defined(${$self->{STATEMENTS}}{$parameters{STATEMENT}})) {
        return 0;
    } elsif(!defined(${${$self->{STATEMENTS}}{$parameters{STATEMENT}}}{HANDLE})) {
        return 0;
    } else {
        eval {
            ${${$self->{STATEMENTS}}{$parameters{STATEMENT}}}{HANDLE}->finish();
            1;
        };
        delete ${$self->{STATEMENTS}}{$parameters{STATEMENT}};
    }
    delete $self->{STATEMENTS} if(0 == scalar(keys(%{$self->{STATEMENTS}})));
    return 1;
}

Anansi::Component::addChannel('Anansi::DatabaseComponent', 'FINISH' => 'finish');


=head2 handle

    my $HANDLE = Anansi::DatabaseComponent::handle($OBJECT, undef);

    my $HANDLE = Anansi::DatabaseComponent::channel($OBJECT, 'HANDLE');

    my $HANDLE = $OBJECT->handle(undef);

    my $dbh = DBI->connect('DBI:mysql:database=someDatabase', 'someUser', 'somePassword');
    my $HANDLE = $OBJECT->channel('HANDLE', $dbh);
    if(defined($HANDLE));

=over 4

=item self I<(Blessed Hash, Required)>

An object of this namespace.

=item channel I<(String, Required)>

The abstract identifier of a subroutine.

=item handle I<(DBI::db, Optional)>

A replacement database handle.

=back

Attempts to redefine an existing database handle when a handle is supplied.
Either returns the database handle or B<undef> on failure.

=cut


sub handle {
    my ($self, $channel, $handle) = @_;
    return if(ref($self) =~ /^(|ARRAY|CODE|FORMAT|GLOB|HASH|IO|LVALUE|REF|Regexp|SCALAR|VSTRING)$/i);
    if(defined($handle)) {
        if(defined($self->{HANDLE})) {
            $self->finish();
            $self->disconnect();
        }
        return if(ref($handle) !~ /^DBI::db$/);
        $self->{HANDLE} = $handle;
        $self->{MANAGE_HANDLE} = 0;
    }
    return $self->{HANDLE} if(defined($self->{HANDLE}));
    return;
}

Anansi::Component::addChannel('Anansi::DatabaseComponent', 'HANDLE' => 'handle');


=head2 initialise

Overrides L<Anansi::Class::initialise|Anansi::Class/"initialise">.  A virtual method.

=cut


sub initialise {
    my ($self, %parameters) = @_;
    Anansi::Actor->new(
        PACKAGE => 'DBI',
    );
    $self->{STATEMENT} = {};
}


=head2 prepare

    my $PREPARATION = if(1 == Anansi::DatabaseComponent::prepare($OBJECT, undef,
        STATEMENT => 'an associated name'
    );
    if(defined($PREPARATION));

    if(1 == Anansi::DatabaseComponent::channel($OBJECT, 'PREPARE',
        INPUT => [
            {
                NAME => 'someParameter'
            }
        ],
        SQL => 'SELECT abc, def FROM some_table WHERE ghi = ?',
        STATEMENT => 'another associated name'
    ));

    if(1 == $OBJECT->prepare(undef,
        INPUT => [
            {
                NAME => 'abc'
            }, {
                NAME => 'def'
            }, {
                NAME => 'ghi'
            }
        ],
        SQL => 'INSERT INTO some_table (abc, def, ghi) VALUES (?, ?, ?);',
        STATEMENT => 'yet another name'
    ));

    if(1 == $OBJECT->channel('PREPARE',
        INPUT => [
            {
                NAME => ''
            }
        ],
        SQL => '',
        STATEMENT => 'and another',
    ));

=over 4

=item self I<(Blessed Hash, Required)>

Either an object or a string of this namespace.

=item channel I<(String, Required)>

The abstract identifier of a subroutine.

=item parameters I<(Hash, Required)>

Named parameters.

=over 4

=item INPUT I<Array, Optional>

An array of hashes.  Each hash should contain a I<NAME> key with a string value
that represents the name of a parameter to associate with the corresponding B<?>
I<(Question mark)>.  See the I<bind> method for details.

=item SQL I<(String, Optional)>

The SQL statement to prepare.

=item STATEMENT I<(String, Required)>

The name to associate with the prepared SQL statement.

=back

=back

Attempts to prepare a SQL statement to accept named parameters in place of B<?>
I<(Question mark)>s as required.  Either returns all of the preparation data
required to fulfill the SQL statement when called as a namespace method or B<1>
I<(one)> when called through a channel on success and B<0> I<(zero)> on failure.

=cut


sub prepare {
    my ($self, $channel, %parameters) = @_;
    return 0 if(ref($self) =~ /^(|ARRAY|CODE|FORMAT|GLOB|HASH|IO|LVALUE|REF|Regexp|SCALAR|VSTRING)$/i);
    $self->{STATEMENTS} = {} if(!defined($self->{STATEMENTS}));
    return 0 if(!defined($parameters{STATEMENT}));
    return 0 if(ref($parameters{STATEMENT}) !~ /^$/);
    if(!defined(${$self->{STATEMENTS}}{$parameters{STATEMENT}})) {
        return 0 if(!defined($parameters{SQL}));
        return 0 if(ref($parameters{SQL}) !~ /^$/);
        $parameters{SQL} =~ s/^\s*(.*)|(.*)\s*$/$1/g;
        my $questionMarks = $parameters{SQL};
        my $questionMarks = $questionMarks =~ s/\?/$1/sg;
        if(0 == $questionMarks) {
            return 0 if(defined($parameters{INPUT}));
        } elsif(!defined($parameters{INPUT})) {
            return 0;
        } elsif(ref($parameters{INPUT}) !~ /^ARRAY$/i) {
            return 0;
        } elsif(scalar(@{$parameters{INPUT}}) != $questionMarks) {
            return 0;
        } else {
            return 0 if(!$self->binding((@{$parameters{INPUT}})));
        }
        my $handle;
        eval {
            $handle = $self->{HANDLE}->prepare($parameters{SQL});
            1;
        } or do {
            $self->rollback();
            return 0;
        };
        my %statement = (
            HANDLE => $handle,
            SQL => $parameters{SQL},
        );
        $statement{INPUT} = $parameters{INPUT} if(defined($parameters{INPUT}));
        ${$self->{STATEMENTS}}{$parameters{STATEMENT}} = \%statement;
    }
    return 1 if(defined($channel));
    return ${$self->{STATEMENTS}}{$parameters{STATEMENT}};
}

Anansi::Component::addChannel('Anansi::DatabaseComponent', 'PREPARE' => 'prepare');


=head2 rollback

    if(1 == Anansi::DatabaseComponent::rollback($OBJECT, undef));

    if(1 == Anansi::DatabaseComponent::channel($OBJECT, 'ROLLBACK'));

    if(1 == $OBJECT->rollback(undef));

    if(1 == $OBJECT->channel('ROLLBACK'));

=over 4

=item self I<(Blessed Hash, Required)>

Either an object or a string of this namespace.

=item channel I<(String, Required)>

The abstract identifier of a subroutine.

=item parameters I<(Hash, Optional)>

Named parameters.

=back

Attempts to undo all of the database changes since the last database I<commit>.
Returns B<1> I<(one)> on success and B<0> I<(zero)> on failure.

=cut


sub rollback {
    my ($self, $channel, %parameters) = @_;
    return 0 if(ref($self) =~ /^(|ARRAY|CODE|FORMAT|GLOB|HASH|IO|LVALUE|REF|Regexp|SCALAR|VSTRING)$/i);
    return 0 if($self->autocommit());
    my $rollback;
    eval {
        $rollback = $self->{HANDLE}->rollback();
        1;
    } or do {
        return 0;
    };
    return 0 if(!defined($rollback));
    return 0 if(ref($rollback) !~ /^$/);
    return 0 if($rollback !~ /^[\+\-]?\d+$/);
    return 1 if($rollback);
    return 0;
}

Anansi::Component::addChannel('Anansi::DatabaseComponent', 'ROLLBACK' => 'rollback');


=begin comment

################################################################################

=head2 script

    my $result = $object->script(
        undef,
        SCRIPT => [
            {
                COMMAND => 'LOOP',
                TEST => '',
            }, [
                {
                },
            ],
        ],
    );

=over 4

=item self I<(Blessed Hash, Required)>

Either an object or a string of this namespace.

=item channel I<(String, Required)>

The abstract identifier of a subroutine.

=item parameters I<(Hash, Required)>

Named parameters.

=over 4

=item SCRIPT I<(Array, Required)>

The SQL statements, control structures and external process triggers that are
iterated through in sequence.

=over 4

=item I<(Array)>

A sequence of statements like the I<SCRIPT> parameter.

=item I<(Hash)>

Either a SQL statement, control structure or external process trigger.

=over 4

=item COMMAND I<(String, Required)>

A script command.

=over 4

=item B<"LOOP">

Describes how to iterate over the subsequent sequence statement.

=item B<"RUN">

Describes how to perform an external subroutine.

=item B<"SET">

Describes how to define or redefine script variables.

=item B<"SQL">

Describes a specific SQL statement and it's interaction requirements.

=item B<"TEST">

Describes whether to perform the subsequent sequence statement.

=back

=item INPUT I<(Array B<or> String, Optional)>

An array of strings or a string containing the variables or variable data.  Only
used when I<COMMAND> contains B<"LOOP">, B<"RUN"> or B<"SQL">.

=item NAME I<(String, Optional)

A sequence name associated with the SQL statement, control structure or external
process trigger.  When I<COMMAND> is B<"LOOP">, represents the name of a script
variable hash that will contain the current I<ITERATION> of the loop starting at
B<0> I<(zero)>, how many I<ITERATIONS> the loop is expected to perform a B<1>
I<(one)> or greater or a B<0> I<(zero)> for indeterminate and the I<INPUT> value
to use in the iteration or B<undef> if indeterminate.  When I<COMMAND> is B<"RUN">
, represents the name of a script variable that will contain the results of the
trigger.  When I<COMMAND> is B<"TEST">, represents the name of a script variable
that will either contain the result of the current test or the name of a script
variable that should be used to determine whether the sequence statement should
be performed.

=item SQL I<(String, Optional)>

A SQL statement like that described in the I<statement> method's I<SQL>
parameter.  Only used when I<COMMAND> contains B<"SQL">.

=item STATEMENT I<(String, Optional)>

The name associated with a SQL statement like that described in the I<statement>
method's I<STATEMENT> parameter.  Only used when I<COMMAND> contains B<"SQL">.

=item TRIGGER I<(String, Optional)>

N/A

=item VALUE I<Array B<or> Hash, Optional>

Either an array of hashes or a hash representing specific script variables and
variable data.  Only used when I<COMMAND> contains B<"LOOP">, B<"SET"> or B<"TEST">.
When I<COMMAND> is B<"LOOP">, all of the referenced script variables must equate
to the referenced values for the body of the loop to iterate.  When I<COMMAND>
is B<"SET">, all of the referenced script variables are either declared or
redeclared to contain the referenced values.  When I<COMMAND> is B<"TEST">, all of
the referenced script variables must equate to the referenced values for the
body of the if to iterate.

=back

=back

=back

=back

Combines SQL statements together with a way to process them dynamically, making
it possible to perform compound database tasks without needing to resort to
using database functions or Perl subroutines.

#=cut


sub script {
    my ($self, $channel, %parameters) = @_;
    my ($VARIABLES);

    sub scriptCommand {
    }

    sub scriptLocalBegin {
        $VARIABLES = [] if(!defined($VARIABLES));
        $VARIABLES = [] if(ref($VARIABLES) !~ /^ARRAY$/i);
        for(my $index = 0; $index < scalar(@{$VARIABLES}); $index++) {
            $VARIABLES[$index] = {} if(ref($VARIABLES[$index]) !~ /^HASH$/i);
        }
        push(@{$VARIABLES}, {});
    }

    sub scriptLocalEnd {
        $VARIABLES = [] if(!defined($VARIABLES));
        $VARIABLES = [] if(ref($VARIABLES) !~ /^ARRAY$/i);
        pop(@{$VARIABLES}) if(0 < scalar(@{$VARIABLES}));
        for(my $index = 0; $index < scalar(@{$VARIABLES}); $index++) {
            $VARIABLES[$index] = {} if(ref($VARIABLES[$index]) !~ /^HASH$/i);
        }
    }

    sub scriptGlobal {
        return scriptLocal(0, (@_));
    }

    sub scriptLocal {
        $VARIABLES = [] if(!defined($VARIABLES));
        $VARIABLES = [] if(ref($VARIABLES) !~ /^ARRAY$/i);
        for(my $index = 0; $index < scalar(@{$VARIABLES}); $index++) {
            $VARIABLES[$index] = {} if(ref($VARIABLES[$index]) !~ /^HASH$/i);
        }
        my $DEPTH = scalar(@{$VARIABLES}) - 1;
        if(0 < scalar(@_)) {
            my $depth = shift(@_);
            if(!defined($depth)) {
            } elsif(ref($depth) !~ /^$/) {
                return ;
            } elsif($depth !~ /^[\-+]?\d+$/) {
                return ;
            } elsif($depth < 0) {
                $DEPTH = scalar(@{$VARIABLES}) + $depth;
                $DEPTH = 0 if($DEPTH < 0);
            } elsif(scalar(@{$VARIABLES}) <= $depth) {
            } else {
                $DEPTH = $depth;
            }
        }
        my %ALL_VARIABLES;
        for(my $index = 0; $index <= $DEPTH; $index++) {
            %ALL_VARIABLES = (%ALL_VARIABLES, %{$VARIABLES[$index]});
        }
        if(0 == scalar(@_)) {
            return [( keys(%ALL_VARIABLES) )];
        } elsif(1 == scalar(@_)) {
            my ($key) = @_;
            return if(!defined($key));
            return if(ref($key) !~ /^$/);
            return if(!defined($ALL_VARIABLES{$key}));
            return $ALL_VARIABLES{$key};
        } elsif(2 == scalar(@_)) {
            my ($key, $value) = @_;
            return 0 if(!defined($key));
            return 0 if(ref($key) !~ /^$/);
            if(defined($value)) {
                ${$VARIABLES[$DEPTH]}{$key} = $value;
                return 1;
            }
            if(defined(${$VARIABLES[$DEPTH]}{$key})) {
                delete ${$VARIABLES[$DEPTH]}{$key};
                return 1;
            }
            return 0;
        }
        return ;
    }

    sub scriptSequence {
        my (@commands) = @_;
        scriptLocalBegin();
        my $sequence = {
            COMMAND => 0,
            COMMANDS => [( @commands )],
        };
        do {
            last if(!scriptLocal('_', $sequence));
            last if(!($sequence{COMMAND} < scalar(@{$sequence{COMMANDS}})));
            scriptCommand();
            $sequence{COMMAND}++;
        } while($sequence{COMMAND} < scalar(@{$sequence{COMMANDS}}));
        scriptLocalEnd();
    }

    sub scriptValidate {
    }

    sub scriptVariable {
    }

    sub block {
        my (undef, @commands) = @_;
        ${$_[0]}{'_'} = [] if(!defined(${$_[0]}{'_'}));
        push(@{${$_[0]}{'_'}}, {});
        ${${${$_[0]}{'_'}}[-1]}{COMMANDS} = [( @commands )];
        for(my $index = 0; $index < scalar(@commands); $index++) {
            my $command = $commands[$index];
            if(ref($command) =~ /^ARRAY$/i) {
                ${${${$_[0]}{'_'}}[-1]}{INDEX} = $INDEX;
                block($_[0], (@{$command}));
            }
            next if(ref($command) !~ /^HASH$/i);
            next if(!defined($command{COMMAND}));
            next if(ref($command{COMMAND}) !~ /^$/);
            if(!defined($command{NAME})) {
            } elsif(ref($command{NAME}) !~ /^$/) {
                delete $command{NAME};
            } elsif($command{NAME} =~ /^\s*$/) {
                delete $command{NAME};
            } elsif(0 == 1) {
            } else {
                ${${${$_[0]}{'_'}}[-1]}{NAME} = $command{NAME};
            }
            if($command{COMMAND} =~ /^LOOP$/i) {
            } elsif($command{COMMAND} =~ /^RUN$/i) {
            } elsif($command{COMMAND} =~ /^SET$/i) {
            } elsif($command{COMMAND} =~ /^SQL$/i) {
            } elsif($command{COMMAND} =~ /^TEST$/i) {
            }
        }
        pop(@{${$_[0]}{'_'}});
        delete ${$_[0]}{'_'} if(0 == scalar(@{${$_[0]}{'_'}}));
    }
    return if(!defined($parameters{SCRIPT}));
    return if(ref($parameters{SCRIPT}) !~ /^ARRAY$/i);
    my $variables = {};
    foreach my $key (keys(%parameters)) {
        $variables{$key} = $parameters{$key};
    }
    block($variables, (@{$parameters{SCRIPT}}));
}

Anansi::Component::addChannel('Anansi::DatabaseComponent', 'SCRIPT' => 'script');

################################################################################

=end comment


=head2 statement

    my $result = Anansi::DatabaseComponent::statement($OBJECT, undef,
        INPUT => [
            'hij' => 'someParameter',
            'klm' => 'anotherParameter'
        ],
        SQL => 'SELECT abc, def FROM some_table WHERE hij = ? AND klm = ?;',
        STATEMENT => 'someStatement',
        someParameter => 123,
        anotherParameter => 456
    );

    my $result = Anansi::DatabaseComponent::channel($OBJECT, 'STATEMENT',
        STATEMENT => 'someStatement',
        someParameter => 234,
        anotherParameter => 'abc'
    );

    my $result = $OBJECT->statement(
        undef,
        STATEMENT => 'someStatement',
        someParameter => 345,
        anotherParameter => 789
    );

    my $result = $OBJECT->channel('STATEMENT',
        STATEMENT => 'someStatement',
        someParameter => 456,
        anotherParameter => 'def'
    );

=over 4

=item self I<(Blessed Hash, Required)>

Either an object or a string of this namespace.

=item channel I<(String, Required)>

The abstract identifier of a subroutine.

=item parameters I<(Hash, Optional)>

Named parameters.

=over 4

=item INPUT I<(Array, Optional)>

An array of hashes with each element corresponding to an equivalent B<?>
I<(Question mark)> found within the supplied I<SQL>.  If the number of elements
is not the same as the number of B<?> I<(Question mark)>s found in the statement
then the statement is invalid.  See the I<bind> method for details.

=item SQL I<(String, Optional)>

The SQL statement to execute.

=item STATEMENT I<(String, Optional)>

The name associated with a prepared SQL statement.  This is interchangeable with
the SQL parameter but helps to speed up repetitive database interaction.

=back

=back

Attempts to execute the supplied I<SQL> with the supplied named parameters.
Either returns an array of retrieved record data or a B<1> I<(one)> on success
and a B<0> I<(zero)> on failure as appropriate to the SQL statement.

=cut


sub statement {
    my ($self, $channel, %parameters) = @_;
    return 0 if(ref($self) =~ /^(|ARRAY|CODE|FORMAT|GLOB|HASH|IO|LVALUE|REF|Regexp|SCALAR|VSTRING)$/i);
    my $prepared = $self->prepare(undef, (%parameters));
    my $handle;
    if($prepared) {
        $handle = ${$prepared}{HANDLE};
        if(defined(${$prepared}{INPUT})) {
            my $bound = $self->bind(
                HANDLE => $handle,
                INPUT => ${$prepared}{INPUT},
                VALUE => \%parameters,
            );
            return 0 if(!$bound);
        }
    } else {
        eval {
            $handle = $self->{HANDLE}->prepare($parameters{SQL});
            1;
        } or do {
            $self->rollback();
            return 0;
        };
        my $questionMarks = $parameters{SQL};
        my $questionMarks = $questionMarks =~ s/\?/$1/sg;
        if(0 == $questionMarks) {
            if(defined($parameters{INPUT})) {
                $self->rollback();
                return 0;
            }
        } elsif(!defined($parameters{INPUT})) {
            $self->rollback();
            return 0;
        } elsif(ref($parameters{INPUT}) !~ /^ARRAY$/i) {
            $self->rollback();
            return 0;
        } elsif(scalar(@{$parameters{INPUT}}) != $questionMarks) {
            $self->rollback();
            return 0;
        } else {
            if(!$self->bind(
                HANDLE => $handle,
                INPUT => $parameters{INPUT},
                VALUE => \%parameters,
            )) {
                $self->rollback();
                return 0;
            }
        }
    }
    eval {
        $handle->execute();
        1;
    } or do {
        $handle->rollback();
        return 0;
    };
    if(!defined($handle->{NUM_OF_FIELDS})) {
        return 1;
    } elsif(undef == $handle->{NUM_OF_FIELDS}) {
        return 1;
    } elsif(0 == $handle->{NUM_OF_FIELDS}) {
        return 1;
    }
    my $result = [];
    while(my $row = $handle->fetchrow_hashref()) {
        push(@{$result}, $row);
    }
    $handle->finish() if(!$prepared);
    return $result;
}

Anansi::Component::addChannel('Anansi::DatabaseComponent', 'STATEMENT' => 'statement');


=head2 validate

    if(1 == Anansi::DatabaseComponent::validate($OBJECT, undef));

    if(1 == Anansi::DatabaseComponent::channel($OBJECT, 'VALIDATE_AS_APPROPRIATE'));

    if(1 == Anansi::DatabaseComponent->validate(undef, DRIVERS => ['some::driver::module', 'anotherDriver']));

    if(1 == Anansi::DatabaseComponent->channel('VALIDATE_AS_APPROPRIATE'));

    if(1 == $OBJECT->validate(undef, DRIVER => 'Example'));

    if(1 == $OBJECT->channel('VALIDATE_AS_APPROPRIATE', DRIVER => 'Example'));

    if(1 == Anansi::DatabaseComponent->validate(undef, DRIVER => 'Example', DRIVERS => 'some::driver'));

    if(1 == Anansi::DatabaseComponent->channel('VALIDATE_AS_APPROPRIATE', DRIVER => 'Example'));

=over 4

=item self I<(Blessed Hash B<or> String, Required)>

Either an object or a string of this namespace.

=item channel I<(String, Required)>

The abstract identifier of a subroutine.

=item parameters I<(Hash, Optional)>

Named parameters.

=over 4

=item DRIVER I<(String, Optional)>

Either the namespace of a database driver or the name of a database driver that
should be used.

=item DRIVERS I<(Array B<or> String, Optional)>

An array of strings or a single string containing either the namespace of a
valid database driver or the name of a database driver that should be looked for
among the installed modules.

=item HANDLE I<DBI::db, Optional>

An existing database connection handle.

=back

=back

Generic validation for whether a database should be handled by a component.  If
the driver name is supplied then an attempt will be made to use that driver as
long as it matches any of the acceptable B<DRIVERS>, otherwise one of the
acceptable B<DRIVERS> will be tried or a generic driver if none have been
supplied.  Returns B<1> I<(one)> for valid and B<0> I<(zero)> for invalid.

=cut


sub validate {
    my ($self, $channel, %parameters) = @_;
    my $package = $self;
    $package = ref($self) if(ref($self) !~ /^$/);
    my %modules = Anansi::Actor->modules();
    return 0 if(!defined($modules{'Bundle::DBI'}));
    my $HANDLE_DRIVER;
    if(defined($parameters{HANDLE})) {
        return 0 if(ref($parameters{HANDLE}) !~ /^DBI::db$/);
        my $driver = $parameters{HANDLE}->get_info(17);
        return 0 if(!defined($driver));
        $HANDLE_DRIVER = $driver;
    }
    if(!defined($parameters{DRIVER})) {
        if(defined($parameters{DRIVERS})) {
            $parameters{DRIVERS} = [( $parameters{DRIVERS} )] if(ref($parameters{DRIVERS}) =~ /^$/);
            return 0 if(ref($parameters{DRIVERS}) !~ /^ARRAY$/i);
            if(defined($HANDLE_DRIVER)) {
                foreach my $DRIVER (@{$parameters{DRIVERS}}) {
                    return 0 if(ref($DRIVER) !~ /^$/);
                    return 1 if($DRIVER eq $HANDLE_DRIVER);
                }
            } else {
                my %reduced = map { lc($_) => $modules{$_} } (keys(%modules));
                foreach my $DRIVER (@{$parameters{DRIVERS}}) {
                    return 0 if(ref($DRIVER) !~ /^$/);
                    return 1 if(defined($modules{$DRIVER}));
                    return 1 if(defined($modules{'DBD::'.$DRIVER}));
                    return 1 if(defined($modules{'Bundle::DBD::'.$DRIVER}));
                    return 1 if(defined($reduced{lc($DRIVER)}));
                    return 1 if(defined($reduced{lc('DBD::'.$DRIVER)}));
                    return 1 if(defined($reduced{lc('Bundle::DBD::'.$DRIVER)}));
                }
            }
            return 0;
        } elsif(defined($HANDLE_DRIVER)) {
        } elsif(!defined($modules{'Bundle::DBD'})) {
            return 0;
        }
    } elsif(ref($parameters{DRIVER}) !~ /^$/) {
        return 0;
    } elsif(defined($parameters{DRIVERS})) {
        $parameters{DRIVERS} = [( $parameters{DRIVERS} )] if(ref($parameters{DRIVERS}) =~ /^$/);
        return 0 if(ref($parameters{DRIVERS}) !~ /^ARRAY$/i);
        my %DRIVERS;
        $DRIVERS{$parameters{DRIVER}} = 1;
        $DRIVERS{'DBD::'.$parameters{DRIVER}} = 1;
        $DRIVERS{'Bundle::DBD::'.$parameters{DRIVER}} = 1;
        $DRIVERS{lc($parameters{DRIVER})} = 1;
        $DRIVERS{lc('DBD::'.$parameters{DRIVER})} = 1;
        $DRIVERS{lc('Bundle::DBD::'.$parameters{DRIVER})} = 1;
        my $found = 0;
        foreach my $DRIVER (@{$parameters{DRIVERS}}) {
            return 0 if(ref($DRIVER) !~ /^$/);
            $found = 1;
            last if(defined($DRIVERS{$DRIVER}));
            last if(defined($DRIVERS{'DBD::'.$DRIVER}));
            last if(defined($DRIVERS{'Bundle::DBD::'.$DRIVER}));
            last if(defined($DRIVERS{lc($DRIVER)}));
            last if(defined($DRIVERS{lc('DBD::'.$DRIVER)}));
            last if(defined($DRIVERS{lc('Bundle::DBD::'.$DRIVER)}));
            $found = 0;
        }
        return 0 if(!$found);
        if(defined($HANDLE_DRIVER)) {
            foreach my $DRIVER (@{$parameters{DRIVERS}}) {
                return 0 if(ref($DRIVER) !~ /^$/);
                return 1 if($DRIVER eq $HANDLE_DRIVER);
            }
        } else {
            my %reduced = map { lc($_) => $modules{$_} } (keys(%modules));
            foreach my $DRIVER (@{$parameters{DRIVERS}}) {
                return 1 if(defined($modules{$DRIVER}));
                return 1 if(defined($modules{'DBD::'.$DRIVER}));
                return 1 if(defined($modules{'Bundle::DBD::'.$DRIVER}));
                return 1 if(defined($reduced{lc($DRIVER)}));
                return 1 if(defined($reduced{lc('DBD::'.$DRIVER)}));
                return 1 if(defined($reduced{lc('Bundle::DBD::'.$DRIVER)}));
            }
        }
        return 0;
    } elsif(defined($modules{$parameters{DRIVER}})) {
        if(defined($HANDLE_DRIVER)) {
            return 0 if($parameters{DRIVER} ne $HANDLE_DRIVER);
        }
    } elsif(defined($modules{'DBD::'.$parameters{DRIVER}})) {
        if(defined($HANDLE_DRIVER)) {
            return 0 if('DBD::'.$parameters{DRIVER} ne $HANDLE_DRIVER);
        }
    } elsif(!defined($modules{'Bundle::DBD::'.$parameters{DRIVER}})) {
        my %reduced = map { lc($_) => $modules{$_} } (keys(%modules));
        if(defined($reduced{lc($parameters{DRIVER})})) {
            if(defined($HANDLE_DRIVER)) {
                return 0 if(lc($parameters{DRIVER}) ne lc($HANDLE_DRIVER));
            }
        } elsif(defined($reduced{lc('DBD::'.$parameters{DRIVER})})) {
            if(defined($HANDLE_DRIVER)) {
                return 0 if(lc('DBD::'.$parameters{DRIVER}) ne lc($HANDLE_DRIVER));
            }
        } elsif(defined($reduced{lc('Bundle::DBD::'.$parameters{DRIVER})})) {
            if(defined($HANDLE_DRIVER)) {
                return 0 if(lc('Bundle::DBD::'.$parameters{DRIVER}) ne lc($HANDLE_DRIVER));
            }
        } else {
            return 0;
        }
    }
    return 1;
}

Anansi::Component::addChannel('Anansi::DatabaseComponent', 'VALIDATE_AS_APPROPRIATE' => 'validate');


=head1 NOTES

This module is designed to make it simple, easy and quite fast to code your
design in perl.  If for any reason you feel that it doesn't achieve these goals
then please let me know.  I am here to help.  All constructive criticisms are
also welcomed.

=cut


=head1 AUTHOR

Kevin Treleaven <kevin I<AT> treleaven I<DOT> net>

=cut


1;
