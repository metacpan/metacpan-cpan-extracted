use 5.008;
use strict;
use warnings;

package Data::Conveyor::Environment;
BEGIN {
  $Data::Conveyor::Environment::VERSION = '1.103130';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system

# ptags: DCE
use Error::Hierarchy::Util qw/assert_defined load_class/;
use Class::Scaffold::Util 'const';
use Class::Scaffold::Factory::Type;
use Class::Value;
use Data::Conveyor::Control::File;    # object() doesn't load the class (?).
use Hook::Modular;
use once;

# Bring in Class::Value right now, so $Class::Value::SkipChecks can be set
# without it being overwritten, since with framework_object and
# make_obj() Class::Value is loaded only on-demand.
use parent 'Class::Scaffold::Environment';
Class::Scaffold::Base->add_autoloaded_package('Data::Conveyor::');
Class::Scaffold::Environment::gen_class_hash_accessor('STAGE');

# ptags: /(\bconst\b[ \t]+(\w+))/
__PACKAGE__->mk_object_accessors(
    'Data::Conveyor::Control::File' => 'control',
    'Property::Lookup'              => {
        slot       => 'configurator',
        comp_mthds => [
            qw(
              max_tickets_per_dispatcher
              dispatcher_sleep
              lockpath
              ignore_locks
              soap_server
              soap_path
              soap_uri
              mutex_storage_name
              mutex_storage_args
              respect_mutex
              should_send_mail
              default_object_limit
              control_filename
              ticket_provider_clause
              storage_init_location
              )
        ]
    },
);
use constant MUTEX_STORAGE_TYPE => 'mutex_storage';
use constant PAYLOAD_VERSION    => 1;
use constant DEFAULTS           => (
    test_mode => (defined $ENV{TEST_MODE} && $ENV{TEST_MODE} == 1),

    # default_object_limit => 250,
);

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    $self->multiplex_transaction_omit(MUTEX_STORAGE_TYPE() => 1);
    ONCE {

        # require NEXT; as long as the patched NEXT.pm is in Data::Inherited -
        # i.e., until such time as Damian releases the new version, we do:
        require Data::Inherited;

        # generically generate instruction classes that look like:
        # package D::C::Ticket::Payload::Instruction::value_person_organization;
        # use parent 'Data::Conveyor::Ticket::Payload::Instruction';
        # __PACKAGE__->mk_framework_object_accessors(
        #   value_person_organization => 'value'
        # );
        # use constant name => 'organization';
        # There are other, more specialized instruction classes like 'clear'
        # or those creating techdata items - which contain several value
        # objects, not just one. There should be one instruction class for
        # every unit that can be added, deleted or updated. A person's
        # organization can be changed by itself, so we have an instruction for
        # that. However, a techdata item can only be changed as a whole - you
        # can't change a techdata item's individual field -, so we have one
        # instruction for the whole techdata item.
        # make sure the superclass is loaded so we can inherit from it
        load_class $self->INSTRUCTION_CLASS_BASE(), 1;
        for my $type ($self->generic_instruction_classes) {

            # construct instruction class
            my $class = $self->INSTRUCTION_CLASS_BASE() . '::' . $type;
            no strict 'refs';
            push @{"$class\::ISA"} => $self->INSTRUCTION_CLASS_BASE;
            my $type_method = "$class\::type";
            $::PTAGS && $::PTAGS->add_tag('type', __FILE__, __LINE__ + 1);
            *$type_method = sub { $type };

            # the class gets a $VERSION so that load_class() doesn't attempt
            # to load it, q.v. We also make an entry in %INC so
            # UNIVERSAL::require is happy. load_class() and require() could
            # be called for this class in Data::Comparable.
            $::PTAGS && $::PTAGS->add_tag('value', __FILE__, __LINE__ + 3);
            eval qq!
                package $class;
                __PACKAGE__->mk_framework_object_accessors($type => 'value');
                our \$VERSION = '0.01';
            !;
            my $file = $class . '.pm';
            $file =~ s!::!/!g;
            $INC{$file} = 1;
            die $@ if $@;
        }
    };
}

