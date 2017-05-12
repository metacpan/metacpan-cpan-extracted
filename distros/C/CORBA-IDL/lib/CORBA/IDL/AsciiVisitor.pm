
#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#

package CORBA::IDL::AsciiVisitor;

use strict;
use warnings;

our $VERSION = '2.60';

use File::Basename;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless($self, $class);
    my ($parser, $doc) = @_;
    $self->{srcname} = $parser->YYData->{srcname};
    $self->{symbtab} = $parser->YYData->{symbtab};
    $self->{doc} = $doc;
    my $filename = basename($self->{srcname}, '.idl') . '.ast';
    open STDOUT, '>', $filename
            or die "can't open $filename ($!).\n";
    $self->{num_key} = 'num_ascii';
    return $self;
}

sub reset_tab {
    my $self = shift;
    $self->{tab} = q{};
}

sub inc_tab {
    my $self = shift;
    $self->{tab} .= "\t";
}

sub dec_tab {
    my $self = shift;
    $self->{tab} =~ s/\t$//;
}

sub get_tab {
    my $self = shift;
    return $self->{tab};
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

sub visitType {
    my $self = shift;
    my ($type) = @_;

    if (ref $type) {
        $type->visit($self);
    }
    else {
        print $self->get_tab(), "type $type\n";
    }
}

#
#   3.5     OMG IDL Specification
#

sub visitSpecification {
    my $self = shift;
    my ($node) = @_;
    $self->reset_tab();
    print "source $self->{srcname} \n\n";
    if (exists $node->{list_import}) {
        foreach (@{$node->{list_import}}) {
            $self->_get_defn($_)->visit($self);
        }
        print "\n";
    }
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self);
    }
}

#
#   3.6     Import Declaration
#

sub visitImport {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "import $node->{value}\n";
    $self->inc_tab();
    foreach (@{$node->{list_decl}}) {
        print $self->get_tab(),$_,"\n";
    }
    $self->dec_tab();
}

#
#   3.7     Module Declaration
#

sub visitModules {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "module $node->{idf} '$node->{repos_id}'\n";
    unless (exists $node->{$self->{num_key}}) {
        $node->{$self->{num_key}} = 0;
    }
    my $module = ${$node->{list_decl}}[$node->{$self->{num_key}}];
    $module->visit($self);
    $node->{$self->{num_key}} ++;
}

sub visitModule {
    my $self = shift;
    my ($node) = @_;
    $self->inc_tab();
    $self->_xp($node);
    print $self->get_tab(), "doc: $node->{doc}\n"
            if ($self->{doc} and exists $node->{doc});
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self);
    }
    $self->dec_tab();
}

#
#   3.8     Interface Declaration
#

sub visitRegularInterface {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "interface $node->{idf} '$node->{repos_id}'\n";
    $self->inc_tab();
    $self->_xp($node);
    print $self->get_tab(), "doc: $node->{doc}\n"
            if ($self->{doc} and exists $node->{doc});
    if (exists $node->{inheritance}) {
        $node->{inheritance}->visit($self);
    }
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self);
    }
    $self->dec_tab();
}

sub visitAbstractInterface {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "interface $node->{idf} '$node->{repos_id}'\n";
    $self->inc_tab();
    $self->_xp($node);
    print $self->get_tab(), "doc: $node->{doc}\n"
            if ($self->{doc} and exists $node->{doc});
    if (exists $node->{inheritance}) {
        $node->{inheritance}->visit($self);
    }
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self);
    }
    $self->dec_tab();
}

sub visitLocalInterface {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "local interface $node->{idf} '$node->{repos_id}'\n";
    $self->inc_tab();
    $self->_xp($node);
    print $self->get_tab(), "doc: $node->{doc}\n"
            if ($self->{doc} and exists $node->{doc});
    if (exists $node->{inheritance}) {
        $node->{inheritance}->visit($self);
    }
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self);
    }
    $self->dec_tab();
}

sub visitForwardRegularInterface {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "forward interface $node->{idf}\n";
    $self->inc_tab();
    $self->_xp($node);
    $self->dec_tab();
}

sub visitForwardAbstractInterface {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "forward abstract interface $node->{idf}\n";
    $self->inc_tab();
    $self->_xp($node);
    $self->dec_tab();
}

sub visitForwardLocalInterface {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "forward local interface $node->{idf}\n";
    $self->inc_tab();
    $self->_xp($node);
    $self->dec_tab();
}

