package Data::Overlay;

use 5.10.0; # for //
use warnings;
use strict;
use Carp qw(cluck confess);
use Scalar::Util qw(reftype refaddr blessed);
use List::Util qw(reduce max);
use List::MoreUtils qw(part);
use Sub::Name qw(subname);
use Exporter 'import';
# Data::Dumper lazy loaded when debugging

our $VERSION = '0.54';
$VERSION = eval $VERSION; ## no critic

our @EXPORT = qw(overlay);
our @EXPORT_OK = qw(overlay overlay_all compose combine_with);

=head1 NAME

Data::Overlay - merge/overlay data with composable changes

=head1 VERSION

Data::Overlay version 0.54 - ALPHA, no compatibility promises, seriously

=head1 SYNOPSIS

#!perl -s
#line 31

    use strict; use warnings;
    use Data::Overlay qw(overlay compose);
    use Data::Dumper;
    $Data::Dumper::Sortkeys = 1;

    my $data_structure = {
        a => 123,
        b => {
            w => [ "some", "content" ],
            x => "hello",
            y => \"world",
        },
        c => [ 4, 5, 6],
        d => { da => [], db => undef, dc => qr/abc/ },
    };

    my %changes = (
        f  => 0,                    # add top level key
        a  => '1, 2, 3',            # overwrite key
        b  => { z => '!'  },        # nested operation
        c  => { '=unshift' => 3.5 },# prepend array
        c  => { '=push' => 7 },     # append array
        d  => { da => [ "DA" ],     # replace w/ differing type
                db => {
                    '=defor' => 123,  # only update if undef
                },
              },
    );

    # apply %changes to $data_structure (read-only ok),
    # returning a new data structure sharing unchanged data with the old
    my $new_data_structure = overlay($data_structure, \%changes);

    # Note sharing shown by Dumper
    print Dumper($data_structure, \%changes, $new_data_structure);

__END__

=head2 Running SYNOPSIS

Once Data::Overlay is installed, you can run it with either:

    perl -x -MData::Overlay `pmpath Data::Overlay`

    perl -x -MData::Overlay \
        `perl -MData::Overlay -le 'print $INC{"Data/Overlay.pm"}'`

=head1 DESCRIPTION

=head2 Basic Idea

The overlay functions can be used to apply a group of changes
(also called an overlay) to a data structure, non-destructively,
returning a shallow-ish copy with the changes applied.
"Shallow-ish" meaning shallow copies at each level along
the path of the deeper changes.

  $result = overlay($original, $overlay);

The algorithm walks the overlay structure, either taking
values from it, or when nothing has changed, retaining the
values of the original data structure.  This means that the
only the overlay fully traversed.

When the overlay is doesn't use any special Data::Overlay
keys (ones starting with "="), then the result will be
the merger of the original and the overlay, with the overlay
taking precedence.  In particular, only hashes will really
be merged, somewhat like C<< %new = (%defaults, %options) >>,
but recursively.  This means that array refs, scalars, code,
etc. will be replace whatever is in the original, regardless
of the original type (so an array in the overlay will take
precedence over an array, hash or scalar in the original).
That's why it's not called Data::Underlay.

Any different merging behaviour needs to be marked with
special keys in the overlay called "actions".  These start
with an "=" sign.  (Double it in the overlay to have an actual
leading "=" in the result).  The actions are described below,
but they combine the original and overlay in various ways,
pushing/unshifting arrays, only overwriting false or undefined,
up to providing ability to write your own combining callback.

=head2 Reference Sharing

Data::Overlay tries to minimize copying and so will try
to share references between the new structure and the old structure
and overlay.  This means that changing any of these is likely
to produce unintended consequences.  This sharing is only
practical when the data structures are either read-only or
cloned immediately after overlaying (Cloner not included).

=head1 GLOSSARY

  overlay
       v : put something on top of something else
       n : layer put on top of something else

  $ds, $old_ds, $new_ds - arbitrary, nested Perl data-structures

=cut

my %action_map; # initialized below
my @action_order;

my $default_conf = {
        action_map  => \%action_map,
        action_order => \@action_order,
        debug       => undef,
        #debug_actions => {},
        #state      => {},
        #protocol   => {},
    };

@action_order = qw(config overwrite delete defor or defaults
                   unshift push
                   shift   pop
                   foreach seq run);

