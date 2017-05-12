package CORBA::omniORB;

use strict;
no strict qw(refs);
use vars qw($VERSION @ISA);

require DynaLoader;
require Error;

require CORBA::omniORB::Fixed;
require CORBA::omniORB::LongLong;
require CORBA::omniORB::ULongLong;
require CORBA::omniORB::LongDouble;

@ISA = qw(DynaLoader);

$VERSION = '0.9';

bootstrap CORBA::omniORB $VERSION;

sub import {
    my $pkg = shift;

    my %keys = @_;

    if (exists $keys{ids}) {
	my $orb = CORBA::ORB_init ("omniORB4");

	my @ids = @{$keys{ids}};
	while (@ids) {
	    my ($id, $idlfile) = splice(@ids, 0, 2);

	    eval { $orb->preload($id); };
	    if( $@ ) {
		require Carp;
		Carp::carp("Could not preload '$id'");
	    }
	}
    }

    if (exists $keys{'wait'}) {
	CORBA::omniORB::debug_wait();
    }

}

END {
    foreach my $repoid (keys %CORBA::omniORB::_interfaces) {
	CORBA::omniORB::clear_interface($repoid);
    }
    my $orb = CORBA::ORB_init ("omniORB4");
    $orb->destroy();
}

package CORBA::Object;

use Carp;

