package Anansi::Database;


=head1 NAME

Anansi::Database - A manager for database interaction.

=head1 SYNOPSIS

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

Manages database interactions allowing the creation, interrogation, modification
and removal of database structures and table records.

=cut


our $VERSION = '0.02';

use base qw(Anansi::ComponentManager);


=head1 METHODS

=cut


=head2 Anansi::Class

See L<Anansi::Class|Anansi::Class> for details.  A parent module of L<Anansi::Singleton|Anansi::Singleton>.

=cut


=head3 DESTROY

See L<Anansi::Class::DESTROY|Anansi::Class/"DESTROY"> for details.  Overridden by L<Anansi::Singleton::DESTROY|Anansi::Singleton/"DESTROY">.

=cut


=head3 finalise

See L<Anansi::Class::finalise|Anansi::Class/"finalise"> for details.  A virtual method.

=cut


=head3 implicate

See L<Anansi::Class::implicate|Anansi::Class/"implicate"> for details.  A virtual method.

=cut


=head3 import

See L<Anansi::Class::import|Anansi::Class/"import"> for details.

=cut


=head3 initialise

See L<Anansi::Class::initialise|Anansi::Class/"initialise"> for details.  Overridden by L<Anansi::ComponentManager::initialise|Anansi::ComponentManager/"initialise">.  A virtual method.

=cut


=head3 new

See L<Anansi::Class::new|Anansi::Class/"new"> for details.  Overridden by L<Anansi::Singleton::new|Anansi::Singleton/"new">.

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


=head2 Anansi::ComponentManager

See L<Anansi::ComponentManager|Anansi::ComponentManager> for details.  A parent module of L<Anansi::Database|Anansi::Database>.

=cut


=head3 Anansi::Singleton

See L<Anansi::Singleton|Anansi::Singleton> for details.  A parent module of L<Anansi::ComponentManager|Anansi::ComponentManager>.

=cut


=head3 addChannel

See L<Anansi::ComponentManager::addChannel|Anansi::ComponentManager/"addChannel"> for details.

=cut


=head3 addComponent

See L<Anansi::ComponentManager::addComponent|Anansi::ComponentManager/"addComponent"> for details.

=cut


=head3 channel

See L<Anansi::ComponentManager::channel|Anansi::ComponentManager/"channel"> for details.

=cut


=head3 component

See L<Anansi::ComponentManager::component|Anansi::ComponentManager/"component"> for details.

=cut


=head3 componentIdentification

See L<Anansi::ComponentManager::componentIdentification|Anansi::ComponentManager/"componentIdentification"> for details.

=cut


=head3 components

See L<Anansi::ComponentManager::components|Anansi::ComponentManager/"components"> for details.

=cut


=head3 initialise

See L<Anansi::ComponentManager::initialise|Anansi::ComponentManager/"initialise"> for details.  Overrides L<Anansi::Class::initialise|Anansi::Class/"initialise">.  A virtual method.

=cut


=head3 priorities

See L<Anansi::ComponentManager::priorities|Anansi::ComponentManager/"priorities"> for details.

=cut


=head3 reinitialise

See L<Anansi::ComponentManager::reinitialise|Anansi::ComponentManager/"reinitialise"> for details.  Overrides L<Anansi::Singleton::reinitialise|Anansi::Singleton/"reinitialise">.  A virtual method.

=cut


=head3 removeChannel

See L<Anansi::ComponentManager::removeChannel|Anansi::ComponentManager/"removeChannel"> for details.

=cut


=head3 removeComponent

See L<Anansi::ComponentManager::removeComponent|Anansi::ComponentManager/"removeComponent"> for details.

=cut


=head2 Anansi::Singleton

See L<Anansi::Singleton|Anansi::Singleton> for details.  A parent module of L<Anansi::ComponentManager|Anansi::ComponentManager>.

=cut


=head3 Anansi::Class

See L<Anansi::Class|Anansi::Class> for details.  A parent module of L<Anansi::Singleton|Anansi::Singleton>.

=cut


=head3 DESTROY

See L<Anansi::Singleton::DESTROY|Anansi::Singleton/"DESTROY"> for details.  Overrides L<Anansi::Class::DESTROY|Anansi::Class/"DESTROY">.

=cut


=head3 fixate

See L<Anansi::Singleton::fixate|Anansi::Singleton/"fixate"> for details.  A virtual method.

=cut


=head3 new

See L<Anansi::Singleton::new|Anansi::Singleton/"new"> for details.  Overrides L<Anansi::Class::new|Anansi::Class/"new">.

=cut


=head3 reinitialise

See L<Anansi::Singleton::reinitialise|Anansi::Singleton/"reinitialise"> for details.  Overridden by L<Anansi::ComponentManager::reinitialise|Anansi::ComponentManager/"reinitialise">.  A virtual method.

=cut


