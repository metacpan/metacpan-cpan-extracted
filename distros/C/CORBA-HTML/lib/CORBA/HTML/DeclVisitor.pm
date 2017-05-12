
#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#

package CORBA::HTML::DeclVisitor;

use strict;
use warnings;

our $VERSION = '2.60';

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    $self->{parent} = shift;
    return $self;
}

sub _get_defn {
    my $self = shift;
    my ($defn) = @_;
    if (ref $defn) {
        return $defn;
    }
    else {
        return $self->{parent}->{symbtab}->Lookup($defn);
    }
}

sub _get_name {
    my $self = shift;
    my ($node) = @_;
    unless (ref $node) {
        $node = $self->{parent}->{symbtab}->Lookup($node);
    }
    return $node->visit($self->{parent}->{html_name}, $self->{parent}->{scope});
}

sub _xp {
    my $self = shift;
    my ($node, $FH) = @_;
    if (exists $node->{declspec}) {
        print $FH "<em>__declspec(",$node->{declspec},")</em>\n";
        print $FH "  ";
    }
    if (exists $node->{props}) {
        print $FH "<em>[";
        my $first = 1;
        while (my ($key, $value) = each (%{$node->{props}})) {
            print $FH ", " unless ($first);
            print $FH $key;
            print $FH " (",$value,")" if (defined $value);
            $first = 0;
        }
        print $FH "]</em>\n";
        print $FH "  ";
    }
}

sub _xp_props {
    my $self = shift;
    my ($node, $FH) = @_;
    if (exists $node->{props}) {
        print $FH "<em>[";
        my $first = 1;
        while (my ($key, $value) = each (%{$node->{props}})) {
            print $FH ", " unless ($first);
            print $FH $key;
            print $FH " (",$value,")" if (defined $value);
            $first = 0;
        }
        print $FH "]</em> ";
    }
}

#
#   3.6     Module Declaration
#

sub visitModules {
    my $self = shift;
    my ($node, $FH) = @_;
    print $FH "<a id='",$node->{idf},"' name='",$node->{idf},"'/>\n";
    print $FH "<pre>  ";
        $self->_xp($node, $FH);
        print $FH "module <span class='decl'>",$node->{idf},"</span>\n";
    print $FH "typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
            if (exists $node->{typeid});
    print $FH "typeprefix ",$node->{idf}," \"",$node->{typeprefix},"\";\n"
            if (exists $node->{typeprefix});
    print $FH "</pre>\n";
}

#
#   3.8     Interface Declaration
#

sub visitRegularInterface {
    my $self = shift;
    my ($node, $FH) = @_;
    print $FH "<a id='",$node->{idf},"' name='",$node->{idf},"'/>\n";
    print $FH "<pre>  ";
        $self->_xp($node, $FH);
        print $FH "interface <span class='decl'>",$node->{idf},"</span>";
        if (exists $node->{inheritance} and exists $node->{inheritance}->{list_interface}) {
            print $FH " : ";
            my $first = 1;
            foreach (@{$node->{inheritance}->{list_interface}}) {
                print $FH ", " unless ($first);
                print $FH $self->_get_name($_);
                $first = 0;
            }
        }
        print $FH ";\n";
    print $FH "typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
            if (exists $node->{typeid});
    print $FH "typeprefix ",$node->{idf}," \"",$node->{typeprefix},"\";\n"
            if (exists $node->{typeprefix});
    print $FH "</pre>\n";
}

sub visitAbstractInterface {
    my $self = shift;
    my ($node, $FH) = @_;
    print $FH "<a id='",$node->{idf},"' name='",$node->{idf},"'/>\n";
    print $FH "<pre>  ";
        $self->_xp($node, $FH);
        print $FH "abstract interface <span class='decl'>",$node->{idf},"</span>";
        if (exists $node->{inheritance} and exists $node->{inheritance}->{list_interface}) {
            print $FH " : ";
            my $first = 1;
            foreach (@{$node->{inheritance}->{list_interface}}) {
                print $FH ", " unless ($first);
                print $FH $self->_get_name($_);
                $first = 0;
            }
        }
        print $FH ";\n";
    print $FH "typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
            if (exists $node->{typeid});
    print $FH "typeprefix ",$node->{idf}," \"",$node->{typeprefix},"\";\n"
            if (exists $node->{typeprefix});
    print $FH "</pre>\n";
}

