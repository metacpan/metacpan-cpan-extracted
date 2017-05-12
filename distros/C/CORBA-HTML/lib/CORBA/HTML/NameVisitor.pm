
#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#

package CORBA::HTML::NameVisitor;

use strict;
use warnings;

our $VERSION = '2.60';

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    my ($parser) = @_;
    $self->{symbtab} = $parser->YYData->{symbtab};
    return $self;
}

sub _get_name {
    my $self = shift;
    my ($node, $scope) = @_;
    my $full = $node->{full};
    $full =~ s/^:://;
    my @list_name = split /::/, $full;
    my @list_scope = split /::/, $scope;
    while (@list_scope) {
        last if ($list_scope[0] ne $list_name[0]);
        shift @list_name;
        shift @list_scope;
    }
    my $name = join '::', @list_name;
    my $fragment = $node->{idf};
    $fragment = $node->{html_name} if (exists $node->{html_name});
    if (exists $node->{file_html}) {
        my $a = '<a href="' . $node->{file_html} . '#' . $fragment . '">' . $name . '</a>';
        return $a;
    }
    elsif ( $node->isa('BaseInterface') or $node->isa('ForwardBaseInterface') ) {
        my $filename = $node->{full};
        $filename =~ s/::/_/g;
        $filename .= '.html';
        my $a = '<a href="' . $filename . '#' . $fragment . '">' . $name . '</a>';
        return $a;
    }
    else {
        return $name;
    }
}

