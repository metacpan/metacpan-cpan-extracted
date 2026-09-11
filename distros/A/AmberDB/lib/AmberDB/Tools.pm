package AmberDB::Tools;

use 5.016;
use warnings;
use Carp qw(croak cluck);
use File::Spec;

our $VERSION = '5.25.1';
my $CREATED = '2018-10-08';

# Constructor
# my $tools = AmberDB::Tools->new($adb, %options);
# my $tools = AmberDB::Tools->new(%options); # creates a new AmberDB instance
# ------------------------------------------------
sub new {

    my $class = shift;
    my $self  = {};

    require AmberDB;

    my ( $adb, %inputs );

    if ( ref( $_[0] ) ) {
        $adb    = shift;
        %inputs = @_;
    }
    else {
        %inputs = @_;
        $adb    = AmberDB->new(%inputs);
    }

    $self->{_adb} = $adb;

    foreach my $in ( keys %inputs ) {
        $self->{ uc($in) } = $inputs{$in};
    }
    $self->{say} = "";

    bless $self, $class;
    return $self;
}

# my $ok = $tools->set_index($tableid, @records);
# ------------------------------------------------
sub set_index {

    my ( $self, $tableid, @records ) = @_;
    my $adb = $self->{_adb} or return;

    my $table_info = $adb->table_info($tableid) or return;
    if ( $adb->config('simple') || $table_info->{use_simple} || ( $table_info->{id_type} && $table_info->{id_type} eq 'ascii' ) ) {
        $self->{say} .= "    - Table '$tableid' is in simple mode, skipping index generation.\n";
        return 1;
    }
    my $table_path = $adb->table_path($tableid);
    return unless ( -e "$table_path.$adb->{db_ext}" );

    # 2. Read records if list empty.
    if ( !@records ) {
        @records = $adb->read_all($tableid, 0, 0, no_index => 1, dir => 'asc');
    }
    return unless scalar @records;

    # Pre-fetch foreign records for junk_rules in one batch before sub-indexers run
    if ( $table_info->{use_junk} ) {
        print "    - Pre-fetching relational foreign records for junk rules...\n";
        $adb->prefetch_junk_rdbm( $table_info, \@records );
    }

    # 3. Create readall index
    if ( exists( $table_info->{record_index} ) ) {
        print "    - Rebuilding readall index (.inx)...\n";
        my $ok = $self->set_readall( $tableid, @records );
    }

    # 4. Create search index
    if ( exists( $table_info->{search_block} ) ) {
        print "    - Rebuilding search index (.src)...\n";
        my $ok = $self->set_search( $tableid, @records );
    }

    # 5. Create fetch field index.
    if ( exists( $table_info->{match_block} ) ) {
        print "    - Rebuilding field index (.fld)...\n";
        my $ok = $self->set_fields( $tableid, @records );
    }

    # 6. Create facet index.
    if ( exists( $table_info->{use_facet} ) ) {
        print "    - Rebuilding facet index (.fac)...\n";
        my $ok = $self->set_filters( $tableid, @records );
    }

    # 7. Create sort index.
    if ( exists( $table_info->{sort_block} ) ) {
        print "    - Rebuilding sort index (.srt)...\n";
        my $ok = $self->set_sort( $tableid, @records );
    }

    # 8. Create URL slug index
    if ( exists( $table_info->{slug_block} ) ) {
        print "    - Rebuilding slug index (.slg)...\n";
        my $ok = $self->set_rwlnkall( $tableid, @records );
    }

    # 9. Create unique index if schema defines unique blocks
    my $has_unique = 0;
    if ( $table_info->{blocks} && ref($table_info->{blocks}) eq 'ARRAY' ) {
        for my $b (@{ $table_info->{blocks} }) {
            if ( ref($b) eq 'HASH' && defined $b->{valid} && $b->{valid} =~ /unique/i ) {
                $has_unique = 1;
                last;
            }
        }
    }
    if ($has_unique) {
        $adb->unique_add( $table_path, $table_info, \@records );
    }

    return 1;
}

# Rebuilds Read All index.
# my $ok = $tools->set_readall($tableid);
# my $ok = $tools->set_readall($tableid, @records);
# ------------------------------------------------
sub set_readall {

    my ( $self, $tableid, @records ) = @_;
    my $adb = $self->{_adb} or return;

    $tableid or return;
    my $table_path = $adb->table_path($tableid);

    my $file_path  = "$table_path.$adb->{db_ext}";
    my $index_path = "$table_path.inx";
    my $tmp_path   = "$index_path.tmp";
    return unless -e $file_path;

    my $table_info = $adb->table_info($tableid);
    return unless $table_info;
    return 1 if $adb->config('simple') || $table_info->{use_simple} || ( $table_info->{id_type} && $table_info->{id_type} eq 'ascii' );

    # Read records from table if absent
    if ( !scalar @records ) {
        @records = $adb->read_all($tableid, 0, 0, no_index => 1, dir => 'asc');
    }
    scalar @records or return;
    my @all_records = ref( $records[0] ) eq 'ARRAY' ? ( map { $_->[0] } @records ) : @records;

    my ( @active_records, @junk_records );
    my $has_junk = $table_info->{use_junk} ? 1 : 0;

    # Accept both full record arrayrefs [ $id, @data ] and scalar ID lists
    if ( ref $records[0] eq "ARRAY" ) {
        if ($has_junk) {
            my $rdbm_recs = $adb->prefetch_junk_rdbm( $table_info, \@records );
            for my $rec (@records) {
                my $rid = $rec->[0];
                next unless defined $rid && $rid =~ /^\d+$/;
                if ( $adb->junk_rules($table_info, $rec, $rdbm_recs) ) {
                    push @junk_records, $rid;
                }
                else {
                    push @active_records, $rid;
                }
            }
        }
        else {
            for my $rec (@records) {
                my $rid = $rec->[0];
                push @active_records, $rid if defined $rid && $rid =~ /^\d+$/;
            }
        }
    }
    else {
        my @clean_rids = grep { /^\d+$/ } @records;
        if ($has_junk) {
            for my $rid (@clean_rids) {
                my @rec = $adb->table_readid($file_path, $rid);
                if ( $adb->junk_rules($table_info, @rec) ) {
                    push @junk_records, $rid;
                }
                else {
                    push @active_records, $rid;
                }
            }
        }
        else {
            @active_records = @clean_rids;
        }
    }

    # Deduplicate in original order
    my %seen_act;
    @active_records = grep { !$seen_act{$_}++ } @active_records;
    my %seen_junk;
    @junk_records   = grep { !$seen_junk{$_}++ } @junk_records;

    my $cur_max = 0;
    if ( @all_records && $all_records[-1] > $cur_max ) {
        $cur_max = $all_records[-1];
    }
    my $old_lastid = $adb->table_lastid($tableid) // 0;
    my $last_id = $cur_max > $old_lastid ? $cur_max : $old_lastid;

    if ( $adb->table_write($tmp_path) ) {
        my $cnt = scalar @all_records;
        $adb->index_put( $tmp_path, "keys",   \@all_records, "ids" );
        $adb->index_put( $tmp_path, "count",  $cnt, "raw" );
        $adb->index_put( $tmp_path, "lastid", $last_id, "raw" ) if defined $last_id;

        if ($has_junk) {
            $adb->index_put( $tmp_path, "A:keys",  \@active_records, "ids" );
            $adb->index_put( $tmp_path, "A:count", scalar @active_records, "raw" );
            $adb->index_put( $tmp_path, "B:keys",  \@junk_records, "ids" );
            $adb->index_put( $tmp_path, "B:count", scalar @junk_records, "raw" );
        }

        $adb->table_close($tmp_path);
        unlink($index_path);
        rename( $tmp_path, $index_path );
        $self->{say} .= "    - Readall records created: \n";
        $self->{say} .= "          * $table_path.inx created ($cnt total records, " . scalar(@active_records) . " active, " . scalar(@junk_records) . " junk)\n";
    }

    return 1;
}