sub visitLocalInterface {
    my $self = shift;
    my ($node, $FH) = @_;
    print $FH "<a id='",$node->{idf},"' name='",$node->{idf},"'/>\n";
    print $FH "<pre>  ";
        $self->_xp($node, $FH);
        print $FH "local interface <span class='decl'>",$node->{idf},"</span>";
        if (exists $node->{inheritance} and exists $node->{inheritance}->{list_interface}) {
            print $FH " : ";
            my $first = 1;
            foreach (@{$node->{inheritance}->{list_interface}}) {
                print $FH ", " unless ($first);
                print $FH $self->_get_name($_);
                $first = 0;
            }
        }
        print $FH ";\n";
    print $FH "typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
            if (exists $node->{typeid});
    print $FH "typeprefix ",$node->{idf}," \"",$node->{typeprefix},"\";\n"
            if (exists $node->{typeprefix});
    print $FH "</pre>\n";
}

#
#   3.9     Value Declaration
#
#   3.9.1   Regular Value Type
#

sub visitRegularValue {
    my $self = shift;
    my ($node, $FH) = @_;
    print $FH "<a id='",$node->{idf},"' name='",$node->{idf},"'/>\n";
    print $FH "<pre>  ";
        $self->_xp($node, $FH);
        print $FH "custom "
                if (exists $node->{modifier});
        print $FH "value <span class='decl'>",$node->{idf},"</span>";
        if (exists $node->{inheritance}) {
            my $inheritance = $node->{inheritance};
            print $FH " : ";
            if (exists $inheritance->{list_value}) {
                print $FH "truncatable " if (exists $inheritance->{modifier});
                my $first = 1;
                foreach (@{$inheritance->{list_value}}) {
                    print $FH ", " if (! $first);
                    print $FH $self->_get_name($_);
                    $first = 0;
                }
                print $FH " ";
            }
            if (exists $inheritance->{list_interface}) {
                print $FH "support ";
                my $first = 1;
                foreach (@{$inheritance->{list_interface}}) {
                    print $FH ", " if (! $first);
                    print $FH $self->_get_name($_);
                    $first = 0;
                }
            }
        }
        print $FH ";\n";
    print $FH "typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
            if (exists $node->{typeid});
    print $FH "typeprefix ",$node->{idf}," \"",$node->{typeprefix},"\";\n"
            if (exists $node->{typeprefix});
    print $FH "</pre>\n";
}

sub visitStateMember {
    my $self = shift;
    my ($node, $FH) = @_;
    print $FH "<pre>  ";
        $self->_xp($node, $FH);
        print $FH $node->{modifier}," ";
        print $FH $self->_get_name($node->{type});
        print $FH " <span class='decl'>",$node->{idf},"</span>";
        if (exists $node->{array_size}) {
            foreach (@{$node->{array_size}}) {
                print $FH "[";
                $_->visit($self, $FH);          # expression
                print $FH "]";
            }
        }
        print $FH ";\n";
    print $FH "typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
            if (exists $node->{typeid});
    print $FH "</pre>\n";
}

sub visitInitializer {
    my $self = shift;
    my ($node, $FH) = @_;
    print $FH "<pre>  ";
        $self->_xp($node, $FH);
        print $FH "factory <span class='decl'>",$node->{idf},"</span> (";
    my $first = 1;
    foreach (@{$node->{list_param}}) {  # parameter
        print $FH "," unless ($first);
        print $FH "\n";
        print $FH "    ";
        $self->_xp_props($_, $FH);
        print $FH $_->{attr}," ",$self->_get_name($_->{type})," ",$_->{idf};
        $first = 0;
    }
    print $FH "\n";
    print $FH "  )";
    if (exists $node->{list_raise}) {
        print $FH " raises(";
        my $first = 1;
        foreach (@{$node->{list_raise}}) {  # exception
            print $FH ", " unless ($first);
            print $FH $self->_get_name($_);
            $first = 0;
        }
        print $FH ")";
    }
    print $FH ";\n";
    print $FH "</pre>\n";
}

#   3.9.2   Boxed Value Type
#

