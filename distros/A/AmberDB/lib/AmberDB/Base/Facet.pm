package AmberDB::Base::Facet;

use 5.016;
use warnings;
use Carp qw(croak cluck);

our $VERSION = '5.25.1';

my $CREATED = '2026-08-28';

# $adb->facet_rules($table_info, @record);
# ------------------------------------------------
sub facet_rules {

    my ( $self, $table_info, @record ) = @_;

    my $fa = $table_info->{facet_rules} or return 1;

    # Single rule: [blk, op, val] or multiple: [[blk,op,val], ...]
    my @rules = ( ref( $fa->[0] ) eq 'ARRAY' ) ? @$fa : ($fa);

    for my $rule (@rules) {
        my ( $spec, $op, $val ) = @$rule;
        my $rv = $self->_resolve_field_value( $table_info, \@record, $spec );
        return 0 if $rv eq '';
        return 0 unless $self->_cmp_op( $rv, $op, $val );
    }
    return 1;
}

# =====================================================================
# İNDEKSLEME (.fac CRUD) FONKSİYONLARI (Yalnızca Aktif Kayıtlar)
# =====================================================================

# $adb->facet_add($table_path, $table_info, \@records);
# records = [ [$rid, @data...], ... ]  — $rid index 0'da
# ------------------------------------------------
sub facet_add {

    my ( $self, $table_path, $table_info, $records ) = @_;

    return unless $table_info->{use_facet} && $table_info->{facet_block};
    return unless ref($records) eq 'ARRAY' && @$records;

    my @active_records;
    my @new_active;
    for my $rec (@$records) {
        my $rid = $rec->[0];
        my $is_active = $self->facet_rules( $table_info, @$rec );
        if ($is_active) {
            push @new_active, $rid;
            push @active_records, $rec;
        }
    }

    my $fac_path = "$table_path.fac";
    return unless @active_records || ( $table_info->{facet_rules} && @new_active );
    return unless $self->table_write($fac_path);

    # Genel aktif ID setini ${table_path}.fac dosyasına kaydet
    if ( $table_info->{facet_rules} && @new_active ) {
        my ($raw_acts) = $self->index_get( $fac_path, "active", "raw" );
        $raw_acts = $self->bin_add( $raw_acts, \@new_active );
        $self->index_put( $fac_path, "active", $raw_acts, "bin" );
    }

    if (@active_records) {
        # SADECE AKTİF kayıtları blok öneki ile (${table_path}.fac) dosyasına yaz
        for my $blk_cfg ( @{ $table_info->{facet_block} } ) {
            my $blk = ref($blk_cfg) eq 'HASH' ? $blk_cfg->{blk} : $blk_cfg;

            for my $rec (@active_records) {
                my $rid = $rec->[0];
                next unless defined $rec->[$blk] && $rec->[$blk] ne '';
                my @ids = $self->set_fieldlist( $rec->[$blk], $table_path, $table_info, $blk );
                if (@ids) {
                    $self->index_put( $fac_path, "$blk:$rid", join( "\t", @ids ), 'raw' );
                }
            }
        }
    }

    $self->table_close($fac_path);
}