# Rebuilds search word index.
# my $ok = $tools->set_search($tableid, @records);
# ------------------------------------------------
sub set_search {

    my ( $self, $tableid, @records ) = @_;
    my $adb = $self->{_adb} or return;

    return unless $tableid;
    my $table_path = $adb->table_path($tableid);
    my $table_info = $adb->table_info($tableid);
    return unless $table_info;
    return 1 if $adb->config('simple') || $table_info->{use_simple} || ( $table_info->{id_type} && $table_info->{id_type} eq 'ascii' );
    return unless exists( $table_info->{search_block} );

    # Read records from table if absent
    if ( !scalar @records ) {
        @records = $adb->read_all($tableid, 0, 0, no_index => 1, dir => 'asc');
    }
    return unless scalar @records;

    # 1. Identify RDBM blocks and prepare pre-fetch
    my %rdbm_blocks; # field => { table => ..., display => ... }
    for my $blk ( @{ $table_info->{search_block} } ) {
        my ( $field, $src_table, $src_display ) =
            ref($blk) eq 'ARRAY' ? ( $blk->[0], $blk->[1], $blk->[2] )
                                 : ( $blk,       undef,     undef      );
        if ( !$src_table ) {
            ( $src_table, $src_display ) = $adb->rdbm_target( $table_info, $field );
        }
        if ( $src_table ) {
            $src_display //= 1;
            $rdbm_blocks{$field} = { table => $src_table, display => $src_display };
        }
    }

    # 2. Collect unique foreign IDs across all records
    my %string;
    if ( %rdbm_blocks ) {
        for my $rec (@records) {
            for my $field ( keys %rdbm_blocks ) {
                my $val = $rec->[$field];
                next unless defined $val && $val ne '';
                my $target_table = $rdbm_blocks{$field}->{table};
                for my $id ( split /[,;]/, $val ) {
                    $id =~ s/^\s+|\s+$//g;
                    $string{$target_table}->{$id} = 1 if $id =~ /^\d+$/;
                }
            }
        }
    }

    # 3. Batch pre-fetch foreign tables into in-memory lookup map and official cache
    my %rdbm_recs; # table => { id => \@target_record }
    for my $table ( keys %string ) {
        my @needed_ids = grep { !$adb->get_cache( $table, $_ ) } keys %{ $string{$table} };
        if (@needed_ids) {
            my @target_recs = $adb->read_list( $table, \@needed_ids );
            for my $trec (@target_recs) {
                $adb->set_cache( $table, $trec->[0], $trec );
            }
        }
        $rdbm_recs{$table} = $adb->get_cache($table) || {};
    }

    # 4. Tokenize and index words
    my ( %search, %act_search, %junk_search );
    $self->{say} .= "    - Search word kayitlari olusturuluyor: \n";
    my $has_junk  = $table_info->{use_junk} ? 1 : 0;
    my $junk_rdbm = $has_junk ? $adb->prefetch_junk_rdbm( $table_info, \@records ) : {};
    foreach my $line (@records) {
        my @fields = @$line;
        my $rid = $fields[0];
        next unless defined $rid && $rid =~ /^\d+$/;
        my $is_junk = $has_junk ? $adb->junk_rules( $table_info, \@fields, $junk_rdbm ) : 0;
        foreach my $blk ( @{ $table_info->{search_block} } ) {
            my $b_idx = ref($blk) eq "ARRAY" ? $blk->[0] : $blk;
            $b_idx =~ /^\d+$/ or next;

            my $val = $fields[$b_idx];
            if ( my $rdbm_info = $rdbm_blocks{$b_idx} ) {
                if ( defined $val && $val ne '' ) {
                    my $table = $rdbm_info->{table};
                    my $disp  = $rdbm_info->{display};
                    my @parts;
                    for my $id ( split /[,;]/, $val ) {
                        $id =~ s/^\s+|\s+$//g;
                        if ( my $rec = $rdbm_recs{$table}->{$id} ) {
                            my $name = $rec->[$disp];
                            push @parts, $name if defined $name && length($name);
                        }
                    }
                    $val = join( ' ', @parts );
                }
            }

            next unless defined $val && $val ne '';
            my %recsearch = $adb->get_words( $val, "write", $tableid );

            foreach my $key ( keys %recsearch ) {
                push @{ $search{$b_idx}{$key} }, $rid;
                if ($has_junk) {
                    if ($is_junk) {
                        push @{ $junk_search{$b_idx}{$key} }, $rid;
                    }
                    else {
                        push @{ $act_search{$b_idx}{$key} }, $rid;
                    }
                }
            }
        }
    }

    my $file_path = "${table_path}.src";
    my $tmp_path  = "$file_path.tmp";

    unlink($tmp_path);

    my %batch_put;
    foreach my $blk ( @{ $table_info->{search_block} } ) {
        my $b_idx = ref($blk) eq "ARRAY" ? $blk->[0] : $blk;
        $b_idx =~ /^\d+$/ or next;

        next unless $search{$b_idx};
        for my $key ( keys %{ $search{$b_idx} } ) {
            my $all_ids = $search{$b_idx}{$key};
            $batch_put{"$b_idx:$key"} = $all_ids if @$all_ids;

            if ($has_junk) {
                if ( my $act_recs = $act_search{$b_idx}{$key} ) {
                    $batch_put{"A:$b_idx:$key"} = $act_recs if @$act_recs;
                }
                if ( my $junk_recs = $junk_search{$b_idx}{$key} ) {
                    $batch_put{"B:$b_idx:$key"} = $junk_recs if @$junk_recs;
                }
            }
        }
    }

    if ( %batch_put ) {
        $adb->table_write($tmp_path)
          or do {
            cluck "[DB_TOOL] $tmp_path can't open.\n";
            return;
          };
        $adb->index_put( $tmp_path, \%batch_put, "ids" );
        $adb->table_close($tmp_path);

        unlink($file_path);
        rename( $tmp_path, $file_path );
        $self->{say} .= "          * $file_path created.\n";
    }
    else {
        unlink($file_path);
    }

    return 1;
}

# Rebuilds block index.
# my $ok = $tools->set_fields("tableid", @records);
# ------------------------------------------------
sub set_fields {

    my ( $self, $tableid, @records ) = @_;
    my $adb = $self->{_adb} or return;

    my $table_path = $adb->table_path($tableid);
    my $table_info = $adb->table_info($tableid);
    return unless $table_info;
    return 1 if $adb->config('simple') || $table_info->{use_simple} || ( $table_info->{id_type} && $table_info->{id_type} eq 'ascii' );
    return unless exists( $table_info->{match_block} );
    return unless -e "$table_path.$adb->{db_ext}";

    # Read records from table if absent
    if ( !scalar @records ) {
        @records = $adb->read_all($tableid, 0, 0, no_index => 1, dir => 'asc');
    }
    return unless scalar @records;

    my ( %fields, %act_fields, %junk_fields );

    my $unq_path = "${table_path}.unq";
    my $unq_opened = 0;
    if ( !$adb->{_db}->{$unq_path} ) {
        $adb->table_write($unq_path);
        $unq_opened = 1;
    }

    # Invert loops: outer loop @records (single pass), inner loop match_block
    my @match_blks = grep { /^\d+$/ } @{ $table_info->{match_block} };
    my $has_junk   = $table_info->{use_junk} ? 1 : 0;
    my $rdbm_recs  = $has_junk ? $adb->prefetch_junk_rdbm( $table_info, \@records ) : {};

    my $table_name = $table_info->{table} || $table_info->{id} || $tableid;

    # Preload unq into in-memory cache to eliminate per-record BDB disk lookups
    if ( $adb->{_tie}->{$unq_path} ) {
        my $tie = $adb->{_tie}->{$unq_path};
        for my $k ( keys %$tie ) {
            if ( $k =~ /^(\d+):s:(.*)$/s ) {
                $adb->set_cache( $table_name, "$1:$2", $tie->{$k} );
            }
            elsif ( $k =~ /^(\d+):lastid$/ ) {
                $adb->set_cache( $table_name, "$1:lastid", $tie->{$k} );
            }
        }
    }

    my $total_rec = scalar @records;
    my $prog_step = int($total_rec / 10) || 1000;
    my $count = 0;

    foreach my $record (@records) {
        $count++;
        if ( $total_rec > 1000 && $count % $prog_step == 0 ) {
            print "    ... processed $count / $total_rec records for field index\n";
        }
        my @fields_arr = @$record;
        my $rid = $fields_arr[0];
        next unless defined $rid && $rid =~ /^\d+$/;
        my $is_junk = $has_junk ? $adb->junk_rules( $table_info, \@fields_arr, $rdbm_recs ) : 0;

        foreach my $line (@match_blks) {
            my $val = $fields_arr[$line];
            next unless defined $val && $val ne '';

            my @num_ids;
            if ( !ref($val) && $val =~ /^\d+$/ && length($val) < 20 ) {
                @num_ids = ($val);
            }
            elsif ( !ref($val) && $val =~ /^[\d,;\s]+$/ ) {
                ( my $clean = $val ) =~ s/\s+//g;
                @num_ids = grep { /^\d+$/ } split /[,;]/, $clean;
            }
            else {
                @num_ids = $adb->set_fieldlist( $val, $table_path, $table_info, $line );
            }

            my %seen_nid;
            foreach my $nid (@num_ids) {
                next if $seen_nid{$nid}++;
                push @{ $fields{$line}{$nid} }, $rid;
                if ($has_junk) {
                    if ($is_junk) {
                        push @{ $junk_fields{$line}{$nid} }, $rid;
                    }
                    else {
                        push @{ $act_fields{$line}{$nid} }, $rid;
                    }
                }
            }
        }
    }

    if ($unq_opened) {
        $adb->table_close($unq_path);
    }

    $self->{say} .= "    - Fields fetch kayitlari olusturuluyor: \n";

    my $file_path = "${table_path}.fld";
    my $tmp_path  = "$file_path.tmp";

    unlink($tmp_path);

    my %batch_put;
    foreach my $line (@match_blks) {
        next unless $fields{$line};
        for my $val ( keys %{ $fields{$line} } ) {
            my $all_ids = $fields{$line}{$val};
            $batch_put{"$line:$val"} = $all_ids if @$all_ids;

            if ($has_junk) {
                if ( my $act_recs = $act_fields{$line}{$val} ) {
                    $batch_put{"A:$line:$val"} = $act_recs if @$act_recs;
                }
                if ( my $junk_recs = $junk_fields{$line}{$val} ) {
                    $batch_put{"B:$line:$val"} = $junk_recs if @$junk_recs;
                }
            }
        }
    }

    if ( %batch_put ) {
        $adb->table_write($tmp_path)
          or do {
            cluck "[DB_TOOL] $tmp_path can't open for write.\n";
            return;
          };
        $adb->index_put( $tmp_path, \%batch_put, "ids" );
        $adb->table_close($tmp_path);
        unlink($file_path);
        rename( $tmp_path, $file_path );

        $self->{say} .= "          * $file_path \n";
    }
    else {
        unlink($file_path);
    }

    return 1;
}

# Rebuilds facet forward index.
# Includes active_flag and "active" key.
# my $ok = $tools->set_filters("tableid", @records);
# ------------------------------------------------
sub set_filters {

    my ( $self, $tableid, @records ) = @_;
    my $adb = $self->{_adb} or return;

    return unless $tableid;
    my $table_path = $adb->table_path($tableid);
    return unless -e "$table_path.$adb->{db_ext}";

    my $table_info = $adb->table_info($tableid);
    return unless $table_info;
    return 1 if $adb->config('simple') || $table_info->{use_simple} || ( $table_info->{id_type} && $table_info->{id_type} eq 'ascii' );
    return unless exists( $table_info->{match_block} );
    return unless exists( $table_info->{use_facet} );

    my @fblocks  = @{ $table_info->{match_block} };
    my $has_active_rule = exists $table_info->{facet_rules};
    my $fac_path = "$table_path.fac";
    my $tmp_path = "$fac_path.tmp";

    # Read records from table if absent
    if ( !scalar @records ) {
        @records = $adb->read_all($tableid, 0, 0, no_index => 1, dir => 'asc');
    }
    scalar @records or return;

    unlink($tmp_path);

    $adb->table_write($tmp_path)
      or do {
        cluck "[DB_TOOL] $tmp_path can't open for write.\n";
        return;
      };

    $self->{say} .= "    - Facet forward index olusturuluyor: \n";

    my @active_ids;
    my %batch_facets;

    foreach my $record (@records) {
        my @fields = @$record;
        $fields[0] or next;
        my @pairs;
        foreach my $blk (@fblocks) {
            $blk =~ /^\d+$/ or next;
            next unless defined $fields[$blk] && $fields[$blk] ne '';
            my @vals;
            if    ( ref $fields[$blk] eq "ARRAY" ) { @vals = @{ $fields[$blk] } }
            elsif ( $fields[$blk] =~ /[,;]/ )      { @vals = split /\s*[,;]\s*/, $fields[$blk] }
            else                                    { @vals = ( $fields[$blk] ) }
            push @pairs, "$blk:$_" for @vals;
        }
        next unless @pairs;
        my $is_active = $adb->facet_rules( $table_info, @fields );
        push @active_ids, $fields[0] if $is_active && $has_active_rule;
        $batch_facets{ $fields[0] } = join( "\t", $is_active, @pairs );
    }

    if ( %batch_facets ) {
        $adb->index_put( $tmp_path, \%batch_facets, "raw" );
    }

    # "active" key: write all active IDs if facet_rules defined
    if ( $has_active_rule && @active_ids ) {
        $adb->index_put( $tmp_path, "active", \@active_ids, "ids" );
    }

    $adb->table_close($tmp_path);

    unlink($fac_path);
    rename( $tmp_path, $fac_path );

    $self->{say} .= "          * $fac_path \n";

    return 1;
}