sub visitBoxedValue {
    my $self = shift;
    my ($node, $FH) = @_;
    print $FH "<pre>  ";
        $self->_xp($node, $FH);
        print $FH "valuetype ";
        print $FH "<span class='decl'>",$node->{idf},"</span> ";
        print $FH $self->_get_name($node->{type});
        print $FH ";\n";
    print $FH "  typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
            if (exists $node->{typeid});
    print $FH "  typeprefix ",$node->{idf}," \"",$node->{typeprefix},"\";\n"
            if (exists $node->{typeprefix});
    print $FH "</pre>\n";
}

#   3.9.3   Abstract Value Type
#

sub visitAbstractValue {
    my $self = shift;
    my ($node, $FH) = @_;
    print $FH "<a id='",$node->{idf},"' name='",$node->{idf},"'/>\n";
    print $FH "<pre>  ";
        $self->_xp($node, $FH);
        print $FH "abstract valuetype <span class='decl'>",$node->{idf},"</span>";
        if (exists $node->{inheritance}) {
            my $inheritance = $node->{inheritance};
            print $FH " : ";
            if (exists $inheritance->{list_value}) {
                print $FH "truncatable " if (exists $inheritance->{modifier});
                my $first = 1;
                foreach (@{$inheritance->{list_value}}) {
                    print $FH ", " if (! $first);
                    print $FH $self->_get_name($_);
                    $first = 0;
                }
                print $FH " ";
            }
            if (exists $inheritance->{list_interface}) {
                print $FH "support ";
                my $first = 1;
                foreach (@{$inheritance->{list_interface}}) {
                    print $FH ", " if (! $first);
                    print $FH $self->_get_name($_);
                    $first = 0;
                }
            }
        }
        print $FH ";\n";
    print $FH "typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
            if (exists $node->{typeid});
    print $FH "typeprefix ",$node->{idf}," \"",$node->{typeprefix},"\";\n"
            if (exists $node->{typeprefix});
    print $FH "</pre>\n";
}

#
#   3.10    Constant Declaration
#

sub visitConstant {
    my $self = shift;
    my ($node, $FH) = @_;
    print $FH "<pre>  ";
        $self->_xp($node, $FH);
        print $FH "constant ";
        print $FH $self->_get_name($node->{type});
        print $FH " <span class='decl'>",$node->{idf},"</span> = ";
        $node->{value}->visit($self, $FH);      # expression
        print $FH ";\n";
    print $FH "  typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
            if (exists $node->{typeid});
    print $FH "</pre>\n";
}

sub visitExpression {
    my $self = shift;
    my ($node, $FH) = @_;
    print $FH $self->_get_name($node);
}

#
#   3.11    Type Declaration
#

sub visitTypeDeclarator {
    my $self = shift;
    my ($node, $FH) = @_;
    print $FH "<pre>  ";
        $self->_xp($node, $FH);
        print $FH "typedef ";
        print $FH $self->_get_name($node->{type});
        print $FH " <span class='decl'>",$node->{idf},"</span>";
        if (exists $node->{array_size}) {
            foreach (@{$node->{array_size}}) {
                print $FH "[";
                $_->visit($self, $FH);              # expression
                print $FH "]";
            }
        }
        print $FH ";\n";
    print $FH "  typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
            if (exists $node->{typeid});
    print $FH "</pre>\n";
}

sub visitNativeType {
    my $self = shift;
    my ($node, $FH) = @_;
    print $FH "<pre>  ";
        $self->_xp($node, $FH);
        print $FH "native ";
        print $FH " <span class='decl'>",$node->{idf},"</span>";
        print $FH " (",$node->{native},")" if (exists $node->{native}); # XPIDL
        print $FH ";\n";
    print $FH "  typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
            if (exists $node->{typeid});
    print $FH "</pre>\n";
}

#
#   3.11.2  Constructed Types
#
#   3.11.2.1    Structures
#

sub visitStructType {
    my $self = shift;
    my ($node, $FH) = @_;
    print $FH "<pre>  ";
        $self->_xp($node, $FH);
        print $FH "struct <span class='decl'>",$node->{html_name},"</span> {\n";
    foreach (@{$node->{list_expr}}) {
        $_->visit($self, $FH);              # members
    }
    print $FH "  };\n";
    print $FH "</pre>\n";
}

sub visitMembers {
    my $self = shift;
    my ($node, $FH) = @_;
    print $FH "    ";
    $self->_xp_props($node, $FH);
    print $FH " ",$self->_get_name($node->{type});
    my $first = 1;
    foreach (@{$node->{list_member}}) {
        if ($first) {
            $first = 0;
        }
        else {
            print $FH ",";
        }
        $self->_get_defn($_)->visit($self, $FH);        # member
    }
    print $FH ";\n";
}

