
package CORBA::XPIDL::DocVisitor;

use strict;
use warnings;

our $VERSION = '0.20';

use File::Basename;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    my ($parser) = @_;
    $self->{srcname} = $parser->YYData->{srcname};
    $self->{symbtab} = $parser->YYData->{symbtab};
    my $filename;
    if ($parser->YYData->{opt_e}) {
        $filename = $parser->YYData->{opt_e};
    }
    else {
        if ($parser->YYData->{opt_o}) {
            $filename = $parser->YYData->{opt_o} . '.html';
        }
        else {
            $filename = basename($self->{srcname}, '.idl') . '.html';
        }
    }
    $self->open_stream($filename);
    $self->{num_key} = 'num_doc_xp';
    return $self;
}

sub open_stream {
    my $self = shift;
    my ($filename) = @_;
    open $self->{out}, '>', $filename
            or die "can't open $filename ($!).\n";
    $self->{filename} = $filename;
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
#   3.5     OMG IDL Specification
#

sub visitSpecification {
    my $self = shift;
    my ($node) = @_;
    my $FH = $self->{out};

    print $FH "<html>\n";
    print $FH "<head>\n";
    print $FH "<!-- this file is generated from ",$self->{srcname}," -->\n";
    print $FH "<title>documentation for ",$self->{srcname}," interfaces</title>\n";
    print $FH "</head>\n";
    print $FH "<body>\n";
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self);
    }
    print $FH "</body>\n";
    print $FH "</html>\n";
    close $FH;
}

#
#   3.6     Import Declaration
#

sub visitImport {
    # empty
}

#
#   3.7     Module Declaration
#

sub visitModules {
    my $self = shift;
    my ($node) = @_;
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
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self);
    }
}

#
#   3.8     Interface Declaration
#

sub visitBaseInterface {
    # empty
}

sub visitRegularInterface {
    my $self = shift;
    my ($node) = @_;
    return unless ($self->{srcname} eq $node->{filename});
    my $FH = $self->{out};

    print $FH "interface ",$node->{idf},"<br />\n";
    if (exists $node->{doc}) {
        print $FH "doc comments:<br />\n";
        print $FH "<pre>\n";
        print $FH $node->{doc};
        print $FH "</pre>\n";
        print $FH "<br />\n";
    }
    if (exists $node->{inheritance}) {
        print $FH $node->{idf}," inherits from:<br />\n";
        print $FH "<ul>\n";
        foreach (@{$node->{inheritance}->{list_interface}}) {
            my $base = $self->_get_defn($_);
            print $FH "    <li>",$base->{idf},"</li>\n";
        }
        print $FH "</ul>\n";
        print $FH "<br />\n";
    }

    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self);
    }
}

sub visitForwardBaseInterface {
    # empty
}

#
#   3.10        Constant Declaration
#

sub visitConstant {
    # empty
}

sub visitExpression {
    # empty
}

#
#   3.11    Type Declaration
#

sub visitTypeDeclarators {
    # empty
}

sub visitNativeType {
    # empty
}

#
#   3.11.2  Constructed Types
#

sub visitStructType {
    # empty
}

sub visitUnionType {
    # empty
}

sub visitForwardStructType {
    # empty
}

sub visitForwardUnionType {
    # empty
}

#   3.11.2.4    Enumerations
#

sub visitEnumType {
    # empty
}

#
#   3.12    Exception Declaration
#

sub visitException {
    # empty
}

#
#   3.13    Operation Declaration
#

sub visitOperation {
    my $self = shift;
    my ($node) = @_;
    my $FH = $self->{out};

    print $FH "method ",$node->{idf},"<br />\n";
}

#
#   3.14    Attribute Declaration
#

sub visitAttributes {
    my $self = shift;
    my ($node) = @_;
    my $FH = $self->{out};

    my $type = $self->_get_defn($node->{type});
    print $FH "readonly " if (exists $node->{modifier});
    print $FH "attribute ",$type->{xp_name},"\n";
    print $FH "<ul>\n";
    foreach (@{$node->{list_decl}}) {
        my $attr = $self->_get_defn($_);
        print $FH "    <li>",$attr->{idf},"</li>\n";
    }
    print $FH "</ul>\n";
    print $FH "<br />\n";
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
#   XPIDL
#

sub visitCodeFragment {
    # empty
}

1;

