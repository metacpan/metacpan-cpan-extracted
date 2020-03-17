package Data::Tersify;

use strict;
use warnings;
no warnings 'uninitialized';

use parent 'Exporter';
our @EXPORT_OK = qw(tersify tersify_many);

# Have you updated the version number in the POD below?
our $VERSION = '1.001';
$VERSION = eval $VERSION;

use Carp;
use Devel::OverloadInfo 0.005;
use Module::Pluggable require => 1, force_search_all_paths => 1;
use Scalar::Util qw(blessed refaddr reftype);

=head1 NAME

Data::Tersify - generate terse equivalents of complex data structures

=head1 VERSION

This is version 1.001 of Data::Tersify.

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
contained, I<somewhere> one or more references to a DateTime, DBIx::Class,
Moose or other verbose object ... you didn't need that.

Data::Tersify looks at any data structure it's given, and if it finds a
blessed object that it knows about, anywhere, it replaces it in the data
structure by a terser equivalent, designed to (a) not use up all of your
scrollback, but (b) be blatantly clear that this is I<not> the original object
that was in that data structure originally, but a terser equivalent.

Do not use Data::Tersify as part of any serialisation implementation! By
design, Data::Tersify is lossy and will throw away information! That's because
it supposes that that if you're using it, you want to dump information about a
complex data structure, and you don't I<care> about the fine details.

If you find yourself saying C<x $foo> in the debugger a lot, consider adding
Data::Tersify::perldb to your .perldb file, or something like it.

=head2 tersify

 In: $data_structure
 In: $terser_data_structure

Supplied with a data structure, returns a data structure with the complicated
bits summarised. Every attempt is made to preserve those parts of the data
structure that don't need summarising.

Objects are only summarised if (1) they're blessed objects, (2) they're
not the root structure passed to tersify (so if you actually to want to dump a
complex DBIx::Class object, for instance, you still can), and (3) a
plugin has been registered that groks that type of object, I<or> they
contain as an element one such object.

Summaries are either scalar references of the form "I<Classname> (I<refaddr>)
I<summary>", e.g. "DateTime (0xdeadbeef) 2017-08-15 12:34:56", blessed into the
Data::Tersify::Summary class, I<or> copies of the
object's internal state with any sub-objects tersified as above, blessed into
the Data::Tersify::Summary::I<Foo>::0xI<refaddr> class, where I<Foo> is the
class the object was originally blessed into and I<refaddr> the object's
original address.

So, if you had the plugin Data::Tersify::Plugin::DateTime installed,
passing a DateTime object to tersify would return that same object, untouched;
but passing

 {
     name        => 'Now',
     description => 'The time it currently is, not a time in the future',
     datetime    => DateTime->now
 }

to tersify would return something like this:

 {
    name        => 'Now',
    description => 'The time it currently is, not a time in the future',
    datetime    => bless \"DateTime (0xdeadbeef) 2018-08-12 17:15:00",
        "Data::Tersify::Summary",
 }

If the hashref had been blessed into the class "Time::Description",
and had a refaddr of 0xcafebabe, you would get back a hash as above, but
blessed into the class
C<Data::Tersify::Summary::Time::Description::0xcafebabe>.

Note that point 2 above (objects aren't tersified if they're the root
structure) applies only to plugins. If the object contains other objects
that could be tersified, they will be. One design consequence of this is that
you should consider writing plugins for I<multiple types of object>, rather
than the ur-object that they might be part of.

=cut

my (%seen_refaddr, %refaddr_tersified_as, %safe_to_mess_with_refaddr);

sub tersify {
    my ($data_structure) = @_;

    %seen_refaddr              = ();
    %refaddr_tersified_as      = ();
    %safe_to_mess_with_refaddr = ();
    ($data_structure) = _tersify($data_structure);
    while (%refaddr_tersified_as) {
        my @known_refaddrs = keys %refaddr_tersified_as;
        %seen_refaddr = ();
        ($data_structure) = _tersify($data_structure);
        delete @refaddr_tersified_as{@known_refaddrs};
    }
    return $data_structure;
}