sub visitMember {
    my $self = shift;
    my ($node, $FH) = @_;
    print $FH " ",$node->{idf};
    if (exists $node->{array_size}) {
        foreach (@{$node->{array_size}}) {
            print $FH "[";
            $_->visit($self, $FH);              # expression
            print $FH "]";
        }
    }
}

#   3.11.2.2    Discriminated Unions
#

sub visitUnionType {
    my $self = shift;
    my ($node, $FH) = @_;
    print $FH "<pre>  ";
        $self->_xp($node, $FH);
        print $FH "union <span class='decl'>",$node->{html_name},"</span> switch(";
        print $FH $self->_get_name($node->{type});
        print $FH ") {\n";
    foreach (@{$node->{list_expr}}) {
        $_->visit($self, $FH);              # case
    }
    print $FH "  };\n";
    print $FH "</pre>\n";
}

sub visitCase {
    my $self = shift;
    my ($node, $FH) = @_;
    foreach (@{$node->{list_label}}) {
        if ($_->isa('Default')) {
            print $FH "    default:\n";
        }
        else {
            print $FH "    case ";
            $_->visit($self, $FH);          # expression
            print $FH ":\n";
        }
    }
    $node->{element}->visit($self, $FH);
}

sub visitElement {
    my $self = shift;
    my ($node, $FH) = @_;
    print $FH "      ",$self->_get_name($node->{type});
    $self->_get_defn($node->{value})->visit($self, $FH);        # member
    print $FH ";\n";
}

#   3.11.2.4    Enumerations
#

sub visitEnumType {
    my $self = shift;
    my ($node, $FH) = @_;
    print $FH "<pre>  ";
        $self->_xp($node, $FH);
        print $FH "enum <span class='decl'>",$node->{html_name},"</span> {\n";
    my $first = 1;
    foreach (@{$node->{list_expr}}) {   # enum
        print $FH ",\n" unless ($first);
        print $FH "    <a id='",$_->{idf},"' name='",$_->{idf},"'/>",$_->{idf};
        $first = 0;
    }
    print $FH "\n";
    print $FH "  };\n";
    print $FH "  typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
            if (exists $node->{typeid});
    print $FH "</pre>\n";
}

#
#   3.12    Exception Declaration
#

sub visitException {
    my $self = shift;
    my ($node, $FH) = @_;
    print $FH "<pre>  ";
        $self->_xp($node, $FH);
        print $FH "exception <span class='decl'>",$node->{idf},"</span> {\n";
    foreach (@{$node->{list_expr}}) {
        $_->visit($self, $FH);              # members
    }
    print $FH "  };\n";
    print $FH "  typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
            if (exists $node->{typeid});
    print $FH "</pre>\n";
}

#
#   3.13    Operation Declaration
#

sub visitOperation {
    my $self = shift;
    my ($node, $FH) = @_;
    print $FH "<pre>  ";
        $self->_xp($node, $FH);
        print $FH "oneway " if (exists $node->{modifier});
        print $FH $self->_get_name($node->{type});
        print $FH " <span class='decl'>",$node->{idf},"</span> (";
    my $first = 1;
    foreach (@{$node->{list_param}}) {  # parameter
        print $FH "," unless ($first);
        print $FH "\n";
        print $FH "    ";
        if ($_->isa('Ellipsis')) {
            print $FH "...";
        }
        else {
            $self->_xp_props($_, $FH);
            print $FH $_->{attr}," ",$self->_get_name($_->{type})," ",$_->{idf};
        }
        $first = 0;
    }
    print $FH "\n";
    print $FH "  )";
    if (exists $node->{list_raise}) {
        print $FH " raises(";
        my $first = 1;
        foreach (@{$node->{list_raise}}) {  # exception
            print $FH ", " unless ($first);
            print $FH $self->_get_name($_);
            $first = 0;
        }
        print $FH ")";
    }
    print $FH ";\n";
    print $FH "  typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
            if (exists $node->{typeid});
    print $FH "</pre>\n";
}

#
#   3.14    Attribute Declaration
#

