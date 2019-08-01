=head1 NAME

Config::Neat::Inheritable - Config::Neat files with inheritance

=head1 SYNOPSIS

File 01.nconf:

    foo {
        bar         baz

        etc {
            pwd     1
        }
    }

    abc             def

File 02.nconf:

    @inherit        01.nconf

    foo {
        bar         replace
    }

    -abc

Resulting data structure will be equivalent to:

    foo {
        bar         replace

        etc {
            pwd     1
        }
    }

Within C<@inherit>, you can use selectors as slash-delimited paths to the node
within a target file, for example:

    whatever {
        @inherit    01.nconf#foo/etc
        bar         replace
    }

Resulting data structure will be equivalent to:

    whatever {
        pwd         1
        bar         replace
    }

Multiple inheritance is supported; use '.' do denote the the current file:

    @inherit    01.nconf#foo 02.nconf#bar .#baz

=head1 COPYRIGHT

Copyright (C) 2012-2015 Igor Afanasyev <igor.afanasyev@gmail.com>

=head1 SEE ALSO

L<https://github.com/iafan/Config-Neat>

=cut

package Config::Neat::Inheritable;

our $VERSION = '1.401';

use strict;

no warnings qw(uninitialized);

use Config::Neat;
use Config::Neat::Util qw(new_ixhash is_hash is_ixhash to_ixhash is_neat_array
                          is_simple_array get_next_auto_key offset_keys
                          get_keys_in_order reorder_ixhash rename_ixhash_key
                          read_file);
use File::Spec::Functions qw(rel2abs);
use File::Basename qw(dirname);
use Storable qw(dclone);
use Tie::IxHash;

#
# Initialize object
#
sub new {
    my ($class) = @_;

    my $self = {
        cfg => Config::Neat->new(),
    };

    bless $self, $class;
    return $self;
}

sub init {
    my ($self) = @_;

    $self->{cache} = {};
    $self->{saved_context} = [];
    $self->{include_stack} = [];
}

# Given a file name, will read this file in the specified mode (UTF-8 by default),
# parse it and expand '@inherit' blocks
sub parse_file {
    my ($self, $filename, $binmode) = @_;

    $self->init;
    $self->{binmode} = $binmode;

    return $self->_parse_file($filename);
}

# Given a string representation of the config, returns a parsed tree
# with expanded '@inherit' blocks
sub parse {
    my ($self, $nconf_text, $filename) = @_;
    $self->init;
    return $self->_parse($nconf_text, $filename);
}

sub _parse_file {
    my ($self, $filename) = @_;

    $filename = rel2abs($filename);
    return $self->_parse(read_file($filename, $self->{binmode}), $filename);
}

sub _parse {
    my ($self, $nconf_text, $filename) = @_;

    # preserve current context
    push @{$self->{saved_context}}, {
        orig_data => $self->{orig_data},
        fullpath => $self->{fullpath}
    };

    # parse the file
    my $data = $self->{cfg}->parse($nconf_text);

    # generate the local context for expand_data()
    $self->{orig_data} = _clone($data);
    $self->{fullpath} = rel2abs($filename);

    # process @inherit rules
    $data = $self->expand_data($data, $data, dirname($self->{fullpath}));

    # restore the context
    my $context = pop @{$self->{saved_context}};
    $self->{orig_data} = $context->{orig_data};
    $self->{fullpath} = $context->{fullpath};

    return $data;
}

sub find_next_node_to_expand {
    my ($self, $node) = @_;
    if (is_hash($node)) {
        map {
            my ($subnode, $key) = $self->find_next_node_to_expand($node->{$_});
            return ($subnode, $key) if defined $subnode;
            return ($node, $_) if is_hash($node->{$_}) && exists $node->{$_}->{'@inherit'};
        } keys %$node;
    }
    return undef;
}

