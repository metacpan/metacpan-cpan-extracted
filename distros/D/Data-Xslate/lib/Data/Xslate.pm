package Data::Xslate;

$Data::Xslate::VERSION = '0.05';

use Text::Xslate;
use Carp qw( croak );
use Storable qw( freeze thaw );

use strict;
use warnings;

# A tied-hash class used to expose the data as the Xslate
# vars when processing the data.
{
    package # NO INDEX
        Data::Xslate::Vars;

    use base 'Tie::Hash';

    sub TIEHASH {
        my ($class, $sub) = @_;
        return bless {sub=>$sub}, $class;
    }

    sub FETCH {
        my ($self, $key) = @_;

        return $self->{sub}->( $key );
    }
}

sub new {
    my $class = shift;

    die if @_ % 2 != 0;
    my $args = { @_ };

    my $defaults = {
        substitution_tag => '=',
        nested_key_tag   => '=',
        key_separator    => '.',
    };

    my $self = bless { %$defaults }, $class;
    foreach my $key (keys %$defaults) {
        next if ! exists $args->{$key};
        $self->{$key} = delete $args->{$key};
    }

    my $function = delete( $args->{function} ) || {};
    $function->{node} ||= \&_find_node_for_xslate;
    $self->{_xslate} = Text::Xslate->new(
        type     => 'text',
        function => $function,
        %$args,
    );

    return $self;
}

# Arguments.
sub substitution_tag { $_[0]->{substitution_tag} }
sub nested_key_tag { $_[0]->{nested_key_tag} }
sub key_separator { $_[0]->{key_separator} }

# Attributes.
sub _xslate { $_[0]->{_xslate} }

# State variables, only used during local() calls to maintain
# state in recursive function calls.
our $XSLATE;
our $VARS;
our $ROOT;
our $NODES;
our $SUBSTITUTION_TAG;
our $NESTED_KEY_TAG;
our $KEY_SEPARATOR;
our $PATH_FOR_XSLATE;

sub render {
    my ($self, $data) = @_;

    $data = thaw( freeze( $data ) );

    local $Carp::Internal{ (__PACKAGE__) } = 1;

    local $XSLATE = $self->_xslate();

    my %vars;
    tie %vars, 'Data::Xslate::Vars', \&_find_node_for_xslate;
    local $VARS = \%vars;

    local $ROOT = $data;
    local $NODES = {};
    local $SUBSTITUTION_TAG = $self->substitution_tag();
    local $NESTED_KEY_TAG = $self->nested_key_tag();
    local $KEY_SEPARATOR = $self->key_separator();

    return _evaluate_node( 'root' => $data );
}

