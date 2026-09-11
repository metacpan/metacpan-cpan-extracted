package AmberDB::Base::Junk;

use 5.016;
use warnings;
use Carp qw(croak cluck);

our $VERSION = '5.25.1';

my $CREATED = '2026-08-28';

# $rdbm_recs = $adb->prefetch_junk_rdbm($table_info, \@records);
# Scans @records for all foreign table keys referenced in junk_rules (e.g. "2->14"),
# batch fetches the foreign records via read_list in a single pass,
# and stores them in an in-memory map: { $foreign_table => { $id => \@record } }
# ---------------------------------------------------------------------
sub prefetch_junk_rdbm {
    my ( $self, $table_info, $records ) = @_;

    return {} unless ref($table_info) eq 'HASH' && $table_info->{use_junk};
    my $jr = $table_info->{junk_rules} or return {};
    return {} unless ref($records) eq 'ARRAY' && @$records;

    my @rules = ( ref( $jr->[0] ) eq 'ARRAY' ) ? @$jr : ($jr);

    # 1. junk_rules icindeki foreign iliskisel bloklari tespit et (orn: "2->14")
    my %rel_blocks; # $b1 => { table => $ref_table, col => $b2 }
    for my $rule (@rules) {
        my ($spec) = @$rule;
        next unless defined $spec;
        if ( $spec =~ /^(\d+)->(\d+)$/ ) {
            my ( $b1, $b2 ) = ( $1, $2 );
            my $blk_info = $table_info->{blocks}->[$b1] if ref( $table_info->{blocks} ) eq 'ARRAY';
            if ( $blk_info && $blk_info->{rdbm} ) {
                my $ref_table;
                if ( ref( $blk_info->{rdbm} ) eq 'HASH' ) {
                    $ref_table = $blk_info->{rdbm}->{table};
                }
                elsif ( $blk_info->{rdbm} =~ /^([\w\-]+)[;:,]/ ) {
                    $ref_table = $1;
                }
                if ($ref_table) {
                    $rel_blocks{$b1} = { table => $ref_table, col => $b2 };
                }
            }
        }
    }

    return {} unless %rel_blocks;

    # 2. @records tablosundaki foreign "tableid"leri ve onlara bagli anahtarlari tespit et
    my %needed_keys; # $ref_table => { $id => 1 }
    for my $rec (@$records) {
        next unless ref($rec) eq 'ARRAY';
        for my $b1 ( keys %rel_blocks ) {
            my $val = $rec->[$b1];
            next unless defined $val && $val ne '';
            my $ref_table = $rel_blocks{$b1}->{table};
            for my $id ( split /[,;]/, $val ) {
                $id =~ s/^\s+|\s+$//g;
                next unless length($id);
                # Eger cache'de zaten varsa tekrar diskten cekme
                unless ( $self->get_cache( $ref_table, $id ) ) {
                    $needed_keys{$ref_table}->{$id} = 1;
                }
            }
        }
    }

    # 3. Cache'de olmayan foreign kayitlari tek seferde (read_list) getir ve cache'e kaydet
    for my $ref_table ( keys %needed_keys ) {
        my @ids = keys %{ $needed_keys{$ref_table} };
        next unless @ids;
        my @target_recs = $self->read_list( $ref_table, \@ids );
        for my $trec (@target_recs) {
            $self->set_cache( $ref_table, $trec->[0], $trec );
        }
    }

    # 4. Tum foreign tablolara ait cache haritalarini hazirla
    my %rdbm_recs; # $ref_table => { $id => \@target_record }
    for my $b1 ( keys %rel_blocks ) {
        my $ref_table = $rel_blocks{$b1}->{table};
        $rdbm_recs{$ref_table} = $self->get_cache($ref_table) || {};
    }

    return \%rdbm_recs;
}

