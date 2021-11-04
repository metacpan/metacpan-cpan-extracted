#+##############################################################################
#                                                                              #
# File: Config/Validator.pm                                                    #
#                                                                              #
# Description: schema based configuration validation                           #
#                                                                              #
#-##############################################################################

#
# module definition
#

package Config::Validator;
use strict;
use warnings;
our $VERSION  = "1.4";
our $REVISION = sprintf("%d.%02d", q$Revision: 1.36 $ =~ /(\d+)\.(\d+)/);

#
# used modules
#

use No::Worries::Die qw(dief);
use No::Worries::Export qw(export_control);
use Scalar::Util qw(blessed reftype);
use URI::Escape qw(uri_escape uri_unescape);

#
# global variables
#

our(
    $_Known,         # hash reference of known schemas used by _check_type()
    $_BuiltIn,       # hash reference of built-in schemas (to validate schemas)
    %_RE,            # hash of commonly used regular expressions
    %_DurationScale, # hash of duration suffixes
    %_SizeScale,     # hash of size suffixes
);

%_DurationScale = (
    ms => 0.001,
     s => 1,
     m => 60,
     h => 60 * 60,
     d => 60 * 60 * 24,
);

%_SizeScale = (
     b => 1,
    kb => 1024,
    mb => 1024 * 1024,
    gb => 1024 * 1024 * 1024,
    tb => 1024 * 1024 * 1024 * 1024,
);

#+++############################################################################
#                                                                              #
# regular expressions                                                          #
#                                                                              #
#---############################################################################

