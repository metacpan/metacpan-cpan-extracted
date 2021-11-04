#+##############################################################################
#                                                                              #
# File: Config/Generator/Util.pm                                               #
#                                                                              #
# Description: miscellaneous utilities for Config::Generator                   #
#                                                                              #
#-##############################################################################

#
# module definition
#

package Config::Generator::Util;
use strict;
use warnings;
our $VERSION  = "1.1";
our $REVISION = sprintf("%d.%02d", q$Revision: 1.13 $ =~ /(\d+)\.(\d+)/);

#
# used modules
#

use No::Worries::Die qw(dief);
use No::Worries::Export qw(export_control);
use Params::Validate qw(validate_pos :types);

#
# constants
#

use constant KB => 1024;
use constant MB => 1024 * KB;
use constant GB => 1024 * MB;

#
# format a profile file (shell exports)
#

sub format_profile (@) {
    my(@list) = validate_pos(@_, ({ type => SCALAR }) x (@_ || 2));
    my($name, $value, $contents);

    dief("invalid invocation!") if @list % 2;
    $contents = "";
    while (@list) {
        $name = shift(@list);
        $value = shift(@list);
        if ($name eq "#") {
            if (length($value)) {
                $contents .= "# $value\n";
            } else {
                $contents .= "#\n";
            }
        } else {
            $contents .= "export $name=\"$value\"\n";
        }
    }
    return($contents);
}

#
# return a list of things (handy with Config::General's list representation)
#

my @list_of_options = (
    { type => UNDEF | SCALAR | ARRAYREF },
);

sub list_of ($) {
    my($list) = validate_pos(@_, @list_of_options);

    return() unless defined($list);
    return($list) unless ref($list) eq "ARRAY";
    return(@{ $list });
}

#
# export control
#

sub import : method {
    my($pkg, %exported);

    $pkg = shift(@_);
    grep($exported{$_}++, qw(KB MB GB format_profile list_of));
    export_control(scalar(caller()), $pkg, \%exported, @_);
}

1;

__DATA__

=head1 NAME

Config::Generator::Util - miscellaneous utilities for Config::Generator

=head1 DESCRIPTION

This module provides miscellaneous utilities for Config::Generator.

=head1 FUNCTIONS

This module provides the following functions (none of them being exported by
default):

=over

=item format_profile(NAME => VALUE, ...)

return a string representing the given shell profile (i.e. key/value pairs);
this is useful to create a configuration file with shell syntax; the key can
also be "#" to represent a comment

=item list_of(SOMETHING)

return a list of things depending on what has been given (undef, an array
reference or a scalar); this is very useful with L<Config::General>'s list
representation

=back

=head1 CONSTANTS

This module provides the following constants (none of them being exported by
default) with obvious values: C<KB>, C<MB> and C<GB>.

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2013-2016
