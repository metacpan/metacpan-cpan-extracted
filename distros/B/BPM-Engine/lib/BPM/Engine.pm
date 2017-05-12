package BPM::Engine;

BEGIN {
    $BPM::Engine::VERSION   = '0.01';
    $BPM::Engine::AUTHORITY = 'cpan:SITETECH';
    }

use 5.010;
use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;
#use Scalar::Util ();
use BPM::Engine::Exceptions qw/throw_engine/;
use BPM::Engine::Store;
use BPM::Engine::ProcessRunner;
use BPM::Engine::Types qw/ArrayRef/;

with qw/
    MooseX::SimpleConfig
    MooseX::Traits
    BPM::Engine::Role::WithCallback
    BPM::Engine::Role::WithPersistence
    BPM::Engine::Role::WithLogger
    BPM::Engine::Handler::ProcessDefinitionHandler
    BPM::Engine::Handler::ProcessInstanceHandler
    BPM::Engine::Handler::ActivityInstanceHandler
    /;
with 'BPM::Engine::Role::EngineAPI';

#has '+configfile'       => ( default => '/etc/bpmengine/engine.yaml' );

has '+_trait_namespace' => (default => 'BPM::Engine::Trait');

has 'runner_traits' => (
    isa       => ArrayRef,
    is        => 'rw',
    default   => sub { [] },
    predicate => 'has_runner_traits'
    );

sub runner {
    my ($self, $pi) = @_;

    #Scalar::Util::weaken($self);

    my $args = {
        process_instance => $pi,
        #engine           => $self, # DEPRECATED
        logger           => $self->logger,
        };
    $args->{callback} = $self->callback      if $self->has_callback;
    $args->{traits}   = $self->runner_traits if $self->has_runner_traits;

    return BPM::Engine::ProcessRunner->new_with_traits($args);
    }

__PACKAGE__->meta->make_immutable;

1;
__END__

=pod

=encoding utf-8

=head1 NAME

BPM::Engine - Business Process Execution Engine

=head1 VERSION

0.01

=head1 SYNOPSIS

Create a new BPM engine

  use BPM::Engine;

  my $callback = sub {
      my($runner, $entity, $event, $node, $instance) = @_;
      ...
      };

  my $engine = BPM::Engine->new(
      log_dispatch_conf => 'log.conf',
      connect_info      => { dsn => $dsn, user => $user, password => $password },
      callback          => $callback
      );

Save an XPDL file with workflow process definitions, and retrieve the process 
definitions
  
  my $package = $engine->create_package('/path/to/model.xpdl');

  my @processes = $engine->get_process_definitions->all;

Create and run a process instance  
  
  my $instance = $engine->create_process_instance(
      $process, { instance_name => 'My first process run' }
      );

  $engine->start_process_instance($instance, { param1 => 'value1' });

=head1 DISCLAIMER

This is ALPHA SOFTWARE. Use at your own risk. Features may change.

=head1 DESCRIPTION

BPM::Engine is an embeddable workflow process engine with persistence. It
handles saving and loading XPDL packages in a database, and running workflow
processes.

=head1 INTERFACE

=head2 CONSTRUCTORS

=head3 B<< BPM::Engine->new(%options) >>

Creates a new bpm engine.

    $engine = BPM::Engine->new(
      connect_info => {
        dsn      => $dsn,
        user     => $user,
        password => $pass,
        %dbi_attributes,
        %extra_attributes,
        });

Possible options are:

=over

=item C<< schema => $schema // BpmEngineStore >>

L<BPM::Engine::Store> connected schema object. If not provided, one will be 
created using the C<connect_info> option.

Either C<schema> or C<connect_info> is required on object construction.

=item C<< connect_info => $dsn // ConnectInfo >>

DBIx::Class::Schema connection arguments that get passed to the C<connect()>
call to BPM::Engine::Store, as specified by the C<ConnectInfo> type in
L<BPM::Engine::Types::Internal>.

Usually a single hashref with dsn/user/password and attributes.

This attribute is only used to build the C<schema> attribute if not provided
already.

=item C<< logger => $logger // BpmEngineLogger >>

A logger object that implements the L<MooseX::LogDispatch::Interface> role,
defaults to a L<BPM::Engine::Logger> instance constructed with
C<log_dispatch_conf>.

=item C<< log_dispatch_conf => $file | $hashref >>

Optional constructor argument for L<BPM::Engine::Logger> to build the default
C<logger>, if a logger was not provided.

=item C<< callback => \&cb >>

