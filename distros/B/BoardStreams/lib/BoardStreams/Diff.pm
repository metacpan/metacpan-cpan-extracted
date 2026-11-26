package BoardStreams::Diff;
use v5.44;

our $VERSION = "v0.0.56";

use Exporter 'import';
use Mojo::JSON qw(encode_json);

our @EXPORT_OK = qw(diff patch);

# A diff is undef (no change) or a hash with one of these shapes:
#   { v => $new }                         replace the value
#   { o => { $key => $subdiff, ... },     change keys of an object
#     d => [ $deleted_key, ... ] }
#   { a => [ $item, ... ] }               append items to an array
# The JavaScript client implements the same format in src/diff.ts.

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

    if (ref $old eq 'ARRAY' and ref $new eq 'ARRAY' and @$old and @$new > @$old) {
        my @head = @$new[0 .. $#$old];
        return { a => [@$new[@$old .. $#$new]] } if _json($old) eq _json(\@head);
    }

    return { v => $new };
}

sub patch ($value, $diff) {
    return $value unless $diff;
    return $diff->{v} if exists $diff->{v};
    if (my $items = $diff->{a}) {
        return [@$value, @$items];
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
