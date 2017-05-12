
#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#
#           C Language Mapping Specification, New Edition June 1999
#


package CORBA::XS::SkeletonCVisitor;

use strict;
use warnings;

our $VERSION = '0.60';

use CORBA::C::SkeletonVisitor;
use base qw(CORBA::C::SkeletonVisitor);

use File::Basename;
use POSIX qw(ctime);

# needs $node->{c_name} (CnameVisitor) and $node->{c_arg} (CincludeVisitor)

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    my ($parser, $prefix) = @_;
    $prefix = 'skel_' if (!defined $prefix);
#   $self->{prefix} = $prefix;
    $self->{prefix} = q{};
    $self->{srcname} = $parser->YYData->{srcname};
    $self->{srcname_size} = $parser->YYData->{srcname_size};
    $self->{srcname_mtime} = $parser->YYData->{srcname_mtime};
    $self->{symbtab} = $parser->YYData->{symbtab};
    my $filename = $prefix . basename($self->{srcname}, '.idl') . '.c';
    $self->parse($filename);
    $self->open_stream($filename);
    $self->{done_hash} = {};
    $self->{num_key} = 'num_skel_c';
    return $self;
}

1;

