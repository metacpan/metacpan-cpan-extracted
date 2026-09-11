package AmberDB::Base::Encoder;

use 5.016;
use warnings;
use Carp qw(croak cluck);
use MIME::Base64 qw(encode_base64 decode_base64);

our $VERSION = '5.25.1';

my $CREATED = '2026-09-06';

# =====================================================================
# RECORD ENCODING / DECODING — ABR v5 (Amber Binary Record)
# Native Pure Perl Binary Format with Zero CPAN Dependencies
# Format Specification:
#   Header:      \x00 A B R \x05  (5 bytes: NUL + Magic "ABR" + Version 5)
#   Mode:        1 byte (0x00 = multiple fields, 0x01 = single root reference)
#   Payload:
#     Mode 0x00: 2 bytes unsigned short "n" (field count) + field nodes
#     Mode 0x01: single root node
#   Node Types (1 byte tag):
#     0x00 -> UNDEF
#     0x01 -> SCALAR_RAW  (4-byte "N" length + raw octets, numbers/ASCII/binary)
#     0x02 -> SCALAR_UTF8 (4-byte "N" length + UTF-8 octets, decoded with utf8::decode)
#     0x03 -> ARRAY       (2-byte "n" count + child nodes)
#     0x04 -> HASH        (2-byte "n" pair count + 2-byte "n" key len + UTF-8 key + child value node)
# =====================================================================