sub visitAttribute {
    my $self = shift;
    my ($node, $FH) = @_;
    print $FH "<pre>  ";
        $self->_xp($node, $FH);
        print $FH "readonly " if (exists $node->{modifier});
        print $FH "attribute ";
        print $FH $self->_get_name($node->{type});
        print $FH " <span class='decl'>",$node->{idf},"</span>;";
    print $FH "  typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
            if (exists $node->{typeid});
    print $FH "</pre>\n";
}

#
#   3.16    Event Declaration
#

sub visitRegularEvent {
    my $self = shift;
    my ($node, $FH) = @_;
    print $FH "<a id='",$node->{idf},"' name='",$node->{idf},"'/>\n";
    print $FH "<pre>  ";
        print $FH "custom "
                if (exists $node->{modifier});
        print $FH "eventtype <span class='decl'>",$node->{idf},"</span>";
        if (exists $node->{inheritance}) {
            my $inheritance = $node->{inheritance};
            print $FH " : ";
            if (exists $inheritance->{list_value}) {
                print $FH "truncatable " if (exists $inheritance->{modifier});
                my $first = 1;
                foreach (@{$inheritance->{list_value}}) {
                    print $FH ", " if (! $first);
                    print $FH $self->_get_name($_);
                    $first = 0;
                }
            }
            if (exists $inheritance->{list_interface}) {
                print $FH "support ";
                my $first = 1;
                foreach (@{$inheritance->{list_interface}}) {
                    print $FH ", " if (! $first);
                    print $FH $self->_get_name($_);
                    $first = 0;
                }
            }
        }
        print $FH ";\n";
    print $FH "typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
            if (exists $node->{typeid});
    print $FH "typeprefix ",$node->{idf}," \"",$node->{typeprefix},"\";\n"
            if (exists $node->{typeprefix});
    print $FH "</pre>\n";
}

sub visitAbstractEvent {
    my $self = shift;
    my ($node, $FH) = @_;
    print $FH "<a id='",$node->{idf},"' name='",$node->{idf},"'/>\n";
    print $FH "<pre>  abstract eventtype <span class='decl'>",$node->{idf},"</span>";
        if (exists $node->{inheritance}) {
            my $inheritance = $node->{inheritance};
            print $FH " : ";
            if (exists $inheritance->{list_value}) {
                print $FH "truncatable " if (exists $inheritance->{modifier});
                my $first = 1;
                foreach (@{$inheritance->{list_value}}) {
                    print $FH ", " if (! $first);
                    print $FH $self->_get_name($_);
                    $first = 0;
                }
            }
            if (exists $inheritance->{list_interface}) {
                print $FH "support ";
                my $first = 1;
                foreach (@{$inheritance->{list_interface}}) {
                    print $FH ", " if (! $first);
                    print $FH $self->_get_name($_);
                    $first = 0;
                }
            }
        }
        print $FH ";\n";
    print $FH "typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
            if (exists $node->{typeid});
    print $FH "typeprefix ",$node->{idf}," \"",$node->{typeprefix},"\";\n"
            if (exists $node->{typeprefix});
    print $FH "</pre>\n";
}

#
#   3.17    Component Declaration
#

sub visitComponent {
    my $self = shift;
    my ($node, $FH) = @_;
    print $FH "<a id='",$node->{idf},"' name='",$node->{idf},"'/>";
    print $FH "<pre>  component <span class='decl'>",$node->{idf},"</span>";
        if (exists $node->{inheritance}) {
            print $FH " : ",$self->_get_name($node->{inheritance});
        }
        if (exists $node->{list_support}) {
            print $FH " support ";
            my $first = 1;
            foreach (@{$node->{list_support}}) {
                print $FH ", " if (! $first);
                print $FH $self->_get_name($_);
                $first = 0;
            }
        }
        print $FH ";\n";
    print $FH "typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
            if (exists $node->{typeid});
    print $FH "</pre>\n";
}

sub visitProvides {
    my $self = shift;
    my ($node, $FH) = @_;
    print $FH "<pre>  ";
        print $FH "provides ";
        print $FH $self->_get_name($node->{type});
        print $FH " <span class='decl'>",$node->{idf},"</span>;\n";
    print $FH "  typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
            if (exists $node->{typeid});
    print $FH "</pre>\n";
}

