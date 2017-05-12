
package CORBA::XPIDL::CheckVisitor;

use strict;
use warnings;

our $VERSION = '0.20';

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    my ($parser, $typelib, $mode) = @_;
    $self->{symbtab} = $parser->YYData->{symbtab};
    $self->{typelib} = $typelib;
    $self->{mode} = $mode;
    $self->{parser} = $parser;
    $self->{num_key} = 'check_xp';
    return $self;
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

sub _get_effective_type {
    my $self = shift;
    my ($type) = @_;
    $type = $self->_get_defn($type);
#   while (     $type->isa('TypeDeclarator')
#           and ! exists $type->{array_size} ) {
    while ($type->isa('TypeDeclarator')) {
        $type = $self->_get_defn($type->{type});
    }
    return $type;
}

sub _verify_type_fits_version {
    my $self = shift;
    my ($type, $node) = @_;

    if ($self->{typelib} eq '1.1') {
        # XPIDL Version 1.1 checks

        # utf8string, cstring, and astring types are not supported
        if (       $type->hasProperty('utf8string')
                or $type->hasProperty('cstring')
                or $type->hasProperty('astring') ) {
            $self->{parser}->YYData->{filename} = $node->{filename};
            $self->{parser}->YYData->{lineno} = $node->{lineno};
            $self->{parser}->Error(
                    "Cannot use [utf8string], [cstring] and [astring] " .
                    "types when generating version 1.1 typelibs.\n"
            );
        }
    }
}

sub _check_param_attribute {
    my $self = shift;
    my ($method, $param, $label) = @_;
    my $prop = $param->getProperty($label);
    return unless (defined $prop);
    $self->{parser}->YYData->{filename} = $method->{filename};
    $self->{parser}->YYData->{lineno} = $method->{lineno};
    foreach (@{$method->{list_param}}) {
        if ($_->{idf} eq $prop) {
            if ($param == $_) {
                $self->{parser}->Error(
                        "attribute [$label($prop)] refers to it's own parameter.\n"
                );
            }
            my $type = $self->_get_defn($_->{type});
            if    ($label eq 'iid_is') {
                # require IID type
                unless ($type->hasProperty('nsid')) {
                    $self->{parser}->Error(
                            "target \"$prop\" of [$label($prop)] attribute " .
                            "must be of IID type.\n"
                    );
                }
            }
            elsif ($label eq 'size_is' or $label eq 'length_is') {
                # require PRUint32 type
                $type = $self->_get_effective_type($type);
                unless ($type->isa('IntegerType') and $type->{value} eq 'unsigned long') {
                    $self->{parser}->Error(
                            "target \"$prop\" of [$label($prop)] attribute " .
                            "must be of unsigned long (or PRUint32) type.\n"
                    );
                }
            }
            return;
        }
    }
    $self->{parser}->Error(
            "attribute [$label($prop)] refers to missing " .
            "parameter \"$prop\".\n"
    );
}

#
#   3.5     OMG IDL Specification
#

sub visitSpecification {
    my $self = shift;
    my ($node) = @_;
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self, $node);
    }
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
        $self->_get_defn($_)->visit($self, $node);
    }
}

#
#   3.8     Interface Declaration
#

sub visitRegularInterface {
    my $self = shift;
    my ($node) = @_;

    $self->{parser}->YYData->{filename} = $node->{filename};
    $self->{parser}->YYData->{lineno} = $node->{lineno};
    my $iid = $node->getProperty('uuid');
    if (defined $iid) {
        if (length($iid) == 36) {
            $self->{parser}->Error("cannot parse IID $iid.\n")
                    unless ($iid =~ /^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$/);
        }
        else {
            $self->{parser}->Error("IID $iid is the wrong length.\n");
        }
    }
    else {
        unless ($self->{mode} eq 'java') {
            $self->{parser}->Error(
                    "interface '$node->{idf}' lacks a uuid attribute.\n"
            );
        }
    }

    if (exists $node->{inheritance}) {
        unless (scalar(@{$node->{inheritance}->{list_interface}}) == 1) {
            unless ($self->{mode} eq 'java') {
                $self->{parser}->Error(
                        "multiple inheritance is not supported by xpidl.\n"
                );
            }
        }

        # If we have the scriptable attribute then make sure all of our direct
        # parents have it as well.
        # NOTE: We don't recurse since all interfaces will fall through here
        if ($node->hasProperty('scriptable')) {
            foreach (@{$node->{inheritance}->{list_interface}}) {
                my $base = $self->_get_defn($_);
                unless ($base->hasProperty('scriptable')) {
                    $self->{parser}->Warning(
                            "'$node->{idf}' is scriptable but inherits from " .
                            "the non-scriptable interface '$base->{idf}'.\n"
                    );
                }
            }
        }
    }

    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self, $node);
    }
}

