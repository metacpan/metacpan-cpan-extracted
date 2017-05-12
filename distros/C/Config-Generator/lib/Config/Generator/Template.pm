#+##############################################################################
#                                                                              #
# File: Config/Generator/Template.pm                                           #
#                                                                              #
# Description: Config::Generator template support                              #
#                                                                              #
#-##############################################################################

#
# module definition
#

package Config::Generator::Template;
use strict;
use warnings;
our $VERSION  = "1.0";
our $REVISION = sprintf("%d.%02d", q$Revision: 1.17 $ =~ /(\d+)\.(\d+)/);

#
# used modules
#

use Config::Validator qw(is_true is_false);
use No::Worries::Die qw(dief);
use No::Worries::Export qw(export_control);
use No::Worries::File qw(file_read);
use Params::Validate qw(validate_pos :types);
use Config::Generator qw(%Config $HomeDir @IncPath);
use Config::Generator::Schema qw(*);

#
# constants
#

use constant OPEN_TOKEN  => "<{";
use constant CLOSE_TOKEN => "}>";

#
# global variables
#

our(%_RE, %_Registered);

$_RE{ALNUM} = "[a-zA-Z0-9]+";
$_RE{NAME}  = "(?:$_RE{ALNUM}\[\\-\\_\\.\])*$_RE{ALNUM}";
$_RE{PATH}  = "/?(?:$_RE{NAME}/)*$_RE{NAME}";
$_RE{TOKEN} = quotemeta(OPEN_TOKEN) . "|" . quotemeta(CLOSE_TOKEN);

#
# tokenize a string
#

sub _tokenize ($) {
    my($string) = @_;
    my($state, @list);

    $state = 1;
    foreach my $token (split(/($_RE{TOKEN})/o, $string)) {
        if ($state == 1) {
            if ($token eq OPEN_TOKEN) {
                $state = 2;
            } elsif ($token eq CLOSE_TOKEN) {
                dief("unexpected %s: not after a %s", CLOSE_TOKEN, OPEN_TOKEN);
            } else {
                push(@list, $token);
            }
        } elsif ($state == 2) {
            if ($token eq OPEN_TOKEN or $token eq CLOSE_TOKEN) {
                dief("unexpected %s: after a %s", $token, OPEN_TOKEN);
            } elsif ($token =~ /^($_RE{PATH})$/o) {
                push(@list, [ "", $1 ]);
                $state = 3;
            } elsif ($token =~ /^($_RE{NAME})\(\)$/o) {
                push(@list, [ $1 ]);
                $state = 3;
            } elsif ($token =~ /^($_RE{NAME})\(($_RE{PATH})\)$/o) {
                push(@list, [ $1, $2 ]);
                $state = 3;
            } else {
                dief("invalid syntax: %s%s", OPEN_TOKEN, $token);
            }
        } elsif ($state == 3) {
            if ($token eq CLOSE_TOKEN) {
                $state = 1;
            } else {
                dief("unexpected %s: after a %s", $token, OPEN_TOKEN);
            }
        } else {
            dief("unexpected state: %s", $state);
        }
    }
    return(@list);
}

#
# lookup a path in a list of hashes
#

