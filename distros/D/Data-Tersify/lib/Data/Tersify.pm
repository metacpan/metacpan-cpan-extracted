package Data::Tersify;

use strict;
use warnings;

use parent 'Exporter';
our @EXPORT_OK = qw(tersify);

our $VERSION = '0.001';
$VERSION = eval $VERSION;

use Module::Pluggable require => 1;
use Scalar::Util qw(blessed refaddr);

=head1 NAME

Data::Tersify - generate terse equivalents of complex data structures

=head1 SYNOPSIS

 use Data::Dumper;
 use Data::Tersify qw(tersify);
 
 my $complicated_data_structure = ...;
 
 print Dumper(tersify($complicated_data_structure));
 # Your scrollback is not full of DateTime, DBIx::Class, Moose etc.
 # spoor which you weren't interested in.

=head1 DESCRIPTION

Complex data structures are useful; necessary, even. But they're not
I<helpful>. In particular, when you're buried in the guts of some code
you don't fully understand and you have a variable you want to inspect,
and you say C<x $foo> in the debugger, or C<print STDERR Dumper($foo)> from
your code, or something very similar with the dumper module of your choice,
and you then get I<pages upon pages of unhelpful stuff> because C<$foo>
contained, I<somewhere> a reference to a DateTime, DBIx::Class, Moose or other
verbose object... you didn't need that.

Data::Tersify looks at any data structure it's given, and if it finds a
blessed object that it knows about, anywhere, it replaces it in the data
structure by a terser equivalent, designed to (a) not use up all of your
scrollback, but (b) be blatantly clear that this is I<not> the original object
that was in that data structure originally, but a terser equivalent.

Do not use Data::Tersify as part of any serialisation implementation! By
design, Data::Tersify is lossy and will throw away information! That's because
it supposes that that if you're using it, you want to dump information about a
complex data structure, and you don't I<care> about the fine details.

=head2 tersify

 In: $data_structure
 In: $terser_data_structure

Supplied with a data structure, returns a data structure with the complicated
bits summarised. Every attempt is made to preserve those parts of the data
structure that don't need summarising.

Structures are only summarised if (1) they're blessed objects, (2) they're 
not the root structure passed to tersify (so if you actually to want to
dump a complex DBIx::Class object, for instance, you still can), and (3) a
plugin has been registered that groks that type of object.

Summaries are blessed scalars of the form "I<Classname> (I<refaddr>)
I<summary>", e.g. "DateTime (0xdeadbeef) 2017-08-15".

=cut

sub tersify {
    my ($data_structure) = @_;

    my $changed;
    ($data_structure, $changed) = _tersify($data_structure);
    return $data_structure;
}

sub _tersify {
    my ($data_structure) = @_;

    # If this is a simple scalar, there's nothing to change.
    if (!ref($data_structure)) {
        return ($data_structure, 0);
    }

    # If this is a blessed object, see if we know how to tersify it.
    if (blessed($data_structure)) {
        # Although if this is the root structure passed to tersify, we want
        # to pass it through as-is; we only tersify complicated objects
        # that feature somewhere deeper in the data structure, possibly
        # unexpectedly.
        my ($caller_sub) = (caller(1))[3];
        if ($caller_sub eq 'Data::Tersify::tersify') {
            return $data_structure;
        }
        my $terse_object = _tersify_via_plugin($data_structure);
        my $changed = blessed($terse_object)
            && $terse_object->isa('Data::Tersify::Summary');
        return ($terse_object, $changed);
    }

    # For arrays and hashes, check if any of the elements changed, and if so
    # return a fresh array or hash.
    my $changed;
    my $get_new_value = sub {
        my ($old_value) = @_;
        my ($new_value, $this_value_changed) = _tersify($old_value);
        $changed += $this_value_changed;
        return $this_value_changed ? $new_value : $old_value;
    };
    if (ref($data_structure) eq 'ARRAY') {
        my @new_array;
        for my $element (@$data_structure) {
            push @new_array, $get_new_value->($element);
        }
        return $changed ? (\@new_array, 1) : ($data_structure, 0);
    }
    if (ref($data_structure) eq 'HASH') {
        my %new_hash;
        for my $key (keys %$data_structure) {
            $new_hash{$key} = $get_new_value->($data_structure->{$key});
        }
        return $changed ? (\%new_hash, 1) : ($data_structure, 0);
    }
}

=head2 PLUGINS

Out of the box, Data::Tersify comes with plugins for DateTime objects.

=cut

{
    my (%plugin_handles, %handled_by_plugin);

    sub _tersify_via_plugin {
        my ($object) = @_;

        if (!keys %plugin_handles) {
            for my $plugin (plugins()) {
                my $handles = $plugin->handles;
                $plugin_handles{$plugin} = $handles;
                if (!ref($handles)) {
                    $handled_by_plugin{$handles} = $plugin;
                } elsif (ref($handles) eq 'ARRAY') {
                    for my $class (@$handles) {
                        $handled_by_plugin{$class} = $plugin;
                    }
                }
            }
        }

        if (my $plugin = $handled_by_plugin{ref($object)}) {
            my $summary = sprintf('%s (0x%x) %s',
                ref($object), refaddr($object), $plugin->tersify($object));
            return bless \$summary => 'Data::Tersify::Summary';
        }
        return $object;
    }
}

1;