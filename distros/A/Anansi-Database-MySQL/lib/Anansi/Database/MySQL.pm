package Anansi::Database::MySQL;


=head1 NAME

Anansi::Database::MySQL - A manager for MySQL databases.

=head1 SYNOPSIS

    use Anansi::Database::MySQL;
    if(Anansi::Database::MySQL->validate(
        undef,
        DRIVER => 'MySQL',
    )) {
        my $OBJECT = Anansi::Database::MySQL->new();
        if($OBJECT->connect(
            undef,
            DATABASE => 'someDatabase',
            PASSWORD => 'somePassword',
            USERNAME => 'someUser',
        )) {
            my $records = $OBJECT->statement(
                undef,
                INPUT => [
                    {
                        DEFAULT => '0',
                        NAME => 'yetAnotherField',
                    }
                ],
                SQL => 'SELECT some_field, another_field FROM some_table WHERE yet_another_field = ?;',
                yetAnotherField => 123,
            );
            $OBJECT->disconnect();
            if(defined($records)) {
                if(ref($records) =~ /^ARRAY$/i) {
                    my $record = 0;
                    foreach my $record (@{$records}) {
                        next if(ref($record) !~ /^HASH$/i);
                        print "\n" if(0 < $record);
                        my $field = 0;
                        foreach my $key (keys(%{$record})) {
                            print ', ' if(0 < $field);
                            print '"'.$key.'" = "'.${record}{$key}.'"';
                            $field++;
                        }
                        $record++;
                    }
                    print "\n";
                }
            }
        }
    }

    use Anansi::Database;
    my $OBJECT = Anansi::Database->new();
    my $component = $OBJECT->addComponent(
        undef,
        DRIVER => 'MySQL',
    );
    if(defined($component)) {
        if($OBJECT->channel(
            'CONNECT',
            $component,
            DATABASE => 'someDatabase',
            PASSWORD => 'somePassword',
            USERNAME => 'someUser',
        )) {
            my $records = $OBJECT->channel(
                'STATEMENT',
                $component,
                INPUT => [
                    {
                        DEFAULT => '0',
                        NAME => 'yetAnotherField',
                    }
                ],
                SQL => 'SELECT some_field, another_field FROM some_table WHERE yet_another_field = ?;',
                yetAnotherField => 123,
            );
            if(defined($records)) {
                if(ref($records) =~ /^ARRAY$/i) {
                    my $record = 0;
                    foreach my $record (@{$records}) {
                        next if(ref($record) !~ /^HASH$/i);
                        print "\n" if(0 < $record);
                        my $field = 0;
                        foreach my $key (keys(%{$record})) {
                            print ', ' if(0 < $field);
                            print '"'.$key.'" = "'.${record}{$key}.'"';
                            $field++;
                        }
                        $record++;
                    }
                    print "\n";
                }
            }
        }
    }

=head1 DESCRIPTION

Manages MySQL databases allowing the opening and closing of MySQL databases.

=cut


our $VERSION = '0.03';

use base qw(Anansi::DatabaseComponent);


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

See L<Anansi::Class::initialise|Anansi::Class/"initialise"> for details.  Overridden by L<Anansi::DatabaseComponent::initialise|Anansi::DatabaseComponent/"initialise">.  A virtual method.

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


=head2 Anansi::DatabaseComponent

See L<Anansi::DatabaseComponent|Anansi::DatabaseComponent> for details.  A parent module of L<Anansi::Database::MySQL|Anansi::Database::MySQL>.

=cut


=head3 Anansi::Component

See L<Anansi::Component|Anansi::Component> for details.  A parent module of L<Anansi::DatabaseComponent|Anansi::DatabaseComponent>.

=cut


=head3 autoCommit

See L<Anansi::DatabaseComponent::autoCommit|Anansi::DatabaseComponent/"autoCommit"> for details.

=cut


Anansi::Component::addChannel('Anansi::Database::MySQL', 'AUTOCOMMIT' => 'Anansi::DatabaseComponent::autocommit');


=head3 bind

See L<Anansi::DatabaseComponent::bind|Anansi::DatabaseComponent/"bind"> for details.

=cut


=head3 binding

See L<Anansi::DatabaseComponent::binding|Anansi::DatabaseComponent/"binding"> for details.