sub expand_data {
    my ($self, $base_node, $node, $dir) = @_;
    if (is_hash($node)) {

        # expand child nodes
        while (1) {
            my ($subnode, $key) = $self->find_next_node_to_expand($node);
            last unless $subnode;
            $subnode->{$key} = $self->expand_data($base_node, $subnode->{$key}, $dir);
        }

        if (exists $node->{'@inherit'}) {
            die "The value of '\@inherit' must be a string or array" unless ref($node->{'@inherit'}) eq 'Config::Neat::Array';

            my @a = @{$node->{'@inherit'}};

            my $intermediate = new_ixhash;

            foreach my $from (@a) {
                my $orig_from = $from;
                my ($filename, $selector) = split('#', $from, 2);
                # allow .#selector style to indicate the current file, since #selector
                # without the leading symbol will be treated as a comment line
                $filename = '' if $filename eq '.';
                die "Neither filename nor selector are specified" unless $filename or $selector;

                # normalize path and selector
                my $fullpath = $filename eq '' ? $self->{fullpath} : rel2abs($filename, $dir); # make path absolute based on current context dir
                $selector =~ s/^\///; # remove leading slash, if any

                $from = $fullpath.'#'.$selector;

                # make sure we don't have any infinite loops
                map {
                    if ($from eq $_) {
                        my $err =
                            "Infinite loop detected in $self->{fullpath} at `\@inherit $orig_from`\n".
                            "\@include stack:\n", join("\n", @{$self->{include_stack}}), "\n\n";
                        die $err;
                    }
                } @{$self->{include_stack}};

                push @{$self->{include_stack}}, $from;

                my $merge_node;
                if (exists $self->{cache}->{$from}) {
                    $merge_node = _clone($self->{cache}->{$from});
                } else {
                    my $merge_cfg;
                    my $merge_dir = $dir;
                    if ($filename) {
                        $merge_dir = dirname($fullpath);

                        if (!exists $self->{cache}->{$fullpath}) {
                            $self->{cache}->{$fullpath} = $self->_parse_file($fullpath);
                        }
                        $merge_cfg = _clone($self->{cache}->{$fullpath});
                    } else {
                        $merge_cfg = _clone($base_node);
                    }

                    $merge_node = $self->select_subnode($merge_cfg, $selector, $dir);
                    $merge_node = $self->expand_data($base_node, $merge_node, $merge_dir);
                    $self->{cache}->{$from} = _clone($merge_node);
                }

                $intermediate = $self->merge_data($merge_node, $intermediate, $dir);
                pop @{$self->{include_stack}};
            }

            delete $node->{'@inherit'};

            $node = $self->merge_data($node, $intermediate, $dir);
        }
    }

    return $node;
}

sub select_subnode {
    my ($self, $node, $selector, $dir) = @_;

    die "Bad selector syntax (double slash) in '$selector'" if $selector =~ m/\/{2,}/;
    die "Bad selector syntax (leading slash) in '$selector'" if $selector =~ m/^\//;

    return _clone($node) if $selector eq '';

    my @a = split('/', $selector);

    my $result = $node;
    foreach (@a) {
        next if ($_ eq '');
        if (is_hash($result) && exists $result->{$_}) {
            $result = $result->{$_};
        } else {
            die "Can't find key '$_' in node (selector: '$selector')";
        }
    }
    return _clone($result);
}

sub _clone {
    my $data = shift;
    return ref($data) ? dclone($data) : $data;
}

# merge tree structure from data2 into data1
# data1 is the one that may contain `-key` and `+key` entries
sub merge_data {
    my ($self, $data1, $data2, $dir) = @_;

    if (is_hash($data1) && is_hash($data2)) {
        my @keys = get_keys_in_order($data2, $data1);

        foreach my $key (keys %$data1) {
            my $base_key = $key =~ m/^[\+\-](.*)$/ ? $1 : $key;

            if ($key =~ m/^-(.*)$/) {
                die "Key '$key' contains bogus data; expected an empty or true value" unless $data1->{$key}->as_boolean;
                delete $data1->{$key};
                delete $data2->{$1};
                next;
            }

            # arrays are NOT merged by default; use `+key` to merge arrays
            if (is_neat_array($data1->{$key})) {
                if ($key =~ m/^\+(.*)$/) {
                    if ((!exists $data2->{$base_key} || is_neat_array($data2->{$base_key}))) {
                        $data1 = rename_ixhash_key($data1, $key, $base_key);
                        $key = $base_key;
                    }

                    if (is_simple_array($data1->{$key}) && exists $data2->{$base_key}) {
                        # we are about to merge two arrays; before doing so,
                        # if the accumulator array is a simple one, we need to convert it
                        # into an array, containing a single array ref, to maintain the
                        # 'array of arrays' structure
                        $data1->{$key} = Config::Neat::Array->new([$data1->{$key}]);
                    }
                } else {
                    delete $data2->{$key};
                }
            }

            # hashes are merged by default; `+key { }` is the same as `key { }`
            if (is_hash($data1->{$key}) && ($key =~ m/^\+(.*)$/)) {
                $data1 = rename_ixhash_key($data1, $key, $base_key);
                $key = $base_key;
            }

            if (is_hash($data1->{$key}) && is_hash($data2->{$key})) {
                my $offset = get_next_auto_key($data2->{$key});
                $data1->{$key} = offset_keys($data1->{$key}, $offset);
            }
            $data1->{$key} = $self->merge_data($data1->{$key}, $data2->{$key}, $dir);
        }

        foreach my $key (keys %$data2) {
            if (exists $data2->{$key} && !exists $data1->{$key}) {
                $data1->{$key} = $data2->{$key};
            }
        }

        $data1 = to_ixhash($data1) unless is_ixhash($data1);
        $data1 = reorder_ixhash($data1, \@keys);
    } elsif (is_neat_array($data1) && is_neat_array($data2)) {
        # always push data as array ref, not as individual items
        # to maintain 'array of arrays' structure
        if (is_simple_array($data2)) {
            unshift(@$data1, $data2);
        } else {
            unshift(@$data1, @$data2);
        }
    }

    return $data1;
}

1;