sub generic_instruction_classes {
    my $self = shift;
    $self->every_list('INSTRUCTION_CLASS_LIST');
}

sub truth {
    my ($self, $condition) = @_;
    $condition ? $self->YES : $self->NO;
}

# locks
const LO => (
    LO_READ  => 'read',
    LO_WRITE => 'write',
);

# YAML::Active phases
const YAP => (YAP_MAKE_TICKET => 'make_ticket',);

# exception ignore
const EI => ();

# context
const CTX => (
    CTX_BEFORE => 'before',
    CTX_AFTER  => 'after',
);

# ticket types
const TT => ();

# ticket status
const TS => (
    TS_RUNNING => 'R',
    TS_HOLD    => 'H',
    TS_ERROR   => 'E',
    TS_DONE    => 'D',
    TS_PENDING => 'P',
);

# tx status
const TXS => (
    TXS_RUNNING => 'R',
    TXS_IGNORE  => 'I',
    TXS_ERROR   => 'E',
);

# tx necessity
const TXN => (
    TXN_MANDATORY => 'M',
    TXN_OPTIONAL  => 'O',
);

# tx type
const TXT => (
    TXT_EXPLICIT => 'explicit',
    TXT_IMPLICIT => 'implicit',
);

# object types that can appear in the payload
const OT => (
    OT_LOCK        => 'lock',
    OT_TRANSACTION => 'transaction',
);

# commands
const CMD => ();

# stage return codes
const RC => (
    RC_OK             => 0,
    RC_ERROR          => 3,
    RC_MANUAL         => 7,
    RC_INTERNAL_ERROR => 8,
);

# ticket origins
const OR => (
    OR_TEST => 'tst',
    OR_SIF  => 'sif',
);

# ticket payload instruction commands
const IC => (
    IC_ADD    => 'add',
    IC_UPDATE => 'update',
    IC_DELETE => 'delete',
);

# stages (see ticket stage value object)
const stages => (ST_TXSEL => 'txsel',);

# stage position names
const stage_positions => (
    STAGE_START  => 'start',
    STAGE_ACTIVE => 'active',
    STAGE_END    => 'end',
);

# notify
const MSG => (
    MSG_NOTOK => 'not OK',
    MSG_OK    => 'OK',
);

# languages
const LANG => (
    LANG_DE => 'de',
    LANG_EN => 'en',
);

# --------------------------------------------------------------------------
# Start of Class::Value::String handling
# --------------------------------------------------------------------------
use constant CHARSET_HANDLER_HASH =>
  (_AUTO => 'Data::Conveyor::Charset::ASCII',);
use constant MAX_LENGTH_HASH => (_AUTO => 2000,);

sub get_charset_handler_for {
    my ($self, $object) = @_;
    our %cache;
    my $object_type =
      Class::Scaffold::Factory::Type->get_factory_type_for($object);

    # cache the every_hash result for efficiency reasons
    $cache{charset_handler_hash} = $self->every_hash('CHARSET_HANDLER_HASH')
      unless defined $cache{charset_handler_hash};
    return $cache{charset_handler_hash}{_AUTO} unless defined $object_type;
    my $class = $cache{charset_handler_hash}{$object_type}
      || $cache{charset_handler_hash}{_AUTO};

    # Cache the charset handler, because there should be only one per
    # subclass. Note that this isn't the same as making
    # Data::Conveyor::Charset::ViaHash a singleton, because there would then
    # be only one in total. We want one per subclass.
    $cache{charset_handler}{$class} ||= $class->new;
}