use vars qw($AUTOLOAD);
sub AUTOLOAD {
    my ($self, @rest) = @_;

    my ($method) = $AUTOLOAD =~ /.*::([^:]+)/;

    # Don't try to autoload DESTROY methods - for efficiency

    if ($method eq 'DESTROY') {
	return 1;
    }

    my $id = $self->_repoid;
    if (!defined $id || $id eq '') {
	croak "Can't locate object method $method"
	    . " for object with no repository ID";
    }

    my $newclass = CORBA::omniORB::find_interface ($id);

    if (!defined $newclass) {
	my $iface = $self->_get_interface;
	defined $iface || croak "Can't get interface '$id'\n";
	$newclass = CORBA::omniORB::load_interface ($iface);
    }

    defined $newclass or die "Can't get interface information";

    my ($oldclass) = "$self" =~ /:*([^=]*)/;
    $oldclass ne $newclass or
	croak qq(Can\'t locate object method "$method" via package "$oldclass");

    bless $self, $newclass;

#       The following goto doesn't work for some reason -
#       the mark stack isn't set correctly.
#	goto &{"$ {newclass}::$ {method}"};

# This is decent, but gets the call stack wrong
    $self->$method(@rest);
}

@POA_PortableServer::ServantActivator::ISA = qw(PortableServer::ServantBase);
@POA_PortableServer::ServantLocator::ISA = qw(PortableServer::ServantBase);
@POA_PortableServer::AdapterActivator::ISA = qw(PortableServer::ServantBase);

package CORBA::Exception;

@CORBA::Exception::ISA = qw(Error);

sub stringify {
    my $self = shift;
    "Exception: ".ref($self)." ('".$self->_repoid."')";
}

sub _repoid {
    no strict qw(refs);

    my $self = shift;
    $ {ref($self)."::_repoid"};
}

package CORBA::SystemException;

sub stringify {
    my $self = shift;
    my $retval = $self->SUPER::stringify;
    $retval .= "\n    ($self->{-minor}, $self->{-status})";
    if (exists $self->{-text}) {
	$retval .= "\n   $self->{-text}";
    }
    $retval;
}

package CORBA::UserException;

sub new {
    my $pkg = shift;
    if (@_ == 1 || ref($_[0]) eq 'ARRAY') {
	$pkg->SUPER::new(@{$_[0]});
    } else {
	$pkg->SUPER::new(@_);
    }
}

package DynamicAny;

package DynamicAny::DynAny;

package DynamicAny::DynFixed;
@DynamicAny::DynFixed::ISA    = qw(DynamicAny::DynAny);
package DynamicAny::DynEnum;
@DynamicAny::DynEnum::ISA     = qw(DynamicAny::DynAny);
package DynamicAny::DynStruct;
@DynamicAny::DynStruct::ISA   = qw(DynamicAny::DynAny);
package DynamicAny::DynUnion;
@DynamicAny::DynUnion::ISA    = qw(DynamicAny::DynAny);
package DynamicAny::DynSequence;
@DynamicAny::DynSequence::ISA = qw(DynamicAny::DynAny);
package DynamicAny::DynArray;
@DynamicAny::DynArray::ISA    = qw(DynamicAny::DynAny);
package DynamicAny::DynValue;
@DynamicAny::DynArray::ISA    = qw(DynamicAny::DynAny);

package DynamicAny::DynAnyFactory;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

CORBA::omniORB - Perl module implementing CORBA 2.x via omniORB

=head1 SYNOPSIS

  use CORBA:::omniORB ids => [ 'IDL:Account/Account:1.0' => undef,
                               'IDL:Account/Counter:1.0' => undef ];

=head1 DESCRIPTION

The omniORB module is a Perl interface to the omniORB ORB.
It is meant, in the spirit of omniORB, to be a clean, simple, system,
at the expense of speed, if necessary.

=head1 Arguments to C<'use omniORB'>

Arguments in the form of key value pairs can be given after
the C<'use CORBA::omniORB'> statement.

=over 4

=item C<ids>

The value of the argument is a array reference
which contains pairs of the form:

    REPOID => FALLBACK_IDL_FILE

REPOID is the repository id of an interface to pre-load.
FALLBACK_IDL_FILE is the name of an IDL file to load the
interface from if it is not found in the interface repository.
This capability is not yet implemented.

=back

=head1 Language Mapping

See the description in L<CORBA::omniORB::mapping>.

=head1 Functions in the CORBA module

=over 4

=item ORB_init ID

=item is_nil OBJ

=back

=head1 Methods of CORBA::Any

=over 4

=item new ( TYPE, VALUE )

Constructs a new any from TYPE (of class CORBA::TypeCode) and
VALUE.

=item type

Returns the type of the any, as a CORBA::TypeCode.

=item value

Returns the value of the any.

=back

=head1 Methods of CORBA::ORB

=over 4

=item object_to_string ( OBJ )

=item list_initial_services

=item resolve_initial_references ( ID )

=item string_to_object ( STRING )

=item cdr_encode ( VAL, TC )

=item cdr_decode ( CDR, TC)

=item preload ( REPOID )

Force the interface specified by REPOID to be loaded from the
Interface Repository. Returns a true value if REPOID represents
interface (dk_Interface), false otherwise.

=item run

=item shutdown ( WAIT_FOR_COMPLETION )

=item perform_work

=item work_pending

=item destroy

=back

=head1 Methods of CORBA::Object

=over 4

=item _get_interface

=item _non_existent

=item _is_a

=item _is_equivalent

=item _hash

=item _repoid

=item _self

=back

=head1 Methods of CORBA::TypeCode

=over 4

=item new ( REPOID )

Create a new typecode object for the type with the
repository id REPOID. Support for the basic types is
provided by the pseudo-repository IDs C<'IDL:CORBA/XXX:1.0'>,
where XXX is one of Short, Long, UShort, ULong, UShort, ULong,
Float, Double, Boolean, Char, Octet, Any, TypeCode, Principal,
Object or String. Note that the capitalization here agrees
with the C++ names for the types, not with that found in
the typecode constant.

In the future, this scheme will probably be revised, or
replaced.

=item kind

=item equal ( TC )

=item equivalent ( TC )

=item get_compact_typecode

=item id

=item name

=item member_count

=item member_name ( INDEX )

=item member_type ( INDEX )

=item member_label ( INDEX )

=item discriminator_type

=item default_index

=item length

=item content_type

=item fixed_digits

=item fixed_scale

=back

=head1 Methods of PortableServer::POA

=over 4

=item _get_the_name

=item _get_the_parent

=item _get_the_POAManager

=item _get_the_activator

=item _set_the_activator

=item create_POA ( ADAPTER_NAME, MNGR_SV, ... )

=item get_servant_manager

=item set_servant_manager

=item get_servant

=item set_servant

=item activate_object

=item activate_object_with_id

=item deactivate_object

=item create_reference

=item create_reference_with_id

=item servant_to_id

=item servant_to_reference

=item reference_to_servant

=item reference_to_id

=item id_to_servant

=item id_to_reference

=back

=head1 Methods of PortableServer::POAManager

=over 4

=item activate

=item hold_requests ( WAIT_FOR_COMPLETION )

=item discard_requests ( WAIT_FOR_COMPLETION )

=item deactivate ( ETHEREALIZE_OBJECTS, WAIT_FOR_COMPLETION )

=item get_state

=back

=head1 Methods of PortableServer::Current

=over 4

=item get_POA

=item get_object_id

=back

=head1 AUTHOR

Owen Taylor <otaylor@gtk.org>

=head1 SEE ALSO

perl(1).

=cut
