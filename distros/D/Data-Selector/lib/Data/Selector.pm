package Data::Selector;

use 5.10.1;
use strict;
use warnings FATAL => 'all';

=head1 NAME

Data::Selector - data selection dsl parser and applicator

=head1 VERSION

1.01

=cut

our $VERSION = '1.01';

=head1 SYNOPSIS

 my $data_tree = {
     foo => {
        bar => { baz1 => 1, baz22 => 2, baz32 => [ 'a', 'b', 'c', ], },
     },
     asdf => 'woohoo',
 };
 Data::Selector->apply_tree(
     {
         selector_tree => Data::Selector->parse_string(
             {
                 named_selectors => { '$bla' => '[non-existent,asdf]', },
                 selector_string => '$bla,foo.bar.baz*2.1..-1',
                 # (same thing with all optional + chars added)
                 # named_selectors => { '$bla' => '[+non-existent,+asdf]', },
                 # selector_string => '$bla,+foo.+bar.+baz*2.+1..-1',
             }
         ),
         data_tree => $data_tree,
     }
 );

 # $data_tree is now:
 # {
 #    foo => { bar => { baz22 => 2, baz32 => [ 'b', 'c', ], }, },
 #    asdf => 'woohoo',
 # }

=head1 DESCRIPTION

This module enables data selection via a terse dsl.  The obvious use case is
data shaping though it could also be used to hint data requirements down the
stack.

A selector string is transformed into a selector tree by parse_string().  Then
the apply_tree() method performs key (array subscripts and hash keys) inclusion,
and/or exclusion on a data tree using the selector tree.  Note that arrays in
the data tree are trimmed of the slots that were removed.

Note that parse_string() will throw some exceptions (in predicate form) but
there are probably many non-sensical selector strings that it won't throw on.
The apply_tree() method, on the other hand, does not throw any exceptions
because in the general case this is preferable.  For example, some typical
"errors" might be missing (misspelled in the selector tree or non-existent in
the data tree) keys or indexing into an array with a string.  Both cases may
legitimately happen when elements of a set are not the same shape.  In the case
of an actual error the resulting data tree will likely reflect it.

=head1 SELECTOR STRINGS

Selector strings are a terse, robust way to express data selection.  They are
sensitive to order of definition, are embeddable via square brackets, can be
constructed of lists of selector strings, and are therefore composable.

A selector string consists of tokens separated by dot characters.  Each dot
character denotes another level in the data tree.  The selector strings may be a
single value or a list of values delimited by square brackets and separated by
commas.

A leading hyphen character indicates exclusion.

An optional leading plus character indicates inclusion.  It is only required for
inclusion of values that start with a hyphen, like a negative array subscript,
or a plus character.

Its important to note that positive array subscripts with a leading + character
are not supported.  For instance, the selector string of "++2" will not
interpreted as "include array subscript 2".  It could be used to include a hash
key of "+2" however.  The same applies to "-+2".  This inconsistency is the
result of a limitation in the implementation and may be changed in the future.

Note that inclusion, in addition to specifying what is to be included, implies a
lower precedence exclusion of all other keys.  In other words, if a particular
key is not specified for inclusion but there was an inclusion then it will be
excluded.  For example, lets say the data tree is a hash with keys foo, bar, and
baz.  A selector string of "foo" will include the foo key and exclude the bar
and baz keys.  But a selector string of "foo,bar" will include the foo and bar
keys and exclude the baz key.

Wildcarding is supported via the asterisk character.

Negative array subscripts are supported but remember that they must be preceded
by a plus character to indicate inclusion (which must be urlencoded as %2B for
urls).  For example, "-1" means "exclude key 1" where "+-1" means "include key
-1".

Array subscript ranges are supported via the double dot sequence.  These can be
tricky when used with negative array subscripts.  For example, "-1..-1" means
exclude 1 to -1.  But "+-2..-1" means include -2 to -1.

