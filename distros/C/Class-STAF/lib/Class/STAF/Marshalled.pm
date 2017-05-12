package Class::STAF::Marshalled;

our $VERSION = 0.02;

use Data::Dumper;
use Exporter;
our @ISA = qw{Exporter};

our @EXPORT = qw{
    Marshall
    UnMarshall
};

our @EXPORT_OK = qw{
    get_staf_fields
    get_staf_class_name
};

our %EXPORT_TAGS = (all=>[@EXPORT, @EXPORT_OK]);

# Each Class record is a hash ref containing the following fields:
#   FieldsDefs - a hash store of fields definitions, containing the following data:
#       key - the name of the key. example: 'serial'
#       'display-name' - description. example: 'serial #'
#       default - optional. a default for this field. example - 5.
#       short - optional. a short name for the field. example: 'ser#'
#   FieldsOrder - the same as FieldsDefs, but stored in array. the fields need an
#                 order to be transmitted.
#   PackageName - The name of the handling package. example: 'STAF::Service::Var::VarInfo'
#   SlashedName - Same as PackageName, but with '/' instade of '::'.
#                 example: 'STAF/Service/Var/VarInfo'
#   Final - 0 if no object was ever created from this class definition, 1 otherwise.
#
# The records are stored by both PackageName and SlashedName
our $classes_store = {};

sub field {
    my @params = @_;
    my $usage =
        "usage: \n" .
        "__PACKAGE__->field(name, description [, default=>5] [, short=>\"ser#\"])\n";
    my $err_msg1 = "The Field function should have at least two parameters.\n";
    my $err_msg2 = "Received undefined parameters.\n";
    my $err_msg3 = "Wrong number of parameters.\n";

    die $err_msg1 . $usage if @params < 3;
    my $class = shift @params;
    my $name = shift @params;
    my $description = shift @params;
    die $err_msg2 . $usage
        unless defined $class and defined $name and defined $description;
    die $err_msg3 . $usage
        unless @params % 2 == 0;

    my $package_store;
    if (exists $classes_store->{$class}) {
        $package_store = $classes_store->{$class};
        die "It is not possible to modify class after instiating objects\n"
            if $package_store->{Final};
    } else {
        my $slashedName = $class;
        $slashedName =~ s/::/\//g;
        $package_store = {
            FieldsDefs => {},
            FieldsOrder => [],
            PackageName => $class,
            SlashedName => $slashedName,
            Final => 0,
        };
        $classes_store->{$class} = $package_store;
        $classes_store->{$slashedName} = $package_store;
    }

    die "Field $name already exists in class $class\n"
        if exists $package_store->{FieldsDefs}->{$name};
    my $field = {
        key => $name,
        'display-name' => $description,
    };
    while (@params) {
        my $opt_name = shift @params;
        my $opt_value = shift @params;
        die "option name not recognized: $opt_name\n" . $usage
            unless $opt_name eq "default" or $opt_name eq "short";
        $field->{$opt_name} = $opt_value;
    }
    $package_store->{FieldsDefs}->{$name} = $field;
    push @{$package_store->{FieldsOrder}}, $field;
    # print "Dump: ", Dumper($package_store), "\n";
}

sub new {
    my ($class, @params) = @_;
    die "Class $class not defined\n" unless exists $classes_store->{$class};
    die "Parameters list is not balanced\n" unless @params % 2 == 0;
    my $package_store = $classes_store->{$class};
    $package_store->{Final} = 1;
    my %self;
    tie %self, 'Class::STAF::Marshalled::_Tied', $package_store;
    while (@params) {
        my $opt_name = shift @params;
        my $opt_value = shift @params;
        $self{$opt_name} = $opt_value;
    }
    my $self_ref = \%self;
    return bless $self_ref, $class;
}

sub _internalMarshallSimpleScalar {
    my ($obj_ref, $defs_store) = @_;
    return "\@SDT/\$S:" . length($obj_ref) . ":" . $obj_ref;
}