sub visitAbstractInterface {
    my $self = shift;
    my ($node) = @_;
    $self->{parser}->YYData->{filename} = $node->{filename};
    $self->{parser}->YYData->{lineno} = $node->{lineno};
    $self->{parser}->Error("abstract interface not supported.\n");
}

sub visitLocalInterface {
    my $self = shift;
    my ($node) = @_;
    $self->{parser}->YYData->{filename} = $node->{filename};
    $self->{parser}->YYData->{lineno} = $node->{lineno};
    $self->{parser}->Error("local interface not supported.\n");
}

sub visitForwardRegularInterface {
    # empty
}

sub visitForwardAbstractInterface {
    shift->visitAbstractInterface(@_);
}

sub visitForwardLocalInterface {
    shift->visitLocalInterface(@_);
}

#   3.9     Value Declaration
#

sub visitValue {
    my $self = shift;
    my ($node) = @_;
    $self->{parser}->YYData->{filename} = $node->{filename};
    $self->{parser}->YYData->{lineno} = $node->{lineno};
    $self->{parser}->Error("valuetype not supported.\n");
}

sub visitForwardValue {
    # empty
}

#
#   3.10    Constant Declaration
#

sub visitConstant {
    my $self = shift;
    my ($node, $parent) = @_;

    $self->{parser}->YYData->{filename} = $node->{filename};
    $self->{parser}->YYData->{lineno} = $node->{lineno};
    unless ($parent->isa('RegularInterface')) {
        $self->{parser}->Error(
                "const declaration '$node->{idf}' outside interface.\n"
        );
    }

    my $type = $self->_get_effective_type($node->{type});
    if (        ! $type->isa('IntegerType') ) {
#           and ! $type->isa('CharType')
#           and ! $type->isa('WideCharType')
#           and ! $type->isa('OctetType') ) {
        $self->{parser}->Error(
                "const declaration '$node->{idf}' must be of type short or long.\n"
        );
    }
}

sub visitExpression {
    # empty
}

#
#   3.11    Type Declaration
#

sub visitTypeDeclarators {
    my $self = shift;
    my ($node) = @_;

    my $type = $self->_get_effective_type($node->{type});
    if ($type->isa('SequenceType')) {
        $self->{parser}->YYData->{filename} = $node->{filename};
        $self->{parser}->YYData->{lineno} = $node->{lineno};
        $self->{parser}->Warning("sequences not supported, ignored.\n");
        return;
    }

    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self);
    }
}

sub visitTypeDeclarator {
    my $self = shift;
    my ($node) = @_;

    my $type = $self->_get_defn($node->{type});
    $type->visit($self);
}

sub visitNativeType {
    my $self = shift;
    my ($node) = @_;

    $self->{parser}->YYData->{filename} = $node->{filename};
    $self->{parser}->YYData->{lineno} = $node->{lineno};
    # require that native declarations give a native type
    unless (exists $node->{native}) {
        $self->{parser}->Error(
                "``native $node->{idf};'' needs C++ type: " .
                "``native $node->{idf}(<C++ type>);''\n"
        );
    }
}

#
#   3.11.1  Basic Types
#

sub visitBasicType {
    # empty
}

sub visitValueBaseType {
    my $self = shift;
    my ($node) = @_;
    $self->{parser}->YYData->{filename} = $node->{filename};
    $self->{parser}->YYData->{lineno} = $node->{lineno};
    $self->{parser}->Error("ValueBase not supported.\n");
}

#
#   3.11.2  Constructed Types
#
#   3.11.2.1    Structures
#

sub visitStructType {
    my $self = shift;
    my ($node) = @_;
    $self->{parser}->YYData->{filename} = $node->{filename};
    $self->{parser}->YYData->{lineno} = $node->{lineno};
    $self->{parser}->Warning("structs not supported, struct '$node->{idf}' ignored\n");
}

