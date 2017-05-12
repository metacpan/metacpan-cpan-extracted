#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#

package CORBA::XMLSchemas::RelaxngVisitor;

use strict;
use warnings;

our $VERSION = '2.60';

use CORBA::XMLSchemas::BaseVisitor;
use base qw(CORBA::XMLSchemas::BaseVisitor);

# needs $node->{xsd_name} (XsdNameVisitor)

use File::Basename;
use POSIX qw(ctime);
use XML::DOM;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    my ($parser, $standalone, $tag_root) = @_;
    $self->{standalone} = $standalone;
    $self->{beautify} = $parser->YYData->{opt_t};
    $self->{tag_root} = $tag_root || q{};
    $self->{_rng} = 'rng';
    $self->{rng} = $parser->YYData->{opt_q} ? 'rng:' : q{};
    $self->{_xsd} = 'xs';
    $self->{xsd} = 'xs:';
    $self->{_corba} = 'corba';
    $self->{corba} = 'corba:';
    $self->{srcname} = $parser->YYData->{srcname};
    $self->{srcname_size} = $parser->YYData->{srcname_size};
    $self->{srcname_mtime} = $parser->YYData->{srcname_mtime};
    $self->{symbtab} = $parser->YYData->{symbtab};
    $self->{base} = $parser->YYData->{opt_b} || q{};
    $self->{root} = $parser->YYData->{root};
    my $filename = basename($self->{srcname}, '.idl') . '.rng';
    $self->open_stream($filename);
    $self->{done_hash} = {};
    $self->{num_key} = 'num_inc_rng';
    $self->{need_corba} = undef;
    return $self;
}

sub _ref_type {
    my $self = shift;
    my ($type, $dom_parent) = @_;

    if (       $type->isa('TypeDeclarator')
            or $type->isa('StructType')
            or $type->isa('UnionType')
            or $type->isa('EnumType')
            or $type->isa('BaseInterface') ) {
        my $ref = $self->{dom_doc}->createElement($self->{rng} . 'ref');
        $ref->setAttribute('name', $type->{xsd_name});
        $dom_parent->appendChild($ref);
    }
    else {
        my $data = $self->{dom_doc}->createElement($self->{rng} . 'data');
        $data->setAttribute('type', $type->{xsd_name});
        $dom_parent->appendChild($data);

        $type->visit($self, $data);
    }
}

sub _standalone {
    my $self = shift;
    my ($node, $dom_parent) = @_;

    if (       $self->{tag_root} eq $node->{xsd_name}
            or $node->hasProperty('start') ) {
        $self->{dom_start} = $self->{dom_doc}->createElement($self->{rng} . 'start');

        my $element = $self->{dom_doc}->createElement($self->{rng} . 'element');
        if ($node->hasProperty('start')) {
            $element->setAttribute('name', $node->getProperty('start'));
        }
        else {
            $element->setAttribute('name', $node->{xsd_name});
        }
        $self->{dom_start}->appendChild($element);

        my $ref = $self->{dom_doc}->createElement($self->{rng} . 'ref');
        $ref->setAttribute('name', $node->{xsd_name});
        $element->appendChild($ref);
    }
    elsif ($self->{standalone}) {
        my $div = $self->{dom_doc}->createElement($self->{rng} . 'div');
        $dom_parent->appendChild($div);

        my $start = $self->{dom_doc}->createElement($self->{rng} . 'start');
        $start->setAttribute('combine', 'choice');
        $div->appendChild($start);

        my $element = $self->{dom_doc}->createElement($self->{rng} . 'element');
        $element->setAttribute('name', $node->{xsd_name});
        $start->appendChild($element);

        my $ref = $self->{dom_doc}->createElement($self->{rng} . 'ref');
        $ref->setAttribute('name', $node->{xsd_name});
        $element->appendChild($ref);
    }
}

#
#   3.5     OMG IDL Specification
#

