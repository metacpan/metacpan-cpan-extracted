
#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#

package CORBA::Python::HPyExtendedVisitor;

use strict;
use warnings;

our $VERSION = '2.60';

use CORBA::Python::CPyVisitor;
use base qw(CORBA::Python::CPyVisitor);

use File::Basename;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    my ($parser, $incpath) = @_;
    $self->{incpath} = $incpath || q{};
    $self->{prefix} = 'hpy_';
    $self->{old_object} = exists $parser->YYData->{opt_O};
    $self->{srcname} = $parser->YYData->{srcname};
    $self->{srcname_size} = $parser->YYData->{srcname_size};
    $self->{srcname_mtime} = $parser->YYData->{srcname_mtime};
    $self->{symbtab} = $parser->YYData->{symbtab};
    $self->{inc} = {};
    my $basename = basename($self->{srcname}, '.idl');
    my $filename = $self->{prefix} . $basename . '.h';
    $self->open_stream($filename);
    $self->{done_hash} = {};
    $self->{extended} = 1;
    $self->{num_key} = 'num_cpyext';
    $self->{error} = 'return NULL';
    $self->{num_typedef} = 0;
    $basename =~ s/\./_/g;
    $self->{root_module} = '_' . $basename;
    return $self;
}

1;

