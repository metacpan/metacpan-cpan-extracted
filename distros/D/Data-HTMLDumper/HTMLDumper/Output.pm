package Data::HTMLDumper::Output;
use strict; use warnings;

our $VERSION = '0.01';

sub new {
    my $class = shift;
    my $unused;
    return bless \$unused, $class;
}

sub output {
    my $self = shift;
    my $array = shift;

    local $" = "";
    return "@$array";
}

sub expression {
    my $self = shift;
    my %item = @_;

    return "<table border='1'>$item{item}</table>\n";
}

sub item_value {
    my $self       = shift;
    my $item       = shift;
    my $hash_value = shift;

    if (defined $hash_value) { return "<tr><td>$item</td></tr>\n"; }
    else                     { return     "<td>$item</td>\n";      }
}

sub item_array {
    my $self       = shift;
    my $array_text = shift;

    return $array_text;
}

sub item_hash {
    my $self      = shift;
    my $hash_text = shift;

    return $hash_text;
}

sub item_object {
    my $self        = shift;
    my $object_text = shift;

    return $object_text;
}

sub item_inside_out_object {
    my $self    = shift;
    my $do_text = shift;

    return $do_text;
}

sub array {
    my $self  = shift;
    my $array = shift;

    local $" = "";
    return "<tr>@$array</tr>";
}

sub array_empty {
    return "<tr><td>NO_ELEMENTS</td></tr>";
}

sub hash {
    my $self  = shift;
    my $pairs = shift;

    local $" = "";
    return "@$pairs\n";
}

sub hash_empty {
    return "<tr><td>NO_PAIRS</td></tr>\n";
}

sub pair {
    my $self  = shift;
    my $key   = shift;
    my $value = shift;

    return "\n<tr>  <td>  $key  </td>\n<td>  <table border='1'>"
            . "$value    </table>\n  </td> </tr>";
}

sub object {
    my $self   = shift;
    my $object = shift;
    my $class  = shift;

    return "\n<td><table border='1'><tr>"
            . "<td><table border='1'>$object</table></td>\n"
            . "<td> isa $class </td>\n"
            . "</tr></table></td>\n";
}

sub inside_out_object {
    my $self       = shift;
    my $do_content = shift;
    my $class      = shift;

    return "\n<td><table border='1'><tr>"
            . "<td><table border='1'>\n"
            . "do{\($do_content)}\n"
            . "</table></td>\n"
            . "<td> isa $class </td>\n"
            . "</tr></table></td>\n";
}

sub string {
    my $self = shift;
    my $text = shift;

    $text    =~ s/&/&amp;/g;
    $text    =~ s/</&lt;/g;
    $text    =~ s/>/&gt;/g;
    #    $text    =~ s/"/????/g;  # XXX this needs the html code for "
    return $text;
}

1;

=head1 NAME

Data::HTMLDumper::Output - Provides the default output for Data::HTMLDumper

=head1 SYNOPSIS

    use Data::HTMLDumper;
    # This module will become your output formatter.

=head1 DESCRIPTION

This is not a class you need to use directly, but if you want to control
what the output of Data::HTMLDumper looks like it will interest you.

Data::HTMLDumper uses Parse::RecDescent to parse the output of Data::Dumper.
At most stages, when its productions match corresponding methods of this
class are called.  Those methods are listed below.  By subclassing this
class and overriding methods, you can control the output's appearance.
You can achieve the same thing by replacing the class outright.  In either
case, you must tell Data::HTMLDumper by calling its actions method:

    my $your_action_object = YourSubclass->new();
    Data::HTMLDumper->actions($your_action_object);

By using objects, you can save your own state, though this class does not.

=head1 METHODS

The following methods are available to generate output.  The are described
with lists of their parameters and samples of their output.  In all cases
(except the constructor), the first argument is the invocant, which is not
listed.

=head2 new

This method is useful only for subclasses which do not need to save state.
It blesses a scalar reference.  It only exists so that object oriented
access is possible.

=head2 output

This is called once each time the top level rule matches.  It receives an
array reference pointing to the text for each expression that matched.  It
is here to serve calls to Dumper which have multiple references.
Mine just interpolates the array into a string (after locally setting
$" to "").

=head2 expression

This method is called when the top level rule matches.  It receives the
invocant plus a hash of consumed text from the input.  The keys in the hash
are SIGIL (usually, or perhaps always, $), ID_NAME (the name of the var
as in VAR3), and item (which is the text produced by the methods below
for the rest of the expression).

My version looks like this:

  sub expression {
    my $self = shift;
    my %item = @_;

    return "<table border='1'>$item{item}</table>\n";
  }

I won't show any more whole methods, but this shows how easy it is to
generate the output.  Simply use the input data to build a string.
Return that string.

=head1 item_value

This should probably be item_simple_value, but I didn't want to type
that everywhere.  It receives two things: a simple item (like a string, a
number, or undef) and a flag telling the item is a hash value or not
(true means it is, undefined means it's not).

=head2 item_array

This is called when an entire array is seen.  Usually the output is
already generated, so my routine simply returns its second argument.

=head2 item_hash

This is just like item_array, but for hashes.  Again, all I do is return
the second argument.

=head2 item_object

This is the third and final in the series.  It receives the object text.
Mine returns the second argument.

=head2 array

This is called with an array reference listing the output for the items
which are the elements of an array.  Mine puts them in a row:

    <tr>@$array</tr>

Remember that it receives an array reference.

=head2 array_empty

This is called without arguments when an array of the form [] is seen.
Do what you like.  I give back this:

    <tr><td>NO_ELEMENTS</td></tr>

=head2 hash

This is like array above, but it recieves an array of the output for the
key/value pairs in the hash.  I just stringify it:

    "@$pairs\n";

(but I reset $" locally to "", so no extra spaces separate the entries)

=head2 hash_empty

This is just like array_empty except for hashes like {}.  I return:

    <tr><td>NO_PAIRS</td></tr>

=head2 pair

This is called with a key and its value item, each time a pair is seen in
a hash.  My output creates a new row (since this is a whole hash), putting
the key in the first column and a table around the value in the second.

=head2 object

This is called when a blessed reference is found.  It receives the object
and the class into which it is blessed.

=head2 string

This is called whenever a string value is seen.  The string is passed
in.  For HTML output it is wise to replace any html characters with
their appropriate entities, for example:

    $text    =~ s/&/&amp;/g;

After several such substitutions, I return the string.

=cut