sub _sort_actions {
    my ($actions, $conf) = @_;

    return @$actions if @$actions == 1; # pre-optimizing..

    # conf changes may override action_order, recalc rank
    my %action_rank;
    my $i = 1;
    for my $action (@{ $conf->{action_order} }) {
        $action_rank{"=$action"} = $i++;
    }

    ## no critic (we have list context for sort)
    return sort {
        # unknown actions last
        ($action_rank{$a} || 9999) <=> ($action_rank{$b} || 9999)
    } @$actions;
}

sub _isreftype {
    my ($type, $maybe_ref) = @_;
    return 0 if blessed($maybe_ref);
    return reftype($maybe_ref) && reftype($maybe_ref) eq $type;
}

=head1 INTERFACE

=head2 overlay

    $new_ds = overlay($old_ds, $overlay);

Apply an overlay to $old_ds, returning $new_ds as the result.

$old_ds is unchanged.  $new_ds may share references to parts
of $old_ds and $overlay (see L<Reference Sharing>).  If this isn't desired
then clone $new_ds.

=cut

sub overlay {
    my ($ds, $overlay, $conf) = @_;
    $conf ||= $default_conf;

    if (_isreftype(HASH => $overlay)) {

        # trivial case: overlay is {}
        if (!keys %$overlay) { # empty overlay
            return $ds; # leave $ds alone
        }

        # = is action (== is key with leading = "escaped")
        my ($overlay_keys, $actions, $escaped_keys) =
                    part { /^(==?)/ && length $1 } keys %$overlay;

        # part might leave undefs
        $_ ||= [] for ($overlay_keys, $actions, $escaped_keys);

        # 0-level $ds copy for actions that operate on $new_ds as a whole
        # ($new_ds need not be a HASH here)
        my $new_ds = $ds; # don't use $ds anymore, $new_ds instead

        # apply each action in order to $new_ds, sequentially
        # (note that some items really need to nest inner overlays
        #  to be useful, eg. config applies only in a dynamic scope
        #  to children under "data", not to peers)
        for my $action_key (_sort_actions($actions, $conf)) {
            my ($action) = ($action_key =~ /^=(.*)/);
            my $callback = $conf->{action_map}{$action};
            die "No action '$action' in action_map" unless $callback;
            $new_ds = $callback->($new_ds, $overlay->{$action_key}, $conf);
        }

        # return if there are only actions, no plain keys
        # ( important for overlaying scalars, eg. a: 1 +++ a: =defor 1 )
        return $new_ds unless @$overlay_keys || @$escaped_keys;

        # There are non-action keys in overlay, so insist on a $new_ds hash
        # (Shallow copy $new_ds in case it is a reference to $ds)
        if (_isreftype(HASH => $new_ds)) {
            $new_ds = { %$new_ds }; # shallow copy
        } else {
            $new_ds = {}; # $new_ds is not a HASH ($ds wasn't), must become one
        }

        # apply overlay_keys to $new_ds
        for my $key (@$overlay_keys) {
            $new_ds->{$key} =
                overlay($new_ds->{$key}, $overlay->{$key}, $conf);
        }

        # apply any escaped_keys in overlay to $new_ds
        for my $escaped_key (@$escaped_keys) {
            my ($actual_key) = ($escaped_key =~ /^=(=.*)/);

            $new_ds->{$actual_key} =
               overlay($new_ds->{$actual_key}, $overlay->{$escaped_key}, $conf);
        }

        return $new_ds;
    } else {
        # all scalars, blessed and non-HASH overlay elements are 'overwrite'
        # (by default, you could intercept all and do other things...)
        my $callback = $conf->{action_map}{overwrite};
        die "No action 'overwrite' in action_map" unless $callback;
        return $callback->($ds, $overlay, $conf);
    }

    confess "A return is missing somewhere";
}

=head2 overlay_all

    $new_ds = overlay_all($old_ds, $overlay1, $overlay2, ...);

Apply several overlays to $old_ds, returning $new_ds as the result.
They are logically applied left to right, that is $overlay1,
then overlay2, etc.  (Internally C<compose> is used, see next)

=cut

sub overlay_all {
    my ($ds, @overlays) = @_;

    return overlay($ds, compose(@overlays));
}

=head2 compose

    $combined_overlay = compose($overlay1, $overlay2, ..);

Produce an overlay that has the combined effect of applying
$overlay1 then $overlay2, etc.

=cut

sub compose {
    my (@overlays) = @_;

    # rubbish dumb merger XXX
    return { '=seq' => \@overlays };
}