sub _get_lexeme {
    my $self = shift;
    my ($node) = @_;
    my $value = $node->{lexeme};
    $value =~ s/&/"&amp;"/g;
    $value =~ s/</"&lt;"/g;
    $value =~ s/>/"&gt;"/g;
    return $value;
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
#   3.8     Interface Declaration
#

sub visitBaseInterface {
    my $self = shift;
    my ($node, $scope) = @_;
    return $self->_get_name($node, $scope);
}

sub visitForwardBaseInterface {
    my $self = shift;
    my ($node, $scope) = @_;
    return $self->_get_name($node, $scope);
}

#
#   3.10    Constant Declaration
#

sub visitConstant {
    my $self = shift;
    my ($node, $scope) = @_;
    return $self->_get_name($node, $scope);
}

sub _Eval {
    my $self = shift;
    my ($list_expr, $scope, $type) = @_;
    my $elt = pop @{$list_expr};
    unless (ref $elt) {
        $elt = $self->{symbtab}->Lookup($elt);
    }
    if (     $elt->isa('BinaryOp') ) {
        my $right = $self->_Eval($list_expr, $scope, $type);
        my $left = $self->_Eval($list_expr, $scope, $type);
        return q{(} . $left . q{ } . $elt->{op} . q{ } . $right . q{)};
    }
    elsif (  $elt->isa('UnaryOp') ) {
        my $right = $self->_Eval($list_expr, $scope, $type);
        return $elt->{op} . $right;
    }
    elsif (  $elt->isa('Constant')
            or $elt->isa('Enum')
            or $elt->isa('Literal') ) {
        return $elt->visit($self, $scope, $type);
    }
    else {
        warn __PACKAGE__," _Eval: INTERNAL ERROR ",ref $elt,".\n";
        return undef;
    }
}

sub visitExpression {
    my $self = shift;
    my ($node, $scope) = @_;
    my @list_expr = @{$node->{list_expr}};      # create a copy
    return $self->_Eval(\@list_expr, $scope, $node->{type});
}

sub visitEnum {
    my $self = shift;
    my ($node, $attr) = @_;
    return $node->{idf};
}

sub visitIntegerLiteral {
    my $self = shift;
    my ($node) = @_;
    return $self->_get_lexeme($node);
}

sub visitStringLiteral {
    my $self = shift;
    my ($node) = @_;
    my @list = unpack 'C*', $node->{value};
    my $str = q{"};
    foreach (@list) {
        if    ($_ < 32 or $_ >= 127) {
            $str .= sprintf "\\x%02x", $_;
        }
        elsif ($_ == ord '&') {
            $str .= '&amp;';
        }
        elsif ($_ == ord '<') {
            $str .= '&lt;';
        }
        elsif ($_ == ord '>') {
            $str .= '&gt;';
        }
        else {
            $str .= chr $_;
        }
    }
    $str .= q{"};
    return $str;
}

sub visitWideStringLiteral {
    my $self = shift;
    my ($node) = @_;
    my @list = unpack 'C*', $node->{value};
    my $str = q{L"};
    foreach (@list) {
        if    ($_ < 32 or ($_ >= 128 and $_ < 256)) {
            $str .= sprintf "\\x%02x", $_;
        }
        elsif ($_ >= 256) {
            $str .= sprintf "\\u%04x", $_;
        }
        elsif ($_ == ord '&') {
            $str .= '&amp;';
        }
        elsif ($_ == ord '<') {
            $str .= '&lt;';
        }
        elsif ($_ == ord '>') {
            $str .= '&gt;';
        }
        else {
            $str .= chr $_;
        }
    }
    $str .= q{"};
    return $str;
}

sub visitCharacterLiteral {
    my $self = shift;
    my ($node) = @_;
    my @list = unpack 'C', $node->{value};
    my $c = $list[0];
    my $str = q{'};
    if    ($c < 32 or $c >= 128) {
        $str .= sprintf "\\x%02x", $c;
    }
    elsif ($c == ord '&') {
        $str .= '&amp;';
    }
    elsif ($c == ord '<') {
        $str .= '&lt;';
    }
    elsif ($c == ord '>') {
        $str .= '&gt;';
    }
    else {
        $str .= chr $c;
    }
    $str .= q{'};
    return $str;
}

sub visitWideCharacterLiteral {
    my $self = shift;
    my ($node) = @_;
    my @list = unpack 'C', $node->{value};
    my $c = $list[0];
    my $str = q{L'};
    if    ($c < 32 or ($c >= 128 and $c < 256)) {
        $str .= sprintf "\\x%02x", $c;
    }
    elsif ($c >= 256) {
        $str .= sprintf "\\u%04x", $c;
    }
    elsif ($c == ord '&') {
        $str .= '&amp;';
    }
    elsif ($c == ord '<') {
        $str .= '&lt;';
    }
    elsif ($c == ord '>') {
        $str .= '&gt;';
    }
    else {
        $str .= chr $c;
    }
    $str .= q{'};
    return $str;
}

sub visitFixedPtLiteral {
    my $self = shift;
    my ($node) = @_;
    return $self->_get_lexeme($node);
}

sub visitFloatingPtLiteral {
    my $self = shift;
    my ($node) = @_;
    return $self->_get_lexeme($node);
}

sub visitBooleanLiteral {
    my $self = shift;
    my ($node) = @_;
    return $node->{value};
}

#
#   3.11    Type Declaration
#

sub visitTypeDeclarator {
    my $self = shift;
    my ($node, $scope) = @_;
    return $self->_get_name($node, $scope);
}

sub visitNativeType {
    my $self = shift;
    my ($node, $scope) = @_;
    return $self->_get_name($node, $scope);
}

sub visitBasicType {
    my $self = shift;
    my ($node) = @_;
    return $node->{value};
}

sub visitAnyType {
    my $self = shift;
    my ($node) = @_;
    return $node->{value};
}

sub visitStructType {
    my $self = shift;
    my ($node, $scope) = @_;
    return $self->_get_name($node, $scope);
}

sub visitUnionType {
    my $self = shift;
    my ($node, $scope) = @_;
    return $self->_get_name($node, $scope);
}

sub visitEnumType {
    my $self = shift;
    my ($node, $scope) = @_;
    return $self->_get_name($node, $scope);
}

sub visitSequenceType {
    my $self = shift;
    my ($node, $scope) = @_;
    my $type = $self->_get_defn($node->{type});
    my $name = $node->{value} . '&lt;';
    $name .= $type->visit($self, $scope);
    if (exists $node->{max}) {
        $name .= q{,};
        $name .= $node->{max}->visit($self, $scope);
    }
    $name .= '&gt;';
    return $name;
}

sub visitStringType {
    my $self = shift;
    my ($node, $scope) = @_;
    if (exists $node->{max}) {
        my $name = $node->{value} . '&lt;';
        $name .= $node->{max}->visit($self, $scope);
        $name .= '&gt;';
        return $name;
    }
    else {
        return $node->{value};
    }
}

sub visitWideStringType {
    my $self = shift;
    my ($node, $scope) = @_;
    if (exists $node->{max}) {
        my $name = $node->{value} . '&lt;';
        $name .= $node->{max}->visit($self, $scope);
        $name .= '&gt;';
        return $name;
    }
    else {
        return $node->{value};
    }
}

sub visitFixedPtType {
    my $self = shift;
    my ($node, $scope) = @_;
    my $name = $node->{value} . '&lt;';
    $name .= $node->{d}->visit($self, $scope);
    $name .= q{,};
    $name .= $node->{s}->visit($self, $scope);
    $name .= '&gt;';
    return $name;
}

sub visitFixedPtConstType {
    my $self = shift;
    my ($node, $scope) = @_;
    return $node->{value};
}

sub visitVoidType {
    my $self = shift;
    my ($node) = @_;
    return $node->{value};
}

sub visitValueBaseType {
    my $self = shift;
    my ($node) = @_;
    return $node->{value};
}

#
#   3.12    Exception Declaration
#

sub visitException {
    my $self = shift;
    my ($node, $scope) = @_;
    return $self->_get_name($node, $scope);
}

#
#   3.13    Operation Declaration
#

sub visitOperation {
    my $self = shift;
    my ($node, $scope) = @_;
    return $self->_get_name($node, $scope);
}

#
#   3.14    Attribute Declaration
#

sub visitAttribute {
    my $self = shift;
    my ($node, $scope) = @_;
    return $self->_get_name($node, $scope);
}

#
#   3.17    Component Declaration
#

sub visitProvides {
    my $self = shift;
    my ($node, $scope) = @_;
    return $self->_get_name($node, $scope);
}

sub visitUses {
    my $self = shift;
    my ($node, $scope) = @_;
    return $self->_get_name($node, $scope);
}

sub visitPublishes {
    my $self = shift;
    my ($node, $scope) = @_;
    return $self->_get_name($node, $scope);
}

sub visitEmits {
    my $self = shift;
    my ($node, $scope) = @_;
    return $self->_get_name($node, $scope);
}

sub visitConsumes {
    my $self = shift;
    my ($node, $scope) = @_;
    return $self->_get_name($node, $scope);
}

#
#   3.18    Home Declaration
#

sub visitFactory {
    my $self = shift;
    my ($node, $scope) = @_;
    return $self->_get_name($node, $scope);
}

sub visitFinder {
    my $self = shift;
    my ($node, $scope) = @_;
    return $self->_get_name($node, $scope);
}

1;