#   3.11.2.2    Discriminated Unions
#

sub visitUnionType {
    my $self = shift;
    my ($node) = @_;
    $self->{parser}->YYData->{filename} = $node->{filename};
    $self->{parser}->YYData->{lineno} = $node->{lineno};
    $self->{parser}->Warning("unions not supported, union '$node->{idf}' ignored\n");
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
    my $self = shift;
    my ($node) = @_;
    $self->{parser}->YYData->{filename} = $node->{filename};
    $self->{parser}->YYData->{lineno} = $node->{lineno};
    $self->{parser}->Warning("enums not supported, enum '$node->{idf}' ignored\n");
}

#
#   3.11.3  Template Types
#

sub visitStringType {
    # empty
}

sub visitWideStringType {
    # empty
}

sub visitFixedPtType {
    my $self = shift;
    my ($node) = @_;
    $self->{parser}->YYData->{filename} = $node->{filename};
    $self->{parser}->YYData->{lineno} = $node->{lineno};
    $self->{parser}->Error("fixed not supported.\n");
}

sub visitFixedPtConstType {
    my $self = shift;
    my ($node) = @_;
    $self->{parser}->YYData->{filename} = $node->{filename};
    $self->{parser}->YYData->{lineno} = $node->{lineno};
    $self->{parser}->Error("fixed not supported.\n");
}

#
#   3.12    Exception Declaration
#

sub visitException {
    shift->visitStructType(@_);
}

#
#   3.13    Operation Declaration
#