Optional callback I<&cb> which is called on all process instance events. This 
option is passed to any C<BPM::Engine::ProcessRunner> constructor.

=item C<< runner_traits => [qw/TraitA TraitB/] // [] >>

Optional traits to be supplied to all C<BPM::Engine::ProcessRunner> objects used.

=back

=head3 B<< BPM::Engine->new_with_config(%options) >>

    $engine = BPM::Engine->new_with_config(
      configfile => "/etc/bpmengine/engine.conf"
      );

Provided by the base role L<MooseX::SimpleConfig>.  Acts just like
regular C<new()>, but also accepts an argument C<configfile> to specify
the configfile from which to load other attributes. 

=over

=item C<< configfile => $file // $ENV{HOME}/bpmengine/engine.conf >>

A file that, when passed to C<new_with_config>, is parsed using
L<Config::Any> to support any of a variety of different config formats,
detected by the file extension.  See L<Config::Any> for more details
about supported formats.

=back

Explicit arguments to C<new_with_config> will override anything loaded from the 
configfile.

=head3 B<< BPM::Engine->new_with_traits(%options) >>

Just like C<new()>, but also accepts a C<traits> argument with a list of trait 
names to apply to the engine object.

    $engine = BPM::Engine->new_with_traits(
        traits => [qw/Foo Bar/],
        schema => $schema
        );

Options, in addition to those to C<new()>:

=over

=item C<< traits => \@traitnames // [] >>

Traits live under the C<BPM::Engine::Trait> namespace by default, prefix full 
class names with a C<+>.

=back

=head3 B<< BPM::Engine->with_traits(@traits)->new(%options) >>
    
You can use the C<with_traits> class method to use traits in combination
with a configuration file. Example:

    $engine = BPM::Engine->with_traits(qw/Foo Bar/)->new_with_config(
      configfile => '/home/user/bpmengine.conf'
      );

=head2 PROCESS DEFINITION METHODS

=head3 get_packages

    $rs = $engine->get_packages();

=over 4

=item * Arguments: $cond?, \%attrs?

=item * Returns: $resultset

=back

Get a L<DBIx::Class::ResultSet|DBIx::Class::ResultSet> of 
L<BPM::Engine::Store::Result::Package> rows. Takes the same arguments as the 
L<DBIx::Class::ResultSet> C<search()> method.

=head3 get_package

    $package = $engine->get_package($package_uuid);

=over 4

=item * Arguments: \%columns_values | $uuid, \%attrs?

=item * Returns: PackageRow

=back

Takes a package UUID or a hashref and optional standard 
L<DBIC resultset attributes|DBIx::Class::ResultSet/ATTRIBUTES> and returns the 
L<BPM::Engine::Store::Result::Package> row. Delegates to 
L<DBIx::Class::ResultSet>'s C<find()> method.

Throws an exception if the package is not found.

=head3 create_package

    $package = $engine->create_package($file);

=over 4

=item * Arguments: $xpdl_file | \$string | L<IO::Handle>

=item * Returns: PackageRow

=back

Takes XPDL xml input and returns a newly created Package row. Input can be a 
file path, URL, reference to a string or io stream.

Throws an exception if inconsistencies were found in the xml.

=head3 delete_package

    $deleted_package = $engine->delete_package($package_uuid);

=over 4

=item * Arguments: \%columns_values | $uuid

=item * Returns: PackageRow

=back

Delete a package from the data store. Warning: this will also delete all 
processes and process instances related to the package.

An exception is thrown if the package is not in the database.

=head3 get_process_definitions

    $rs = $engine->get_process_definitions();

=over 4

=item * Arguments: $cond?, \%attrs?

=item * Returns: $resultset

=back

Get a L<DBIx::Class::ResultSet|DBIx::Class::ResultSet> of
L<BPM::Engine::Store::Result::Process|BPM::Engine::Store::Result::Process> rows. 
Takes the same arguments as the L<DBIx::Class::ResultSet> C<search()> method.

=head3 get_process_definition

    $process = $engine->get_process_definition($uuid);

=over 4

=item * Arguments: \%columns_values | $uuid, \%attrs?

=item * Returns: ProcessRow

=back

Takes a package UUID or a hashref and optional standard
L<DBIC resultset attributes|DBIx::Class::ResultSet/ATTRIBUTES> and returns the
corresponding L<BPM::Engine::Store::Result::Process> row. Delegates to 
L<DBIx::Class::ResultSet>'s C<find()> method.

Throws an exception if the process is not found.

=head2 PROCESS INSTANCE METHODS

