use strict;
use warnings;

#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#

package CORBA::IDL::Node;

our $VERSION = '2.63';

use UNIVERSAL;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $parser = shift;
    my %attr = @_;
    my $self = \%attr;
    foreach (keys %attr) {
        unless (defined $self->{$_}) {
            delete $self->{$_};
        }
    }
    bless($self, $class);
    $self->_Init($parser);      # specialized or default
    return $self;
}

sub isa {
    return UNIVERSAL::isa(shift, 'CORBA::IDL::' . shift);
}

sub _Init {
    # default
}

sub configure {
    my $self = shift;
    my %attr = @_;
    while ( my ($key, $value) = each(%attr) ) {
        if (defined $value) {
            $self->{$key} = $value;
        }
    }
    return $self;
}

sub line_stamp {
    my $self = shift;
    my ($parser) = @_;
    $self->{filename} = $parser->YYData->{filename};
    $self->{lineno} = $parser->YYData->{lineno};
}

sub getRef {
    my $self = shift;
    my $class = ref $self;
    $class = substr $class, rindex($class, ':') + 1;
    if (exists $self->{full}) {
        if (       $class eq 'Module'
                or $class =~ /^Forward/ ) {
            return $self;
        }
        else {
            return $self->{full};
        }
    }
    else {
        return $self;
    }
}

sub getInheritance {
    my $self = shift;
    my @list = ();
    if (exists $self->{inheritance}) {
        if (exists $self->{inheritance}->{list_interface}) {
            push @list, @{$self->{inheritance}->{list_interface}};
        }
        if (exists $self->{inheritance}->{list_value}) {
            push @list, @{$self->{inheritance}->{list_value}};
        }
    }
    return @list;
}

sub getProperty {
    my $self = shift;
    my ($key) = @_;
    return undef unless (exists $self->{props});
    return undef unless (exists $self->{props}->{$key});
    return $self->{props}->{$key};
}

sub hasProperty {
    my $self = shift;
    my ($key) = @_;
    return 0 unless (exists $self->{props});
    return 0 unless (exists $self->{props}->{$key});
    return 1;
}

sub visit {
    my $self = shift;
    my $class = ref $self;
    my $visitor = shift;
    no strict 'refs';
    while ($class ne 'CORBA::IDL::Node') {
        my $func = 'visit' . substr($class, rindex($class, ':') + 1);
        if ($visitor->can($func)) {
            return $visitor->$func($self, @_);
        }
        $class = ${"$class\::ISA"}[0];
    }
    warn "Please implement a function 'visit",ref $self,"' in '",ref $visitor,"'.\n";
    return undef;
}

# deprecated in favor of 'visit'
sub visitName {
    my $self = shift;
    my $class = ref $self;
    my $visitor = shift;
    no strict 'refs';
    while ($class ne 'CORBA::IDL::Node') {
        my $func = 'visitName' . substr($class, rindex($class, ':') + 1);
        if ($visitor->can($func)) {
            return $visitor->$func($self, @_);
        }
        $class = ${"$class\::ISA"}[0];
    }
    warn "Please implement a function 'visitName",ref $self,"' in '",ref $visitor,"'.\n";
    return undef;
}

1;

#
#   3.5     OMG IDL Specification
#

package CORBA::IDL::Specification;

use base qw(CORBA::IDL::Node);

sub _Init {
    my $self = shift;
    my ($parser) = @_;
    my %hash;
    foreach my $export (@{$self->{list_decl}}) {
        if (ref $export) {
            unless (ref($export) =~ /^CORBA::IDL::Forward/) {
                if ($export->isa('Module')) {
                    $hash{$export->{full}} = 1;
                }
                else {  # TypeDeclarators, StateMembers, Attributes
                    foreach (@{$export->{list_decl}}) {
                        $hash{$_} = 1 if (defined $_);
                    }
                }
            }
        }
        else {
            $hash{$export} = 1;
        }
    }
    $self->{list_export} = [keys %hash];
    $parser->YYData->{symbtab}->Insert($self);
}

#
#   3.6     Import Declaration
#

package CORBA::IDL::Import;

use base qw(CORBA::IDL::Node);

sub _Init {
    my $self = shift;
    my ($parser) = @_;
    $parser->YYData->{symbtab}->Import($self);
}

#
#   3.7     Module Declaration
#

package CORBA::IDL::Modules;

use base qw(CORBA::IDL::Node);

package CORBA::IDL::Module;

use base qw(CORBA::IDL::Node);

sub _Init {
    my $self = shift;
    my ($parser) = @_;
    $self->{prefix} = $parser->YYData->{symbtab}->GetPrefix();
    $self->{_typeprefix} = $parser->YYData->{symbtab}->GetTypePrefix();
    $self->line_stamp($parser);
    if ($parser->YYData->{doc} ne q{}) {
        $self->{doc} = $parser->YYData->{doc}
                unless (exists $self->{doc});
        $parser->YYData->{doc} = q{};
    }
    $parser->YYData->{symbtab}->PushCurrentRoot($self);
    $parser->YYData->{curr_node} = $self;
}

sub Configure {
    my $self = shift;
    my $parser = shift;
    $self->configure(@_);
    my $defn = $parser->YYData->{symbtab}->Lookup($self->{full});   # Modules
    my %hash;
    foreach my $module (@{$defn->{list_decl}}) {
        foreach my $export (@{$module->{list_decl}}) {
            if (ref $export) {
                unless (ref($export) =~ /^CORBA::IDL::Forward/) {
                    if ($export->isa('Module')) {
                        $hash{$export->{full}} = 1;
                    }
                    else {  # TypeDeclarators, StateMembers, Attributes
                        foreach (@{$export->{list_decl}}) {
                            $hash{$_} = 1 if (defined $_);
                        }
                    }
                }
            }
            else {
                $hash{$export} = 1;
            }
        }
    }
    $defn->{list_export} = [keys %hash];
    return $defn;
}

#
#   3.8     Interface Declaration
#

package CORBA::IDL::BaseInterface;

use base qw(CORBA::IDL::Node);

sub _Init {
    my $self = shift;
    my ($parser) = @_;
    $self->{prefix} = $parser->YYData->{symbtab}->GetPrefix();
    $self->{_typeprefix} = $parser->YYData->{symbtab}->GetTypePrefix();
    $self->line_stamp($parser);
    if ($parser->YYData->{doc} ne q{}) {
        $self->{doc} = $parser->YYData->{doc};
        $parser->YYData->{doc} = q{};
    }
    $self->{local_type} = 1 if ($self->isa('LocalInterface'));
    $parser->YYData->{symbtab}->PushCurrentScope($self);
    $parser->YYData->{curr_itf} = $self;
    $self->_CheckInheritance($parser);          # specialized
    $self->_InsertInherited($parser);
    $parser->YYData->{curr_node} = $self;
}

sub _InsertInherited {
    my $self = shift;
    my ($parser) = @_;
    $self->{hash_attribute_operation} = {};
    foreach ($self->getInheritance()) {
        my $base = $parser->YYData->{symbtab}->Lookup($_);
        foreach (keys %{$base->{hash_attribute_operation}}) {
            my $name = $base->{hash_attribute_operation}{$_};
            my $defn = $parser->YYData->{symbtab}->Lookup($name);
            next if ($defn->isa('Initializer'));
            next if ($defn->isa('StateMember'));
#           next if ($defn->isa('Factory'));
#           next if ($defn->isa('Finder'));
            if (exists $self->{hash_attribute_operation}{$_}) {
                if ($self->{hash_attribute_operation}{$_} ne $name) {
                    $parser->Error("multi inheritance of '$_'.\n");
                }
            }
            else {
                $self->{hash_attribute_operation}{$_} = $name;
                $parser->YYData->{symbtab}->InsertInherit($self, $_, $name);
            }
        }
    }
}

sub Configure {
    my $self = shift;
    my $parser = shift;
    $self->configure(@_);
    my @list;
    foreach my $export (@{$self->{list_decl}}) {
        if (ref $export) {
            unless (ref($export) =~ /^CORBA::IDL::Forward/) {
                foreach (@{$export->{list_decl}}) {
                    push @list, $_ if (defined $_);
                }
            }
        }
        else {
            push @list, $export;
        }
    }
    $self->{list_export} = \@list;
    $self->_CheckLocal($parser);            # specialized
    $self->_CheckNative($parser);           # specialized
    return $self;
}

sub _CheckNative {
    # If a native type is used as an exception for an operation, the
    # operation must appear in either a local interface or a valuetype.
}

sub Lookup {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    $class = substr $class, rindex($class, ':') + 1;
    my ($parser, $name, $bypass) = @_;
    my $defn = $parser->YYData->{symbtab}->Lookup($name);
    if (defined $defn) {
        if ($defn->isa('Forward' . $class)) {
            $parser->Error("'$name' is declared, but not defined.\n")
                    unless ($bypass);
        }
        elsif (! $defn->isa($class)) {
            $parser->Error("'$name' is not a $class.\n");
        }
        return $defn->{full};
    }
    else {
        return q{};
    }
}

#
#   3.8.2   Interface Inheritance Specification
#

package CORBA::IDL::InheritanceSpec;

use base qw(CORBA::IDL::Node);

sub _Init {
    my $self = shift;
    my ($parser) = @_;
    $self->{hash_interface} = {};
    my %hash;
    # 3.8.5 Interface Inheritance
    if (exists $self->{list_interface}) {
        foreach my $name (@{$self->{list_interface}}) {
            if (exists $hash{$name}) {
                $parser->Warning("'$name' redeclares inheritance.\n");
            }
            else {
                $hash{$name} = 1;
                $self->{hash_interface}->{$name} = 1;
                my $base = $parser->YYData->{symbtab}->Lookup($name);
                if (exists $base->{inheritance}) {
                    foreach (keys %{$base->{inheritance}->{hash_interface}}) {
                        $self->{hash_interface}->{$_} = 1;
                    }
                }
            }
        }
    }
    # 3.9.5 Valuetype Inheritance
    if (exists $self->{list_value}) {
        foreach my $name (@{$self->{list_value}}) {
            if (exists $hash{$name}) {
                $parser->Warning("'$name' redeclares inheritance.\n");
            }
            else {
                $hash{$name} = 1;
                $self->{hash_interface}->{$name} = 1;
                my $base = $parser->YYData->{symbtab}->Lookup($name);
                if (exists $base->{inheritance}) {
                    foreach (keys %{$base->{inheritance}->{hash_interface}}) {
                        $self->{hash_interface}->{$_} = 1;
                    }
                }
            }
        }
    }
}

