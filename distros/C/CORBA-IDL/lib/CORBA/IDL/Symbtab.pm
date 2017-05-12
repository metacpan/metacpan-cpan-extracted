#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#

use strict;
use warnings;

package CORBA::IDL::Scope;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    my($symbtab, $classname, $full, $name) = @_;
    $self->{class} = $classname;
    $self->{full} = $full;
    $self->{entry} = {};
    return $self;
}

sub _Insert {
    my $self = shift;
    my($name, $defn) = @_;
    $self->{entry}->{lc $name} = $defn;
}

sub _Lookup {
    my $self = shift;
    return $self->{entry}->{lc shift};
}

##############################################################################

package CORBA::IDL::Symbtab;

our $VERSION = '2.63';

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    my($parser) = @_;
    $self->{current_root} = q{};
    $self->{current_scope} = q{};
    $self->{parser} = $parser;

    $self->{scopes} = {
        q{}     => new CORBA::IDL::Scope($self, 'CORBA::IDL::Module', q{}, q{})
    };
    $self->{prefix} = {};
    $self->{typeprefix} = {};
    # C Mapping
    $self->{c_mapping} = {};
#   $self->_Init();
    return $self;
}

#sub _Init {
#   my $self = shift;
#}

sub _CheckCMapping {
    my $self = shift;
    my($full) = @_;

    my $c_key = $full;
    $c_key =~ s/^:://;
    $c_key =~ s/::/_/g;
    if (exists $self->{c_mapping}{$c_key}) {
        $self->{parser}->Info(
                "'$full' is ambiguous (C mapping) with '$self->{c_mapping}{$c_key}'.\n");
    }
    else {
        $self->{c_mapping}{$c_key} = $full
    }
}

sub PushCurrentRoot {
    my $self = shift;
    my($node) = @_;
    my $name = $node->{idf};
    my $class = ref $node;
    $class = substr $class, rindex($class, ':') + 1;
##  print "PushCurrentRoot '$name' $class\n";
    $self->{parser}->Error("PushCurrentRoot: INTERNAL_ERROR ($class).\n")
            unless ($class eq 'Module');
    # OpenModule
    $self->{parser}->Error("PushCurrentRoot: INTERNAL_ERROR current_scope not empty ($self->{current_scope}).\n")
            if ($self->{current_scope});
    delete $self->{msg} if (exists $self->{msg});
    my $scope = $self->{current_root};
    my $key_prefix = $self->{parser}->YYData->{filename} . $scope;
    my $new_scope = $self->{current_root} . '::' . $name;
    my $prev = $self->{scopes}->{$scope}->_Lookup($name);
    if (defined $prev) {
        while ($prev->isa('Entry')) {
            $prev = $self->{scopes}->{$prev->{scope}}->_Lookup($name);
        }
        if ($prev->isa('Modules')) {
            # reopen
            push @{$prev->{list_decl}}, $node;
            if ($prev->{prefix} ne $node->{prefix}) {
                $self->{parser}->Error("Prefix redefinition for '$name'.\n");
            }
        }
        else {
            $self->{msg} ||= "Identifier '$name' already exists.\n";
            $self->{parser}->Error($self->{msg});
            unless (exists $self->{scopes}->{$new_scope}) {
                $self->{scopes}->{$new_scope} = new CORBA::IDL::Scope($self, ref $node, $new_scope, $name);
                my $modules = bless {
                        idf                 => $name,
                        full                => $new_scope,
                        prefix              => $node->{prefix},
                        _typeprefix         => $node->{_typeprefix},
                        list_decl           => [ $node ],
                }, 'CORBA::IDL::Modules';
                $modules->{typeprefix} = $node->{typeprefix}
                        if (exists $node->{typeprefix});
                $modules->{declspec} = $node->{declspec}
                        if (exists $node->{declspec});
                $self->{scopes}->{$new_scope}->_Insert($name, $modules);
            }
        }
    }
    else {
        $self->{scopes}->{$scope}->_Insert($name, bless({'scope' => $new_scope}, 'Entry'));
        $self->_CheckCMapping($new_scope);
        $self->{scopes}->{$new_scope} = new CORBA::IDL::Scope($self, ref $node, $new_scope, $name);
        my $modules = bless {
                idf                 => $name,
                full                => $new_scope,
                prefix              => $node->{prefix},
                _typeprefix         => $node->{_typeprefix},
                list_decl           => [ $node ],
        }, 'CORBA::IDL::Modules';
        $modules->{typeprefix} = $node->{typeprefix}
                if (exists $node->{typeprefix});
        $modules->{declspec} = $node->{declspec}
                if (exists $node->{declspec});
        $self->{scopes}->{$new_scope}->_Insert($name, $modules);
    }

    $self->{current_root} = $new_scope;
    $node->{full} = $new_scope;
    if (defined $node->{_typeprefix}) {
        my $typeprefix = $node->{_typeprefix};
        if ($typeprefix) {
            $typeprefix .= '/' . $node->{idf};
        }
        else {
            $typeprefix = $node->{idf};
        }
        $self->{typeprefix}->{$new_scope} = $typeprefix;
    }
    else {
        $key_prefix .= '::' . $node->{idf};
        my $prefix = $node->{prefix};
        if ($prefix) {
            $prefix .= '/' . $node->{idf};
        }
        else {
            $prefix = $node->{idf};
        }
        $self->{prefix}->{$key_prefix} = $prefix;
    }
    return;
}