sub visitSpecification {
    my $self = shift;
    my ($node) = @_;
    my $FH = $self->{out};

    $self->{dom_doc} = new XML::DOM::Document();
    $self->{dom_parent} = $self->{dom_doc};

    my $grammar = $self->{dom_doc}->createElement($self->{rng} . 'grammar');
    $grammar->setAttribute('ns', 'http://www.omg.org/IDL-Mapped/');
    $grammar->setAttribute('datatypeLibrary', 'http://www.w3.org/2001/XMLSchema-datatypes');
    $grammar->setAttribute('xmlns:' . $self->{_xsd}, 'http://www.w3.org/2001/XMLSchema');
    if ($self->{rng}) {
        $grammar->setAttribute('xmlns:' . $self->{_rng}, 'http://relaxng.org/ns/structure/1.0');
    }
    else {
        $grammar->setAttribute('xmlns', 'http://relaxng.org/ns/structure/1.0');
    }
    $grammar->setAttribute('xmlns:' . $self->{_corba}, 'http://www.omg.org/IDL-WSDL/1.0/');
    $self->{dom_parent}->appendChild($grammar);

    if ($self->{root}->{need_corba} or $self->{root}->{need_any}) {
        my $include = $self->{dom_doc}->createElement($self->{xsd} . 'include');
        $include->setAttribute('href', $self->{base} . 'corba.rng');
        $grammar->appendChild($include);
    }

    if (exists $node->{list_import}) {
        foreach (@{$node->{list_import}}) {
            $_->visit($self, $grammar);
        }
    }
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self, $grammar);
    }

    $grammar->appendChild($self->{dom_start}) if (exists $self->{dom_start});

    if ($self->{beautify}) {
        print $FH "<!-- This file was generated (by ",$0,"). DO NOT modify it -->\n";
        print $FH "<!-- From file : ",$self->{srcname},", ",$self->{srcname_size}," octets, ",POSIX::ctime($self->{srcname_mtime});
        print $FH "-->\n";
        print $FH "\n";
        print $FH $self->_beautify($self->{dom_doc}->toString());
        print $FH "\n\n";
        print $FH "<!-- end of file : ",$self->{filename}," -->\n";
    }
    else {
        print $FH $self->{dom_doc}->toString();
    }
    close $FH;
    $self->{dom_doc}->dispose();
}

#
#   3.9     Value Declaration
#
#   See 1.2.7.10    ValueType
#

sub visitRegularValue {
    my $self = shift;
    my ($node, $dom_parent) = @_;

    foreach (@{$node->{list_decl}}) {
        my $value_element = $self->_get_defn($_);
        if (       $value_element->isa('StateMembers')
                or $value_element->isa('Initializer')
                or $value_element->isa('Operation')
                or $value_element->isa('Attributes') ) {
            next;
        }
        $value_element->visit($self, $dom_parent);
    }

    my $define = $self->{dom_doc}->createElement($self->{rng} . 'define');
    $define->setAttribute('name', $node->{xsd_name});
    $dom_parent->appendChild($define);

    my $group = $self->{dom_doc}->createElement($self->{rng} . 'group');
    $define->appendChild($group);

    if (exists $node->{inheritance} and exists $node->{inheritance}->{list_value}) {
        for (@{$node->{inheritance}->{list_value}}) {
            my $base = $self->_get_defn($_);
            next unless ($base->isa('RegularValue'));
            my $ref = $self->{dom_doc}->createElement($self->{rng} . 'ref');
            $ref->setAttribute('name', $base->{xsd_name});
            $group->appendChild($ref);
            last;
        }
    }
    else {
        $self->_value_id($group);
    }

    foreach (@{$node->{list_decl}}) {
        my $defn = $self->_get_defn($_);
        if ($defn->isa('StateMembers')) {
            $defn->visit($self, $group);
        }
    }

    $self->_standalone($node, $dom_parent);
}

sub _value_id {
    my $self = shift;
    my ($dom_parent) = @_;

    my $optional = $self->{dom_doc}->createElement($self->{rng} . 'optional');
    $dom_parent->appendChild($optional);

    my $attribute = $self->{dom_doc}->createElement($self->{rng} . 'attribute');
    $attribute->setAttribute('name', 'id');
    $optional->appendChild($attribute);

    my $data = $self->{dom_doc}->createElement($self->{rng} . 'data');
    $data->setAttribute('type', 'ID');
    $attribute->appendChild($data);
}