sub visitOperation {
    my $self = shift;
    my ($node, $parent) = @_;

    $self->{parser}->YYData->{filename} = $node->{filename};
    $self->{parser}->YYData->{lineno} = $node->{lineno};

    # We don't support attributes named IID, conflicts with static GetIID
    # member. The conflict is due to certain compilers (VC++) choosing a
    # different vtable order, placing GetIID at the beginning regardless
    # of it's placement
    if ($node->{idf} eq 'GetIID') {
        $self->{parser}->Error(
                "Methods named GetIID not supported, causes vtable " .
                "ordering problems.\n"
        );
    }

    # Decide if the interface was marked [scriptable]
    my $scriptable_interface = $parent->hasProperty('scriptable');

    # Require that any method in an interface marked as [scriptable], that
    # *isn't* scriptable because it refers to some native type, be marked
    # [noscript] or [notxpcom].
    #
    # Also check that iid_is points to nsid, and length_is, size_is points
    # to unsigned long.
    my $notxpcom = $node->hasProperty('notxpcom');
    my $scriptable_method = $scriptable_interface && !$notxpcom && !$node->hasProperty('noscript');

    my $seen_retval;
    my $last = 1;
    foreach (reverse @{$node->{list_param}}) {
        if ($_->isa('Ellipsis')) {
            $self->{parser}->Error("varargs are not currently supported.\n");
        }
        else {
            my $type = $self->_get_effective_type($_->{type});
            if ($type->isa('SequenceType')) {
                $self->{parser}->Error("sequences not supported.\n");
            }

            # Reject this method if it should be scriptable and some parameter is
            # native that isn't marked with either nsid, domstring, utf8string,
            # cstring, astring or iid_is.
            if ( $scriptable_method and $type->isa('NativeType') ) {
                if (        ! $type->hasProperty('nsid')
                        and ! $_->hasProperty('iid_is')
                        and ! $type->hasProperty('domstring')
                        and ! $type->hasProperty('utf8string')
                        and ! $type->hasProperty('cstring')
                        and ! $type->hasProperty('astring') ) {
                    $self->{parser}->Error(
                            "methods in [scriptable] interfaces that are " .
                            "non-scriptable because they refer to native " .
                            "types (parameter '$_->{idf}') must be marked " .
                            "[noscript].\n"
                    );
                }
            }

            # nsid's parameters that aren't ptr's or ref's are not currently
            # supported in xpcom or non-xpcom (marked with [notxpcom]) methods
            # as input parameters
            if ( !$notxpcom and $_->{attr} ne 'in') {
                if (          $type->hasProperty('nsid')
                        and ! $type->hasProperty('ptr')
                        and ! $type->hasProperty('ref') ) {
                    $self->{parser}->Error(
                            "Feature currently not supported: " .
                            "parameter '$_->{idf}' is of type nsid and " .
                            "must be marked either [ptr] or [ref] " .
                            "or method '$node->{idf}' must be marked [notxpcom]" .
                            " and must not be an input parameter.\n"
                    );
                }
            }

            # Sanity checks on return values.
            if ($_->hasProperty('retval')) {
                unless ($last) {
                    $self->{parser}->Error(
                            "only the last parameter can be marked [retval].\n"
                    );
                }
                unless ($self->_get_defn($node->{type})->isa('VoidType')) {
                    $self->{parser}->Error(
                            "can't have [retval] with non-void return type.\n"
                    );
                }
                # In case XPConnect relaxes the retval-is-last restriction.
                if ($seen_retval) {
                    $self->{parser}->Error(
                            "can't have more than one [retval] parameter.\n"
                    );
                }
                $seen_retval = 1;
            }

            # Confirm that [shared] attributes are only used with string, wstring,
            # or native (but not nsid, domstring, utf8string, cstring or astring)
            # and can't be used with [array].
            if ($_->hasProperty('shared')) {
                if ($_->hasProperty('array')) {
                    $self->{parser}->Error(
                            "[shared] parameter '$_->{idf}' cannot " .
                            "be of array type.\n"
                    );
                }

                unless (   $type->isa('StringType')
                        or $type->isa('WideStringType')
                        or (    $type->isa('NativeType')
                            and ! $type->hasProperty('nsid')
                            and ! $type->hasProperty('domstring')
                            and ! $type->hasProperty('utf8string')
                            and ! $type->hasProperty('cstring')
                            and ! $type->hasProperty('astring') ) ) {
                    $self->{parser}->Error(
                            "[shared] parameter '$_->{idf}' must be of type " .
                            "string, wstring or native.\n"
                    );
                }
            }

            # inout is not allowed with "domstring", "UTF8String", "CString"
            # and "AString" types
            if ( $_->{attr} eq 'inout' and $type->isa('NativeType') ) {
                if (       $type->hasProperty('domstring')
                        or $type->hasProperty('utf8string')
                        or $type->hasProperty('cstring')
                        or $type->hasProperty('astring') ) {
                    $self->{parser}->Error(
                            "[domstring], [utf8string], [cstring], [astring] " .
                            "types cannot be used as inout parameters"
                    );
                }
            }

            # arrays of domstring, utf8string, cstring, astring types not allowed
            if ( $_->hasProperty('array') and $type->isa('NativeType') ) {
                if (       $type->hasProperty('domstring')
                        or $type->hasProperty('utf8string')
                        or $type->hasProperty('cstring')
                        or $type->hasProperty('astring') ) {
                    $self->{parser}->Error(
                            "[domstring], [utf8string], [cstring], [astring] " .
                            "types cannot be used in array parameters.\n"
                    );
                }
            }

            $self->_check_param_attribute($node, $_, 'iid_is');
            $self->_check_param_attribute($node, $_, 'length_is');
            $self->_check_param_attribute($node, $_, 'size_is');

            # Run additional error checks on the return type if targetting an
            # older version of XPConnect.
            $self->_verify_type_fits_version($type, $node);
        }
        $last = 0;
    }

    my $type = $self->_get_effective_type($node->{type});
    if ($type->isa('SequenceType')) {
        $self->{parser}->Error("sequences not supported.\n");
    }

    return if ($type->isa('VoidType'));

    # XXX q: can return type be nsid?
    # Native return type?
    if ( $scriptable_method and $type->isa('NativeType') ) {
        if (        ! $type->hasProperty('nsid')
                and ! $type->hasProperty('domstring')
                and ! $type->hasProperty('utf8string')
                and ! $type->hasProperty('cstring')
                and ! $type->hasProperty('astring') ) {
            $self->{parser}->Error(
                    "methods in [scriptable] interfaces that are " .
                    "non-scriptable because they return native " .
                    "types must be marked [noscript].\n"
            );
        }
    }

    # nsid's parameters that aren't ptr's or ref's are not currently
    # supported in xpcom
    if (!$notxpcom) {
        if (          $type->hasProperty('nsid')
                and ! $type->hasProperty('ptr')
                and ! $type->hasProperty('ref') ) {
            $self->{parser}->Error(
                    "Feature currently not supported: " .
                    "return value is of type nsid and " .
                    "must be marked either [ptr] or [ref], " .
                    "or else method '$node->{idf}' must be marked [notxpcom].\n"
            );
        }
    }

    # Run additional error checks on the return type if targetting an
    # older version of XPConnect.
    $self->_verify_type_fits_version($type, $node);
}

