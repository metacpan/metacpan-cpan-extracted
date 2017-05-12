package App::RoboBot::Plugin::Types::Map;
$App::RoboBot::Plugin::Types::Map::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;

extends 'App::RoboBot::Plugin';

=head1 types.map

Provides functions for creating and manipulating unordered maps.

=cut

has '+name' => (
    default => 'Types::Map',
);

has '+description' => (
    default => 'Provides functions for creating and manipulating unordered maps.',
);

=head2 get

=head3 Description

Returns the value for the given key name from the provided map. If a vector of
key names are provided, all of their values are returned in the listed order.

An optional default value may be provided which will be returned for any key
which is not present in the map. Otherwise a nil is returned.

=head3 Usage

<map> <key name>|<vector of keys> [<default value>]

=head3 Examples

    :emphasize-lines: 2,5

    (get { :first-name "Bobby" :last-name "Sue" } :last-name)
    "Sue"

    (get { :a 10 :b 20 :c 30 :d 40 } [:a :c :e] 0)
    (10 30 0)

=head2 keys

=head3 Description

Returns a list of keys from the given map, in no guaranteed order.

=head3 Usage

<map>

=head3 Examples

    :emphasize-lines: 2

    (keys { :first-name "Bobby" :last-name "Sue" })
    (:first-name :last-name)

=head2 values

=head3 Description

Returns a list of values from the given map, in no guaranteed order.

=head3 Usage

<map>

=head3 Examples

    :emphasize-lines: 2

    (keys { :first-name "Bobby" :last-name "Sue" })
    ("Bobby" "Sue")

=head2 assoc

=head3 Description

Returns a new map containing the existing keys and values, as well as any new
key-value pairs provided. Values default to undefined, and keys that already
exist will have their values replaced.

Multiple key-value pairs may be provided. Providing no new key-value pairs will
simply return the existing map.

=head3 Usage

<map> [<key> [<value>] [<key> [<value>] ...]]

=head3 Examples

    :emphasize-lines: 2

    (assoc { :old-key "foo" } :new-key "bar")
    { :old-key "foo" :new-key "bar" }

=cut

has '+commands' => (
    default => sub {{
        'get' => { method      => 'map_get',
                   description => 'Retrieves the value of the named key from the given map. An undefined value is returned if the key does not exist and no default value was provided. A vector of key names may be provided, in which case a list of their values, in the vector\'s order, will be returned.',
                   usage       => '<map> <key name>|<vector of keys> [<default value>]',
                   example     => '{ :foo "bar" } :baz 23',
                   result      => '23' },

        'keys' => { method      => 'map_keys',
                    description => 'Returns a list of keys from the given map, in no guaranteed order.',
                    usage       => '<map>',
                    example     => '{ :first-name "Bobby" :last-name "Sue" }',
                    result      => '[:first-name,:last-name]', },

        'values' => { method      => 'map_values',
                      description => 'Returns a list of values from the given map, in no guaranteed order.',
                      usage       => '<map>',
                      example     => '{ :first-name "Bobby" :last-name "Sue" }',
                      result      => '["Bobby","Sue"]', },

        'assoc' => { method      => 'map_assoc',
                     description => 'Returns a new map containing the existing keys and values, as well as any new key-value pairs provided. Values default to undefined, and key that already exist will have their values replaced. Multiple key-value pairs may be provided. Providing no new key-value pairs will simply return the existing map.',
                     usage       => '<map> [<key> [<value>]]',
                     example     => '{ :old-key "foo" } :new-key "bar"',
                     result      => '{ :old-key "foo" :new-key "bar" }', },
    }},
);

sub map_assoc {
    my ($self, $message, $command, $rpl, $map, @new_elements) = @_;

    unless (defined $map && ref($map) eq 'HASH') {
        $message->response->raise('Must provide a map.');
        return;
    }

    my $key;
    foreach my $el (@new_elements) {
        if (!ref($el) && substr($el, 0, 1) eq ':') {
            $key = $el;
            $map->{$key} = undef;
        } elsif (defined $key) {
            $map->{$key} = $el;
            $key = undef;
        } else {
            $message->response->raise('Invalid parameters supplied. Map keys must evaluate to scalar symbols. Was expecting a key name, but got: %s', $el);
            return;
        }
    }

    return $map;
}

sub map_get {
    my ($self, $message, $command, $rpl, $map, $key, $default) = @_;

    unless (defined $map && ref($map) eq 'HASH') {
        $message->response->raise('Must provide a valid map.');
        return;
    }

    unless (defined $key) {
        $message->response->raise('Must provide a key name whose value you wish to retrieve from the map.');
        return;
    }

    my @ret;

    if (ref($key) eq 'ARRAY') {
        foreach my $k (@{$key}) {
            if (exists $map->{$k}) {
                push(@ret, $map->{$k});
            } elsif (defined $default) {
                push(@ret, $default);
            } else {
                push(@ret, undef);
            }
        }
    } else {
        if (exists $map->{$key}) {
            @ret = ($map->{$key});
        } elsif (defined $default) {
            @ret = ($default);
        } else {
            @ret = (undef);
        }
    }

    return @ret;
}

sub map_keys {
    my ($self, $message, $command, $rpl, $map) = @_;

    unless (defined $map && ref($map) eq 'HASH') {
        $message->response->raise('Must supply a map.');
        return;
    }

    return keys %{$map};
}

sub map_values {
    my ($self, $message, $command, $rpl, $map) = @_;

    unless (defined $map && ref($map) eq 'HASH') {
        $message->response->raise('Must supply a map.');
        return;
    }

    return values %{$map};
}

__PACKAGE__->meta->make_immutable;

1;