=cut


=head3 commit

See L<Anansi::DatabaseComponent::commit|Anansi::DatabaseComponent/"commit"> for details.

=cut


Anansi::Component::addChannel('Anansi::Database::MySQL', 'COMMIT' => 'Anansi::DatabaseComponent::commit');


=head3 connect

See L<Anansi::DatabaseComponent::connect|Anansi::DatabaseComponent/"connect"> for details.  Overridden by L<Anansi::Database::MySQL::connect|Anansi::Database::MySQL/"connect">.

=cut


=head3 disconnect

See L<Anansi::DatabaseComponent::disconnect|Anansi::DatabaseComponent/"disconnect"> for details.

=cut


Anansi::Component::addChannel('Anansi::Database::MySQL', 'DISCONNECT' => 'Anansi::DatabaseComponent::disconnect');


=head3 finalise

See L<Anansi::DatabaseComponent::finalise|Anansi::DatabaseComponent/"finalise"> for details.  Overrides L<Anansi::Class::finalise|Anansi::Class/"finalise">.  A virtual method.

=cut


=head3 finish

See L<Anansi::DatabaseComponent::finish|Anansi::DatabaseComponent/"finish"> for details.

=cut


Anansi::Component::addChannel('Anansi::Database::MySQL', 'FINISH' => 'Anansi::DatabaseComponent::finish');


=head3 handle

See L<Anansi::DatabaseComponent::handle|Anansi::DatabaseComponent/"handle"> for details.

=cut


Anansi::Component::addChannel('Anansi::Database::MySQL', 'HANDLE' => 'Anansi::DatabaseComponent::handle');


=head3 initialise

See L<Anansi::DatabaseComponent::initialise|Anansi::DatabaseComponent/"initialise"> for details.  Overrides L<Anansi::Class::initialise|Anansi::Class/"initialise">.  A virtual method.

=cut


=head3 prepare

See L<Anansi::DatabaseComponent::prepare|Anansi::DatabaseComponent/"prepare"> for details.

=cut


Anansi::Component::addChannel('Anansi::Database::MySQL', 'PREPARE' => 'Anansi::DatabaseComponent::prepare');


=head3 rollback

See L<Anansi::DatabaseComponent::rollback|Anansi::DatabaseComponent/"rollback"> for details.

=cut


Anansi::Component::addChannel('Anansi::Database::MySQL', 'ROLLBACK' => 'Anansi::DatabaseComponent::rollback');


=head3 statement

See L<Anansi::DatabaseComponent::statement|Anansi::DatabaseComponent/"statement"> for details.

=cut


Anansi::Component::addChannel('Anansi::Database::MySQL', 'STATEMENT' => 'Anansi::DatabaseComponent::statement');


=head3 validate

See L<Anansi::DatabaseComponent::validate|Anansi::DatabaseComponent/"validate"> for details.  Overridden by L<Anansi::Database::MySQL::validate|Anansi::Database::MySQL/"validate">.

=cut


=head2 connect

    if(Anansi::Database::MySQL::connect(
        $OBJECT,
        undef,
        DATABASE => 'someDatabase',
        PASSWORD => 'somePassword',
        USERNAME => 'someUser',
    ));

    my $handle = DBI->connect('DBI:mysql:database=someDatabase', 'someUser', 'somePassword');
    if($OBJECT->connect(
        undef,
        HANDLE => $handle,
    ));

=over 4

=item self I<(Blessed Hash, Required)>

An object of this namespace.

=item channel I<(String, Required)>

The abstract identifier of a subroutine.

=item parameters I<(Hash, Optional)>

Named parameters.

=over 4

=item AutoCommit I<(String, Optional)>

Defines whether the MySQL driver automatically saves any changes made to the
B<DATABASE>.  A value of B<1> I<(one)> means changes will be saved, a value of
B<0> I<(zero)> means changes will need to be manually saved.  Changes are not
saved by default.

=item DATABASE I<(String, Optional)>

The name of the MySQL database.  A value of B<mysql> is used by default.

=item HANDLE I<(DBI::db, Optional)>

The database handle of an existing database connection.

=item HOSTNAME I<(String, Optional)>