=head3 get_process_instances

    $rs = $engine->get_process_instances();

=over 4

=item * Arguments: $cond?, \%attrs?

=item * Returns: $resultset

=back

Get a L<DBIx::Class::ResultSet|DBIx::Class::ResultSet> of
L<BPM::Engine::Store::Result::ProcessInstance|BPM::Engine::Store::Result::ProcessInstance> 
rows. Takes the same arguments as the L<DBIx::Class::ResultSet> C<search()> 
method.

=head3 get_process_instance

    $process_instance = $engine->get_process_instance($pi_id);

=over 4

=item * Arguments: \%columns_values | $uuid, \%attrs?

=item * Returns: ProcessInstanceRow

=back

Takes a package UUID or a hashref and optional standard
L<DBIC resultset attributes|DBIx::Class::ResultSet/ATTRIBUTES> and returns the
corresponding L<BPM::Engine::Store::Result::ProcessInstance> row. Delegates to
L<DBIx::Class::ResultSet>'s C<find()> method.

=head3 create_process_instance

    $process_instance = $engine->create_process_instance($process_id);

=over 4

=item * Arguments: $uuid | ProcessRow, \%attrs?

=item * Returns: ProcessInstanceRow

=back

Creates a new process instance, given a process id or 
L<BPM::Engine::Store::Result::Process> row object and an optional hash of 
process instance properties.

Of these process instance properties, C<instance_name> is useful to specify a 
name for the instance. A name will be auto-generated if not specified.

Returns the L<BPM::Engine::Store::Result::ProcessInstance> that was created.

=head3 start_process_instance

    $engine->start_process_instance($pi_id);

=over 4

=item * Arguments: $process_instance_id | ProcessInstanceRow, \%attrs?

=item * Returns: void

=back

Starts to run a process instance given a process instance object or id, and an 
optional hash of process instance attributes.

=head3 delete_process_instance

    $engine->delete_process_instance($pi_id);

=over 4

=item * Arguments: $process_instance_id | ProcessInstanceRow | \%columns_values

=item * Returns: ProcessInstanceRow

=back

Takes a process instance id or a process instance object, and deletes the
process instance from the data store.

An exception is thrown if the process instance is not found in the data store.

=head3 process_instance_attribute

    $attr = $engine->process_instance_attribute($pi_id, 'some_var');
    $attr = $engine->process_instance_attribute($pi_id, 'some_var', 'new_value');

=over 4

=item * Arguments: $process_instance_id | ProcessInstanceRow | \%columns_values,
$attribute_name, $attribute_value?

=item * Returns: ProcessInstanceAttributeRow

=back

Gets or sets a process instance attribute.

=head3 change_process_instance_state

    $engine->change_process_instance_state($pi_id, 'abort');

=over 4

=item * Arguments: $process_instance_id | ProcessInstanceRow | \%columns_values,
$state_transition

=item * Returns: ProcessInstanceRow

=back

Sets the new state of the process instance given a process instance id or a 
process instance object and a state transition name.

The following state transitions are possible:

=over 4

=item start

Changes the process instance state from C<open.not_running.ready> to 
C<open.running>.

=item suspend

Changes the process instance state from C<open.running> to 
C<open.not_running.suspended>.

=item resume

Changes the process instance state from C<open.not_running.suspended> to 
C<open.running>.

=item terminate

Changes the process instance state from C<open.not_running.ready>, 
C<open.running> or C<open.not_running.suspended> to 
C<closed.cancelled.terminated>. This is an end state (no more state transitions
possible).

=item abort

Changes the process instance state from C<open.not_running.ready>,
C<open.running> or C<open.not_running.suspended> to
C<closed.cancelled.aborted>. This is an end state (no more state transitions 
possible).

=item finish

Changes the process instance state from C<open.running> to C<closed.completed>. 
This is an end state (no more state transitions possible).

=back

An exception will be thrown for invalid state transitions, for example when the 
process instance is not in the right state to allow the transition.

=head2 ACTIVITY INSTANCE METHODS

=head3 get_activity_instances

    $rs = $engine->get_activity_instances();

=over 4

=item * Arguments: $cond?, \%attrs?

=item * Returns: $resultset

=back

Get a L<DBIx::Class::ResultSet|DBIx::Class::ResultSet> of
L<BPM::Engine::Store::Result::ActivityInstance|BPM::Engine::Store::Result::ActivityInstance>
rows. Takes the same arguments as the L<DBIx::Class::ResultSet> C<search()>
method.

=head3 get_activity_instance
    
    $ai = $engine->get_activity_instance($aid);