# Rebuilds ReWrite links.
# my $ok = $tools->set_rwlnkall($tableid);
# my $ok = $tools->set_rwlnkall($tableid, @records);
# ------------------------------------------------
sub set_rwlnkall {

    my ( $self, $tableid, @records ) = @_;
    my $adb = $self->{_adb} or return;

    my $table_path = $adb->table_path($tableid);
    return unless -e "$table_path.$adb->{db_ext}";

    my $table_info = $adb->table_info($tableid);
    return unless $table_info;
    return 1 if $adb->config('simple') || $table_info->{use_simple} || ( $table_info->{id_type} && $table_info->{id_type} eq 'ascii' );
    return unless $table_info->{slug_block};

    # Read records from table if input is empty
    if ( !scalar @records ) {
        (@records) = $adb->read_all($tableid, 0, 0, no_index => 1, dir => 'asc');
        @records = grep { ref($_) eq 'ARRAY' } @records;
        if ( !scalar @records ) {
            cluck "[DB_TOOL] No records found for ReWrite in $tableid.\n";
            return;
        }
    }
    else {
        @records = grep { ref($_) eq 'ARRAY' } @records;
    }

    # Rebuild unified slug file.
    my $slg_path = "${table_path}.slg";
    my $tmp_path = "$slg_path.tmp";

    unlink($tmp_path);

    my @slg_records;
    my %seen_links;

    @records = $adb->db_sortid( $tableid, @records );
    foreach my $record (@records) {
        my $rw_link = $adb->set_slug( $tableid, $record );
        next unless defined $rw_link && length $rw_link;
        if ( exists $seen_links{$rw_link} ) {
            $rw_link .= "-$record->[0]";
        }
        $seen_links{$rw_link} = $record->[0];
        push @slg_records, [ "0:$record->[0]", $rw_link ];
        push @slg_records, [ "1:$rw_link", $record->[0] ];
    }

    if ( @slg_records ) {
        $adb->table_write($tmp_path)
          or do {
            cluck "[DB_TOOL] $tmp_path can't be written.\n";
            return 0;
          };
        $adb->recs_put( $tmp_path, @slg_records );
        $adb->table_close($tmp_path);

        unlink($slg_path);
        rename( $tmp_path, $slg_path );

        $self->{say} .= "    - Slug indexes are being created.: \n";
        $self->{say} .= "          * $slg_path \n";
    }
    else {
        unlink($slg_path);
    }

    return 1;
}