sub visitStateMember {
    my $self = shift;
    my ($node, $dom_parent) = @_;

    my $type = $self->_get_defn($node->{type});
    if (exists $node->{array_size}) {
        # like Array
        my $idx = scalar(@{$node->{array_size}}) - 1;
        my $current = $type;
        while ($current->isa('SequenceType')) {
            $idx ++;
            $current = $self->_get_defn($current->{type});
        }

        my $element = $self->{dom_doc}->createElement($self->{rng} . 'element');
        $element->setAttribute('name', $node->{xsd_name});
        $dom_parent->appendChild($element);

        $current = $element;
        my $first = 1;
        foreach (reverse @{$node->{array_size}}) {
            my $oneOrMore = $self->{dom_doc}->createElement($self->{rng} . 'oneOrMore');
            $current->appendChild($oneOrMore);

            my $element = $self->{dom_doc}->createElement($self->{rng} . 'element');
            my $item = ($idx != 0) ? 'item' . $idx : 'item';
            $element->setAttribute('name', $item);
            $oneOrMore->appendChild($element);

            $current = $element;
            $idx --;
            $first = 0;
        }

        if ($type->isa('SequenceType')) {
            $type->visit($self, $current);
        }
        else {
            $self->_ref_type($type, $current);
        }
    }
    else {
        if ($type->isa('RegularValue')) {
            my $choice = $self->{dom_doc}->createElement($self->{rng} . 'choice');
            $dom_parent->appendChild($choice);

            my $element = $self->{dom_doc}->createElement($self->{rng} . 'element');
            $element->setAttribute('name', $node->{xsd_name});
            $choice->appendChild($element);

            my $ref = $self->{dom_doc}->createElement($self->{rng} . 'ref');
            $ref->setAttribute('name', $type->{xsd_name});
            $element->appendChild($ref);

            $element = $self->{dom_doc}->createElement($self->{rng} . 'element');
            $element->setAttribute('name', '_REF_' . $node->{xsd_name});
            $choice->appendChild($element);

            $ref = $self->{dom_doc}->createElement($self->{rng} . 'ref');
            $ref->setAttribute('name', '_VALREF');
            $element->appendChild($ref);
        }
        else {
            # like Single
            my $element = $self->{dom_doc}->createElement($self->{rng} . 'element');
            $element->setAttribute('name', $node->{xsd_name});
            $dom_parent->appendChild($element);

            if ($type->isa('SequenceType')) {
                $type->visit($self, $element);
            }
            else {
                $self->_ref_type($type, $element);
            }
        }
    }
}

sub visitBoxedValue {
    my $self = shift;
    my ($node, $dom_parent) = @_;

    my $type = $self->_get_defn($node->{type});
    if (       $type->isa('StructType')
            or $type->isa('UnionType')
            or $type->isa('EnumType') ) {
        $type->visit($self, $dom_parent);
    }

    my $define = $self->{dom_doc}->createElement($self->{rng} . 'define');
    $define->setAttribute('name', $node->{xsd_name});
    $dom_parent->appendChild($define);

    my $group = $self->{dom_doc}->createElement($self->{rng} . 'group');
    $define->appendChild($group);

    my $element = $self->{dom_doc}->createElement($self->{rng} . 'element');
    $element->setAttribute('name', 'value');
    $group->appendChild($element);

    if ($type->isa('SequenceType')) {
        $type->visit($self, $element);
    }
    else {
        $self->_ref_type($type, $element);
    }

    $self->_value_id($define);

    $self->_standalone($node, $dom_parent);
}

#
#   3.11    Type Declaration
#
#   See 1.2.7.3     Typedefs
#

sub visitTypeDeclarator {
    my $self = shift;
    my ($node, $dom_parent) = @_;

    my $type = $self->_get_defn($node->{type});
    if (       $type->isa('StructType')
            or $type->isa('UnionType')
            or $type->isa('EnumType') ) {
        $type->visit($self, $dom_parent);
    }

    my $define = $self->{dom_doc}->createElement($self->{rng} . 'define');
    $define->setAttribute('name', $node->{xsd_name});
    $dom_parent->appendChild($define);

    if (exists $node->{array_size}) {
        #
        #   See 1.2.7.6 Arrays
        #
        warn __PACKAGE__,"::visitTypeDecalarator $node->{idf} : empty array_size.\n"
                unless (@{$node->{array_size}});

        my $idx = scalar(@{$node->{array_size}}) - 1;
        my $current = $type;
        while ($current->isa('SequenceType')) {
            $idx ++;
            $current = $self->_get_defn($current->{type});
        }

        $current = $define;
        my $first = 1;
        foreach (reverse @{$node->{array_size}}) {
            my $oneOrMore = $self->{dom_doc}->createElement($self->{rng} . 'oneOrMore');
            $current->appendChild($oneOrMore);

            my $element = $self->{dom_doc}->createElement($self->{rng} . 'element');
            my $item = ($idx != 0) ? 'item' . $idx : 'item';
            $element->setAttribute('name', $item);
            $oneOrMore->appendChild($element);

            $current = $element;
            $idx --;
            $first = 0;
        }

        if ($type->isa('SequenceType')) {
            $type->visit($self, $current);
        }
        else {
            $self->_ref_type($type, $current);
        }
    }
    else {
        if ($type->isa('SequenceType')) {
            $type->visit($self, $define);
        }
        elsif ($node->hasProperty('idref')) {
            my $data = $self->{dom_doc}->createElement($self->{rng} . 'data');
            $data->setAttribute('type', 'IDREF');
            $define->appendChild($data);
        }
        else {
            $self->_ref_type($type, $define);
        }
    }

    $self->_standalone($node, $dom_parent);
}

