# -*- Mode: Perl; indent-tabs-mode: nil -*-

=pod

=head1 NAME

Data::Properties - persistent properties

=head1 SYNOPSIS

  my $props = Data::Properties->new();

  open FH, "./my.properties" or
      die "can't open my.properties: $!\n";
  $props->load(\*FH);
  close FH;

  for my $name ($props->property_names()) {
      my $val = $props->get_property($name);
  }

  $props->set_property("foo", "bar");

  open FH, "> ./new.properties" or
      die "can't open new.properties: $!\n";
  $props->store(\*FH);
  close FH;

=head1 DESCRIPTION

This class is a Perl version of Java's B<java.util.Properties> and
aims to be format-compatible with that class.

The B<Properties> class represents a persistent set of properties. The
B<Properties> can be saved to a filehandle or loaded from a
filehandle. Each key and its corresponding value in the property list
is a string.

A property list can contain another property list as its "defaults";
this second property list is searched if the property key is not found
in the original property ist.

B<Properties> does no type checking on the keys or values stored with
C<set_property()>. Keys and values are stored as strings via
C<sprintf()>, so you almost always want to use simple keys and values,
not arrays, or hashes, or references. Keys and values are loaded and
stored "as-is"; no character or other conversions are performed on
them.

=cut

package Data::Properties;

$VERSION = '0.02';

use strict;
use POSIX ();

=pod

=head1 CONSTRUCTOR

=over

=item new([$defaults])

Creates an empty property list, optionally with the specified
defaults.

Dies if C<$defaults> is not a B<Properties> object.

=back

=cut

sub new {
    my ($type, $defaults) = @_;
    my $class = ref($type) || $type;

    if ($defaults && !UNIVERSAL::isa($defaults, __PACKAGE__)) {
        die sprintf("Specified defaults object does not inherit from %s\n",
                    __PACKAGE__);
    }

    my $self = {
                _props => {},
                _defaults => $defaults,
                _lastkey => undef,
               };

    return bless $self, $class;
}

=pod

=head1 METHODS

=over

=item get_property($key, [$default_value])

Searches for the property with the specified key in this property
list. If the key is not found in this property list, the default
property list and its defaults are recursively checked. If the
property is not found, C<$default_value> is returned if specified, or
C<undef> otherwise.

=cut

sub get_property {
    my ($self, $key, $default_value) = @_;
    $default_value ||= "";

    return $default_value unless $key;
    return $self->{_props}->{$key} if $self->{_props}->{$key};

    return $default_value unless $self->{_defaults};
    return $self->{_defaults}->get_property($key);
}

=pod

=item load($handle)

Reads a property list from the specified input handle.

Every property occupies one line read from the input handle. Lines
from the input handle are processed until EOF is reached.

A line that contains only whitespace or whose first non-whitespace
character is an ASCII C<#> or C<!> is ignored (thus, these characters
indicate comment lines).

Every line other than a blank line or a comment line describes one
property to be added to the property list (except that if a line ends
with C<\>, then the following line, if it exists, is treated as a
continuation line, as described below). The key consists of all the
characters in the line starting with the first non-whitespace
character and up to, but not including, the first ASCII C<=>, C<:>, or
whitespace character. Any whitespace after the key is skipped; if the
first non-whitespace character after the key is C<=> or C<:>, then it
is ignored and any whitespace characters after it are also
skipped. All remaining characters on th eline become part of the
associated value. If the last character on the line is C<\>, then the
next line is treated as a continuation of the current line; the C<\>
and line terminator are simply discarded, and any leading whitespace
characters on the continuation line are also discarded and not part of
the element string.

As an example, each of the following lines specifies the key C<"Truth">
and the associated element value C<"Beauty">:

  Truth = Beauty
        Truth:Beauty
  Truth                        :Beauty

As another example, the following three lines specify a single
property:

  fruits                        apple, banana, pear, \
                                cantaloupe, watermelon, \
                                kiwi, mango

The key is C<"fruits"> and the associated element is C<"apple, banana,
pear, cantaloupe, watermelon, kiwi, mango">.