package CORBA::IDL::Interface;

use base qw(CORBA::IDL::BaseInterface);

package CORBA::IDL::RegularInterface;

use base qw(CORBA::IDL::Interface);

sub _CheckInheritance {
    my $self = shift;
    my ($parser) = @_;
    if (exists $self->{inheritance}) {
        foreach (@{$self->{inheritance}->{list_interface}}) {
            my $base = $parser->YYData->{symbtab}->Lookup($_);
            # An unconstrained interface may not inherit from a local interface.
            if ($base->isa('LocalInterface')) {
                $parser->Error("'$self->{idf}' is not local.\n");
            }
        }
    }
}

sub _CheckLocal {
    my $self = shift;
    my ($parser) = @_;

    # A local type may not appear as a parameter, attribute, return type, or exception
    # declaration of an unconstrained interface or as a state member of a valuetype.
    foreach (@{$self->{list_export}}) {
        my $defn = $parser->YYData->{symbtab}->Lookup($_);
        if      ($defn->isa('Attribute')) {
            if (CORBA::IDL::TypeDeclarator->IsaLocal($parser, $defn->{type})) {
                $parser->Error("'$self->{idf}' is not local.\n");
            }
        }
        elsif ($defn->isa('Operation')) {
            if (CORBA::IDL::TypeDeclarator->IsaLocal($parser, $defn->{type})) {
                $parser->Error("'$self->{idf}' is not local.\n");
            }
            foreach (@{$defn->{list_param}}) {
                if (CORBA::IDL::TypeDeclarator->IsaLocal($parser, $_->{type})) {
                    $parser->Error("'$self->{idf}' is not local.\n");
                }
            }
        }
    }
}

sub _CheckNative {
    my $self = shift;
    my ($parser) = @_;

    # If a native type is used as an exception for an operation, the
    # operation must appear in either a local interface or a valuetype.
    foreach (@{$self->{list_export}}) {
        my $defn = $parser->YYData->{symbtab}->Lookup($_);
        if (exists $defn->{list_raise}) {
            foreach (@{$defn->{list_raise}}) {
                my $except = $parser->YYData->{symbtab}->Lookup($_);
                if ($except->isa('NativeType')) {
                    $parser->Error("'$except->{idf}' used in a not local interface.\n");
                }
            }
        }
    }
}

#
#   3.8.4   Forward Declaration
#

package CORBA::IDL::ForwardBaseInterface;

use base qw(CORBA::IDL::Node);

sub _Init {
    my $self = shift;
    my ($parser) = @_;
    $self->{prefix} = $parser->YYData->{symbtab}->GetPrefix();
    $self->{_typeprefix} = $parser->YYData->{symbtab}->GetTypePrefix();
    $self->line_stamp($parser);
    $self->{local_type} = 1 if ($self->isa('ForwardLocalInterface'));
    $parser->YYData->{symbtab}->InsertForward($self);
}

package CORBA::IDL::ForwardInterface;

use base qw(CORBA::IDL::ForwardBaseInterface);

package CORBA::IDL::ForwardRegularInterface;

use base qw(CORBA::IDL::ForwardInterface);

package CORBA::IDL::ForwardAbstractInterface;

use base qw(CORBA::IDL::ForwardInterface);

package CORBA::IDL::ForwardLocalInterface;

use base qw(CORBA::IDL::ForwardInterface);

#
#   3.8.6   Abstract Interface
#

package CORBA::IDL::AbstractInterface;

use base qw(CORBA::IDL::Interface);

sub _CheckInheritance {
    my $self = shift;
    my ($parser) = @_;
    if (exists $self->{inheritance}) {
        foreach (@{$self->{inheritance}->{list_interface}}) {
            my $base = $parser->YYData->{symbtab}->Lookup($_);
            # (An unconstrained interface may not inherit from a local interface.)
            # An abstract interface may only inherit from other abstract interfaces.
            unless ($base->isa('AbstractInterface')) {
                $parser->Error("'$_' is not abstract.\n");
            }
        }
    }
}

sub _CheckLocal {
    my $self = shift;
    my ($parser) = @_;

    # A local type may not appear as a parameter, attribute, return type, or exception
    # declaration of an unconstrained interface or as a state member of a valuetype.
    foreach (@{$self->{list_export}}) {
        my $defn = $parser->YYData->{symbtab}->Lookup($_);
        if      ($defn->isa('Attribute')) {
            if (CORBA::IDL::TypeDeclarator->IsaLocal($parser, $defn->{type})) {
                $parser->Error("'$self->{idf}' is not local.\n");
            }
        }
        elsif ($defn->isa('Operation')) {
            if (CORBA::IDL::TypeDeclarator->IsaLocal($parser, $defn->{type})) {
                $parser->Error("'$self->{idf}' is not local.\n");
            }
            foreach (@{$defn->{list_param}}) {
                if (CORBA::IDL::TypeDeclarator->IsaLocal($parser, $_->{type})) {
                    $parser->Error("'$self->{idf}' is not local.\n");
                }
            }
        }
    }
}

sub _CheckNative {
    my $self = shift;
    my ($parser) = @_;

    # If a native type is used as an exception for an operation, the
    # operation must appear in either a local interface or a valuetype.
    foreach (@{$self->{list_export}}) {
        my $defn = $parser->YYData->{symbtab}->Lookup($_);
        if (exists $defn->{list_raise}) {
            foreach (@{$defn->{list_raise}}) {
                my $except = $parser->YYData->{symbtab}->Lookup($_);
                if ($except->isa('NativeType')) {
                    $parser->Error("'$except->{idf}' used in a not local interface.\n");
                }
            }
        }
    }
}

#
#   3.8.7   Local Interface
#

package CORBA::IDL::LocalInterface;

use base qw(CORBA::IDL::Interface);

sub _CheckInheritance {
    # A local interface may inherit from other local or unconstrained interfaces
}

sub _CheckLocal {
    # Any IDL type, including an unconstrained interface, may appear as a parameter,
    # attribute, return type, or exception declaration of a local interface.

    # A local type may be used as a parameter, attribute, return type, or exception
    # declaration of a local interface or of a valuetype.
}

#
#   3.9     Value Declaration
#

package CORBA::IDL::Value;

use base qw(CORBA::IDL::BaseInterface);

#   3.9.1   Regular Value Type
#

package CORBA::IDL::RegularValue;

use base qw(CORBA::IDL::Value);

sub _CheckInheritance {
    my $self = shift;
    my ($parser) = @_;
    if (exists $self->{inheritance}) {
        if (    exists $self->{inheritance}->{modifier}     # truncatable
            and exists $self->{modifier} ) {                # custom
            $parser->Error("'truncatable' is used in a custom value.\n");
        }
        if (exists $self->{inheritance}->{list_interface}) {
            my $nb = 0;
            foreach (@{$self->{inheritance}->{list_interface}}) {
                my $base = $parser->YYData->{symbtab}->Lookup($_);
                if ($base->isa('RegularInterface')) {
                    $nb ++;
                }
            }
            $parser->Error("'$self->{idf}' inherits from more than once regular interface.\n")
                    if ($nb > 1);
        }
        if (exists $self->{inheritance}->{list_value}) {
            my $nb = 0;
            foreach (@{$self->{inheritance}->{list_value}}) {
                my $base = $parser->YYData->{symbtab}->Lookup($_);
                if ($base->isa('RegularValue')) {
                    $nb ++;
                }
                if ($base->isa('BoxedValue')) {
                    $parser->Error("'$_' is a boxed value.\n")
                }
            }
            $parser->Error("'$self->{idf}' inherits from more than once regular value.\n")
                    if ($nb > 1);
        }
    }
}

sub Configure {
    my $self = shift;
    my $parser = shift;
    $self->SUPER::Configure($parser, @_);
    my @list;
    foreach my $value_element (@{$self->{list_decl}}) {
        next unless (ref $value_element eq 'CORBA::IDL::StateMembers');
        foreach (@{$value_element->{list_decl}}) {
            push @list, $_;
            $self->{deprecated} = 1 if (CORBA::IDL::TypeDeclarator->IsDeprecated($parser, $_));
        }
    }
    $self->configure(list_member    =>  \@list);    # list of 'StateMember'
    return $self;
}

sub _CheckLocal {
    # A local type may be used as a parameter, attribute, return type, or exception
    # declaration of a local interface or of a valuetype.
}

#
#   3.9.1.4 State Members
#

package CORBA::IDL::StateMembers;

use base qw(CORBA::IDL::Node);

sub _Init {
    my $self = shift;
    my ($parser) = @_;
    CORBA::IDL::TypeDeclarator->CheckDeprecated($parser, $self->{type});
    CORBA::IDL::TypeDeclarator->CheckForward($parser, $self->{type});
    my @list;
    foreach (@{$self->{list_expr}}) {
        my $member;
        my @array_size = @{$_};
        my $idf = shift @array_size;
        if (@array_size) {
            $member = new CORBA::IDL::StateMember($parser,
                    declspec        =>  $self->{declspec},
                    props           =>  $self->{props},
                    modifier        =>  $self->{modifier},
                    type            =>  $self->{type},
                    idf             =>  $idf,
                    array_size      =>  \@array_size,
                    deprecated      =>  1,
            );
            $parser->Deprecated("Anonymous type (array).\n")
                    if ($CORBA::IDL::Parser::IDL_VERSION ge '2.4');
        }
        else {
            $member = new CORBA::IDL::StateMember($parser,
                    declspec        =>  $self->{declspec},
                    props           =>  $self->{props},
                    modifier        =>  $self->{modifier},
                    type            =>  $self->{type},
                    idf             =>  $idf,
                    deprecated      =>  CORBA::IDL::TypeDeclarator->IsDeprecated($parser, $self->{type}),
            );
        }
        push @list, $member->{full};
    }
    $self->configure(list_decl  =>  \@list);
    # A local type may not appear as a parameter, attribute, return type, or exception
    # declaration of an unconstrained interface or as a state member of a valuetype.
    if (CORBA::IDL::TypeDeclarator->IsaLocal($parser, $self->{type})) {
        my $idf = $self->{type}->{idf} if (exists $self->{type}->{idf});
        $idf ||= $self->{type};
        $parser->Error("'$idf' is local.\n");
    }
}

package CORBA::IDL::StateMember;            # modifier, idf, type[, array_size]

use base qw(CORBA::IDL::Node);