#
#   3.11.1  Basic Types
#

sub visitCharType {
    my $self = shift;
    my ($node, $dom_parent) = @_;

    my $param = $self->{dom_doc}->createElement($self->{rng} . 'param');
    $param->setAttribute('name', 'length');
    $dom_parent->appendChild($param);

    my $value = $self->{dom_doc}->createTextNode('1');
    $param->appendChild($value);
}

sub visitBasicType {
    # empty
}

#
#   3.11.2  Constructed Types
#
#   3.11.2.1    Structures
#
#   See 1.2.7.2     Structure
#

sub visitStructType {
    my $self = shift;
    my ($node, $dom_parent) = @_;
    return if (exists $self->{done_hash}->{$node->{xsd_name}});
    $self->{done_hash}->{$node->{xsd_name}} = 1;

    foreach (@{$node->{list_expr}}) {
        my $type = $self->_get_defn($_->{type});
        if (       $type->isa('StructType')
                or $type->isa('UnionType') ) {
            $type->visit($self, $dom_parent);
        }
    }

    my $define = $self->{dom_doc}->createElement($self->{rng} . 'define');
    $define->setAttribute('name', $node->{xsd_name});
    $dom_parent->appendChild($define);

    my $group = $self->{dom_doc}->createElement($self->{rng} . 'group');
    $define->appendChild($group);

    if ($node->hasProperty('id')) {
        my $attribute = $self->{dom_doc}->createElement($self->{rng} . 'attribute');
        $attribute->setAttribute('name', 'id');
        $group->appendChild($attribute);
        my $data = $self->{dom_doc}->createElement($self->{rng} . 'data');
        $data->setAttribute('type', 'ID');
        $attribute->appendChild($data);
    }

    foreach (@{$node->{list_member}}) {
        $self->_get_defn($_)->visit($self, $group);
    }

    $self->_standalone($node, $dom_parent);
}

sub visitMember {
    my $self = shift;
    my ($node, $dom_parent) = @_;

    my $type = $self->_get_defn($node->{type});
    while ($type->isa('TypeDeclarator') and !exists $type->{array_size}) {
        $type = $self->_get_defn($type->{type});
    }
    unless ($type->isa('SequenceType')) {
        $type = $self->_get_defn($node->{type});
    }

    my $element = $self->{dom_doc}->createElement($self->{rng} . 'element');
    if ($node->hasProperty('attr') and !exists $node->{array_size}) {
        $element = $self->{dom_doc}->createElement($self->{rng} . 'attribute');
    }
    $element->setAttribute('name', $node->{xsd_name});
    $dom_parent->appendChild($element);

    my $current = $element;
    if (exists $node->{array_size}) {
        my $idx = scalar(@{$node->{array_size}}) - 1;
        my $curr = $type;
        while ($curr->isa('SequenceType')) {
            $idx ++;
            $curr = $self->_get_defn($curr->{type});
        }
        my $first = 1;
        foreach (reverse @{$node->{array_size}}) {
            my $oneOrMore = $self->{dom_doc}->createElement($self->{rng} . 'oneOrMore');
            $current->appendChild($oneOrMore);

            my $element = $self->{dom_doc}->createElement($self->{rng} . 'element');
            my $item = ($idx != 0) ? 'item' . $idx : 'item';
            $element->setAttribute('name', $item);
            $oneOrMore->appendChild($element);

            $current = $element;
            $idx --;
            $first = 0;
        }
    }

    if ($type->isa('SequenceType')) {
        $type->visit($self, $current);
    }
    else {
        $self->_ref_type($type, $current);
    }
}

#   3.11.2.2    Discriminated Unions
#
#   See 1.2.7.4     Unions
#

