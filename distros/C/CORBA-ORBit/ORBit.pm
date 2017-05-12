package CORBA::ORBit;

use strict;
no strict qw(refs);
use vars qw($VERSION @ISA);

require DynaLoader;
require Error;

require CORBA::ORBit::Fixed;
require CORBA::ORBit::LongLong;
require CORBA::ORBit::ULongLong;
require CORBA::ORBit::LongDouble;
require Carp;

@ISA = qw(DynaLoader);

$VERSION = '0.4.3';

bootstrap CORBA::ORBit $VERSION;

@CORBA::Object::ISA = qw(CORBA::ORBit::RootObject);
@CORBA::TypeCode::ISA = qw(CORBA::ORBit::RootObject);

# ORBit does not properly reference count the following
#
# @CORBA::ORB::ISA = qw(CORBA::ORBit::RootObject);
# @PortableServer::POA::ISA = qw(CORBA::ORBit::RootObject);
# @PortableServer::POAManager::ISA = qw(CORBA::ORBit::RootObject);

my $IDL_PATH;

sub import {
    my $pkg = shift;

    my %keys = @_;

    if (exists $keys{'wait'}) {
	CORBA::ORBit::debug_wait();
    }

    if (exists $keys{idl_path}) {
	$IDL_PATH = $keys{idl_path};
    }

    if (exists $keys{ids}) {
	my $orb = CORBA::ORB_init ("orbit-local-orb");

	my @ids = @{$keys{ids}};
	foreach (@ids) {
	    $orb->preload($_);
	}
    }

    if (exists $keys{idl}) {
	my $orb = CORBA::ORB_init ("orbit-local-orb");

	my @idls = @{$keys{idl}};

    file:
	foreach my $file (@idls) {
	    if ($file =~ m@^/@) {
		if (-e $file) {
		    $orb->load_idl_file("$file");
		    next file;
		}
	    } else {
		my $path = defined $IDL_PATH ? $IDL_PATH : "";
		foreach ((split /:/, $path), ".") {
		    if (-e "$_/$file") {
			$orb->load_idl_file("$_/$file");
			next file;
		    }
		}
	    }
	    Carp::croak("Cannot locate IDL file: '$file'");
	}
    }
}

package CORBA::Any;

sub new {
    my ($pkg, $tc, $val) = @_;

    if (ref($tc) ne 'CORBA::TypeCode') {
	Carp::croak ('First argument to CORBA::Any::new must be a CORBA::TypeCode');
    }
    
    return bless [ $tc, $val ];
}

sub type {
    return $_[0]->[0];
}

sub value {
    return $_[0]->[1];
}

package CORBA::Object;

use Carp;

use vars qw($AUTOLOAD);
sub AUTOLOAD {
    my ($self, @rest) = @_;

    my ($method) = $AUTOLOAD =~ /.*::([^:]+)/;

    # Don't try to autoload DESTROY methods - for efficiency

    print STDERR "autoloading $method\n";
    
    if ($method eq 'DESTROY') {
	print STDERR "Autoloaded DESTROY, why?";
	return 1;
    }

    my $id = $self->_repoid;

    my $newclass = CORBA::ORBit::find_interface ($id);

    if (!defined $newclass) {
	my $iface = $self->_get_interface;
	defined $iface or croak "Can't get interface\n";
	$newclass = CORBA::ORBit::load_interface ($iface);
    }

    defined $newclass or croak "Can't get interface intformation";

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
    $retval .= "\n    ($self->{-minor}, $self->{-status})\n";
    if (exists $self->{-text}) {
	$retval .= "   $self->{-text}\n";
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

1;
__END__

=head1 NAME

CORBA::ORBit - Perl module implementing CORBA 2.0 via ORBit

=head1 AUTHOR

Owen Taylor <otaylor@redhat.com>

=head1 SYNOPSIS

  use CORBA:::ORBit idl => [ 'Account.idl' ];

=head1 DESCRIPTION

The CORBA::ORBit module is a set of bindings for ORBit.
It can read descriptions of interfaces either from an
interface repository or from idl files.

=head1 SEE ALSO

perl(1).

=cut


