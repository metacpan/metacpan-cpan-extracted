package AmberDB::Tools::Index;

use 5.016;
use warnings;
use strict;
use Carp qw(croak cluck);
use File::Spec;

our $VERSION = '5.26.0';
my $CREATED = '2018-10-08';

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

    # 1. Clean up previous index files on physical storage and RAM-disk before rebuilding
    my @idx_exts = qw( inx src fld fac slg unq );
    for my $ext (@idx_exts) {
        my $p_file = "$table_path.$ext";
        if ( -e $p_file ) {
            $adb->table_close($p_file);
            unlink $p_file;
        }
    }
    if ( $adb->ramdisk_is_mounted() ) {
        my $rm_path = $adb->ramdisk_path($tableid);
        if ($rm_path) {
            for my $ext (@idx_exts) {
                my $rm_file = "$rm_path.$ext";
                if ( -e $rm_file ) {
                    $adb->table_close($rm_file);
                    unlink $rm_file;
                }
            }
        }
    }
    $adb->clear_cache($tableid);

    # 2. Read records if list empty.
    if ( !@records ) {
        @records = $adb->read_all($tableid, 0, 0, no_index => 1, dir => 'asc');
    }
    return unless scalar @records;

    # Pre-fetch foreign records for junk_rules in one batch before sub-indexers run
    if ( $table_info->{use_junk} ) {
        $self->{say} .= "    - Pre-fetching relational foreign records for junk rules...\n";
        $adb->prefetch_junk_rdbm( $table_info, \@records );
    }

    # 3. Create readall index
    if ( exists( $table_info->{record_index} ) ) {
        $self->{say} .= "    - Rebuilding readall index (.inx)...\n";
        my $ok = $self->set_readall( $tableid, @records );
    }

    # 4. Create search index
    if ( exists( $table_info->{search_block} ) ) {
        $self->{say} .= "    - Rebuilding search index (.src)...\n";
        my $ok = $self->set_search( $tableid, @records );
    }

    # 5. Create fetch field index.
    if ( exists( $table_info->{match_block} ) ) {
        $self->{say} .= "    - Rebuilding field index (.fld)...\n";
        my $ok = $self->set_fields( $tableid, @records );
    }

    # 6. Create facet index.
    if ( exists( $table_info->{use_facet} ) ) {
        $self->{say} .= "    - Rebuilding facet index (.fac)...\n";
        my $ok = $self->set_filters( $tableid, @records );
    }

    # 7. Create sort index.
    if ( exists( $table_info->{sort_block} ) ) {
        $self->{say} .= "    - Rebuilding sort index (.inx)...\n";
        my $ok = $self->set_sort( $tableid, @records );
    }

    # 8. Create URL slug index
    if ( exists( $table_info->{slug_block} ) ) {
        $self->{say} .= "    - Rebuilding slug index (.slg)...\n";
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

    # 10. If RAM-disk is active, sync freshly built index files to RAM-disk
    if ( $adb->ramdisk_is_mounted() ) {
        my $rm_path = $adb->ramdisk_path($tableid);
        if ($rm_path) {
            require File::Copy;
            for my $ext (@idx_exts) {
                my $src_file = "$table_path.$ext";
                my $dst_file = "$rm_path.$ext";
                if ( -e $src_file ) {
                    $adb->table_close($src_file);
                    $adb->table_close($dst_file);
                    unlink $dst_file if -e $dst_file;
                    File::Copy::copy( $src_file, $dst_file );
                    chmod 0777, $dst_file if -e $dst_file;
                }
            }
        }
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
    @all_records = grep { defined $_ && /^\d+$/ && $_ > 0 } @all_records;

    my ( @active_records, @junk_records );
    my $has_junk = $table_info->{use_junk} ? 1 : 0;

    # Accept both full record arrayrefs [ $id, @data ] and scalar ID lists
    if ( ref $records[0] eq "ARRAY" ) {
        if ($has_junk) {
            my $rdbm_recs = $adb->prefetch_junk_rdbm( $table_info, \@records );
            for my $rec (@records) {
                my $rid = $rec->[0];
                next unless defined $rid && $rid =~ /^\d+$/ && $rid > 0;
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
                push @active_records, $rid if defined $rid && $rid =~ /^\d+$/ && $rid > 0;
            }
        }
    }
    else {
        my @clean_rids = grep { defined $_ && /^\d+$/ && $_ > 0 } @records;
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
    @active_records = grep { defined $_ && /^\d+$/ && $_ > 0 && !$seen_act{$_}++ } @active_records;
    my %seen_junk;
    @junk_records   = grep { defined $_ && /^\d+$/ && $_ > 0 && !$seen_junk{$_}++ } @junk_records;


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
        $adb->table_close($index_path);
        unlink($index_path);
        rename( $tmp_path, $index_path ) or do {
            require File::Copy;
            File::Copy::move( $tmp_path, $index_path );
        };
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
        $adb->table_close($file_path);
        unlink($file_path);
        rename( $tmp_path, $file_path ) or do {
            require File::Copy;
            File::Copy::move( $tmp_path, $file_path );
        };
        $self->{say} .= "          * $file_path created.\n";
    }
    else {
        $adb->table_close($file_path);
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
            $self->{say} .= "    ... processed $count / $total_rec records for field index\n";
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
        $adb->table_close($file_path);
        unlink($file_path);
        rename( $tmp_path, $file_path ) or do {
            require File::Copy;
            File::Copy::move( $tmp_path, $file_path );
        };

        $self->{say} .= "          * $file_path \n";
    }
    else {
        $adb->table_close($file_path);
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
    $adb->table_close($fac_path);
    unlink($fac_path);
    rename( $tmp_path, $fac_path ) or do {
        require File::Copy;
        File::Copy::move( $tmp_path, $fac_path );
    };

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
        $adb->table_close($slg_path);
        unlink($slg_path);
        rename( $tmp_path, $slg_path ) or do {
            require File::Copy;
            File::Copy::move( $tmp_path, $slg_path );
        };

        $self->{say} .= "    - Slug indexes are being created.: \n";
        $self->{say} .= "          * $slg_path \n";
    }
    else {
        $adb->table_close($slg_path);
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
            : ( $cfg, undef, 8 );

        if ( ( !defined $type || $type eq '' || $type eq 'auto' ) && $table_info->{blocks} ) {
            if ( ref($table_info->{blocks}) eq 'ARRAY' && ref($table_info->{blocks}[$blk]) eq 'HASH' ) {
                $type = $table_info->{blocks}[$blk]{type};
            }
        }
        $type ||= 'string';

        my %map;
        my ( %act_map, %junk_map );
        my %uniq_vals;
        my ( %act_uniq, %junk_uniq );
        foreach my $rec (@records) {
            next unless ref($rec) eq 'ARRAY' && defined $rec->[0] && $rec->[0] =~ /^\d+$/ && $rec->[0] > 0;
            my $rid  = $rec->[0];
            my $val  = $rec->[$blk];
            my $norm = $adb->normalize_sort_key( $val, $type, $len );
            $map{$rid} = $norm;

            if ( defined $val && $val ne '' ) {
                $uniq_vals{$val} = 1;
            }

            if ($has_junk) {
                my $is_junk = $adb->junk_rules( $table_info, $rec, $junk_rdbm );
                if ($is_junk) {
                    $junk_map{$rid} = $norm;
                    $junk_uniq{$val} = 1 if defined $val && $val ne '';
                }
                else {
                    $act_map{$rid} = $norm;
                    $act_uniq{$val} = 1 if defined $val && $val ne '';
                }
            }
        }

        # Sort all keys in-memory with deterministic tie-breaker (strictly numeric IDs)
        my @sorted_ids = grep { defined $_ && /^\d+$/ && $_ > 0 } sort {
            ( ( $map{$a} // '' ) cmp ( $map{$b} // '' ) )
              || ( $a <=> $b )
        } keys %map;

        $keys_batch{"$blk:keys"} = \@sorted_ids;
        foreach my $k ( keys %map ) {
            $raw_batch{"$blk:$k"} = $map{$k};
        }

        my $sort_vals = sub {
            my ($href) = @_;
            my $is_num = ( $type eq 'num' || $type eq 'decimal' ) ? 1 : 0;
            if ( !$is_num && %$href ) {
                $is_num = 1;
                for my $k ( keys %$href ) {
                    if ( $k !~ /^-?[0-9]+(?:\.[0-9]+)?$/ ) {
                        $is_num = 0;
                        last;
                    }
                }
            }
            my @sv = $is_num ? ( sort { $a <=> $b } keys %$href ) : ( sort { $a cmp $b } keys %$href );
            return join("\t", @sv);
        };
        $raw_batch{"$blk:vals"} = $sort_vals->(\%uniq_vals) if %uniq_vals;

        if ($has_junk) {
            my @sorted_act = grep { defined $_ && /^\d+$/ && $_ > 0 } sort {
                ( ( $act_map{$a} // '' ) cmp ( $act_map{$b} // '' ) )
                  || ( $a <=> $b )
            } keys %act_map;
            $keys_batch{"A:$blk:keys"} = \@sorted_act;
            $raw_batch{"A:$blk:vals"} = $sort_vals->(\%act_uniq) if %act_uniq;

            my @sorted_junk = grep { defined $_ && /^\d+$/ && $_ > 0 } sort {
                ( ( $junk_map{$a} // '' ) cmp ( $junk_map{$b} // '' ) )
                  || ( $a <=> $b )
            } keys %junk_map;
            $keys_batch{"B:$blk:keys"} = \@sorted_junk;
            $raw_batch{"B:$blk:vals"} = $sort_vals->(\%junk_uniq) if %junk_uniq;
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
    my $tables_hash = ($self->can('all_tables') ? $self->all_tables() : do { require AmberDB::Tools::Maintain; AmberDB::Tools::Maintain->new($self->{_adb})->all_tables(); });
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


1;