sub _tersify {
    my ($data_structure) = @_;

    # If this is a data structure that we've tersified already, replace it.
    if (my $terse_object = $refaddr_tersified_as{refaddr($data_structure)}) {
        return ($terse_object, 1);
    }

    # If this is a simple scalar, there's nothing to change.
    if (!ref($data_structure)) {
        return ($data_structure, 0);
    }

    # If it's a reference to something, tersify *that* and take a reference
    # to it.
    if (ref($data_structure) eq 'REF') {
        my $referenced_data_structure = $$data_structure;
        my ($maybe_new_data_structure, $changed)
            = _tersify($referenced_data_structure);
        if (!$changed) {
            return ($data_structure, 0);
        }
        my $ref = \$maybe_new_data_structure;
        return ($ref, 1);
    }

    # Don't loop infinitely through a complex structure.
    return ($data_structure, 0) if $seen_refaddr{refaddr($data_structure)}++;
    
    # If this is a blessed object, see if we know how to tersify it.
    if (blessed($data_structure)) {
        my ($object, $changed) = _tersify_object($data_structure);
        if ($changed) {
            $refaddr_tersified_as{refaddr($data_structure)} = $object;
        }
        return ($object, $changed);
    }

    # For arrays and hashes, check if any of the elements changed, and if so
    # create a fresh array or hash.
    my $changed;
    my $get_new_value = sub {
        my ($old_value) = @_;
        my ($new_value, $this_value_changed) = _tersify($old_value);
        $changed += $this_value_changed;
        return $this_value_changed ? $new_value : $old_value;
    };
    my $new_structure;
    if (ref($data_structure) eq 'ARRAY') {
        my @new_array;
        for my $element (@$data_structure) {
            push @new_array, $get_new_value->($element);
        }
        if (!$changed) {
            return ($data_structure, 0);
        }
        $new_structure = \@new_array;
    } elsif (ref($data_structure) eq 'HASH') {
        my %new_hash;
        for my $key (keys %$data_structure) {
            $new_hash{$key} = $get_new_value->($data_structure->{$key});
        }
        if (!$changed) {
            return ($data_structure, 0);
        }
        $new_structure = \%new_hash;
    } else {
        return ($data_structure, 0);
    }

    # If it's safe to mess with the existing data structure (e.g. because this
    # is the second pass, or later, that we've done through a data structure
    # and this is an arrayref or hashref that we already anonymised earlier),
    # just update its contents. Otherwise mark it as a new data structure.
    if (!$safe_to_mess_with_refaddr{refaddr($data_structure)}) {
        $refaddr_tersified_as{ refaddr($data_structure) } = $new_structure;
        $safe_to_mess_with_refaddr{refaddr($new_structure)} = 1;
        return ($new_structure, 1);
    } else {
        _replace_contents_of_structure_with($data_structure,
            $new_structure);
        return ($data_structure, 0);
    }
}