sub _Init {
    my $self = shift;
    my ($parser) = @_;
    $parser->YYData->{symbtab}->Insert($self);
    if (defined $parser->YYData->{curr_itf}) {
        $parser->YYData->{curr_itf}->{hash_attribute_operation}{$self->{idf}} = $self->{full}
    }
    else {
        $parser->Error(__PACKAGE__ . "::new ERROR_INTERNAL.\n");
    }
    if ($parser->YYData->{doc} ne q{}) {
        $self->{doc} = $parser->YYData->{doc};
        $parser->YYData->{doc} = q{};
    }
    $parser->YYData->{curr_node} = $self;
}

#
#   3.9.1.5 Initializers
#

package CORBA::IDL::Initializer;

use base qw(CORBA::IDL::Node);

sub _Init {
    my $self = shift;
    my ($parser) = @_;
    $parser->YYData->{symbtab}->Insert($self);
    $parser->YYData->{unnamed_symbtab} = new CORBA::IDL::UnnamedSymbtab($parser);
    if (defined $parser->YYData->{curr_itf}) {
        $self->{itf} = $parser->YYData->{curr_itf}->{full};
        $parser->YYData->{curr_itf}->{hash_attribute_operation}{$self->{idf}} = $self->{full}
    }
    else {
        $parser->Error(__PACKAGE__ . "::new ERROR_INTERNAL.\n");
    }
    if ($parser->YYData->{doc} ne q{}) {
        $self->{doc} = $parser->YYData->{doc};
        $parser->YYData->{doc} = q{};
    }
    $parser->YYData->{curr_node} = $self;
}

sub Configure {
    my $self = shift;
    my $parser = shift;
    $self->configure(@_);
    my @list_in = ();
    foreach ( @{$self->{list_param}} ) {
        if      ($_->{attr} eq 'in') {
            unshift @list_in, $_;
        }
    }
    $self->{list_in} = \@list_in;
    $self->{list_inout} = [];
    $self->{list_out} = [];
    return $self;
}

#
#   3.9.2   Boxed Value Type
#
package CORBA::IDL::BoxedValue;

use base qw(CORBA::IDL::Value);

sub _Init {
    my $self = shift;
    my ($parser) = @_;
    $self->{prefix} = $parser->YYData->{symbtab}->GetPrefix();
    $self->{_typeprefix} = $parser->YYData->{symbtab}->GetTypePrefix();
    $self->line_stamp($parser);
    if ($parser->YYData->{doc} ne q{}) {
        $self->{doc} = $parser->YYData->{doc};
        $parser->YYData->{doc} = q{};
    }
    $parser->YYData->{symbtab}->PushCurrentScope($self);
    $parser->YYData->{curr_itf} = $self;
    $parser->YYData->{curr_node} = $self;
}

sub Configure {
    my $self = shift;
    my $parser = shift;
    $self->configure(@_);
    my $type = CORBA::IDL::TypeDeclarator->GetDefn($parser, $self->{type});
    if ($type->isa('Value')) {
        if ($CORBA::IDL::Parser::IDL_VERSION ge '3.0') {
            $parser->Error("$self->{type}->{idf} is a value type.\n");
        }
        else {
            $parser->Info("$self->{type}->{idf} is a value type.\n");
        }
    }
    $self->{deprecated} = 1 if (CORBA::IDL::TypeDeclarator->IsDeprecated($parser, $type));
    return $self;
}

#
#   3.9.3   Abstract Value Type
#

package CORBA::IDL::AbstractValue;

use base qw(CORBA::IDL::Value);

sub _CheckInheritance {
    my $self = shift;
    my ($parser) = @_;
    if (exists $self->{inheritance}) {
        if (exists $self->{inheritance}->{list_interface}) {
            my $nb = 0;
            foreach (@{$self->{inheritance}->{list_interface}}) {
                my $base = $parser->YYData->{symbtab}->Lookup($_);
                if ($base->isa('RegularInterface')) {
                    $nb ++;
                }
            }
            $parser->Error("'$self->{idf}' inherits from more than once regular interface.\n")
                    if ($nb > 1);
        }
        if (exists $self->{inheritance}->{list_value}) {
            foreach (@{$self->{inheritance}->{list_value}}) {
                my $base = $parser->YYData->{symbtab}->Lookup($_);
                unless ($base->isa('AbstractValue')) {
                    $parser->Error("'$_' is not abstract value.\n");
                }
            }
        }
    }
}

sub _CheckLocal {
    # A local type may be used as a parameter, attribute, return type, or exception
    # declaration of a local interface or of a valuetype.
}

#
#   3.9.4   Value Forward Declaration
#

package CORBA::IDL::ForwardValue;

use base qw(CORBA::IDL::ForwardBaseInterface);

package CORBA::IDL::ForwardRegularValue;

use base qw(CORBA::IDL::ForwardValue);

package CORBA::IDL::ForwardAbstractValue;

use base qw(CORBA::IDL::ForwardValue);

#
#   3.10        Constant Declaration
#

package CORBA::IDL::Expression;

use base qw(CORBA::IDL::Node);

sub _Init {
    my $self = shift;
    my ($parser) = @_;
    if (      ! exists $self->{type} ) {
        $self->configure(
                type    =>  new CORBA::IDL::IntegerType($parser,
                                    value   =>  'unsigned long',
                                    auto    =>  1
                            )
        );
    }
    elsif (   @{$self->{list_expr}} == 1
            and defined $self->{list_expr}[0] ) {
        if (ref $self->{type}) {
            my $expr = $self->{list_expr}[0];
            if (      $self->{type}->isa('WideCharType')
                    and $expr->isa('CharacterLiteral') ) {
                $self->{list_expr} = [
                        new CORBA::IDL::WideCharacterLiteral($parser,
                                value   =>  $expr->{value}
                        )
                ];
            }
            elsif (   $self->{type}->isa('WideStringType')
                    and $expr->isa('StringLiteral') ) {
                $self->{list_expr} = [
                        new CORBA::IDL::WideStringLiteral($parser,
                                value   =>  $expr->{value}
                        )
                ];
            }
        }
    }
    $self->configure(
            value   =>  $self->Eval($parser)
    );
}

use Math::BigInt;
use Math::BigFloat;

use constant UCHAR_MAX      => new Math::BigInt(                 '255');
use constant SHRT_MIN       => new Math::BigInt(              '-32768');
use constant SHRT_MAX       => new Math::BigInt(               '32767');
use constant USHRT_MAX      => new Math::BigInt(               '65535');
use constant LONG_MIN       => new Math::BigInt(         '-2147483648');
use constant LONG_MAX       => new Math::BigInt(          '2147483647');
use constant ULONG_MAX      => new Math::BigInt(          '4294967295');
use constant LLONG_MIN      => new Math::BigInt('-9223372036854775808');
use constant LLONG_MAX      => new Math::BigInt( '9223372036854775807');
use constant ULLONG_MAX     => new Math::BigInt('18446744073709551615');
use constant FLT_MAX        => new Math::BigFloat(         '3.40282347e+38' );
use constant DBL_MAX        => new Math::BigFloat('1.79769313486231571e+308');
use constant LDBL_MAX       => new Math::BigFloat('1.79769313486231571e+308');
use constant FLT_MIN        => new Math::BigFloat(         '1.17549435e-38' );
use constant DBL_MIN        => new Math::BigFloat('2.22507385850720138e-308');
use constant LDBL_MIN       => new Math::BigFloat('2.22507385850720138e-308');

sub Eval {
    my $self = shift;
    my ($parser) = @_;
    my @list_expr = @{$self->{list_expr}};      # create a copy
    my $type = CORBA::IDL::TypeDeclarator->GetEffectiveType($parser, $self->{type});
    if (defined $type) {
        return _Eval($parser, $type, \@list_expr);
    }
    else {
        return 0;
    }
}

sub _EvalBinop {
    my ($parser, $type, $elt, $list_expr, $bypass) = @_;
    if (       $type->isa('IntegerType')
            or $type->isa('OctetType') ) {
        my $right = _Eval($parser, $type, $list_expr, 1);
        return undef unless (defined $right);
        my $left = _Eval($parser, $type, $list_expr, 1);
        return undef unless (defined $left);
        my $value = new Math::BigInt($left);
        if (    $elt->{op} eq '|' ) {
            $value->bior($right);
            return _CheckRange($parser, $type, $value, $bypass);
        }
        elsif ( $elt->{op} eq '^' ) {
            $value->bxor($right);
            return _CheckRange($parser, $type, $value, $bypass);
        }
        elsif ( $elt->{op} eq '&' ) {
            $value->band($right);
            return _CheckRange($parser, $type, $value, $bypass);
        }
        elsif ( $elt->{op} eq '+' ) {
            $value->badd($right);
            return _CheckRange($parser, $type, $value, $bypass);
        }
        elsif ( $elt->{op} eq '-' ) {
            $value->bsub($right);
            return _CheckRange($parser, $type, $value, $bypass);
        }
        elsif ( $elt->{op} eq '*' ) {
            $value->bmul($right);
            return _CheckRange($parser, $type, $value, $bypass);
        }
        elsif ( $elt->{op} eq '/' ) {
            $value->bdiv($right);
            return _CheckRange($parser, $type, $value, $bypass);
        }
        elsif ( $elt->{op} eq '%' ) {
            $value->bmod($right);
            return _CheckRange($parser, $type, $value, $bypass);
        }
        elsif ( $elt->{op} eq '>>' ) {
            if (0 <= $right and $right < 64) {
                $value->brsft($right);
                return _CheckRange($parser, $type, $value, $bypass);
            }
            else {
                $parser->Error("shift operation out of range.\n");
                return undef;
            }
        }
        elsif ( $elt->{op} eq '<<' ) {
            if (0 <= $right and $right < 64) {
                $value->blsft($right);
                return _CheckRange($parser, $type, $value, $bypass);
            }
            else {
                $parser->Error("shift operation out of range.\n");
                return undef;
            }
        }
        else {
            $parser->Error("_BinopEval (int) : INTERNAL ERROR.\n");
            return undef;
        }
    }
    elsif (  $type->isa('FloatingPtType') ) {
        my $right = _Eval($parser, $type, $list_expr);
        return undef unless (defined $right);
        my $left = _Eval($parser, $type, $list_expr);
        return undef unless (defined $left);
        my $value = new Math::BigFloat($left);
        if (    $elt->{op} eq '+' ) {
            $value->fadd($right);
            return _CheckRange($parser, $type, $value);
        }
        elsif ( $elt->{op} eq '-' ) {
            $value->fsub($right);
            return _CheckRange($parser, $type, $value);
        }
        elsif ( $elt->{op} eq '*' ) {
            $value->fmul($right);
            return _CheckRange($parser, $type, $value);
        }
        elsif ( $elt->{op} eq '/' ) {
            $value->fdiv($right);
            return _CheckRange($parser, $type, $value);
        }
        elsif (  $elt->{op} eq '|'
                or $elt->{op} eq '^'
                or $elt->{op} eq '&'
                or $elt->{op} eq '>>'
                or $elt->{op} eq '<<'
                or $elt->{op} eq '%' ) {
            $parser->Error("'$elt->{op}' is not valid for '$type'.\n");
        }
        else {
            $parser->Error("_EvalBinop (fp) : INTERNAL ERROR.\n");
            return undef;
        }
    }
    elsif (  $type->isa('FixedPtConstType') ) {
        my $right = _Eval($parser, $type, $list_expr);
        return undef unless (defined $right);
        my $left = _Eval($parser, $type, $list_expr);
        return undef unless (defined $left);
        my $value = new Math::BigFloat($left);
        if (    $elt->{op} eq '+' ) {
            $value->fadd($right);
            return _CheckRange($parser, $type, $value);
        }
        elsif ( $elt->{op} eq '-' ) {
            $value->fsub($right);
            return _CheckRange($parser, $type, $value);
        }
        elsif ( $elt->{op} eq '*' ) {
            $value->fmul($right);
            return _CheckRange($parser, $type, $value);
        }
        elsif ( $elt->{op} eq '/' ) {
            $value->fdiv($right);
            return _CheckRange($parser, $type, $value);
        }
        elsif (  $elt->{op} eq '|'
                or $elt->{op} eq '^'
                or $elt->{op} eq '&'
                or $elt->{op} eq '>>'
                or $elt->{op} eq '<<'
                or $elt->{op} eq '%' ) {
            $parser->Error("'$elt->{op}' is not valid for '$type'.\n");
            return undef;
        }
        else {
            $parser->Error("_EvalBinop (fixed) : INTERNAL ERROR.\n");
            return undef;
        }
    }
    else {
        $parser->Error("'$type->{value}' can't use expression.\n");
        return undef;
    }
}

