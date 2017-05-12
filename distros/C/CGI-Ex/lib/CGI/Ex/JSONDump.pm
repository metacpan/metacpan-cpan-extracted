package CGI::Ex::JSONDump;

=head1 NAME

CGI::Ex::JSONDump - Comprehensive data to JSON dump.

=cut

###----------------------------------------------------------------###
#  Copyright 2006-2015 - Paul Seamons                                #
#  Distributed under the Perl Artistic License without warranty      #
###----------------------------------------------------------------###

use vars qw($VERSION
            @EXPORT @EXPORT_OK);
use strict;
use base qw(Exporter);

BEGIN {
    $VERSION = '2.44';

    @EXPORT = qw(JSONDump);
    @EXPORT_OK = @EXPORT;

};

sub JSONDump {
    my ($data, $args) = @_;
    return __PACKAGE__->new($args)->dump($data);
}

###----------------------------------------------------------------###

sub new {
    my $class = shift || __PACKAGE__;
    my $args  = shift || {};
    my $self  = bless {%$args}, $class;

    $self->{'skip_keys'} = {map {$_ => 1} ref($self->{'skip_keys'}) eq 'ARRAY' ? @{ $self->{'skip_keys'} } : $self->{'skip_keys'}}
        if $self->{'skip_keys'} && ref $self->{'skip_keys'} ne 'HASH';

    $self->{'sort_keys'} = 1 if ! exists $self->{'sort_keys'};

    return $self;
}

sub dump {
    my ($self, $data, $args) = @_;
    $self = $self->new($args) if ! ref $self;

    local $self->{'indent'}   = ! $self->{'pretty'} ? ''  : defined($self->{'indent'})   ? $self->{'indent'}   : '  ';
    local $self->{'hash_sep'} = ! $self->{'pretty'} ? ':' : defined($self->{'hash_sep'}) ? $self->{'hash_sep'} : ' : ';
    local $self->{'hash_nl'}  = ! $self->{'pretty'} ? ''  : defined($self->{'hash_nl'})  ? $self->{'hash_nl'}  : "\n";
    local $self->{'array_nl'} = ! $self->{'pretty'} ? ''  : defined($self->{'array_nl'}) ? $self->{'array_nl'} : "\n";
    local $self->{'str_nl'}   = ! $self->{'pretty'} ? ''  : defined($self->{'str_nl'})   ? $self->{'str_nl'}   : "\n";

    return $self->_dump($data, '');
}

sub _dump {
    my ($self, $data, $prefix) = @_;
    my $ref = ref $data;

    if ($ref eq 'CODE' && $self->{'play_coderefs'}) {
        $data = $data->();
        $ref = ref $data;
    }

    if ($ref eq 'HASH') {
        my @keys = (grep { my $r = ref $data->{$_};
                           ! $r || $self->{'handle_unknown_types'} || $r eq 'HASH' || $r eq 'ARRAY' || ($r eq 'CODE' && $self->{'play_coderefs'})}
                    grep { ! $self->{'skip_keys'}    || ! $self->{'skip_keys'}->{$_} }
                    grep { ! $self->{'skip_keys_qr'} || $_ !~ $self->{'skip_keys_qr'} }
                    ($self->{'sort_keys'} ? (sort keys %$data) : (keys %$data)));
        return "{}" if ! @keys;
        return "{$self->{hash_nl}${prefix}$self->{indent}"
            . join(",$self->{hash_nl}${prefix}$self->{indent}",
                   map  { $self->js_escape($_, "${prefix}$self->{indent}", 1)
                              . $self->{'hash_sep'}
                              . $self->_dump($data->{$_}, "${prefix}$self->{indent}") }
                   @keys)
            . "$self->{hash_nl}${prefix}}";

    } elsif ($ref eq 'ARRAY') {
        return "[]" if ! @$data;
        return "[$self->{array_nl}${prefix}$self->{indent}"
            . join(",$self->{array_nl}${prefix}$self->{indent}",
                   map { $self->_dump($_, "${prefix}$self->{indent}") }
                   @$data)
            . "$self->{array_nl}${prefix}]";

    } elsif ($ref) {
        return $self->{'handle_unknown_types'}->($self, $data, $ref) if ref($self->{'handle_unknown_types'}) eq 'CODE';
        return '"'.$data.'"'; ### don't do anything

    } else {
        return $self->js_escape($data, "${prefix}$self->{indent}");
    }
}

