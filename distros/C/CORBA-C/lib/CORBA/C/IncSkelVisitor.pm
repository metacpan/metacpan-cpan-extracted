
#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#
#           C Language Mapping Specification, New Edition June 1999
#

package CORBA::C::IncSkelVisitor;

use strict;
use warnings;

our $VERSION = '2.60';

use CORBA::C::IncludeVisitor;
use base qw(CORBA::C::IncludeVisitor);

use File::Basename;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    my ($parser, $incpath, $prefix) = @_;
    $self->{incpath} = $incpath || q{};
    $prefix = 'skel_' unless (defined $prefix);
    $self->{prefix} = $prefix;
    $self->{srcname} = $parser->YYData->{srcname};
    $self->{srcname_size} = $parser->YYData->{srcname_size};
    $self->{srcname_mtime} = $parser->YYData->{srcname_mtime};
    $self->{symbtab} = $parser->YYData->{symbtab};
    $self->{inc} = {};
    $self->{use_define} = 1;
    $self->{reposit} = 1;
    my $filename = $prefix . basename($self->{srcname}, '.idl') . '.h';
    $self->open_stream($filename);
    $self->{filename} = $filename;
    $self->{done_hash} = {};
    $self->{num_key} = 'num_incskel_c';
    return $self;
}

1;