sub _EvalUnop {
    my ($parser, $type, $elt, $list_expr, $bypass) = @_;
    if (       $type->isa('IntegerType')
            or $type->isa('OctetType') ) {
        my $right = _Eval($parser, $type, $list_expr, 1);
        return undef unless (defined $right);
        my $value = new Math::BigInt($right);
        if (    $elt->{op} eq '+' ) {
            return _CheckRange($parser, $type, $right, $bypass);
        }
        elsif ( $elt->{op} eq '-' ) {
            $value->bneg();
            return _CheckRange($parser, $type, $value, $bypass);
        }
        elsif ( $elt->{op} eq '~' ) {
            my $cpl;
            if    ($type->{value} eq 'short') {
                $cpl = USHRT_MAX;
            }
            elsif ($type->{value} eq 'unsigned short') {
                $cpl = USHRT_MAX;
            }
            elsif ($type->{value} eq 'long') {
                $cpl = ULONG_MAX;
            }
            elsif ($type->{value} eq 'unsigned long') {
                $cpl = ULONG_MAX;
            }
            elsif ($type->{value} eq 'long long') {
                $cpl = ULLONG_MAX;
            }
            elsif ($type->{value} eq 'unsigned long long') {
                $cpl = ULLONG_MAX;
            }
            elsif ($type->{value} eq 'octet') {
                $cpl = UCHAR_MAX;
            }
            $value->bxor($cpl);
            return _CheckRange($parser, $type, $value, $bypass);
        }
        else {
            $parser->Error("_EvalUnop (int) : INTERNAL ERROR.\n");
            return undef;
        }
    }
    elsif (  $type->isa('FloatingPtType') ) {
        my $right = _Eval($parser, $type, $list_expr);
        return undef unless (defined $right);
        my $value = new Math::BigFloat($right);
        if (    $elt->{op} eq '+' ) {
            return _CheckRange($parser, $type, $right);
        }
        elsif ( $elt->{op} eq '-' ) {
            $value->fneg();
            return _CheckRange($parser, $type, $value);
        }
        elsif (  $elt->{op} eq '~' ) {
            $parser->Error("'$elt->{op}' is not valid for '$type'.\n");
            return undef;
        }
        else {
            $parser->Error("_EvalUnop (fp) : INTERNAL ERROR.\n");
            return undef;
        }
    }
    elsif (  $type->isa('FixedPtConstType') ) {
        my $right = _Eval($parser, $type, $list_expr);
        return undef unless (defined $right);
        my $value = new Math::BigFloat($right);
        if (    $elt->{op} eq '+' ) {
            return _CheckRange($parser, $type, $right);
        }
        elsif ( $elt->{op} eq '-' ) {
            $value->fneg();
            return _CheckRange($parser, $type, $value);
        }
        elsif (  $elt->{op} eq '~' ) {
            $parser->Error("'$elt->{op}' is not valid for '$type'.\n");
            return undef;
        }
        else {
            $parser->Error("_EvalUnop (fixed) : INTERNAL ERROR.\n");
            return undef;
        }
    }
    else {
        $parser->Error("'$type->{value}' can't use expression.\n");
        return undef;
    }
}

sub _Eval {
    my ($parser, $type, $list_expr, $bypass) = @_;
    my $elt = pop @$list_expr;
    return undef unless (defined $elt);
    return undef unless ($elt);
    unless (ref $elt) {
        $elt = $parser->YYData->{symbtab}->Lookup($elt);
        return undef unless (defined $elt);
    }
    if    ($elt->isa('BinaryOp'))   {
        return _EvalBinop($parser, $type, $elt, $list_expr, $bypass);
    }
    elsif ($elt->isa('UnaryOp')) {
        return _EvalUnop($parser, $type, $elt, $list_expr, $bypass);
    }
    elsif ($elt->isa('Constant')) {
        if (ref $type eq ref $elt->{value}->{type}) {
            return _CheckRange($parser, $type, $elt->{value}->{value}, $bypass);
        }
        elsif ($type->isa('IntegerType') and $elt->{value}->{type}->isa('OctetType')) {
            return _CheckRange($parser, $type, $elt->{value}->{value}, $bypass);
        }
        else {
            $parser->Error("'$elt->{value}->{value}' is not a '$type->{value}'.\n");
            return undef;
        }
    }
    elsif ($elt->isa('Enum')) {
        if ($type eq $parser->YYData->{symbtab}->Lookup($elt->{type})) {
            return $elt;
        }
        else {
            $parser->Error("'$elt->{idf}' is not a '$type->{idf}'.\n");
            return undef;
        }
    }
    elsif ($elt->isa('IntegerLiteral')) {
        if ($type->isa('IntegerType')) {
            return _CheckRange($parser, $type, $elt->{value}, $bypass);
        }
        elsif ($type->isa('OctetType')) {
            return _CheckRange($parser, $type, $elt->{value}, $bypass);
        }
        else {
            $parser->Error("'$elt->{value}' is not a '$type->{value}'.\n");
            return undef;
        }
    }
    elsif ($elt->isa('StringLiteral')) {
        if ($type->isa('StringType')) {
            return _CheckRange($parser, $type, $elt->{value});
        }
        else {
            $parser->Error("'$elt->{value}' is not a '$type->{value}'.\n");
            return undef;
        }
    }
    elsif ($elt->isa('WideStringLiteral')) {
        if ($type->isa('WideStringType')) {
            return _CheckRange($parser, $type, $elt->{value});
        }
        else {
            $parser->Error("'$elt->{value}' is not a '$type->{value}'.\n");
            return undef;
        }
    }
    elsif ($elt->isa('CharacterLiteral')) {
        if ($type->isa('CharType')) {
            return $elt->{value};
        }
        else {
            $parser->Error("'$elt->{value}' is not a '$type->{value}'.\n");
            return undef;
        }
    }
    elsif ($elt->isa('WideCharacterLiteral')) {
        if ($type->isa('WideCharType')) {
            return $elt->{value};
        }
        else {
            $parser->Error("'$elt->{value}' is not a '$type->{value}'.\n");
            return undef;
        }
    }
    elsif ($elt->isa('FixedPtLiteral')) {
        if ($type->isa('FixedPtConstType')) {
            return _CheckRange($parser, $type, $elt->{value});
        }
        else {
            $parser->Error("'$elt->{value}' is not a '$type->{value}'.\n");
            return undef;
        }
    }
    elsif ($elt->isa('FloatingPtLiteral')) {
        if ($type->isa('FloatingPtType')) {
            return _CheckRange($parser, $type, $elt->{value});
        }
        else {
            $parser->Error("'$elt->{value}' is not a '$type->{value}'.\n");
            return undef;
        }
    }
    elsif ($elt->isa('BooleanLiteral')) {
        if ($type->isa('BooleanType')) {
            return $elt->{value};
        }
        else {
            $parser->Error("'$elt->{value}' is not a '$type->{value}'.\n");
            return undef;
        }
    }
    else {
        $parser->Error("_Eval: INTERNAL ERROR ",ref $elt," .\n");
        return undef;
    }
}