sub _internalMarshall {
    my ($obj_ref, $defs_store) = @_;
    
    if (!defined $obj_ref) {
        return "\@SDT/\$0:";
    }
    if (!ref($obj_ref)) {
        # it is a simple scalar. marshall it.
        return _internalMarshallSimpleScalar($obj_ref, $defs_store);
    }
    if (UNIVERSAL::isa($obj_ref, "SCALAR")) {
        # a reference to a scalar. recurse on it.
        my $m = _internalMarshall($$obj_ref, $defs_store);
        return "\@SDT/\$S:" . length($m) . ":" . $m;
    }
    if (UNIVERSAL::isa($obj_ref, "ARRAY")) {
        # array reference. no problem.
        my @list = map { _internalMarshall($_, $defs_store) } @$obj_ref;
        my $m = join('', @list);
        return "\@SDT/[" . scalar(@list) . ":" . length($m) . ":" . $m;
    }
    die "Unrecognized Data type!\n" unless UNIVERSAL::isa($obj_ref, "HASH");
    my $tied_obj = tied(%$obj_ref);
    if (!$tied_obj or !UNIVERSAL::isa($tied_obj, 'Class::STAF::Marshalled::_Tied')) {
        # this is a simple hash. nothing to see, move along.
        # @SDT/{:<map-length>:<key-1-length>:<key-1><SDT-Any>
        my @list;
        while (my ($key, $val) = each %$obj_ref) {
            my $key_len = length($key);
            push @list, $key_len . ":" . $key . _internalMarshall($val, $defs_store);
        }
        my $m = join(":", @list);
        return "\@SDT/{:" . length($m) . ":" . $m;
    }
    # A Map Class
    my $class_name = $tied_obj->[1]->{SlashedName};
    $defs_store->{$class_name} = $tied_obj->[1];
    #@SDT/%:<map-class-instance-length>::<map-class-name-length>:<map-class-name>
    #    <SDT-Any-value-1>
    #    ...
    #    <SDT-Any-value-n>
    my @list = map _internalMarshall($tied_obj->[0]->{$_->{key}}, $defs_store), @{$tied_obj->[1]->{FieldsOrder}};
    my $m = ":" . length($class_name) . ":" . $class_name . join('', @list);
    return "\@SDT/%:" . length($m) . ":" . $m;
}

sub _create_class_nametag {
    my ($nametag) = @_;
    return ":" . length($nametag) . ":" . $nametag;
}

sub _create_class_field {
    my ($field) = @_;
    my @list;
    foreach my $field_name (qw{display-name key short}) {
        next unless exists $field->{$field_name};
        push @list, _create_class_nametag($field_name) . _internalMarshallSimpleScalar($field->{$field_name});
    }
    my $m = join("", @list);
    return "\@SDT/{:" . length($m) . ":" . $m;
}

sub _create_class_definition {
    my ($class_name, $record) = @_;
    my @keys_list = map _create_class_field($_), @{$record->{FieldsOrder}};
    my $keys_joined = join '', @keys_list;
    my $keys_marshalled = "\@SDT/[" . scalar(@keys_list) . ":" . length($keys_joined) . ":" . $keys_joined;
    my $name_marshalled = _internalMarshall($class_name, {});
    my $joined1 = ":4:keys" . $keys_marshalled  . ":4:name" . $name_marshalled;
    return _create_class_nametag($class_name) . "\@SDT/{:" . length($joined1) . ":" . $joined1;
}

sub Marshall {
    my @params = @_;
    my $class_def = {};
    my $data;
    die "Please call marshall with at least one data\n" if (@params < 1);
    if (@params == 1) {
        $data = _internalMarshall($params[0], $class_def);
    } else {
        $data = _internalMarshall(\@params, $class_def);        
    }
    # if no class was invovled, return the data itself.
    #return $data unless %$class_def;
    my $serialize_classes;
    if (not %$class_def) {
        # when we have no class - add empty class data
        # wasting bytes is fun.
        $serialize_classes = '@SDT/{:26::13:map-class-map@SDT/{:0:';
    } else {
        my @list;
        while (my ($key, $record) = each %$class_def) {
            push @list, _create_class_definition($key, $record);
        }
        my $class_data_classes = join('', @list);
        my $maped2 = "\@SDT/{:" . length($class_data_classes) . ":" . $class_data_classes;
        my $joined3 = ":13:map-class-map" . $maped2;
        $serialize_classes = "\@SDT/{:" . length($joined3) . ":" . $joined3;
    }
    
    my $total_data = $serialize_classes . $data;
    return "\@SDT/*:" . length($total_data) . ":" . $total_data;
}