#
#   3.14    Attribute Declaration
#

sub visitAttributes {
    my $self = shift;
    my ($node, $parent) = @_;

    $self->{parser}->YYData->{filename} = $node->{filename};
    $self->{parser}->YYData->{lineno} = $node->{lineno};

    my $type = $self->_get_effective_type($node->{type});
    if ($type->isa('SequenceType')) {
        $self->{parser}->Error("sequences not supported.\n");
    }
#   if (scalar(@{$node->{list_decl}}) > 1) {
#       $self->{parser}->Warning("multiple attributes in a single declaration aren't currently supported by xpidl.\n");
#   }
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self, $parent);
    }
}

sub visitAttribute {
    my $self = shift;
    my ($node, $parent) = @_;

    $self->{parser}->YYData->{filename} = $node->{filename};
    $self->{parser}->YYData->{lineno} = $node->{lineno};

    # We don't support attributes named IID, conflicts with static GetIID
    # member. The conflict is due to certain compilers (VC++) choosing a
    # different vtable order, placing GetIID at the beginning regardless
    # of it's placement
    if ($node->{idf} eq 'IID') {
        $self->{parser}->Error(
                "Attributes named IID not supported, causes vtable " .
                "ordering problems.\n"
        );
    }

    # If the interface isn't scriptable, or the attribute is marked noscript,
    # there's no need to check.
    return unless ($parent->hasProperty('scriptable'));
    return if ($node->hasProperty('noscript'));

    # If it should be scriptable, check that the type is non-native. nsid,
    # domstring, utf8string, cstring, astring are exempted.
    my $type = $self->_get_effective_type($node->{type});

    if ($type->isa('NativeType')) {
        if (        ! $type->hasProperty('nsid')
                and ! $type->hasProperty('domstring')
                and ! $type->hasProperty('utf8string')
                and ! $type->hasProperty('cstring')
                and ! $type->hasProperty('astring') ) {
            $self->{parser}->Error(
                    "attributes in [scriptable] interfaces that are " .
                    "non-scriptable because they refer to native " .
                    "types must be marked [noscript].\n"
            );
        }
    }

    # We currently don't support properties of type nsid that aren't
    # pointers or references, unless they are marked [notxpcom] and
    # must be read-only
    if (       ! $node->hasProperty('notxpcom')
            or !exists $node->{modifier}) {     # readonly
        if (          $type->hasProperty('nsid')
                and ! $type->hasProperty('ptr')
                and ! $type->hasProperty('ref') ) {
            $self->{parser}->Error(
                    "Feature not currently supported: " .
                    "attributes with a type of nsid must be marked " .
                    "either [ptr] or [ref], or " .
                    "else must be marked [notxpcom] " .
                    "and must be read-only.\n"
            );
        }
    }

    # Run additional error checks on the attribute type if targetting an
    # older version of XPConnect.
    $self->_verify_type_fits_version($type, $node);
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
    my $self = shift;
    my ($node, $parent) = @_;

    $self->{parser}->YYData->{filename} = $node->{filename};
    $self->{parser}->YYData->{lineno} = $node->{lineno};
    if ($parent->isa('BaseInterface')) {
        $self->{parser}->Warning(
                "\%\%{ .. \%\%} code fragment within interface " .
                "ignored when generating NS_DECL_$parent->{idf} macro; " .
                "if the code fragment contains method declarations, " .
                "the macro probably isn't complete.\n"
        );
    }
    if ($self->{mode} eq 'header') {
        my @code = split /\n/, $node->{value};
        my $lang = shift @code;
        unless ($lang =~ /^\s*C\+\+/) {
            $self->{parser}->YYData->{filename} = $node->{filename};
            $self->{parser}->YYData->{lineno} = $node->{lineno};
            $self->{parser}->Warning(
                    "ignoring '\%\%{$lang' escape. " .
                    "(Use '\%\%{C++' to escape verbatim C++ code).\n"
            );
        }
    }
}

1;