sub js_escape {
    my ($self, $str, $prefix, $no_num) = @_;
    return 'null'  if ! defined $str;

    ### allow things that look like numbers to show up as numbers (and those that aren't quite to not)
    return $str if ! $no_num && $str =~ /^ -? (?: [1-9][0-9]{0,12} | 0) (?: \. \d* [1-9])? $/x;

    my $quote = $self->{'single_quote'} ? "'" : '"';

    $str =~ s/\\/\\\\/g;
    $str =~ s/\r/\\r/g;
    $str =~ s/\t/\\t/g;
    $self->{'single_quote'} ? $str =~ s/\'/\\\'/g : $str =~ s/\"/\\\"/g;

    ### allow for really odd chars
    $str =~ s/([\x00-\x07\x0b\x0e-\x1f])/'\\u00' . unpack('H2',$1)/eg; # from JSON::Converter
    utf8::decode($str) if $self->{'utf8'} && &utf8::decode;

    ### escape <html> and </html> tags in the text
    $str =~ s{(</? (?: htm | scrip | !-) | --(?=>) )}{$1$quote+$quote}gx
        if ! $self->{'no_tag_splitting'};

    ### add nice newlines (unless pretty is off)
    if ($self->{'str_nl'} && length($str) > 80) {
        if ($self->{'single_quote'}) {
            $str =~ s/\'\s*\+\'$// if $str =~ s/\n/\\n\'$self->{str_nl}${prefix}+\'/g;
        } else {
            $str =~ s/\"\s*\+\"$// if $str =~ s/\n/\\n\"$self->{str_nl}${prefix}+\"/g;
        }
    } else {
        $str =~ s/\n/\\n/g;
    }

    return $quote . $str . $quote;
}

1;

__END__

=head1 SYNOPSIS

    use CGI::Ex::JSONDump;

    my $js = JSONDump(\%complex_data, {pretty => 1});

    ### OR

    my $js = CGI::Ex::JSONDump->new({pretty => 1})->dump(\%complex_data);

=head1 DESCRIPTION

CGI::Ex::JSONDump is a very lightweight and fast perl data structure to javascript object
notation dumper.  This is useful for AJAX style methods, or dynamic page creation that
needs to embed perl data in the presented page.

CGI::Ex::JSONDump has roughly the same output as JSON::objToJson, but with the following
differences:

    - CGI::Ex::JSONDump is much much lighter and smaller (a whopping 134 lines).
    - It dumps Javascript in more browser friendly format (handling of </script> tags).
    - It removes unknown key types by default instead of dying.
    - It allows for a general handler to handle unknown key types.
    - It allows for fine grain control of all whitespace.
    - It allows for skipping keys by name or by regex.
    - It dumps both data structures and scalar types.

=head1 METHODS

=over 4

=item new

Create a CGI::Ex::JSONDump object.  Takes arguments hashref as single argument.

    my $obj = CGI::Ex::JSONDump->new(\%args);

See the arguments section for a list of the possible arguments.

=item dump

Takes a perl data structure or scalar string or number and returns a string
containing the javascript representation of that string (in Javascript object
notation - JSON).

=item js_escape

Takes a scalar string or number and returns a javascript escaped string that will
embed properly in javascript.  All numbers and strings of nested data structures
are passed through this method.

=back

=head1 FUNCTIONS

=over 4

=item JSONDump

A wrapper around the new and dump methods.  Takes a structure to dump
and optional args to pass to the new routine.

    JSONDump($data, $args);

Is the same as:

    CGI::Ex::JSONDump->new($args)->dump($data);

=back

=head1 ARGUMENTS

The following arguments may be passed to the new method or as the second
argument to the JSONDump function.

=over 4

=item pretty

0 or 1.  Default 0 (false).  If true then dumped structures will
include whitespace to make them more readable.

     JSONDump({a => [1, 2]}, {pretty => 0});
     JSONDump({a => [1, 2]}, {pretty => 1});

     Would print

     {"a":[1,2]}
     {
       "a" : [
         1,
         2
       ]
     }

=item single_quote

0 or 1.  Default 0 (false).  If true then escaped values will be quoted
with single quotes.  Otherwise values are quoted with double quotes.

     JSONDump("a", {single_quote => 0});
     JSONDump("a", {single_quote => 1});

     Would print

     "a"
     'a'

=item sort_keys

0 or 1.  Default 1 (true)