sub _lookup ($@) {
    my($path, @list) = @_;
    my(@names, $name);

    @names = grep(length($_), split(/\//, $path));
    while (@names > 1) {
        $name = shift(@names);
        @list = grep(ref($_) eq "HASH", map($_->{$name}, @list));
        return() unless @list;
    }
    $name = shift(@names);
    @list = grep(defined($_) && ref($_) eq "", map($_->{$name}, @list));
    return() unless @list;
    return($list[0]);
}

#
# locate an ending conditional token
#

sub _locate ($$) {
    my($name, $list) = @_;
    my($index);

    $index = 0;
    foreach my $token (@{ $list }) {
        return($index)
            if ref($token) and $token->[0] eq "endif" and $token->[1] eq $name;
        $index++;
    }
    dief("no matching %sendif(%s)%s found", OPEN_TOKEN, $name, CLOSE_TOKEN);
}

#
# process a template string (private)
#

sub _process ($@);
sub _process ($@) {
    my($string, @hashes) = @_;
    my($result, @list, $token, $value, $index, $match);

    $result = "";
    @list = _tokenize($string);
    while (@list) {
        $token = shift(@list);
        unless (ref($token)) {
            $result .= $token;
            next;
        }
        unless (defined($token->[1])) {
            if ($token->[0] eq "open") {
                $result .= OPEN_TOKEN;
            } elsif ($token->[0] eq "close") {
                $result .= CLOSE_TOKEN;
            } else {
                dief("unexpected operator: %s", $token->[0]);
            }
            next;
        }
        $value = _lookup($token->[1], @hashes);
        if ($token->[0] =~ /^(if|ifnot|if_(true|false))?$/) {
            # these macros need an existing path...
            dief("unknown path: %s", $token->[1]) unless defined($value);
        }
        if ($token->[0] eq "") {
            $result .= _process($value, @hashes);
            next;
        }
        if ($token->[0] eq "endif") {
            dief("unexpected %sendif(%s)%s",
                 OPEN_TOKEN, $token->[1], CLOSE_TOKEN);
        }
        $index = _locate($token->[1], \@list);
        if ($token->[0] eq "if") {
            $match = $value;
        } elsif ($token->[0] eq "ifnot") {
            $match = not $value;
        } elsif ($token->[0] eq "if_true") {
            $match = is_true($value);
        } elsif ($token->[0] eq "if_false") {
            $match = is_false($value);
        } elsif ($token->[0] eq "ifdef") {
            $match = defined($value);
        } elsif ($token->[0] eq "ifndef") {
            $match = not defined($value);
        } else {
            dief("unexpected operator: %s", $token->[0]);
        }
        if ($match) {
            splice(@list, $index, 1);
        } else {
            splice(@list, 0, $index + 1);
        }
    }
    return($result);
}

#
# declare one or more template names
#

sub declare_template (@) {
    my(@names) = validate_pos(@_, ({ type => SCALAR }) x (@_ || 1));

    foreach my $name (@names) {
        dief("duplicate template declared: %s", $name)
            if $_Registered{$name};
        $_Registered{$name} = OPT_STRING;
    }
}

#
# expand a template (given its name)
#

sub expand_template ($%) {
    my($name, %hash) = @_;

    return(_process(read_template($name), \%hash, \%Config));
}

#
# process a template string (public)
#

my @process_template_options = (
    { type => SCALAR },
);

sub process_template ($@) {
    my($string, @hashes) = validate_pos(@_, @process_template_options,
        ({ type => HASHREF }) x (@_ - 1),
    );

    return(_process($string, @hashes));
}

#
# read a template file (given its name)
#

sub read_template ($) {
    my($name) = @_;
    my($path, $contents);

    $name = $Config{Template}{$name} || "$name.tpl";
    if ($name =~ /\n/) {
        # inline
        $contents = $name;
    } else {
        # from file
        foreach my $inc (@IncPath, "$HomeDir/tpl") {
            next unless -e "$inc/$name";
            $path = "$inc/$name";
            last;
        }
        dief("missing template file: %s", $name) unless $path;
        $contents = file_read($path);
    }
    # remove trailing spaces and make it is newline terminated (unless empty)
    $contents =~ s/\s*$/\n/s if length($contents);
    return($contents);
}

#
# define the Template schema
#

register_schema("/Template", { type => "struct", fields => \%_Registered });

#
# export control
#

sub import : method {
    my($pkg, %exported);

    $pkg = shift(@_);
    grep($exported{"${_}_template"}++, qw(declare expand process read));
    export_control(scalar(caller()), $pkg, \%exported, @_);
}

1;

__DATA__

=head1 NAME

Config::Generator::Template - Config::Generator template support

=head1 DESCRIPTION

This module eases configuration file generation by providing template support.
A template is a file with markup. Given a high-level configuration, the
template can be processed and transformed into a low-level configuration file.

=head1 SYNTAX

The template commands are enclosed within "<{" and "}>". If I<PATH> represents
a path in the high-level configuration:

=over

=item * "<{PATH}>" will be replaced by the value of I<PATH>

=item * "<{open()}>" will be replaced by "<{"

=item * "<{close()}>" will be replaced by "}>"

=item * "<{if(PATH)}>xxx<{endif(PATH)}>" will be replaced by "xxx" if PATH is
true or "" otherwise (this is done using Perl's conditional testing)

=item * "<{ifnot(PATH)}>xxx<{endif(PATH)}>" is the same as "if()" but negated

=item * "<{if_true(PATH)}>xxx<{endif(PATH)}>" is the same as "if()" but tested
using L<Config::Validator>'s is_true()

=item * "<{if_false(PATH)}>xxx<{endif(PATH)}>" is the same as "if()" but
tested using L<Config::Validator>'s is_false()

=item * "<{ifdef(PATH)}>xxx<{endif(PATH)}>" will be replaced by "xxx" if PATH
is defined (i.e. set) or "" otherwise

=item * "<{ifndef(PATH)}>xxx<{endif(PATH)}>" is the same as "ifdef()" but
negated

=back

=head1 FUNCTIONS

This module provides the following functions (none of them being exported by
default):

=over

=item declare_template(NAME...)

declare one or more template names so that they can be customized using the
C</Template> schema

=item expand_template(NAME[, HASH])

read and process the named template, using the given hash as well as the
high-level configuration

=item process_template(TEMPLATE, HASH...)

process the given template string using the given hashes

=item read_template(NAME)

return the contents of the named template (unprocessed)

=back

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2013-2016
