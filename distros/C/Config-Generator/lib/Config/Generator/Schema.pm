#+##############################################################################
#                                                                              #
# File: Config/Generator/Schema.pm                                             #
#                                                                              #
# Description: Config::Generator schema support                                #
#                                                                              #
#-##############################################################################

#
# module definition
#

package Config::Generator::Schema;
use strict;
use warnings;
our $VERSION  = "1.0";
our $REVISION = sprintf("%d.%02d", q$Revision: 1.29 $ =~ /(\d+)\.(\d+)/);

#
# used modules
#

use Config::Validator qw();
use No::Worries::Die qw(dief);
use No::Worries::Export qw(export_control);
use No::Worries::Log qw(log_debug);
use Params::Validate qw(validate_pos :types);
use Config::Generator qw(%Config);

#
# constants
#

use constant _BOOLEAN => { type => "boolean" };
use constant OPT_BOOLEAN => { optional => "true",  %{ _BOOLEAN() } };
use constant DEF_BOOLEAN => { optional => "incfg", %{ _BOOLEAN() } };
use constant REQ_BOOLEAN => { optional => "false", %{ _BOOLEAN() } };

use constant _DURATION => { type => "duration" };
use constant OPT_DURATION => { optional => "true",  %{ _DURATION() } };
use constant DEF_DURATION => { optional => "incfg", %{ _DURATION() } };
use constant REQ_DURATION => { optional => "false", %{ _DURATION() } };

use constant _HOSTNAME => { type => "hostname" };
use constant OPT_HOSTNAME => { optional => "true",  %{ _HOSTNAME() } };
use constant DEF_HOSTNAME => { optional => "incfg", %{ _HOSTNAME() } };
use constant REQ_HOSTNAME => { optional => "false", %{ _HOSTNAME() } };

use constant _INTEGER => { type => "integer" };
use constant OPT_INTEGER => { optional => "true",  %{ _INTEGER() } };
use constant DEF_INTEGER => { optional => "incfg", %{ _INTEGER() } };
use constant REQ_INTEGER => { optional => "false", %{ _INTEGER() } };

use constant _NAME => {
    type  => "string",
    match => qr/^[\w\-\.]+$/,
};
use constant OPT_NAME => { optional => "true",  %{ _NAME() } };
use constant DEF_NAME => { optional => "incfg", %{ _NAME() } };
use constant REQ_NAME => { optional => "false", %{ _NAME() } };

use constant _NUMBER => { type => "number" };
use constant OPT_NUMBER => { optional => "true",  %{ _NUMBER() } };
use constant DEF_NUMBER => { optional => "incfg", %{ _NUMBER() } };
use constant REQ_NUMBER => { optional => "false", %{ _NUMBER() } };

use constant _PATH => {
    type  => "string",
    match => qr/^(\/[\w\-\.]+)+\/?$/,
};
use constant OPT_PATH => { optional => "true",  %{ _PATH() } };
use constant DEF_PATH => { optional => "incfg", %{ _PATH() } };
use constant REQ_PATH => { optional => "false", %{ _PATH() } };

use constant _SIZE => { type => "size" };
use constant OPT_SIZE => { optional => "true",  %{ _SIZE() } };
use constant DEF_SIZE => { optional => "incfg", %{ _SIZE() } };
use constant REQ_SIZE => { optional => "false", %{ _SIZE() } };

use constant _STRING => { type => "string" };
use constant OPT_STRING => { optional => "true",  %{ _STRING() } };
use constant DEF_STRING => { optional => "incfg", %{ _STRING() } };
use constant REQ_STRING => { optional => "false", %{ _STRING() } };

use constant OPT_STRING_LIST => {
    type => "list?(string)",
    optional => "true",
};

use constant OPT_STRING_TABLE => {
    type => "table(string)",
    optional => "true",
};

#
# global variables
#

our(%_Registered, %_Mandatory);

#
# replace the "incfg" string in the optional values of the given schema
#

sub _incfg ($%);
sub _incfg ($%) {
    my($incfg, %old) = @_;
    my(%new);

    foreach my $key (keys(%old)) {
        if ($key eq "optional" and $old{$key} eq "incfg") {
            $new{$key} = $incfg;
        } elsif (ref($old{$key}) eq "HASH") {
            $new{$key} = { _incfg($incfg, %{$old{$key}}) };
        } else {
            $new{$key} = $old{$key};
        }
    }
    return(%new);
}

#
# return the collated schema to use for validation
#

sub _schema ($) {
    my($optional) = @_;
    my(%hash);

    %hash = _incfg($optional, %_Registered);
    $hash{root} = { type => "struct", fields => {} };
    # the root schema is a struct made of all the toplevel subtrees
    foreach my $key (keys(%_Registered)) {
        if ($key =~ /^\/(\w+)$/) {
            $hash{root}{fields}{$1} = {
                type => "valid($key)",
                optional => $_Mandatory{$key} ? $optional : "true",
            };
        }
    }
    return(%hash);
}