#
#   3.9     Value Declaration
#
#   3.9.1   Regular Value Type
#

sub visitRegularValue {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "regular value $node->{idf} '$node->{repos_id}'\n";
    $self->inc_tab();
    $self->_xp($node);
    print $self->get_tab(), "doc: $node->{doc}\n"
            if ($self->{doc} and exists $node->{doc});
    if (exists $node->{modifier}) {     # custom
        print $self->get_tab(), "modifier $node->{modifier}\n";
    }
    if (exists $node->{inheritance}) {
        $node->{inheritance}->visit($self);
    }
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self);
    }
    $self->dec_tab();
}

sub visitInheritanceSpec {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "inheritance spec\n";
    $self->inc_tab();
    if (exists $node->{modifier}) {     # truncatable
        print $self->get_tab(), "modifier $node->{modifier}\n";
    }
    if (exists $node->{list_value}) {
        foreach (@{$node->{list_value}}) {
            print $self->get_tab(), "value $_\n";
        }
    }
    if (exists $node->{list_interface}) {
        foreach (@{$node->{list_interface}}) {
            print $self->get_tab(), "interface $_\n";
        }
    }
    $self->dec_tab();
}

sub visitStateMembers {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "state members\n";
    $self->_xp($node);
    $self->inc_tab();
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self);
    }
    $self->dec_tab();
}

sub visitStateMember {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "$node->{modifier} $node->{idf}\n";
    $self->inc_tab();
    $self->visitType($node->{type});
    if (exists $node->{array_size}) {
        foreach (@{$node->{array_size}}) {
            $_->visit($self);           # expression
        }
    }
    $self->dec_tab();
}

sub visitInitializer {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "factory $node->{idf}\n";
    $self->inc_tab();
    $self->_xp($node);
    print $self->get_tab(), "doc: $node->{doc}\n"
            if ($self->{doc} and exists $node->{doc});
    foreach (@{$node->{list_param}}) {
        $_->visit($self);
    }
    if (exists $node->{list_raise}) {
        foreach (@{$node->{list_raise}}) {      # exception
            print $self->get_tab(), "raise $_\n";
        }
    }
    $self->dec_tab();
}

#
#   3.9.2   Boxed Value Type
#

sub visitBoxedValue {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "boxed value $node->{idf} '$node->{repos_id}'\n";
    $self->inc_tab();
    $self->_xp($node);
    print $self->get_tab(), "doc: $node->{doc}\n"
            if ($self->{doc} and exists $node->{doc});
    $self->visitType($node->{type});
    $self->dec_tab();
}

#
#   3.9.3   Abstract Value Type
#

sub visitAbstractValue {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "abstract value $node->{idf} '$node->{repos_id}'\n";
    $self->inc_tab();
    $self->_xp($node);
    print $self->get_tab(), "doc: $node->{doc}\n"
            if ($self->{doc} and exists $node->{doc});
    if (exists $node->{inheritance}) {
        $node->{inheritance}->visit($self);
    }
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self);
    }
    $self->dec_tab();
}

#
#   3.9.4   Value Forward Declaration
#

sub visitForwardRegularValue {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "forward regular value $node->{idf}\n";
    $self->inc_tab();
    $self->_xp($node);
    $self->dec_tab();
}

sub visitForwardAbstractValue {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "forward abstract value $node->{idf}\n";
    $self->inc_tab();
    $self->_xp($node);
    $self->dec_tab();
}

#
#   3.10        Constant Declaration
#

sub visitConstant {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "constant $node->{idf}\n";
    $self->inc_tab();
    $self->_xp($node);
    print $self->get_tab(), "doc: $node->{doc}\n"
            if ($self->{doc} and exists $node->{doc});
    $self->visitType($node->{type});
    $node->{value}->visit($self);       # expression
    $self->dec_tab();
}

sub visitExpression {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "expression value $node->{value}\n";
    $self->inc_tab();
    foreach my $elt (@{$node->{list_expr}}) {
        if (ref $elt) {
            if ($elt->isa('Constant')) {
                print $self->get_tab(), "constant $elt->{idf}\n";
            }
            else {
                $elt->visit($self);         # literal, unop, binop
            }
        }
        else {
            print $self->get_tab(), "entry $elt\n";
        }
    }
    $self->dec_tab();
}

sub visitUnaryOp {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "unop $node->{op}\n";
}

sub visitBinaryOp {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "binop $node->{op}\n";
}

