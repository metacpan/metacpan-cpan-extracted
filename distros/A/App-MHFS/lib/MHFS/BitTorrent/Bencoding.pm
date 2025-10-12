package MHFS::BitTorrent::Bencoding v0.7.0;
use 5.014;
use strict; use warnings;
use Exporter 'import';
our @EXPORT_OK = ('bencode', 'bdecode');
use feature 'say';

# a node is an array with the first element being the type, followed by the value(s)
# ('int', iv)          - integer node, MUST have one integer value, bencoded as iIVe
# ('bstr', bytestring) - byte string node, MUST have one bytestring value, bencoded as bytestringLength:bytestring where bytestringLength is the length as ASCII numbers
# ('l', values)        - list node, MAY have one or more values of type int, bstr, list, and dict bencoded as lVALUESe
# ('d', kvpairs)       - dict node, special case of list, MAY one or more key and value pairs. A dict node MUST have multiple of 2 values; a bstr key with corespoding value
# ('null', value)      - null node, MAY have one value, used internally by bdecode to avoid dealing with the base case of no parent
# ('e')                - end node, MUST NOT have ANY values, used internally by bencode to handle writing list/dict end

sub bencode {
    my ($node) = @_;
    my @toenc = ($node);
    my $output;

    while(my $node = shift @toenc) {
        my $type = $node->[0];
        if(($type eq 'd') || ($type eq 'l')) {
            $output .= $type;
            my @nextitems = @{$node};
            shift @nextitems;
            push @nextitems, ['e'];
            unshift @toenc, @nextitems;
        }
        elsif($type eq 'bstr') {
            $output .= sprintf("%u:%s", length($node->[1]), $node->[1]);
        }
        elsif($type eq 'int') {
            $output .= 'i'.$node->[1].'e';
        }
        elsif($type eq 'e') {
            $output .= 'e';
        }
        else {
            return undef;
        }
    }

    return $output;
}

sub bdecode {
    my ($contents, $foffset) = @_;
    my @headnode = ('null');
    my @nodestack = (\@headnode);
    my $startoffset = $foffset;

    while(1) {
        # a bstr is always valid as it can be a dict key
        if(substr($$contents, $foffset) =~ /^(0|[1-9][0-9]*):/) {
            my $count = $1;
            $foffset += length($count)+1;
            my $bstr = substr($$contents, $foffset, $count);
            my $node = ['bstr', $bstr];
            $foffset += $count;
            push @{$nodestack[-1]}, $node;
        }
        elsif((substr($$contents, $foffset, 1) eq 'e') &&
        (($nodestack[-1][0] eq 'l') ||
        (($nodestack[-1][0] eq 'd') &&((scalar(@{$nodestack[-1]}) % 2) == 1)))) {
            pop @nodestack;
            $foffset++;
        }
        elsif(($nodestack[-1][0] ne 'd') || ((scalar(@{$nodestack[-1]}) % 2) == 0)) {
            my $firstchar = substr($$contents, $foffset++, 1);
            if(($firstchar eq 'd') || ($firstchar eq 'l')) {
                my $node = [$firstchar];
                push @{$nodestack[-1]}, $node;
                push @nodestack, $node;
            }
            elsif(substr($$contents, $foffset-1) =~ /^i(0|\-?[1-9][0-9]*)e/) {
                my $node = ['int', $1];
                $foffset += length($1)+1;
                push @{$nodestack[-1]}, $node;
            }
            else {
                say "bad elm $firstchar $foffset";
                return undef;
            }
        }
        else {
            say "bad elm $foffset";
            return undef;
        }

        if(scalar(@nodestack) == 1) {
            return [$headnode[1], $foffset-$startoffset];
        }
    }
}

1;