sub _unmarshallClassDef_keydef {
    my ($string_ref, $pos_ref) = @_;
    my ($prefix, $len1) = $$string_ref =~ /^(\@SDT\/{:(\d+):)/;
    die "Not a STAF data. at " . $$pos_ref . " near " . substr($$string_ref, 0, 10)
        unless defined $len1;
    substr($$string_ref, 0, length($prefix), '');
    $$pos_ref += length($prefix);

    my $my_string = substr($$string_ref, 0, $len1);
    my %key_def;
    while ($my_string) {
        my ($p_name_len) = $my_string =~ /^:(\d+):/;
        die "Not a STAF data. at " . $$pos_ref . " near " . substr($$string_ref, 0, 10)
            unless (defined $p_name_len) and (length($my_string) >= $p_name_len + length($p_name_len) + 2);
        substr($my_string, 0, 2 + length($p_name_len), '');
        my $p_name = substr($my_string, 0, $p_name_len, '');
        $$pos_ref += $p_name_len + 2 + length($p_name_len);
        
        my ($prefix2, $p_value_len) = $my_string =~ /^(\@SDT\/\$S:(\d+):)/;
        die "Not a STAF data. at " . $$pos_ref . " near " . substr($$string_ref, 0, 10)
            unless (defined $p_value_len) and (length($my_string) >= $p_value_len + length($prefix2));
        substr($my_string, 0, length($prefix2), '');
        my $p_value = substr($my_string, 0, $p_value_len, '');
        $$pos_ref += $p_value_len + length($prefix2);
        
        $key_def{$p_name} = $p_value;
    }
    
    substr($$string_ref, 0, $len1, '');
    $$pos_ref += $len1;
    return \%key_def;
}

sub _unmarshallClassDef {
    my ($string_ref, $pos_ref, $class_storage) = @_;
    my ($len1) = $$string_ref =~ /^:(\d+):/;
    die "Not a STAF data. at " . $$pos_ref . " near " . substr($$string_ref, 0, 10)
        unless defined $len1;

    substr($$string_ref, 0, 2 + length($len1), '');
    my $slashed_name = substr($$string_ref, 0, $len1, '');
    $$pos_ref += $len1 + length($len1) + 2;
    
    my ($prefix, $num_of_keys) = $$string_ref =~ /^(\@SDT\/{:\d+::4:keys\@SDT\/\[(\d+):\d+:)/;
    die "Not a STAF data. at " . $$pos_ref . " near " . substr($$string_ref, 0, 10)
        unless defined $prefix;
    substr($$string_ref, 0, length($prefix), '');
    $$pos_ref += length($prefix);
    
    my @keys_defs;
    for (1..$num_of_keys) {
        my $key_def = _unmarshallClassDef_keydef($string_ref, $pos_ref);
        push @keys_defs, $key_def;
    }
    my %fields = map { ( $_->{key}, $_ ) } @keys_defs;
    my ($postfix, $len2) = $$string_ref =~ /^(:4:name\@SDT\/\$S:(\d+):)/;
    die "Not a STAF data. at " . $$pos_ref . " near " . substr($$string_ref, 0, 10)
        unless defined $postfix;
    substr($$string_ref, 0, length($postfix) + $len2, '');
    $$pos_ref += length($postfix) + $len2;
    
    my $class_def = {
        FieldsDefs => \%fields,
        FieldsOrder => \@keys_defs,
        PackageName => '', # incoming class - no package associated.
        SlashedName => $slashed_name,
        Final => 1,
    };
    $class_storage->{$slashed_name} = $class_def;
}

sub _internalUnmarshall {
    my ($string_ref, $pos_ref, $class_storage) = @_;
    
    my ($type, $typeInfo, $len) = $$string_ref =~ /^\@SDT\/(\{|\[|\$|\*|\%)([^:]*):(\d*):/;
    die "Not a STAF data. at " . $$pos_ref . " near " . substr($$string_ref, 0, 10)
        unless $type;
    
    {
        # remove the already processed prefix
        my $second_colon = length($typeInfo) + length($len) + 7;
        my $length_handled = $second_colon + 1;
        substr($$string_ref, 0, $length_handled, '');
        $$pos_ref += $length_handled;
    }
    $len = 0 unless $len;
    
    if ($type eq '$') {
        if ($typeInfo eq '0') {
            return undef;
        } elsif ($typeInfo eq 'S') {
            my $ret_string = substr($$string_ref, 0, $len, '');
            $$pos_ref += $len;
            return $ret_string;
        } else {
            die "Failed parsing string at " . $$pos_ref . " near " . substr($$string_ref, 0, 5);
        }
    } elsif ($type eq '[') {
        # @SDT/[<number-of-items>:<array-length>:<SDT-Any-1>...<SDT-Any-n>
        die "Not a STAF data. at " . $$pos_ref . " near " . substr($$string_ref, 0, 10)
            unless $typeInfo =~ /\d+/;
        my @list;
        for (1..$typeInfo) {
            push @list, _internalUnmarshall($string_ref, $pos_ref, $class_storage);
        }
        return \@list;
    } elsif ($type eq '{') {
        # @SDT/{:<map-length>:<key-1-length>:<key-1><SDT-Any>
        #                    ...
        #                    :<key-n-length>:<key-1><SDT-Any>
        if ($len == 0) {
            # handle an empty map
            return {};
        }
        my $the_rest = ":" . substr($$string_ref, 0, $len);
        my %map;
        while ($the_rest) {
            die "Failed parsing string at " . $$pos_ref . " near " . substr($the_rest, 0, 5)
                unless substr($the_rest, 0, 1) eq ':';
            my $next_colon = index($the_rest, ':', 1);
            die "Failed parsing string at " . $$pos_ref . " near " . substr($the_rest, 0, 5)
                unless $next_colon > 1 and $next_colon < 8;
            my $key_len = substr($the_rest, 1, $next_colon - 2);
            my $key_name = substr($the_rest, $next_colon+1, $key_len);
            my $handled = $next_colon + 1 + $key_len;
            $$pos_ref += $handled;
            substr($the_rest, 0, $handled, '');
            my $value = _internalUnmarshall(\$the_rest, $pos_ref, $class_storage);
            $map{$key_name} = $value;
        }
        substr($$string_ref, 0, $len, '');
        return \%map;
    } elsif ($type eq '%') {
        #@SDT/%:<map-class-instance-length>::<map-class-name-length>:<map-class-name>
        #    <SDT-Any-value-1>
        #    ...
        #    <SDT-Any-value-n>
        my ($name_len) = $$string_ref =~ /^:(\d+):/;
        my $class_name = substr($$string_ref, 2 + length($name_len), $name_len);
        die "Not a STAF data - unrecognized class. at " . $$pos_ref . " near " . substr($$string_ref, 0, 10)
            unless exists $class_storage->{$class_name};
        my $class_data = $class_storage->{$class_name};
        # remove the class name from the string 
        my $handled = 2 + length($name_len) + $name_len;
        substr($$string_ref, 0, $handled, '');
        $$pos_ref += $handled;
        # create class instance
        my %object;
        tie %object, 'Class::STAF::Marshalled::_Tied', $class_data;
        foreach my $field_record (@{ $class_data->{FieldsOrder} }) {
            my $value = _internalUnmarshall($string_ref, $pos_ref, $class_storage);
            $object{$field_record->{key}} = $value;
        }
        my $object_ref = \%object;
        return bless $object_ref, 'Class::STAF::Marshalled';
    } elsif ($type eq '*') {
        my ($len1, $len2) = $$string_ref =~ /^\@SDT\/{:(\d+)::13:map-class-map\@SDT\/{:(\d+):/;
        my $prefix_len = length("\@SDT\/{:::13:map-class-map\@SDT\/{::") + length($len1) + length($len2);
        substr($$string_ref, 0, $prefix_len, '');
        $$pos_ref += $prefix_len;
        my $classes_raw_string = substr($$string_ref, 0, $len2, '');
        while ($classes_raw_string) {
            _unmarshallClassDef(\$classes_raw_string, $pos_ref, $class_storage);
        }
        return _internalUnmarshall($string_ref, $pos_ref, $class_storage);
    }
}

sub UnMarshall {
    my $string = shift;
    return undef if (!defined $string) or ($string !~ /^\@SDT\//);
    my $current_pos = 0;
    my $ret_data;
    eval {
        $ret_data = _internalUnmarshall(\$string, \$current_pos, {});
    };
    print $@ if $@;
    print "Error: not all data was parsed: |", $string, "|\n"
        if $string;
    return $ret_data;
}

sub get_staf_class_name {
    my $ref = shift;
    if (not defined $ref) {
        die "usage: get_staf_class_name(\$ref)";
    }
    return unless UNIVERSAL::isa($ref, "HASH"); # a class have to be a hash ref
    my $tied_obj = tied(%$ref);
    return unless $tied_obj; # and a tied object
    return unless UNIVERSAL::isa($tied_obj, 'Class::STAF::Marshalled::_Tied');
    return scalar($tied_obj->[1]->{SlashedName});
}

sub get_staf_fields {
    my $ref = shift;
    if (not defined $ref) {
        die "usage: get_staf_fields(\$ref)";
    }
    return unless UNIVERSAL::isa($ref, "HASH"); # a class have to be a hash ref
    my $tied_obj = tied(%$ref);
    return unless $tied_obj; # and a tied object
    return unless UNIVERSAL::isa($tied_obj, 'Class::STAF::Marshalled::_Tied');
    my @fields = map { +{ %$_ } } @{ $tied_obj->[1]->{FieldsOrder} };
    return @fields;
}

package # hide?
    Class::STAF::Marshalled::_Tied;

# Each Tied object is a blessed array ref, that contain two items:
#   [0] - hash ref with all the fields pre-defined
#   [1] - a reference to the class definition, sent from STAF::Marshalled
sub TIEHASH {
    my ($class, $package_store) = @_;
    my %values;
    while (my ($key, $val) = each %{$package_store->{FieldsDefs}}) {
        if (exists $val->{default}) {
            $values{$key} = $val->{default};
        } else {
            $values{$key} = undef;
        }
    }
    my $self = [\%values, $package_store];
    return bless $self, $class;
}

sub FETCH {
    my ($self, $key) = @_;
    die "Key $key does not exists\n" unless exists $self->[0]->{$key};
    return $self->[0]->{$key};
}

sub STORE {
    my ($self, $key, $value) = @_;
    die "Key $key does not exist\n" unless exists $self->[0]->{$key};
    $self->[0]->{$key} = $value;
}

sub DELETE {
    my ($self, $key) = @_;
    die "Deleting keys from an Object does not make sense\n";
}

sub CLEAR {
    my ($self) = @_;
    while (my ($key, $val) = each %{$self->{fields_defs}}) {
        if (exists $val->{default}) {
            $self->[0]->{$key} = $val->{default};
        } else {
            $self->[0]->{$key} = undef;
        }
    }
}

sub EXISTS {
    my ($self, $key) = @_;
    return exists $self->[0]->{$key};
}

sub FIRSTKEY {
    my ($self) = @_;
    return each %{$self->[0]};
}

sub NEXTKEY {
    my ($self, $last_key) = @_;
    return each %{$self->[0]};
}

sub SCALAR {
    my ($self) = @_;
    return scalar %{$self->[0]};
}

1;

__END__

=head1 NAME

Class::STAF::Marshalled - an OO approach to Marshalling and UnMarshalling STAF data (http://staf.sourceforge.net/)

=head1 SYNOPSIS

Preparing regular data to be sent:

    use Class::STAF;
    
    my $x = [ { a1=>5, a2=>6 }, "bbbb", [1, 2, 3] ];
    my $out_string = Marshall($x);

Preparing class data to be sent:

    package STAF::Service::Var::VarInfo;
    use base qw/Class::STAF::Marshalled/;
    __PACKAGE__->field("X", "X");
    __PACKAGE__->field("Y", "Y", default=>5);
    __PACKAGE__->field("serial", "SerialNumber", short=>"ser#");

    ... elsewhere in your program
    $ref = STAF::Service::Var::VarInfo->new("X"=>3, "serial"=> 37);
    # ... and Y is 5, by default.
    $out_string = Marshall($ref);

Receiving and manipulating data:

    my $ref = UnMarshall($incoming_string);
    my $info = $ref->[0]->{info};
    $ref->[2]->{Number} = 3;
    $out_string = Marshall($ref);

=head1 DESCRIPTION

This module is an OO interface to the STAF Marshalling API, inspired by Class::DBI.

Marshalling is serializing. The same job done by Storable and such, only compatible with
the standard serializing API the the STAF framework create and understand.

For more info about STAF: http://staf.sourceforge.net/

This API covers handling scalars, arrays, and hashes. Use this API to create
classes and send them; 
accept data that includes classes from a different origin, manipulate it,
and marshall it back with the original classes defenitions. and all this is completely
transparant to the developer.

=head1 Functions

=head2 Marshall

Stringify a data structure.

    $out_string1 = Marshall($single_ref);
    $out_string2 = Marshall($ref1, $ref2, ...);

Can handle any array, hash or scalar that is received by reference. If a list/array is
passed, it is handled as if a reference to that array was passed.

=head2 UnMarshall

Un-Stringify a data structure.

    my $ref = UnMarshall($stringify_data);

accept a single string containing marshalled data, and return a single reference
to the opened data.

=head2 get_staf_class_name

Not exported by default.

Accept a hash reference, and return the name of the STAF-class that it instantiate.
Return undef if the reference is not to a STAF-class.

=head2 get_staf_fields

Not exported by default.

Accept a hash reference, and return the list of fields. Each of the fields contains
at least the map-key ('key') and the display-name ('display-name'). May contain
a default ('default') and short name ('short') if defined.

=head1 Building staf-class

=head2 Defining

For building a STAF-class, define a package and base it on Class::STAF::Marshalled,
for example:

    package STAF::Service::My::FileRecord;
    use base qw/Class::STAF::Marshalled/;

Will define a STAF-class named 'STAF/Service/My/FileRecord', (names of classes
in STAF are delimited with slashes instead of '::') then define the members of the class:

    __PACKAGE__->field("name", "LongFileName");
    __PACKAGE__->field("size", "SizeInBytes", default=>0);
    __PACKAGE__->field("owner", "FileOwner", short=>"owner");

The syntax of the command is:

    __PACKAGE__->field(name, description [, default=>5] [, short=>"ser#"]);

The first and second parameters are the name and description of the field.
Two more optional parameters are named default and short
(when displaying the class in formatted text, it is sometimes needed).

=head2 Instancing

Simple.

    $filerec1 = STAF::Service::My::FileRecord->new();

The fields defined as default will be assigned their default values, all other will be left undefined.

    $filerec2 = STAF::Service::My::FileRecord->new(name=>"system.ini", owner=>"me");

Fields specified will be assigned that value. Fields that were not specified but have a default
value, will be assigned the default value. Fields that neither specified nor have a default,
will left undefined. 

    $filerec2 = STAF::Service::My::FileRecord->new(name=>"system.ini", size=>70);

=head2 Perl and STAF classes

When instancing a class, it will be blessed to that Perl class. So it is possible
to define subrotines inside these classes.

However, when a class data is being unmarshalled, it is blessed to Class::STAF::Marshalled,
and not to its true name, (that can be anything that the sender want) for oblious
security reasons.

So, if it is needed to find out the name of a locally created class, it is possible
to use the ref keyword. If it is an unmarshalled class, use the get_staf_class_name function.

=head1 BUGS

None known.

This is a first release - your feedback will be appreciated.

=head1 SEE ALSO

STAF homepage: http://staf.sourceforge.net/
Main package: L<Class::STAF>

=head1 AUTHOR

Fomberg Shmuel, E<lt>owner@semuel.co.ilE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Shmuel Fomberg.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