sub _CheckRange {
    my ($parser, $type, $value, $bypass) = @_;
    return $value if (defined $bypass);
    if (       $type->isa('IntegerType') ) {
        if (   $type->{value} eq 'short' ) {
            if ($value >= SHRT_MIN and $value <= SHRT_MAX) {
                return $value;
            }
            else {
                $parser->Error("'$type->{value}' $value is out of range.\n");
                return undef;
            }
        }
        elsif ($type->{value} eq 'long') {
            if ($value >= LONG_MIN and $value <= LONG_MAX) {
                return $value;
            }
            else {
                $parser->Error("'$type->{value}' $value is out of range.\n");
                return undef;
            }
        }
        elsif ($type->{value} eq 'long long') {
            if ($value >= LLONG_MIN and $value <= LLONG_MAX) {
                return $value;
            }
            else {
                $parser->Error("'$type->{value}' $value is out of range.\n");
                return undef;
            }
        }
        elsif ($type->{value} eq 'unsigned short') {
            if ($value >= 0 and $value <= USHRT_MAX) {
                return $value;
            }
            else {
                $parser->Error("'$type->{value}' $value is out of range.\n");
                return undef;
            }
        }
        elsif ($type->{value} eq 'unsigned long') {
            if ($value >= 0 and $value <= ULONG_MAX) {
                return $value;
            }
            else {
                $parser->Error("'$type->{value}' $value is out of range.\n");
                return undef;
            }
        }
        elsif ($type->{value} eq 'unsigned long long') {
            if ($value >= 0 and $value <= ULLONG_MAX) {
                return $value;
            }
            else {
                $parser->Error("'$type->{value}' $value is out of range.\n");
                return undef;
            }
        }
        else {
            $parser->Error("_CheckRange IntegerType : INTERNAL ERROR.\n");
            return undef;
        }
    }
    elsif (  $type->isa('OctetType') ) {
        if ($value >= 0 and $value <= UCHAR_MAX) {
            return $value;
        }
        else {
            $parser->Error("'$type->{value}' $value is out of range.\n");
            return undef;
        }
    }
    elsif (  $type->isa('FloatingPtType') ) {
        return $value if ($value == 0);
        my $abs_v = abs $value;
        if (   $type->{value} eq 'float' ) {
            if ($abs_v >= FLT_MIN and $abs_v <= FLT_MAX) {
                return $value;
            }
            else {
                $parser->Error("'$type->{value}' $value is out of range.\n");
                return undef;
            }
        }
        elsif ($type->{value} eq 'double') {
            if ($abs_v >= DBL_MIN and $abs_v <= DBL_MAX) {
                return $value;
            }
            else {
                $parser->Error("'$type->{value}' $value is out of range.\n");
                return undef;
            }
        }
        elsif ($type->{value} eq 'long double') {
            if ($abs_v >= LDBL_MIN and $abs_v <= LDBL_MAX) {
                return $value;
            }
            else {
                $parser->Error("'$type->{value}' $value is out of range.\n");
                return undef;
            }
        }
        else {
            $parser->Error("_CheckRange FloatingPtType : INTERNAL ERROR.\n");
            return undef;
        }
    }
    elsif (  $type->isa('FixedPtConstType') ) {
        return $value;
    }
    elsif (  $type->isa('StringType')
            or $type->isa('WideStringType') ) {
        if (exists $type->{max}) {
            my @lst = split //, $value;
            my $len = @lst;
            if ($len <= $type->{max}->{value}) {
                return $value;
            }
            else {
                $parser->Error("'$type->{value}' '$value' is out of range.\n");
                return undef;
            }
        }
        return $value;
    }
}

package CORBA::IDL::Constant;

use base qw(CORBA::IDL::Node);

sub _Init {
    my $self = shift;
    my ($parser) = @_;
    $self->line_stamp($parser);
    if ($parser->YYData->{doc} ne q{}) {
        $self->{doc} = $parser->YYData->{doc};
        $parser->YYData->{doc} = q{};
    }
    $self->{prefix} = $parser->YYData->{symbtab}->GetPrefix();
    $self->{_typeprefix} = $parser->YYData->{symbtab}->GetTypePrefix();
    $parser->YYData->{symbtab}->Insert($self);
    my $type = $self->{type};
    CORBA::IDL::TypeDeclarator->CheckDeprecated($parser, $type);
    my $defn = CORBA::IDL::TypeDeclarator->GetEffectiveType($parser, $type);
    if (defined $defn) {
        if (        ! $defn->isa('IntegerType')
                and ! $defn->isa('EnumType')
                and ! $defn->isa('OctetType')
                and ! $defn->isa('CharType')
                and ! $defn->isa('StringType')
                and ! $defn->isa('BooleanType')
                and ! $defn->isa('FloatingPtType')
                and ! $defn->isa('WideCharType')
                and ! $defn->isa('WideStringType')
                and ! $defn->isa('FixedPtConstType') ) {
            my $idf = $defn->{idf} if (exists $defn->{idf});
            $idf ||= $type->{idf} if (exists $type->{idf});
            $idf ||= $type;
            $parser->Error("'$idf' refers a bad type for constant.\n");
            return $self;
        }
    }
    else {
        $parser->Error(__PACKAGE__ . "::_Init ERROR_INTERNAL ($type).\n");
    }
    $self->configure(
            value   =>  new CORBA::IDL::Expression($parser,
                                type        =>  $defn,
                                list_expr   =>  $self->{list_expr}
                        )
    );
    $parser->YYData->{curr_node} = $self;
}

sub Lookup {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    $class = substr $class, rindex($class, ':') + 1;
    my ($parser, $name) = @_;
    my $defn = $parser->YYData->{symbtab}->Lookup($name);
    if (defined $defn) {
        if (        ! $defn->isa($class)
                and ! $defn->isa('Enum') ) {
            $parser->Error("'$name' is not a $class.\n");
        }
        return $defn->{full};
    }
    else {
        return q{};
    }
}

package CORBA::IDL::UnaryOp;

use base qw(CORBA::IDL::Node);

package CORBA::IDL::BinaryOp;

use base qw(CORBA::IDL::Node);

#
#   3.2.5   Literals
#

package CORBA::IDL::Literal;

use base qw(CORBA::IDL::Node);

package CORBA::IDL::IntegerLiteral;

use base qw(CORBA::IDL::Literal);

package CORBA::IDL::StringLiteral;

use base qw(CORBA::IDL::Literal);

package CORBA::IDL::WideStringLiteral;

use base qw(CORBA::IDL::Literal);

package CORBA::IDL::CharacterLiteral;

use base qw(CORBA::IDL::Literal);

package CORBA::IDL::WideCharacterLiteral;

use base qw(CORBA::IDL::Literal);

package CORBA::IDL::FixedPtLiteral;

use base qw(CORBA::IDL::Literal);

package CORBA::IDL::FloatingPtLiteral;

use base qw(CORBA::IDL::Literal);

package CORBA::IDL::BooleanLiteral;

use base qw(CORBA::IDL::Literal);

#
#   3.11    Type Declaration
#

package CORBA::IDL::TypeDeclarators;

use base qw(CORBA::IDL::Node);

sub _Init {
    my $self = shift;
    my ($parser) = @_;
    $self->line_stamp($parser);
    my @list;
    foreach (@{$self->{list_expr}}) {
        my @array_size = @{$_};
        my $idf = shift @array_size;
        my $decl;
        if (@array_size) {
            $decl = new CORBA::IDL::TypeDeclarator($parser,
                    type                =>  $self->{type},
                    idf                 =>  $idf,
                    array_size          =>  \@array_size
            );
            CORBA::IDL::TypeDeclarator->CheckDeprecated($parser, $self->{type});
        }
        else {
            $decl = new CORBA::IDL::TypeDeclarator($parser,
                    type                =>  $self->{type},
                    idf                 =>  $idf
            );
        }
        push @list, $decl->{full};
    }
    $self->configure(list_decl  =>  \@list);
}

sub Configure {
    my $self = shift;
    my $parser = shift;
    $self->configure(@_);
    foreach (@{$self->{list_decl}}) {
        my $defn = $parser->YYData->{symbtab}->Lookup($_);
        $defn->configure(@_);
    }
    return $self;
}

package CORBA::IDL::TypeDeclarator;

use base qw(CORBA::IDL::Node);

sub _Init {
    my $self = shift;
    my ($parser) = @_;
    $self->{prefix} = $parser->YYData->{symbtab}->GetPrefix();
    $self->{_typeprefix} = $parser->YYData->{symbtab}->GetTypePrefix();
    $self->line_stamp($parser);
    if ($parser->YYData->{doc} ne q{}) {
        $self->{doc} = $parser->YYData->{doc};
        $parser->YYData->{doc} = q{};
    }
    $parser->YYData->{symbtab}->Insert($self);
    $parser->YYData->{curr_node} = $self;
    $self->{local_type} = 1 if (CORBA::IDL::TypeDeclarator->IsaLocal($parser, $self->{type}));
    $self->{deprecated} = 1 if (CORBA::IDL::TypeDeclarator->IsDeprecated($parser, $self->{type}));
}

sub Lookup {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    $class = substr $class, rindex($class, ':') + 1;
    my ($parser, $name) = @_;
    my $defn = $parser->YYData->{symbtab}->Lookup($name);
    if (defined $defn) {
        if (        ! $defn->isa($class)
                and ! $defn->isa('NativeType')
                and ! $defn->isa('_ConstructedType')
                and ! $defn->isa('_ForwardConstructedType')
                and ! $defn->isa('BaseInterface')
                and ! $defn->isa('ForwardBaseInterface') ) {
            $parser->Error("'$name' is not a type nor a value.\n");
        }
        return $defn->{full};
    }
    else {
        return q{};
    }
}

sub GetDefn {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my ($parser, $type) = @_;
    return undef unless ($type);
    if (ref $type) {
        return $type;
    }
    else {
        my $defn = $parser->YYData->{symbtab}->Lookup($type);
        return $defn;
    }
}

sub GetEffectiveType {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my ($parser, $type) = @_;
    my $defn = CORBA::IDL::TypeDeclarator->GetDefn($parser, $type);
    unless (defined $defn) {
        $parser->Error(__PACKAGE__ . "::GetEffectiveType ERROR_INTERNAL ($type).\n");
        return undef;
    }
    while (     $defn->isa('TypeDeclarator')
            and ! exists $defn->{array_size} ) {
        $defn = CORBA::IDL::TypeDeclarator->GetDefn($parser, $defn->{type});
        unless (defined $defn) {
            $parser->Error(__PACKAGE__ . "::GetEffectiveType ERROR_INTERNAL ($defn->{type}).\n");
            return undef;
        }
    }
    return $defn;
}

sub CheckDeprecated {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my ($parser, $type) = @_;
    my $defn = CORBA::IDL::TypeDeclarator->GetDefn($parser, $type);
    return unless (defined $defn);
    if (       $defn->isa('StringType')
            or $defn->isa('WideStringType') ) {
        if (exists $defn->{max}) {
            $defn->configure(deprecated =>  1);
            $parser->Deprecated("Anonymous type.\n")
                    if ($CORBA::IDL::Parser::IDL_VERSION ge '2.4');
        }
    }
    elsif   (  $defn->isa('FixedPtType') ) {
        $defn->configure(deprecated =>  1);
        $parser->Deprecated("Anonymous type.\n")
                if ($CORBA::IDL::Parser::IDL_VERSION ge '2.4');
    }
    elsif   (  $defn->isa('SequenceType') ) {
        $defn->configure(deprecated =>  1);
        $parser->Deprecated("Anonymous type.\n")
                if ($CORBA::IDL::Parser::IDL_VERSION ge '2.4');
    }
}

sub IsDeprecated {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my ($parser, $type) = @_;
    my $defn = CORBA::IDL::TypeDeclarator->GetDefn($parser, $type);
    return (exists $defn->{deprecated} ? 1 : undef);
}

