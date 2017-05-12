# ConfigReader/DirectiveStyle.pm: Reads a configuration file of
#   directives and values.
#
# Copyright 1996 by Andrew Wilcox <awilcox@world.std.com>.
# All rights reserved.
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Library General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.
#
# You should have received a copy of the GNU Library General Public
# License along with this library; if not, write to the Free
# Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

package ConfigReader::DirectiveStyle;
$VERSION = "0.5";
require ConfigReader::Values;
@ISA = qw(ConfigReader::Values);

my $Tainted_empty_string = substr($0, 0, 0);

use Carp;
use strict;

=head1 NAME

ConfigReader::DirectiveStyle

Reads a configuration file of directives and values.

=head1 CONFIGURATION FILE SYNOPSIS

    # comments start with a #, and blank lines are ignored
    
    Input     /etc/data_source      # the value follows the directive name
    HomePage  http://www.w3.org/
    
    # values can be quoted
    Comment   "here is a value with trailing spaces   "

=head1 CODE SYNOPSIS

    my $c = new ConfigReader::DirectiveStyle;
    
    directive $c 'Input', undef, '~/input';  # specify default value,
                                             #   but no parsing needed
    required  $c 'HomePage', 'new URI::URL'; # create URI::URL object
    ignore    $c 'Comment';                  # Ignore this directive.
    
    
    $c->load('my.config');
    open(IN, $c->value("Input"));
    
    $c->define_accessors();                  # creates Input() and HomePage()
    retrieve(HomePage());

=head1 DESCRIPTION

This class reads a common style of configuration files, where
directive names are followed by a value.  For each directive you can
specify whether it has a default value or is required, and a function
or method to use to parse the value.  Errors and warnings are caught
while parsing, and the location where the offending value came from
(either from the configuration file, or your Perl source for default
values) is reported.

DirectiveStyle is a subclass of L<ConfigReader::Values>.  The methods to
define the directives in the configuration file are documented there.

Comments are introduced by the "#" character, and continue until the
end of line.  Like in Perl, the backslash character "\" may be used in
the directive values for the various standard sequences:

     \t          tab
     \n          newline
     \r          return
     \f          form feed
     \v          vertical tab, whatever that is
     \b          backspace
     \a          alarm (bell)
     \e          escape
     \033        octal char
     \x1b        hex char

The value may also be quoted, which lets you include leading or
trailing spaces.  The quotes are stripped off before the value is
returned.

DirectiveStyle itself only reads the configuration file.  Most of the
hard work of defining the directives and parsing the values is done in
its superclass, ConfigReader::Values.  You should be able to easily
modify or subclass DirectiveStyle to read a different style of
configuration file.

=head1 PUBLIC METHODS

=head2 C<new( [$spec] )>

This static method creates and returns a new DirectiveStyle object.
For information about the optional $spec argument, see
DirectiveStyle::new().


=head2 C<load($file, [$untaint])>

Before calling load(), you'll want to define the directives using the
methods described in ConfigReader::Values.

Reads a configuration from $file.  The default values for any
directives not present in the file are assigned.

Normally configuration values are tainted like any data read from a
file.  If the configuration file comes from a trusted source, you can
untaint all the values by setting the optional $untaint argument to a
true value (such as C<'UNTAINT'>).

=cut

sub load {
    my ($self, $file, $untaint) = @_;
    my ($whence, $directive, $value);
    local $/ = "\n";
    local ($_, $., $!);

    open(IN, $file)
        or croak "Could not open configuration file '$file' for reading: $!";
    while (<IN>) {
        chomp;
        $whence = "in line $. of the configuration file '$file':\n> $_\n";
        ($directive, $value) = $self->parse_line($_, $whence, $untaint);
        $self->assign($directive, $value, $whence) if defined $directive;
    }
    close(IN);

    $self->assign_defaults("in the configuration file '$file'");
}


=head1 SUBCLASSABLE METHODS

You can stop reading here if you just want to use DirectiveStyle.  The
following methods could be overridden in a subclass to provide
additional or alternate functionality.

