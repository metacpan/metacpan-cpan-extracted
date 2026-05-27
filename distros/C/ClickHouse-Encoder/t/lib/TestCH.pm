package TestCH;
# Shared test helpers: varint readers (value-form and ref-form) and a
# block-header skipper for single-column Native blocks.
use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(read_varint read_varint_ref skip_header split_paren_list);

# Value form: read a LEB128 varint from $buf at $off, return ($value, $new_off).
sub read_varint {
    my ($buf, $off) = @_;
    my $n = 0;
    my $shift = 0;
    while (1) {
        my $b = ord(substr($buf, $off++, 1));
        $n |= ($b & 0x7F) << $shift;
        last unless $b & 0x80;
        $shift += 7;
    }
    return ($n, $off);
}

# Ref form: same parse but takes scalar refs and mutates $$off; returns the
# value only. Convenient when threading $off through many sequential reads.
sub read_varint_ref {
    my ($buf_ref, $off_ref) = @_;
    my $n = 0;
    my $shift = 0;
    while (1) {
        my $b = ord(substr($$buf_ref, $$off_ref++, 1));
        $n |= ($b & 0x7F) << $shift;
        last unless $b & 0x80;
        $shift += 7;
    }
    return $n;
}

# Split a comma-separated list at top level only, respecting parentheses.
# Used by test-side type-spec parsers (Tuple(Int32, Nullable(String)) etc.).
sub split_paren_list {
    my ($body) = @_;
    my @parts;
    my $start = 0;
    my $depth = 0;
    my $len = length $body;
    for (my $i = 0; $i <= $len; $i++) {
        my $c = $i < $len ? substr($body, $i, 1) : ',';
        if    ($c eq '(') { $depth++ }
        elsif ($c eq ')') { $depth-- }
        elsif ($c eq ',' && $depth == 0) {
            my $p = substr($body, $start, $i - $start);
            $p =~ s/\A\s+|\s+\z//g;
            push @parts, $p if length $p;
            $start = $i + 1;
        }
    }
    return @parts;
}

# Skip past the block header (ncols, nrows, col_name, col_type) and return
# the offset where the first column's data starts. Single-column blocks only.
sub skip_header {
    my ($buf) = @_;
    my $off = 0;
    read_varint_ref(\$buf, \$off);          # ncols
    read_varint_ref(\$buf, \$off);          # nrows
    my $name_len = read_varint_ref(\$buf, \$off); $off += $name_len;
    my $type_len = read_varint_ref(\$buf, \$off); $off += $type_len;
    return $off;
}

1;