If true, then key/value pairs of hashrefs will be output in sorted order.

=item play_coderefs

0 or 1.  Default 0 (false).  If true, then any code refs will be executed
and the returned string will be dumped.

If false, then keys of hashrefs that contain coderefs will be skipped (unless
the handle_unknown_types property is set).  Coderefs
that are in arrayrefs will show up as "CODE(0x814c648)" unless
the handle_unknown_types property is set.

=item handle_unknown_types

Default undef.  If true it should contain a coderef that will be called if any
unknown types are encountered.  The only default known types are scalar string
or number values, unblessed HASH refs and ARRAY refs (and CODE refs if the
play_coderefs property is set).  All other types will be passed to the
handle_unknown_types method call.

    JSONDump({a => bless({}, 'A'), b => 1}, {
        handle_unknown_types => sub {
            my $self = shift; # a JSON object
            my $data = shift; # the object to dump

            return $self->js_escape("Ref=" . ref $data);
        },
        pretty => 0,
    });

    Would print

    {"a":"Ref=A","b":1}

If the handle_unknown_types method is not set then keys hashrefs that have values
with unknown types will not be included in the javascript output.

    JSONDump({a => bless({}, 'A'), b => 1}, {pretty => 0});

    Would print

    {"b":1}

=item skip_keys

Should contain an arrayref of keys or a hashref whose keys are the
keys to skip.  Default is unset.  Any keys of hashrefs (including
nested hashrefs) that are listed in the skip_keys item will not be included
in the javascript output.

    JSONDump({a => 1, b => 1}, {skip_keys => ['a'], pretty => 0});

    Would print

    {"b":1}

=item skip_keys_qr

Similar to skip_keys but should contain a regex.  Any keys of hashrefs
(including nested hashrefs) that match the skip_keys_qr regex will not
be included in the javascript output.

    JSONDump({a => 1, _b => 1}, {skip_keys_qr => qr/^_/, pretty => 0});

    Would print

    {"a":1}

=item indent

The level to indent each nested data structure level if pretty is true.  Default is "  " (two spaces).

=item hash_nl

The whitespace to add after each hashref key/value pair if pretty is true.  Default is "\n".

=item hash_sep

The separator and whitespace to put between each hashref key/value pair if pretty is true.  Default is " : ".

=item array_nl

The whitespace to add after each arrayref entry if pretty is true.  Default is "\n".

=item str_nl

The whitespace to add in between newline separated strings if pretty is true or the output line is
greater than 80 characters.  Default is "\n" (if pretty is true).

    JSONDump("This is a long string\n"
             ."with plenty of embedded newlines\n"
             ."and is greater than 80 characters.\n", {pretty => 1});

    Would print

    "This is a long string\n"
      +"with plenty of embedded newlines\n"
      +"and is greater than 80 characters.\n"

    JSONDump("This is a long string\n"
             ."with plenty of embedded newlines\n"
             ."and is greater than 80 characters.\n", {pretty => 1, str_nl => ""});

    Would print

    "This is a long string\nwith plenty of embedded newlines\nand is greater than 80 characters.\n"

If the string is less than 80 characters, or if str_nl is set to "", then the escaped
string will be contained on a single line.  Setting pretty to 0 effectively sets str_nl equal to "".

=item no_tag_splitting

Default off.  If JSON is embedded in an HTML document and the JSON contains C<< <html> >>,
C<< </html> >>, C<< <script> >>, C<< </script> >>, C<< <!-- >>, or , C<< --> >> tags, they are
split apart with a quote, a +, and a quote.  This allows the embedded tags to not affect
the currently playing JavaScript.

However, if the JSON that is output is intended for deserialization by another non-javascript-engine
JSON parser, this splitting behavior may cause errors when the JSON is imported.  To avoid the splitting
behavior in these cases you can use the no_tag_splitting flag to turn off the behavior.

    JSONDump("<html><!-- comment --><script></script></html>");

    Would print

    "<htm"+"l><!-"+"- comment --"+"><scrip"+"t></scrip"+"t></htm"+"l>"

    With the flag

    JSONDump("<html><!-- comment --><script></script></html>", {no_tag_splitting => 1});

    Would print

    "<html><!-- comment --><script></script></html>"

=back

=head1 LICENSE

This module may distributed under the same terms as Perl itself.

=head1 AUTHORS

Paul Seamons <perl at seamons dot com>

=cut