Named selectors allow for pre-defined selectors to be interpolated into a
selector_string.  They begin with a dollar character and otherwise can only
contain lower case alpha or underscore characters (a-z,_).

=head2 EXAMPLES

Lets say we have a date tree like so:

 $data_tree = {
     count => 2,
     items => [
         {
             body => 'b1',
             links => [ 'l1', 'l2', 'l3', ],
             rel_1_url => 'foo',
             rel_1_id => 12,
             rel_2_url => 'bar',
             rel_2_id => 34,
         },
         {
             body => 'b2',
             links => [ 'l4', 'l5', ],
             rel_1_url => 'up',
             rel_1_id => 56,
             rel_2_url => 'down',
             rel_2_id => 78,
         },
     ],
     total => 42,
 }

=over

=item total only

 $selector_string = "total";

 $data_tree = {
     total => 42,
 }

=item only rel urls in items

 $selector_string = "items.*.rel_*_url"

 $data_tree = {
     items => [
         {
             rel_1_url => 'foo',
             rel_2_url => 'bar',
         },
         {
             rel_1_url => 'up',
             rel_2_url => 'down',
         },
     ],
 }

=item count and last item with no body

 $selector_string = "count,items.+-1.-body"

 $data_tree = {
     count => 2,
     items => [
         {
             links => [ 'l4', 'l5', ],
             rel_1_url => 'up',
             rel_1_id => 56,
             rel_2_url => 'down',
             rel_2_id => 78,
         },
     ],
 }

=item last 2 links

 $selector_string = "items.*.links.+-2..-1"

 $data_tree = {
     items => [
         {
             links => [ 'l2', 'l3', ],
         },
         {
             links => [ 'l4', 'l5', ],
         },
     ],
 }

=back

=head1 METHODS

=cut

=over

=item parse_string

Creates a selector tree from a selector string.  A map of named selectors can
also be provided which will be interpolated into the selector string before it
is parsed.

Required Args:  selector_string
Optional Args:  named_selectors

=cut

my $selector_string_pattern = qr/
    (
        [^\[\]\,]*+
        (?:
            \[
                (?:
                    [^\[\]]++
                    |
                    (?1)
                )*
            \]
        )?+
    )
    ,?+
/x;