=over 4

=item * Arguments: \%columns_values | $activity_instance_id, \%attrs?

=item * Returns: ActivityInstanceRow

Takes an activity instance id or a hashref and optional standard
L<DBIC resultset attributes|DBIx::Class::ResultSet/ATTRIBUTES> and returns the
corresponding L<BPM::Engine::Store::Result::ActivityInstance> row. Delegates to
L<DBIx::Class::ResultSet>'s C<find()> method.

=back

=head3 change_activity_instance_state

    $engine->change_activity_instance_state($aid, 'finish');

=over 4

=item * Arguments: $activity_instance_id | ActivityInstanceRow | \%columns_values,
$state_transition

=item * Returns: ActivityInstanceRow

=back

Sets the new state of the activity instance given a activity instance id or a
activity instance object and a state transition name.

The following state transitions are possible:

=over 4

=item start

Changes the activity instance state from C<open.not_running.ready> to
C<open.running.not_assigned>.

=item assign

Changes the activity instance state from C<open.not_running.ready> or 
C<open.running.not_assigned> to C<open.running.assigned>.

=item reassign

Valid state transition when the activity instance state is 
C<open.running.assigned>. Does not actually change the state.

=item unassign

Changes the activity instance state from C<open.running.assigned> to 
C<open.running.not_assigned>.

=item suspend

Changes the activity instance state from C<open.running.assigned> to
C<open.not_running.suspended>.

=item resume

Changes the activity instance state from C<open.not_running.suspended> to
C<open.running.assigned>.

=item abort

Changes the activity instance state from C<open.not_running.ready> or
C<open.running.assigned> to C<closed.cancelled.aborted>. This is an end state 
(no more state transitions possible).

=item finish

Changes the activity instance state from C<open.not_running.ready> or 
C<open.running.assigned> to C<closed.completed>. This is an end state (no more 
state transitions possible).

=back

=head3 activity_instance_attribute

    $attr = $engine->activity_instance_attribute($ai_id, 'some_var');
    $attr = $engine->activity_instance_attribute($ai_id, 'some_var', 'new_value');

=over 4

=item * Arguments: $activity_instance_id | ActivityInstanceRow | \%columns_values,
$attribute_name, $attribute_value?

=item * Returns: ActivityInstanceAttributeRow

=back

Gets or sets an activity instance attribute, and returns the corresponding 
L<ActivityInstanceAttribute|BPM::Engine::Store::Result::ActivityInstanceAttribute>
row.

=head2 LOGGING METHODS

    $engine->debug('Some thing did a thing');

The following methods of the attached logger object are available to the engine:
log, debug, info, notice, warning, error, critical, alert, emergency

=head2 INTERNAL METHODS

=head3 runner

    $runner = $engine->runner($process_instance);

Returns a new L<BPM::Engine::ProcessRunner> instance with the C<runner_traits>
and C<callback> attribute applied for the specified process instance.
Internal method, used by C<start_process_instance()> and
C<change_activity_instance_state()> to advance a process instance.

=head1 DIAGNOSTICS

=head2 Exception Handling

When C<BPM::Engine> encounters an API error, it throws a
C<BPM::Engine::Exception> object.  You can catch and process these exceptions,
see L<BPM::Engine::Exception> for more information.

=head1 CONFIGURATION AND ENVIRONMENT

BPM::Engine may optionally be configured with a configuration file when
constructed using the C<new_with_config> method. See F<etc/engine.yaml> for an
example.

=head1 MAJOR DEPENDENCIES

=over 4

=item * Moose

=item * Class::Workflow

=item * BPM::XPDL

=item * DBIx::Class

=item * Template Toolkit

=item * Text::Xslate

=item * XML::LibXML

=item * Graph

=back

See the included F<Makefile.PL> for a list of all dependencies.

=head1 INCOMPATIBILITIES

None reported.

=head1 AUTHOR

Peter de Vos, C<< <sitetech@cpan.org> >>

=head1 SOURCE

You can contribute or fork this project via GitHub:

  git clone git://github.com/sitetechie/BPM-Engine.git

=head1 BUGS

Probably. Along with error conditions not being handled gracefully etc.

They will be fixed in due course as I start using this more seriously,
however in the meantime, patches are welcome :)

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc BPM::Engine

You can also look for information at:

=over 4

=item * Homepage

L<http://bpmengine.org/>

=item * Github Repository

L<http://github.com/sitetechie/BPM-Engine>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010, 2011 Peter de Vos.

This module is free software; you can redistribute it and/or modify it under the 
same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