#
# extend a registered schema (i.e. add or overwrite struct fields)
#

my @extend_schema_options = (
    { type => SCALAR, regex => qr/^((\/\w+)+|\w+)$/ },
    { type => HASHREF },
);

sub extend_schema ($$) {
    my($name, $fields) = validate_pos(@_, @extend_schema_options);

    dief("unregistered schema: %s", $name)
        unless $_Registered{$name};
    dief("cannot extend %s: not a struct", $name)
        unless $_Registered{$name}{type} eq "struct";
    foreach my $field (keys(%{ $fields })) {
        $_Registered{$name}{fields}{$field} = $fields->{$field};
    }
}

#
# mark a toplevel subtree as being mandatory
#

my @mandatory_subtree_options = (
    { type => SCALAR, regex => qr/^\/\w+$/ },
);

sub mandatory_subtree ($) {
    my($name) = validate_pos(@_, @mandatory_subtree_options);

    $_Mandatory{$name}++;
}

#
# register a schema
#

my @register_schema_options = (
    $extend_schema_options[0],
    { type => HASHREF },
);

sub register_schema ($$) {
    my($name, $schema) = validate_pos(@_, @register_schema_options);

    $_Registered{$name} = $schema;
}

#
# validate the configuration in %Config
#

# very basic validation before any schema is even known!

sub validate_basic () {
    my($validator);

    log_debug("basic validation");
    $validator = Config::Validator->new(
        node => { type => [ "list?(string)", "table(valid(node))" ] },
    );
    $validator->validate(\%Config, "node");
}

# advanced validation before all the modules check() execution

sub validate_before () {
    my($validator);

    log_debug("advanced validation (before check)");
    $validator = Config::Validator->new(_schema("true"));
    $validator->validate(\%Config, "root");
}

# advanced validation after all the modules check() execution

sub validate_after () {
    my($validator);

    log_debug("advanced validation (after check)");
    $validator = Config::Validator->new(_schema("false"));
    $validator->validate(\%Config, "root");
}

# advanced validation of the given data

my @validate_data_options = (
    { type => HASHREF },
    $extend_schema_options[0],
);

sub validate_data ($$) {
    my($data, $name) = validate_pos(@_, @validate_data_options);
    my($validator);

    log_debug("data validation (%s)", $name);
    $validator = Config::Validator->new(_schema("false"));
    $validator->validate($data, $name);
}

#
# export control
#

sub import : method {
    my($pkg, %exported);

    $pkg = shift(@_);
    foreach my $optional (qw(OPT DEF REQ)) {
        foreach my $type (qw(BOOLEAN DURATION HOSTNAME INTEGER NAME NUMBER PATH
                             SIZE STRING)) {
            $exported{$optional . "_" . $type}++;
        }
    }
    grep($exported{$_}++, qw(OPT_STRING_LIST OPT_STRING_TABLE));
    grep($exported{$_}++, qw(extend_schema mandatory_subtree register_schema));
    grep($exported{"validate_${_}"}++, qw(basic before after data));
    export_control(scalar(caller()), $pkg, \%exported, @_);
}

1;

__DATA__

=head1 NAME

Config::Generator::Schema - Config::Generator schema support

=head1 DESCRIPTION

This module eases the manipulation of schemas used to validate the
configuration data.

=head1 FUNCTIONS

This module provides the following functions (none of them being exported by
default):

=over

=item extend_schema(NAME, SCHEMA)

extend the named schema

=item mandatory_subtree(NAME)

declare a part of the schema to be mandatory

=item register_schema(NAME, SCHEMA)

register the given SCHEMA under the given NAME

=item validate_basic()

perform a basic validation (before any schema is even known)

=item validate_before()

perform a schema-based validation (before the execution of the "check" hooks)

=item validate_after()

perform a schema-based validation (after the execution of the "check" hooks)

=item validate_data(DATA, NAME)

validate the given DATA using the given named schema

=back

=head1 CONSTANTS

This module provides the following useful constants to simplify schema
declarations (none of them being exported by default):

=over

=item * DEF_BOOLEAN

=item * DEF_DURATION

=item * DEF_HOSTNAME

=item * DEF_INTEGER

=item * DEF_NAME

=item * DEF_NUMBER

=item * DEF_PATH

=item * DEF_SIZE

=item * DEF_STRING

=item * OPT_BOOLEAN

=item * OPT_DURATION

=item * OPT_HOSTNAME

=item * OPT_INTEGER

=item * OPT_NAME

=item * OPT_NUMBER

=item * OPT_PATH

=item * OPT_SIZE

=item * OPT_STRING

=item * OPT_STRING_LIST

=item * OPT_STRING_TABLE

=item * REQ_BOOLEAN

=item * REQ_DURATION

=item * REQ_HOSTNAME

=item * REQ_INTEGER

=item * REQ_NAME

=item * REQ_NUMBER

=item * REQ_PATH

=item * REQ_SIZE

=item * REQ_STRING

=back

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2013-2016