sub visitLiteral {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "literal $node->{value}\n";
}

#
#   3.11    Type Declaration
#

sub visitTypeDeclarators {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "type declarators\n";
    $self->inc_tab();
    $self->_xp($node);
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self);
    }
    $self->dec_tab();
}

sub visitTypeDeclarator {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "type declarator $node->{idf} '$node->{repos_id}'\n";
    $self->inc_tab();
    $self->_xp($node);
    print $self->get_tab(), "doc: $node->{doc}\n"
        if ($self->{doc} and exists $node->{doc});
    $self->visitType($node->{type});
    if (exists $node->{array_size}) {
        foreach (@{$node->{array_size}}) {
            $_->visit($self);               # expression
        }
    }
    $self->dec_tab();
}

sub visitNativeType {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "native $node->{idf}\n";
    $self->inc_tab();
    $self->_xp($node);
    $self->dec_tab();
}

#
#   3.11.1  Basic Types
#

sub visitBasicType {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "basic type $node->{value}\n";
}

#
#   3.11.2  Constructed Types
#
#   3.11.2.1    Structures
#

sub visitStructType {
    my $self = shift;
    my ($node) = @_;
    if (defined $node->{list_expr}) {
        print $self->get_tab(), "struct $node->{idf} '$node->{repos_id}'\n";
        $self->inc_tab();
        $self->_xp($node);
        push @{$self->{seq}}, $node;
        foreach (@{$node->{list_expr}}) {
            $_->visit($self);               # members
        }
#       foreach (@{$node->{list_member}}) {
#           $self->_get_defn($_)->visit($self);     # member
#       }
        pop @{$self->{seq}};
        $self->dec_tab();
    }
    else {
        print $self->get_tab(), "struct $node->{idf} (forward)\n";
    }
}

sub visitMembers {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "members\n";
    $self->inc_tab();
    foreach (@{$node->{list_member}}) {
        $self->_get_defn($_)->visit($self);
    }
    $self->dec_tab();
}

sub visitMember {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "member $node->{idf}\n";
    $self->inc_tab();
    $self->visitType($node->{type});
    if (exists $node->{array_size}) {
        foreach (@{$node->{array_size}}) {
            $_->visit($self);           # expression
        }
    }
    $self->dec_tab();
}

#   3.11.2.2    Discriminated Unions
#

sub visitUnionType {
    my $self = shift;
    my ($node) = @_;
    if (defined $node->{list_expr}) {
        print $self->get_tab(), "union $node->{idf} '$node->{repos_id}'\n";
        $self->inc_tab();
        $self->_xp($node);
        print $self->get_tab(), "doc: $node->{doc}\n"
                if ($self->{doc} and exists $node->{doc});
        push @{$self->{seq}}, $node;
        foreach (@{$node->{list_expr}}) {
            $_->visit($self);               # case
        }
        pop @{$self->{seq}};
        $self->dec_tab();
    }
    else {
        print $self->get_tab(), "union $node->{idf} (forward)\n";
    }
}

sub visitCase {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "case\n";
    $self->inc_tab();
    foreach (@{$node->{list_label}}) {
        $_->visit($self);               # default or expression
    }
    $node->{element}->visit($self);
    $self->dec_tab();
}

sub visitDefault {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "default\n";
}

sub visitElement {
    my $self = shift;
    my ($node) = @_;
    $self->_get_defn($node->{value})->visit($self);     # member
}

#   3.11.2.3    Constructed Recursive Types and Forward Declarations
#

sub visitForwardStructType {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "forward struct $node->{idf}\n";
}

sub visitForwardUnionType {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "forward union $node->{idf}\n";
}

#   3.11.2.4    Enumerations
#

sub visitEnumType {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "enum $node->{idf} '$node->{repos_id}'\n";
    $self->inc_tab();
    $self->_xp($node);
    print $self->get_tab(), "doc: $node->{doc}\n"
            if ($self->{doc} and exists $node->{doc});
    foreach (@{$node->{list_expr}}) {
        $_->visit($self);               # enum
    }
    $self->dec_tab();
}

sub visitEnum {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "$node->{idf}\n";
}

#
#   3.11.3  Template Types
#

sub visitSequenceType {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "sequence\n";
    $self->inc_tab();
    my $found = 0;                      # recursion prevention
    foreach (@{$self->{seq}}) {
        if ($_ eq $node->{type}) {
            $found = 1;
            last;
        }
    }
    if ($found) {
        print $self->get_tab(), "recursion $node->{type}\n";
    }
    else {
        push @{$self->{seq}}, $node;
        $self->visitType($node->{type});
        pop @{$self->{seq}};
    }
    if (exists $node->{max}) {
        $node->{max}->visit($self);
    }
    $self->dec_tab();
}