=head2 combine_with

    $combiner_sub = combine_with { $a && $b };
    my $conf = { action_map => {
                    and => $combiner_sub
                 } };
    my $new = overlay($this, $that, $conf);

Utility to build simple overlay actions.  For example, the included
"or" is just:

    combine_with { $a || $b};

$a is the old_ds parameter, $b is the overlay parameter.
@_ contains the rest of the arguments.

=cut
#$action_map{defor} = combine_with { $a // $b};
sub combine_with (&@) { ## no critic
    my ($code) = shift;

    return sub {
        local ($a) = shift; # $old_ds
        local ($b) = shift; # $overlay
        return $code->(@_); # $conf (remainder of args in @_)
    };
}

=head2 Actions

=over 4

=cut

=item config

=cut

$action_map{config} = sub {
    my ($old_ds, $overlay, $old_conf) = @_;

    #my $new_conf = overlay($old_conf, $overlay->{conf}, $old_conf);
    # do we really want a config here XXX?
    my $new_conf = overlay($old_conf, $overlay->{conf}); # eat dogfood #1

    # wrap all actions with debug if needed
    if (!defined $old_conf->{debug}
            && $new_conf->{debug} ) {

        # XXX overlay action_map, eat dogfood #2
        my $old_action_map = $new_conf->{action_map};
        my $new_action_map;

        my @actions = keys %$old_action_map;
        if ($new_conf->{debug_actions}) {
            @actions = keys %{ $new_conf->{debug_actions} };
        }

        for my $action (@actions) {
            $new_action_map->{$action} =
                _wrap_debug($action, $old_action_map->{$action});
        }
        $new_conf->{action_map} = $new_action_map;
    }

    return overlay($old_ds, $overlay->{data}, $new_conf);
};

=item overwrite

"Overwrite" the old location with the value of the overwrite key.
This is the default action for non-HASH overlay elements.
(The actual action used in this implicit case and also
the explicit case is $conf->{action_map}{overwrite},
so it can be overriden).

You can also use C<overwrite> explicitly, to overlay an empty
hash (which would otherwise be treated as a keyless, no-op overlay):

  overlay(undef, {});                   # -> undef
  overlay(undef, {'=overwrite'=>{}});   # -> {}

=cut

$action_map{overwrite} = sub {
    my ($old_ds, $overlay, $conf) = @_;
    return $overlay;
};

=item defaults

=cut

$action_map{defaults} = sub {
    my ($old_ds, $overlay, $conf) = @_;

    if (    _isreftype(HASH => $old_ds)
            && _isreftype(HASH => $overlay) ) {
        my %new_ds = %$old_ds; # shallow copy
        for (keys %$overlay) {
            $new_ds{$_} //= $overlay->{$_};
        }
        return \%new_ds;
    } else {
        return $old_ds // $overlay; # only HASHes have defaults
    }
};

=item delete

=cut

$action_map{delete} = sub {
    my ($old_ds, $overlay, $conf) = @_;

    if (       _isreftype(HASH => $old_ds)
            && _isreftype(HASH => $overlay)) {
        # overlay is a set of keys to "delete"
        my %new_ds = %$old_ds;
        delete $new_ds{$_} for (keys %$old_ds);
        return \%new_ds;
    } elsif (  _isreftype(ARRAY => $old_ds)
            && _isreftype(ARRAY => $overlay)) {
        # overlay is a list of indices to "delete"
        my @new_ds = @$old_ds;
        delete $new_ds[$_] for (@$old_ds);
        return \@new_ds;
    } else {
        warn "Container mismatch (ew XXX)";
        return overlay($old_ds, $overlay, $conf);
    }
};

=item defor

