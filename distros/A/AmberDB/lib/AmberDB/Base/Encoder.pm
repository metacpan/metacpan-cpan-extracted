package AmberDB::Base::Encoder;

use 5.016;
use warnings;
use Carp qw(croak cluck);
use MIME::Base64 qw(encode_base64 decode_base64);

our $VERSION = '5.26.0';

my $CREATED = '2026-09-06';

# =====================================================================
# RECORD ENCODING / DECODING — ABR v5 (AmberDB Binary Record)
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
    my $result = join( "\t", @encoded );
    utf8::encode($result) if utf8::is_utf8($result);

    return $result;
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

sub detect_tsv_format {
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
# Pure binary buffer operations: 0 hashes, 0 regexes, 0 splits.
# =====================================================================

# $adb->bin_encode(\@rids)
# Encodes list of numeric record IDs into 8-byte packed binary format (64-bit uint Q>*).
# ------------------------------------------------
sub bin_encode {
    my ( $self, $rids ) = @_;

    return '' unless ref($rids) eq 'ARRAY' && @$rids;

    # Fast numeric filter: positive numbers only (no regex overhead)
    my @valid = grep { defined && $_ > 0 } @$rids;
    return '' unless @valid;

    return pack( "(Q>)*", @valid );
}

# $adb->bin_decode($binary_buffer, $offset, $limit, $dir)
# Decodes 8-byte binary buffer (64-bit uint Q>*) with O(1) substr slicing.
# Returns ($total_count, @sliced_ids)
# ------------------------------------------------
sub bin_decode {
    my ( $self, $buffer, $offset, $limit, $dir ) = @_;

    return ( 0, () ) unless defined $buffer && length($buffer) >= 8;

    $offset = 0 if !defined $offset || $offset < 0;
    $limit  ||= 0;
    my $rec_size = 8;
    my $total    = int( length($buffer) / $rec_size );
    return ( $total, () ) if $offset >= $total;

    $dir = ( defined $dir && lc($dir) eq 'asc' ) ? 'asc' : 'desc';

    if ( $total - $offset < $limit || $limit <= 0 ) {
        $limit = $total - $offset;
    }

    if ( $dir eq 'desc' ) {
        my $real_start = $total - $offset - $limit;
        my $slice = substr( $buffer, $real_start * $rec_size, $limit * $rec_size );
        return ( $total, reverse unpack( "(Q>)*", $slice ) );
    }

    my $slice = substr( $buffer, $offset * $rec_size, $limit * $rec_size );
    return ( $total, unpack( "(Q>)*", $slice ) );
}

# $idx = $adb->bin_search($buffer, $target)
# Binary search on 8-byte big-endian packed buffer.
# Returns 0-based record index (0, 1, 2, ...) if found, -1 if not found.
# ------------------------------------------------
sub bin_search {
    my ( $self, $buffer, $target ) = @_;

    return -1 unless defined $buffer && length($buffer) >= 8 && defined $target && $target > 0;

    my $len = int( length($buffer) / 8 );
    my ( $low, $high ) = ( 0, $len - 1 );

    while ( $low <= $high ) {
        my $mid = int( ( $low + $high ) / 2 );
        my $val = unpack( "Q>", substr( $buffer, $mid * 8, 8 ) );
        return $mid if $val == $target;
        if ( $val < $target ) {
            $low = $mid + 1;
        }
        else {
            $high = $mid - 1;
        }
    }

    return -1;
}

# $adb->bin_crop($buffer, $liste, $option)
# Ultra-fast binary intersection / cropping without unpacking the buffer into hashes.
#   $buffer: Packed 8-byte binary buffer (64-bit uint Q>*)
#   $liste:  ARRAY ref of integer IDs OR another 8-byte packed binary buffer
#   $option: 0 (or undef/empty) -> no sorting (fastest)
#            1 -> preserves $buffer order
#            2 -> preserves $liste order
# Returns:
#   List context:   Array of matching integer IDs
#   Scalar context: Packed 8-byte binary buffer ((Q>)*)
# ------------------------------------------------
sub bin_crop {
    my ( $self, $buffer, $liste, $option ) = @_;

    return () unless defined $buffer && length($buffer) >= 8;
    return () unless defined $liste;

    $option ||= 0;
    my @result;

    if ( ref($liste) eq 'ARRAY' ) {
        return () unless @$liste;

        if ( $option == 2 ) {
            # 2: Listenin sıralaması korunur
            for my $id (@$liste) {
                next unless defined $id && $id > 0;
                push @result, $id if $self->bin_search( $buffer, $id ) >= 0;
            }
        }
        elsif ( $option == 1 ) {
            # 1: Buffer'ın sıralaması korunur (indeks pozisyonuna göre sırala: 0 hash)
            my @matches;
            for my $id (@$liste) {
                next unless defined $id && $id > 0;
                my $pos = $self->bin_search( $buffer, $id );
                push @matches, [ $pos, $id ] if $pos >= 0;
            }
            @result = map { $_->[1] } sort { $a->[0] <=> $b->[0] } @matches;
        }
        else {
            # 0: Sıralama önemsiz (en hızlı yol)
            for my $id (@$liste) {
                next unless defined $id && $id > 0;
                push @result, $id if $self->bin_search( $buffer, $id ) >= 0;
            }
        }
    }
    elsif ( !ref($liste) && length($liste) >= 8 ) {
        # $liste de ikili bir tampon ise
        if ( $option == 2 ) {
            # 2: $liste tamponunun sırası
            my @l_ids = unpack( "(Q>)*", $liste );
            @result = grep { $self->bin_search( $buffer, $_ ) >= 0 } @l_ids;
        }
        elsif ( $option == 1 ) {
            # 1: $buffer tamponunun sırası (indeks pozisyonuna göre sırala: 0 hash)
            my @l_ids = unpack( "(Q>)*", $liste );
            my @matches;
            for my $id (@l_ids) {
                my $pos = $self->bin_search( $buffer, $id );
                push @matches, [ $pos, $id ] if $pos >= 0;
            }
            @result = map { $_->[1] } sort { $a->[0] <=> $b->[0] } @matches;
        }
        else {
            # 0: Sıralama önemsiz: küçük olanı büyükte ikili ara
            my ( $small, $large ) = length($buffer) <= length($liste) ? ( $buffer, $liste ) : ( $liste, $buffer );
            my @s_ids = unpack( "(Q>)*", $small );
            @result = grep { $self->bin_search( $large, $_ ) >= 0 } @s_ids;
        }
    }

    return wantarray ? @result : ( @result ? pack( "(Q>)*", @result ) : '' );
}

# $adb->bin_union(\@buffers, $dir)
# High-performance binary union across 8-byte packed buffers without Perl %seen hash.
# In list context: returns deduplicated list of IDs sorted by $dir (default 'asc').
# In scalar context: returns 8-byte packed binary buffer ((Q>)*) sorted ascending.
# ------------------------------------------------
sub bin_union {
    my ( $self, $buffers, $dir ) = @_;

    return () unless $buffers;

    my @bufs = ref($buffers) eq 'ARRAY' ? @$buffers : ($buffers);
    @bufs = grep { defined $_ && length($_) >= 8 } @bufs;
    return () unless @bufs;

    # Single buffer fast-path
    if ( @bufs == 1 ) {
        if (wantarray) {
            my ( undef, @ids ) = $self->bin_decode( $bufs[0], 0, 0, $dir // 'asc' );
            return @ids;
        }
        return $bufs[0];
    }

    # Multiple buffers: concatenate binary streams in C (zero hash allocation)
    my $combined = join( '', @bufs );
    return () unless length($combined) >= 8;

    my @all_ids = unpack( "(Q>)*", $combined );
    @all_ids = ( defined $dir && lc($dir) eq 'desc' ) ? sort { $b <=> $a } @all_ids : sort { $a <=> $b } @all_ids;

    # O(N) linear deduplication of adjacent elements (no hash table!)
    my $prev = -1;
    my @uniq = grep { my $dup = ($_ == $prev); $prev = $_; !$dup } @all_ids;

    return wantarray ? @uniq : ( @uniq ? pack( "(Q>)*", @uniq ) : '' );
}

# $updated_buf = $adb->bin_add($buffer, $rids)
# Adds one or more record IDs into 8-byte packed binary buffer without duplicates.
# Pure binary buffer operation: uses binary search to check existence and maintains sort order.
# ------------------------------------------------
sub bin_add {
    my ( $self, $buffer, $new_rids ) = @_;

    return $buffer // '' unless defined $new_rids;

    $buffer //= '';

    my @ids = ref($new_rids) eq 'ARRAY'
      ? @$new_rids
      : ( !ref($new_rids) && length($new_rids) >= 8 && length($new_rids) % 8 == 0
          ? unpack( "(Q>)*", $new_rids )
          : ($new_rids) );

    @ids = grep { defined && $_ > 0 } @ids;
    return $buffer unless @ids;

    # Deduplicate input IDs without a hash
    my @sorted_in = sort { $a <=> $b } @ids;
    my $prev_in = -1;
    @ids = grep { my $d = ($_ == $prev_in); $prev_in = $_; !$d } @sorted_in;

    if ( length($buffer) < 8 ) {
        return pack( "(Q>)*", @ids );
    }

    my @to_add;
    for my $id (@ids) {
        push @to_add, $id if $self->bin_search( $buffer, $id ) < 0;
    }
    return $buffer unless @to_add;

    $buffer .= pack( "(Q>)*", @to_add );
    return $self->bin_sort($buffer);
}

# $updated_buf = $adb->bin_punch($buffer, $del_rids)
# Removes one or more record IDs from 8-byte packed binary buffer.
# Pure binary buffer operation: O(log N) binary search and surgical 8-byte excision.
# ------------------------------------------------
sub bin_punch {
    my ( $self, $buffer, $del_rids ) = @_;

    return '' unless defined $buffer && length($buffer) >= 8;
    return $buffer unless defined $del_rids;

    my @del_list = ref($del_rids) eq 'ARRAY'
      ? @$del_rids
      : ( !ref($del_rids) && length($del_rids) >= 8 && length($del_rids) % 8 == 0
          ? unpack( "(Q>)*", $del_rids )
          : ($del_rids) );

    @del_list = grep { defined && $_ > 0 } @del_list;
    return $buffer unless @del_list;

    for my $del_id (@del_list) {
        my $len = length($buffer);
        last if $len < 8;

        my $mid = $self->bin_search( $buffer, $del_id );
        if ( $mid >= 0 ) {
            substr( $buffer, $mid * 8, 8, "" );
            next;
        }

        # Fallback for unsorted buffer: 8-byte boundary index search
        my $target_bytes = pack( "Q>", $del_id );
        my $pos = index( $buffer, $target_bytes );
        while ( $pos >= 0 ) {
            if ( $pos % 8 == 0 ) {
                substr( $buffer, $pos, 8, "" );
                last;
            }
            $pos = index( $buffer, $target_bytes, $pos + 1 );
        }
    }

    return $buffer;
}

# $found = $adb->bin_find($buffer, $rid)
# Returns 1 if $rid exists in 8-byte binary buffer, 0 otherwise.
# Pure O(log N) binary search on 8-byte chunks.
# ------------------------------------------------
sub bin_find {
    my ( $self, $buffer, $rid ) = @_;

    return 0 unless defined $buffer && length($buffer) >= 8 && defined $rid && $rid > 0;

    return 1 if $self->bin_search( $buffer, $rid ) >= 0;

    # Fallback for unsorted buffer: 8-byte boundary index search
    my $target_bytes = pack( "Q>", $rid );
    my $pos = index( $buffer, $target_bytes );
    while ( $pos >= 0 ) {
        return 1 if $pos % 8 == 0;
        $pos = index( $buffer, $target_bytes, $pos + 1 );
    }

    return 0;
}

# $sorted_buf = $adb->bin_sort($buffer, $dir)
# Sorts 8-byte big-endian binary buffer in ascending (or descending) order.
# Pure C-level string sort of 8-byte big-endian chunks (0 Perl hash / 0 unpack to array).
# ------------------------------------------------
sub bin_sort {
    my ( $self, $buffer, $dir ) = @_;

    return '' unless defined $buffer && length($buffer) >= 8;
    return $buffer if length($buffer) == 8;

    if ( defined $dir && lc($dir) eq 'desc' ) {
        return join( '', sort { $b cmp $a } unpack( "(a8)*", $buffer ) );
    }
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