sub CheckForward {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my ($parser, $type) = @_;
    my $defn = CORBA::IDL::TypeDeclarator->GetDefn($parser, $type);
    return unless (defined $defn);
    while (        $defn->isa('SequenceType')
                or $defn->isa('TypeDeclarator') ) {
        last if (exists $defn->{array_size});
        $defn = CORBA::IDL::TypeDeclarator->GetDefn($parser, $defn->{type});
        return unless (defined $defn);
    }
    if ($defn->isa('_ForwardConstructedType')) {
        $parser->Error("'$defn->{idf}' is declared, but not defined.\n");
    }
}

sub IsaLocal {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my ($parser, $type) = @_;
    return undef unless ($type);
    my $defn = CORBA::IDL::TypeDeclarator->GetDefn($parser, $type);
    return exists $defn->{local_type} if ($defn);
    $parser->Error(__PACKAGE__ . "::IsaLocal ERROR_INTERNAL ($type).\n");
    return undef;
}

package CORBA::IDL::NativeType;

use base qw(CORBA::IDL::Node);

sub _Init {
    my $self = shift;
    my ($parser) = @_;
    $self->{prefix} = $parser->YYData->{symbtab}->GetPrefix();
    $self->{_typeprefix} = $parser->YYData->{symbtab}->GetTypePrefix();
    $self->line_stamp($parser);
    if ($parser->YYData->{doc} ne q{}) {
        $self->{doc} = $parser->YYData->{doc};
        $parser->YYData->{doc} = q{};
    }
    $parser->YYData->{symbtab}->Insert($self);
    $parser->YYData->{curr_node} = $self;
}

sub Configure {
    my $self = shift;
    my $parser = shift;
    $self->configure(@_);
}

#
#   3.11.1  Basic Types
#

package CORBA::IDL::BasicType;

use base qw(CORBA::IDL::Node);

package CORBA::IDL::FloatingPtType;

use base qw(CORBA::IDL::BasicType);

package CORBA::IDL::IntegerType;

use base qw(CORBA::IDL::BasicType);

package CORBA::IDL::CharType;

use base qw(CORBA::IDL::BasicType);

package CORBA::IDL::WideCharType;

use base qw(CORBA::IDL::BasicType);

package CORBA::IDL::BooleanType;

use base qw(CORBA::IDL::BasicType);

package CORBA::IDL::OctetType;

use base qw(CORBA::IDL::BasicType);

package CORBA::IDL::AnyType;

use base qw(CORBA::IDL::BasicType);

package CORBA::IDL::ObjectType;

use base qw(CORBA::IDL::BasicType);

package CORBA::IDL::ValueBaseType;

use base qw(CORBA::IDL::BasicType);

#
#   3.11.2  Constructed Types
#

package CORBA::IDL::_ConstructedType;

use base qw(CORBA::IDL::Node);

#   3.11.2.1    Structures
#

package CORBA::IDL::StructType;

use base qw(CORBA::IDL::_ConstructedType);

sub _Init {
    my $self = shift;
    my ($parser) = @_;
    $self->{prefix} = $parser->YYData->{symbtab}->GetPrefix();
    $self->{_typeprefix} = $parser->YYData->{symbtab}->GetTypePrefix();
    $self->line_stamp($parser);
    if ($parser->YYData->{doc} ne q{}) {
        $self->{doc} = $parser->YYData->{doc};
        $parser->YYData->{doc} = q{};
    }
    $parser->YYData->{symbtab}->PushCurrentScope($self);
    $parser->YYData->{curr_node} = $self;
}

sub Configure {
    my $self = shift;
    my $parser = shift;
    $self->configure(@_);
    my @list;
    foreach (@{$self->{list_expr}}) {
        foreach (@{$_->{list_member}}) {
            push @list, $_;
            $self->{deprecated} = 1 if (CORBA::IDL::TypeDeclarator->IsDeprecated($parser, $_));
        }
        $self->{local_type} = 1 if (CORBA::IDL::TypeDeclarator->IsaLocal($parser, $_->{type}));
    }
    $self->configure(list_member    =>  \@list);    # list of 'Member'
    return $self;
}

package CORBA::IDL::Members;

use base qw(CORBA::IDL::Node);

sub _Init {
    my $self = shift;
    my ($parser) = @_;
    CORBA::IDL::TypeDeclarator->CheckDeprecated($parser, $self->{type});
    CORBA::IDL::TypeDeclarator->CheckForward($parser, $self->{type});
    my @list;
    foreach (@{$self->{list_expr}}) {
        my $member;
        my @array_size = @{$_};
        my $idf = shift @array_size;
        if (@array_size) {
            $member = new CORBA::IDL::Member($parser,
                    props           =>  $self->{props},
                    type            =>  $self->{type},
                    idf             =>  $idf,
                    array_size      =>  \@array_size,
                    deprecated      =>  1,
            );
            $parser->Deprecated("Anonymous type (array).\n")
                    if ($CORBA::IDL::Parser::IDL_VERSION ge '2.4');
        }
        else {
            $member = new CORBA::IDL::Member($parser,
                    props           =>  $self->{props},
                    type            =>  $self->{type},
                    idf             =>  $idf,
                    deprecated      =>  CORBA::IDL::TypeDeclarator->IsDeprecated($parser, $self->{type}),
            );
        }
        push @list, $member->{full};
    }
    $self->configure(list_member    =>  \@list);
}

package CORBA::IDL::Member;                         # idf, type[, array_size]

use base qw(CORBA::IDL::Node);

sub _Init {
    my $self = shift;
    my ($parser) = @_;
    $parser->YYData->{symbtab}->Insert($self);
    if ($parser->YYData->{doc} ne q{}) {
        $self->{doc} = $parser->YYData->{doc};
        $parser->YYData->{doc} = q{};
    }
    $parser->YYData->{curr_node} = $self;
}

#   3.11.2.2    Discriminated Unions
#

package CORBA::IDL::UnionType;

use base qw(CORBA::IDL::_ConstructedType);

sub _Init {
    my $self = shift;
    my ($parser) = @_;
    $self->{prefix} = $parser->YYData->{symbtab}->GetPrefix();
    $self->{_typeprefix} = $parser->YYData->{symbtab}->GetTypePrefix();
    $self->line_stamp($parser);
    if ($parser->YYData->{doc} ne q{}) {
        $self->{doc} = $parser->YYData->{doc};
        $parser->YYData->{doc} = q{};
    }
    $parser->YYData->{symbtab}->PushCurrentScope($self);
    $parser->YYData->{curr_node} = $self;
}

sub Configure {
    my $self = shift;
    my $parser = shift;
    $self->configure(@_);
    my $dis = $self->{type};
    my $defn = CORBA::IDL::TypeDeclarator->GetEffectiveType($parser, $dis);
    if (defined $defn) {
        if (        ! $defn->isa('IntegerType')
                and ! $defn->isa('CharType')
                and ! $defn->isa('BooleanType')
                and ! $defn->isa('EnumType') ) {
            my $idf = $defn->{idf} if (exists $defn->{idf});
            $idf ||= $dis->{idf} if (exists $dis->{idf});
            $idf ||= $dis;
            $parser->Error("'$idf' refers a bad type for union discriminator.\n");
            return $self;
        }
    }
    my %hash;
    my @list_all;
    foreach my $case (@{$self->{list_expr}}) {
        my $elt = $case->{element};
        $self->{local_type} = 1 if (CORBA::IDL::TypeDeclarator->IsaLocal($parser, $elt->{type}));
        $self->{deprecated} = 1 if (CORBA::IDL::TypeDeclarator->IsDeprecated($parser, $elt->{value}));
        my @list;
        foreach (@{$case->{list_label}}) {
            my $key;
            if (ref $_ eq 'CORBA::IDL::Default') {
                $key = 'Default';
                push @list, $_;
                $self->configure(default    =>  $case);
            }
            else {
                # now, type is known
                my $cst = new CORBA::IDL::Expression($parser,
                        type                =>  $dis,
                        list_expr           =>  $_
                );
                if ($defn->isa('EnumType')) {
                    $key = $cst->{value}->{full};
                }
                else {
                    $key = $cst->{value};
                }
                push @list, $cst;
                push @list_all, $cst;
            }
            if (defined $key) {
                if (exists $hash{$key}) {
                    $parser->Error("label value '$key' is duplicate for union.\n");
                }
                else {
                    $hash{$key} = $elt;
                }
            }
        }
        $case->{list_label} = \@list;
    }
    $self->configure(list_member    =>  \@list_all);
    $self->configure(hash_member    =>  \%hash);
    if ($defn->isa('EnumType')) {
        my $all = 1;
        foreach (@{$defn->{list_member}}) {
            $all = 0 unless (exists $hash{$_});
        }
        if ($all) {
            $parser->Error("illegal label 'default'.\n")
                    if (exists $self->{default});
        }
        else {
            $self->configure(need_default   =>  1)
                    unless (exists $self->{default});
        }
    }
    else {
        $self->configure(need_default   =>  1)
                unless (exists $self->{default});
    }
    return $self;
}

package CORBA::IDL::Case;

use base qw(CORBA::IDL::Node);

package CORBA::IDL::Default;

use base qw(CORBA::IDL::Node);

package CORBA::IDL::Element;

use base qw(CORBA::IDL::Node);

sub _Init {
    my $self = shift;
    my ($parser) = @_;
    CORBA::IDL::TypeDeclarator->CheckDeprecated($parser, $self->{type});
    CORBA::IDL::TypeDeclarator->CheckForward($parser, $self->{type});
    my @array_size = @{$self->{list_expr}};
    my $idf = shift @array_size;
    my $value;
    if (@array_size) {
        $value = new CORBA::IDL::Member($parser,
                type            =>  $self->{type},
                idf             =>  $idf,
                array_size      =>  \@array_size,
                deprecated      =>  1,
        );
        $parser->Deprecated("Anonymous type (array).\n")
                if ($CORBA::IDL::Parser::IDL_VERSION ge '2.4');
    }
    else {
        $value = new CORBA::IDL::Member($parser,
                type            =>  $self->{type},
                idf             =>  $idf,
                deprecated      =>  CORBA::IDL::TypeDeclarator->IsDeprecated($parser, $self->{type}),
        );
    }
    $self->configure(value  =>  $value->{full});    # 'Member'
}

#   3.11.2.3    Constructed Recursive Types and Forward Declarations
#

package CORBA::IDL::_ForwardConstructedType;

use base qw(CORBA::IDL::Node);

sub _Init {
    my $self = shift;
    my ($parser) = @_;
    $self->{prefix} = $parser->YYData->{symbtab}->GetPrefix();
    $self->{_typeprefix} = $parser->YYData->{symbtab}->GetTypePrefix();
    $self->line_stamp($parser);
    $parser->YYData->{symbtab}->InsertForward($self);
    $parser->Error("Forward constructed not supported.\n")
            if ($parser->YYData->{forward_constructed_forbidden});

}