sub get_max_length_for {
    my ($self, $object) = @_;
    our %cache;
    my $object_type =
      Class::Scaffold::Factory::Type->get_factory_type_for($object);

    # cache the every_hash result for efficiency reasons
    $cache{max_length_hash} = $self->every_hash('MAX_LENGTH_HASH')
      unless defined $cache{max_length_hash};
    return $cache{max_length_hash}{_AUTO} unless defined $object_type;
    return $cache{max_length}{$object_type}
      if defined $cache{max_length}{$object_type};
    $cache{max_length}{$object_type} = $cache{max_length_hash}{$object_type}
      || $cache{max_length_hash}{_AUTO};
}

sub setup {
    my $self = shift;
    $self->SUPER::setup(@_);
    require Class::Value::String;
    Class::Value::String->string_delegate($self);
}

# --------------------------------------------------------------------------
# End of Class::Value::String handling
# --------------------------------------------------------------------------
# truth: how are boolean values represented in the storage? truth() uses these
# constants. Some systems might want 1 and 0 for these values.
use constant YES => 'Y';
use constant NO  => 'N';

# service interface parameters
use constant SIP_STRING    => 'string';
use constant SIP_BOOLEAN   => 'boolean';
use constant SIP_MANDATORY => 'mandatory';
use constant SIP_OPTIONAL  => 'optional';

sub FINAL_TICKET_STAGE {
    my $self = shift;
    $self->make_obj('value_ticket_stage')->new_end('ticket');
}

# for display purposes
sub STAGE_ORDER {
    local $_ = $_[0]->delegate;
    ($_->ST_TXSEL, 'ticket',);
}

# ----------------------------------------------------------------------
# class name-related code
sub STAGE_CLASS_NAME_HASH {
    local $_ = $_[0]->delegate;
    ($_->ST_TXSEL => 'Data::Conveyor::Stage::TxSelector',);
}
Class::Scaffold::Factory::Type->register_factory_type(
    exception_container => 'Data::Conveyor::Exception::Container',
    exception_handler   => 'Data::Conveyor::Exception::Handler',
    lock                => 'Data::Conveyor::Ticket::Lock',
    monitor             => 'Data::Conveyor::Monitor',
    mutex               => 'Data::Conveyor::Mutex',
    payload_common      => 'Data::Conveyor::Ticket::Payload::Common',
    payload_instruction_container =>
      'Data::Conveyor::Ticket::Payload::Instruction::Container',
    payload_instruction_factory =>
      'Data::Conveyor::Ticket::Payload::Instruction::Factory',
    payload_lock             => 'Data::Conveyor::Ticket::Payload::Lock',
    payload_transaction      => 'Data::Conveyor::Ticket::Payload::Transaction',
    service_interface_shell  => 'Data::Conveyor::Service::Interface::Shell',
    service_interface_soap   => 'Data::Conveyor::Service::Interface::SOAP',
    service_methods          => 'Data::Conveyor::Service::Methods',
    service_result_container => 'Data::Conveyor::Service::Result::Container',
    service_result_scalar    => 'Data::Conveyor::Service::Result::Scalar',
    service_result_tabular   => 'Data::Conveyor::Service::Result::Tabular',
    template_factory    => 'Data::Conveyor::Template::Factory',
    test_ticket         => 'Data::Conveyor::Test::Ticket',
    ticket              => 'Data::Conveyor::Ticket',
    ticket_dispatcher   => 'Data::Conveyor::Ticket::Dispatcher',
    ticket_dispatcher_test => 'Data::Conveyor::Ticket::Dispatcher::Test',
    ticket_facets          => 'Data::Conveyor::Ticket::Facets',
    ticket_payload         => 'Data::Conveyor::Ticket::Payload',
    test_util_loader       => 'Data::Conveyor::Test::UtilLoader',
    ticket_provider        => 'Data::Conveyor::Ticket::Provider',
    ticket_transition      => 'Data::Conveyor::Ticket::Transition',
    transaction            => 'Data::Conveyor::Ticket::Transaction',
    transaction_factory    => 'Data::Conveyor::Transaction::Factory',
    value_lock_type        => 'Data::Conveyor::Value::LockType',
    value_ticket_rc        => 'Data::Conveyor::Value::Ticket::RC',
    value_ticket_stage  => 'Data::Conveyor::Value::Ticket::Stage',
    value_ticket_status => 'Data::Conveyor::Value::Ticket::Status',
    stage_delegate           => 'Data::Conveyor::Delegate::Stage',
);
use constant DELEGATE_ACCESSORS => qw(
  stage_delegate
);
use constant STORAGE_CLASS_NAME_HASH => (

    # storage names
    STG_DC_NULL => 'Data::Conveyor::Storage::Null',
);
use constant INSTRUCTION_CLASS_BASE =>
  'Data::Conveyor::Ticket::Payload::Instruction';

