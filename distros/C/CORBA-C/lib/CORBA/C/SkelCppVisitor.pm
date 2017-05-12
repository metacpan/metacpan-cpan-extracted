
package CORBA::C::SkelCppVisitor;

use strict;
use warnings;

our $VERSION = '2.60';

use CORBA::C::SkeletonVisitor;
use base qw(CORBA::C::SkeletonVisitor);

use File::Basename;
use POSIX qw(ctime);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    my ($parser, $prefix) = @_;
    $prefix = 'skel_' if (!defined $prefix);
    $self->{prefix} = $prefix;
    $self->{srcname} = $parser->YYData->{srcname};
    $self->{srcname_size} = $parser->YYData->{srcname_size};
    $self->{srcname_mtime} = $parser->YYData->{srcname_mtime};
    $self->{symbtab} = $parser->YYData->{symbtab};
    my $filename = $prefix . basename($self->{srcname}, '.idl') . '.cpp';
    $self->parse($filename);
    $self->open_stream($filename);
    $self->{done_hash} = {};
    $self->{num_key} = 'num_skel_c';
    return $self;
}

#
#   3.5     OMG IDL Specification
#

sub visitSpecification {
    my $self = shift;
    my ($node) = @_;
    my $filename = $self->{prefix} . basename($self->{srcname}, '.idl') . '.h';
    my $FH = $self->{out};
    print $FH "/* This file was partialy generated (by ",basename($0),").*/\n";
    print $FH "/* From file : ",$self->{srcname},", ",$self->{srcname_size}," octets, ",POSIX::ctime($self->{srcname_mtime});
    print $FH " */\n";
    print $FH "\n";
    print $FH "/* START_EDIT */\n";
    print $FH $self->merge();
    print $FH "/* STOP_EDIT */\n";
    print $FH "\n";
    print $FH "extern \"C\" {\n";
    print $FH "\n";
    print $FH "#include \"",$filename,"\"\n";
    print $FH "\n";
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self);
    }
    print $FH "\n";
    print $FH "}\n";
    print $FH "\n";
    print $FH "/* end of file : ",$self->{filename}," */\n";
    close $FH;
}

1;