sub parse_string {
    my ( $class, $args, ) = @_;

    die "selector_string required\n"
      unless defined $args->{selector_string}
      && length $args->{selector_string};

    if ( index( $args->{selector_string}, '$', ) != -1 ) {
        $args->{selector_string} =~
          s/(?:(?<=^)|(?<=,))(\$[a-z_]*)(?:(,)(?!$)|$)/
            defined $args->{named_selectors}->{$1}
              && length $args->{named_selectors}->{$1}
              ? $args->{named_selectors}->{$1} . ( $2 ? $2 : '' )
              : die "contains invalid named selector\n";
        /ego;
    }

    my $selector_tree = {};
    my @queue = ( [ $args->{selector_string}, $selector_tree, [], ], );

    die "must be a string that matches /[^.\[\],]/\n"
      if length $args->{selector_string}
      && $args->{selector_string} !~ /[^.\[\],]/o;
    die "must not contain ']['\n" if index( $queue[0]->[0], '][' ) != -1;
    die "must not contain '[]'\n" if index( $queue[0]->[0], '[]' ) != -1;
    die "must not contain '[,'\n" if index( $queue[0]->[0], '[,' ) != -1;
    die "must not contain ',]'\n" if index( $queue[0]->[0], ',]' ) != -1;
    die "must not contain '[.'\n" if index( $queue[0]->[0], '[.' ) != -1;
    die "must not contain '.]'\n" if index( $queue[0]->[0], '.]' ) != -1;
    die "must not begin with','\n" if substr( $queue[0]->[0], 0, 1 ) eq ',';
    die "must not end with','\n"   if substr( $queue[0]->[0], -1, ) eq ',';
    die "must not begin with'.'\n" if substr( $queue[0]->[0], 0, 1 ) eq '.';
    die "must not end with'.'\n"   if substr( $queue[0]->[0], -1, ) eq '.';
    die "must have balanced [] chars\n"
      unless $queue[0]->[0] =~ tr/[/[/ == $queue[0]->[0] =~ tr/]/]/;
    die "must not match /[^.,]\[/\n"
      if $args->{selector_string} =~ /[^.,]\[/o;
    die "must not match /\][^.,\]]/\n"
      if $args->{selector_string} =~ /\][^.,\]]/o;

    my $order;
    while (@queue) {
        my $token  = shift @queue;
        my @groups = $token->[0] =~ /$selector_string_pattern/go;
        pop @groups;

        my ( $shift_a_suffix, $prev_is_suffix, );
        for my $string (@groups) {
            my $sub_tree = $token->[1];

            my $is_suffix = substr( $string, 0, 1, ) eq '.';
            if ($is_suffix) {
                push( @{ $queue[-1]->[2] }, substr( $string, 1, ), );
                $string = '';
            }
            else {
                my $opening_bracket_pos = index( $string, '[' );

                my $dot_in_prefix_pos = index( $string, '.' );
                $dot_in_prefix_pos = -1
                  if $opening_bracket_pos > -1
                  && $dot_in_prefix_pos > $opening_bracket_pos;

                if ( $dot_in_prefix_pos > -1 ) {
                    my $is_range =
                      substr( $string, $dot_in_prefix_pos + 1, 1 ) eq '.';
                    if ($is_range) {
                        $dot_in_prefix_pos =
                          index( $string, '.', $dot_in_prefix_pos + 2, );
                        $dot_in_prefix_pos = -1
                          if $opening_bracket_pos > -1
                          && $dot_in_prefix_pos > $opening_bracket_pos;
                    }
                }

                my $bare = '';
                if ( $dot_in_prefix_pos >= 1 ) {
                    $bare = substr( $string, 0, $dot_in_prefix_pos + 1, '' );
                    chop $bare;
                    $string =
                      substr( $string,
                        $opening_bracket_pos - $dot_in_prefix_pos, -1 )
                      if $dot_in_prefix_pos + 1 == $opening_bracket_pos;
                }
                elsif ( $opening_bracket_pos == 0 ) {
                    $string = substr( $string, $opening_bracket_pos + 1, -1 );
                }
                else {
                    $bare   = $string;
                    $string = '';
                }

                if ( length $bare ) {
                    my $first_char = substr( $bare, 0, 1, );
                    $bare = "+$bare"
                      if $first_char ne "+" && $first_char ne "-";
                    my $bare_inverse =
                      ( $first_char eq "-" ? "+" : "-" ) . substr( $bare, 1, );
                    delete $sub_tree->{$bare_inverse};
                    if ( $sub_tree->{$bare} ) {
                        $sub_tree->{$bare}->{_order_} = ++$order;
                    }
                    else { $sub_tree->{$bare} = { _order_ => ++$order, }; }
                    $sub_tree = $sub_tree->{$bare};
                }

                if ( !length $string && !$prev_is_suffix && @{ $token->[2] } ) {
                    $string = $token->[2]->[0];
                    $shift_a_suffix++;
                }
            }

            push(
                @queue,
                [
                    $string, $sub_tree,
                    ( !$is_suffix && !$prev_is_suffix ? $token->[2] : [] ),
                ],
            ) if length $string;

            $prev_is_suffix = $is_suffix;
        }
        shift @{ $token->[2] } if $shift_a_suffix;
    }

    return $selector_tree;
}

=item apply_tree

Include or exclude parts of a data tree as specified by a selector tree.  Note
that arrays that have elements excluded, or removed, will be trimmed.

Required Args:  selector_tree, data_tree

=back

=cut

sub apply_tree {
    my ( $class, $args, ) = @_;

    die "selector_tree required" unless $args->{selector_tree};
    die "data_tree required"     unless $args->{data_tree};

    my @queue = ( [ $args->{selector_tree}, $args->{data_tree}, ], );
    my %selector_trees_keys;
    while (@queue) {
        my ( $selector_tree, $data_tree, ) = @{ shift @queue };

        # Compile the selector tree keys and cache them sans any data tree
        # dependencies.  At this point each entry will contain:
        #
        # [ $selector_tree_key, $selector_tree_key_base, $pattern,
        #   $array_range, $original_selector_tree_key, $original_selector_tree ]
        #
        # Note that the array range and original selector tree key slots
        # will always be undef at this point because they depend on the
        # data tree.  The original selector tree key is used to store a
        # non-translated negative array subscript.  During data tree based
        # compilation below the two slots may be changed, if applicable.
        #
        # The ref to the original selector tree prevents its untimely
        # destruction which may lead to its refaddr being recycled.  That's
        # undesirable since we use said refaddr as the key for this cache.  I
        # don't know how to reliably test for this so extra care is appropriate.
        $selector_trees_keys{$selector_tree} ||= [
            map {
                my $selector_tree_key_base = substr( $_, 1, );
                [
                    $_,
                    $selector_tree_key_base,
                    index( $selector_tree_key_base, '*', ) != -1
                    ? do {
                        my $pattern = quotemeta $selector_tree_key_base;
                        $pattern =~ s/\\\*/.*/go;
                        $pattern;
                      }
                    : undef,
                    undef,
                    undef,
                    $selector_tree,
                ];
              }
              sort {
                $selector_tree->{$a}->{_order_}
                  <=> $selector_tree->{$b}->{_order_};
              } grep { $_ ne '_order_'; }
              keys %{$selector_tree}
        ];

        my $data_tree_type = ref $data_tree;
        my @data_tree_keys =
          $data_tree_type eq 'HASH'
          ? keys %{$data_tree}
          : 0 .. $#{$data_tree};

        # Take a copy of the selector tree keys and do any data tree based
        # compilation.
        my @selector_tree_keys = @{ $selector_trees_keys{$selector_tree} };
        my $has_includes;
        for (@selector_tree_keys) {
            $has_includes = 1
              if !$has_includes && index( $_->[0], '+', ) == 0;
            if ( index( $_->[0], '+-', ) == 0 || index( $_->[0], '--', ) == 0 )
            {
                if ( $_->[0] =~ /^(\+|-)(-\d+)$/o ) {
                    $_->[4] = $_->[0];
                    $_->[0] = $2 < 0 && $2 >= -@{$data_tree}
                      ? $_->[0] = $1 . ( @{$data_tree} + $2 )
                      : $1 . substr( $2, 1, );
                    $_->[1] = substr( $_->[0], 1, );
                }
            }

            if ( $data_tree_type eq 'ARRAY' && index( $_->[0], '..', ) != -1 ) {
                my @array_range = $_->[0] =~ /^(?:\+|-)(-?\d+)\.\.(-?\d+)$/o;
                map { $_ = @{$data_tree} + $_ if $_ < 0; } @array_range;
                $_->[3] = \@array_range;
            }
        }

        # Match up data tree keys with selector tree keys.
        my %matching_selector_keys_by_data_key;
        my $data_tree_keys_string = join( "\n", @data_tree_keys, ) . "\n";
        for (@selector_tree_keys) {
            my $selector_tree_key_pattern =
                defined $_->[3] ? join( '|', $_->[3]->[0] .. $_->[3]->[1], )
              : defined $_->[2] ? $_->[2]
              : defined $_->[1] ? quotemeta $_->[1]
              :                   undef;
            my @matches =
              $data_tree_keys_string =~ /($selector_tree_key_pattern)\n/g;
            for my $data_tree_key (@matches) {
                push(
                    @{ $matching_selector_keys_by_data_key{$data_tree_key} },
                    $_->[4] // $_->[0],
                );
            }
        }

        # Execute on matches.  Exclusions are done immediately which includes
        # marking arrays for later trimming.  Inclusions result in new queue
        # entries for any sub trees as well as matched inclusion and deferred
        # exclusion bookkeeping.
        my ( %arrays_to_be_trimmed, %deferred_excludes, %matched_includes, );
        for my $data_tree_key ( keys %matching_selector_keys_by_data_key ) {
            my $matching_selector_keys =
              $matching_selector_keys_by_data_key{$data_tree_key};
            if ( index( $matching_selector_keys->[-1], '-', ) == 0 ) {
                if ( $data_tree_type eq 'HASH' ) {
                    delete $data_tree->{$data_tree_key};
                }
                else {
                    my $ok =
                      eval { $data_tree->[$data_tree_key] = '_to_be_trimmed_'; };
                    $arrays_to_be_trimmed{$data_tree} = $data_tree if $ok;
                }
            }
            else {
                $matched_includes{$data_tree}->{$data_tree_key}++;
                delete $deferred_excludes{$data_tree}->{$data_tree_key};

                my $matched_includes_for_data_tree =
                  $matched_includes{$data_tree};
                my @data_keys_to_be_deferred =
                  grep { !$matched_includes_for_data_tree->{$_}; }
                  @data_tree_keys;
                @{ $deferred_excludes{$data_tree} }{@data_keys_to_be_deferred}
                  = ($data_tree) x @data_keys_to_be_deferred;

                my $data_sub_tree =
                    $data_tree_type eq 'HASH'
                  ? $data_tree->{$data_tree_key}
                  : eval { $data_tree->[$data_tree_key] };

                # Using {%{}} to catch non-existance with fatal error.  Can be
                # taken out for space and/or speed savings at cost of "safety".
                my $selector_sub_tree =
                  @{$matching_selector_keys} == 1
                  ? { %{ $selector_tree->{ $matching_selector_keys->[0] } } }
                  : {
                    map { %{ $selector_tree->{$_} }; }
                      @{$matching_selector_keys},
                  };

                push( @queue, [ $selector_sub_tree, $data_sub_tree, ] )
                  if ref $data_sub_tree && grep { $_ ne '_order_'; }
                  keys %{$selector_sub_tree};
            }
        }

        # Add deferred exclusions for all data keys if there were inclusions but
        # none matched.
        if ( $has_includes && !%matched_includes ) {
            $deferred_excludes{$data_tree}->{$_} = $data_tree
              for @data_tree_keys;
        }

        # Execute deferred exclusions.
        for my $data_tree_string ( keys %deferred_excludes ) {
            my @data_tree_keys =
              keys %{ $deferred_excludes{$data_tree_string} };
            if (@data_tree_keys) {
                my $data_tree =
                  $deferred_excludes{$data_tree_string}->{ $data_tree_keys[0] };
                my $data_tree_type = ref $data_tree;
                next unless $data_tree_type;

                if ( $data_tree_type eq 'HASH' ) {
                    delete @{$data_tree}{@data_tree_keys};
                }
                else {
                    my $ok = eval {
                        @{$data_tree}[@data_tree_keys] =
                          ('_to_be_trimmed_') x @data_tree_keys;
                    };
                    $arrays_to_be_trimmed{$data_tree} = $data_tree if $ok;
                }
            }
        }

        # Trim arrays of slots that fell victim to exclusion.
        for my $array ( values %arrays_to_be_trimmed ) {
            @{$array} =
              map { $_ eq '_to_be_trimmed_' ? () : $_; } @{$array};
        }
    }

    return;
}

=head1 AUTHOR

Justin DeVuyst, C<justin@devuyst.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2015 by Justin DeVuyst.

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