sub PopCurrentRoot {
    my $self = shift;
    my($node) = @_;
    return unless (defined $node);
    return if ($self->{current_root} =~ s/::$node->{idf}$//);
    $self->{parser}->Error(
            "PopCurrentRoot: INTERNAL_ERROR $self->{current_root} $node->{idf}.\n");
    return;
}

sub PushCurrentScope {
    my $self = shift;
    my($node) = @_;
    my $name = $node->{idf};
    my $class = ref $node;
    $class = substr $class, rindex($class, ':') + 1;
##  print "PushCurrentScope '$name' $class\n";
    # Insert
    delete $self->{msg} if (exists $self->{msg});
    my $scope = $self->{current_root} . $self->{current_scope};
    my $key_prefix = $self->{parser}->YYData->{filename} . $scope;
    my $new_scope = $scope . '::' . $name;
    my $prev = $self->{scopes}->{$scope}->_Lookup($name);
    if (defined $prev) {
        while ($prev->isa('Entry')) {
            $prev = $self->{scopes}->{$prev->{scope}}->_Lookup($name);
        }
        if ($prev->isa('Forward' . $class)) {
            # the previous must be the same
            foreach (keys %{$prev}) {
                if (       $_ eq 'full'
                        or $_ eq 'filename'
                        or $_ eq 'lineno'
                        or $_ eq 'typeprefix'
                        or $_ eq '_typeprefix'
                        or $_ eq 'hash_attribute_operation' ) {
                    next;
                }
                if (       $_ eq 'id'
                        or $_ eq 'version' ) {
                    $node->{$_} = $prev->{$_};
                    next;
                }
                if ($prev->{$_} ne $node->{$_}) {
##                  print "$_ $prev->{$_} $node->{$_}\n";
                    if ($_ eq 'prefix') {
                        unless (defined $node->{_typeprefix}) {
                            $self->{parser}->Error(
                                    "Prefix redefinition for '$name'.\n");
                        }
                        next;
                    }
                    $self->{parser}->Error(
                            "Definition of '$name' conflicts with previous declaration.\n");
                    return;
                }
            }
            $node->{typeprefix} = $prev->{typeprefix}
                    if (exists $prev->{typeprefix});
            $self->{scopes}->{$scope}->_Insert($name, bless({'scope' => $new_scope}, 'Entry'));
            $self->{scopes}->{$new_scope} = new CORBA::IDL::Scope($self, ref $node, $new_scope, $name);
            $self->{scopes}->{$new_scope}->_Insert($name, $node);
        }
        else {
            $self->{msg} ||= "Identifier '$name' already exists.\n";
            $self->{parser}->Error($self->{msg});
            unless (exists $self->{scopes}->{$new_scope}) {
                $self->{scopes}->{$new_scope} = new CORBA::IDL::Scope($self, ref $node, $new_scope, $name);
                $self->{scopes}->{$new_scope}->_Insert($name, $node);
            }
        }
    }
    else {
        $self->{scopes}->{$scope}->_Insert($name, bless({'scope' => $new_scope}, 'Entry'));
        $self->_CheckCMapping($new_scope);
        $self->{scopes}->{$new_scope} = new CORBA::IDL::Scope($self, ref $node, $new_scope, $name);
        $self->{scopes}->{$new_scope}->_Insert($name, $node);
    }

    $self->{current_scope} .= '::' . $name;
    $node->{full} = $new_scope;
    if (defined $node->{_typeprefix}) {
        my $typeprefix = $node->{_typeprefix};
        if ($typeprefix) {
            $typeprefix .= '/' . $node->{idf};
        }
        else {
            $typeprefix = $node->{idf};
        }
        $self->{typeprefix}->{$new_scope} = $typeprefix;
    }
    else {
        $key_prefix .= '::' . $node->{idf};
        my $prefix = $node->{prefix};
        if ($prefix) {
            $prefix .= '/' . $node->{idf};
        }
        else {
            $prefix = $node->{idf};
        }
        $self->{prefix}->{$key_prefix} = $prefix;
    }
    return;
}

sub PopCurrentScope {
    my $self = shift;
    my($node) = @_;
    return unless (defined $node);
    return if ($self->{current_scope} =~ s/::$node->{idf}$//);
    $self->{parser}->Error(
            "PopCurrentScope: INTERNAL_ERROR $self->{current_scope} $node->{idf}.\n");
    return;
}

sub Insert {
    my $self = shift;
    my($node) = @_;
    if ($node->isa('Specification')) {
        $node->{full} = q{};
        $self->{scopes}->{''}->_Insert(q{}, $node);
        return;
    }
    my $name = $node->{idf};
    return unless ($name);
    delete $self->{msg} if (exists $self->{msg});
    my $scope = $self->{current_root} . $self->{current_scope};
##  print "Insert '$name' ",ref $node," => $scope\n";
    unless (exists $self->{scopes}->{$scope}) {
        warn "'$scope' not exist.\n";
        return;
    }
    my $prev = $self->{scopes}->{$scope}->_Lookup($name);
    if (defined $prev) {
        while ($prev->isa('Entry')) {
            $prev = $self->{scopes}->{$prev->{scope}}->_Lookup($name);
        }
        my $class = ref $prev;
        $class = substr $class, rindex($class, ':') + 1;
        if ($class =~ s/^Forward//) {
            if (ref $node ne $class) {
                $self->{parser}->Error(
                        "Definition of '$name' conflicts with previous declaration.\n");
                return;
            }
            else {
                # the previous must be the same
                foreach (keys %{$prev}) {
                    if (       $_ eq 'full'
                            or $_ eq 'lineno'
                            or $_ eq 'hash_attribute_operation' ) {
                        next;
                    }
                    if (       $_ eq 'id'
                            or $_ eq 'version' ) {
                        $node->{$_} = $prev->{$_};
                        next;
                    }
                    if ($_ eq 'filename') {
                        if (       $prev->isa('ForwardStruct')
                                or $prev->isa('ForwardUnion') ) {
                            if ($prev->{$_} ne $node->{$_}) {
                                $self->{parser}->Error(
                                "Definition of '$name' is not in the same file.\n");
                            }
                        }
                        next;
                    }
                    if ($prev->{$_} ne $node->{$_}) {
                        if ($_ eq 'prefix') {
                            unless (defined $node->{_typeprefix}) {
                                $self->{parser}->Error(
                                        "Prefix redefinition for '$name'.\n");
                            }
                            next;
                        }
                        $self->{parser}->Error(
                                "Definition of '$name' conflicts with previous declaration.\n");
                    }
                }
            }
        }
        else {
            if ($prev->{idf} eq $name) {
                $self->{msg} ||= "Identifier '$name' already exists.\n";
            }
            else {
                $self->{msg} ||= "Identifier '$name' collides with '$prev->{idf}'.\n";
            }
            $self->{parser}->Error($self->{msg});
            return;
        }
    }
    # insert
    $node->{full} = $scope . '::' . $name;
    $self->{scopes}->{$scope}->_Insert($name, $node);
    $self->_CheckCMapping($node->{full});
    return;
}

sub InsertForward {
    my $self = shift;
    my($node) = @_;
    my $name = $node->{idf};
    return unless ($name);
    my $class = ref $node;
    $class = substr $class, rindex($class, ':') + 1;
##  print "InsertForward '$name' '$node->{idf}'\n";
    delete $self->{msg} if (exists $self->{msg});
    my $scope = $self->{current_root} . $self->{current_scope};
    my $prev = $self->{scopes}->{$scope}->_Lookup($name);
    if (defined $prev) {
        while ($prev->isa('Entry')) {
            $prev = $self->{scopes}->{$prev->{scope}}->_Lookup($name);
        }
        my $class = ref $prev;
        $class = substr $class, rindex($class, ':') + 1;
        if ($class =~ /^Forward/) {
            # redeclaration
            if (ref $node ne ref $prev) {
                $self->{parser}->Error(
                        "Definition of '$name' conflicts with previous declaration.\n");
                return;
            }
            else {
                # the previous must be the same
                foreach (keys %{$prev}) {
                    if (       $_ eq 'full'
                            or $_ eq 'lineno'
                            or $_ eq 'filename'
                            or $_ eq 'typeprefix'
                            or $_ eq '_typeprefix' ) {
                        next;
                    }
                    if (       $_ eq 'id'
                            or $_ eq 'version' ) {
                        $node->{$_} = $prev->{$_};
                        next;
                    }
                    if ($prev->{$_} ne $node->{$_}) {
                        if ($_ eq 'prefix') {
                            unless (defined $node->{_typeprefix}) {
                                $self->{parser}->Error(
                                        "Prefix redefinition for '$name'.\n");
                            }
                            next;
                        }
                        $self->{parser}->Error(
                                "Definition of '$name' conflicts with previous declaration.\n");
                        return;
                    }
                }
            }
        }
        else {
            $self->{msg} ||= "Identifier '$name' already exists.\n";
            $self->{parser}->Error($self->{msg});
            return;
        }
    }
    # insert
    $node->{full} = $scope . '::' . $name;
    $self->{scopes}->{$scope}->_Insert($name, $node);
    return;
}

sub InsertInherit {
    my $self = shift;
    my($node, $name, $full) = @_;
##  print "InsertInherit '$name' $full \n";

    # Insert
    delete $self->{msg} if (exists $self->{msg});
    my $scope = $self->{current_root} . $self->{current_scope};
    my $prev = $self->{scopes}->{$scope}->_Lookup($name);
    if (defined $prev) {
        $self->{parser}->Error(__PACKAGE__ . "::InsertInherit: INTERNAL_ERROR ($full).\n");
    }
    else {
        my $scope_base = $full;
        $scope_base =~ s/::[0-9A-Z_a-z]+$//;
        $self->{scopes}->{$scope}->_Insert($name, bless({'scope' => $scope_base}, 'Entry'));
    }
    return;
}

sub InsertBogus {
    my $self = shift;
    my($node) = @_;
    my $scope =  $self->{current_root} . $self->{current_scope};
    $node->{full} = $scope . '::_seq_';
}

sub Lookup {
    my $self = shift;
    my($name) = @_;
    delete $self->{msg} if (exists $self->{msg});
    if (ref $name) {
        warn __PACKAGE__,"::Lookup $name ",caller," PB\n";
        return $name;
    }
    my $defn = $self->_Lookup($name);
    if (defined $defn) {
        $self->{parser}->Error($self->{msg}) if (exists $self->{msg});
    }
    else {
##      print __PACKAGE__,"::Lookup $name ",caller()," PB\n";
        $self->{parser}->Error("Undefined symbol '$name'.\n");
    }
    return $defn;
}

sub _Lookup {
    my $self = shift;
    my($name) = @_;
    my $defn;
##  print "_Lookup: '$name'\n";
    if (ref $name) {
        warn __PACKAGE__,"::_Lookup $name ",caller," PB\n";
        return $name;
    }
    return undef unless ($name);
    if ($name =~ /^::/) {
        # global name
##      print "_global name.\n";
        return $self->___Lookup($name);
    }
    elsif ($name =~ /^[0-9A-Z_a-z]+$/) {
        # identifier alone
        my $scope_init = $self->{current_root} . $self->{current_scope};
        my $scope = $scope_init;
##      print "_Lookup init : '$scope'\n";
        while (1) {
            # Section 3.15.3 Special Scoping Rules for Type Names
            my $g_name = $scope . '::' . $name;
            $defn = $self->__Lookup($scope, $g_name, $name);
            last if (defined $defn || $scope eq '');
            $scope =~ s/::[0-9A-Z_a-z]+$//;
##          print "_Lookup curr : '$scope'\n";
        };
        if (defined $defn) {
##          print "_found $name $scope_init $scope\n";
            my $scope_real = $defn->{full};
            $scope_real =~ s/::[0-9A-Z_a-z]+$//;
            while ($scope_init ne $scope) {
                my $node = $self->___Lookup($scope_init);
                if ($defn->isa('Modules') or ! $node->isa('Modules')) {
##                  print "_insert $name $scope_init $scope_real\n";
                    $self->{scopes}->{$scope_init}->_Insert($name, bless({'scope' => $scope_real}, 'Entry'));
                }
                $scope_init =~ s/::[0-9A-Z_a-z]+$//;
            }
        }
        return $defn;
    }
    else {
        # qualified name
        my @list = split /::/, $name;
        my $idf = pop @list;
        my $scoped_name = $name;
        $scoped_name =~ s/::[0-9A-Z_a-z]+$//;
##      print "_qualified name : '$scoped_name' '$idf'\n";
        my $scope = $self->_Lookup($scoped_name);       # recursive
        if (defined $scope) {
            $defn = $self->___Lookup($scope->{full} . '::' . $idf);
        }
        return $defn;
    }
}

sub __Lookup {
    my $self = shift;
    my ($scope, $g_name, $name) = @_;
##  print "__Lookup: '$scope' '$g_name' '$name'\n";
    my $defn = $self->___Lookup($g_name);
    return $defn if (defined $defn);
    return undef unless($scope);
    my $node = $self->___Lookup($scope);
    if (defined $node) {
##      print "__inherit $node->{full}\n";
        my @list;
        foreach ($node->getInheritance()) {
            my $base = $self->Lookup($_);
            if (defined $base) {
                $g_name = $base->{full} . '::' . $name;
                $defn = $self->___Lookup($g_name);
                if (defined $defn) {
                    my $found = 0;
                    foreach (@list) {
                        if ($defn == $_) {
                            $found = 1;
                            last;
                        }
                    }
                    push @list, $defn unless ($found);
                }
            }
        }
        if (@list) {
            if (scalar @list > 1) {
                $self->{parser}->Error("Ambiguous symbol '$name'.\n");
            }
            return pop @list;
        }
    }
    return undef;
}

sub ___Lookup {
    my $self = shift;
    my ($full) = @_;
##  print "___Lookup: '$full'\n";
    if ($full =~ /^((?:::[0-9A-Z_a-z]+)*)::([0-9A-Z_a-z]+)$/) {
        if (exists $self->{scopes}->{$1}) {
            my $defn = $self->{scopes}->{$1}->_Lookup($2);
            if (defined $defn) {
                while ($defn->isa('Entry')) {
                    $defn = $self->{scopes}->{$defn->{scope}}->_Lookup($2);
                    last unless (defined $defn);
                }
                unless (defined $defn) {
                    $self->{parser}->Error(__PACKAGE__ . "::___Lookup: INTERNAL_ERROR ($full).\n");
                    return undef;
                }
                if ($defn->{idf} ne $2) {
                    $self->{msg} = "Identifier '$2' collides with '$defn->{idf}'.\n";
                }
##              print "___found $defn->{full}\n";
                return $defn;
            }
            else {
##              print "___not found '$2' in '$1'.\n";
                return undef;
            }
        }
        else {
##          print "___not found scope '$1'.\n";
            return undef;
        }
    }
    else {
        $self->{parser}->Error(__PACKAGE__ . "::___Lookup: INTERNAL_ERROR not match ($full).\n");
        return undef;
    }
}

sub PragmaID {                          #   10.7.5.1    The ID Pragma
    my $self = shift;
    my($name, $id) = @_;
    my $node = $self->Lookup($name);
    if (defined $node) {
        if (exists $node->{typeid}) {
            $self->{parser}->Warning("TypeId/pragma conflict for '$self->{idf}'.\n");
        }
        if (exists $node->{id}) {
            $self->{parser}->Error("Repository ID redefinition for '$name'.\n")
                    unless ($id eq $node->{id});
        }
        else {
            $node->{id} = $id;
            $self->CheckID($node, $id);
        }
        if ($node->isa('Modules')) {
            foreach (@{$node->{list_decl}}) {
                if ($_->{filename} eq $self->{parser}->YYData->{filename}) {
                    $_->{id} = $id;
                }
            }
        }
    }
    else {
        $self->{parser}->Warning("Undefined symbol '$name' for '$id'.\n")
    }
}

sub CheckID {
    my $self = shift;
    my($node, $id) = @_;
    if ($id =~ /^IDL:/) {
        #   10.7.1      OMG IDL Format
        if ($id =~ /^IDL:[0-9A-Za-z_:\.\/\-]+:([0-9]+)\.([0-9]+)/) {
            my $version = $1 . '.' . $2;
            if (exists $node->{version}) {
                $self->{parser}->Error("Version redefinition for '$node->{idf}'.\n")
                        unless ($version eq $node->{version});
            }
            else {
                $node->{version} = $version;
            }
        }
        else {
            $self->{parser}->Error("Bad IDL format for Repository ID '$id'.\n");
        }
    }
    elsif ($id =~ /^RMI:/) {
        #   10.7.2      RMI Hashed Format
        $self->{parser}->Error("Bad RMI format for Repository ID '$id'.\n")
                unless ($id =~ /^RMI:[0-9A-Za-z_\[\-\.\/\$\\]+:[0-9A-Fa-f]{16}(:[0-9A-Fa-f]{16})?/);
    }
    elsif ($id =~ /^DCE:/) {
        #   10.7.3      DCE UUID Format
        $self->{parser}->Error("Bad DCE format for Repository ID '$id'.\n")
                unless ($id =~ /^DCE:[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}(:[0-9]+)?/);
    }
    elsif ($id =~ /^LOCAL:/) {
        #   10.7.4      LOCAL Format
        # followed by an arbitrary string.
    }
}

sub PragmaPrefix {                      #   10.7.5.2    The Prefix Pragma
    my $self = shift;
    my($prefix) = @_;
    my $key_prefix = $self->{parser}->YYData->{filename} . $self->{current_root} . $self->{current_scope};
    $self->{prefix}->{$key_prefix} = $prefix;
}

sub GetPrefix {
    my $self = shift;
    my $scope = $self->{current_root} . $self->{current_scope};
    my $key_prefix = $self->{parser}->YYData->{filename} . $scope;
    if (exists $self->{prefix}->{$key_prefix}) {
        return $self->{prefix}->{$key_prefix};
    }
    else {
        return q{};
    }
}

sub GetTypePrefix {
    my $self = shift;
    my $scope = $self->{current_root} . $self->{current_scope};
    if (exists $self->{typeprefix}->{$scope}) {
        return $self->{typeprefix}->{$scope};
    }
    else {
        return undef;
    }
}

sub PragmaVersion {                     #   10.7.5.3    The Version Pragma
    my $self = shift;
    my($name, $major, $minor) = @_;
    my $version = $major . '.' . $minor;
    my $node = $self->Lookup($name);
    if (defined $node) {
        if (exists $node->{version}) {
            $self->{parser}->Error("Version redefinition for '$name'.\n")
                    unless ($version eq $node->{version});
        }
        else {
            $node->{version} = $version;
        }
    }
}

sub CheckForward {
    my $self = shift;

    foreach my $scope (values %{$self->{scopes}}) {
        foreach my $entry (values %{$scope->{entry}}) {
            if ($entry->isa('_ForwardConstructedType')) {
                $self->{parser}->Error("'$entry->{idf}' never defined.\n");
            }
        }
    }
}

sub CheckRepositoryID {
    my $self = shift;

    foreach my $scope (values %{$self->{scopes}}) {
        foreach my $entry (values %{$scope->{entry}}) {
            if ($entry->isa('Modules') and exists $entry->{id}) {
                foreach (@{$entry->{list_decl}}) {
                    if (       ! exists $_->{id}
                            or $_->{id} ne $entry->{id} ) {
                        $self->{parser}->Error("Repository ID inconsistent for '$entry->{idf}'.\n");
                    }
                }
            }
        }
    }
}

sub Import {
    my $self = shift;
    my($node) = @_;

    my %imports = ($node->{value} => 1) ;
    my $dirname = $self->{parser}->YYData->{opt_i};
    my $fullname = $node->{value};
    $fullname =~ s/::/_/g;
    my $filename = $fullname . '.mod';
    $filename = $dirname . '/' . $filename if ($dirname);
    require $filename;
    my $scope = eval('$main::' . $fullname);
    if (defined $scope and $scope->isa('CORBA::IDL::Scope')) {
        my $class = $scope->{class};
        if (       $class eq 'CORBA::IDL::Module'
                or $class eq 'CORBA::IDL::RegularInterface'
                or $class eq 'CORBA::IDL::LocalInterface'
                or $class eq 'CORBA::IDL::AbstractInterface'
                or $class eq 'CORBA::IDL::RegularValue'
                or $class eq 'CORBA::IDL::BoxedValue'
                or $class eq 'CORBA::IDL::AbstractValue'
                or $class eq 'CORBA::IDL::RegularEvent'
                or $class eq 'CORBA::IDL::AbstractEvent' ) {
            $self->{scopes}->{$node->{value}} = $scope;
            my $root = $node->{value};
            $root =~ s/::([0-9A-Z_a-z]+)$//;
            my $name = lc $1;
            $self->{scopes}->{$root}->_Insert($name, bless({'scope' => $node->{value}}, 'Entry'));
            foreach (values %{$scope->{entry}}) {
                next if (ref $_ ne 'Entry');
                next if (exists $self->{scopes}->{$_->{scope}});
                $self->_Import($_->{scope}, \%imports);
            }
            $node->{list_decl} = [ keys %imports ];
        }
        else {
            $self->{parser}->Error("'$node->{value}' can't imported (bad type).\n");
        }
    }
    else {
        $self->{parser}->Error("Import: INTERNAL_ERROR ($node->{value}).\n");
    }
}

sub _Import {
    my $self = shift;
    my($full, $r_import) = @_;

    $r_import->{$full} = 1;
    my $dirname = $self->{parser}->YYData->{opt_i};
    my $fullname = $full;
    $fullname =~ s/::/_/g;
    my $filename = $fullname . '.mod';
    $filename = $dirname . '/' . $filename if ($dirname);
    require $filename;
    my $scope = eval('$main::' . $fullname);
    if (defined $scope and $scope->isa('CORBA::IDL::Scope')) {
        $self->{scopes}->{$full} = $scope;
        my $root = $full;
        $root =~ s/::([0-9A-Z_a-z]+)$//;
        my $name = lc $1;
        $self->{scopes}->{$root}->_Insert($name, bless({'scope' => $full}, 'Entry'));
        foreach (values %{$scope->{entry}}) {
            next if (ref $_ ne 'Entry');
            next if (exists $self->{scopes}->{$_->{scope}});
            $self->_Import($_->{scope}, $r_import);
        }
    }
    else {
        $self->{parser}->Error("_Import: INTERNAL_ERROR ($full).\n");
    }
}

sub Export {
    my $self = shift;
    use Data::Dumper;

    my $dirname = $self->{parser}->YYData->{opt_i};
    if ($dirname) {
        unless (-d $dirname) {
            mkdir $dirname
                    or die "can't create $dirname ($!).\n";
        }
    }
    foreach my $scope (values %{$self->{scopes}}) {
        my $fullname = $scope->{full};
        next unless ($fullname);
        $fullname =~ s/::/_/g;
        my $filename = $fullname . '.mod';
        $filename = $dirname . '/' . $filename if ($dirname);
        open my $OUT, '>', $filename
                or die "can't open $filename ($!).\n";
        my $d = Data::Dumper->new([$scope], [$fullname]);
        $d->Indent(1);
#       $d->Indent(0);
        $d->Purity(1);
        print $OUT "package main;\n";
        print $OUT $d->Dump();
        close $OUT;
    }
}

sub Dump {
    my $self = shift;
    use Data::Dumper;

    my $d = Data::Dumper->new([$self->{scopes}], [qw(scopes)]);
    $d->Indent(1);
#   $d->Indent(0);
    print $d->Dump();
}

##############################################################################

package CORBA::IDL::UnnamedSymbtab;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my($parser) = @_;
    my $self = {};
    bless $self, $class;
    $self->{parser} = $parser;
    $self->{entry} = {};
    return $self;
}

sub Insert {
    my $self = shift;
    my($name) = @_;
##  print "Insert '$name'\n";
    my $key = lc $name;
    if (exists $self->{entry}{$key}) {
        if ($self->{entry}{$key} eq $name) {
            $self->{parser}->Error(
                    "Identifier '$name' already exists.\n");
        }
        else {
            $self->{parser}->Error(
                    "Identifier '$name' collides with '$self->{entry}{$key}'.\n");
        }
    }
    else {
        $self->{entry}{$key} = $name;
    }
    return;
}

sub InsertUsed {
    my $self = shift;
    return if ($self->{parser}->YYData->{collision_allowed});
    my($name) = @_;
##  print "InsertUsed '$name'\n";
    my $key = lc $name;
    $self->{entry}{$key} = $name unless (exists $self->{entry}{$key});
    return;
}

1;