# $adb->facet_modify($table_path, $table_info, \@pairs);
# pairs = [ [$rid, \@old_rec, \@new_rec], ... ]
# ------------------------------------------------
sub facet_modify {

    my ( $self, $table_path, $table_info, $pairs ) = @_;

    return unless $table_info->{use_facet} && $table_info->{facet_block};
    return unless ref($pairs) eq 'ARRAY' && @$pairs;

    my ( @add_active, @remove_active );
    my ( @became_active, @became_passive, @stayed_active );

    for my $pair (@$pairs) {
        my ( $rid, $old_rec, $new_rec ) = @$pair;
        next if $self->array_compare( $old_rec, $new_rec );
        my $old_active = $self->facet_rules( $table_info, @$old_rec );
        my $new_active = $self->facet_rules( $table_info, @$new_rec );

        if ( $old_active && !$new_active ) {
            push @remove_active, $rid;
            push @became_passive, $pair;
        }
        elsif ( !$old_active && $new_active ) {
            push @add_active, $rid;
            push @became_active, $pair;
        }
        elsif ( $old_active && $new_active ) {
            push @stayed_active, $pair;
        }
    }

    my $fac_path = "$table_path.fac";
    my $need_modify = ( $table_info->{facet_rules} && ( @add_active || @remove_active ) )
      || @became_passive || @became_active || @stayed_active;
    return 1 unless $need_modify;

    return unless $self->table_write($fac_path);

    # Genel aktif ID setini güncelle
    if ( $table_info->{facet_rules} && ( @add_active || @remove_active ) ) {
        my ($raw_acts) = $self->index_get( $fac_path, "active", "raw" );
        $raw_acts //= '';
        if (@remove_active) {
            $raw_acts = $self->bin_punch( $raw_acts, \@remove_active );
        }
        if (@add_active) {
            $raw_acts = $self->bin_add( $raw_acts, \@add_active );
        }
        if ( length($raw_acts) >= 8 ) {
            $self->index_put( $fac_path, "active", $raw_acts, "bin" );
        }
        else {
            $self->index_del( $fac_path, "active" );
        }
    }

    # 1. Pasife dönenleri .fac dosyasından sil ($blk:$rid)
    if (@became_passive) {
        for my $blk_cfg ( @{ $table_info->{facet_block} } ) {
            my $blk = ref($blk_cfg) eq 'HASH' ? $blk_cfg->{blk} : $blk_cfg;
            for my $p (@became_passive) {
                $self->index_del( $fac_path, "$blk:$p->[0]" );
            }
        }
    }

    # 2. Aktife dönenleri .fac dosyasına yaz ($blk:$rid)
    if (@became_active) {
        for my $blk_cfg ( @{ $table_info->{facet_block} } ) {
            my $blk = ref($blk_cfg) eq 'HASH' ? $blk_cfg->{blk} : $blk_cfg;
            for my $p (@became_active) {
                my ( $rid, undef, $new_rec ) = @$p;
                next unless defined $new_rec->[$blk] && $new_rec->[$blk] ne '';
                my @ids = $self->set_fieldlist( $new_rec->[$blk], $table_path, $table_info, $blk );
                if (@ids) {
                    $self->index_put( $fac_path, "$blk:$rid", join( "\t", @ids ), 'raw' );
                }
            }
        }
    }

    # 3. Zaten aktif kalanların değişen bloklarını güncelle
    if (@stayed_active) {
        for my $blk_cfg ( @{ $table_info->{facet_block} } ) {
            my $blk = ref($blk_cfg) eq 'HASH' ? $blk_cfg->{blk} : $blk_cfg;

            my @changed_pairs;
            for my $p (@stayed_active) {
                my ( $rid, $old_rec, $new_rec ) = @$p;
                my $ov = $old_rec->[$blk] // '';
                my $nv = $new_rec->[$blk] // '';
                if ( $ov ne $nv ) {
                    push @changed_pairs, $p;
                }
            }

            next unless @changed_pairs;

            for my $p (@changed_pairs) {
                my ( $rid, undef, $new_rec ) = @$p;
                if ( defined $new_rec->[$blk] && $new_rec->[$blk] ne '' ) {
                    my @ids = $self->set_fieldlist( $new_rec->[$blk], $table_path, $table_info, $blk );
                    if (@ids) {
                        $self->index_put( $fac_path, "$blk:$rid", join( "\t", @ids ), 'raw' );
                    }
                    else {
                        $self->index_del( $fac_path, "$blk:$rid" );
                    }
                }
                else {
                    $self->index_del( $fac_path, "$blk:$rid" );
                }
            }
        }
    }

    $self->table_close($fac_path);

    return 1;
}

# $adb->facet_del($table_path, $table_info, \@records);
# ------------------------------------------------
sub facet_del {

    my ( $self, $table_path, $table_info, $records ) = @_;

    return unless $table_info->{use_facet};
    return unless ref($records) eq 'ARRAY' && @$records;

    my $fac_path = "$table_path.fac";
    return 1 unless -e $fac_path;
    return unless $self->table_write($fac_path);

    # Genel aktif ID setinden sil
    if ( $table_info->{facet_rules} ) {
        my @remove_active = map { $_->[0] } @$records;
        if (@remove_active) {
            my ($raw_acts) = $self->index_get( $fac_path, "active", "raw" );
            if ( defined $raw_acts && length($raw_acts) > 0 ) {
                my $orig_len = length($raw_acts);
                $raw_acts = $self->bin_punch( $raw_acts, \@remove_active );
                if ( length($raw_acts) != $orig_len ) {
                    if ( length($raw_acts) >= 8 ) {
                        $self->index_put( $fac_path, "active", $raw_acts, "bin" );
                    }
                    else {
                        $self->index_del( $fac_path, "active" );
                    }
                }
            }
        }
    }

    # Blok bazlı indekslerden ($blk:$rid) sil
    for my $blk_cfg ( @{ $table_info->{facet_block} || [] } ) {
        my $blk = ref($blk_cfg) eq 'HASH' ? $blk_cfg->{blk} : $blk_cfg;
        for my $rec (@$records) {
            my $rid = $rec->[0];
            $self->index_del( $fac_path, "$blk:$rid" );
        }
    }

    $self->table_close($fac_path);

    return 1;
}