Defined or (//) is used to combine the original and overlay

=cut

$action_map{defor} = combine_with { $a // $b};

=item or

=cut

$action_map{or} = combine_with { $a || $b};

=item push

=cut

$action_map{push} = sub {
    my ($old_ds, $overlay) = @_;

    # flatten 1 level of ARRAY
    my @overlay_array = _isreftype(ARRAY => $overlay)
                ? @$overlay : $overlay;

    if (_isreftype(ARRAY => $old_ds)) {
        return [ @$old_ds, @overlay_array ];
    } else {
        return [ $old_ds, @overlay_array ]; # one elem array
    }
};

=item unshift

=cut

$action_map{unshift} = sub {
    my ($old_ds, $overlay) = @_;

    # flatten 1 level of ARRAY
    my @overlay_array = _isreftype(ARRAY => $overlay)
                ? @$overlay : $overlay;

    if (_isreftype(ARRAY => $old_ds)) {
        return [ @overlay_array, @$old_ds ];
    } else {
        return [ @overlay_array, $old_ds ]; # one elem array
    }
};

=item pop

=cut

$action_map{pop} = sub {
    my ($old_ds, $overlay) = @_;
    if (_isreftype(ARRAY => $old_ds)) {
        if (_isreftype(ARRAY => $overlay)) {
            # if pop's arg is ARRAY, use it's size
            # as the number of items to pop
            # (for symmetry with push)
            my $pop_size = @$overlay;
            return [ @{$old_ds}[0..$#$old_ds-$pop_size] ];
        } else {
            return [ @{$old_ds}[0..$#$old_ds-1] ];
        }
    } else {
        return [ ]; # pop "one elem array", or zero
    }
};

=item shift

=cut

$action_map{shift} = sub {
    my ($old_ds, $overlay) = @_;
    if (_isreftype(ARRAY => $old_ds)) {
        if (_isreftype(ARRAY => $overlay)) {
            # if pop's arg is ARRAY, use it's size
            # as the number of items to pop
            # (for symmetry with push)
            my $shift_size = @$overlay;
            return [ @{$old_ds}[$shift_size..$#$old_ds] ];
        } else {
            return [ @{$old_ds}[1..$#$old_ds] ];
        }
    } else {
        return [ ]; # shift "one elem array", or zero
    }
};

=item run

      '=run' => {
        code => sub {
            my ($old_ds, @args) = @_;
            ...;
            return $result;
        },
        args => [ ... ], # optional argument list
      }

=cut

$action_map{run} = sub {
    my ($old_ds, $overlay) = @_;
    return $overlay->{code}->($old_ds, @{ $overlay->{args} || [] });
};

=item foreach

Apply one overlay to all elements of an array or values of a hash
(or just a scalar).  Often useful with =run if the overlay is
a function of the original value.

=cut

# XXX each with (k,v) or [i,...]
$action_map{foreach} = sub {
    my ($old_ds, $overlay, $conf) = @_;
    if (_isreftype(ARRAY => $old_ds)) {
        return [
            map { overlay($_, $overlay, $conf) } @$old_ds
        ];
    } elsif (_isreftype(HASH => $old_ds)) {
        return {
            map {
                $_ => overlay($old_ds->{$_}, $overlay, $conf)
            } keys %$old_ds
        };
    } else {
        return overlay($old_ds, $overlay, $conf);
    }
};

=item seq

Apply in sequence an array of overlays.

=cut

$action_map{seq} = sub {
    my ($old_ds, $overlay, $conf) = @_;
    # XXX reftype $overlay
    my $ds = $old_ds;
    for my $ol (@$overlay) {
        $ds = overlay($ds, $ol, $conf);
    }
    return $ds;
};

=back

=cut

for my $action (keys %action_map) {
    # debuggable names for callbacks (not the used perl names)
    subname "$action-overlay", $action_map{$action};

    # XXX
    warn "$action not in \@action_order"
        if ! grep { $action eq $_ } @action_order;
}

sub _wrap_debug {
    my ($action_name, $inner_sub) = @_;

    my $s = subname "$action_name-debug", sub {
        my ($old_ds, $overlay, $conf) = @_;

        my $debug = max($conf->{debug},
                        (   ref($conf->{debug_actions})
                         && $conf->{debug_actions}{$action_name} ));
        if ($debug) {
            warn "Calling $action_name $inner_sub\n";
            warn "  with ", _dt($overlay), "\n" if $debug >= 1;
            warn "    conf ", _dt({map { "$_" } %$conf}), "\n" if $debug >= 2;
            cluck " CALL STACK" if $debug >= 3;
        }
        my $result = $inner_sub->($old_ds, $overlay, $conf);
        if ($debug) {
            warn " Back from $action_name\n";
            warn "  got ", _dt($result), "\n" if $debug >= 2;
        }
        return $result;
    };
    warn "Wrapped $inner_sub with $s";

    return $s;
}


sub _dt {
    require Data::Dumper;
    my $dumper = Data::Dumper->new( map [$_], @_ );
    $dumper->Indent(0)->Terse(1);
    $dumper->Sortkeys(1) if $dumper->can("Sortkeys");
    return $dumper->Dump;
}


__PACKAGE__; # true return
__END__

exists
delete

and/if/ifthen replace if $ds is true
sprintf prepend_str append_str interpolate $_
splice grep map sort
+/-/*/++/--/x/%/**/./<</>>
| & ^ ~ masks boolean logic
conditionals? comparison?
deref?
invert apply inverted
swap overlay and ds roles
splitting one ds val into multiple new_ds?
regex matching and extraction
pack/unpack
const?
Objects?
x eval too dangerous
grep


       Functions for SCALARs or strings
           "chomp", "chop", "chr", "crypt", "hex", "index", "lc", "lcfirst",
           "length", "oct", "ord", "pack", "q//", "qq//", "reverse", "rindex",
           "sprintf", "substr", "tr///", "uc", "ucfirst", "y///"

=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 Cookbook and Serving Suggestions

Some made up use-cases.

=head2 Configuration Data Merging

 overlay_all($defaults, $host_conf, $app_conf, $user_conf, $cmd_line_conf);

=head2 List of Undoable Edits

Use the memory sharing to keep a sequence of persistent data structures.
"Persistent" in the functional programming sense, you can
access (read-only) old and new versions.

=head2 Circular References in Overlays

There is no protection against reference cycles in overlays.

L<Devel::Cycle> or L<Data::Structure::Util> may help.

=head2 Unsharing Data with Clone

If you don't want any sharing of data between the result and
source or overlay, then use a clone.
Either L<Storable>'s dclone or L<Clone>

    $new_clone = dclone(overlay($old, $overlay));

=head2 Escaping "=" Keys

Rmap

=head2 Writing Your Own Callbacks

Note that while most of the names of core actions are based
on mutating perl functions, their implementation is careful
to do shallow copies.

=head2 Readonly for Testing

The Readonly module is useful for testing that nothing is
changing data that is supposed to be Readonly.

=head2 Sharing State in Callbacks

Shared lexical variables.

=head2 Where Are The Objects?

This is a bit of an experiment in using data immutability, persistence
and sharing instead of using OO conventions to manage changing state.
(This approach doesn't hit all of the OO targets, but Data::Overlay's
subset may be useful).

Blessed references are treated as opaque object by default (not overlaid).
(Encapsulation was ignored in developer release 0.53 and earlier).

=head1 DEPENDENCIES

L<List::MoreUtils>, L<Sub::Name>

=head1 BUGS AND LIMITATIONS

I'm happy to hear suggestions, please email them or use RT
in addition to using cpan ratings or annocpan (I'll notice them faster).

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-data-edit@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 SEE ALSO

Merging of nested data structures:

=over

=item * L<Hash::Merge> merge with global options

=item * L<Data::Utilities> (L<Data::Merger>) merge with call-time options

=item * L<Data::Nested> merging (per application options), paths and schemas

=item * L<Data::ModeMerge>

"Mode" (overwrite/add/default) is in the data merged, like Data::Overlay.
Uses special characters to indicate the action performed.  Also permits
local config overrides and extensions.

=back

Potential overlay builders, modules that could be used to build
overlays for data:

=over

=item * L<CGI::Expand>

Build nested hashes from a flat path hash:

    use CGI::Expand qw(expand_hash);

    my $overlay = expand_hash({"a.b.c"=>1,"a.b.d"=>[2,3]})
    # = {'a' => {'b' => {'c' => 1,'d' => [1,2,3]}}};

L<Hash::Flatten> also has an unflatten function.

=back

Lazy deep copying nested data:

=over

=item * L<Data::COW> - Copy on write

=back

Data structure differences:

=over

=item * L<Data::Diff>

=item * L<Data::Utilities> (L<Data::Comparator>)

=item * L<Data::Rx> schema checking

=item * L<Test::Deep>

=back

L<autovivification> can avoid nested accesses creating intermediate keys.

There some overlap between what this module is trying to do
and both the darcs "theory of patches", and operational
transforms.  The overlap is mainly around composing changes,
but there's nothing particularly concurrent about Data::Overlay.
Also, patches and operations have more context and are invertible.

=head1 KEYWORDS

Merge, edit, overlay, clone, modify, transform, memory sharing, COW,
operational transform, patch.

So an SEO expert walks into a bar, tavern, pub...

=head1 AUTHOR

Brad Bowman  C<< <cpan@bereft.net> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2011, Brad Bowman C<< <cpan@bereft.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