sub visitStringType {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "string\n";
    $self->inc_tab();
    if (exists $node->{max}) {
        $node->{max}->visit($self);
    }
    $self->dec_tab();
}

sub visitWideStringType {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "wstring\n";
    $self->inc_tab();
    if (exists $node->{max}) {
        $node->{max}->visit($self);
    }
    $self->dec_tab();
}

sub visitFixedPtType {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "fixed\n";
    $self->inc_tab();
    $node->{d}->visit($self);
    $node->{s}->visit($self);
    $self->dec_tab();
}

sub visitFixedPtConstType {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "fixed\n";
}

#
#   3.12    Exception Declaration
#

sub visitException {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "exception $node->{idf} '$node->{repos_id}'\n";
    $self->inc_tab();
    $self->_xp($node);
    print $self->get_tab(), "doc: $node->{doc}\n"
            if ($self->{doc} and exists $node->{doc});
    if (exists $node->{list_expr}) {
        foreach (@{$node->{list_expr}}) {
            $_->visit($self);           # members
        }
    }
#   foreach (@{$node->{list_member}}) {
#           $self->_get_defn($_)->visit($self);     # member
#   }
    $self->dec_tab();
}

#
#   3.13    Operation Declaration
#

sub visitOperation {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "operation $node->{idf}\n";
    $self->inc_tab();
    $self->_xp($node);
    print $self->get_tab(), "doc: $node->{doc}\n"
            if ($self->{doc} and exists $node->{doc});
    if (exists $node->{attr}) {         # oneway
        print $self->get_tab(), "attribute $node->{attr}\n";
    }
    $self->visitType($node->{type});
    foreach (@{$node->{list_param}}) {
        $_->visit($self);               # parameter
    }
    if (exists $node->{list_raise}) {
        foreach (@{$node->{list_raise}}) {      # exception
            print $self->get_tab(), "raise $_\n";
        }
    }
    if (exists $node->{list_context}) {
        foreach (@{$node->{list_context}}) {    # string literal
            print $self->get_tab(), "context $_->{value}\n";
        }
    }
    $self->dec_tab();
}

sub visitParameter {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "parameter $node->{idf}\n";
    $self->inc_tab();
    $self->_xp($node);
    # in, out, inout
    print $self->get_tab(), "attribute $node->{attr}\n";
    $self->visitType($node->{type});
    $self->dec_tab();
}

sub visitVoidType {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "void\n";
}

#
#   3.14    Attribute Declaration
#

sub visitAttributes {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "attributes\n";
    $self->_xp($node);
    $self->inc_tab();
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self);
    }
    $self->dec_tab();
}

sub visitAttribute {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "attribute $node->{idf}\n";
    $self->inc_tab();
    print $self->get_tab(), "doc: $node->{doc}\n"
            if ($self->{doc} and exists $node->{doc});
    if (exists $node->{modifier}) {     # readonly
        print $self->get_tab(), "modifier $node->{modifier}\n";
    }
    if (exists $node->{list_getraise}) {
        foreach (@{$node->{list_getraise}}) {       # exception
            print $self->get_tab(), "getraise $_\n";
        }
    }
    if (exists $node->{list_setraise}) {
        foreach (@{$node->{list_setraise}}) {       # exception
            print $self->get_tab(), "setraise $_\n";
        }
    }
    $self->visitType($node->{type});
    $self->dec_tab();
}

#
#   3.15    Repository Identity Related Declarations
#

sub visitTypeId {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "typeid $node->{idf} '$node->{value}'\n";
}

sub visitTypePrefix {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "typeprefix $node->{idf} '$node->{value}'\n";
}

#
#   3.16    Event Declaration
#

sub visitRegularEvent {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "regular event $node->{idf} '$node->{repos_id}'\n";
    $self->inc_tab();
    print $self->get_tab(), "doc: $node->{doc}\n"
            if ($self->{doc} and exists $node->{doc});
    if (exists $node->{modifier}) {     # custom
        print $self->get_tab(), "modifier $node->{modifier}\n";
    }
    if (exists $node->{inheritance}) {
        $node->{inheritance}->visit($self);
    }
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self);
    }
    $self->dec_tab();
}