=head2 connect

    my $component = Anansi::Database->addComponent();
    my $connection = Anansi::Database->connect(
        undef,
        $component,
        DATABASE => 'someDatabase',
        PASSWORD => 'somePassword',
        USERNAME => 'someUsername',
    );
    if(!defined($connection));

    my $handle = DBI->connect('DBI:mysql:someDatabase', 'someUsername', 'somePassword');
    my $component = Anansi::Database->addComponent();
    my $connection = Anansi::Database->channel(
        'CONNECT',
        $component,
        HANDLE => $handle,
    );
    if(!defined($connection));

=over 4

=item self I<(Blessed Hash B<or> String, Required)>

Either an object or a string of this namespace.

=item channel I<(String, Required)>

The abstract identifier of a subroutine.

=item component I<(String, Required)>

The name associated with the component.

=item parameters I<(Hash, Optional)>

Named parameters.

=back

Attempts to load the appropriate database driver and connect to a database.
Returns B<1> I<(one)> on success and B<0> I<(zero)> on failure.  Returns an
B<undef> when an error occurs.

=cut


sub connect {
    my ($self, $channel, $component, %parameters) = @_;
    my $channels = Anansi::Database->component($component);
    return if(!defined($channels));
    my %hash = map { $_ => 1 } (@{$channels});
    return if(!defined($hash{CONNECT}));
    return Anansi::Database->component($component, 'CONNECT', %parameters);
}

Anansi::Database->addChannel('CONNECT' => 'connect');


=head2 disconnect

    my $component = Anansi::Database->addComponent();
    my $connection = Anansi::Database->connect(undef, $component);
    if(defined($connection)) (
        Anansi::Database->disconnect(undef, $component);
    }

    my $component = Anansi::Database->addComponent();
    my $connection = Anansi::Database->channel('CONNECT', $component);
    if(defined($connection)) {
        Anansi::Database->channel('DISCONNECT', $component)
    }

=over 4

=item self I<(Blessed Hash B<or> String, Required)>

Either an object or a string of this namespace.

=item channel I<(String, Required)>

The abstract identifier of a subroutine.

=item component I<(String, Required)>

The name associated with the component.

=item parameters I<(Hash, Optional)>

Named parameters.

=back

Attempts to disconnect from a database.  Returns B<1> I<(one)> on success and
B<0> I<(zero)> on failure.  Returns an B<undef> when an error occurs.

=cut


sub disconnect {
    my ($self, $channel, $component, %parameters) = @_;
    my $channels = Anansi::Database->component($component);
    return if(!defined($channels));
    my %hash = map { $_ => 1 } (@{$channels});
    return if(!defined($hash{DISCONNECT}));
    return Anansi::Database->component($component, 'DISCONNECT', %parameters);
}

Anansi::Database->addChannel('DISCONNECT' => 'disconnect');


=head2 statement

    my $result = Anansi::Database::statement(
        $OBJECT,
        undef,
        INPUT => [
            'hij' => 'someParameter',
            'klm' => 'anotherParameter'
        ],
        SQL => 'SELECT abc, def FROM some_table WHERE hij = ? AND klm = ?;',
        STATEMENT => 'someStatement',
        someParameter => 123,
        anotherParameter => 456
    );

    my $result = Anansi::Database::channel(
        $OBJECT,
        'STATEMENT',
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

    my $result = $OBJECT->channel(
        'STATEMENT',
        STATEMENT => 'someStatement',
        someParameter => 456,
        anotherParameter => 'def'
    );

=over 4

=item self I<(Blessed Hash B<or> String, Required)>

Either an object or a string of this namespace.

=item channel I<(String, Required)>

The abstract identifier of a subroutine.

=item component I<(String, Required)>

The name associated with the component.

=item parameters I<(Hash, Optional)>

Named parameters.

=over 4

=item INPUT I<(Array, Optional)>

An array of hashes with each element corresponding to an equivalent B<?>
I<(Question mark)> found within the supplied B<SQL>.  If the number of elements
is not the same as the number of B<?> I<(Question mark)>s found in the statement
then the statement is invalid.  See the L<Anansi::DatabaseComponent::bind>
method for details.

=item SQL I<(String, Optional)>

The SQL statement to execute.

=item STATEMENT I<(String, Optional)>

The name associated with a prepared SQL statement.  This is interchangeable with
the B<SQL> parameter but helps to speed up repetitive database interaction.

=back

=back

Attempts to execute the supplied B<SQL> with the supplied named parameters.
Either returns an array of retrieved record data or a B<1> I<(one)> on success
and a B<0> I<(zero)> on failure as appropriate to the SQL statement.  Returns an
B<undef> when an error occurs.

=cut


sub statement {
    my ($self, $channel, $component, %parameters) = @_;
    my $channels = Anansi::Database->component($component);
    return if(!defined($channels));
    my %hash = map { $_ => 1 } (@{$channels});
    return if(!defined($hash{STATEMENT}));
    return Anansi::Database->component($component, 'STATEMENT', %parameters);
}

Anansi::Database->addChannel('STATEMENT' => 'statement');


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