# $is_junk = $adb->junk_rules($table_info, @record);
# $is_junk = $adb->junk_rules($table_info, \@record, \%rdbm_recs);
# Returns 1 if record satisfies any junk condition, 0 otherwise.
# ------------------------------------------------
sub junk_rules {

    my ( $self, $table_info, @args ) = @_;

    return 0 unless ref($table_info) eq 'HASH' && $table_info->{use_junk};
    my $jr = $table_info->{junk_rules} or return 0;

    my ( $record_ref, $rdbm_recs );
    if ( @args && ref( $args[0] ) eq 'ARRAY' ) {
        $record_ref = $args[0];
        $rdbm_recs  = $args[1] if @args > 1 && ref( $args[1] ) eq 'HASH';
    }
    elsif ( @args && ref( $args[-1] ) eq 'HASH' ) {
        $rdbm_recs  = pop @args;
        $record_ref = \@args;
    }
    else {
        $record_ref = \@args;
    }

    my @rules = ( ref( $jr->[0] ) eq 'ARRAY' ) ? @$jr : ($jr);

    for my $rule (@rules) {
        my ( $spec, $op, $val ) = @$rule;
        my $rv = $self->_resolve_field_value( $table_info, $record_ref, $spec, $rdbm_recs );
        if ( $rv ne '' && $self->_cmp_op( $rv, $op, $val ) ) {
            return 1; # Herhangi bir kural sağlandıysa JUNK'tır
        }
    }

    return 0; # Aktif
}