package CORBA::IDL::ForwardStructType;

use base qw(CORBA::IDL::_ForwardConstructedType);

package CORBA::IDL::ForwardUnionType;

use base qw(CORBA::IDL::_ForwardConstructedType);

#   3.11.2.4    Enumerations
#

package CORBA::IDL::EnumType;

use base qw(CORBA::IDL::_ConstructedType);

use constant ULONG_MAX      => 4294967295;

sub _Init {
    my $self = shift;
    my ($parser) = @_;
    $self->{prefix} = $parser->YYData->{symbtab}->GetPrefix();
    $self->{_typeprefix} = $parser->YYData->{symbtab}->GetTypePrefix();
    $self->line_stamp($parser);
    if ($parser->YYData->{doc} ne q{}) {
        $self->{doc} = $parser->YYData->{doc};
        $parser->YYData->{doc} = q{};
    }
    $parser->YYData->{symbtab}->Insert($self);
    $parser->YYData->{curr_node} = $self;
}

sub Configure {
    my $self = shift;
    my $parser = shift;
    $self->configure(@_);
    my $idx = 0;                        # Section 15.3 CDR Transfer Syntax
                                        # 15.3.2.6 Enum
    my %hash;
    my @list;
    foreach (@{$self->{list_expr}}) {
        if (exists $hash{$_->{idf}}) {
            $parser->Error("enum '$_->{idf}' is duplicate.\n");
        }
        else {
            $hash{$_->{idf}} = $idx;
            push @list, $_->{full};
        }
        $_->configure(
                type        =>  $self->{full},
                value       =>  "$idx"
        );
        $idx++;
    }
    $self->configure(list_member    =>  \@list);    # list of 'Enum'    #### ????
    if ($idx > ULONG_MAX) {
        $parser->Error("too many enum for '$self->{idf}'.\n");
    }
    return $self;
}

package CORBA::IDL::Enum;

use base qw(CORBA::IDL::Node);

sub _Init {
    my $self = shift;
    my ($parser) = @_;
    if ($parser->YYData->{doc} ne q{}) {
        $self->{doc} = $parser->YYData->{doc};
        $parser->YYData->{doc} = q{};
    }
    $parser->YYData->{symbtab}->Insert($self);
    $parser->YYData->{curr_node} = $self;
}

#
#   3.11.3  Template Types
#

package CORBA::IDL::_TemplateType;

use base qw(CORBA::IDL::Node);

package CORBA::IDL::SequenceType;

use base qw(CORBA::IDL::_TemplateType);

sub _Init {
    my $self = shift;
    my ($parser) = @_;
    $self->line_stamp($parser);
    $parser->YYData->{symbtab}->InsertBogus($self);
    CORBA::IDL::TypeDeclarator->CheckDeprecated($parser, $self->{type});
    $self->{local_type} = 1 if (CORBA::IDL::TypeDeclarator->IsaLocal($parser, $self->{type}));
}

package CORBA::IDL::StringType;

use base qw(CORBA::IDL::_TemplateType);

package CORBA::IDL::WideStringType;

use base qw(CORBA::IDL::_TemplateType);

package CORBA::IDL::FixedPtType;

use base qw(CORBA::IDL::_TemplateType);

sub _Init {
    my $self = shift;
    my ($parser) = @_;
    $self->line_stamp($parser);
}

package CORBA::IDL::FixedPtConstType;

use base qw(CORBA::IDL::_TemplateType);

#
#   3.12    Exception Declaration
#

package CORBA::IDL::Exception;

use base qw(CORBA::IDL::Node);

sub _Init {
    my $self = shift;
    my ($parser) = @_;
    $self->{prefix} = $parser->YYData->{symbtab}->GetPrefix();
    $self->{_typeprefix} = $parser->YYData->{symbtab}->GetTypePrefix();
    $self->line_stamp($parser);
    if ($parser->YYData->{doc} ne q{}) {
        $self->{doc} = $parser->YYData->{doc};
        $parser->YYData->{doc} = q{};
    }
    $parser->YYData->{symbtab}->PushCurrentScope($self);
    $parser->YYData->{curr_node} = $self;
}

sub Configure {
    my $self = shift;
    my $parser = shift;
    $self->configure(@_);
    my @list;
    foreach (@{$self->{list_expr}}) {
        foreach (@{$_->{list_member}}) {
            push @list, $_;
        }
        $self->{local_type} = 1 if (CORBA::IDL::TypeDeclarator->IsaLocal($parser, $_->{type}));
    }
    $self->configure(list_member    =>  \@list);    # list of 'Member'
    return $self;
}

sub Lookup {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    $class = substr $class, rindex($class, ':') + 1;
    my ($parser, $name) = @_;
    my $defn = $parser->YYData->{symbtab}->Lookup($name);
    if (defined $defn) {
        unless ($defn->isa($class) || $defn->isa('NativeType')) {
            $parser->Error("'$name' is not a $class or a native type.\n");
        }
        return $defn->{full};
    }
    else {
        return q{};
    }
}

#
#   3.13    Operation Declaration
#

package CORBA::IDL::Operation;

use base qw(CORBA::IDL::Node);

sub _Init {
    my $self = shift;
    my ($parser) = @_;
    my $type = $self->{type};
    $self->line_stamp($parser);
    if ($parser->YYData->{doc} ne q{}) {
        $self->{doc} = $parser->YYData->{doc};
        $parser->YYData->{doc} = q{};
    }
    $parser->YYData->{symbtab}->Insert($self);
    $parser->YYData->{unnamed_symbtab} = new CORBA::IDL::UnnamedSymbtab($parser);
    CORBA::IDL::TypeDeclarator->CheckDeprecated($parser, $type);
    CORBA::IDL::TypeDeclarator->CheckForward($parser, $type);
    if (defined $parser->YYData->{curr_itf}) {
        $self->{itf} = $parser->YYData->{curr_itf}->{full};
        $parser->YYData->{curr_itf}->{hash_attribute_operation}{$self->{idf}} = $self->{full}
                unless($self->{idf} =~ /^_/);       # _get_ or _set_
    }
    else {
        $parser->Error(__PACKAGE__ . "::new ERROR_INTERNAL.\n");
    }
    unless (ref $type) {
        if ($type =~ /::([0-9A-Z_a-z]+)$/) {
            $parser->YYData->{unnamed_symbtab}->InsertUsed($1);
        }
    }
    $parser->YYData->{curr_node} = $self;
}

sub _CheckOneway {
    my $self = shift;
    my ($parser) = @_;
    if (exists $self->{modifier} and $self->{modifier} eq 'oneway') {
        # 3.12.1    Operation Attribute
        my $type = $self->{type};
        unless (ref $type or $type->isa('VoidType')) {
            $parser->Error("return type of '$self->{idf}' is not 'void'.\n");
        }
        foreach ( @{$self->{list_param}} ) {
            next if ($_->isa('Ellipsis'));
            if ($_->{attr} ne 'in') {
                $parser->Error("parameter '$_->{idf}' is not 'in'.\n");
            }
        }
        if (exists $self->{list_raise}) {
            $parser->Error("oneway operation can't raise exception.\n");
        }
    }
}

sub Configure {
    my $self = shift;
    my $parser = shift;
    $self->configure(@_);
    $self->_CheckOneway($parser);
    my @list_in = ();
    my @list_inout = ();
    my @list_out = ();
    foreach ( @{$self->{list_param}} ) {
        next if ($_->isa('Ellipsis'));
        if    ($_->{attr} eq 'in') {
            push @list_in, $_;
        }
        elsif ($_->{attr} eq 'inout') {
            push @list_inout, $_;
        }
        elsif ($_->{attr} eq 'out') {
            push @list_out, $_;
        }
    }
    $self->{list_in} = \@list_in;
    $self->{list_inout} = \@list_inout;
    $self->{list_out} = \@list_out;
    return $self;
}

package CORBA::IDL::Parameter;

use base qw(CORBA::IDL::Node);

sub _Init {
    my $self = shift;
    my ($parser) = @_;
    $self->line_stamp($parser);
    my $type = $self->{type};
    unless (ref $type) {
        if ($type =~ /::([0-9A-Z_a-z]+)$/) {
            $parser->YYData->{unnamed_symbtab}->InsertUsed($1);
        }
    }
    CORBA::IDL::TypeDeclarator->CheckDeprecated($parser, $type);
    CORBA::IDL::TypeDeclarator->CheckForward($parser, $type);
    $parser->YYData->{unnamed_symbtab}->Insert($self->{idf});
    if ($parser->YYData->{doc} ne q{}) {
        $self->{doc} = $parser->YYData->{doc};
        $parser->YYData->{doc} = q{};
    }
    $parser->YYData->{curr_node} = $self;
}

package CORBA::IDL::VoidType;

use base qw(CORBA::IDL::Node);

package CORBA::IDL::Ellipsis;

use base qw(CORBA::IDL::Node);

#
#   3.14    Attribute Declaration
#

package CORBA::IDL::Attributes;

use base qw(CORBA::IDL::Node);

sub _Init {
    my $self = shift;
    my ($parser) = @_;
    my @list;
    foreach (@{$self->{list_expr}}) {
        my $attr = new CORBA::IDL::Attribute($parser,
                declspec            =>  $self->{declspec},
                props               =>  $self->{props},
                modifier            =>  $self->{modifier},
                type                =>  $self->{type},
                idf                 =>  $_,
                list_getraise       =>  $self->{list_getraise},
                list_setraise       =>  $self->{list_setraise}
        );
        push @list, $attr->{full};
    }
    $self->configure(list_decl  =>  \@list);
}

package CORBA::IDL::Attribute;

use base qw(CORBA::IDL::Node);