sub _init_regexp () {
    my($label, $byte, $hex4, $ipv4, $ipv6, @tail);

    # simple ones
    $_RE{boolean} = q/true|false/;
    $_RE{integer} = q/[\+\-]?\d+/;
    $_RE{number} = q/[\+\-]?(?=\d|\.\d)\d*(?:\.\d*)?(?:[Ee][\+\-]?\d+)?/;
    $_RE{duration} = q/(?:\d+(?:ms|s|m|h|d))+|\d+/;
    $_RE{size} = q/\d+[bB]?|(?:\d+\.)?\d+[kKmMgGtT][bB]/;
    # complex ones
    $label = q/[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?/;
    $byte = q/25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d/;
    $hex4 = q/[0-9a-fA-F]{1,4}/;
    $ipv4 = qq/(($byte)\\.){3}($byte)/;
    @tail = (
        ":",
        "(:($hex4)?|($ipv4))",
        ":(($ipv4)|$hex4(:$hex4)?|)",
        "(:($ipv4)|:$hex4(:($ipv4)|(:$hex4){0,2})|:)",
        "((:$hex4){0,2}(:($ipv4)|(:$hex4){1,2})|:)",
        "((:$hex4){0,3}(:($ipv4)|(:$hex4){1,2})|:)",
        "((:$hex4){0,4}(:($ipv4)|(:$hex4){1,2})|:)",
    );
    $ipv6 = $hex4;
    foreach my $tail (@tail) {
        $ipv6 = "$hex4:($ipv6|$tail)";
    }
    $ipv6 = qq/:(:$hex4){0,5}((:$hex4){1,2}|:$ipv4)|$ipv6/;
    $_RE{hostname} = qq/($label\\.)*$label/;
    $_RE{ipv4} = $ipv4;
    $_RE{ipv6} = $ipv6;
    # improve some of them
    foreach my $name (qw(hostname ipv4 ipv6)) {
        $_RE{$name} =~ s/\(/(?:/g;
    }
    # compile them all
    foreach my $name (keys(%_RE)) {
        $_RE{$name} = qr/^(?:$_RE{$name})$/;
    }
}

_init_regexp();

#+++############################################################################
#                                                                              #
# helper functions                                                             #
#                                                                              #
#---############################################################################

#
# stringify any scalar, including undef
#

sub _string ($) {
    my($scalar) = @_;

    return(defined($scalar) ? "$scalar" : "<undef>");
}

#
# format an error
#

sub _errfmt (@);
sub _errfmt (@) {
    my(@errors) = @_;
    my($string, $tmp);

    return("") unless @errors;
    $string = shift(@errors);
    foreach my $error (@errors) {
        $tmp = ref($error) ? _errfmt(@{ $error }) : $error;
        next unless length($tmp);
        $tmp =~ s/^/  /mg;
        $string .= "\n" . $tmp;
    }
    return($string);
}

#
# expand a duration string and return the corresponding number of seconds
#

sub expand_duration ($) {
    my($value) = @_;
    my($result);

    if ($value =~ /^(\d+(ms|s|m|h|d))+$/) {
        $result = 0;
        while ($value =~ /(\d+)(ms|s|m|h|d)/g) {
            $result += $1 * $_DurationScale{$2};
        }
    } else {
        $result = $value;
    }
    return($result);
}

#
# expand a size string and return the corresponding number of bytes
#

sub expand_size ($) {
    my($value) = @_;

    if ($value =~ /^(.+?)([kmgt]?b)$/i) {
        return(int($1 * $_SizeScale{lc($2)} + 0.5));
    } else {
        return($value);
    }
}

#
# test if a boolean is true or false
#

sub is_true ($) {
    my($value) = @_;

    return(undef) unless defined($value);
    return($value and not ref($value) and $value eq "true");
}

sub is_false ($) {
    my($value) = @_;

    return(undef) unless defined($value);
    return($value and not ref($value) and $value eq "false");
}

#
# return the given thing as a list
#

sub listof ($) {
    my($thing) = @_;

    return() unless defined($thing);
    return(@{ $thing }) if ref($thing) eq "ARRAY";
    return($thing);
}

#+++############################################################################
#                                                                              #
# conversion helper functions                                                  #
#                                                                              #
#---############################################################################

#
# string -> hash
#

sub string2hash ($) {
    my($string) = @_;
    my(%hash);

    foreach my $kv (split(/\s+/, $string)) {
        if ($kv =~ /^([^\=]+)=(.*)$/) {
            $hash{uri_unescape($1)} = uri_unescape($2);
        } else {
            dief("invalid hash key=value: %s", $kv);
        }
    }
    return(%hash) if wantarray();
    return(\%hash);
}

#
# hash -> string
#

sub hash2string (@) {
    my(@args) = @_;
    my($hash, @kvs);

    if (@args == 1 and ref($args[0]) eq "HASH") {
        $hash = $args[0];
    } else {
        $hash = { @args };
    }
    foreach my $key (sort(keys(%{ $hash }))) {
        push(@kvs, uri_escape($key) . "=" . uri_escape($hash->{$key}));
    }
    return(join(" ", @kvs));
}

#
# treeify
#

sub treeify ($);
sub treeify ($) {
    my($hash) = @_;

    foreach my $key (grep(/-/, keys(%{ $hash }))) {
        if ($key =~ /^(\w+)-(.+)$/) {
            $hash->{$1}{$2} = delete($hash->{$key});
        } else {
            dief("unexpected configuration name: %s", $key);
        }
    }
    foreach my $value (values(%{ $hash })) {
        treeify($value) if ref($value) eq "HASH";
    }
}

#
# return the value of the given option in a treeified hash
#

sub treeval ($$);
sub treeval ($$) {
    my($hash, $name) = @_;

    return($hash->{$name}) if exists($hash->{$name});
    if ($name =~ /^(\w+)-(.+)$/) {
        return() unless $hash->{$1};
        return(treeval($hash->{$1}, $2));
    }
    return();
}

#+++############################################################################
#                                                                              #
# built-in schemas                                                             #
#                                                                              #
#---############################################################################

#
# check that a type is valid
#

sub _check_type ($$$);
sub _check_type ($$$) {
    my($valid, $schema, $data) = @_;

    return() if $data =~ /^[a-z46]+$/;
    return() if $data =~ /^(ref|isa)\(\*\)$/;
    return() if $data =~ /^(ref|isa)\([\w\:]+\)$/;
    if ($data =~ /^(list\??|table)\((.+)\)$/) {
        return(_check_type($valid, $schema, $2));
    }
    if ($data =~ /^valid\((.+)\)$/) {
        return() if $_Known->{$1};
        return("unknown schema: $1");
    }
    return("unexpected type: $data");
}

#
# schema of a "type"
#

$_BuiltIn->{type} = {
    type  => "string",
    match => qr/ ^
        ( anything        # really anything
        | undef           # undef
        | undefined       #   "
        | defined         # not undef
        | string          # any string
        | boolean         # either 'true' or 'false'
        | number          # any number
        | integer         # any integer
        | duration        # any duration, i.e. numbers with hms suffixes
        | size            # any size, i.e. number with optional byte-suffix
        | hostname        # host name
        | ipv4            # IPv4 address
        | ipv6            # IPv6 address
        | reference       # any reference, blessed or not
        | ref\(\*\)       #   "
        | blessed         # any blessed reference
        | object          #   "
        | isa\(\*\)       #   "
        | unblessed       # any reference which is not blessed
        | code            # a code reference (aka ref(CODE))
        | regexp          # a regular expression (see is_regexp())
        | list            # an homogeneous list
        | list\(.+\)      # idem but with the given subtype
        | list\?\(.+\)    # shortcut: list?(X) means either X or list(X)
        | table           # an homogeneous table
        | table\(.+\)     # idem but with the given subtype
        | struct          # a structure, i.e. a table with known keys
        | ref\(.+\)       # a reference of the given kind
        | isa\(.+\)       # an object of the given kind
        | valid\(.+\)     # something valid according to the named schema
        ) $ /x,
    check => \&_check_type,
};

#
# check that a schema is valid
#

sub _check_schema ($$$);
sub _check_schema ($$$) {
    my($valid, $schema, $data) = @_;
    my($field);

    $field = "min";
    goto unexpected if defined($data->{$field})
        and not $data->{type} =~ /^(string|number|integer|list.*|table.*)$/;
    $field = "max";
    goto unexpected if defined($data->{$field})
        and not $data->{type} =~ /^(string|number|integer|list.*|table.*)$/;
    $field = "match";
    goto unexpected if defined($data->{$field})
        and not $data->{type} =~ /^(string|table.*)$/;
    $field = "subtype";
    if ($data->{type} =~ /^(list|table)$/) {
        goto missing unless defined($data->{$field});
    } else {
        goto unexpected if defined($data->{$field});
    }
    $field = "fields";
    if ($data->{type} =~ /^(struct)$/) {
        goto missing unless defined($data->{$field});
    } else {
        goto unexpected if defined($data->{$field});
    }
    return();
  unexpected:
    return(sprintf("unexpected schema field for type %s: %s",
                   $data->{type}, $field));
  missing:
    return(sprintf("missing schema field for type %s: %s",
                   $data->{type}, $field));
}

#
# schema of a "schema"
#

$_BuiltIn->{schema} = {
    type   => "struct",
    fields => {
        type     => { type => "list?(valid(type))" },
        subtype  => { type => "valid(schema)",        optional => "true" },
        fields   => { type => "table(valid(schema))", optional => "true" },
        optional => { type => "boolean",              optional => "true" },
        min      => { type => "number",               optional => "true" },
        max      => { type => "number",               optional => "true" },
        match    => { type => "regexp",               optional => "true" },
        check    => { type => "code",                 optional => "true" },
    },
    check => \&_check_schema,
};

#+++############################################################################
#                                                                              #
# options helpers                                                              #
#                                                                              #
#---############################################################################

#
# schema -> options
#

sub _options ($$$@);
sub _options ($$$@) {
    my($valid, $schema, $type, @path) = @_;
    my(@list);

    $type ||= $schema->{type};
    # terminal
    return(join("-", @path) . "=s") if $type eq "string";
    return(join("-", @path) . "=f") if $type eq "number";
    return(join("-", @path) . "=i") if $type eq "integer";
    return(join("-", @path) . "!")  if $type eq "boolean";
    # assumed to come from strings
    return(join("-", @path) . "=s")
        if $type =~ /^isa\(.+\)$/
        or $type eq "table(string)"
        or $type =~ /^(duration|hostname|ipv[46]|regexp|size)$/;
    # recursion
    if ($type =~ /^list\?\((.+)\)$/) {
        return(map($_ . "\@", _options($valid, $schema, $1, @path)));
    }
    if ($type =~ /^valid\((.+)\)$/) {
        dief("options(): unknown schema: %s", $1) unless $valid->{$1};
        return(_options($valid, $valid->{$1}, undef, @path));
    }
    if ($type eq "struct") {
        foreach my $field (keys(%{ $schema->{fields} })) {
            push(@list, _options($valid, $schema->{fields}{$field},
                                 undef, @path, $field));
        }
        return(@list);
    }
    # unsupported
    dief("options(): unsupported type: %s", $type);
}

#
# treat the given options as mutually exclusive
#

sub mutex ($@) {
    my($hash, @options) = @_;
    my(@list);

    foreach my $opt (@options) {
        next unless defined(treeval($hash, $opt));
        push(@list, $opt);
        dief("options %s and %s are mutually exclusive", @list) if @list == 2;
    }
}

#
# if the first option is set, all the others are required
#

sub reqall ($$@) {
    my($hash, $opt1, @options) = @_;

    return unless not defined($opt1) or defined(treeval($hash, $opt1));
    foreach my $opt2 (@options) {
        next if defined(treeval($hash, $opt2));
        dief("option %s requires option %s", $opt1, $opt2) if defined($opt1);
        dief("option %s is required", $opt2);
    }
}

#
# if the first option is set, one at least of the others is required
#

sub reqany ($$@) {
    my($hash, $opt1, @options) = @_;
    my($req);

    return unless not defined($opt1) or defined(treeval($hash, $opt1));
    foreach my $opt2 (@options) {
        return if defined(treeval($hash, $opt2));
    }
    if (@options <= 2) {
        $req = join(" or ", @options);
    } else {
        push(@options, join(" or ", splice(@options, -2)));
        $req = join(", ", @options);
    }
    dief("option %s requires option %s", $opt1, $req) if defined($opt1);
    dief("option %s is required", $req);
}

#+++############################################################################
#                                                                              #
# traverse helpers                                                             #
#                                                                              #
#---############################################################################

#
# traverse data
#

sub _traverse_list ($$$$$$@) {
    my($callback, $valid, $schema, $reftype, $subtype, $data, @path) = @_;

    return unless $reftype eq "ARRAY";
    foreach my $val (@{ $data }) {
        _traverse($callback, $valid, $schema, $subtype,
                  $val, @path, 0);
    }
}

sub _traverse_table ($$$$$$@) {
    my($callback, $valid, $schema, $reftype, $subtype, $data, @path) = @_;

    return unless $reftype eq "HASH";
    foreach my $key (keys(%{ $data })) {
        _traverse($callback, $valid, $schema, $subtype,
                  $data->{$key}, @path, $key);
    }
}

sub _traverse_struct ($$$$$$@) {
    my($callback, $valid, $schema, $reftype, $subtype, $data, @path) = @_;

    return unless $reftype eq "HASH";
    foreach my $key (keys(%{ $schema->{fields} })) {
        next unless exists($data->{$key});
        _traverse($callback, $valid, $schema->{fields}{$key}, undef,
                  $data->{$key}, @path, $key);
    }
}

sub _traverse ($$$$$@);
sub _traverse ($$$$$@) {
    my($callback, $valid, $schema, $type, $data, @path) = @_;
    my($reftype, $subtype);

    # set the type if missing
    $type ||= $schema->{type};
    # call the callback and stop unless we are told to continue
    return unless $callback->($valid, $schema, $type, $_[4], @path);
    # terminal
    return if $type =~ /^(boolean|number|integer)$/;
    return if $type =~ /^(duration|size|hostname|ipv[46])$/;
    return if $type =~ /^(undef|undefined|defined|blessed|unblessed)$/;
    return if $type =~ /^(anything|string|regexp|object|reference|code)$/;
    # recursion
    $reftype = reftype($data) || "";
    if ($type =~ /^valid\((.+)\)$/) {
        dief("traverse(): unknown schema: %s", $1) unless $valid->{$1};
        _traverse($callback, $valid, $valid->{$1}, undef, $_[4], @path);
        return;
    }
    if ($type eq "struct") {
        _traverse_struct($callback, $valid, $schema,
                         $reftype, $subtype, $data, @path);
        return;
    }
    if ($type =~ /^list$/) {
        _traverse_list($callback, $valid, $schema->{subtype},
                       $reftype, $subtype, $data, @path);
        return;
    }
    if ($type =~ /^list\((.+)\)$/) {
        _traverse_list($callback, $valid, $schema,
                       $reftype, $1, $data, @path);
        return;
    }
    if ($type =~ /^list\?\((.+)\)$/) {
        if ($reftype eq "ARRAY") {
            _traverse_list($callback, $valid, $schema,
                           $reftype, $1, $data, @path);
        } else {
            _traverse($callback, $valid, $schema,
                      $1, $_[4], @path);
        }
        return;
    }
    if ($type =~ /^table$/) {
        _traverse_table($callback, $valid, $schema->{subtype},
                        $reftype, $subtype, $data, @path);
        return;
    }
    if ($type =~ /^table\((.+)\)$/) {
        _traverse_table($callback, $valid, $schema,
                        $reftype, $1, $data, @path);
        return;
    }
    # unsupported
    dief("traverse(): unsupported type: %s", $type);
}

#+++############################################################################
#                                                                              #
# validation helpers                                                           #
#                                                                              #
#---############################################################################

#
# test if something is a regular expression
#

if ($] >= 5.010) {
    require re;
    re->import(qw(is_regexp));
} else {
    *is_regexp = sub { return(ref($_[0]) eq "Regexp") };
}

#
# validate that a value is within a numerical range
#

sub _validate_range ($$$$) {
    my($what, $value, $min, $max) = @_;

    return(sprintf("%s is not >= %s: %s", $what, $min, $value))
        if defined($min) and not $value >= $min;
    return(sprintf("%s is not <= %s: %s", $what, $max, $value))
        if defined($max) and not $value <= $max;
    return();
}

#
# validate a list of homogeneous elements
#

sub _validate_list ($$$) {
    my($valid, $schema, $data) = @_;
    my(@errors, $index, $element);

    @errors = _validate_range("size", scalar(@{ $data }),
                              $schema->{min}, $schema->{max})
        if defined($schema->{min}) or defined($schema->{max});
    return(@errors) if @errors;
    $index = 0;
    foreach my $tmp (@{ $data }) {
        $element = $tmp; # preserved outside loop
        @errors = _validate($valid, $schema->{subtype}, $element);
        goto invalid if @errors;
        $index++;
    }
    return();
  invalid:
    return(sprintf("invalid element %d: %s",
                   $index, _string($element)), \@errors);
}

#
# validate a table of homogeneous elements
#

sub _validate_table ($$$) {
    my($valid, $schema, $data) = @_;
    my(@errors, $key);

    @errors = _validate_range("size", scalar(keys(%{ $data })),
                              $schema->{min}, $schema->{max})
        if defined($schema->{min}) or defined($schema->{max});
    return(@errors) if @errors;
    foreach my $tmp (keys(%{ $data })) {
        $key = $tmp; # preserved outside loop
        @errors = (sprintf("key does not match %s: %s",
                           $schema->{match}, $key))
            if defined($schema->{match}) and not $key =~ $schema->{match};
        goto invalid if @errors;
        @errors = _validate($valid, $schema->{subtype}, $data->{$key});
        goto invalid if @errors;
    }
    return();
  invalid:
    return(sprintf("invalid element %s: %s",
                   $key, _string($data->{$key})), \@errors);
}

#
# validate a struct, i.e. a hash with known fields
#

sub _validate_struct ($$$) {
    my($valid, $schema, $data) = @_;
    my(@errors, $key);

    # check the missing fields
    foreach my $tmp (keys(%{ $schema->{fields} })) {
        $key = $tmp; # preserved outside loop
        next if exists($data->{$key});
        next if is_true($schema->{fields}{$key}{optional});
        return(sprintf("missing field: %s", $key));
    }
    # check the existing fields
    foreach my $tmp (keys(%{ $data })) {
        $key = $tmp; # preserved outside loop
        return(sprintf("unexpected field: %s", $key))
            unless $schema->{fields}{$key};
        @errors = _validate($valid, $schema->{fields}{$key}, $data->{$key});
        goto invalid if @errors;
    }
    return();
  invalid:
    return(sprintf("invalid field %s: %s",
                   $key, _string($data->{$key})), \@errors);
}

#
# validate something using multiple possible types
#

sub _validate_multiple ($$$@) {
    my($valid, $schema, $data, @types) = @_;
    my(@errors, %tmpschema, @tmperrors);

    %tmpschema = %{ $schema };
    foreach my $type (@types) {
        $tmpschema{type} = $type;
        @tmperrors = _validate($valid, \%tmpschema, $data);
        return() unless @tmperrors;
        push(@errors, [ @tmperrors ]);
    }
    return(sprintf("invalid data (none of the types could be validated): %s",
                   _string($data)), @errors);
}

#
# validate data (non-reference types)
#

sub _validate_data_nonref ($$) {
    my($schema, $data) = @_;
    my($type, @errors);

    $type = $schema->{type};
    if ($type eq "string") {
        @errors = _validate_range
            ("length", length($data), $schema->{min}, $schema->{max})
            if defined($schema->{min}) or defined($schema->{max});
        @errors = (sprintf("value does not match %s: %s",
                           $schema->{match}, $data))
            if not @errors and defined($schema->{match})
                and not $data =~ $schema->{match};
    } elsif ($type =~ /^(boolean|hostname|ipv[46])$/) {
        goto invalid unless $data =~ $_RE{$type};
        # additional hard-coded checks for host names...
        if ($type eq "hostname") {
            goto invalid if ".$data." =~ /\.\d+\./;
            @errors = _validate_range("length", length($data), 1, 255);
        }
    } elsif ($type =~ /^(integer|number|duration|size)$/) {
        goto invalid unless $data =~ $_RE{$type};
        @errors = _validate_range
            ("value", $data, $schema->{min}, $schema->{max})
            if defined($schema->{min}) or defined($schema->{max});
    } else {
        return(sprintf("unexpected type: %s", $type));
    }
    return() unless @errors;
  invalid:
    return(sprintf("invalid %s: %s", $type, $data), \@errors);
}

#
# validate data (reference types)
#

## no critic (ProhibitCascadingIfElse, ProhibitExcessComplexity)
sub _validate_data_ref ($$$$) {
    my($valid, $schema, $data, $reftype) = @_;
    my(@errors, %tmpschema, $blessed);

    $blessed = defined(blessed($data));
    if ($schema->{type} =~ /^(blessed|object|isa\(\*\))$/) {
        goto invalid unless $blessed;
    } elsif ($schema->{type} eq "unblessed") {
        goto invalid if $blessed;
    } elsif ($schema->{type} eq "code") {
        goto invalid unless $reftype eq "CODE";
    } elsif ($schema->{type} eq "regexp") {
        goto invalid unless is_regexp($data);
    } elsif ($schema->{type} eq "list") {
        goto invalid unless $reftype eq "ARRAY";
        @errors = _validate_list($valid, $schema, $data);
    } elsif ($schema->{type} =~ /^list\((.+)\)$/) {
        goto invalid unless $reftype eq "ARRAY";
        %tmpschema = %{ $schema };
        $tmpschema{subtype} = { type => $1 };
        @errors = _validate_list($valid, \%tmpschema, $data);
    } elsif ($schema->{type} eq "table") {
        goto invalid unless $reftype eq "HASH";
        @errors = _validate_table($valid, $schema, $data);
    } elsif ($schema->{type} =~ /^table\((.+)\)$/) {
        goto invalid unless $reftype eq "HASH";
        %tmpschema = %{ $schema };
        $tmpschema{subtype} = { type => $1 };
        @errors = _validate_table($valid, \%tmpschema, $data);
    } elsif ($schema->{type} eq "struct") {
        goto invalid unless $reftype eq "HASH";
        @errors = _validate_struct($valid, $schema, $data);
    } elsif ($schema->{type} =~ /^ref\((.+)\)$/) {
        goto invalid unless $reftype eq $1;
    } elsif ($schema->{type} =~ /^isa\((.+)\)$/) {
        goto invalid unless $blessed and $data->isa($1);
    } else {
        return(sprintf("unexpected type: %s", $schema->{type}));
    }
    return() unless @errors;
  invalid:
    return(sprintf("invalid %s: %s", $schema->{type}, $data), \@errors);
}
## use critic

#
# validate something
#

sub _validate ($$$);
sub _validate ($$$) {
    my($valid, $schema, $data) = @_;
    my($type, @errors, $reftype, $blessed, %tmpschema);

    $type = $schema->{type};
    # check multiple types
    if (ref($type) eq "ARRAY") {
        return(_validate_multiple($valid, $schema, $data, @{ $type }));
    }
    # check list?(X)
    if ($type =~ /^list\?\((.+)\)$/) {
        return(_validate_multiple($valid, $schema, $data, $1, "list($1)"));
    }
    # check valid(X)
    if ($type =~ /^valid\((.+)\)$/) {
        return(sprintf("unexpected schema: %s", $1)) unless $valid->{$1};
        return(_validate($valid, $valid->{$1}, $data));
    }
    # check anything
    goto good if $type eq "anything";
    # check if defined
    if ($type =~ /^(undef|undefined)$/) {
        goto invalid if defined($data);
        goto good;
    }
    return(sprintf("invalid %s: <undef>", $type))
        unless defined($data);
    goto good if $type eq "defined";
    $reftype = reftype($data);
    if ($type =~ /^(string|boolean|number|integer)$/ or
        $type =~ /^(duration|size|hostname|ipv[46])$/) {
        # check reference type (for non-reference)
        goto invalid if defined($reftype);
        @errors = _validate_data_nonref($schema, $data);
    } else {
        # check reference type (for reference)
        goto invalid unless defined($reftype);
        goto good if $type =~ /^(reference|ref\(\*\))$/;
        @errors = _validate_data_ref($valid, $schema, $data, $reftype);
    }
    return(@errors) if @errors;
  good:
    @errors = $schema->{check}->($valid, $schema, $data) if $schema->{check};
    return() unless @errors;
  invalid:
    return(sprintf("invalid %s: %s", $type, $data), \@errors);
}

#+++############################################################################
#                                                                              #
# object oriented interface                                                    #
#                                                                              #
#---############################################################################

#
# create a validator object
#

sub new : method {
    my($class, $self, @errors);

    $class = shift(@_);
    $self = {};
    # find out which schema(s) to use
    if (@_ == 0) {
        $self->{schema} = $_BuiltIn;
    } elsif (@_ == 1) {
        $self->{schema}{""} = $_[0];
    } elsif (@_ % 2 == 0) {
        $self->{schema} = { @_ };
    } else {
        dief("new(): unexpected number of arguments: %d", scalar(@_));
    }
    # validate them
    {
            local $_Known = $self->{schema};
            @errors = _validate($_BuiltIn, { type => "table(valid(schema))" },
                            $self->{schema});
    }
    dief("new(): invalid schema: %s", _errfmt(@errors)) if @errors;
    # so far so good!
    bless($self, $class);
    return($self);
}

#
# convert to a list of options
#

sub options : method {
    my($self, $schema);

    $self = shift(@_);
    # find out which schema to convert to options
    if (@_ == 0) {
        dief("options(): no default schema")
            unless $self->{schema}{""};
        $schema = $self->{schema}{""};
    } elsif (@_ == 1) {
        $schema = shift(@_);
        dief("options(): unknown schema: %s", $schema)
            unless $self->{schema}{$schema};
        $schema = $self->{schema}{$schema};
    } else {
        dief("options(): unexpected number of arguments: %d", scalar(@_));
    }
    # convert to options
    return(_options($self->{schema}, $schema, undef));
}

#
# validate the given data
#

sub validate : method {
    my($self, $data, $schema, @errors);

    $self = shift(@_);
    # find out what to validate against
    if (@_ == 1) {
        $data = shift(@_);
        dief("validate(): no default schema")
            unless $self->{schema}{""};
        $schema = $self->{schema}{""};
    } elsif (@_ == 2) {
        $data = shift(@_);
        $schema = shift(@_);
        dief("validate(): unknown schema: %s", $schema)
            unless $self->{schema}{$schema};
        $schema = $self->{schema}{$schema};
    } else {
        dief("validate(): unexpected number of arguments: %d", scalar(@_));
    }
    # validate data
    {
        local $_Known = $self->{schema};
        @errors = _validate($self->{schema}, $schema, $data);
    }
    dief("validate(): %s", _errfmt(@errors)) if @errors;
}

#
# traverse the given data
#

sub traverse : method {
    my($self, $callback, $data, $schema);

    $self = shift(@_);
    # find out what to traverse
    if (@_ == 2) {
        $callback = shift(@_);
        $data = shift(@_);
        dief("traverse(): no default schema")
            unless $self->{schema}{""};
        $schema = $self->{schema}{""};
    } elsif (@_ == 3) {
        $callback = shift(@_);
        $data = shift(@_);
        $schema = shift(@_);
        dief("traverse(): unknown schema: %s", $schema)
            unless $self->{schema}{$schema};
        $schema = $self->{schema}{$schema};
    } else {
        dief("traverse(): unexpected number of arguments: %d", scalar(@_));
    }
    # traverse data
    _traverse($callback, $self->{schema}, $schema, undef, $data);
}

#
# export control
#

sub import : method {
    my($pkg, %exported);

    $pkg = shift(@_);
    foreach my $name (qw(string2hash hash2string treeify treeval
                         expand_duration expand_size
                         is_true is_false is_regexp listof
                         mutex reqall reqany)) {
        $exported{$name}++;
    }
    export_control(scalar(caller()), $pkg, \%exported, @_);
}

1;

__DATA__

=head1 NAME

Config::Validator - schema based configuration validation

=head1 SYNOPSIS

  use Config::Validator;

  # simple usage
  $validator = Config::Validator->new({ type => "list(integer)" });
  $validator->validate([ 1, 2 ]);   # OK
  $validator->validate([ 1, 2.3 ]); # FAIL
  $validator->validate({ 1, 2 });   # FAIL

  # advanced usage
  $validator = Config::Validator->new(
      octet => {
          type => "integer",
          min  => 0,
          max  => 255,
      },
      color => {
          type   => "struct",
          fields => {
              red   => { type => "valid(octet)" },
              green => { type => "valid(octet)" },
              blue  => { type => "valid(octet)" },
          },
      },
  );
  $validator->validate(
      { red => 23, green => 47,  blue => 6 }, "color"); # OK
  $validator->validate(
      { red => 23, green => 470, blue => 6 }, "color"); # FAIL
  $validator->validate(
      { red => 23, green => 47,  lbue => 6 }, "color"); # FAIL

=head1 DESCRIPTION

This module allows to perform schema based configuration validation.

The idea is to define in a schema what valid data is. This schema can be used
to create a validator object that can in turn be used to make sure that some
data indeed conforms to the schema.

Although the primary focus is on "configuration" (for instance as provided by
modules like L<Config::General>) and, to a lesser extent, "options" (for
instance as provided by modules like L<Getopt::Long>), this module can in fact
validate any data structure.

=head1 METHODS

The following methods are available:

=over

=item new([OPTIONS])

return a new Config::Validator object (class method)

=item options([NAME])

convert the named schema (or the default schema if the name is not given) to a
list of L<Getopt::Long> compatible options

=item validate(DATA[, NAME])

validate the given data using the named schema (or the default schema if the
name is not given)

=item traverse(CALLBACK, DATA[, NAME])

traverse the given data using the named schema (or the default schema if the
name is not given) and call the given CALLBACK on each node

=back

=head1 FUNCTIONS

The following convenient functions are available:

=over

=item is_true(SCALAR)

check if the given scalar is the boolean C<true>

=item is_false(SCALAR)

check if the given scalar is the boolean C<false>

=item is_regexp(SCALAR)

check if the given scalar is a compiled regular expression

=item expand_duration(STRING)

convert a string representing a duration (such as "1h10m12s") into the
corresponding number of seconds (such as "4212")

=item expand_size(STRING)

convert a string representing a size (such as "1.5kB") into the corresponding
integer (such as "1536")

=item listof(SCALAR)

return the given scalar as a list, dereferencing it if it is a list reference
(this is very useful with the C<list?(X)> type)

=item string2hash(STRING)

convert a string of space separated key=value pairs into a hash or hash
reference

=item hash2string(HASH)

convert a hash or hash reference into a string of space separated key=value
pairs

=item treeify(HASH)

modify (in place) a hash reference to turn it into a tree, using the dash
character to split keys

=item treeval(HASH, NAME)

return the value of the given option (e.g. C<foo-bar>) in a treeified hash

=item mutex(HASH, NAME...)

treat the given options as mutually exclusive

=item reqall(HASH, NAME1, NAME...)

if the first option is set, all the others are required

=item reqany(HASH, NAME1, NAME...)

if the first option is set, one at least of the others is required

=back

=head1 SCHEMAS

A schema is simply a structure (i.e. a hash reference) with the following
fields (all of them being optional except the first one):

=over

=item type

the type of the thing to validate (see the L</"TYPES"> section for the
complete list); this can also be a list of possible types (e.g. C<integer> or
C<undef>)

=item subtype

for an homogeneous list or table, the schema of its elements

=item fields

for a structure, a table of the allowed fields, in the form: field name =E<gt>
corresponding schema

=item optional

for a structure field, it indicates that the field is optional

=item min

the minimum length/size, only for some types (integer, number, string, list
and table)

=item max

the maximum length/size, only for some types (integer, number, string, list
and table)

=item match

a regular expression used to validate a string or table keys

=item check

a code reference allowing to run user-supplied code to further validate the
data

=back

As an example, the following schema describe what a valid schema is:

  {
    type   => "struct",
    fields => {
      type     => { type => "list?(valid(type))" },
      subtype  => { type => "valid(schema)",        optional => "true" },
      fields   => { type => "table(valid(schema))", optional => "true" },
      optional => { type => "boolean",              optional => "true" },
      min      => { type => "number",               optional => "true" },
      max      => { type => "number",               optional => "true" },
      match    => { type => "regexp",               optional => "true" },
      check    => { type => "code",                 optional => "true" },
    },
  }

=head1 NAMED SCHEMAS

For convenience and self-reference, schemas can be named.

To use named schemas, give them along with their names to the new() method:

  $validator = Config::Validator->new(
      name1 => { ... schema1 ... },
      name2 => { ... schema2 ... },
  );

You can then refer to them in the validate() method:

  $validator->validate($data, "name1");

If you don't need named schemas, you can use the simpler form:

  $validator = Config::Validator->new({ ... schema ... });
  $validator->validate($data);

=head1 TYPES

Here are the different types that can be used:

=over

=item anything

really anything, including undef

=item undef

the undefined value

=item undefined

synonym for C<undef>

=item defined

anything but undef

=item string

any string (in fact, anything that is defined and not a reference)

=item boolean

either C<true> or C<false>

=item number

any number (this is tested using a regular expression)

=item integer

any integer (this is tested using a regular expression)

=item duration

any duration (integers with optional time suffixes)

=item size

any size (integer with optional fractional part and optional byte-suffix)

=item hostname

any host name (as per RFC 1123)

=item ipv4

any IPv4 address (this is tested using a regular expression)

=item ipv6

any IPv6 address (this is tested using a regular expression)

=item reference

any reference, blessed or not

=item ref(*)

synonym for C<reference>

=item blessed

any blessed reference

=item object

synonym for C<blessed>

=item isa(*)

synonym for C<blessed>

=item unblessed

any reference which is not blessed

=item code

a code reference

=item regexp

a compiled regular expression

=item list

an homogeneous list

=item list(X)

idem but with the given subtype

=item list?(X)

shortcut for either C<X> or C<list(X)>

=item table

an homogeneous table

=item table(X)

idem but with the given subtype

=item struct

a structure, i.e. a table with known keys

=item ref(X)

a reference of the given kind

=item isa(X)

an object of the given kind

=item valid(X)

something valid according to the given named schema

=back

=head1 EXAMPLES

=head2 CONFIGURATION VALIDATION

This module works well with L<Config::General>. In particular, the C<list?(X)>
type matches the way L<Config::General> merges blocks.

For instance, one could use the following code:

  use Config::General qw(ParseConfig);
  use Config::Validator;
  $validator = Config::Validator->new(
    service => {
      type   => "struct",
      fields => {
        port  => { type => "integer", min => 0, max => 65535 },
        proto => { type => "string" },
      },
    },
    host => {
      type   => "struct",
      fields => {
        name    => { type => "string", match => qr/^\w+$/ },
        service => { type => "list?(valid(service))" },
      },
    },
  );
  %cfg = ParseConfig(-ConfigFile => $path, -CComments => 0);
  $validator->validate($cfg{host}, "host");

This would work with:

  <host>
    name = foo
    <service>
      port = 80
      proto = http
    </service>
  </host>

where C<$cfg{host}{service}> is the service hash but also with:

  <host>
    name = foo
    <service>
      port = 80
      proto = http
    </service>
    <service>
      port = 443
      proto = https
    </service>
  </host>

where C<$cfg{host}{service}> is the list of service hashes.

=head2 OPTIONS VALIDATION

This module interacts nicely with L<Getopt::Long>: the options() method can be
used to convert a schema into a list of L<Getopt::Long> options.

Here is a simple example:

  use Config::Validator;
  use Getopt::Long qw(GetOptions);
  use Pod::Usage qw(pod2usage);
  $validator = Config::Validator->new({
    type   => "struct",
    fields => {
      debug => {
        type     => "boolean",
        optional => "true",
      },
      proto => {
        type  => "string",
        match => qr/^\w+$/,
      },
      port => {
        type => "integer",
        min  => 0,
        max  => 65535,
      },
    },
  });
  @options = $validator->options();
  GetOptions(\%cfg, @options) or pod2usage(2);
  $validator->validate(\%cfg);

=head2 ADVANCED VALIDATION

This module can also be used to combine configuration and options validation
using the same schema. The idea is to:

=over

=item *

define a unique schema validating both configuration and options

=item *

parse the command line options using L<Getopt::Long> (first pass, to detect a
C<--config> option)

=item *

read the configuration file using L<Config::General>

=item *

parse again the command line options, using the configuration data as default
values

=item *

validate the merged configuration/options data

=back

In some situations, it may make sense to consider the configuration data as a
tree and prefer:

  <incoming>
    uri = foo://host1:1234
  </incoming>
  <outgoing>
    uri = foo://host2:2345
  </outgoing>

to:

  incoming-uri = foo://host1:1234
  outgoing-uri = foo://host2:2345

The options() method flatten the schema to get a list of command line options
and the treeify() function transform flat options (as returned by
L<Getopt::Long>) into a deep tree so that it matches the schema.  Then the
treeval() function can conveniently access the value of an option.

See the bundled examples for complete working programs illustrating some of
the possibilities of this module.

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2012-2015
