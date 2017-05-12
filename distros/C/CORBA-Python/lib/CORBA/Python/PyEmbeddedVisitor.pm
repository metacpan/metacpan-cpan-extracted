
#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#
#           Python Language Mapping Specification, Version 1.2 November 2002
#

package CORBA::Python::PyEmbeddedVisitor;

use strict;
use warnings;

our $VERSION = '2.60';

use CORBA::Python::ClassVisitor;
use base qw(CORBA::Python::ClassVisitor);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    my ($parser) = @_;
    $self->{srcname} = $parser->YYData->{srcname};
    $self->{srcname_size} = $parser->YYData->{srcname_size};
    $self->{srcname_mtime} = $parser->YYData->{srcname_mtime};
    $self->{symbtab} = $parser->YYData->{symbtab};
    $self->{client} = 1;
    if (exists $parser->YYData->{opt_J}) {
        $self->{base_package} = $parser->YYData->{opt_J};
    }
    else {
        $self->{base_package} = q{};
    }
    $self->{done_hash} = {};
    $self->{marshal} = 0;
    $self->{stringify} = 1;
    $self->{compare} = 1;
    $self->{id} = 1;
    $self->{old_object} = exists $parser->YYData->{opt_O};
    $self->{indent} = q{};
    $self->{out} = undef;
    $self->{import} = "import PyIDL as CORBA\n"
                    . "\n";
    $self->{scope} = undef;
    return $self;
}

1;