sub _Init {
    my $self = shift;
    my ($parser) = @_;
    return unless ($self->{idf});
    if ($parser->YYData->{doc} ne q{}) {
        $self->{doc} = $parser->YYData->{doc};
        $parser->YYData->{doc} = q{};
    }
    $self->line_stamp($parser);
    $parser->YYData->{symbtab}->Insert($self);
    if (defined $parser->YYData->{curr_itf}) {
        $self->{itf} = $parser->YYData->{curr_itf}->{full};
        $parser->YYData->{curr_itf}->{hash_attribute_operation}{$self->{idf}} = $self->{full};
    }
    else {
        $parser->Error(__PACKAGE__ . "::new ERROR_INTERNAL.\n");
    }
    $parser->YYData->{curr_node} = $self;
    my $op = new CORBA::IDL::Operation($parser,
            type                =>  $self->{type},
            idf                 =>  '_get_' . $self->{idf}
    );
    $op->Configure($parser,
            list_param      =>  [],
            list_raise      =>  $self->{list_getraise}
    );
    $self->configure(
            _get        =>  $op
    );
    unless (exists $self->{modifier}) {     # readonly
        $op = new CORBA::IDL::Operation($parser,
                type            =>  new CORBA::IDL::VoidType($parser,
                                            value       =>  'void'
                                    ),
                idf             =>  '_set_' . $self->{idf}
        );
        # unnamed_symbtab created
        $op->Configure($parser,
                list_param      =>  [
                                        new CORBA::IDL::Parameter($parser,
                                                attr    =>  'in',
                                                type    =>  $self->{type},
                                                idf     =>  'new' . ucfirst $self->{idf}
                                        )
                                    ],
                list_raise      =>  $self->{list_setraise}
        );
        $self->configure(
                _set        =>  $op
        );
    }
}

#
#   3.15    Repository Identity Related Declarations
#

package CORBA::IDL::TypeId;

use base qw(CORBA::IDL::Node);

sub _Init {
    my $self = shift;
    my ($parser) = @_;
    my $node = $parser->YYData->{symbtab}->Lookup($self->{idf});
    if (defined $node) {
        if (       $node->isa('Modules')
                or $node->isa('BaseInterface')
                or $node->isa('ForwardBaseInterface')
                or $node->isa('StateMember')
                or $node->isa('Constant')
                or $node->isa('TypeDeclarator')
                or $node->isa('Enum')
                or $node->isa('Exception')
                or $node->isa('Operation')
                or $node->isa('Attribute')
                or $node->isa('Provides')
                or $node->isa('Uses')
                or $node->isa('Emits')
                or $node->isa('Publishes')
                or $node->isa('Consumes')
                or $node->isa('Factory')
                or $node->isa('Finder') ) {
            if (exists $node->{id}) {
                $parser->Warning("TypeId/pragma conflict for '$self->{idf}'.\n");
            }
            if (exists $node->{typeid}) {
                $parser->Error("TypeId redefinition for '$self->{idf}'.\n");
            }
            else {
                $parser->YYData->{symbtab}->CheckID($node, $self->{value});
                $node->{typeid} = $self->{value};
            }
        }
        else {
            $parser->Error("Typeid not allowed for '$self->{idf}'.\n");
        }
    }
}

package CORBA::IDL::TypePrefix;

use base qw(CORBA::IDL::Node);

sub _Init {
    my $self = shift;
    my ($parser) = @_;
    unless ($self->{value} =~ /^[0-9A-Za-z_:\.\/\-]*$/) {
        $parser->Warning("Invalid TypePrefix format for \"$self->{value}\".\n");
    }
    if ($self->{idf}) {
        my $node = $parser->YYData->{symbtab}->Lookup($self->{idf});
        if (defined $node) {
            if (       $node->isa('Modules')
                    or $node->isa('Interface')
                    or $node->isa('ForwardInterface')
                    or $node->isa('Value')
                    or $node->isa('ForwardValue')
                    or $node->isa('Specification') ) {
                if ($node->{prefix}) {
                    $parser->Warning("TypePrefix/pragma conflict for '$self->{idf}'.\n");
                }
                $node->{typeprefix} = $self->{value};
                $node->{_typeprefix} = $self->{value};
                $parser->YYData->{symbtab}->{typeprefix}->{$node->{full}} = $self->{value} . '/' . $node->{idf};
            }
            else {
                $parser->Error("Typeprefix not allowed for '$self->{idf}'.\n");
            }
        }
    }
    else {
        $parser->YYData->{symbtab}->{typeprefix}->{''} = $self->{value};
    }
}

#
#   3.16    Event Declaration
#

package CORBA::IDL::Event;

use base qw(CORBA::IDL::Value);

package CORBA::IDL::RegularEvent;

use base qw(CORBA::IDL::Event);

sub _CheckInheritance {
    my $self = shift;
    my ($parser) = @_;
    if (exists $self->{inheritance}) {
        if (    exists $self->{inheritance}->{modifier}     # truncatable
            and exists $self->{modifier} ) {                # custom
            $parser->Error("'truncatable' is used in a custom event.\n");
        }
    }
}

sub _CheckLocal {
    # A local type may be used as a parameter, attribute, return type, or exception
    # declaration of a local interface or of a valuetype.
}

package CORBA::IDL::AbstractEvent;

use base qw(CORBA::IDL::Event);

sub _CheckInheritance {
    # empty
}

sub _CheckLocal {
    # A local type may be used as a parameter, attribute, return type, or exception
    # declaration of a local interface or of a valuetype.
}

package CORBA::IDL::ForwardEvent;

use base qw(CORBA::IDL::ForwardValue);

package CORBA::IDL::ForwardRegularEvent;

use base qw(CORBA::IDL::ForwardEvent);

package CORBA::IDL::ForwardAbstractEvent;

use base qw(CORBA::IDL::ForwardEvent);

#
#   3.17    Component Declaration
#

package CORBA::IDL::Component;

use base qw(CORBA::IDL::BaseInterface);

sub _CheckInheritance {
}

package CORBA::IDL::ForwardComponent;

use base qw(CORBA::IDL::ForwardBaseInterface);

package CORBA::IDL::Provides;

use base qw(CORBA::IDL::Node);

package CORBA::IDL::Uses;

use base qw(CORBA::IDL::Node);

package CORBA::IDL::Emits;

use base qw(CORBA::IDL::Node);

package CORBA::IDL::Publishes;

use base qw(CORBA::IDL::Node);

package CORBA::IDL::Consumes;

use base qw(CORBA::IDL::Node);

#
#   3.18    Home Declaration
#

package CORBA::IDL::Home;

use base qw(CORBA::IDL::BaseInterface);

sub _CheckInheritance {
}

package CORBA::IDL::Factory;

use base qw(CORBA::IDL::Node);

sub _Init {
    my $self = shift;
    my ($parser) = @_;
    $parser->YYData->{symbtab}->Insert($self);
    $parser->YYData->{unnamed_symbtab} = new CORBA::IDL::UnnamedSymbtab($parser);
    if (defined $parser->YYData->{curr_itf}) {
        $self->{itf} = $parser->YYData->{curr_itf}->{full};
        $parser->YYData->{curr_itf}->{hash_attribute_operation}{$self->{idf}} = $self->{full}
    }
    else {
        $parser->Error(__PACKAGE__ . "::new ERROR_INTERNAL.\n");
    }
    if ($parser->YYData->{doc} ne q{}) {
        $self->{doc} = $parser->YYData->{doc};
        $parser->YYData->{doc} = q{};
    }
    $parser->YYData->{curr_node} = $self;
}

sub Configure {
    my $self = shift;
    my $parser = shift;
    $self->configure(@_);
    my @list_in = ();
    foreach ( @{$self->{list_param}} ) {
        if      ($_->{attr} eq 'in') {
            unshift @list_in, $_;
        }
    }
    $self->{list_in} = \@list_in;
    $self->{list_inout} = [];
    $self->{list_out} = [];
    return $self;
}

package CORBA::IDL::Finder;

use base qw(CORBA::IDL::Node);

sub _Init {
    my $self = shift;
    my ($parser) = @_;
    $parser->YYData->{symbtab}->Insert($self);
    $parser->YYData->{unnamed_symbtab} = new CORBA::IDL::UnnamedSymbtab($parser);
    if (defined $parser->YYData->{curr_itf}) {
        $self->{itf} = $parser->YYData->{curr_itf}->{full};
        $parser->YYData->{curr_itf}->{hash_attribute_operation}{$self->{idf}} = $self->{full}
    }
    else {
        $parser->Error(__PACKAGE__,"::new ERROR_INTERNAL.\n");
    }
    if ($parser->YYData->{doc} ne q{}) {
        $self->{doc} = $parser->YYData->{doc};
        $parser->YYData->{doc} = q{};
    }
    $parser->YYData->{curr_node} = $self;
}

sub Configure {
    my $self = shift;
    my $parser = shift;
    $self->configure(@_);
    my @list_in = ();
    foreach ( @{$self->{list_param}} ) {
        if      ($_->{attr} eq 'in') {
            unshift @list_in, $_;
        }
    }
    $self->{list_in} = \@list_in;
    $self->{list_inout} = [];
    $self->{list_out} = [];
    return $self;
}

package CORBA::IDL::CodeFragment;

use base qw(CORBA::IDL::Node);

sub _Init {
    my $self = shift;
    my ($parser) = @_;
    $self->line_stamp($parser);
}

=for tree

    Node
        Specification -
        Import -
        Modules - NEW
        Module
        (BaseInterface) -
            (Interface)
                RegularInterface
                LocalInterface
                AbstractInterface
            (Value)
                RegularValue
                BoxedValue
                AbstractValue
                (Event) -
                    RegularEvent
                    AbstractEvent
            Component
            Home
        (ForwardBaseInterface)
            (ForwardInterface) -
                ForwardRegularInterface
                ForwardLocalInterface
                ForwardAbstractInterface
            (ForwardValue) -
                ForwardRegularValue -
                ForwardAbstractValue -
                (ForwardEvent) -
                    ForwardRegularEvent -
                    ForwardAbstractEvent -
            ForwardComponent -
        InheritanceSpec
        StateMembers
        StateMember
        Initializer
        Expression
        Constant
        UnaryOp -
        BinaryOp -
        (Literal)
            IntegerLiteral -
            StringLiteral -
            WideStringLiteral -
            CharacterLiteral -
            WideCharacterLiteral -
            FixedPtLiteral -
            FloatingLiteral -
            BooleanLiteral -
        TypeDeclarator
        TypeDeclarators
        NativeType
        (BasicType)
            FloatingPtType -
            IntegerType -
            CharType -
            WideCharType -
            BooleanType -
            OctetType -
            AnyType -
            ObjectType -
            ValueBaseType -
        (_ConstructedType)
            StructType
            UnionType
            EnumType
        (_ForwardConstructedType)
            ForwardStructType -
            ForwardUnionType -
        Members
        Member
        Case -
        Default -
        Element
        Enum
        (_TemplateType) -
            SequenceType
            StringType -
            WideStringType -
            FixedPtType
            FixedPtConstType - NEW
        Exception
        Operation
        Parameter
        VoidType -
        Ellipsis -
        Attributes
        Attribute
        TypeId
        TypePrefix
        Provides
        Uses
        Emits
        Publishes
        Consumes
        Factory
        Finder

=end tree

1;