sub _tersify_object {
    my ($data_structure) = @_;

    # A summary has, by definition, already been tersified.
    if (ref($data_structure) eq 'Data::Tersify::Summary') {
        return ($data_structure, 0);
    }

    # We might know how to tersify such an object directly, via a
    # plugin.
    my $terse_object = _tersify_via_plugin($data_structure);
    my $changed      = blessed($terse_object)
        && $terse_object->isa('Data::Tersify::Summary');

    # OK, but does it overload stringification?
    if (!$changed) {
        if (my $overload_info
            = Devel::OverloadInfo::overload_info($data_structure))
        {
            if ($overload_info->{'""'}) {
                return (
                    _summarise_object_as_string(
                        $data_structure, "$data_structure"
                    ),
                    1
                );
            }
        }
    }

    # Although if this is the root structure passed to tersify, we want
    # to pass it through as-is; we only tersify complicated objects
    # that feature somewhere deeper in the data structure, possibly
    # unexpectedly.
    my ($caller_sub) = (caller(2))[3];
    if ($changed && $caller_sub ne 'Data::Tersify::tersify') {
        return ($terse_object, $changed);
    }

    # If we didn't tersify this object, maybe we can tersify its internal
    # structure?
    my $object_contents;
    if (reftype($data_structure) eq 'HASH') {
        $object_contents = {%$data_structure};
    } elsif (reftype($data_structure) eq 'ARRAY') {
        $object_contents = [@$data_structure];
    }
    if ($object_contents) {
        my $maybe_new_structure;
        ($maybe_new_structure, $changed) = _tersify($object_contents);
        if ($changed) {
            # We might need to build a new Data::Tersify::Summary object.
            if (!$safe_to_mess_with_refaddr{refaddr($data_structure)}) {
                # No need to remember that we messed with $object_contents;
                # that was a temporary variable we created purely to see if
                # we could tersify it, and it's not referenced anywhere.
                delete $refaddr_tersified_as{refaddr($object_contents)};
                # Just create a new blessed object; the calling code will
                # realise that we created a new object and update
                # %refaddr_tersified_as with the proper values.
                $terse_object = $maybe_new_structure;
                bless $terse_object =>
                    sprintf('Data::Tersify::Summary::%s::0x%x',
                    ref($data_structure), refaddr($data_structure));
                $safe_to_mess_with_refaddr{refaddr($terse_object)}++;
            } else {
                # We can reuse the existing one, which is now *even terser*!
                # There's no danger of blatting existing data structures,
                # because we've *already* replaced the previous data structure
                # with one of ours, as part of generating a new object.
                _replace_contents_of_structure_with($data_structure,
                    $maybe_new_structure);
            }
            return ($terse_object, $changed);
        }
    }

    # OK, return this object unchanged.
    return ($data_structure, 0);
}

sub _replace_contents_of_structure_with {
    my ($safe_structure, $new_contents) = @_;

    if (reftype($safe_structure) eq 'HASH'
        && reftype($new_contents) eq 'HASH')
    {
        %$safe_structure = %$new_contents;
    } elsif (reftype($safe_structure) eq 'ARRAY'
        && reftype($new_contents) eq 'ARRAY')
    {
        @$safe_structure = @$new_contents;
    } else {
        croak sprintf(q{Want to put %s in existing %s, but that's a %s?!},
            $new_contents, $safe_structure, reftype($new_contents));
    }
}

=head2 tersify_many

 In: @data_structures
 Out: @terser_data_structures

A simple wrapper around L</tersify> that expects to be passed one or more
variables. Note that as each value is passed to L</tersify>, none of the values
in @data_structures will be tersified if they're objects recognised by plugins.
(Whereas they would have been if you'd said C<tersify(\@data_structures)>.

This is intended to be used by e.g. the Perl debugger's x command.

=cut

sub tersify_many {
    return map { tersify($_) } @_;
}

=head2 PLUGINS

Data::Tersify can be extended by plugins. See L<Data::Tersify::Plugin> for
a general description of plugins; for examples of plugins, see
L<Data::Tersify::Plugin::DateTime> and L<Data::Tersify::Plugin::DBIx::Class>,
provided in separate distributions.

=cut

{
    my (%handled_by_plugin);

    sub _tersify_via_plugin {
        my ($object) = @_;

        if (!keys %handled_by_plugin) {
            for my $plugin (plugins()) {
                for my $class ($plugin->handles) {
                    $handled_by_plugin{$class} = $plugin;
                }
            }
        }

        ### FIXME: subclasses also. Loop the other way, go through
        ### the types we know about and see if $object->isa(...)
        ### rather than hard-coding the ref($object).
        if (my $plugin = $handled_by_plugin{ref($object)}) {
            return _summarise_object_as_string($object,
                $plugin->tersify($object));
        }
        return $object;
    }
}

sub _summarise_object_as_string {
    my ($object, $string) = @_;
    my $summary
        = sprintf('%s (0x%x) %s', ref($object), refaddr($object), $string);
    return bless \$summary => 'Data::Tersify::Summary';
}

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same
terms as Perl 5.

=head1 BUGS

If you find any bugs, or have any feature suggestions, please report them
via L<github|https://github.com/skington/data-tersify/issues>.

=head1 SEE ALSO

L<Data::Printer> will tersify data structures as part of its standard
output.

=cut

1;
