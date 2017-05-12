
#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#
#           CORBA to WSDL/SOAP Interworking Specification, Version 1.1 February 2005
#

package CORBA::XMLSchemas::BaseVisitor;

use strict;
use warnings;

our $VERSION = '2.60';

sub open_stream {
    my $self = shift;
    my ($filename) = @_;
    open $self->{out}, '>', $filename
            or die "can't open $filename ($!).\n";
    $self->{filename} = $filename;
}

sub _value {
    my $self = shift;
    my ($node) = @_;

    my $value = $node->{value};
    if (ref $value and $value->isa('Enum')) {
        return $value->{xsd_name};
    }
    else {
        my $str = $value;
        $str =~ s/^\+//;
        return $str;
    }
}

sub _beautify {
    my $self = shift;
    my ($in) = @_;
    my $out = q{};
    my @tab;
    foreach (split /(<[^>']*(?:'[^']*'[^>']*)*>)/, $in) {
        next unless ($_);
        pop @tab if (/^<\//);
        $out .= join(q{}, @tab) . "$_\n";
        push @tab, q{  } if (/^<[^\/?!]/ and /[^\/]>$/);
    }
    $out =~ s/\s+$//;
    return $out;
}

sub _no_mapping {
    my $self = shift;
    my ($node, $dom_parent) = @_;

    my $str = ' no mapping for ' . $node->{full} . ' (' . ref $node . ') ';
    my $comment = $self->{dom_doc}->createComment($str);
    $dom_parent->appendChild($comment);
}

sub _get_defn {
    my $self = shift;
    my ($defn) = @_;
    if (ref $defn) {
        return $defn;
    }
    else {
        return $self->{symbtab}->Lookup($defn);
    }
}

#
#   3.7     Module Declaration
#

sub visitModules {
    my $self = shift;
    my ($node, $dom_parent) = @_;
    unless (exists $node->{$self->{num_key}}) {
        $node->{$self->{num_key}} = 0;
    }
    my $module = ${$node->{list_decl}}[$node->{$self->{num_key}}];
    $module->visit($self, $dom_parent);
    $node->{$self->{num_key}} ++;
}

sub visitModule {
    my $self = shift;
    my ($node, $dom_parent) = @_;
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self, $dom_parent);
    }
}

#
#   3.8     Interface Declaration
#
#   See 1.2.8       Interfaces
#

sub visitInterface {
    my $self = shift;
    my ($node, $dom_parent) = @_;

    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self, $dom_parent);
    }
}

sub visitLocalInterface {
    shift->_no_mapping(@_);
}

sub visitForwardBaseInterface {
    # empty
}

#
#   3.9     Value Declaration
#
#   See 1.2.7.10    ValueType
#

sub visitAbstractValue {
    my $self = shift;
    my ($node, $dom_parent) = @_;

    foreach (@{$node->{list_decl}}) {
        my $value_element = $self->_get_defn($_);
        if (       $value_element->isa('Operation')
                or $value_element->isa('Attributes') ) {
            next;
        }
        $value_element->visit($self, $dom_parent);
    }
}

sub visitStateMembers {
    my $self = shift;
    my ($node, $dom_parent) = @_;
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self, $dom_parent);
    }
}

#
#   3.10    Constant Declaration
#
#   See 1.2.6.1     Constants
#

sub visitConstant {
    # empty
}

#
#   3.11    Type Declaration
#
#   See 1.2.7.3     Typedefs
#

sub visitTypeDeclarators {
    my $self = shift;
    my ($node, $dom_parent) = @_;
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self, $dom_parent);
    }
}

sub visitNativeType {
    # empty
}

#   3.11.2.3    Constructed Recursive Types and Forward Declarations
#

sub visitForwardStructType {
    # empty
}

sub visitForwardUnionType {
    # empty
}

#
#   3.14    Attribute Declaration
#

sub visitAttributes {
    my $self = shift;
    my ($node, $dom_parent) = @_;
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self, $dom_parent);
    }
}

sub visitAttribute {
    my $self = shift;
    my ($node, $dom_parent) = @_;
    $node->{_get}->visit($self, $dom_parent);
    $node->{_set}->visit($self, $dom_parent)
            if (exists $node->{_set});
}

#
#   3.15    Repository Identity Related Declarations
#

sub visitTypeId {
    # empty
}

sub visitTypePrefix {
    # empty
}

#
#   3.16    Event Declaration
#

sub visitEvent {
    shift->_no_mapping(@_);
}

#
#   3.17    Component Declaration
#

sub visitComponent {
    shift->_no_mapping(@_);
}

#
#   3.18    Home Declaration
#

sub visitHome {
    shift->_no_mapping(@_);
}

1;