sub visitUnionType {
    my $self = shift;
    my ($node, $dom_parent) = @_;
    return if (exists $self->{done_hash}->{$node->{xsd_name}});
    $self->{done_hash}->{$node->{xsd_name}} = 1;

    foreach (@{$node->{list_expr}}) {
        my $type = $self->_get_defn($_->{element}->{type});
        if (       $type->isa('StructType')
                or $type->isa('UnionType') ) {
            $type->visit($self, $dom_parent);
        }
    }

    my $type = $self->_get_defn($node->{type});

    my $define = $self->{dom_doc}->createElement($self->{rng} . 'define');
    $define->setAttribute('name', $node->{xsd_name});
    $dom_parent->appendChild($define);

    my $group = $self->{dom_doc}->createElement($self->{rng} . 'group');
    $define->appendChild($group);

    my $element = $self->{dom_doc}->createElement($self->{rng} . 'element');
    $element->setAttribute('name', 'discriminator');
    $group->appendChild($element);

    if ($type->isa('EnumType')) {
        $type->visit($self, $element, 1);
    }
    else {
        my $data = $self->{dom_doc}->createElement($self->{rng} . 'data');
        $data->setAttribute('type', $type->{xsd_name});
        $element->appendChild($data);
    }

    my $choice = $self->{dom_doc}->createElement($self->{rng} . 'choice');
    $group->appendChild($choice);

    foreach (@{$node->{list_expr}}) {
        $_->visit($self, $choice);              # case
    }

    $self->_standalone($node, $dom_parent);
}

sub visitCase {
    my $self = shift;
    my ($node, $dom_parent) = @_;

    my $str = ' case';
    my $first = 1;
    foreach (@{$node->{list_label}}) {
        $str .= ',' unless ($first);
        $str .= q{ };
        if ($_->isa('Default')) {
            $str .= 'default';
        }
        else {
            $str .= $self->_value($_);
        }
        $first = 0;
    }
    $str .= q{ };

    my $comment = $self->{dom_doc}->createComment($str);
    $dom_parent->appendChild($comment);

    $self->_get_defn($node->{element}->{value})->visit($self, $dom_parent);     # single or array
}

#   3.11.2.4    Enumerations
#
#   See 1.2.7.1     Enum
#

sub visitEnumType {
    my $self = shift;
    my ($node, $dom_parent, $indirect) = @_;
    return if (exists $self->{done_hash}->{$node->{xsd_name}});
    $self->{done_hash}->{$node->{xsd_name}} = 1;

    my $choice = $self->{dom_doc}->createElement($self->{rng} . 'choice');

    if ($indirect) {
        $dom_parent->appendChild($choice);
    }
    else {
        my $define = $self->{dom_doc}->createElement($self->{rng} . 'define');
        $define->setAttribute('name', $node->{xsd_name});
        $dom_parent->appendChild($define);

        $define->appendChild($choice);
    }

    foreach (@{$node->{list_expr}}) {
        $_->visit($self, $choice);              # enum
    }

    $self->_standalone($node, $dom_parent) unless ($indirect);
}

sub visitEnum {
    my $self = shift;
    my ($node, $dom_parent) = @_;
    my $FH = $self->{out};

    my $value = $self->{dom_doc}->createElement($self->{rng} . 'value');
    $dom_parent->appendChild($value);

    my $text = $self->{dom_doc}->createTextNode($node->{xsd_name});
    $value->appendChild($text);
}

#
#   3.11.3  Template Types
#
#   See 1.2.7.5     Sequences
#

sub visitSequenceType {
    my $self = shift;
    my ($node, $dom_parent) = @_;

    my $type = $self->_get_defn($node->{type});
    my $idx = 0;
    my $current = $type;
    while ($current->isa('SequenceType')) {
        $idx ++;
        $current = $self->_get_defn($current->{type});
    }

    my $zeroOrMore = $self->{dom_doc}->createElement($self->{rng} . 'zeroOrMore');
    $dom_parent->appendChild($zeroOrMore);

    my $element = $self->{dom_doc}->createElement($self->{rng} . 'element');
    my $item = ($idx != 0) ? 'item' . $idx : 'item';
    $element->setAttribute('name', $item);
    $zeroOrMore->appendChild($element);

    if ($type->isa('SequenceType')) {
        $type->visit($self, $element);
    }
    else {
        $self->_ref_type($type, $element);
    }
}

#
#   See 1.2.6   Primitive Types
#

sub visitStringType {
    my $self = shift;
    my ($node, $dom_parent) = @_;

    if (exists $node->{max}) {
        my $param = $self->{dom_doc}->createElement($self->{rng} . 'param');
        $param->setAttribute('name', 'maxLength');
        $dom_parent->appendChild($param);

        my $value = $self->{dom_doc}->createTextNode($self->_value($node->{max}));
        $param->appendChild($value);
    }
}