The IP address of the computer where the MySQL B<DATABASE> is hosted.  A value
of B<127.0.0.1> is used by default.

=item PASSWORD I<(String, Optional)>

The password of the B<USERNAME> that is accessing the MySQL database.  A value
of B<undef> is used by default.

=item PORT I<(String, Optional)>

The IP address port number of the computer where the MySQL B<DATABASE> is
hosted.  A value of B<3306> I<(three three zero six)> is used by default.

=item PrintError I<(String, Optional)>

Defines whether the MySQL driver will use the B<warn> function.  A value of B<1>
I<(one)> means errors will be output using B<warn>, a value of B<0> I<(zero)>
means errors will not be output in this way.  Errors are output by default.

=item RaiseError I<(String, Optional)>

Defines whether the MySQL driver will use the B<die> function.  A value of B<1>
I<(one)> means errors will be output using B<die>, a value of B<0> I<(zero)>
means errors will not be output in this way.  Errors are output by default.

=item USERNAME I<(String, Optional)>

The user that is accessing the MySQL database.  A value of B<undef> is used by
default.

=back

=back

Overrides L<Anansi::DatabaseComponent::connect|Anansi::DatabaseComponent/"connect">.

=cut


sub connect {
    my ($self, $channel, %parameters) = @_;
    return $self->SUPER::connect(
        undef,
        INPUT => [
            {
                INPUT => [
                    'dbi:mysql:database=', {
                        DEFAULT => 'mysql',
                        NAME => 'DATABASE',
                        REF => '',
                    },
                    ';host=', {
                        DEFAULT => '127.0.0.1',
                        NAME => 'HOSTNAME',
                        REF => '',
                    },
                    ';port=', {
                        DEFAULT => '3306',
                        NAME => 'PORT',
                        REF => '',
                    }
                ],
                REF => '',
            }, {
                NAME => 'USERNAME',
                REF => '',
            }, {
                NAME => 'PASSWORD',
                REF => '',
            }, {
                INPUT => [
                    {
                        DEFAULT => 0,
                        NAME => 'AutoCommit',
                        REF => '',
                    }, {
                        DEFAULT => 1,
                        NAME => 'PrintError',
                        REF => '',
                    }, {
                        DEFAULT => 1,
                        NAME => 'RaiseError',
                        REF => '',
                    }
                ],
                REF => 'HASH',
            }
        ],
        (%parameters),
    );
}


Anansi::Component::addChannel('Anansi::Database::MySQL', 'CONNECT' => 'connect');


=head2 validate

    if(1 == Anansi::Database::MySQL::validate($OBJECT, undef));

    if(1 == Anansi::Database::MySQL::channel($OBJECT, 'VALIDATE_AS_APPROPRIATE'));

    if(1 == Anansi::Database::MySQL->validate(undef));

    if(1 == Anansi::Database::MySQL->channel('VALIDATE_AS_APPROPRIATE'));

    if(1 == $OBJECT->validate(undef, DRIVER => 'MySQL'));

    if(1 == $OBJECT->channel('VALIDATE_AS_APPROPRIATE', DRIVER => 'MySQL'));

    if(1 == Anansi::Database::MySQL->validate(undef, DRIVER => 'MySQL'));

    if(1 == Anansi::Database::MySQL->channel('VALIDATE_AS_APPROPRIATE', DRIVER => 'MySQL'));

=over 4

=item self I<(Blessed Hash B<or> String, Required)>

Either an object or a string of this namespace.

=item channel I<(String, Required)>

The abstract identifier of a subroutine.

=item parameters I<(Hash, Optional)>

Named parameters.

=over 4

=item DRIVER

When the B<DRIVER> parameter is defined as I<MySQL> then this database driver
component will be used otherwise an attempt will be made to use this driver.

=back

=back

Overrides L<Anansi::DatabaseComponent::validate|Anansi::DatabaseComponent/"validate">.

=cut


sub validate {
    my ($self, $channel, %parameters) = @_;
    $parameters{DRIVERS} = 'MySQL';
    return $self->SUPER::validate(undef, (%parameters));
}


Anansi::Component::addChannel('Anansi::Database::MySQL', 'VALIDATE_AS_APPROPRIATE' => 'validate');


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