=head2 C<parse_line($line, $whence, $untaint)>

Parses $line.  $whence is a string describing the source of the line.
Returns a two-element array of the directive and the value string, or
the empty array () if the line is blank or only contains a comment.

=cut

sub parse_line {
    my ($self, $line, $whence, $untaint) = @_;
    my ($directive, $rest);

    return () if $line =~ m/^ [\s\cZ]* $/x;
    return () if $line =~ m/^ [\s\cZ]* \# /x;

    ($directive, $rest) = ($line =~ m/^ [\s\cZ]* ([\w\-]+) [\s\cZ]* (.*)/x)
        or die "Syntax error in directive name $whence";

    my $value = $self->parse_value_string($rest, $whence);

    if ($untaint) {
        $value =~ m/(.*)/;
        return ($directive, $1);
    }
    else {
        # ensure that it is tainted, even after regex matching
        return ($directive, $value . $Tainted_empty_string);
    }
}

=head2 C<parse_value_string($str, $whence)>

Interprets quotes, backslashes, and comments in the value part.  (Note
that after the value string is returned, it will still get passed to
the directive's parsing function of method if one is defined).

=cut

# Just taking it step by step.

sub parse_value_string {
    my ($self, $str, $whence) = @_;
    my ($value, $p);

    $str =~ s,[\s\cZ]+$,,;      # trim trailing whitespace
    $value = '';

    # string quoted with double quote
    if ($str =~ m/^ \" /gx) {
        # parse through, looking for \, #, and closing "
        for (;;) {
            $p = pos($str);
            # pick up everything until next \ or "
            if ($str =~ m/\G ([^\\\"]+) /gx) {
                $value .= $1;
                next;
            }

            pos($str) = $p;     # reset search, since last match failed
            # looking at \
            if ($str =~ m/\G \\ /gx) {
                $value .= $self->match_backslash(\$str);
                next;
            }

            pos($str) = $p;
            # looking at "
            if ($str =~ m/\G \" /gx) {
                # got closing quote, so only thing left should be a comment
                # if any.  m/\G$/ doesn't match, so check position manually
                pos($str) < length($str)
                    and $str !~ m/\G (\s* \# .*)? $/gx
                    and die "Extra characters after closing quote $whence";
                last;
            }

            die "No closing quote $whence";
        }
    }

    # ditto, but for single quote
    elsif ($str =~ m/^ \' /gx) {
        for (;;) {
            $p = pos($str);
            if ($str =~ m/\G ([^\\\']+) /gx) {
                $value .= $1;
                next;
            }

            pos($str) = $p;
            if ($str =~ m/\G \\ /gx) {
                $value .= $self->match_backslash(\$str);
                next;
            }

            pos($str) = $p;
            if ($str =~ m/\G \' /gx) {
                pos($str) < length($str)
                    and $str !~ m/\G (\s* \# .*)? $/gx
                    and die "Extra characters after closing quote $whence";
                last;
            }

            die "No closing quote $whence";
        }
    }

    # ok, not quoted
    else {
        for (;;) {
            $p = pos($str);
            # pick up everything up to \ or comment #
            if ($str =~ m/\G ([^\\\#]+) /gx) {
                $value .= $1;
                next;
            }

            pos($str) = $p;
            if ($str =~ m/\G \\ /gx) {
                $value .= $self->match_backslash(\$str);
                next;
            }

            # either end of string or comment
            last;
        }
        # trim trailing whitespace
        $value =~ s,[\s\cZ]+$,,;
    }

    return $value;
}

sub match_backslash {
    my ($self, $str_ref) = @_;

    my $p = pos($$str_ref);
    if ($$str_ref =~ m/\G ((?:\d\d\d) | (?:x\w\w) | (?:[A-Za-z])) /gx) {
        # untainted and considered safe
        return eval '"\\' . $1 . '"';
    }

    # return next character verbatim, bumping match position
    pos($$str_ref) = $p;
    $$str_ref =~ m/\G (.)/gx;
    return $1;
}

1;