#
#   See 1.2.6   Primitive Types
#

sub visitWideStringType {
    # empty
}

#
#   See 1.2.7.9     Fixed
#

sub visitFixedPtType {
    my $self = shift;
    my ($node, $dom_parent) = @_;

    my $param = $self->{dom_doc}->createElement($self->{rng} . 'param');
    $param->setAttribute('name', 'totalDigits');
    $dom_parent->appendChild($param);

    my $value = $self->{dom_doc}->createTextNode($self->_value($node->{d}));
    $param->appendChild($value);

    $param = $self->{dom_doc}->createElement($self->{rng} . 'param');
    $param->setAttribute('name', 'fractionDigits');
    $dom_parent->appendChild($param);

    $value = $self->{dom_doc}->createTextNode($self->_value($node->{s}));
    $param->appendChild($value);
}

#
#   3.12    Exception Declaration
#
#   See 1.2.8.5     Exceptions
#

sub visitException {
    my $self = shift;
    my ($node, $dom_parent) = @_;
    return if (exists $self->{done_hash}->{$node->{xsd_name}});
    $self->{done_hash}->{$node->{xsd_name}} = 1;

    if (exists $node->{list_expr}) {
        warn __PACKAGE__,"::visitException $node->{idf} : empty list_expr.\n"
                unless (@{$node->{list_expr}});
        foreach (@{$node->{list_expr}}) {
            my $type = $self->_get_defn($_->{type});
            if (       $type->isa('StructType')
                    or $type->isa('UnionType') ) {
                $type->visit($self, $dom_parent);
            }
        }
    }

    my $define = $self->{dom_doc}->createElement($self->{rng} . 'define');
    $define->setAttribute('name', $node->{xsd_name});
    $dom_parent->appendChild($define);

    if (scalar @{$node->{list_member}}) {
        my $group = $self->{dom_doc}->createElement($self->{rng} . 'group');
        $define->appendChild($group);

        foreach (@{$node->{list_member}}) {
            $self->_get_defn($_)->visit($self, $group);
        }
    }
    else {
        my $empty = $self->{dom_doc}->createElement($self->{rng} . 'empty');
        $define->appendChild($empty);
    }

    $self->_standalone($node, $dom_parent);
}

#
#   3.13    Operation Declaration
#
#   See 1.2.8.2     Interface as Binding Operations
#

sub visitOperation {
    my $self = shift;
    my ($node, $dom_parent) = @_;

    return unless ($self->{standalone});

    if (scalar(@{$node->{list_in}}) + scalar(@{$node->{list_inout}})) {
        my $define = $self->{dom_doc}->createElement($self->{rng} . 'define');
        $define->setAttribute('name', $node->{xsd_name});
        $dom_parent->appendChild($define);

        my $group = $self->{dom_doc}->createElement($self->{rng} . 'group');
        $define->appendChild($group);

        foreach (@{$node->{list_param}}) {  # parameter
            if (       $_->{attr} eq 'in'
                    or $_->{attr} eq 'inout' ) {
                $_->visit($self, $group);
            }
        }
    }

    my $type = $self->_get_defn($node->{type});
    if (scalar(@{$node->{list_inout}}) + scalar(@{$node->{list_out}})
            or ! $type->isa('VoidType') ) {
        my $define = $self->{dom_doc}->createElement($self->{rng} . 'define');
        $define->setAttribute('name', $node->{xsd_name} . 'Response');
        $dom_parent->appendChild($define);

        my $group = $self->{dom_doc}->createElement($self->{rng} . 'group');
        $define->appendChild($group);

        unless ($type->isa('VoidType')) {
            my $element = $self->{dom_doc}->createElement($self->{rng} . 'element');
            $element->setAttribute('name', $node->{xsd_name});
            $group->appendChild($element);

            $self->_ref_type($type, $element);
        }

        foreach (@{$node->{list_param}}) {  # parameter
            if (       $_->{attr} eq 'inout'
                    or $_->{attr} eq 'out' ) {
                $_->visit($self, $group);
            }
        }
    }
}

sub visitParameter {
    my $self = shift;
    my ($node, $dom_parent) = @_;

    my $type = $self->_get_defn($node->{type});

    my $element = $self->{dom_doc}->createElement($self->{rng} . 'element');
    $element->setAttribute('name', $node->{xsd_name});
    $dom_parent->appendChild($element);

    $self->_ref_type($type, $element);
}

1;

