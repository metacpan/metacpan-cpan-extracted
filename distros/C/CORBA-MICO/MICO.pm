package CORBA::MICO;

use strict;
no strict qw(refs);
use vars qw($VERSION @ISA);

require DynaLoader;
require Error;

require CORBA::MICO::Fixed;
require CORBA::MICO::LongLong;
require CORBA::MICO::ULongLong;
require CORBA::MICO::LongDouble;

@ISA = qw(DynaLoader);

$VERSION = '0.6.0';

bootstrap CORBA::MICO $VERSION;

sub import {
    my $pkg = shift;

    my %keys = @_;

    if (exists $keys{ids}) {
	my $orb = CORBA::ORB_init ("mico-local-orb");

	my @ids = @{$keys{ids}};
	while (@ids) {
	    my ($id, $idlfile) = splice(@ids,0,2);

	    if (!$orb->preload($id)) {
		require Carp;
		Carp::carp("Could not preload '$_'");
	    } 
	}
    }

    if (exists $keys{'wait'}) {
	CORBA::MICO::debug_wait();
    }

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

    my $newclass = CORBA::MICO::find_interface ($id);

    if (!defined $newclass) {
	my $iface = $self->_get_interface;
	defined $iface or print "Can't get interface\n";
	$newclass = CORBA::MICO::load_interface ($iface);
    }

    defined $newclass or die "Can't get interface interformation";

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

package CORBA::MICO::GtkDispatcher;

@CORBA::MICO::GtkDispatcher::ISA = qw(CORBA::Dispatcher);

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

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

CORBA::MICO - Perl module implementing CORBA 2.0 via MICO

=head1 SYNOPSIS

  use CORBA:::MICO ids => [ 'IDL:Account/Account:1.0' => undef,
                            'IDL:Account/Counter:1.0' => undef ];

=head1 DESCRIPTION

The MICO module is a Perl interface to the MICO ORB.
It is meant, in the spirit of MICO, to be a clean, simple, system,
at the expense of speed, if necessary.

=head1 Arguments to C<'use MICO'>

Arguments in the form of key value pairs can be given after 
the C<'use MICO'> statement. 

=over 4

=item C<ids>. The value of the argument is a array reference
which contains pairs of the form:

    REPOID => FALLBACK_IDL_FILE

REPOID is the repository id of an interface to pre-load.
FALLBACK_IDL_FILE is the name of an IDL file to load the
interface from if it is not found in the interface repository.
This capability is not yet implemented.

=back

=head1 Language Mapping

See the description in L<CORBA::MICO::mapping>.

=head1 Functions in the CORBA module

=over 4

=item ORB_init ID

=back

=head1 Methods of CORBA::Any

=over 4

=item new ( TYPE, VALUE )

Constructs a new any from TYPE (of class CORBA::TypeCode) and 
VALUE.

=item type

Returns the type of the any.

=item value

Returns the value of the any.

=back

=head1 Methods of CORBA::BOA

=over 4

=item impl_is_ready ( IMPLEMENTATION_DEF )

=item deactivate_impl ( IMPLEMENTATION_DEF )

=item obj_is_ready ( OBJ, IMPLEMENTATION_DEF )

=item deactivate_obj ( OBJ )

=item dispose ( OBJ )

=back

=head1 Methods of CORBA::BOAObjectRestorer

=over 4

=item new

=item add_binders ( [ REPOID => CALLBACK ] ... )

=item add_restorers ( [ REPOID => CALLBACK ] ... )

=back

=head1 Methods of CORBA::MICO::GtkDispatcher

=over 4

=item new

=back

=head1 Methods of CORBA::Object

=over 4

=item _boa

=item _ident

=item _get_interface

=item _get_implementation

=item _self

=item _restore

=item _repoid

=item _set_repoid (  REPOID  )

Specify the repository ID of the interface that this
object implements.

=back

=head1 Methods of CORBA::ORB

=over 4

=item bind ( REPOID, [ OBJECT_TAG [, ADDR ]] )

=item BOA_init ( ID )

=item dispatcher ( DISPATCHER )

=item object_to_string ( OBJ )

=item resolve_initial_references ( ID )

=item string_to_object ( STRING )

=item run 

=item shutdown ( WAIT_FOR_COMPLETION )

=item perform_work

=item work_pending

=item preload ( REPOID )

Force the interface specified by REPOID to be loaded from the
Interface Repository. Returns a true value if the operation
succeeds.

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

=back

=head1 AUTHOR

Owen Taylor <otaylor@gtk.org>

=head1 SEE ALSO

perl(1).

=cut