# =====================================================================
# SORGULAMA VE SAYIM FONKSİYONLARI
# =====================================================================

# $hashref = $adb->field_fltkeys($tableid, \%options);
# options: target_block => 2, base_ids => \@subset, filter => { 1 => 5, 3 => [10,12] }
# ------------------------------------------------
sub field_fltkeys {

    my ( $self, $tableid, @args ) = @_;

    $tableid or return;

    my $table_info = $self->table_info($tableid);
    return unless $table_info && $table_info->{use_facet};

    my $use_ramdisk = $table_info ? ( $table_info->{use_ramdisk} // $table_info->{use_cache} // 0 ) : 0;
    if ($use_ramdisk) {
        $self->ramdisk_ensure($tableid);
    }
    my $table_path = $self->table_path($tableid);
    my $idx_path   = $use_ramdisk ? $self->ramdisk_path($tableid) : $table_path;
    my $fac_path   = ( -e "${idx_path}.fac" ) ? "${idx_path}.fac" : "${table_path}.fac";
    my $unq_path   = ( -e "${idx_path}.unq" ) ? "${idx_path}.unq" : "${table_path}.unq";
    my $index_path = ( -e "${idx_path}.inx" ) ? "${idx_path}.inx" : "${table_path}.inx";

    # Parameter parsing
    my ( $target_block, %active_filter, $base_scope );

    if ( ref( $args[0] ) eq 'HASH' ) {
        $target_block  = $args[0]->{target_block};
        %active_filter = %{ $args[0]->{where} || $args[0]->{filter} || $args[0]->{match} || {} };
        $base_scope    = $args[0]->{base_ids} || $args[0]->{scope_ids} || undef;

        if ( $args[0]->{range} ) {
            if ( my $ranges = $self->normalize_range_opts( $tableid, $args[0] ) ) {
                if ( $base_scope && @$base_scope ) {
                    my @scoped = $self->filter_ids_by_range( $tableid, $base_scope, $ranges );
                    $base_scope = \@scoped;
                }
                else {
                    my ( undef, @all_active );
                    ( undef, @all_active ) = $self->index_get( $fac_path, "active" ) if -e $fac_path;
                    unless (@all_active) {
                        ( undef, @all_active ) = $self->index_get( $index_path, "keys" ) if -e $index_path;
                    }
                    @all_active = $self->table_keys($tableid) unless @all_active;
                    my @scoped = $self->filter_ids_by_range( $tableid, \@all_active, $ranges );
                    $base_scope = \@scoped;
                }
            }
        }
    }
    else {
        my ( $fld1, $fld2, $val1 ) = @args;
        $target_block = $fld2;
        %active_filter = ( $fld1 => $val1 ) if defined($fld1) && defined($val1);
    }

    defined($target_block) or return;

    # Hedef blok hariç diğer filtreleri baz ID listesi için uygula
    my %excl = map { $_ => $active_filter{$_} }
               grep { $_ ne $target_block } keys %active_filter;

    my @base_ids;
    if (%excl) {
        my $filter_obj = $self->field_filter(
            $tableid, map { [ $_, $excl{$_} ] } keys %excl
        );
        @base_ids = @{ $filter_obj->{ids} || [] };
        if ( $base_scope && @$base_scope ) {
            my %scope_map = map { $_ => 1 } @$base_scope;
            @base_ids = grep { $scope_map{$_} } @base_ids;
        }
    }
    elsif ( $base_scope && @$base_scope ) {
        @base_ids = @$base_scope;
    }
    else {
        if ( $table_info->{facet_rules} && -e $fac_path ) {
            ( undef, @base_ids ) = $self->index_get( $fac_path, "active" );
        }
        unless (@base_ids) {
            return unless -e $index_path;
            ( undef, @base_ids ) = $self->index_get( $index_path, "keys" );
        }
    }

    return {} unless @base_ids;

    # Doğrudan ilgili bloğun indeksinden (.fac) oku ($target_block:$rid)
    my %count_map;

    if ( -e $fac_path ) {
        my @keys     = map { "$target_block:$_" } @base_ids;
        my $res      = $self->recs_get( $fac_path, @keys );
        for my $id (@base_ids) {
            my $raw = $res ? $res->{"$target_block:$id"} : undef;
            next unless defined $raw && $raw ne '';
            my @vals = ( index( $raw, "\t" ) == -1 ) ? ($raw) : split /\t/, $raw;
            for my $v (@vals) {
                $count_map{$v}++;
            }
        }
    }

    if ( -e $unq_path && %count_map ) {
        my @val_ids = keys %count_map;
        my @n_keys = map { "$target_block:n:$_" } @val_ids;
        my $names = $self->index_get( $unq_path, \@n_keys, 'raw' );
        if ( $names && ref($names) eq 'HASH' && %$names ) {
            my %named_map;
            for my $vid (@val_ids) {
                my $name = $names->{"$target_block:n:$vid"} // $vid;
                $named_map{$name} = $count_map{$vid};
            }
            return \%named_map;
        }
    }

    return \%count_map;
}

# Returns count map for multiple blocks in a single pass.
# my $all = $adb->field_allfltkeys("tableid", \%options);
# options: target_blocks => \@blk_list, base_ids => \@base_scope
# Legacy: $adb->field_allfltkeys("tableid", \@blk_list, \@base_scope);
# Returns: { blk => { val => count }, ... }
# ------------------------------------------------
sub field_allfltkeys {

    my ( $self, $tableid, @args ) = @_;

    $tableid or return {};

    my ( $blks, $base_scope );

    if ( @args == 1 && ref( $args[0] ) eq 'HASH' ) {
        my $opts = $args[0];
        $blks       = $opts->{target_blocks} || $opts->{blocks} || $opts->{blks} || $opts->{target_block};
        $base_scope = $opts->{base_ids} || $opts->{scope_ids} || $opts->{base_scope};
    }
    elsif ( @args >= 1 ) {
        $blks = $args[0];
        if ( @args >= 2 ) {
            if ( ref( $args[1] ) eq 'HASH' ) {
                $base_scope = $args[1]->{base_ids} || $args[1]->{scope_ids} || $args[1]->{base_scope};
            }
            elsif ( ref( $args[1] ) eq 'ARRAY' ) {
                $base_scope = $args[1];
            }
        }
    }

    $blks = [$blks] if defined $blks && !ref($blks);
    ref $blks eq 'ARRAY' && @$blks or return {};

    my $table_info = $self->table_info($tableid);
    return {} unless $table_info && $table_info->{use_facet};

    my $use_ramdisk = $table_info ? ( $table_info->{use_ramdisk} // $table_info->{use_cache} // 0 ) : 0;
    if ($use_ramdisk) {
        $self->ramdisk_ensure($tableid);
    }
    my $table_path = $self->table_path($tableid);
    my $idx_path   = $use_ramdisk ? $self->ramdisk_path($tableid) : $table_path;
    my $fac_path   = ( -e "${idx_path}.fac" ) ? "${idx_path}.fac" : "${table_path}.fac";
    my $unq_path   = ( -e "${idx_path}.unq" ) ? "${idx_path}.unq" : "${table_path}.unq";
    my $index_path = ( -e "${idx_path}.inx" ) ? "${idx_path}.inx" : "${table_path}.inx";

    my $r_opts = ( @args == 1 && ref($args[0]) eq 'HASH' ) ? $args[0] : ( @args >= 2 && ref($args[1]) eq 'HASH' ? $args[1] : undef );
    if ( $r_opts && $r_opts->{range} ) {
        if ( my $ranges = $self->normalize_range_opts( $tableid, $r_opts ) ) {
            if ( $base_scope && @$base_scope ) {
                my @scoped = $self->filter_ids_by_range( $tableid, $base_scope, $ranges );
                $base_scope = \@scoped;
            }
            else {
                my ( undef, @all_active );
                ( undef, @all_active ) = $self->index_get( $fac_path, "active" ) if -e $fac_path;
                unless (@all_active) {
                    ( undef, @all_active ) = $self->index_get( $index_path, "keys" ) if -e $index_path;
                }
                @all_active = $self->table_keys($tableid) unless @all_active;
                my @scoped = $self->filter_ids_by_range( $tableid, \@all_active, $ranges );
                $base_scope = \@scoped;
            }
        }
    }

    my @scan_ids;
    if ( $base_scope && ref($base_scope) eq 'ARRAY' && @$base_scope ) {
        @scan_ids = @$base_scope;
    }
    elsif ( $table_info->{facet_rules} && -e $fac_path ) {
        ( undef, @scan_ids ) = $self->index_get( $fac_path, "active" );
    }

    my %all_counts;
    return \%all_counts unless -e $fac_path;

    if (@scan_ids) {
        for my $blk (@$blks) {
            my @keys = map { "$blk:$_" } @scan_ids;
            my $res  = $self->recs_get( $fac_path, @keys );
            for my $id (@scan_ids) {
                my $raw = $res ? $res->{"$blk:$id"} : undef;
                next unless defined $raw && $raw ne '';
                my @vals = ( index( $raw, "\t" ) == -1 ) ? ($raw) : split /\t/, $raw;
                for my $v (@vals) {
                    $all_counts{$blk}{$v}++;
                }
            }
        }
    }
    else {
        my %wanted_blks = map { ( ref($_) eq 'HASH' ? $_->{blk} : $_ ) => 1 } @$blks;
        $self->recs_scan(
            $fac_path,
            sub {
                my ( $k, $raw ) = @_;
                return unless defined $raw && $raw ne '';
                return unless $k =~ /^(\d+):(\d+)$/;
                my ( $k_blk, $rid ) = ( $1, $2 );
                return unless $wanted_blks{$k_blk};
                my @vals = ( index( $raw, "\t" ) == -1 ) ? ($raw) : split /\t/, $raw;
                for my $v (@vals) {
                    $all_counts{$k_blk}{$v}++;
                }
            }
        );
    }

    if ( -e $unq_path && %all_counts ) {
        for my $blk ( keys %all_counts ) {
            my $cnt_map = $all_counts{$blk};
            next unless $cnt_map && ref($cnt_map) eq 'HASH' && %$cnt_map;
            my @val_ids = keys %$cnt_map;
            my @n_keys  = map { "$blk:n:$_" } @val_ids;
            my $names   = $self->index_get( $unq_path, \@n_keys, 'raw' );
            if ( $names && ref($names) eq 'HASH' && %$names ) {
                my %named_map;
                for my $vid (@val_ids) {
                    my $name = $names->{"$blk:n:$vid"} // $vid;
                    $named_map{$name} = $cnt_map->{$vid};
                }
                $all_counts{$blk} = \%named_map;
            }
        }
    }

    return \%all_counts;
}

# Generates schema-driven facet menu structure and performs active filtering.
# my $result = $adb->facet_menu($tableid, [\%options]);
# options: selected => \%selected, facet_defs => \@facet_defs, offset => 0, limit => 20, base_ids => \@base_scope
# Legacy: my $result = $adb->facet_menu($tableid, \%selected, \@facet_defs, \%opts);
# ------------------------------------------------
sub facet_menu {

    my ( $self, $tableid, @args ) = @_;

    $tableid or return ( wantarray ? () : {} );
    my $table_info = $self->table_info($tableid);
    return ( wantarray ? () : {} ) unless $table_info && $table_info->{use_facet};

    my ( $selected, $facet_defs, $opts );
    if ( @args == 1 && ref( $args[0] ) eq 'HASH' ) {
        my $arg = $args[0];
        if ( exists $arg->{selected}
          || exists $arg->{facet_defs}
          || exists $arg->{offset}
          || exists $arg->{start}
          || exists $arg->{limit}
          || exists $arg->{base_ids}
          || exists $arg->{scope_ids}
          || exists $arg->{blocks}
          || exists $arg->{filter}
          || exists $arg->{where}
          || exists $arg->{match}
          || exists $arg->{range} )
        {
            $opts       = $arg;
            $selected   = $arg->{selected} || $arg->{filter} || $arg->{where} || $arg->{match} || {};
            $facet_defs = $arg->{facet_defs} || $arg->{blocks} || $table_info->{facet_block} || [];
        }
        else {
            $selected   = $arg;
            $facet_defs = $table_info->{facet_block} || [];
            $opts       = {};
        }
    }
    else {
        ( $selected, $facet_defs, $opts ) = @args;
    }

    $selected   ||= {};
    $facet_defs ||= $table_info->{facet_block} || [];
    $opts       ||= {};

    my $table_path = $self->table_path($tableid);
    my $offset     = $opts->{offset} // $opts->{start} // 0;
    my $limit      = $opts->{limit} // 0;
    my $base_scope = $opts->{base_ids} || $opts->{scope_ids} || undef;
    if ( $opts && $opts->{range} ) {
        if ( my $ranges = $self->normalize_range_opts( $tableid, $opts ) ) {
            if ( $base_scope && @$base_scope ) {
                my @scoped = $self->filter_ids_by_range( $tableid, $base_scope, $ranges );
                $base_scope = \@scoped;
            }
            else {
                my ( undef, @all_active );
                my $fac_path = "$table_path.fac";
                ( undef, @all_active ) = $self->index_get( $fac_path, "active" ) if -e $fac_path;
                unless (@all_active) {
                    my $inx_path = "$table_path.inx";
                    ( undef, @all_active ) = $self->index_get( $inx_path, "keys" ) if -e $inx_path;
                }
                @all_active = $self->table_keys($tableid) unless @all_active;
                my @scoped = $self->filter_ids_by_range( $tableid, \@all_active, $ranges );
                $base_scope = \@scoped;
            }
        }
    }

    # Normalize active selections into %active_filter
    my %active_filter;
    for my $raw_k ( keys %$selected ) {
        my $blk = $raw_k;
        $blk =~ s/^f//; # Strip leading 'f' prefix if passed as f1, f2...
        my $v = $selected->{$raw_k};
        if ( defined $v && $v ne '' ) {
            my @vals = ref($v) eq 'ARRAY' ? @$v : split /,/, $v;
            @vals = grep { defined $_ && $_ ne '' } @vals;
            $active_filter{$blk} = \@vals if @vals;
        }
    }

    # 1. Active Filtering (Filtered IDs)
    my ( $filtered_ids, $total_count ) = ( [], 0 );
    if (%active_filter) {
        my $f_res = $self->field_filter(
            $tableid,
            {
                type   => 'and',
                filter => \%active_filter,
                offset => $offset,
                limit  => $limit,
                ( $opts->{range} ? ( range => $opts->{range} ) : () ),
            }
        );
        $filtered_ids = $f_res->{ids} || [];
        if ( $base_scope && @$base_scope ) {
            my %scope_map = map { $_ => 1 } @$base_scope;
            $filtered_ids = [ grep { $scope_map{$_} } @$filtered_ids ];
        }
        $total_count  = scalar @$filtered_ids;
    }
    elsif ( $base_scope && @$base_scope ) {
        $total_count = scalar @$base_scope;
        if ($limit) {
            my ( undef, @slice ) = $self->recs_cutting( $offset, $limit, @$base_scope );
            $filtered_ids = \@slice;
        }
        else {
            $filtered_ids = $base_scope;
        }
    }
    else {
        my $fac_path = "$table_path.fac";
        if ( -e $fac_path ) {
            ( undef, my @all_active ) = $self->index_get( $fac_path, "active" );
            unless (@all_active) {
                my $inx_path = "$table_path.inx";
                ( undef, @all_active ) = $self->index_get( $inx_path, "keys" ) if -e $inx_path;
            }
            $total_count = scalar @all_active;
            if ($limit) {
                my ( undef, @slice ) = $self->recs_cutting( $offset, $limit, @all_active );
                $filtered_ids = \@slice;
            }
            else {
                $filtered_ids = \@all_active;
            }
        }
    }

    # 2. Compute Facet Counts (Disjunctive / Multi-pass)
    my %all_counts;
    if ( !%active_filter ) {
        my @blks = map { ref($_) eq 'HASH' ? $_->{blk} : $_ } @$facet_defs;
        my $raw_counts = $self->field_allfltkeys( $tableid, \@blks, $base_scope );
        %all_counts = %{ $raw_counts || {} };
    }
    else {
        for my $cfg (@$facet_defs) {
            my $blk = ref($cfg) eq 'HASH' ? $cfg->{blk} : $cfg;
            my %excl = %active_filter;
            delete $excl{$blk};

            my $cnt_map = $self->field_fltkeys(
                $tableid,
                {
                    target_block => $blk,
                    filter       => \%excl,
                    base_ids     => $base_scope,
                }
            );
            $all_counts{$blk} = $cnt_map || {};
        }
    }

    # 3. Build Menu Groups, Whitelist & Batch Label Resolution (.unq / RDBM)
    my @groups;
    my %groups_by_blk;
    my %active_counts;

    for my $cfg (@$facet_defs) {
        my $blk    = ref($cfg) eq 'HASH' ? $cfg->{blk} : $cfg;
        my $label  = ref($cfg) eq 'HASH' ? ( $cfg->{label} // "Grup $blk" ) : "Grup $blk";
        my $counts = $all_counts{$blk} // {};

        next unless %$counts || ( ref($cfg) eq 'HASH' && $cfg->{required} );

        my @vals = keys %$counts;

        # Whitelist: filter_block
        if ( ref($cfg) eq 'HASH' && $cfg->{filter_block} ) {
            my @fb = @{ $cfg->{filter_block} };
            my ( $fb_blk, $fb_op, $fb_val ) = @fb == 3 ? @fb : ( $fb[0], 'eq', $fb[1] );
            my $all_map = $self->field_keyvals( $cfg->{table}, $fb_blk );
            my %allowed;
            for my $k ( keys %$all_map ) {
                if ( $self->_cmp_op( $k, $fb_op, $fb_val ) ) {
                    $allowed{$_} = 1 for @{ $all_map->{$k} };
                }
            }
            @vals = grep { $allowed{$_} } @vals;
        }

        # filter_op on value
        if ( ref($cfg) eq 'HASH' && $cfg->{filter_op} ) {
            my ( $fo_op, $fo_val ) = @{ $cfg->{filter_op} };
            @vals = grep { $self->_cmp_op( $_, $fo_op, $fo_val ) } @vals;
        }

        # csv_list whitelist if defined
        if ( ref($cfg) eq 'HASH' && defined $cfg->{csv_list} && $cfg->{csv_list} ne '' ) {
            my %csv_allowed = map { $_ => 1 } split /,/, $cfg->{csv_list};
            @vals = grep { $csv_allowed{$_} } @vals;
        }

        # Sorting
        my $sort_mode = ( ref($cfg) eq 'HASH' ? $cfg->{sort} : '' ) || 'count';
        if ( $sort_mode eq 'count' ) {
            @vals = sort { ( $counts->{$b} || 0 ) <=> ( $counts->{$a} || 0 ) } @vals;
        }
        elsif ( $sort_mode eq 'value' ) {
            @vals = sort { $a cmp $b } @vals;
        }

        # Top-N Limiting
        my $limit_n = ( ref($cfg) eq 'HASH' ? ( $cfg->{limit} // $cfg->{display_limit} ) : 0 ) || 0;
        if ( $limit_n && @vals > $limit_n ) {
            @vals = @vals[ 0 .. ( $limit_n - 1 ) ];
        }

        # Batch Label Resolution (RDBM -> .unq bidirectional -> option)
        my %name_map;
        if ( ref($cfg) eq 'HASH' && $cfg->{table} ) {
            if (@vals) {
                my @recs = $self->read_list( $cfg->{table}, \@vals );
                my $name_idx = $cfg->{name_idx} // 2;
                %name_map = map { $_->[0] => $_->[$name_idx] } @recs;
            }
        }
        else {
            # .unq sözlük dosyasından $blk:n: prefixi ile çift yönlü çözümle
            my $unq_file = "${table_path}.unq";
            if ( -e $unq_file && @vals ) {
                my @n_keys = map { "$blk:n:$_" } @vals;
                my $res = $self->index_get( $unq_file, \@n_keys, 'raw' );
                if ( $res && ref($res) eq 'HASH' ) {
                    for my $val (@vals) {
                        my $text = $res->{"$blk:n:$val"};
                        if ( defined $text && $text ne '' ) {
                            $name_map{$val} = $text;
                        }
                    }
                }
            }

            # Şema option alanı fallback'i (örn: "1:Satışta,0:Satış Dışı")
            my $opt_str = $table_info->{blocks}->[$blk]->{option} // '';
            if ($opt_str) {
                for my $pair ( split /,/, $opt_str ) {
                    my ( $v, $l ) = split /:/, $pair, 2;
                    $name_map{$v} //= $l // $v;
                }
            }
        }

        # Active status for this block
        my %selected_vals = map { $_ => 1 } @{ $active_filter{$blk} // [] };
        my $active_cnt    = scalar keys %selected_vals;
        $active_counts{$blk} = $active_cnt;

        my @items;
        for my $val (@vals) {
            push @items, {
                uid     => "fc_${blk}_${val}",
                param   => "f$blk",
                val     => $val,
                label   => ( $name_map{$val} // $val ),
                count   => ( $counts->{$val} // 0 ),
                checked => ( $selected_vals{$val} ? "1" : "" ),
            };
        }

        my $group_data = {
            blk          => $blk,
            name         => $label,
            active       => ( $active_cnt ? "1" : "" ),
            active_count => $active_cnt,
            records      => \@items,
        };

        push @groups, $group_data;
        $groups_by_blk{$blk} = \@items;
    }

    my $res = {
        count         => $total_count,
        ids           => $filtered_ids,
        groups        => \@groups,
        groups_by_blk => \%groups_by_blk,
        active_counts => \%active_counts,
        counts        => \%all_counts,
    };

    return wantarray ? @groups : $res;
}

=encoding utf8

=head1 NAME

AmberDB::Index::Facet - Column-oriented facet indexing, disjunctive counting, and navigation menu generator

=head1 SYNOPSIS

  # Querying from AmberDB instance ($adb inherits AmberDB::Index::Facet):

  # 1. Generate full-catalog or filtered facet menu with disjunctive counts:
  my $menu_data = $adb->facet_menu(
      "catalog_product",
      { 1 => "5", 2 => [ "12", "14" ] }, # %selected_filters
      \@facet_block_definitions,
      { sort => 'count', top => 10 }      # %options
  );

  # 2. Dynamic Scoped facet menu (e.g. within search results or category scope):
  my $search_facets = $adb->facet_menu(
      "catalog_product",
      \%selected,
      \@facet_defs,
      { base_ids => \@search_result_ids }
  );

  # 3. Direct facet key counts for a single block:
  my $counts = $adb->field_fltkeys("catalog_product", {
      target_block => 2,
      base_ids     => \@active_product_ids,
  });

=head1 DESCRIPTION

C<AmberDB::Index::Facet> provides a high-performance, column-oriented forward indexing and disjunctive facet aggregation engine designed for low-latency faceted navigation across large-scale catalogs.

B<Inheritance Note:> C<AmberDB> inherits from C<AmberDB::Index::Facet> via C<use parent>. All facet query and menu methods documented below are invoked directly on C<$adb>.

=head1 KEY ARCHITECTURAL FEATURES

=over 4

=item * B<1. Columnar Unified Storage (C<$table_path.fac>):> Facet data is stored in a unified columnar forward index file (C<$table_path.fac>). Each record's block values are keyed as C<$blk:$rid> mapping to packed value IDs, enabling fast single-column and multi-column scans.

=item * B<2. Active-Only Storage Guarantee:> Facet index files store B<only currently active records>. Inactive, discontinued, or out-of-stock records violating C<facet_rules> / C<junk_rules> are excluded during indexing, eliminating the overhead of scanning historical records.

=item * B<3. Bidirectional String Dictionary (C<.unq>):> Text facets (e.g. colors, specifications) map transparently between string labels and compact numeric dictionary IDs.

=item * B<4. Dynamic Scoping (C<base_ids>):> When computing facet counts within search results or subcategories, passing C<base_ids =E<gt> \@ids> bounds the aggregation strictly to matching records.

=item * B<5. Multi-Select Disjunctive Faceting:> Supports multi-selection where checking multiple items within the same filter group uses OR logic (showing counts of remaining options), while combining across different filter groups uses AND logic.

=back

=head1 METHODS

=head2 facet_menu($tableid, [\%options])

High-level faceted navigation menu generator.

Options:
=over 4
=item * C<selected>: Hash of currently active filter selections: C<{ block_idx =E<gt> $val_or_arr_ref }>. (Aliases: C<filter>, C<where>, C<match>).
=item * C<facet_defs>: Array of facet block definitions (or reads directly from table schema C<facet_block> if omitted).
=item * C<offset>: Pagination start offset (default: 0).
=item * C<limit>: Page size limit (default: 0 = unpaginated).
=item * C<base_ids>: (Alias: C<scope_ids>) Array reference of record IDs to scope calculation (e.g. search result IDs).
=item * C<sort>: C<'count'> (default, descending count) or C<'label'> / C<'name'> (alphabetical).
=item * C<top>: Limit maximum items returned per facet group (e.g. 10).
=item * C<min_count>: Minimum count required to include an item (default: 1).
=item * C<range>: Numerical / chronological range filtering C<{ block => 4, min => 1000, max => 2000 }>.
=back

Returns a comprehensive result hash:
C<{ count => $total, ids => \@filtered_ids, groups => \@groups, active_counts => \%counts, counts => \%all_counts }>.

  my $menu = $adb->facet_menu("catalog_product", {
      selected => { 1 => "5" },
      range    => { block => "price", min => 1000, max => 2000 },
      offset   => 0,
      limit    => 20,
  });

Legacy invocation C<$adb->facet_menu($tableid, \%selected, \@facet_defs, \%options)> remains fully supported.

=head2 field_fltkeys($tableid, \%opts)

Calculates facet key counts for a target block directly from active C<.fac>. Automatically resolves dictionary string labels.

Options:
=over 4
=item * C<target_block>: (Required) Attribute block index to aggregate facet counts for.
=item * C<filter>: (Optional, aliases: C<where>, C<match>) Active filter conditions on other blocks C<{ block_idx => $value }>.
=item * C<base_ids>: (Optional, alias: C<scope_ids>) Array reference of record IDs to scope calculation to.
=item * C<range>: (Optional) Numerical / chronological range filtering C<{ block => 4, min => 1000, max => 2000 }>.
=back

  my $counts = $adb->field_fltkeys("catalog_product", {
      target_block => 2,
      filter       => { 1 => "5" },
      range        => { block => "price", min => 1000 },
      base_ids     => \@scoped_ids,
  });

=head2 field_allfltkeys($tableid, [\%options])

Calculates facet key counts across multiple configured blocks from unified C<.fac> in a single pass.

Options:
=over 4
=item * C<target_blocks>: (Required, alias: C<blocks>) Array reference of block indices to aggregate facet counts for.
=item * C<base_ids>: (Optional, alias: C<scope_ids>) Array reference of record IDs to scope calculation to.
=item * C<range>: (Optional) Numerical / chronological range filtering C<{ block => 4, min => 1000, max => 2000 }>.
=back

  my $all = $adb->field_allfltkeys("catalog_product", {
      target_blocks => [ 1, 2, 4 ],
      base_ids      => \@scoped_ids,
  });

Legacy invocation C<$adb->field_allfltkeys($tableid, \@blk_list, \@base_scope)> remains fully supported.

=head2 facet_rules($table_info, @record)

Evaluates whether a record qualifies for inclusion in facet index files. Automatically integrates with C<junk_rules>.

=head1 AUTHOR

Maruf Cetin <marufcetin@gmail.com>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020-2026 Maruf Cetin.

This library is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0.

=cut

1;