# Rebuilds sort index within .inx ($blk:keys).
# my $ok = $tools->set_sort($tableid, @records);
# ------------------------------------------------
sub set_sort {

    my ( $self, $tableid, @records ) = @_;
    my $adb = $self->{_adb} or return;

    return unless $tableid;
    my $table_path = $adb->table_path($tableid);
    my $table_info = $adb->table_info($tableid);
    return unless $table_info;
    return 1 if $adb->config('simple') || $table_info->{use_simple} || ( $table_info->{id_type} && $table_info->{id_type} eq 'ascii' );
    return unless exists $table_info->{sort_block};

    if ( !@records ) {
        @records = $adb->read_all( $tableid, 0, 0, no_index => 1, dir => 'asc' );
    }

    my $has_junk  = $table_info->{use_junk};
    my $junk_rdbm = $has_junk ? $adb->prefetch_junk_rdbm( $table_info, \@records ) : {};

    my ( %keys_batch, %raw_batch );
    foreach my $cfg ( @{ $table_info->{sort_block} } ) {
        my ( $blk, $type, $len ) = ref($cfg) eq 'HASH'
            ? ( $cfg->{blk}, $cfg->{type}, $cfg->{len} // 8 )
            : ( $cfg, 'string', 8 );

        my %map;
        my ( %act_map, %junk_map );
        foreach my $rec (@records) {
            next unless ref($rec) eq 'ARRAY' && defined $rec->[0];
            my $rid  = $rec->[0];
            my $norm = $adb->normalize_sort_key( $rec->[$blk], $type, $len );
            $map{$rid} = $norm;

            if ($has_junk) {
                my $is_junk = $adb->junk_rules( $table_info, $rec, $junk_rdbm );
                if ($is_junk) {
                    $junk_map{$rid} = $norm;
                }
                else {
                    $act_map{$rid} = $norm;
                }
            }
        }

        # Sort all keys in-memory with deterministic tie-breaker
        my @sorted_ids = sort {
            ( ( $map{$a} // '' ) cmp ( $map{$b} // '' ) )
              || ( $a <=> $b )
        } keys %map;

        $keys_batch{"$blk:keys"} = \@sorted_ids;
        foreach my $k ( keys %map ) {
            $raw_batch{"$blk:$k"} = $map{$k};
        }

        if ($has_junk) {
            my @sorted_act = sort {
                ( ( $act_map{$a} // '' ) cmp ( $act_map{$b} // '' ) )
                  || ( $a <=> $b )
            } keys %act_map;
            $keys_batch{"A:$blk:keys"} = \@sorted_act;

            my @sorted_junk = sort {
                ( ( $junk_map{$a} // '' ) cmp ( $junk_map{$b} // '' ) )
                  || ( $a <=> $b )
            } keys %junk_map;
            $keys_batch{"B:$blk:keys"} = \@sorted_junk;
        }
    }

    if ( %keys_batch || %raw_batch ) {
        my $inx_path = "${table_path}.inx";
        if ( $adb->table_write($inx_path) ) {
            $adb->index_put( $inx_path, \%keys_batch, "ids" ) if %keys_batch;
            $adb->index_put( $inx_path, \%raw_batch,  "raw" ) if %raw_batch;
            $adb->table_close($inx_path);
        }
    }

    unlink("${table_path}.srt");

    $self->{say} .= "    - Sort indexes created in ${table_path}.inx for table $tableid.\n";
    return 1;
}

# Rebuilds index for all tables
# my $ok = $tools->index_alltables();
# print $self->{say};
# ------------------------------------------------
sub index_alltables {

    my ($self) = @_;
    my $adb = $self->{_adb} or return;

    my @tables;

    # 1. Locate tables.
    my $tables_hash = $self->all_tables();
    foreach my $dbase ( keys %$tables_hash ) {
        $dbase =~ /^[a-z0-9]+$/ or next;
        foreach my $tableid ( keys %{ $tables_hash->{$dbase} } ) {
            $tableid =~ /^[a-z0-9_]+$/ or next;
            my $table_path = $adb->table_path($tableid);
            push @tables, [ $tableid, "$table_path.$adb->{db_ext}" ];
        }
    }

    # 2. Read table records and enter indexing loop
    foreach my $table_entry (@tables) {
        my $tbl = $table_entry->[0];
        my @records = $adb->read_all($tbl, 0, 0, no_index => 1, dir => 'asc');

        my $count = scalar @records;
        $self->set_index( $tbl, @records );

        $self->{say} .=
          "Table: $tbl, Record count: $count\n";
    }
}

# Verifies validity of Read All index
# my $diff = $tools->check_readall($tableid, @records);
# ------------------------------------------------
sub check_readall {

    my ( $self, $tableid, @records ) = @_;
    my $adb = $self->{_adb} or return;

    return unless $tableid;
    my $table_path = $adb->table_path($tableid);
    my $table_info = $adb->table_info($tableid);

    my ( %diff, %recs );
    foreach my $rec (@records) {
        $rec = $rec->[0] if ref $rec eq "ARRAY";
        next unless defined $rec && $rec ne "";
        $recs{keys}->{$rec} = 1;
        $recs{lastid} ||= $rec;
        $rec > $recs{lastid} and $recs{lastid} = $rec;
    }

    my (%inds);
    my $inx_path = "$table_path.inx";
    my ( $total_keys, @keys ) = $adb->index_get( $inx_path, "keys", "ids" );
    $adb->table_close($inx_path);
    foreach my $rec (@keys) {
        $inds{keys}->{$rec} = 1;
        $inds{lastid} ||= $rec;
        $rec > $inds{lastid} and $inds{lastid} = $rec;
    }

    if ( ( $recs{lastid} // "" ) ne ( $inds{lastid} // "" ) ) {
        $diff{lastid}->{recs} = $recs{lastid};
        $diff{lastid}->{inds} = $inds{lastid};
    }

    my $diffs = $adb->hash_diff( $recs{keys}, $inds{keys} );

    if ( $diffs->{hash1} ) {
        $diff{keys}->{recs} = $diffs->{hash1};
    }
    if ( $diffs->{hash2} ) {
        $diff{keys}->{inds} = $diffs->{hash2};
    }

    return \%diff;
}

# Rebuilds search word index.
# my $ok = $tools->check_search($tableid, @records);
# ------------------------------------------------
sub check_search {

    my ( $self, $tableid, @records ) = @_;
    my $adb = $self->{_adb} or return;

    my %diff = ();
    return unless $tableid;
    scalar @records or return \%diff;
    my $table_path = $adb->table_path($tableid);
    my $table_info = $adb->table_info($tableid);
    exists( $table_info->{search_block} ) or return \%diff;

    foreach my $line (@records) {
        my @fields = @$line;
        foreach my $src ( @{ $table_info->{search_block} } ) {
            $src =~ /^[0-9]+$/ or next;
            my %words = $adb->get_words( $fields[$src], "write" );

            foreach my $word ( keys %words ) {
                $diff{recs}->{$src}->{$word}->{ $fields[0] } = 1;
            }
        }
    }

    my $unified_src = "${table_path}.src";
    if ( -e $unified_src ) {
        if ( $adb->table_read($unified_src) ) {
            $adb->recs_scan(
                $unified_src,
                sub {
                    my ( $k, $records ) = @_;
                    my ( $src, $word ) = split( /:/, $k, 2 );
                    return unless defined $src && defined $word;
                    my ( undef, @rids ) = $adb->bin_decode($records);
                    foreach my $rid (@rids) {
                        if ( exists( $diff{recs}->{$src}->{$word}->{$rid} ) ) {
                            delete( $diff{recs}->{$src}->{$word}->{$rid} );
                        }
                        else {
                            $diff{inds}->{$src}->{$word}->{$rid} = 1;
                        }
                    }
                }
            );
            $adb->table_close($unified_src);
        }
    }

    return \%diff;
}

# my $ok = $tools->tie2csv("dbase_table");
# print $self->{say} if($ok);
# ---------------------------------------------------------------------
sub tie2csv {

    my ( $self, $tableid ) = @_;
    my $adb = $self->{_adb} or return;

    $tableid or return;
    my $table_path = $adb->table_path($tableid);

    my $i = 1;
    if ( -e "$table_path.csv" ) {
        my $day_id = $adb->{date}->{day_id} || 'backup';
        rename( "$table_path.csv", "$table_path-$day_id.csv" );
    }

    # cevirme islemlerini yap
    my $tie_path = "${table_path}.$adb->{db_ext}";
    return 1 unless -e $tie_path;
    $adb->table_read($tie_path) or return 1;

    my %data;
    $adb->recs_scan(
        $tie_path,
        sub {
            my ( $k, $v ) = @_;
            $data{$k} = $v;
        }
    );
    $adb->table_close($tie_path);

    my @uids = $adb->db_sortid( $tableid, keys %data );
    open my $fh, ">", "$table_path.csv" or do {
        cluck "[DB_TOOL] Could not open $table_path.csv: $!\n";
        return;
    };
    foreach my $uid (@uids) {
        my @fields = $adb->db_decode( $data{$uid} );
        my $record = $adb->tsv_encode( $uid, @fields );
        print $fh "$record\n";
        $self->{say} .= "$i. $uid ID record converted.\n\n";
        $i++;
    }
    close $fh;
    $adb->table_close($tie_path);

    return 1;
}

# $tools->{ISO2UTF} = 1;
# my $ok = $tools->csv2tie("file");
# ---------------------------------------------------------------------
sub csv2tie {

    my ( $self, $tableid ) = @_;
    my $adb = $self->{_adb} or return;

    $tableid or return;

    # file paths
    my $table_path = $adb->table_path($tableid);
    my $file_path  = "${table_path}.$adb->{db_ext}";
    my $csv_path   = "$table_path.csv";
    return unless -e $csv_path;

    # backup with timestamp if exists
    if ( -e "${table_path}.$adb->{db_ext}" ) {
        my $sec_id = $adb->{date}->{second_id} || time();
        rename( "${table_path}.$adb->{db_ext}",
            "${table_path}-$sec_id.$adb->{db_ext}" );
        unlink("${table_path}.$adb->{db_ext}");
    }

    # perform conversion operations
    my $i = 1;
    my @records;

    open my $FH, "<", $csv_path or do {
        cluck "[DB_TOOL] Could not open $csv_path: $!\n";
        return;
    };
    $adb->table_write($file_path) or do {
        close $FH;
        cluck "[DB_TOOL] Could not open $file_path for writing.\n";
        return;
    };
    my @chunk;
    while ( my $record = <$FH> ) {
        chomp($record);
        $record =~ s/\r$//;
        my (@fields) = $adb->db_decode($record);
        push @chunk, [@fields];
        if ( @chunk >= 2000 ) {
            $adb->recs_put( $file_path, @chunk );
            @chunk = ();
        }

        # collect into list for indexing
        push @records, [@fields];
        $self->{say} .= "$i. Record ID $fields[0] converted.\n\n" if $i % 1000 == 0;
        $i++;
    }
    if ( @chunk ) {
        $adb->recs_put( $file_path, @chunk );
    }
    close $FH;
    $adb->table_close($file_path);

    $self->set_index( $tableid, @records );

    return 1;
}

# my @tables = $tools->dir_tables();
# ------------------------------------------------
sub dir_tables {

    my ( $self, $dir ) = @_;
    my $adb = $self->{_adb} or return;

    $dir or return;
    my $target_dir = File::Spec->catdir( $adb->path('dbase_dir') || ".", $dir );
    my $ext        = $adb->{db_ext} || "db";
    my @names      = $adb->dir_files( $target_dir, "*.$ext", full_path => 0 );

    my %all_tables = map { /^(.+)\.\Q$ext\E$/i ? ( $1 => 1 ) : () } @names;

    return sort { $a cmp $b } keys %all_tables;
}

# my @tables = $tools->vacuum($tableid, 1);
# ------------------------------------------------
sub vacuum {

    my ( $self, $tableid, $reindex ) = @_;
    my $adb = $self->{_adb} or return;

    my $table_path = $adb->table_path($tableid);
    my $tie_path   = "$table_path.$adb->{db_ext}";
    return unless -e $tie_path;

    my $sec_id = $adb->{date}->{second_id} || time();
    my $pid_name = "$sec_id-$$";
    my $tie_back = "$table_path-$pid_name.$adb->{db_ext}";
    my $csv_path = "$table_path.csv";
    my $csv_back = "$table_path-$pid_name.csv";

    # Backup and reset index structure
    my $table_info = $adb->table_info($tableid);
    $adb->table_attr( $tableid, {} );

    # Fetch records
    my $count   = {};
    my @records = $adb->read_all($tableid);
    $count->{tie1} = scalar @records;
    if ( !$count->{tie1} ) {
        cluck "[DB_TOOL] Cannot vacuum table $tableid as no records were found.\n";
        return;
    }

    -e $csv_path and rename( $csv_path, $csv_back );

    open my $FH, ">", $csv_path or do {
        cluck "[DB_TOOL] Could not create $csv_path. Check file permissions: $!\n";
        return;
    };
    foreach my $record (@records) {
        my $new_record = $adb->tsv_encode(@$record);
        print $FH "$new_record\n";
        $count->{csv1}++;
    }
    close $FH;

    # Reverse operation
    rename( $tie_path, $tie_back );

    open $FH, "<", $csv_path or do {
        cluck "[DB_TOOL] Could not open $csv_path for reading: $!\n";
        return;
    };
    $adb->table_write($tie_path);
    my @chunk;
    while ( my $record = <$FH> ) {
        chomp($record);
        $record =~ s/\r$//;
        my @fields = $adb->db_decode($record);
        push @chunk, [@fields];
        if ( @chunk >= 2000 ) {
            my $ok = $adb->recs_put( $tie_path, @chunk );
            $count->{tie2} += scalar @chunk if $ok;
            @chunk = ();
        }
    }
    if ( @chunk ) {
        my $ok = $adb->recs_put( $tie_path, @chunk );
        $count->{tie2} += scalar @chunk if $ok;
    }
    close $FH;
    $adb->table_close($tie_path);

    $adb->table_attr( $tableid, $table_info );
    $self->set_index( $tableid, @records ) if $reindex;
    $self->{say} .= "Vacuum completed. Record counts: Tie old: $count->{tie1}, CSV: $count->{csv1}, Tie new: $count->{tie2}\n";

    return 1;
}

# my $tables_hash = $tools->all_tables(); # scalar context -> grouped hashref
# my @table_list  = $tools->all_tables(); # list context   -> flat array of table IDs
# ------------------------------------------------
sub all_tables {

    my ($self) = @_;
    my $adb = $self->{_adb} or return;

    my @all_tables;
    my %all_tables;

    my $dbase_dir  = $adb->path('dbase_dir')  || ".";
    my $year_dir   = $adb->path('year_dir')   || "";
    my $schema_dir = $adb->path('schema_dir') || "";

    # 1. Simple Mode: Single flat directory scan for files matching configured db_ext
    if ( $adb->config('simple') ) {
        my $ext = $adb->{db_ext} || "db";
        my @files = $adb->dir_files( $dbase_dir, "*.$ext", full_path => 0 );
        @all_tables = map { /^([a-z0-9_]+)\.\Q$ext\E$/i ? $1 : () } @files;
    }
    # 2. Standard Structured Mode: Multi-directory scan (table/ and year directories) for .db files
    else {
        my $tbl_dir = File::Spec->catdir( $dbase_dir, 'table' );
        push @all_tables, $adb->dir_files( $tbl_dir, "*.db", full_path => 0 ) if -d $tbl_dir;

        my %seen_dirs = ( "table" => 1, "schema" => 1, "backup" => 1, "lock" => 1, "ramdisk" => 1, "journal" => 1, "session" => 1, "config" => 1 );
        if ($year_dir) {
            my $yd_path = File::Spec->catdir( $dbase_dir, $year_dir );
            push @all_tables, $adb->dir_files( $yd_path, "*.db", full_path => 0 );
            $seen_dirs{$year_dir} = 1;
        }

        # Auto-discover any 4-digit year directories under $dbase_dir (e.g. 2024, 2025, 2026)
        if ( -d $dbase_dir ) {
            my @year_dirs = $adb->dir_files( $dbase_dir, qr/^\d{4}$/, full_path => 0, files_only => 0 );
            foreach my $yd (@year_dirs) {
                next if $seen_dirs{$yd} || !-d File::Spec->catdir( $dbase_dir, $yd );
                my $yd_path = File::Spec->catdir( $dbase_dir, $yd );
                push @all_tables, $adb->dir_files( $yd_path, "*.db", full_path => 0 );
            }
        }

        @all_tables = map { /^([a-z0-9_]+)\.db$/i ? $1 : () } @all_tables;
    }

    foreach my $record (@all_tables) {
        next unless $record;
        next if $record =~ /^_/; # skip internal / temp files

        if ( my ( $dbs, $tbl ) = ( $record =~ /^([a-z0-9]+)_(.+)$/i ) ) {
            $all_tables{$dbs}->{$record} = 1;
            if ( $schema_dir && !-e "$schema_dir/$dbs.dbase" ) {
                $all_tables{__NO_DBASE__}->{$dbs} = 1;
            }
            if ( $schema_dir && !-e "$schema_dir/$record.table" ) {
                $all_tables{__NO_TABLE__}->{$record} = 1;
            }
        }
        else {
            # Single-token table name without underscore
            $all_tables{_main}->{$record} = 1;
            if ( $schema_dir && !-e "$schema_dir/$record.table" ) {
                $all_tables{__NO_TABLE__}->{$record} = 1;
            }
        }
    }

    if (wantarray) {
        my @flat_list;
        foreach my $dbs ( sort keys %all_tables ) {
            next if $dbs =~ /^__/;
            push @flat_list, sort keys %{ $all_tables{$dbs} };
        }
        return @flat_list;
    }

    return \%all_tables;
}

# =====================================================================
# TABLE MIGRATION & HISTORICAL FORMAT CONVERSION ENGINE
# =====================================================================


# Helper to binary copy a file safely without external modules
sub _copy_file {
    my ( $self, $src, $dst ) = @_;
    return 0 unless -e $src;
    open my $in, '<:raw', $src or return 0;
    open my $out, '>:raw', $dst or do { close $in; return 0; };
    my $buf;
    while ( read( $in, $buf, 65536 ) ) {
        print $out $buf;
    }
    close $in;
    close $out;
    return 1;
}

# ---------------------------------------------------------------------
# update_table($tableid, %options)
# Scans an entire table record-by-record, detects any legacy formats (2003-2026),
# creates a timestamped backup with detected dominant version, and rewrites the table
# directly in ABR v1 format preserving original IDs.
# Rebuilds indexes using $self->set_index($tableid).
# Preserves companion data files ('del', 'aut').
# ---------------------------------------------------------------------
sub update_table {
    my ( $self, $tableid, %opts ) = @_;
    my $adb = $self->{_adb} or return;
    $tableid or return;

    my $table_path = $adb->table_path($tableid);
    my $ext        = $adb->{db_ext} || "db";
    my $file_path  = "$table_path.$ext";

    # Use exist_table to verify primary table existence
    return { status => 'not_found', table => $tableid }
      unless $adb->exist_table( $tableid );

    # Format modification timestamp: YYYY-MMDD
    my @mtime_parts = localtime( ( stat($file_path) )[9] || time() );
    my $mtime_str   = sprintf( "%04d-%02d%02d", $mtime_parts[5] + 1900, $mtime_parts[4] + 1, $mtime_parts[3] );

    # 1. Once mevcut tablodaki kayitlari tara
    my %format_counts;
    my $total                 = 0;
    my $already_current = 0;
    my $legacy_count    = 0;
    my @decoded_records;
    my $recovered_from_backup = 0;

    $adb->recs_scan( $file_path, sub {
        my ( $k, $v ) = @_;
        $total++;
        my $fmt = $adb->detect_record_format($v);
        $format_counts{$fmt}++;

        my @fields;
        if ( $fmt eq 'v5' ) {
            @fields = $adb->db_decode($v);
            $already_current++;
        }
        else {
            @fields = $adb->tsv_decode( $v, $k );
            $legacy_count++;
        }
        push @decoded_records, [ $k, @fields ];
        } );
    $adb->table_close($file_path);

    # Eger aktif dosya bos ise (ornegin onceki basarisiz bir calismada yedeklenip bos kalmissa):
    # Dizin icindeki yedek dosyasini bulup kayitlari oradan kurtar
    my $backup_file;
    if ( $total == 0 ) {
        my ( $pdir ) = $file_path =~ m{^(.*)[/\\]};
        $pdir //= ".";
        my @cand_backups;
        if ( opendir( my $dh, $pdir ) ) {
            while ( my $f = readdir($dh) ) {
                next if $f eq '.' || $f eq '..';
                if ( $f =~ /^\Q$tableid\E-.*?\.\Q$ext\E$/i ) {
                    push @cand_backups, "$pdir/$f";
                }
            }
            closedir($dh);
        }
        @cand_backups = sort { ( -s $b ) <=> ( -s $a ) } @cand_backups;
        for my $cb (@cand_backups) {
            next unless -e $cb && -s $cb;
            my @b_records;
            my %b_counts;
            my $b_legacy = 0;
            $adb->recs_scan( $cb, sub {
            my ( $k, $v ) = @_;
                my $fmt = $adb->detect_record_format($v);
                $b_counts{$fmt}++;
                my @fields = ( $fmt eq 'v5' ) ? $adb->db_decode($v) : $adb->tsv_decode( $v, $k );
                $b_legacy++ if $fmt ne 'v5';
                push @b_records, [ $k, @fields ];
        } );
            $adb->table_close($cb);
            if (@b_records) {
                @decoded_records       = @b_records;
                %format_counts         = %b_counts;
                $total                 = scalar @b_records;
                $legacy_count          = $b_legacy;
                $already_current       = $total - $b_legacy;
                $recovered_from_backup = 1;
                $backup_file           = $cb;
                last;
            }
        }
    }

    # 2. Eslikci veri dosyalarini ('del', 'aut') tara ve formatlarini tespit et
    my %companion_info;
    my $companion_legacy_total = 0;
    for my $cext (qw(del aut)) {
        next unless $adb->exist_table( $tableid, $cext );
        my $cfile = "$table_path.$cext";
        my $c_total   = 0;
        my $c_legacy  = 0;
        my $c_current = 0;
        my @c_decoded;

        $adb->recs_scan( $cfile, sub {
            my ( $ck, $cv ) = @_;
            $c_total++;
            my $cfmt = $adb->detect_record_format($cv);
            if ( $cfmt eq 'v5' ) {
                $c_current++;
                push @c_decoded, [ $ck, $adb->db_decode($cv) ];
            }
            else {
                $c_legacy++;
                push @c_decoded, [ $ck, $adb->tsv_decode( $cv, $ck ) ];
            }
        } );
        $adb->table_close($cfile);

        $companion_legacy_total += $c_legacy;
        $companion_info{$cext} = {
            exists  => 1,
            file    => $cfile,
            total   => $c_total,
            legacy  => $c_legacy,
            current => $c_current,
            decoded => \@c_decoded,
        };
    }

    # Eksik indeks dosyalarini kontrol et
    my $table_info = $adb->table_info($tableid);
    my $missing_indexes = 0;
    if ($table_info) {
        if ( $table_info->{record_index} && !-e "$table_path.inx" ) {
            $missing_indexes = 1;
        }
        if ( $table_info->{match_block} && !-e "$table_path.fld" ) {
            $missing_indexes = 1;
        }
        if ( $table_info->{use_facet} && !-e "$table_path.fac" ) {
            $missing_indexes = 1;
        }
    }

    # Eger ana tablo ve tum eslikci dosyalar zaten guncelse, eksik indeks yoksa ve force istenmemisse
    if ( $legacy_count == 0 && $companion_legacy_total == 0 && !$opts{force} && !$recovered_from_backup && !$missing_indexes ) {
        $self->{say} .= "Table '$tableid' is already up to date in ABR v1 format ($already_current records).\n";
        my $res = {
            status          => 'already_current',
            table           => $tableid,
            total           => $total,
            updated         => 0,
            already_current => $already_current,
        };
        for my $cext (qw(del aut)) {
            if ( my $ci = $companion_info{$cext} ) {
                $res->{"${cext}_status"} = ( $ci->{total} == 0 )
                  ? "0 records (empty)"
                  : "already ABR v1 ($ci->{total} records)";
            }
        }
        return $res;
    }

    # 3. En baskin eski formati tespit et
    my $dom_ver = 'v4';
    my $max_c   = -1;
    for my $v (qw(v4 v3 v2 v1)) {
        if ( ( $format_counts{$v} // 0 ) > $max_c ) {
            $max_c   = $format_counts{$v} // 0;
            $dom_ver = $v;
        }
    }

    # 4. Ana tablo donusumu (gerekliyse veya force ise)
    if ( $legacy_count > 0 || $recovered_from_backup || $opts{force} ) {
        # Eger yedekten kurtarilmadiysa, aktif dosyayi nihai yedek adiyla yedekle
        if ( !$recovered_from_backup ) {
    my $backup_base = "$table_path-$dom_ver-$mtime_str";
            $backup_file = "$backup_base.$ext";
    my $counter     = 1;
    while ( -e $backup_file ) {
        $backup_file = "$backup_base-$counter.$ext";
        $counter++;
    }
    rename( $file_path, $backup_file ) or do {
        cluck "[DB_TOOL] Could not backup $file_path to $backup_file: $!\n";
        return { status => 'error', table => $tableid, error => "Backup failed: $!" };
    };
        }

        # Yeni dosyayi sifir temiz yazma modunda ac
        $adb->table_close($file_path);
        $adb->clear_cache($tableid);
        my $new_db = $adb->table_write($file_path);
        unless ($new_db) {
            return { status => 'error', table => $tableid, error => "Could not open $file_path for writing" };
        }

        # Kayitlari yeni ikili ABR v1 formatinda tek tek yaz
        print "  - Writing $total records in ABR v1 format...\n";
        for my $rec (@decoded_records) {
            my ( $k, @fields ) = @$rec;
            my $v_new   = $adb->db_encode(@fields);
            my $k_enc   = $adb->utf_encode("$k");
            my $val_enc = $adb->utf_encode("$v_new");
            $new_db->put( $k_enc, $val_enc );
        }
        $adb->table_close($file_path);

        # Eski turetilen indeks dosyalarini temizle
    for my $iext (qw(inx src fld fac slg srt jinx jfld jsrc)) {
        my $idx_f = "$table_path.$iext";
        unlink $idx_f if -e $idx_f;
    }
    $adb->clear_cache($tableid);
    }
    else {
        $backup_file //= "None (already ABR v1)";
        print "  - Main table is already in ABR v1 format ($already_current records).\n";
    }

    # 5. Eslikci veri dosyalarini ('del', 'aut') donustur (indeks insasindan once calisir)
    my %companion_stats;
    for my $cext (qw(del aut)) {
        my $ci = $companion_info{$cext};
        next unless $ci;
        my $cfile = $ci->{file};

        if ( $ci->{legacy} > 0 || $opts{force} ) {
            if ( $ci->{total} > 0 ) {
                print "  - Migrating companion file ($cext: $ci->{total} records)...\n";
        my $c_backup_base = "$table_path-$dom_ver-$mtime_str.$cext";
        my $c_backup = $c_backup_base;
        my $cnt = 1;
        while ( -e $c_backup ) {
            $c_backup = "$table_path-$dom_ver-$mtime_str-$cnt.$cext";
            $cnt++;
        }
        rename( $cfile, $c_backup ) or next;

        my $new_cdb = $adb->table_write($cfile);
        if ($new_cdb) {
                    for my $crec ( @{ $ci->{decoded} } ) {
                my ( $ck, @cfields ) = @$crec;
                my $cv_new = $adb->db_encode(@cfields);
                $new_cdb->put( $adb->utf_encode("$ck"), $adb->utf_encode("$cv_new") );
            }
            $adb->table_close($cfile);
                    $companion_stats{"${cext}_migrated"} = $ci->{total};
            $companion_stats{"${cext}_backup"}   = $c_backup;
    }
    else {
            rename( $c_backup, $cfile );
    }
    }
            else {
                $companion_stats{"${cext}_status"} = "0 records (empty)";
            }
        }
        else {
            $companion_stats{"${cext}_status"} = "already ABR v1 ($ci->{total} records)";
        }
    }

    # 6. Indeksleri insa et (gerekliyse veya eksikse)
    my $is_simple = $adb->config('simple') || ( $table_info && $table_info->{use_simple} ) || ( $table_info && $table_info->{id_type} && $table_info->{id_type} eq 'ascii' );
    if ( $is_simple ) {
        print "  - Table '$tableid' is in simple mode, skipping index generation.\n";
    }
    elsif ( $legacy_count > 0 || $recovered_from_backup || $opts{force} ) {
        print "  - Rebuilding indexes...\n";
        eval {
            $self->set_index( $tableid, @decoded_records );
            1;
        } or do {
            warn "  [ERROR in set_index]: $@\n";
        };
    }
    elsif ($missing_indexes) {
        print "  - Rebuilding missing indexes...\n";
        eval {
            $self->set_index( $tableid, @decoded_records );
            1;
        } or do {
            warn "  [ERROR in set_index]: $@\n";
        };
    }

    # 7. Eslikci sozluk ve sayac (.unq, .cnt) dosyalarini koru ve yedekle
    my $has_unq = $adb->exist_table($tableid, 'unq');
    my $unq_backup;
    if ($has_unq) {
        my $unq_file = "$table_path.unq";
        my $u_backup_base = "$table_path-$dom_ver-$mtime_str.unq";
        $unq_backup = $u_backup_base;
        my $cnt = 1;
        while ( -e $unq_backup ) {
            $unq_backup = "$table_path-$dom_ver-$mtime_str-$cnt.unq";
            $cnt++;
        }
        require File::Copy;
        File::Copy::copy( $unq_file, $unq_backup );
    }

    my $has_cnt = $adb->exist_table($tableid, 'cnt');
    my $cnt_backup;
    if ($has_cnt) {
        my $cnt_file = "$table_path.cnt";
        my $c_backup_base = "$table_path-$dom_ver-$mtime_str.cnt";
        $cnt_backup = $c_backup_base;
        my $cnt = 1;
        while ( -e $cnt_backup ) {
            $cnt_backup = "$table_path-$dom_ver-$mtime_str-$cnt.cnt";
            $cnt++;
        }
        require File::Copy;
        File::Copy::copy( $cnt_file, $cnt_backup );
    }

    $self->{say} .= "Table '$tableid' updated to ABR v1: $total records migrated ($legacy_count converted, backup: $backup_file).\n";

    return {
        status          => ( ( $legacy_count > 0 || $companion_legacy_total > 0 || $recovered_from_backup || $opts{force} ) ? 'updated' : 'already_current' ),
        table           => $tableid,
        total           => $total,
        updated         => $legacy_count,
        already_current => $already_current,
        dominant_format => $dom_ver,
        backup_file     => $backup_file,
        del_migrated    => $companion_stats{del_migrated} // 0,
        del_backup      => $companion_stats{del_backup},
        del_status      => $companion_stats{del_status},
        aut_migrated    => $companion_stats{aut_migrated} // 0,
        aut_backup      => $companion_stats{aut_backup},
        aut_status      => $companion_stats{aut_status},
        has_unq         => $has_unq ? 1 : undef,
        unq_backup      => $unq_backup,
        has_cnt         => $has_cnt ? 1 : undef,
        cnt_backup      => $cnt_backup,
    };
}

# ---------------------------------------------------------------------
# update_all(%options)
# Iterates through all discovered tables and runs update_table on each.
# ---------------------------------------------------------------------
sub update_all {
    my ( $self, %opts ) = @_;
    my $adb = $self->{_adb} or return;

    my @tables = $self->all_tables();
    my @results;

    foreach my $table (@tables) {
        my $res = $self->update_table( $table, %opts );
        push @results, $res if $res;
    }

    return wantarray ? @results : \@results;
}

# my $ok = $tools->table_exist("tableid");
# ------------------------------------------------
sub table_exist {

    my ( $self, $table ) = @_;
    my $adb = $self->{_adb} or return 0;

    my $table_path = $adb->table_path($table);
    my $ok         = -e "$table_path.$adb->{db_ext}" ? 1 : 0;

    return $ok;
}

# my $status = dbase_tableold
# ------------------------------------------------
sub replace_tablename {

    my ( $self, $find, $replace ) = @_;
    my $adb = $self->{_adb} or return;

    my @tables;
    my $dbase_dir = $adb->path('dbase_dir') || ".";
    my $year_dir  = $adb->path('year_dir') || "";

    if ( $adb->config('simple') ) {
        @tables = glob "$dbase_dir/$find.*";
        push @tables, ( glob "$dbase_dir/${find}_*" );
    }
    else {
        @tables = glob "$dbase_dir/table/$find.*";
        push @tables, ( glob "$dbase_dir/table/${find}_*" );
        if ( $adb->config('use_section') ) {
            my @sections = glob "$dbase_dir/section_*";
            foreach my $sec_file (@sections) {
                push @tables, ( glob "$sec_file/$find.*" );
                push @tables, ( glob "$sec_file/${find}_*" );
            }
        }

        if ( $adb->config('use_year') && $year_dir ) {
            @tables = glob "$dbase_dir/$year_dir/$find.*";
            push @tables, ( glob "$dbase_dir/$year_dir/${find}_*" );
            if ( $adb->config('use_section') ) {
                my @sections = glob "$dbase_dir/$year_dir/section_*";
                foreach my $sec_file (@sections) {
                    push @tables, ( glob "$sec_file/${find}.*" );
                    push @tables, ( glob "$sec_file/${find}_*" );
                }
            }
        }
    }

    foreach my $old_file (@tables) {
        my $new_file = "$old_file";
        $new_file =~ s/\/$find([\.\_])/$replace$1/;
        rename( $old_file, $new_file );
    }
    $self->{say} .= "    - database table $find renamed to $replace.\n";

    return 1;
}

# my %files = (
# "dbase_table1" => 0,
# "dbase_table2" => 2,
# "dbase_table3" => { BLOCK => 1, START => 2, STARTBLOCK => 3 },
# );
# my %replace = (
# "fields1" => "new_fields1",
# "fields2" => "new_fields2",
# );
# my $status = $tools->replace_blockdata(\%files, \%replace);
# ------------------------------------------------
sub replace_blockdata {

    my ( $self, $files, $replace ) = @_;
    my $adb = $self->{_adb} or return {};

    my $status = {};
    ref($files) eq "HASH"   or return $status;
    ref($replace) eq "HASH" or return $status;

    while ( my ( $file, $block ) = each %{$files} ) {
        my @datas = $adb->read_all($file);
        foreach my $record (@datas) {
            my $change = 0;
            if ( $block =~ /^[0-9]+$/ ) {
                if ( exists( $replace->{ $record->[$block] } ) ) {
                    $record->[$block] = $replace->{ $record->[$block] };
                    $change = 1;
                }
            }
            elsif ( ref($block) eq "HASH" ) {
                if ( $block->{BLOCK} ) {
                    my $b = $block->{BLOCK};
                    if ( exists( $replace->{ $record->[$b] } ) ) {
                        $record->[$b] = $replace->{ $record->[$b] };
                        $change = 1;
                    }
                }

                if ( $block->{START} && $block->{STARTBLOCK} ) {
                    my $s = $block->{START};
                    my $b = $block->{STARTBLOCK};
                    foreach my $line ( @{$record}[ $s .. $#$record ] ) {
                        if ( exists( $replace->{ $line->[$b] } ) ) {
                            $line->[$b] = $replace->{ $line->[$b] };
                            $change = 1;
                        }
                    }
                }
            }
            if ($change) {
                $adb->modify_id( $file, @$record );
                $status->{$file}->{ $record->[0] } = 1;
                $self->{say} .= "          * $file: $record->[0] ID updated.\n";
            }
        }
    }

    return $status;
}

# my $table_path = $tools->del_table($tableid);
# ------------------------------------------------
sub del_table {

    my ( $self, $tableid ) = @_;
    my $adb = $self->{_adb} or return;

    $tableid or return;

    $adb->config('no_write') and return;

    my $table_path = $adb->table_path($tableid);
    return unless $table_path && -e "$table_path.$adb->{db_ext}";

    my ($parent_dir, $base_name) = $table_path =~ m{^(.+)[/\\]([^/\\]+)$};
    $parent_dir //= ".";
    $base_name  //= $table_path;

    my @files1 = $adb->dir_files( $parent_dir, qr/^\Q$base_name\E(?:\.[a-z0-9]+|_[0-9]+\.[a-z0-9]+)$/i );

    foreach my $file (@files1) {
        $adb->table_close($file);
        unlink($file);
        $self->{say} .= "          * $file deleted.\n";
    }

    $self->{say} .= "    - Table $tableid deleted.\n";

    return 1;
}

# my $db_obje = $tools->db_simple($datadir);
# ------------------------------------------------
sub db_simple {

    my ( $self, $dir, $ext ) = @_;

    $ext //= "db";
    require AmberDB;
    my $db_obje = AmberDB->new(
        ext  => { db        => $ext },
        path => { dbase_dir => $dir },
        cfg  => {
            simple  => 1,
        }
    );
    return $db_obje;
}

# Rebuilds and converts binary indexes for all tables in database directory.
# my $status = $tools->convert_tables();
# ------------------------------------------------
sub convert_tables {
    my ($self) = @_;
    my $adb = $self->{_adb} or return;

    my $db_dir = $adb->path('dbase_dir');
    return unless $db_dir && -d $db_dir;

    my @dirs = ($db_dir);
    push @dirs, File::Spec->catdir( $db_dir, 'table' ) if -d File::Spec->catdir( $db_dir, 'table' );

    my @db_files;
    foreach my $d (@dirs) {
        if ( opendir my $dh, $d ) {
            push @db_files, map { File::Spec->catfile( $d, $_ ) }
                            grep { /\.\Q$adb->{db_ext}\E$/ }
                            readdir($dh);
            closedir $dh;
        }
    }
    my %converted;

    foreach my $file (@db_files) {
        my ($tableid) = $file =~ /([^\\\/]+)\.\w+$/;
        next unless $tableid;
        next if $tableid =~ /^\_/;

        $self->{say} .= "Processing table $tableid...\n";
        my $ok = $self->set_index($tableid);
        if ($ok) {
            $converted{$tableid} = 1;
            $self->{say} .= "  -> Rebuilt packed binary indexes (.inx, .fld, .src) for $tableid\n";
        }
    }

    return \%converted;
}

# Creates a compressed, portable .amberdb archive containing table schemas,
# native data files (.db, .del, .aut, .cnt), and integrity manifest.
# my $archive = $tools->dump( [file => 'backup.amberdb'], [tables => ['t1', 't2']] );
# ---------------------------------------------------------------------
sub dump {
    my ( $self, %opts ) = @_;
    my $adb = $self->{_adb} or return;

    require Archive::Tar;
    require Digest::SHA;
    require JSON::PP;
    require File::Spec;
    require File::Path;

    # 1. Determine target tables
    my @tables;
    if ( $opts{tables} && ref( $opts{tables} ) eq 'ARRAY' ) {
        @tables = @{ $opts{tables} };
    }
    elsif ( $opts{table} ) {
        @tables = ( $opts{table} );
    }
    else {
        @tables = $self->all_tables();
    }
    return unless @tables;

    # 2. Flush and close open table handles for read consistency
    $adb->close_all();

    # 3. Determine output file path
    my $year = ( $adb->{date} && $adb->{date}->{year} ) ? $adb->{date}->{year} : (localtime)[5] + 1900;
    my $month = ( $adb->{date} && $adb->{date}->{month} ) ? $adb->{date}->{month} : sprintf( "%02d", (localtime)[4] + 1 );
    my $day = ( $adb->{date} && $adb->{date}->{day} ) ? $adb->{date}->{day} : sprintf( "%02d", (localtime)[3] );
    my $date_iso = "$year-$month-$day";
    my $time_id = ( $adb->{date} && $adb->{date}->{second_id} ) ? $adb->{date}->{second_id} : time();

    my $backup_base = $adb->path('backup_dir')
      || ( $adb->path('dbase_dir') ? $adb->path('dbase_dir') . "/backup" : "backup" );
    my $year_dir = "$backup_base/$year";
    $adb->make_path($year_dir);

    my $outfile = $opts{file} || "$year_dir/amberdb_${date_iso}_${time_id}.amberdb";

    # Ensure parent directory for $outfile exists
    if ( my ($outdir) = $outfile =~ m{^(.*)[/\\]} ) {
        $adb->make_path($outdir);
    }

    my $tar = Archive::Tar->new();

    my $manifest = {
        format          => "AmberDB Archive",
        format_version  => 1,
        amberdb_version => $AmberDB::VERSION || $VERSION,
        created_at      => "$date_iso " . sprintf( "%02d:%02d:%02d", (localtime)[2], (localtime)[1], (localtime)[0] ),
        dbase_dir       => $adb->path('dbase_dir'),
        tables          => {},
    };

    my $schema_dir = $adb->path('schema_dir')
      || ( $adb->path('dbase_dir') ? $adb->path('dbase_dir') . "/schema" : "schema" );

    # Collect .dbase database group schemas
    if ( -d $schema_dir ) {
        opendir( my $sdh, $schema_dir );
        my @dbase_files = grep { /\.dbase$/i } readdir($sdh);
        closedir $sdh;

        foreach my $df (@dbase_files) {
            my ($dbs) = $df =~ /^([^.]+)\.dbase$/i;
            next unless $dbs;

            # If dumping specific tables, only include matching dbase prefix
            if ( $opts{tables} || $opts{table} ) {
                my $matched = 0;
                foreach my $tid (@tables) {
                    if ( $tid =~ /^\Q$dbs\E_/ or $tid eq $dbs ) {
                        $matched = 1;
                        last;
                    }
                }
                next unless $matched;
            }

            my $dpath = "$schema_dir/$df";
            if ( -e $dpath ) {
                open my $dfh, "<:raw", $dpath or next;
                local $/ = undef;
                my $dcontent = <$dfh>;
                close $dfh;
                $tar->add_data( "schema/$df", $dcontent );
                $manifest->{dbases}->{$dbs} = "schema/$df";
            }
        }
    }

    foreach my $tid (@tables) {
        my $tpath = $adb->table_path($tid);
        my $db_file = "$tpath." . ( $adb->{db_ext} || "db" );
        next unless -e $db_file;

        my $table_manifest = {
            records => 0,
            files   => [],
            sha256  => {},
        };

        # A. Collect Schema file if exists
        my $schema_file = "$schema_dir/$tid.table";
        if ( -e $schema_file ) {
            open my $sfh, "<:raw", $schema_file or next;
            local $/ = undef;
            my $schema_content = <$sfh>;
            close $sfh;
            $tar->add_data( "schema/$tid.table", $schema_content );
            $table_manifest->{schema} = "schema/$tid.table";
        }

        # B. Count records from .db table safely
        my $count = scalar( $adb->table_keys($tid) ) || 0;
        $table_manifest->{records} = $count;

        # C. Collect data files (.db, .del, .aut, .cnt)
        # Suffixes that represent data, NOT derived indexes
        my @suffixes = ( ( $adb->{db_ext} || "db" ), "del", "aut", "cnt" );
        my $base_dir = $adb->path('dbase_dir') || ".";
        $base_dir =~ s{\\}{/}g;
        $base_dir =~ s{/$}{};

        foreach my $sfx (@suffixes) {
            my $fpath = "$tpath.$sfx";
            if ( -e $fpath ) {
                open my $dfh, "<:raw", $fpath or next;
                local $/ = undef;
                my $dcontent = <$dfh>;
                close $dfh;

                my $norm_fpath = $fpath;
                $norm_fpath =~ s{\\}{/}g;
                my $arch_path = $norm_fpath;
                if ( $norm_fpath =~ m{^\Q$base_dir\E/(.+)$} ) {
                    $arch_path = $1;
                }
                else {
                    $arch_path = "table/$tid.$sfx";
                }

                $tar->add_data( $arch_path, $dcontent );
                push @{ $table_manifest->{files} }, $arch_path;

                my $sha256 = Digest::SHA::sha256_hex($dcontent);
                $table_manifest->{sha256}->{$arch_path} = $sha256;
            }
        }

        # D. Collect Authoritative String Dictionary (.unq)
        my @unq_files = -e "${tpath}.unq" ? ("${tpath}.unq") : ();
        foreach my $fpath (@unq_files) {
            next unless -e $fpath;
            open my $dfh, "<:raw", $fpath or next;
            local $/ = undef;
            my $dcontent = <$dfh>;
            close $dfh;

            my $norm_fpath = $fpath;
            $norm_fpath =~ s{\\}{/}g;
            my $arch_path = $norm_fpath;
            if ( $norm_fpath =~ m{^\Q$base_dir\E/(.+)$} ) {
                $arch_path = $1;
            }
            else {
                my ($fname) = $fpath =~ m{([^/\\]+)$};
                $arch_path = "table/$fname";
            }

            $tar->add_data( $arch_path, $dcontent );
            push @{ $table_manifest->{files} }, $arch_path;

            my $sha256 = Digest::SHA::sha256_hex($dcontent);
            $table_manifest->{sha256}->{$arch_path} = $sha256;
        }

        $manifest->{tables}->{$tid} = $table_manifest;
    }

    # Add manifest.json to archive
    my $json = JSON::PP->new->utf8->pretty->encode($manifest);
    $tar->add_data( "manifest.json", $json );

    # Write tar.gz archive
    unless ( $tar->write( $outfile, Archive::Tar::COMPRESS_GZIP() ) ) {
        cluck "[DB_BACKUP] Failed to write archive $outfile: " . $tar->error() . "\n";
        return;
    }

    $self->{say} .= "Archive successfully written to $outfile (" . ( -s $outfile ) . " bytes)\n";
    return wantarray ? ( $outfile, $manifest ) : $outfile;
}

# Restores a .amberdb archive into target database, validates checksums,
# and deterministically rebuilds all binary indexes via set_index.
# my $res = $tools->restore( file => 'backup.amberdb', [force => 1], [reindex => 1] );
# ---------------------------------------------------------------------
sub restore {
    my ( $self, %opts ) = @_;
    my $adb = $self->{_adb} or return;

    my $file = $opts{file} or do {
        cluck "[DB_RESTORE] Missing required parameter 'file'.\n";
        return;
    };
    return unless -e $file;

    require Archive::Tar;
    require Digest::SHA;
    require JSON::PP;
    require File::Spec;
    require File::Path;

    my $tar = Archive::Tar->new();
    unless ( $tar->read($file) ) {
        cluck "[DB_RESTORE] Cannot read archive $file: " . $tar->error() . "\n";
        return;
    }

    # 1. Read and parse manifest.json
    my $manifest_content = $tar->get_content("manifest.json");
    unless ($manifest_content) {
        cluck "[DB_RESTORE] Archive $file is missing manifest.json.\n";
        return;
    }

    my $manifest = eval { JSON::PP->new->utf8->decode($manifest_content) };
    if ( $@ || ref($manifest) ne 'HASH' ) {
        cluck "[DB_RESTORE] Corrupted manifest.json in $file: $@\n";
        return;
    }

    # 2. Check if target DB is empty or force is set
    my $schema_dir = $adb->path('schema_dir')
      || ( $adb->path('dbase_dir') ? $adb->path('dbase_dir') . "/schema" : "schema" );
    my $table_dir = $adb->path('table_dir')
      || ( $adb->path('dbase_dir') ? $adb->path('dbase_dir') . "/table" : "table" );

    my $force = $opts{force} || $opts{overwrite};
    unless ($force) {
        # Check if existing schema or data files exist.
        # NOTE: Avoid calling table_path() here because it triggers
        # table_info() -> dbase_info() which caches empty hashes for
        # schemas that don't exist yet on the target, poisoning the
        # cache for the rest of the restore operation.
        my $has_existing = 0;
        my $db_ext = $adb->{db_ext} || "db";
        foreach my $tid ( keys %{ $manifest->{tables} || {} } ) {
            if ( -e "$table_dir/$tid.$db_ext" || -e "$schema_dir/$tid.table" ) {
                $has_existing = 1;
                last;
            }
        }
        if ($has_existing) {
            cluck "[DB_RESTORE] Target database is not empty. Use 'force => 1' to overwrite existing tables.\n";
            return;
        }
    }

    # Ensure target directories exist
    $adb->make_path($schema_dir);
    $adb->make_path($table_dir);

    # Flush all active handles before restoring
    $adb->close_all();

    my @restored_tables;
    my %table_filter = $opts{tables} ? map { $_ => 1 } @{ $opts{tables} } : ();

    # 3. Extract .dbase database group schemas
    if ( ref( $manifest->{dbases} ) eq 'HASH' ) {
        foreach my $dbs ( sort keys %{ $manifest->{dbases} } ) {
            my $arch_path = $manifest->{dbases}->{$dbs};
            my $scontent = $tar->get_content($arch_path);
            if ( defined $scontent ) {
                my $target_dbase = "$schema_dir/$dbs.dbase";
                open my $dfh, ">:raw", $target_dbase or do {
                    cluck "[DB_RESTORE] Cannot write dbase schema $target_dbase: $!\n";
                    return;
                };
                print $dfh $scontent;
                close $dfh;
            }
        }
    }

    # 4. Extract table schemas and data files
    my $base_dir = $adb->path('dbase_dir') || ".";
    $base_dir =~ s{\\}{/}g;
    $base_dir =~ s{/$}{};

    foreach my $tid ( sort keys %{ $manifest->{tables} || {} } ) {
        next if ( %table_filter && !$table_filter{$tid} );

        my $tinfo = $manifest->{tables}->{$tid};

        # A. Restore Schema
        if ( $tinfo->{schema} ) {
            my $scontent = $tar->get_content( $tinfo->{schema} );
            if ( defined $scontent ) {
                my $target_schema = "$schema_dir/$tid.table";
                open my $sfh, ">:raw", $target_schema or do {
                    cluck "[DB_RESTORE] Cannot write schema $target_schema: $!\n";
                    return;
                };
                print $sfh $scontent;
                close $sfh;
            }
        }

        # B. Restore Data Files (.db, .del, .aut, .cnt)
        my $tpath = $adb->table_path($tid);

        foreach my $arch_path ( @{ $tinfo->{files} || [] } ) {
            my $dcontent = $tar->get_content($arch_path);
            next unless defined $dcontent;

            # Verify checksum if present
            if ( my $expected_sha = $tinfo->{sha256}->{$arch_path} ) {
                my $actual_sha = Digest::SHA::sha256_hex($dcontent);
                if ( $expected_sha ne $actual_sha ) {
                    cluck "[DB_RESTORE] Checksum mismatch for $arch_path! Expected $expected_sha, got $actual_sha.\n";
                    return;
                }
            }

            # Native archive path: e.g. table/products.db or 2026/sales.db
            my $target_file = "$base_dir/$arch_path";

            if ( my ($tdir) = $target_file =~ m{^(.*)[/\\]} ) {
                $adb->make_path($tdir);
            }

            open my $dfh, ">:raw", $target_file or do {
                cluck "[DB_RESTORE] Cannot write data file $target_file: $!\n";
                return;
            };
            print $dfh $dcontent;
            close $dfh;
        }

        push @restored_tables, $tid;
    }

    # 5. Rebuild all indexes if reindex is requested (default: 1)
    my $reindex = defined $opts{reindex} ? $opts{reindex} : 1;
    if ($reindex) {
        foreach my $tid (@restored_tables) {
            $self->set_index($tid);
        }
    }

    $self->{say} .= "Restored " . scalar(@restored_tables) . " tables from $file.\n";

    return {
        ok             => 1,
        file           => $file,
        tables         => \@restored_tables,
        manifest       => $manifest,
        reindexed      => $reindex ? 1 : 0,
    };
}

1;


__END__

=head1 NAME

AmberDB::Tools - Database maintenance, CLI reindexing, and bulk conversion toolset

=head1 SYNOPSIS

  use AmberDB;
  use AmberDB::Tools;

  my $adb   = AmberDB->new(path => { dbase_dir => "/path/to/dbstore" });
  my $tools = AmberDB::Tools->new($adb);

  # 1. Create portable .amberdb database backup archive
  my $archive = $tools->dump();

  # 2. Restore database archive with integrity validation and reindexing
  my $result  = $tools->restore(file => "backup.amberdb", force => 1);

  # 3. Rebuild all indexes for a single table (.inx, .src, .fld, .fac)
  $tools->set_index("catalog_product");

  # 4. Rebuild only specific index components
  $tools->set_search("catalog_product");  # Rebuild full-text search index
  $tools->set_fields("catalog_product");  # Rebuild field exact match index
  $tools->set_filters("catalog_product"); # Rebuild facet forward filter index
  $tools->set_sort("catalog_product");    # Rebuild binary pre-sorted sequences in .inx

  # 5. Batch reindex / convert all tables in database directory
  my $report = $tools->convert_tables();

=head1 DESCRIPTION

C<AmberDB::Tools> provides maintenance, native disaster recovery archiving (C<dump>/C<restore>), and batch utility functions for rebuilding indexes, populating full-text search inverted files, compiling forward facet filter dictionaries, generating binary sort matrices, and running automated database-wide index migrations.

AmberDB maintenance and indexing operations can also be invoked directly from the terminal using C<bin/amberdb_cli.pl> (e.g. C<perl bin/amberdb_cli.pl action=reindex table=products>) and C<bin/amberdb_setup.pl>. See C<perldoc bin/amberdb_cli.pl>.

=head1 CONSTRUCTOR

=head2 new($adb, [%options])

Creates an C<AmberDB::Tools> instance associated with an active C<AmberDB> object handle.

  my $tools = AmberDB::Tools->new($adb);

=head1 METHODS

=head2 dump([%options])

Creates a compressed, portable C<.amberdb> archive file (gzipped tar archive) containing table and database schemas (C<schema/*.table>, C<schema/*.dbase>), native database data files (C<table/*.db>, C<table/*.del>, C<table/*.aut>, C<table/*.cnt>), and a cryptographically verified SHA-256 C<manifest.json>.

Options:

=over 4

=item * C<file>: Custom output file path (defaults to C<backup/YYYY/amberdb_YYYY-MM-DD_time.amberdb>).

=item * C<tables>: Array reference of table IDs to include (defaults to all tables in database).

=item * C<table>: Single table ID to export as a focused snapshot.

=back

  my $archive = $tools->dump();
  my $archive = $tools->dump(tables => ["catalog_product", "orders_cart"]);

=head2 restore(%options)

Restores a C<.amberdb> archive into the target database. Validates archive integrity via SHA-256 checksums in C<manifest.json>, extracts schemas and data files, and deterministically reconstructs all binary indexes (C<.inx>, C<.src>, C<.fld>, C<.fac>) via C<set_index>.

Options:

=over 4

=item * C<file>: Path to C<.amberdb> archive file (required).

=item * C<force>: Boolean (default 0). Must be set to 1 to overwrite existing tables in a non-empty database directory.

=item * C<reindex>: Boolean (default 1). Automatically executes C<set_index> for all restored tables.

=item * C<tables>: Array reference of specific table IDs to extract from the archive.

=back

  my $res = $tools->restore(file => "backup.amberdb", force => 1);

=head2 set_index($table_id, [@records])

Rebuilds all secondary and primary indexes for C<$table_id> based on its schema definition:

=over 4

=item * Primary key index (C<.inx>) via C<set_readall>

=item * Full-text search inverted indexes (C<.src>) via C<set_search>

=item * Inverted field match indexes (C<.fld>) via C<set_fields>

=item * Columnar facet filter forward indexes (C<.fac>) via C<set_filters>

=item * Monotonic binary pre-sorted record indexes (within C<.inx>) via C<set_sort>

=back

If C<@records> is omitted, reads all records from the base table automatically.

  $tools->set_index("catalog_product");

=head2 set_readall($table_id, [@ids])

Rebuilds the primary C<.inx> index file, populating C<keys> (compact binary packed list of IDs), C<count>, and C<lastid>.

  $tools->set_readall("catalog_product");

=head2 set_search($table_id, [@records])

Scans records, tokenizes text according to schema C<search_block>, and builds inverted keyword index file (C<.src>).

  $tools->set_search("catalog_product");

=head2 set_fields($table_id, [@records])

Builds inverted exact match index file (C<.fld>) for fields specified in schema C<match_block>.

  $tools->set_fields("catalog_product");

=head2 set_filters($table_id, [@records])

Builds columnar facet forward index files (C<.fac>) and bidirectional string dictionary (C<.unq>) for blocks configured in schema C<facet_block>.

  $tools->set_filters("catalog_product");

=head2 set_sort($table_id, [@records])

Builds monotonic binary pre-sorted index sequences within C<.inx> (C<$blk:keys>) according to schema C<sort_block>.

  $tools->set_sort("catalog_product");

=head2 convert_tables()

Scans the entire database directory, identifies all physical tables, and sequentially runs C<set_index> to rebuild and migrate packed binary indexes across the entire system. Returns a status hash reference.

  my $status = $tools->convert_tables();

=head1 AUTHOR

Maruf Cetin <marufcetin@gmail.com>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2018-2026 Maruf Cetin.

This library is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0.

=cut