sub _evaluate_node {
    my ($path, $node) = @_;

    return $NODES->{$path} if exists $NODES->{$path};

    if (!ref $node) {
        if (defined $node) {
            if ($node =~ m{^\Q$SUBSTITUTION_TAG\E\s*(.+?)\s*$}) {
                $node = _find_node( $1, $path );
            }
            else {
                local $PATH_FOR_XSLATE = $path;
                $node = $XSLATE->render_string( $node, $VARS );
            }
        }
        $NODES->{$path} = $node;
    }
    elsif (ref($node) eq 'HASH') {
        $NODES->{$path} = $node;
        foreach my $key (sort keys %$node) {
            if ($key =~ m{^(.*)\Q$NESTED_KEY_TAG\E$}) {
                my $sub_path = "$path$KEY_SEPARATOR$1";
                my $value = delete $node->{$key};
                _set_node( $sub_path, $value );
            }
            else {
                my $sub_path = "$path$KEY_SEPARATOR$key";
                $node->{$key} = _evaluate_node( $sub_path, $node->{$key} );
            }
        }
    }
    elsif (ref($node) eq 'ARRAY') {
        $NODES->{$path} = $node;
        @$node = (
            map { _evaluate_node( "$path$KEY_SEPARATOR$_" => $node->[$_] ) }
            (0..$#$node)
        );
    }
    else {
        croak "The config node at $path is neither a hash, array, or scalar";
    }

    return $node;
}

sub _load_node {
    my ($path) = @_;

    my @parts = split(/\Q$KEY_SEPARATOR\E/, $path);
    my $built_path = shift( @parts ); # root

    my $node = $ROOT;
    while (@parts) {
        my $key = shift( @parts );
        $built_path .= "$KEY_SEPARATOR$key";

        if (ref($node) eq 'HASH') {
            return undef if !exists $node->{$key};
            $node = _evaluate_node( $built_path => $node->{$key} );
        }
        elsif (ref($node) eq 'ARRAY') {
            return undef if $key > $#$node;
            $node = _evaluate_node( $built_path => $node->[$key] );
        }
        else {
            croak "The config node at $path is neither a hash or array";
        }
    }

    return $node;
}

sub _find_node {
    my ($path, $from_path) = @_;

    if ($path =~ m{^\Q$KEY_SEPARATOR\E(.+)}) {
        $path = $1;
        $from_path = "root${KEY_SEPARATOR}root_sub_key_that_is_not_used_for_absolute_keys";
    }

    my @parts = split(/\Q$KEY_SEPARATOR\E/, $from_path);
    pop( @parts );

    while (@parts) {
        my $sub_path = join($KEY_SEPARATOR, @parts);

        my $node = _load_node( "$sub_path$KEY_SEPARATOR$path" );
        return $node if $node;

        pop( @parts );
    }

    return _load_node( $path );
}

sub _find_node_for_xslate {
    my ($path) = @_;
    return _find_node( $path, $PATH_FOR_XSLATE );
}

sub _set_node {
    my ($path, $value) = @_;

    my @parts = split(/\Q$KEY_SEPARATOR\E/, $path);
    my $built_path = shift( @parts ); # root
    my $last_part = pop( @parts );

    my $node = $ROOT;
    while (@parts) {
        my $key = shift( @parts );
        $built_path .= "$KEY_SEPARATOR$key";

        if (ref($node) eq 'HASH') {
            return 0 if !exists $node->{$key};
            $node = _evaluate_node( $built_path => $node->{$key} );
        }
        elsif (ref($node) eq 'ARRAY') {
            return 0 if $key > $#$node;
            $node = _evaluate_node( $built_path => $node->[$key] );
        }
        else {
            croak "The config node at $path is neither a hash or array";
        }
    }

    delete $NODES->{$path};
    $value = _evaluate_node( $path => $value );

    if (ref($node) eq 'HASH') {
        $node->{$last_part} = $value;
    }
    elsif (ref($node) eq 'ARRAY') {
        $node->[$last_part] = $value;
    }

    return 1;
}

1;
__END__

=head1 NAME

Data::Xslate - Templatize your data.

=head1 SYNOPSIS

    use Data::Xslate;
    
    my $xslate = Data::Xslate->new();
    
    my $output = $xslate->render( $input );

Given this input data structure:

    {
        color_names => ['red', 'blue', 'orange'],
        email => {
            message => 'Do you like the color <: $user.color_name :>?',
            subject => 'Hello <: $user.name :>!',
            to      => '=user.email',
        },
        'email.from=' => 'george@example.com',
        user => {
            color_id => 2,
            color_name => '<: node("color_names")[$color_id] :>',
            email => '<: $login :>@example.com',
            login => 'john',
            name  => 'John',
        },
    }

This data will be output:

    {
        color_names => ['red', 'blue', 'orange'],
        email => {
            from => 'george@example.com',
            message => 'Do you like the color orange?',
            subject => 'Hello John!',
            to => 'john@example.com',
        },
        user => {
            color_id => '2',
            color_name => 'orange',
            email => 'john@example.com',
            login => 'john',
            name => 'John',
        },
    }

=head1 DESCRIPTION

This module provides a syntax for templatizing data structures.

=head2 Templating

The most powerful feature by far is templating, where you can
use L<Text::Xslate> in your values.

    {
        foo => 'green',
        bar => 'It is <: $foo :>!',
    }
    # { foo=>'green', bar=>'It is green!' }

There is a lot you can do with this beyond simply including values
from other keys:

    {
        prod => 1,
        memcached_host => '<: if $prod { :>memcached.example.com<: } else { :>127.0.0.1<: } :>',
    }
    # { prod=>1, memcached_host=>'memcached.example.com' }

Values in arrays are also processed for templating:

    {
        ceo_name => 'Sara',
        employees => [
            '<: $ceo_name :>',
            'Fred',
            'Alice',
        ],
    }
    # {
    #     ceo_name => 'Sara',
    #     employees => [
    #         'Sara',
    #         'Fred',
    #         'Alice',
    #     ],
    # }

As well as using array values in a template:

    { foo=>'<: $bar.1 :>', bar=>[4,5,6] }
    # { foo=>5, bar=>[4,5,6] }

Data structures of any arbitrary depth and complexity are handled
correctly, and keys from any level can be referred to following
the L</SCOPE> rules.

=head2 Substitution

Substituion allows you to retrieve a value from one key and use it
as the value for the current key.  To do this your hash or array
value must start with the L</substitution_tag> (defaults to C<=>):

    {
        foo => 14,
        bar => '=foo',
    }
    # { foo=>14, bar=>14 }

Templating could be used instead of substitution:

    {
        foo => 14,
        bar => '<: $foo :>',
    }

But, templating only works with strings.  Substitutions become vital
when you want to substitute an array or hash:

    {
        foo => [1,2,3],
        bar => '=foo',
    }
    # { foo=>[1,2,3], bar=>[1,2,3] }

The keys in substitution follow the L</SCOPE> rules.

=head2 Nested Keys

When setting a key value the key can point deeper into the structure by
separating keys with the L</key_separator> (defaults to a dot, C<.>),
and ending the key with the L</nested_key_tag> (defaults to C<=>).
Consider this:

    { a=>{ b=>1 }, 'a.b=' => 2 }
    # { a=>{ b=>2 } }

So, nested keys are a way to set values in other data structures.  This
feature is very handy when you are merging data structures from different
sources and one data structure will override a subset of values in the
other.

=head2 Key Paths

When referring to other values in L</TEMPLATING>, L</SUBSTITUTION>, or
L</NESTED KEYS> you are specifying a path made up of keys for this module
to walk and find a value to retrieve.

So, when you specify a key path such as C<foo.bar> you are looking for a hash
with the key C<foo> who's value is a hash and then retrieving the value
of the C<bar> key in it.

Arrays are fully supported in these key paths so that if you specify
a key path such as C<bar.0> you are looking for a hash with the C<bar>
key whose value is an array, and then the first value in the array is
fetched.

Note that the above examples assume that L</key_separator> is a dot (C<.>),
the default.

=head2 Scope

When using either L</SUBSTITUTION> or L</TEMPLATING> you specify a key to be
acted on.  This key is found using scope-aware rules where the key is searched for
in a similar fashion to how you'd expect when dealing with lexical variables in
programming.

For example, you can refer to a key in the same scope:

    { a=>1, b=>'=a' }

You may refer to a key in a lower scope:

    { a=>{ b=>1 }, c=>'=a.b' }

You may refer to a key in a higher scope:

    { a=>{ b=>'=c' }, c=>1 }

You may refer to a key in a higher scope that is nested:

    { a=>{ b=>'=c.d' }, c=>{ d=>1 } }

The logic behind this is pretty flexible, so more complex use cases will
just work like you would expect.

If you'd rather avoid this scoping you can prepend any key with the L</key_separator>
(defaults to a dot, C<.>), and it will be looked for at the root of the config data
only.

In the case of templating a special C<node> function is provided which
will allow you to retrieve an absolute key.  For example these two lines
would do the same thing (printing out a relative key value):

    <: $foo.bar :>
    <: node("foo.bar") :>

But if you wanted to refer to an absolute key you'd have to do this:

    <: node(".foo.bar") :>

=head1 ARGUMENTS

Any arguments you pass to C<new>, which this class does not directly
handle, will be used when creating the underlying L<Text::Xslate> object.
So, any arguments which L<Text::Xslate> supports may be set.  For example:

    my $xslate = Data::Xslate->new(
        substitution_tag => ']]', # A Data::Xslate argument.
        verbose          => 2,    # A Text::Xslate argument.
    );

=head2 substitution_tag

The string to look for at the beginning of any string value which
signifies L</SUBSTITUTION>.  Defaults to C<=>.  This is used in
data like this:

    { a=>{ b=>2 }, c => '=a.b' }
    # { a=>{ b=>2 }, c => 2 }

=head2 nested_key_tag

The string to look for at the end of any key which signifies
L</NESTED KEYS>.  Defaults to C<=>.  This is used in data
like this:

    { a=>{ b=>2 }, 'a.c=' => 3 }
    # { a=>{ b=>2, c=>3 } }

=head2 key_separator

The string which will be used between keys.  The default is a dot (C<.>)
which looks like this:

    { a=>{ b=>2 }, c => '=a.b' }

Whereas, for example, if you changed the C<key_separator> to a forward
slash it would look like this:

    { a=>{ b=>2 }, c => '=a/b' }

Which looks rather good with absolute keys:

    { a=>{ b=>2 }, c => '=/a/b' }

=head1 METHODS

=head2 render

    my $data_out = $xslate->render( $data_in );

Processes the data and returns new data.  The passed in data is not
modified.

=head1 SUPPORT

Please submit bugs and feature requests to the
Data-Xslate GitHub issue tracker:

L<https://github.com/bluefeet/Data-Xslate/issues>

=head1 AUTHOR

Aran Deltac <bluefeetE<64>gmail.com>

=head1 ACKNOWLEDGEMENTS

Thanks to L<ZipRecruiter|https://www.ziprecruiter.com/>
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