# $mode = $adb->get_jnktype($table_info, \%opts);
# Resolves jnktype mode: 'ALL', 'A', 'AB', 'B', 'BA'
# ------------------------------------------------
sub get_jnktype {

    my ( $self, $table_info, $opts ) = @_;

    my $mode = ( ref($opts) eq 'HASH' ? ( $opts->{jnktype} // $opts->{use_jnktype} ) : undef )
            // ( ref($table_info) eq 'HASH' ? ( $table_info->{jnktype} // $table_info->{use_jnktype} ) : undef )
            // $self->config('jnktype')
            // 'AB';

    $mode = uc("$mode");
    if ( $mode eq 'NONE' || $mode eq 'ALL' || $mode eq '0' || $mode eq 'OFF' || $mode eq '' ) {
        return 'ALL';
    }
    return $mode =~ /^(A|AB|B|BA|ALL)$/ ? $mode : 'AB';
}

# =====================================================================
# OTOMATİK AKTİF <-> JUNK GEÇİŞİ (State Transitions)
# =====================================================================

# $adb->junk_transition($table_path, $table_info, $tableid, \@pairs);
# ------------------------------------------------
sub junk_transition {

    my ( $self, $table_path, $table_info, $tableid, $pairs ) = @_;

    return unless ref($table_info) eq 'HASH' && $table_info->{use_junk};
    return unless ref($pairs) eq 'ARRAY' && @$pairs;

    my ( @became_junk, @became_active, @stayed_active, @stayed_junk );

    for my $pair (@$pairs) {
        my ( $rid, $old_rec, $new_rec ) = @$pair;
        next if $self->array_compare( $old_rec, $new_rec );

        my $old_is_junk = $self->junk_rules( $table_info, @$old_rec );
        my $new_is_junk = $self->junk_rules( $table_info, @$new_rec );

        if ( !$old_is_junk && $new_is_junk ) {
            push @became_junk, $pair;
        }
        elsif ( $old_is_junk && !$new_is_junk ) {
            push @became_active, $pair;
        }
        elsif ( !$old_is_junk && !$new_is_junk ) {
            push @stayed_active, $pair;
        }
        else {
            push @stayed_junk, $pair;
        }
    }

    # 1. Aktif -> Junk Geçişi: A'dan sil, B'ye ekle (Base stream 'keys' değişmez!)
    if (@became_junk) {
        my @old_records = map { $_->[1] } @became_junk;
        my @new_records = map { $_->[2] } @became_junk;
        my @rids        = map { $_->[0] } @became_junk;

        # A akışından sil
        $self->records_del( $table_path, $table_info, \@rids, $tableid, 'A' );
        $self->match_del( $table_path, $table_info, \@old_records, 'A' );
        $self->search_del( $table_path, $table_info, $tableid, \@old_records, 'A' );
        $self->sort_del( $table_path, $table_info, \@old_records, 'A' ) if $table_info->{sort_block};

        # Facet'ten sil (artık aktif değil)
        $self->facet_del( $table_path, $table_info, \@old_records )
            if $table_info->{use_facet};

        # B akışına ekle
        $self->records_add( $table_path, $table_info, $tableid, \@rids, 'B' );
        $self->match_add( $table_path, $table_info, \@new_records, 'B' );
        $self->search_add( $table_path, $table_info, $tableid, \@new_records, 'B' );
        $self->sort_add( $table_path, $table_info, \@new_records, 'B' ) if $table_info->{sort_block};
    }

    # 2. Junk -> Aktif Geçişi: B'den sil, A'ya ekle (Base stream 'keys' değişmez!)
    if (@became_active) {
        my @old_records = map { $_->[1] } @became_active;
        my @new_records = map { $_->[2] } @became_active;
        my @rids        = map { $_->[0] } @became_active;

        # B akışından sil
        $self->records_del( $table_path, $table_info, \@rids, $tableid, 'B' );
        $self->match_del( $table_path, $table_info, \@old_records, 'B' );
        $self->search_del( $table_path, $table_info, $tableid, \@old_records, 'B' );
        $self->sort_del( $table_path, $table_info, \@old_records, 'B' ) if $table_info->{sort_block};

        # A akışına ekle
        $self->records_add( $table_path, $table_info, $tableid, \@rids, 'A' );
        $self->match_add( $table_path, $table_info, \@new_records, 'A' );
        $self->search_add( $table_path, $table_info, $tableid, \@new_records, 'A' );
        $self->sort_add( $table_path, $table_info, \@new_records, 'A' ) if $table_info->{sort_block};

        # Facet'e ekle (artık aktif)
        $self->facet_add( $table_path, $table_info, \@new_records )
            if $table_info->{use_facet};
    }

    # 3. Zaten Aktif Kalanlar
    if (@stayed_active) {
        $self->match_modify( $table_path, $table_info, \@stayed_active, 'A' );
        $self->search_modify( $table_path, $table_info, $tableid, \@stayed_active, 'A' );
        $self->sort_modify( $table_path, $table_info, \@stayed_active, 'A' ) if $table_info->{sort_block};

        # Facet güncelle (değişen alanlar varsa)
        $self->facet_modify( $table_path, $table_info, \@stayed_active )
            if $table_info->{use_facet};
    }

    # 4. Zaten Junk Kalanlar
    if (@stayed_junk) {
        $self->match_modify( $table_path, $table_info, \@stayed_junk, 'B' );
        $self->search_modify( $table_path, $table_info, $tableid, \@stayed_junk, 'B' );
        $self->sort_modify( $table_path, $table_info, \@stayed_junk, 'B' ) if $table_info->{sort_block};
    }

    return 1;
}

=head1 NAME

AmberDB::Index::Junk - Schema-driven Tiered (Hot/Cold) Indexing and Lifecycle Management for AmberDB

=head1 SYNOPSIS

  # In table schema definition (.table):
  {
      name         => "Products",
      record_index => 1,
      use_junk     => 1,
      junk_rules   => [
          [ 20, "ne", 1 ],                      # Direct block rule (e.g. sales_status != 1)
          [ "2->14", "ne", 1 ],                 # Relational RDBM rule (producer block 2 -> status block 14)
          [ "6->0", "eq", "out_of_stock" ],     # Nested array / composite rule
      ],
      jnktype      => "AB",                     # Default table query tier mode (A, AB, B, BA)
      search_block => [ 4, 5 ],
      match_block  => [ 1, 2, 3 ],
  }

  # Querying from AmberDB ($adb inherits AmberDB::Index::Junk):

  # 1. Search with explicit tier mode:
  my ($cnt, @recs) = $adb->search_table("catalog_product", "roman", offset => 0, limit => 20, jnktype => 'A');

  # 2. Field filter with tier mode:
  my $filter_res   = $adb->field_filter("catalog_product", { filter => { 1 => 45 }, jnktype => 'AB' });

  # 3. Read all records with tier mode:
  my @active_ids   = $adb->read_all("catalog_product", jnktype => 'A', keys_only => 1);
  my @junk_ids     = $adb->read_all("catalog_product", jnktype => 'B', keys_only => 1);
  my @combined_ids = $adb->read_all("catalog_product", jnktype => 'AB', keys_only => 1);

=head1 DESCRIPTION

C<AmberDB::Index::Junk> provides a schema-driven, fully automated three-stream dual-tier indexing architecture:

=over 4

=item * B<Base Stream (All Records - no prefix):>

Contains ALL records (active and junk) in chronological/numerical sequence.
Keys: C<keys>, C<count>, C<$blk:$val>, C<$blk:$word>, C<$blk:keys>.
Queried when C<jnktype =E<gt> 'none'>, C<'ALL'>, or when C<use_junk> is not enabled.

=item * B<Hot / Active Tier (Tier A - C<A:> prefix):>

Contains high-priority, currently active, in-sale records.
Keys: C<A:keys>, C<A:count>, C<A:$blk:$val>, C<A:$blk:$word>, C<A:$blk:keys>.

=item * B<Cold / Junk Tier (Tier B - C<B:> prefix):>

Contains passive, expired, or out-of-sale records.
Keys: C<B:keys>, C<B:count>, C<B:$blk:$val>, C<B:$blk:$word>, C<B:$blk:keys>.

=back

This partitioning ensures high performance on storefront search, filtering, and indexing operations while keeping legacy and inactive catalog data searchable and accessible on demand without degrading active traffic.

=head1 SCHEMA CONFIGURATION

=head2 use_junk => 1

Enables dual-tier indexing on the table. If absent or set to 0, standard single-tier indexing is used.

=head2 junk_rules => [ [ $spec, $operator, $value ], ... ]

Defines the conditions under which a record is classified as Junk (Tier B). If any rule matches (logical OR), the record is routed to Tier B. If no rules match, the record is routed to Tier A.

=over 4

=item * B<Direct Block Index:> C<[ 20, "ne", 1 ]>

Evaluates block 20 of the current record.

=item * B<Relational RDBM Reference:> C<[ "2->14", "ne", 1 ]>

Looks up block 2's target table (via C<rdbm> schema configuration) and evaluates block 14 of the referenced record. For example, if a product is manufactured by a publisher whose status in C<catalog_producer> is passive, the product is automatically classified as Junk.

=item * B<Nested Array / Composite:> C<[ "6->0", "eq", "archived" ]>

Evaluates nested array elements or comma/tab separated fields within the record.

=back

=head1 QUERY MODES (jnktype)

The query tier mode is resolved with the following priority hierarchy:

  1. Query Parameter: $opts->{jnktype} (e.g. in search_table, field_filter, field_fetch, read_all)
  2. Table Schema:    $table_info->{jnktype} or $table_info->{use_jnktype}
  3. Instance Config: $adb->config('jnktype')
  4. Global Default:  'AB'

=head2 Available Modes:

=over 4

=item * B<ALL / NONE:>

Bypasses junk partitioning and queries the Base stream directly (C<keys>, C<$blk:$val>, C<$blk:$word>, C<$blk:keys>). Guaranteed continuous numerical sequence with zero page-skip anomalies.

=item * B<A (Active Only):>

Queries only active indexes (C<A:keys>, C<A:$blk:$val>, C<A:$blk:$word>, C<A:$blk:keys>). Ideal for customer-facing category listings, checkout, stock verification, and order processing.

=item * B<AB (Active First, Junk Appended):>

Queries active indexes first, then appends results from junk indexes. Ideal for general storefront search where active products appear at the top, followed by out-of-print items.

=item * B<B (Junk Only):>

Queries only junk keys (C<B:keys>, C<B:$blk:$val>, C<B:$blk:$word>, C<B:$blk:keys>). Ideal for administrative archives, inventory reconciliation, and discontinued item reports.

=item * B<BA (Junk First, Active Appended):>

Queries junk indexes first, followed by active records.

=back

=head1 LIFECYCLE & AUTOMATIC STATE TRANSITIONS

During C<modify_id> and C<modify_list> calls, C<junk_transition> calculates state changes:

=over 4

=item * B<Active -E<gt> Junk:>

Record is removed from C<A:> tier indexes and added to C<B:> tier indexes. The Base stream (C<keys>) remains unaffected.

=item * B<Junk -E<gt> Active:>

Record is removed from C<B:> tier indexes and added to C<A:> tier indexes. The Base stream (C<keys>) remains unaffected.

=item * B<Unchanged:>

Record is modified in-place within its existing tier and updated in Base indexes.

=back

=head1 METHODS

=head2 junk_rules($table_info, @record)

Evaluates schema rules (C<junk_rules>) against a given record. Resolves direct fields, nested arrays, and relational foreign keys (RDBM) dynamically. Returns C<1> if the record satisfies any junk condition (Tier B), C<0> if active (Tier A).

  my $is_junk = $adb->junk_rules($table_schema, @record_fields);

=head2 get_jnktype($table_info, \%opts)

Resolves the effective query mode (C<'ALL'>, C<'A'>, C<'AB'>, C<'B'>, C<'BA'>) using the 4-level priority hierarchy (query options -E<gt> table schema -E<gt> instance config -E<gt> default C<'AB'>).

  my $mode = $adb->get_jnktype($table_schema, { jnktype => 'A' }); # "A"

=head2 junk_transition($table_path, $table_info, $tableid, \@pairs)

Calculates state changes between Active and Junk tiers during update operations, and coordinates atomic migration between C<A:> and C<B:> tier indexes via unified C<Index> methods.


=head1 AUTHOR

Maruf Cetin <marufcetin@gmail.com>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012-2026 Maruf Cetin.

This library is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0.

=cut

1;