# used to generate instruction classes, see init() above
sub INSTRUCTION_CLASS_LIST { () }

# ----------------------------------------------------------------------
# storage-related code
use constant STORAGE_TYPE_HASH => (
    mutex             => MUTEX_STORAGE_TYPE,
    ticket_transition => 'memory_storage',
);

sub mutex_storage {
    my $self = shift;
    $self->storage_cache->{ MUTEX_STORAGE_TYPE() } ||=
      $self->make_storage_object($self->mutex_storage_name,
        $self->mutex_storage_args);
}

# ----------------------------------------------------------------------
# how many transactions of a given object_type may occur in a ticket of a given
# ticket type?
use constant object_limit => {};

sub get_object_limit {
    my ($self, $ticket_type, $object_type) = @_;
    my $limit = $self->object_limit->{$ticket_type}{$object_type}
      || $self->default_object_limit;
    return $limit if defined $limit;
    throw Error::Hierarchy::Internal::CustomMessage(
        custom_message => sprintf
          "Can't determine object limit for ticket type [%s], object type [%s]",
        $ticket_type, $object_type
    );
}

# ----------------------------------------------------------------------
# code to make objects of various types
sub make_stage_object {
    my ($self, $stage_type, @args) = @_;
    assert_defined $stage_type, 'called without stage type.';
    my $class = $self->get_stage_class_name_for($stage_type);
    assert_defined $class,
"no stage class name found for [$stage_type]. Hint: did you define it in STAGE_CLASS_NAME_HASH?";
    load_class $class, $self->test_mode;
    $class->new(@args);
}

# like the generated make_*_object() methods, but cache the object.
sub make_ticket_transition_object {
    my $self = shift;
    our $ticket_transition_object ||= $self->make_obj(ticket_transition => @_);
}

sub allowed_dispatcher_stages {
    my $self = shift;
    $self->delegate->stages;
}

1;


__END__
=pod

=head1 NAME

Data::Conveyor::Environment - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.103130

=head1 METHODS

=head2 FINAL_TICKET_STAGE

FIXME

=head2 INSTRUCTION_CLASS_LIST

FIXME

=head2 STAGE_CLASS_NAME_HASH

FIXME

=head2 STAGE_ORDER

FIXME

=head2 allowed_dispatcher_stages

FIXME

=head2 generic_instruction_classes

FIXME

=head2 get_charset_handler_for

FIXME

=head2 get_max_length_for

FIXME

=head2 get_object_limit

FIXME

=head2 make_stage_object

FIXME

=head2 make_ticket_transition_object

FIXME

=head2 mutex_storage

FIXME

=head2 plugin_handler

FIXME

=head2 truth

FIXME

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Data-Conveyor>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<http://search.cpan.org/dist/Data-Conveyor/>.

The development version lives at L<http://github.com/hanekomu/Data-Conveyor>
and may be cloned from L<git://github.com/hanekomu/Data-Conveyor>.
Instead of sending patches, please fork this project using the standard
git and github infrastructure.

=head1 AUTHORS

=over 4

=item *

Marcel Gruenauer <marcel@cpan.org>

=item *

Florian Helmberger <fh@univie.ac.at>

=item *

Achim Adam <ac@univie.ac.at>

=item *

Mark Hofstetter <mh@univie.ac.at>

=item *

Heinz Ekker <ek@univie.ac.at>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