sub _abr_encode_node {
    my ( $self, $node, $depth ) = @_;
    die "AmberDB ABR: Max nesting depth exceeded (>32)\n" if ( $depth // 0 ) > 32;

    if ( !defined $node ) {
        return "\x00";
    }

    my $ref = ref($node);
    if ( !$ref ) {
        my $is_utf8 = utf8::is_utf8($node);
        my $bytes   = "$node";
        utf8::encode($bytes) if $is_utf8;
        return ( $is_utf8 ? "\x02" : "\x01" ) . pack( "N", length($bytes) ) . $bytes;
    }
    elsif ( $ref eq 'ARRAY' ) {
        my $cnt = scalar @$node;
        my $out = "\x03" . pack( "n", $cnt );
        for my $item (@$node) {
            $out .= $self->_abr_encode_node( $item, ( $depth // 0 ) + 1 );
        }
        return $out;
    }
    elsif ( $ref eq 'HASH' ) {
        my @keys = sort keys %$node;
        my $cnt  = scalar @keys;
        my $out  = "\x04" . pack( "n", $cnt );
        for my $k (@keys) {
            my $k_bytes = "$k";
            my $k_utf8  = utf8::is_utf8($k_bytes);
            utf8::encode($k_bytes) if $k_utf8;
            $out .= pack( "n", length($k_bytes) ) . $k_bytes;
            $out .= $self->_abr_encode_node( $node->{$k}, ( $depth // 0 ) + 1 );
        }
        return $out;
    }
    else {
        my $str = "$node";
        return "\x01" . pack( "N", length($str) ) . $str;
    }
}

sub _abr_decode_node {
    my ( $self, $dref, $pref, $depth ) = @_;
    die "AmberDB ABR: Max nesting depth exceeded (>32)\n" if ( $depth // 0 ) > 32;

    return undef if $$pref >= length($$dref);
    my $tag = substr( $$dref, $$pref++, 1 );
    return undef if !defined $tag || $tag eq "\x00";

    if ( $tag eq "\x01" || $tag eq "\x02" ) {
        # SCALAR_RAW / SCALAR_UTF8
        return undef if $$pref + 4 > length($$dref);
        my $len = unpack( "N", substr( $$dref, $$pref, 4 ) );
        $$pref += 4;
        return undef unless defined $len;
        return undef if $$pref + $len > length($$dref);
        my $val = substr( $$dref, $$pref, $len );
        $$pref += $len;
        utf8::decode($val) if $tag eq "\x02";
        return $val;
    }
    elsif ( $tag eq "\x03" ) {
        # ARRAY
        return undef if $$pref + 2 > length($$dref);
        my $cnt = unpack( "n", substr( $$dref, $$pref, 2 ) );
        $$pref += 2;
        return undef unless defined $cnt;
        my @arr;
        for ( 1 .. $cnt ) {
            push @arr, $self->_abr_decode_node( $dref, $pref, ( $depth // 0 ) + 1 );
        }
        return \@arr;
    }
    elsif ( $tag eq "\x04" ) {
        # HASH
        return undef if $$pref + 2 > length($$dref);
        my $cnt = unpack( "n", substr( $$dref, $$pref, 2 ) );
        $$pref += 2;
        return undef unless defined $cnt;
        my %h;
        for ( 1 .. $cnt ) {
            return undef if $$pref + 2 > length($$dref);
            my $klen = unpack( "n", substr( $$dref, $$pref, 2 ) );
            $$pref += 2;
            return undef unless defined $klen;
            return undef if $$pref + $klen > length($$dref);
            my $k = substr( $$dref, $$pref, $klen );
            $$pref += $klen;
            utf8::decode($k);
            $h{$k} = $self->_abr_decode_node( $dref, $pref, ( $depth // 0 ) + 1 );
        }
        return \%h;
    }
    return undef;
}

# my $record  = $adb->db_encode(@fields);
# my $record  = $adb->db_encode(\%hash_data);
# ------------------------------------------------
sub db_encode {
    my ( $self, @fields ) = @_;
    return unless @fields;

    # ROOT CHECK: If single item passed and it is a reference
    if ( @fields == 1 && ref( $fields[0] ) ) {
        return "\x00ABR\x05\x01" . $self->_abr_encode_node( $fields[0], 0 );
    }

    my $out = "\x00ABR\x05\x00" . pack( "n", scalar @fields );
    for my $f (@fields) {
        $out .= $self->_abr_encode_node( $f, 0 );
    }
    return $out;
}

# my @fields   = $adb->db_decode($record);
# my $hash_ref = $adb->db_decode($record);
# ------------------------------------------------
sub db_decode {
    my ( $self, $record ) = @_;
    return unless defined $record && length $record;

    # ABR Binary Check (5-byte magic signature \x00ABR\x05 or \x00ABR\x01)
    if ( length($record) >= 7 && substr( $record, 0, 4 ) eq "\x00ABR" && ( substr( $record, 4, 1 ) eq "\x05" || substr( $record, 4, 1 ) eq "\x01" ) ) {
        my $mode = substr( $record, 5, 1 );
        my $pos  = 6;

        if ( $mode eq "\x01" ) {
            # Single root reference
            return $self->_abr_decode_node( \$record, \$pos, 0 );
        }
        elsif ( $mode eq "\x00" ) {
            # Multiple fields
            my $fcnt = unpack( "n", substr( $record, $pos, 2 ) );
            $pos += 2;
            my @fields;
            for ( 1 .. $fcnt ) {
                push @fields, $self->_abr_decode_node( \$record, \$pos, 0 );
            }
            return wantarray ? @fields : ( @fields == 1 ? $fields[0] : \@fields );
        }
    }

    # TRANSPARENT FALLBACK: Legacy Text Format Decoding
    return $self->tsv_decode($record);
}

# ------------------------------------------------
# tsv_decode: Multi-era decoder for historical and text-based records (v1 - v4)
# ------------------------------------------------
sub tsv_decode {
    my ( $self, $record, $expected_rid ) = @_;
    return () unless defined $record && length($record);

    # If already ABR binary, decode directly via db_decode
    if ( length($record) >= 7 && substr( $record, 0, 4 ) eq "\x00ABR" ) {
        return $self->db_decode($record);
    }

    if ( $self && ref($self) ) {
        $record = $self->utf_decode($record);
    }

    # drop line endings: chomp
    $record =~ s/\R$//;

    # FAST-PATH: Plain TSV record without escapes, entities, or nested tags
    if ( index($record, "\\") == -1 && index($record, "<TAB") == -1 && index($record, "&#") == -1 && index($record, "ARRAY:") == -1 && index($record, "HASH:") == -1 ) {
        my @fields = split( /\t/, $record, -1 );
        return wantarray ? @fields : ( @fields == 1 ? $fields[0] : \@fields );
    }

    # 1. ERA 2019 - 2025: <TAB> Hierarchy (<TAB0>, <TAB1>, <TAB2>, <TAB3>)
    if ( $record =~ /<TAB[0-9]+>/ ) {
        my $white_decode = sub {
            return map {
                my $s = $_;
                if ( defined $s ) {
                    $s =~ s/\\(.)/$1 eq "t" ? "\t" : $1 eq "n" ? "\n" : $1 eq "r" ? "\r" : $1 eq "T" ? "\\T" : $1/eg;
                }
                $s;
            } @_;
        };

        my $rid_prefix;
        if ( $record =~ /^([a-zA-Z0-9_\-\.]+)(?:<TAB0>|\t)(.*)$/s ) {
            my ( $candidate_rid, $rest ) = ( $1, $2 );
            if ( !defined $expected_rid || $candidate_rid eq $expected_rid ) {
                $rid_prefix = $candidate_rid;
                $record     = $rest;
            }
        }

        my @fields = $record =~ /<TAB0>/ ? split( /<TAB0>/, $record, -1 ) : split( /\t/, $record, -1 );
        @fields = $white_decode->(@fields);

        for my $f1 (@fields) {
            if ( defined $f1 && $f1 =~ /<TAB1>/ ) {
                my @sub1 = map { $_ eq '-' ? '' : $_ } split( /<TAB1>/, $f1, -1 );
                @sub1 = $white_decode->(@sub1);
                for my $f2 (@sub1) {
                    if ( defined $f2 && $f2 =~ /<TAB2>/ ) {
                        my @sub2 = map { $_ eq '-' ? '' : $_ } split( /<TAB2>/, $f2, -1 );
                        @sub2 = $white_decode->(@sub2);
                        for my $f3 (@sub2) {
                            if ( defined $f3 && $f3 =~ /<TAB3>/ ) {
                                my @sub3 = map { $_ eq '-' ? '' : $_ } split( /<TAB3>/, $f3, -1 );
                                $f3 = [ $white_decode->(@sub3) ];
                            }
                        }
                        $f2 = \@sub2;
                    }
                }
                $f1 = \@sub1;
            }
        }

        if ( defined $rid_prefix ) {
            unshift @fields, $rid_prefix;
        }
        return wantarray ? @fields : ( @fields == 1 ? $fields[0] : \@fields );
    }

    # 2. ERA 2026: HTML entities (&#38;, &#124;, &#61;) + ARRAY: / HASH:
    if ( $record =~ /(?:ARRAY:|HASH:|&#(?:38|61|124|92|30);)/ ) {
        my $unescape_chars = sub {
            my ($str) = @_;
            return "" unless defined $str;
            $str =~ s/\\\\/\\/g;
            $str =~ s/\\([nrt])/$1 eq 'n' ? "\n" : $1 eq 'r' ? "\r" : "\t"/eg;
            $str =~ s/&#61;/=/g;
            $str =~ s/&#124;/|/g;
            $str =~ s/&#30;/\x1e/g;
            $str =~ s/&#92;/\\/g;
            $str =~ s/&#38;/&/g;
            return $str;
        };

        my $decode_node;
        $decode_node = sub {
            my ($field) = @_;
            return "" unless defined $field;

            if ( $field =~ /^ARRAY:(.*)/s ) {
                my $payload = $1;
                return [] if $payload eq "";
                return [ map { $decode_node->( $unescape_chars->($_) ) } split( /\|/, $payload, -1 ) ];
            }
            elsif ( $field =~ /^HASH:(.*)/s ) {
                my $payload = $1;
                my %h;
                if ( $payload ne "" ) {
                    for my $pair ( split( /\|/, $payload, -1 ) ) {
                        my ( $k, $v ) = split( /=/, $pair, 2 );
                        $h{ $unescape_chars->($k) } = $decode_node->( $unescape_chars->( $v // '' ) );
                    }
                }
                return \%h;
            }
            elsif ( $field =~ /\\T/ ) {
                return [ map { $unescape_chars->($_) } split( /\\T/, $field, -1 ) ];
            }
            else {
                return $unescape_chars->($field);
            }
        };

        my @raw = split( /\t/, $record, -1 );
        if ( @raw == 1 && $raw[0] =~ /^(?:ARRAY|HASH):/ ) {
            my $res = $decode_node->( $raw[0] );
            return wantarray ? ($res) : $res;
        }
        my @res = map { $decode_node->( $unescape_chars->($_) ) } @raw;
        return wantarray ? @res : ( @res == 1 ? $res[0] : \@res );
    }

    # 3. ERA 2004 - 2006 & 2003: \t root, \T array delimiter, standard escapes
    my $unescape_basic = sub {
        my ($s) = @_;
        return "" unless defined $s;
        $s =~ s/\\(.)/$1 eq "t" ? "\t" : $1 eq "n" ? "\n" : $1 eq "r" ? "\r" : $1 eq "T" ? "\\T" : $1 eq "\\" ? "\\" : $1/eg;
        return $s;
    };

    my @raw_fields = split( /\t/, $record, -1 );
    @raw_fields = map { $unescape_basic->($_) } @raw_fields;

    for my $line (@raw_fields) {
        if ( defined $line && $line =~ /\\T/ ) {
            my @parts = split( /\\T/, $line, -1 );
            @parts = map { $unescape_basic->($_) } @parts;
            $line = \@parts;
        }
    }

    return wantarray ? @raw_fields : ( @raw_fields == 1 ? $raw_fields[0] : \@raw_fields );
}

# ------------------------------------------------
# tsv_encode: Legacy text encoder for CSV exports and text-mode pipelines
# ------------------------------------------------
sub tsv_encode {
    my ( $self, @fields ) = @_;
    return unless @fields;

    my $encode_node;
    $encode_node = sub {
        my ($node) = @_;

        if ( ref($node) eq "ARRAY" ) {
            my @escaped = map { ref($_) ? $encode_node->($_) : $self->char_escape($_) } @$node;
            return "ARRAY:" . join( "|", @escaped );
        }
        elsif ( ref($node) eq "HASH" ) {
            my @escaped_pairs;
            foreach my $k ( sort keys %$node ) {
                my $safe_k = $self->char_escape($k);
                my $safe_v = ref( $node->{$k} ) ? $encode_node->( $node->{$k} ) : $self->char_escape( $node->{$k} );
                push @escaped_pairs, "$safe_k=$safe_v";
            }
            return "HASH:" . join( "|", @escaped_pairs );
        }
        else {
            return $self->char_escape($node);
        }
    };

    if ( @fields == 1 && ref( $fields[0] ) ) {
        return $encode_node->( $fields[0] );
    }

    my @encoded = map { ref($_) ? $encode_node->($_) : $self->char_escape($_) } @fields;
    return join( "\t", @encoded );
}

# ------------------------------------------------
sub char_escape {
    my ( $self, $str ) = @_;
    return "" unless defined $str;

    # WARNING: Escape ampersand & first! (Double escaping logic)
    $str =~ s/&/&#38;/g;      # ampersand
    $str =~ s/\\/&#92;/g;     # backslash
    $str =~ s/\|/&#124;/g;    # pipe (Array/Hash delimiter)
    $str =~ s/=/&#61;/g;      # equals (Hash key-value delimiter)
    $str =~ s/\x1e/&#30;/g;   # record separator (Transaction journal delimiter)
    $str =~ s/\t/\\t/g;       # tab
    $str =~ s/\n/\\n/g;       # newline
    $str =~ s/\r/\\r/g;       # carriage return
    return $str;
}

# ------------------------------------------------
sub char_unescape {
    my ( $self, $str ) = @_;
    return "" unless defined $str;

    $str =~ s{ (\\\\) | \\([nrt]) | &\#(92|61|124|38|30); }{
        defined $1 ? "\\" :
        defined $2 ? ( $2 eq 'n' ? "\n" : $2 eq 'r' ? "\r" : "\t" ) :
        chr($3)
    }gex;

    return $str;
}

# encode like cgi escape
# my $sifresiz = $adb->uri_encode("sifreli");
# ------------------------------------------------
sub uri_encode {
    my ( $self, $str ) = @_;

    $str =~ s/([^A-Za-z0-9\-_.~])/sprintf("%%%02X", ord($1))/ge;

    return $str;
}

# decode like cgi unescape
# my $sifresiz = $adb->uri_decode("sifresiz");
# ------------------------------------------------
sub uri_decode {
    my ( $self, $str ) = @_;

    $str =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge;

    return $str;
}

# my $key_escape = $adb->key_encode($key);
# ------------------------------------------------
sub key_encode {
    my ( $self, $key ) = @_;

    my $key_escape = "$key";

    if ( $key_escape =~ /[^\w]/ ) {
        if ( $self && ref($self) ) {
            $key_escape = $self->to_ascii($key_escape);
        }
        $key_escape =~ s/[^\w]//g;
    }

    return $key_escape;
}

# =====================================================================
# FORMAT DETECTION & LEGACY DECODING (2003-2026 formats)
# =====================================================================

sub detect_record_format {
    my ( $self, $record ) = @_;
    return 'v5' if !defined $record || $record eq '';

    if ( length($record) >= 7 && substr( $record, 0, 4 ) eq "\x00ABR" ) {
        return 'v5';
    }
    if ( $record =~ /(?:ARRAY:|HASH:|&#(?:38|61|124|92|30);)/ ) {
        return 'v4';
    }
    if ( $record =~ /<TAB[0-9]+>/ ) {
        return 'v3';
    }
    if ( $record =~ /\\T/ ) {
        return 'v2';
    }
    return 'v1';
}

# =====================================================================
# BINARY INDEX PACKING (64-bit Big-Endian Packed Identifiers)
# =====================================================================

# $adb->bin_encode(\@rids)
# Encodes list of record IDs into 8-byte packed binary format (64-bit uint Q>*).
# ------------------------------------------------
sub bin_encode {
    my ( $self, $rids ) = @_;

    return '' unless ref($rids) eq 'ARRAY' && @$rids;

    return pack( "(Q>)*", @$rids );
}

# $adb->bin_decode($binary_buffer, $offset, $limit, $dir)
# Decodes 8-byte binary buffer (64-bit uint Q>*) with O(1) substr slicing.
# Returns ($total_count, @sliced_ids)
# ------------------------------------------------
sub bin_decode {
    my ( $self, $buffer, $offset, $limit, $dir ) = @_;

    return ( 0, () ) unless defined $buffer && length($buffer) >= 8;

    my $rec_size = 8;
    my $total = int( length($buffer) / $rec_size );
    return ( 0, () ) unless $total;

    $offset ||= 0;
    $limit  ||= 0;
    $dir    = ( defined $dir && $dir =~ /^(asc|desc|reverse)$/i ) ? lc($dir) : 'desc';

    if ( lc($dir) eq 'desc' ) {
        my ( $real_start, $real_limit );
        if ($limit) {
            $real_start = $total - $offset - $limit;
            $real_limit = $limit;
            if ( $real_start < 0 ) {
                $real_limit += $real_start;
                $real_start = 0;
            }
        }
        else {
            $real_start = 0;
            $real_limit = $total - $offset;
        }

        return ( $total, () ) if $real_limit <= 0;

        my $slice = substr( $buffer, $real_start * $rec_size, $real_limit * $rec_size );
        my @ids = unpack( "(Q>)*", $slice );
        my @ids_rev = reverse @ids;
        return ( $total, @ids_rev );
    }

    return ( $total, () ) if $offset >= $total;

    my $bytes_to_read = $limit ? ( $limit * $rec_size ) : ( length($buffer) - ( $offset * $rec_size ) );
    if ( $offset * $rec_size + $bytes_to_read > length($buffer) ) {
        $bytes_to_read = length($buffer) - ( $offset * $rec_size );
    }

    return ( $total, () ) if $bytes_to_read <= 0;

    my $slice = substr( $buffer, $offset * $rec_size, $bytes_to_read );
    my @ids = unpack( "(Q>)*", $slice );
    return ( $total, @ids );
}

# $adb->bin_crop( \@group1, \@group2, ... )
# Intersects or unions multiple binary ID buffer groups using Shortest-First Candidate Pruning.
sub bin_crop {
    my $self = shift;

    return () unless @_;

    # 1. Parse optional %opts / $mode parameter
    my %opts;
    if ( ref( $_[0] ) eq 'HASH' ) {
        %opts = %{ shift @_ };
    }
    elsif ( defined $_[0] && !ref( $_[0] ) && $_[0] =~ /^(and|or)$/i ) {
        $opts{mode} = lc( shift @_ );
    }

    my $mode   = lc( $opts{mode}   // 'and' );
    my $offset = $opts{offset}     // $opts{start} // 0;
    my $limit  = $opts{limit}      // 0;
    my $dir    = lc( $opts{sort}   // $opts{dir}   // 'desc' );

    my @raw_groups = @_;
    return () unless @raw_groups;

    # 2. Normalize and inspect each group
    my @stats;
    for my $g (@raw_groups) {
        next unless defined $g;
        my @raws;
        if ( ref($g) eq 'ARRAY' ) {
            for my $item (@$g) {
                push @raws, $item if defined $item && length($item) >= 8;
            }
        }
        elsif ( !ref($g) && length($g) >= 8 ) {
            push @raws, $g;
        }

        if ( $mode eq 'and' ) {
            return () unless @raws;
        }

        my $total_bytes = 0;
        $total_bytes += length($_) for @raws;
        my $id_count = int( $total_bytes / 8 );

        push @stats, {
            raws  => \@raws,
            count => $id_count,
        };
    }

    return () unless @stats;

    # 3. INTERSECTION (AND MODE)
    my @result_ids;
    if ( $mode eq 'and' ) {
        @stats = sort { $a->{count} <=> $b->{count} } @stats;

        return () if $stats[0]{count} == 0;

        my %candidates;
        if ( @{ $stats[0]{raws} } == 1 ) {
            my ( undef, @ids ) = $self->bin_decode( $stats[0]{raws}[0] );
            $candidates{$_} = 1 for @ids;
        }
        else {
            for my $raw ( @{ $stats[0]{raws} } ) {
                my ( undef, @ids ) = $self->bin_decode($raw);
                $candidates{$_} = 1 for @ids;
            }
        }

        return () unless %candidates;

        for my $grp_idx ( 1 .. $#stats ) {
            my $grp = $stats[$grp_idx];
            my %grp_seen;

            if ( @{ $grp->{raws} } == 1 ) {
                my ( undef, @ids ) = $self->bin_decode( $grp->{raws}[0] );
                $grp_seen{$_} = 1 for @ids;
            }
            else {
                for my $raw ( @{ $grp->{raws} } ) {
                    my ( undef, @ids ) = $self->bin_decode($raw);
                    $grp_seen{$_} = 1 for @ids;
                }
            }

            for my $cand ( keys %candidates ) {
                delete $candidates{$cand} unless exists $grp_seen{$cand};
            }

            return () unless %candidates;
        }

        @result_ids = keys %candidates;
    }
    else {
        # 4. UNION (OR MODE)
        my %seen;
        for my $grp (@stats) {
            for my $raw ( @{ $grp->{raws} } ) {
                my ( undef, @ids ) = $self->bin_decode($raw);
                $seen{$_} = 1 for @ids;
            }
        }
        @result_ids = keys %seen;
    }

    return () unless @result_ids;

    # 5. Sorting & Pagination
    if ( $dir eq 'asc' ) {
        @result_ids = sort { $a <=> $b } @result_ids;
    }
    else {
        @result_ids = sort { $b <=> $a } @result_ids;
    }

    if ( $offset > 0 || $limit > 0 ) {
        my $total = scalar @result_ids;
        return () if $offset >= $total;
        my $end = $limit ? ( $offset + $limit - 1 ) : ( $total - 1 );
        $end = ( $total - 1 ) if $end >= $total;
        @result_ids = @result_ids[ $offset .. $end ];
    }

    return @result_ids;
}

# $updated_buf = $adb->bin_add($buffer, $rids)
# Adds one or more record IDs into 8-byte packed binary buffer without duplicates.
# ------------------------------------------------
sub bin_add {
    my ( $self, $buffer, $new_rids ) = @_;

    return $buffer // '' unless defined $new_rids;

    my @ids = ref($new_rids) eq 'ARRAY' ? @$new_rids : ($new_rids);
    return $buffer // '' unless @ids;

    $buffer //= '';

    if ( length($buffer) < 8 ) {
        my %seen;
        my @valid = grep { defined && /^\d+$/ && !$seen{$_}++ } @ids;
        return @valid ? pack( "(Q>)*", @valid ) : '';
    }

    my %seen_in_input;
    for my $id (@ids) {
        next unless defined $id && $id =~ /^\d+$/;
        next if $seen_in_input{$id}++;

        my $target_bytes = pack( "Q>", $id );
        my $pos = index( $buffer, $target_bytes );
        while ( $pos != -1 && ( $pos % 8 != 0 ) ) {
            $pos = index( $buffer, $target_bytes, $pos + 1 );
        }
        if ( $pos == -1 ) {
            $buffer .= $target_bytes;
        }
    }

    return $buffer;
}

# $updated_buf = $adb->bin_punch($buffer, $del_rids)
# Removes one or more record IDs from 8-byte packed binary buffer.
# ------------------------------------------------
sub bin_punch {
    my ( $self, $buffer, $del_rids ) = @_;

    return '' unless defined $buffer && length($buffer) >= 8;
    return $buffer unless defined $del_rids;

    my @del_list = ref($del_rids) eq 'ARRAY' ? @$del_rids : ($del_rids);
    return $buffer unless @del_list;

    my @sorted_del = sort { $b <=> $a } grep { defined && /^\d+$/ } @del_list;
    return $buffer unless @sorted_del;

    for my $del_id (@sorted_del) {
        my $len = length($buffer);
        last if $len < 8;

        my $target_bytes = pack( "Q>", $del_id );
        my ( $low, $high ) = ( 0, int( $len / 8 ) - 1 );
        my $found = 0;

        # 1. Fast O(log N) binary search for sorted buffers
        while ( $low <= $high ) {
            my $mid = int( ( $low + $high ) / 2 );
            my $mid_bytes = substr( $buffer, $mid * 8, 8 );
            if ( $mid_bytes eq $target_bytes ) {
                substr( $buffer, $mid * 8, 8, "" );
                $found = 1;
                last;
            }
            elsif ( $mid_bytes lt $target_bytes ) {
                $low = $mid + 1;
            }
            else {
                $high = $mid - 1;
            }
        }

        # 2. Fallback: linear index() scan with 8-byte boundary alignment
        if ( !$found ) {
            my $pos = index( $buffer, $target_bytes );
            while ( $pos >= 0 ) {
                if ( $pos % 8 == 0 ) {
                    substr( $buffer, $pos, 8, "" );
                    $pos = index( $buffer, $target_bytes, $pos );
                }
                else {
                    $pos = index( $buffer, $target_bytes, $pos + 1 );
                }
            }
        }
    }

    return $buffer;
}

# $found = $adb->bin_find($buffer, $rid)
# Returns 1 if $rid exists in 8-byte binary buffer, 0 otherwise.
# ------------------------------------------------
sub bin_find {
    my ( $self, $buffer, $rid ) = @_;

    return 0 unless defined $buffer && length($buffer) >= 8 && defined $rid && $rid =~ /^\d+$/;

    my $target_bytes = pack( "Q>", $rid );
    my $len = length($buffer);
    my ( $low, $high ) = ( 0, int( $len / 8 ) - 1 );

    while ( $low <= $high ) {
        my $mid = int( ( $low + $high ) / 2 );
        my $mid_bytes = substr( $buffer, $mid * 8, 8 );
        if ( $mid_bytes eq $target_bytes ) {
            return 1;
        }
        elsif ( $mid_bytes lt $target_bytes ) {
            $low = $mid + 1;
        }
        else {
            $high = $mid - 1;
        }
    }

    my $pos = index( $buffer, $target_bytes );
    while ( $pos != -1 && ( $pos % 8 != 0 ) ) {
        $pos = index( $buffer, $target_bytes, $pos + 1 );
    }

    return ( $pos != -1 ) ? 1 : 0;
}

# $sorted_buf = $adb->bin_sort($buffer)
# Sorts 8-byte big-endian binary buffer in ascending order.
# ------------------------------------------------
sub bin_sort {
    my ( $self, $buffer ) = @_;

    return '' unless defined $buffer && length($buffer) >= 8;
    return $buffer if length($buffer) == 8;

    return join( '', sort unpack( "(a8)*", $buffer ) );
}

# $count = $adb->bin_count($buffer)
# Returns record count in 8-byte binary buffer.
# ------------------------------------------------
sub bin_count {
    my ( $self, $buffer ) = @_;

    return 0 unless defined $buffer && length($buffer) >= 8;
    return int( length($buffer) / 8 );
}

# =====================================================================
# JOURNAL ENCODING / DECODING (TSV + Base64 Delta Specification)
# Standard 8-field Journal Entry Format:
#   $epoch \t $type \t $tableid \t $file_path \t $key \t $action \t $pos \t $base64_payload \n
#   - $type: 'recs' or 'index'
#   - $action: 'add', 'edit', 'del', 'append', 'punch', 'patch', 'put'
#   - $pos: exact byte offset (e.g. 0, 4800000, 8000000) or '' if unpositioned
#   - $payload: Base64-encoded raw octets, or '__NULL__' if undef
# =====================================================================

sub journal_encode {
    my ( $self, $type, $tableid, $file_path, $key, $action, $pos, $payload, $epoch ) = @_;

    $epoch     //= time();
    $type      //= 'recs';
    $tableid   //= '';
    $file_path //= '';
    $key       //= '';
    $action    //= 'put';
    $pos       = ( defined $pos && $pos ne '' ) ? "$pos" : '';

    my $b64;
    if ( !defined $payload || $payload eq '__NULL__' ) {
        $b64 = '__NULL__';
    }
    else {
        $b64 = encode_base64( $payload, '' );
    }

    return join( "\t", $epoch, $type, $tableid, $file_path, $key, $action, $pos, $b64 );
}

sub journal_decode {
    my ( $self, $line ) = @_;

    return unless defined $line;
    chomp $line;
    return if $line eq '';

    my ( $epoch, $type, $tableid, $file_path, $key, $action, $pos, $b64 ) = split /\t/, $line, 8;

    my $payload;
    if ( !defined $b64 || $b64 eq '__NULL__' ) {
        $payload = undef;
    }
    else {
        $payload = decode_base64( $b64 );
    }

    return {
        epoch       => $epoch,
        type        => $type,
        tableid     => $tableid,
        file_path   => $file_path,
        key         => $key,
        action      => $action,
        pos         => ( defined $pos && $pos ne '' ) ? ( 0 + $pos ) : undef,
        payload     => $payload,
    };
}

1;