sub visitUses {
    my $self = shift;
    my ($node, $FH) = @_;
    print $FH "<pre>  ";
        print $FH "provides ";
        print $FH "multiple " if (exists $node->{modifier});
        print $FH $self->_get_name($node->{type});
        print $FH " <span class='decl'>",$node->{idf},"</span>;\n";
    print $FH "  typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
            if (exists $node->{typeid});
    print $FH "</pre>\n";
}

sub visitPublishes {
    my $self = shift;
    my ($node, $FH) = @_;
    print $FH "<pre>  ";
        print $FH "publishes ";
        print $FH $self->_get_name($node->{type});
        print $FH " <span class='decl'>",$node->{idf},"</span>;\n";
    print $FH "  typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
            if (exists $node->{typeid});
    print $FH "</pre>\n";
}

sub visitEmits {
    my $self = shift;
    my ($node, $FH) = @_;
    print $FH "<pre>  ";
        print $FH "emits ";
        print $FH $self->_get_name($node->{type});
        print $FH " <span class='decl'>",$node->{idf},"</span>;\n";
    print $FH "  typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
            if (exists $node->{typeid});
    print $FH "</pre>\n";
}

sub visitConsumes {
    my $self = shift;
    my ($node, $FH) = @_;
    print $FH "<pre>  ";
        print $FH "consumes ";
        print $FH $self->_get_name($node->{type});
        print $FH " <span class='decl'>",$node->{idf},"</span>;\n";
    print $FH "  typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
            if (exists $node->{typeid});
    print $FH "</pre>\n";
}

#
#   3.18    Home Declaration
#

sub visitHome {
    my $self = shift;
    my ($node, $FH) = @_;
    print $FH "<a id='",$node->{idf},"' name='",$node->{idf},"'/>";
    print $FH "<pre>  home <span class='decl'>",$node->{idf},"</span>";
        if (exists $node->{inheritance}) {
            print $FH " : ",$self->_get_name($node->{inheritance});
        }
        if (exists $node->{list_support}) {
            print $FH " support ";
            my $first = 1;
            foreach (@{$node->{list_support}}) {
                print $FH ", " if (! $first);
                print $FH $self->_get_name($_);
                $first = 0;
            }
        }
        print $FH " manages ",$self->_get_name($node->{manage});
        if (exists $node->{primarykey}) {
            print $FH " primarykey ",$self->_get_name($node->{primarykey});
        }
        print $FH ";\n";
    print $FH "typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
            if (exists $node->{typeid});
    print $FH "</pre>\n";
}

sub visitFactory {
    my $self = shift;
    my ($node, $FH) = @_;
    print $FH "<pre>  factory <span class='decl'>",$node->{idf},"</span> (";
    my $first = 1;
    foreach (@{$node->{list_param}}) {  # parameter
        print $FH "," unless ($first);
        print $FH "\n";
        print $FH "    ",$_->{attr}," ",$self->_get_name($_->{type})," ",$_->{idf};
        $first = 0;
    }
    print $FH "\n";
    print $FH "  )";
    if (exists $node->{list_raise}) {
        print $FH " raises(";
        my $first = 1;
        foreach (@{$node->{list_raise}}) {  # exception
            print $FH ", " unless ($first);
            print $FH $self->_get_name($_);
            $first = 0;
        }
        print $FH ")";
    }
    print $FH ";\n";
    print $FH "  typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
            if (exists $node->{typeid});
    print $FH "</pre>\n";
}

sub visitFinder {
    my $self = shift;
    my ($node, $FH) = @_;
    print $FH "<pre>  finder <span class='decl'>",$node->{idf},"</span> (";
    my $first = 1;
    foreach (@{$node->{list_param}}) {  # parameter
        print $FH "," unless ($first);
        print $FH "\n";
        print $FH "    ",$_->{attr}," ",$self->_get_name($_->{type})," ",$_->{idf};
        $first = 0;
    }
    print $FH "\n";
    print $FH "  )";
    if (exists $node->{list_raise}) {
        print $FH " raises(";
        my $first = 1;
        foreach (@{$node->{list_raise}}) {  # exception
            print $FH ", " unless ($first);
            print $FH $self->_get_name($_);
            $first = 0;
        }
        print $FH ")";
    }
    print $FH ";\n";
    print $FH "  typeid ",$node->{idf}," \"",$node->{typeid},"\";\n"
            if (exists $node->{typeid});
    print $FH "</pre>\n";
}

1;