sub visitAbstractEvent {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "abstract event $node->{idf} '$node->{repos_id}'\n";
    $self->inc_tab();
    print $self->get_tab(), "doc: $node->{doc}\n"
            if ($self->{doc} and exists $node->{doc});
    if (exists $node->{inheritance}) {
        $node->{inheritance}->visit($self);
    }
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self);
    }
    $self->dec_tab();
}

sub visitForwardRegularEvent {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "forward regular event $node->{idf}\n";
}

sub visitForwardAbstractEvent {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "forward abstract event $node->{idf}\n";
}

#
#   3.17    Component Declaration
#

sub visitComponent {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "component $node->{idf} '$node->{repos_id}'\n";
    $self->inc_tab();
    print $self->get_tab(), "doc: $node->{doc}\n"
            if ($self->{doc} and exists $node->{doc});
    if (exists $node->{inheritance}) {
        $node->{inheritance}->visit($self);
    }
    if (exists $node->{list_support}) {
        print $self->get_tab(), "supports \n";
        foreach (@{$node->{list_support}}) {
            $_->visit($self);
        }
    }
    print $self->get_tab(), "exports \n";
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self);
    }
    $self->dec_tab();
}

sub visitForwardComponent {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "forward component $node->{idf}\n";
}

sub visitProvides {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "provides $node->{idf} $node->{type}\n";
}

sub visitUses {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "uses $node->{idf} $node->{type}\n";
    $self->inc_tab();
    if (exists $node->{modifier}) {     # multiple
        print $self->get_tab(), "modifier $node->{modifier}\n";
    }
    $self->dec_tab();
}

sub visitPublishes {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "publishes $node->{idf} $node->{type}\n";
}

sub visitEmits {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "emits $node->{idf} $node->{type}\n";
}

sub visitConsumes {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "consumes $node->{idf} $node->{type}\n";
}

#
#   3.18    Home Declaration
#

sub visitHome {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "home $node->{idf} '$node->{repos_id}'\n";
    $self->inc_tab();
    print $self->get_tab(), "doc: $node->{doc}\n"
            if ($self->{doc} and exists $node->{doc});
    if (exists $node->{inheritance}) {
        $node->{inheritance}->visit($self);
    }
    if (exists $node->{list_support}) {
        print $self->get_tab(), "supports \n";
        foreach (@{$node->{list_support}}) {
            $_->visit($self);
        }
    }
    $node->{manage}->visit($self);
    if (exists $node->{primakey}) {
        print $self->get_tab(), "primarykey $self->{primarykey}\n";
    }
    print $self->get_tab(), "exports \n";
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self);
    }
    $self->dec_tab();
}

sub visitFactory {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "factory $node->{idf}\n";
    $self->inc_tab();
    print $self->get_tab(), "doc: $node->{doc}\n"
            if ($self->{doc} and exists $node->{doc});
    foreach (@{$node->{list_param}}) {
        $_->visit($self);
    }
    if (exists $node->{list_raise}) {
        foreach (@{$node->{list_raise}}) {      # exception
            print $self->get_tab(), "raise $_\n";
        }
    }
    $self->dec_tab();
}

sub visitFinder {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "finder $node->{idf}\n";
    $self->inc_tab();
    print $self->get_tab(), "doc: $node->{doc}\n"
            if ($self->{doc} and exists $node->{doc});
    foreach (@{$node->{list_param}}) {
        $_->visit($self);
    }
    if (exists $node->{list_raise}) {
        foreach (@{$node->{list_raise}}) {      # exception
            print $self->get_tab(), "raise $_\n";
        }
    }
    $self->dec_tab();
}

#
#   XPIDL
#

sub _xp {
    my $self = shift;
    my ($node) = @_;
    if (exists $node->{declspec}) {
        print $self->get_tab(), "declspec : ",$node->{declspec},"\n";
    }
    if (exists $node->{props}) {
        print $self->get_tab(), "props : ";
        while (my ($key, $value) = each (%{$node->{props}})) {
            print $key," ";
            print "(",$value,") " if (defined $value);
        }
        print "\n";
    }
    if (exists $node->{native}) {
        print $self->get_tab(), "native : ",$node->{native},"\n";
    }
}

sub visitEllipsis {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "...\n";
}

sub visitCodeFragment {
    my $self = shift;
    my ($node) = @_;
    print $self->get_tab(), "code:\n";
    print $node->{value},"\n";
}

1;