Note that a space appears before each C<\> so that a space will appear
after each comma in the final value; the C<\>, line terminator, and
leading whitespace on the continuation line are merely discarded and
are C<not> replaced by one or more characters.

As a third example, the line:

  cheeses:

specifies that the key is C<"cheeses"> and the associated element is
the empty string.

Dies if an error occurs when reading from the input handle.

=cut

sub load {
    my ($self, $in) = @_;
    return undef unless $in;

    my ($key, $val, $is_continuation, $is_continued);
    local $_;
    while (defined($_ = <$in>)) {
        next if /^[#!]/; # leading # or ! signifies comment
        next if /^\s+$/;  # all-whitespace

        chomp;

        if ($is_continuation) {
            # don't attempt to parse a key on a continuation line
            s/^\s*//;
            undef $key;
        } else {
            # regular line - parse out the key
            s/^\s*([^=:\s]+)\s*[=:\s]\s*//;
            $key = $1;
        }

        $is_continued = s/\\$// ? 1 : undef;
        $val = $_;

        if ($is_continuation) {
            # append the continuation value to the value of the
            # last key
            $self->{_props}->{$self->{_lastkey}} .= $val;
        } elsif ($key) {
            $self->{_props}->{$key} = $val;
        } else {
            warn "Malformed property line: $_\n";
        }

        if ($is_continued) {
            $is_continuation = 1;
            # allow for continuation lines being continued
            $self->{_lastkey} = $key if defined $key;
        } else {
            undef $is_continuation;
            undef $self->{_lastkey};
        }
   }

    return 1;
}

=pod

=item property_names

Returns an array (or an arrayref in scalar context) containing all of
the keys in this property list, including the keys in the default
property list.

=cut

sub property_names {
    my ($self) = @_;

    my @names = keys %{$self->{_props}};
    push @names, $self->{_defaults}->property_names() if $self->{_defaults};

    return wantarray ? @names : \@names;
}

=pod

=item set_property($key, $value)

Sets the property with the specified key.

=cut

sub set_property {
    my ($self, $key, $value) = @_;
    return undef unless $key;

    $self->{_props}->{$key} = $value;

    return 1;
}

=pod

=item store($handle, $header)

Writes this property list to the specified output handle. Default
properties are I<not> written by this method.

If a header is specified, then the ASCII characters C<# >, the header
string, and a line separator are first written to the output
handle. Thus the header can serve as an identifying comment.

Next, a comment line is always written, consisting of the ASCII
characters C<# >, the current date and time (as produced by
C<POSIX::ctime()>), and a line separator.

Then every entry in the property list is written out, one per
line. For each entry the key string is written, then an ASCII C<=>,
then the associated value.

The output handle remains open after this method returns.

Dies if an error occurs when writing to the input handle.

=cut

sub store {
    my ($self, $out, $header) = @_;
    return undef unless $out;

    local $| = 1;

    print $out "# $header\n",  if $header;
    print $out "# ", POSIX::ctime(time), "\n";

    for my $k (sort keys %{$self->{_props}}) {
        print $out sprintf("%s=%s\n", $k, $self->{_props}->{$k});
    }

    return 1;
}

1;
__END__

=pod

=back

=head1 TODO

=over

=item o

Read and write escaped characters in property keys and values.

In values only, the ASCII characters backslash, tab, newline, carriage
return, double quote, and single quote should be stored as the literal
strings C<\\>, C<\t>, C<\n>, C<\r>, C<\">, and C<\'> respectively, and
those literal strings should be converted into the corresponding ASCII
characters when loading properties. The same goes for leading spaces
(converted into C<\ >), but not embedded or trailing spaces.

In keys and values, the ASCII characters C<#>, C<!>, C<=>, and C<:>
should be stored with a preceding C<\>, and those literal strings
should be unescaped when loading properties.

=back

=head1 ISSUES

=over

=item o

What happens when non-ASCII characters are used?
B<java.util.Properties> uses ISO-8859-1 and allows for Unicode escape
sequences.

=head1 SEE ALSO

B<POSIX>

B<java.util.Properties>,
http://java.sun.com/j2se/1.3/docs/api/index.html

=back

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut

