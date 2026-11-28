package BoardStreams::Diff;
use v5.44;

our $VERSION = "v0.0.60";

use Exporter 'import';
use Mojo::JSON qw(encode_json);

our @EXPORT_OK = qw(diff patch);

# A diff is undef (no change) or a hash with one of these shapes:
#   { v => $new }                         replace the value
#   { o => { $key => $subdiff, ... },     change keys of an object
#     d => [ $deleted_key, ... ] }
#   { s => [ $start, $end ],              change the ends of an array: keep
#     p => [ $item, ... ],                the old items from index $start up
#     a => [ $item, ... ] }               to, not including, $end (all of
#                                         them without "s"), put the "p"
#                                         items before them and the "a"
#                                         items after them
# Each of "s", "p" and "a" is left out when it has nothing to say, so a
# push is { a => [...] }, a pop { s => [0, $n - 1] }, a shift
# { s => [1, $n] } and an unshift { p => [...] }, and they combine.
# The JavaScript client implements the same format in src/diff.ts.

# How many places a run of old items is looked for in the new array.
use constant ARRAY_TRIES => 8;

sub diff ($old, $new) {
    if (ref $old eq 'HASH' and ref $new eq 'HASH') {
        my %changed;
        for my $key (keys %$new) {
            if (exists $old->{$key}) {
                my $sub = diff($old->{$key}, $new->{$key});
                $changed{$key} = $sub if $sub;
            }
            else {
                $changed{$key} = { v => $new->{$key} };
            }
        }
        my @deleted = sort grep { !exists $new->{$_} } keys %$old;
        return undef unless %changed or @deleted;
        return {
            (%changed ? (o => \%changed) : ()),
            (@deleted ? (d => \@deleted) : ()),
        };
    }

    return undef if _json($old) eq _json($new);

    if (ref $old eq 'ARRAY' and ref $new eq 'ARRAY' and @$old and @$new) {
        my $ends = _array_diff($old, $new);
        return $ends if $ends;
    }

    return { v => $new };
}

# The diff for an array whose ends changed while a run of its items stayed
# as it was: what push, pop, shift and unshift do, alone or together.
# Returns nothing if no such run is found. The run has to start with the
# first old item or with the first new one, which leaves out only an array
# that lost items at its start and gained others there at the same time.
sub _array_diff ($old, $new) {
    my @was = map { _json($_) } @$old;
    my @is  = map { _json($_) } @$new;
    my ($kept, $from, $at) = (0, 0, 0);    # length of the run, where it starts in old, and in new
    my $consider = sub ($start, $position) {
        my $run = 0;
        $run++ while $start + $run < @was and $position + $run < @is and $was[$start + $run] eq $is[$position + $run];
        ($kept, $from, $at) = ($run, $start, $position) if $run > $kept;
    };
    # The old array from its first item on, wherever that is now: at the
    # start (push, pop) or further in (unshift).
    my @positions = grep { $is[$_] eq $was[0] } 0 .. $#is;
    $consider->(0, $_) for splice @positions, 0, ARRAY_TRIES;
    # The new array from its first item on, wherever that was: shift.
    my @starts = grep { $was[$_] eq $is[0] } 1 .. $#was;
    $consider->($_, 0) for splice @starts, 0, ARRAY_TRIES;
    return undef unless $kept;
    return {
        ($kept < @was       ? (s => [$from, $from + $kept])            : ()),
        ($at                ? (p => [@$new[0 .. $at - 1]])             : ()),
        ($at + $kept < @is  ? (a => [@$new[$at + $kept .. $#$new]])    : ()),
    };
}

sub patch ($value, $diff) {
    return $value unless $diff;
    return $diff->{v} if exists $diff->{v};
    if ($diff->{s} or $diff->{p} or $diff->{a}) {
        my ($start, $end) = $diff->{s} ? $diff->{s}->@* : (0, scalar @$value);
        return [@{ $diff->{p} // [] }, @$value[$start .. $end - 1], @{ $diff->{a} // [] }];
    }
    my %copy = %$value;
    delete @copy{ @{ $diff->{d} // [] } };
    my $changed = $diff->{o} // {};
    $copy{$_} = patch($copy{$_}, $changed->{$_}) for keys %$changed;
    return \%copy;
}

# Mojo::JSON sorts hash keys, so equal structures encode identically.
sub _json ($value) { encode_json([$value]) }

1;
