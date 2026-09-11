package AmberDB::Base::Schema;

use 5.016;
use warnings;
use Carp qw(croak cluck);
use File::Spec;
use parent 'AmberDB::Base';

our $VERSION = '5.25.1';

my $CREATED = '2026-09-06';

# =====================================================================
# SCHEMA FIELD NORMALIZATION, VALIDATION & TYPE CONVERSION
# =====================================================================

# Normalizes and validates a single field value according to schema block definition.
# Usage:
#   my $clean_val = $adb->enc_field($blk_def, $val);
# ------------------------------------------------
sub enc_field {
    my ( $self, $blk, $val ) = @_;

    if ( $blk && ref($blk) eq 'HASH' ) {
        my $type  = lc( $blk->{type}  // 'text' );
        my $valid = lc( $blk->{valid} // '' );

        # 1. Type: number / num (integer, float, negative support)
        if ( $type eq 'num' || $type eq 'number' || $type eq 'numeric' || $type eq 'int' || $type eq 'float' || $type eq 'decimal' ) {
            if ( defined $val && length("$val") ) {
                ( my $trimmed = "$val" ) =~ s/^\s+|\s+$//g;
                if ( $trimmed =~ /^[+-]?[0-9]+(?:\.[0-9]+)?$/ ) {
                    $val = 0 + $trimmed;
                }
                else {
                    $val = 0;
                }
            }
            else {
                $val = 0;
            }
        }
        # 2. Type: ascii
        elsif ( $type eq 'ascii' ) {
            if ( defined $val && length("$val") ) {
                $val = $self->to_ascii("$val");
            }
            else {
                $val = '';
            }
        }
        # 3. Type: date
        elsif ( $type eq 'date' || $type eq 'datetime' || $type eq 'date_short' || $type eq 'date_long' ) {
            if ( ( !defined $val || $val eq '' ) && $valid =~ /auto_date/ ) {
                my $y = $self->{date}->{year}  // ( 1900 + (localtime)[5] );
                my $m = $self->{date}->{month} // sprintf( "%02d", (localtime)[4] + 1 );
                my $d = $self->{date}->{day}   // sprintf( "%02d", (localtime)[3] );
                $val = "$y-$m-$d";
            }
            else {
                $val //= '';
            }
        }
        # 4. Type: array / repeat / loop
        elsif ( $type eq 'array' || $type eq 'list' || $type eq 'repeat' || $type eq 'repeats' || $type eq 'loop' ) {
            if ( defined $val ) {
                if ( ref($val) eq 'ARRAY' ) {
                    # ok
                }
                elsif ( ref($val) ) {
                    $val = [$val];
                }
                elsif ( length("$val") ) {
                    $val = [ split /[,|]/, "$val" ];
                }
                else {
                    $val = [];
                }
            }
            else {
                $val = [];
            }
        }
        # 5. Type: hash
        elsif ( $type eq 'hash' || $type eq 'dict' || $type eq 'json' ) {
            if ( defined $val && ref($val) eq 'HASH' ) {
                # ok
            }
            else {
                $val = {};
            }
        }
        # 6. Type: text / string
        elsif ( $type eq 'text' || $type eq 'string' || $type eq 'tinytext' || $type eq 'html' ) {
            $val //= '';
        }
        # 7. Type: binary / base64
        elsif ( $type eq 'binary' || $type eq 'base64' ) {
            $val //= '';
        }
        # 8. Type: auto_id
        elsif ( $type eq 'auto_id' || $type eq 'autoid' ) {
            # auto_id is handled by table_autoid
        }
    }

    return $val;
}

# Normalizes and validates field values according to schema block definitions prior to encoding/writing.
# Usage:
#   my @clean_fields = $adb->enc_validate($tableid, \@fields, $has_id);
# ------------------------------------------------
sub enc_validate {
    my ( $self, $tableid, $fields_ref, $has_id ) = @_;

    return wantarray ? () : [] unless defined $fields_ref;
    my @fields = ( ref($fields_ref) eq 'ARRAY' ) ? @$fields_ref : ($fields_ref);
    return wantarray ? @fields : \@fields unless @fields;

    # Bypass in simple mode or when no tableid is given
    return wantarray ? @fields : \@fields
        if $self->config('simple') || !defined $tableid || $tableid eq '';

    my $table_info = $self->table_info($tableid);
    return wantarray ? @fields : \@fields
        unless $table_info && ref( $table_info->{blocks} ) eq 'ARRAY' && @{ $table_info->{blocks} };

    my $blocks = $table_info->{blocks};
    my @cleaned;

    for ( my $i = 0 ; $i < @fields ; $i++ ) {
        my $blk_idx = $has_id ? $i : ( $i + 1 );
        my $blk     = $blocks->[$blk_idx];
        if ( !$blk && $table_info->{repeat_start} && $blk_idx >= $table_info->{repeat_start} ) {
            $blk = $blocks->[ $table_info->{repeat_start} ] // $blocks->[-1];
        }
        push @cleaned, $self->enc_field( $blk, $fields[$i] );
    }

    return wantarray ? @cleaned : \@cleaned;
}

# Normalizes and casts a single field value according to schema block definition upon decoding/reading.
# Usage:
#   my $decoded_val = $adb->dec_field($blk_def, $val);
# ------------------------------------------------
sub dec_field {
    my ( $self, $blk, $val ) = @_;

    if ( $blk && ref($blk) eq 'HASH' ) {
        my $type = lc( $blk->{type} // 'text' );

        # 1. Type: number / num -> Ensure numeric scalar (0 + $val)
        if ( $type eq 'num' || $type eq 'number' || $type eq 'numeric' || $type eq 'int' || $type eq 'float' || $type eq 'decimal' ) {
            if ( defined $val && length("$val") ) {
                ( my $trimmed = "$val" ) =~ s/^\s+|\s+$//g;
                if ( $trimmed =~ /^[+-]?[0-9]+(?:\.[0-9]+)?$/ ) {
                    $val = 0 + $trimmed;
                }
                else {
                    $val = 0;
                }
            }
            else {
                $val = 0;
            }
        }
        # 2. Type: array / repeat / loop -> Ensure ARRAY ref
        elsif ( $type eq 'array' || $type eq 'list' || $type eq 'repeat' || $type eq 'repeats' || $type eq 'loop' ) {
            if ( !defined $val ) {
                $val = [];
            }
            elsif ( ref($val) ne 'ARRAY' ) {
                $val = length("$val") ? [ split /[,|]/, "$val" ] : [];
            }
        }
        # 3. Type: hash -> Ensure HASH ref
        elsif ( $type eq 'hash' || $type eq 'dict' || $type eq 'json' ) {
            if ( !defined $val || ref($val) ne 'HASH' ) {
                $val = {};
            }
        }
        # 4. Text / ASCII / Date / Binary
        else {
            $val //= '';
        }
    }

    return $val;
}

# Normalizes and casts field values according to schema block definitions upon decoding/reading.
# Usage:
#   my @decoded_fields = $adb->dec_validate($tableid, \@fields, $has_id);
# ------------------------------------------------
sub dec_validate {
    my ( $self, $tableid, $fields_ref, $has_id ) = @_;

    return wantarray ? () : [] unless defined $fields_ref;
    my @fields = ( ref($fields_ref) eq 'ARRAY' ) ? @$fields_ref : ($fields_ref);
    return wantarray ? @fields : \@fields unless @fields;

    # Bypass in simple mode or when no tableid is given
    return wantarray ? @fields : \@fields
        if $self->config('simple') || !defined $tableid || $tableid eq '';

    my $table_info = $self->table_info($tableid);
    return wantarray ? @fields : \@fields
        unless $table_info && ref( $table_info->{blocks} ) eq 'ARRAY' && @{ $table_info->{blocks} };

    my $blocks = $table_info->{blocks};
    my @cleaned;

    for ( my $i = 0 ; $i < @fields ; $i++ ) {
        my $blk_idx = $has_id ? $i : ( $i + 1 );
        my $blk     = $blocks->[$blk_idx];
        if ( !$blk && $table_info->{repeat_start} && $blk_idx >= $table_info->{repeat_start} ) {
            $blk = $blocks->[ $table_info->{repeat_start} ] // $blocks->[-1];
        }
        push @cleaned, $self->dec_field( $blk, $fields[$i] );
    }

    return wantarray ? @cleaned : \@cleaned;
}

# =====================================================================
# TABLE SANITIZATION & SCHEMA ARGUMENTS
# =====================================================================

# Sanitizes table/file identifier.
# Allows subdirectories and dots (e.g. 'uyeler/bekleyen.uyeler', '/.dosya')
# Strictly strips path traversal segments ('..', '.', './', '.\', '../', '..\')
# ------------------------------------------------
sub sanitize_table {
    my ( $self, $table ) = @_;
    return "" unless defined $table && length $table;

    # 1. Normalize backslashes to forward slashes
    $table =~ s/\\/\//g;

    # 2. Strip database extension if present at end
    my $ext = $self->{db_ext} // "db";
    $table =~ s/\.\Q$ext\E$//;

    # 3. Filter allowed characters: alphanumeric, underscore, dot, hyphen, slash
    $table =~ s/[^\w\.\-\/]+//g;

    # 4. Collapse multiple consecutive slashes
    $table =~ s{/+}{/}g;

    # 5. Remove path traversal components: split into segments and filter out '.' and '..'
    my @clean_segments;
    foreach my $seg ( split m{/}, $table ) {
        next if $seg eq '' || $seg eq '.' || $seg eq '..';
        push @clean_segments, $seg;
    }

    return join( '/', @clean_segments );
}

# ($id, $path) = $self->schema_arg($arg, "table"|"dbase")
# ------------------------------------------------
sub schema_arg {
    my ( $self, $arg, $ext ) = @_;
    return ( "", "" ) unless defined $arg && length $arg;

    if ( $arg =~ m{[\\/]|\.${ext}$} ) {
        ( my $id = $arg ) =~ s{.+[\\/]([^\\/]+?)(?:\.${ext})?$}{$1};
        $id = $self->sanitize_table($id);
        return ( $id, $arg );
    }
    my $clean = $self->sanitize_table($arg);
    my $schema_dir = $self->path('schema_dir')
      || ( $self->path('dbase_dir') ? $self->path('dbase_dir') . "/schema" : "schema" );
    return ( $clean, "$schema_dir/$clean.$ext" );
}

# =====================================================================
# SCHEMA LOADERS, ATTRIBUTES & WRITERS
# =====================================================================

# Retrieves database group schema definition.
# my $dbase_info = $adb->dbase_info($dbase);
# ------------------------------------------------
sub dbase_info {
    my ( $self, $arg ) = @_;

    return unless $arg;
    my ( $dbase, $dbase_path ) = $self->schema_arg( $arg, "dbase" );

    return $self->{_dbase}->{$dbase}
        if $self->{_dbase}->{$dbase} && %{ $self->{_dbase}->{$dbase} };

    my $ramdisk_schema = $self->{_path}->{schema_rdir} || $self->path('schema_rdir');
    my $target_path    = $dbase_path;
    if ( $ramdisk_schema && -e "$ramdisk_schema/$dbase.dbase" ) {
        $target_path = "$ramdisk_schema/$dbase.dbase";
    }

    if ( -e $target_path ) {
        $target_path =~ s{\\}{/}g;
        $target_path = "./$target_path" unless $target_path =~ m{^(?:\./|/|[a-zA-Z]:)};
        my $do_data = do $target_path;
        if ($do_data) {
            $self->{_dbase}->{$dbase} = $do_data;
            if ( $ramdisk_schema && !-e "$ramdisk_schema/$dbase.dbase" && $self->dir_exist($ramdisk_schema) ) {
                require File::Copy;
                eval { File::Copy::copy( $dbase_path, "$ramdisk_schema/$dbase.dbase" ) };
            }
        }
        else {
            if ($@) {
                cluck "[AMBERDB_SCHEMA] Syntax error in dbase schema file '$target_path': $@\n";
            }
        }
    }

    return $self->{_dbase}->{$dbase};
}

# ============================================================================
# TABLE SCHEMA NORMALIZATION & VALIDATION PIPELINE
# Normalizes, converts, and validates table schema definitions through an ordered
# rule pipeline. Ensures consistent in-memory structures across disk loading,
# table_attr, and table_infset.
# Usage:
#   $adb->normalize_blocks($table, $schema_hashref);
# ============================================================================
sub normalize_blocks {
    my ( $self, $table, $schema ) = @_;

    return {} unless ref($schema) eq 'HASH';

    # ------------------------------------------------------------------------
    # Pipeline Step 0: Table Identity & Metadata
    # Ensure table name and database group are present in schema.
    # ------------------------------------------------------------------------
    if ( defined $table && length $table ) {
        $schema->{table} = $table unless defined $schema->{table} && length $schema->{table};
        my ($dbase) = ( $table =~ /^([a-z0-9]+)_/i );
        $dbase //= "";
        $schema->{dbase} = $dbase unless defined $schema->{dbase} && length $schema->{dbase};
    }

    # ------------------------------------------------------------------------
    # Pipeline Step 1: Global Configuration Inheritance
    # ------------------------------------------------------------------------
    if ( defined $schema->{use_ramdisk} ) {
        $schema->{use_ramdisk} = $self->_normalize_ramdisk_tier( $schema->{use_ramdisk} );
    }
    elsif ( !defined $schema->{use_cache} ) {
        my $global_ram = $self->config('use_ramdisk');
        $global_ram = $self->_normalize_ramdisk_tier($global_ram);
        $global_ram = 0 if $global_ram == 3;
        $schema->{use_ramdisk} = $global_ram;
    }

    # ------------------------------------------------------------------------
    # Pipeline Step 1b: Volatile RAM-Disk Tier 3 Stripping
    # If use_ramdisk == 3, table is pure volatile key-value store on RAM-disk.
    # Strip all indexing, columnar, facet, and relational definitions.
    # ------------------------------------------------------------------------
    if ( ( $schema->{use_ramdisk} // 0 ) == 3 ) {
        delete @{$schema}{
            qw(
              blocks match_block search_block view_block facet_block filter_block
              slug_block sort_block sort_fields use_facet facet_rules use_junk junk_rules
              record_index repeat_start repeat_ids field_rules keep_deleted
            )
        };
        $schema->{use_simple}  = 1;
        $schema->{no_backup}   = 1;
        $schema->{no_transact} = 1;
        $schema->{ramdisk_ttl} = 300 unless defined $schema->{ramdisk_ttl} && $schema->{ramdisk_ttl} > 0;
    }

    # ------------------------------------------------------------------------
    # Pipeline Step 2: Simple Mode Stripping
    # In simple key-value mode, selectively strip columnar, indexing, relational,
    # and caching definitions to enforce lightweight operation.
    # ------------------------------------------------------------------------
    if ( $schema->{use_simple} && ( $schema->{use_ramdisk} // 0 ) != 3 ) {
        delete @{$schema}{
            qw(
              blocks match_block search_block view_block facet_block filter_block
              slug_block sort_block sort_fields use_facet facet_rules use_junk junk_rules
              record_index repeat_start repeat_ids field_rules
              use_ramdisk ramdisk_ttl use_cache cache_ttl
            )
        };
        return $schema;
    }

    # ------------------------------------------------------------------------
    # Pipeline Step 3: RAM-Disk Environment & Mount Verification
    # If RAM-disk is not physically mounted or ready, strip use_ramdisk.
    # The existence of $schema->{use_ramdisk} is a guaranteed contract of readiness.
    # ------------------------------------------------------------------------
    unless ( $self->ramdisk_is_mounted() ) {
        delete $schema->{use_ramdisk};
        delete $schema->{use_cache};
    }

    # ------------------------------------------------------------------------
    # Pipeline Step 4: Blocks & Relational Foreign Keys (RDBM) Normalization
    # Converts string RDBM definitions like:
    # "catalog_category,2", "catalog_category;2", "catalog_category|2", "catalog_category:2"
    # into canonical hashref: { table => "catalog_category", display => 2 }
    # ------------------------------------------------------------------------
    if ( exists $schema->{blocks} ) {
        if ( ref( $schema->{blocks} ) eq 'ARRAY' ) {
            foreach my $block ( @{ $schema->{blocks} } ) {
                $self->normalize_rdbm($block) if ref($block) eq 'HASH';
            }
        }
        elsif ( ref( $schema->{blocks} ) eq 'HASH' ) {
            foreach my $key ( keys %{ $schema->{blocks} } ) {
                my $block = $schema->{blocks}->{$key};
                $self->normalize_rdbm($block) if ref($block) eq 'HASH';
            }
        }
    }

    # ------------------------------------------------------------------------
    # Pipeline Step 5: (Future Schema Rules / Extensions)
    # Alanları ve sınırları belirlenmiş yeni şema kuralları buraya eklenebilir.
    # ------------------------------------------------------------------------

    return $schema;
}

# Normalizes rdbm definition within a block into canonical { table => $t, display => $d }
sub normalize_rdbm {
    my ( $self, $block ) = @_;
    return unless ref($block) eq 'HASH';

    return unless defined $block->{rdbm} && $block->{rdbm} ne '';

    # Case A: Already a hashref { table => '...', display => ... }
    if ( ref( $block->{rdbm} ) eq 'HASH' ) {
        my $t = $block->{rdbm}->{table};
        my $d = $block->{rdbm}->{display};
        $t = defined $t ? "$t" : "";
        $t =~ s/^\s+|\s+$//g;
        $d = ( defined $d && $d =~ /^\d+$/ ) ? int($d) : ( defined $block->{display} && $block->{display} =~ /^\d+$/ ? int($block->{display}) : 1 );
        $block->{rdbm} = {
            table   => $t,
            display => $d,
        };
        return;
    }

    # Case B: String format like "catalog_category,2", "catalog_category;2", "catalog_category|2", "catalog_category:2"
    if ( !ref( $block->{rdbm} ) ) {
        my $raw = "$block->{rdbm}";
        $raw =~ s/^\s+|\s+$//g;
        if ( !length $raw ) {
            delete $block->{rdbm};
            return;
        }

        # Split on comma, semicolon, pipe, or colon (, ; | :)
        my ( $t, $d ) = split( /[,;:|]/, $raw, 2 );
        $t =~ s/^\s+|\s+$//g if defined $t;
        $d =~ s/^\s+|\s+$//g if defined $d;

        if ( defined $t && length $t ) {
            my $disp = ( defined $d && $d =~ /^\d+$/ )
              ? int($d)
              : ( defined $block->{display} && $block->{display} =~ /^\d+$/
                ? int( $block->{display} )
                : 1 );
            $block->{rdbm} = {
                table   => $t,
                display => $disp,
            };
        }
        else {
            delete $block->{rdbm};
        }
    }
}

# my $table_info = $adb->table_info($table_id);
# ------------------------------------------------
sub table_info {
    my ( $self, $arg ) = @_;

    return {} unless $arg;
    return {} if $self->config('simple');

    my ( $table, $table_path ) = $self->schema_arg( $arg, "table" );
    $table && $table_path or return {};

    if ( $self->{_table}->{$table} && %{ $self->{_table}->{$table} } ) {
        return { %{ $self->{_table}->{$table} } };
    }

    my ($dbase) = ( $table =~ /^([a-z0-9]+)_/i );
    $dbase //= "";

    my $ramdisk_schema = $self->path('schema_rdir');
    my $target_path    = $table_path;
    if ( $ramdisk_schema && -e "$ramdisk_schema/$table.table" ) {
        $target_path = "$ramdisk_schema/$table.table";
    }

    if ( -e $target_path ) {
        $target_path =~ s{\\}{/}g;
        $target_path = "./$target_path" unless $target_path =~ m{^(?:\./|/|[a-zA-Z]:)};
        my $do_data = do $target_path;
        if ($do_data) {
            $self->normalize_blocks( $table, $do_data );
            $self->{_table}->{$table} = $do_data;

            if ( $ramdisk_schema && !-e "$ramdisk_schema/$table.table" && $self->dir_exist($ramdisk_schema) ) {
                require File::Copy;
                eval { File::Copy::copy( $table_path, "$ramdisk_schema/$table.table" ) };
            }
            if ( $do_data->{use_ramdisk} ) {
                $do_data->{_ramdisk_ensured} = 1;
                $self->ramdisk_ensure($table);
            }
        }
        else {
            if ($@) {
                cluck "[AMBERDB_SCHEMA] Syntax error in table schema file '$target_path': $@\n";
                return {};
            }
        }
    }
    else {
        my $schema = $self->{_table}->{$table} ||= {};
        $self->normalize_blocks( $table, $schema );
        $self->{_table}->{$table} = $schema;
        if ( $schema->{use_ramdisk} && !$schema->{_ramdisk_ensured} ) {
            $schema->{_ramdisk_ensured} = 1;
            $self->ramdisk_ensure($table);
        }
    }

    if ( $self->{_table}->{$table} && %{ $self->{_table}->{$table} } ) {
        $self->{_table}->{$table}->{table} //= $table;
        $self->{_table}->{$table}->{dbase} //= $dbase if $dbase;

        $self->dbase_info($dbase) if $dbase;

        return { %{ $self->{_table}->{$table} } };
    }

    return {};
}

# my $table_path = $adb->table_path($table);
# ------------------------------------------------
sub table_path {
    my ( $self, $table, $with_ext ) = @_;

    $table = $self->sanitize_table($table);
    return "" unless defined $table && length $table;

    # return if processed earlier and still exists on disk
    if ( $self->{_table}->{$table}->{_path} ) {
        my $ext = $self->{db_ext} || "db";
        if ( -e ( $self->{_table}->{$table}->{_path} . ".$ext" ) ) {
            return $self->{_table}->{$table}->{_path} . ($with_ext ? ".$ext" : "");
        }
        delete $self->{_table}->{$table}->{_path};
    }

    # load table info first
    $self->table_info($table);
    my $table_info = $self->{_table}->{$table};

    # Volatile RAM-Disk Tier 3: table lives strictly on RAM-disk
    if ( $table_info && ( $table_info->{use_ramdisk} // 0 ) == 3 && $self->ramdisk_is_mounted() ) {
        my $target = $self->ramdisk_path($table);
        $self->{_table}->{$table}->{_path} = $target;
        return $target . ( $with_ext ? ".$self->{db_ext}" : "" );
    }

    # set simple mode if DATADIR directory does not exist
    if ( !$self->dir_exist( $self->path('dbase_dir') ) ) {
        $self->config( simple => 1 );
    }

    # return table path if simple mode
    if ( $self->config('simple') ) {
        my $target = ( $self->path('dbase_dir') || "." ) . "/$table";
        my ($parent_dir) = $target =~ m{^(.+)[/\\][^/\\]+$};
        if ( $parent_dir && !$self->dir_exist($parent_dir) ) {
            croak "[AMBERDB_FATAL] Database directory '$parent_dir' does not exist for table '$table'";
        }
        $self->{_table}->{$table}->{_path} = $target;
        return $target . ($with_ext ? ".$self->{db_ext}" : "");
    }

    # set path value
    my $dbase_dir = $self->path('dbase_dir') || ".";

    my ($dbase) = ( $table =~ /^([a-z0-9]+)_/i );
    $dbase //= "";

    # if root dbase
    if ( $self->{_dbase}->{$dbase}->{root} ) {
        my $target = ( $self->path('dbase_dir') || "." ) . "/$table";
        my ($parent_dir) = $target =~ m{^(.+)[/\\][^/\\]+$};
        if ( $parent_dir && !$self->dir_exist($parent_dir) ) {
            croak "[AMBERDB_FATAL] Database directory '$parent_dir' does not exist for table '$table'";
        }
        $self->{_table}->{$table}->{_path} = $target;
        return $self->{_table}->{$table}->{_path} . ($with_ext ? ".$self->{db_ext}" : "");
    }

    if ( $table_info && exists $table_info->{table_dir} ) {
        my $tdir = $table_info->{table_dir};
        if ( defined $tdir && length $tdir ) {
            $tdir =~ s{^[\\/]+|[\\/]+$}{}g;
            $dbase_dir .= "/$tdir";
        }
        # if defined $tdir && length $tdir == 0 (table_dir => ''), overwrite default: keep $dbase_dir directly
    }
    else {
        # if using year
        my $yeardir;
        if (
            $self->config('use_year')
            and (  $self->{_dbase}->{$dbase}->{year}
                or $self->{_table}->{$table}->{year} )
          )
        {
            $yeardir = $self->path('year_dir') || $self->{date}->{year};
        }
        else {
            delete( $self->{_dbase}->{$dbase}->{year} )
              if ( $self->{_dbase}->{$dbase}->{year} );

            delete( $self->{_table}->{$table}->{year} )
              if ( $self->{_table}->{$table}->{year} );
            $yeardir = "table";
        }
        $dbase_dir .= "/$yeardir" if $yeardir;

        # if using section
        if (
            $self->config('use_section')
            and (  $self->{_dbase}->{$dbase}->{section}
                or $self->{_table}->{$table}->{section} )
          ) {
            my $section = $self->{_table}->{$table}->{section} || $self->config('section') || "center";
            $dbase_dir .= "_$section";
        }

        # if using language
        if (
            $self->config('use_language') and 
                (  $self->{_dbase}->{$dbase}->{lang} ||
                   $self->{_table}->{$table}->{lang} )
        ) {
            my $lang = $self->{_dbase}->{$dbase}->{lang} || 
                       $self->{_table}->{$table}->{lang} // "";

            $dbase_dir .= "_$lang";
        }
    }

    unless ( $self->dir_exist($dbase_dir) ) {
        if ( $table_info && exists $table_info->{table_dir} ) {
            $self->make_path($dbase_dir);
        }
        else {
            croak "[AMBERDB_FATAL] Database directory '$dbase_dir' does not exist for table '$table'";
        }
    }

    my $target = "$dbase_dir/$table";
    $self->{_table}->{$table}->{_path} = $target;

    return $self->{_table}->{$table}->{_path} . ($with_ext ? ".$self->{db_ext}" : "");
}

# my $attrs = $adb->table_attr($table);
# ------------------------------------------------
sub table_attr {
    my ( $self, $table, @args ) = @_;

    $table = $self->sanitize_table($table);
    return unless defined $table && length $table;

    # 1. No extra arguments: return shallow copy of table attributes
    if ( !@args ) {
        unless ( $self->ramdisk_is_mounted() ) {
            delete $self->{_table}->{$table}->{use_ramdisk};
            delete $self->{_table}->{$table}->{use_cache};
        }
        return { %{ $self->{_table}->{$table} || {} } };
    }

    # 2. Single scalar argument: getter -> $adb->table_attr($table, 'use_simple')
    if ( @args == 1 && !ref( $args[0] ) ) {
        if ( ( $args[0] eq 'use_ramdisk' || $args[0] eq 'use_cache' ) && !$self->ramdisk_is_mounted() ) {
            delete $self->{_table}->{$table}->{use_ramdisk};
            delete $self->{_table}->{$table}->{use_cache};
            return undef;
        }
        return $self->{_table}->{$table}->{ $args[0] };
    }

    # 3. Setter: key-value list or hashref
    my %attrs = ( @args == 1 && ref( $args[0] ) eq "HASH" ) ? %{ $args[0] } : @args;
    my $needs_path_refresh = 0;

    foreach my $key ( keys %attrs ) {
        my $val = $attrs{$key};
        if ( $key eq 'use_ramdisk' ) {
            $val = $self->_normalize_ramdisk_tier($val);
        }
        $self->{_table}->{$table}->{$key} = $val;
        $needs_path_refresh = 1 if $key =~ /^(year|section|lang|table_dir|use_ramdisk)$/;
    }

    $self->normalize_blocks( $table, $self->{_table}->{$table} );

    my $use_ram = $self->{_table}->{$table}->{use_ramdisk} // 0;
    if ($use_ram) {
        $self->{_table}->{$table}->{_ramdisk_ensured} = 1;
        $self->ramdisk_ensure($table);
    }

    if ($needs_path_refresh) {
        delete $self->{_table}->{$table}->{_path};
        $self->table_path($table);
    }

    return $self;
}

# my $table_path = $adb->table_infset($table);
# ------------------------------------------------
sub table_infset {
    my ( $self, $table, $schema_data ) = @_;

    $self->config('simple') and return 1;
    if ( ref($schema_data) eq 'HASH' ) {
        $self->normalize_blocks( $table, $schema_data );
        $self->{_table}->{$table} = $schema_data;
    }
    my $tbl = $self->{_table}->{$table};
    ref($tbl) eq 'HASH' or return;

    my $table_path = "$table";
    $table_path =~ s/\\/\//g;
    $table_path =~ s/\//-/g;

    my $table_str = "";

    # Scalar keys
    my @scalar_keys = qw(
      name record_index keep_deleted log_owner parent_table
      use_menu use_simple force use_ramdisk ramdisk_ttl use_cache use_alias
      use_counter use_facet stop_word min_char
      use_junk cache_ttl repeat_ids repeat_start
      no_transact no_backup table_dir
    );
    foreach my $key (@scalar_keys) {
        next unless exists $tbl->{$key};
        next unless defined $tbl->{$key} && $tbl->{$key} ne "";
        ( my $val = $tbl->{$key} ) =~ s/"/\\"/g;
        $table_str .= "\t$key => \"$val\",\n";
    }

    # Array keys
    my @array_keys = qw(
      search_block match_block view_block facet_block
      filter_block slug_block reverse
    );
    foreach my $key (@array_keys) {
        next unless ref( $tbl->{$key} ) eq "ARRAY";
        my $array = join ", ", @{ $tbl->{$key} };
        next unless $array;
        $table_str .= "\t$key => [ $array ],\n";
    }

    # Serialize sort_block
    if ( ref( $tbl->{sort_block} ) eq 'ARRAY' && @{ $tbl->{sort_block} } ) {
        $table_str .= "\tsort_block => [\n";
        foreach my $sb ( @{ $tbl->{sort_block} } ) {
            if ( ref($sb) eq 'HASH' ) {
                $table_str .= "\t\t{ blk => $sb->{blk}, type => \"$sb->{type}\"" . ( $sb->{len} ? ", len => $sb->{len}" : "" ) . " },\n";
            }
            else {
                $table_str .= "\t\t$sb,\n";
            }
        }
        $table_str .= "\t],\n";
    }

    # Serialize facet_rules
    if ( ref( $tbl->{facet_rules} ) eq 'ARRAY' && @{ $tbl->{facet_rules} } ) {
        my $fa = $tbl->{facet_rules};
        my $fa_val;
        if ( ref( $fa->[0] ) eq 'ARRAY' ) {
            my @rules_str = map {
                "[" . join( ", ", map { $_ =~ /^\d+$/ ? $_ : "\"$_\"" } @$_ ) . "]"
            } @$fa;
            $fa_val = "[ " . join( ", ", @rules_str ) . " ]";
        }
        else {
            $fa_val = "[ " . join( ", ", map { $_ =~ /^\d+$/ ? $_ : "\"$_\"" } @$fa ) . " ]";
        }
        $table_str .= "\tfacet_rules => $fa_val,\n";
    }

    # Serialize junk_rules
    if ( ref( $tbl->{junk_rules} ) eq 'ARRAY' && @{ $tbl->{junk_rules} } ) {
        my $jr = $tbl->{junk_rules};
        my $jr_val;
        if ( ref( $jr->[0] ) eq 'ARRAY' ) {
            my @rules_str = map {
                "[" . join( ", ", map { $_ =~ /^\d+$/ ? $_ : "\"$_\"" } @$_ ) . "]"
            } @$jr;
            $jr_val = "[ " . join( ", ", @rules_str ) . " ]";
        }
        else {
            $jr_val = "[ " . join( ", ", map { $_ =~ /^\d+$/ ? $_ : "\"$_\"" } @$jr ) . " ]";
        }
        $table_str .= "\tjunk_rules => $jr_val,\n";
    }

    # Serialize blocks in correct format
    if ( ref( $tbl->{blocks} ) eq "ARRAY" && @{ $tbl->{blocks} } ) {
        $table_str .= "\tblocks => [\n";
        my %seen;
        foreach my $blok ( @{ $tbl->{blocks} } ) {
            next unless $blok->{id} && $blok->{name};
            next if $seen{ $blok->{id} }++;
            $table_str .= "\t\t{ id => \"$blok->{id}\",";
            $table_str .= " name => \"$blok->{name}\",";
            $blok->{type}  and $table_str .= " type  => \"$blok->{type}\",";
            $blok->{input} and $table_str .= " input => \"$blok->{input}\",";
            $blok->{valid} and $table_str .= " valid => \"$blok->{valid}\",";
            if ( ref( $blok->{rdbm} ) eq 'HASH' && $blok->{rdbm}{table} ) {
                my $disp = $blok->{rdbm}{display} || 0;
                $table_str .= 
                    " rdbm  => { table => \"$blok->{rdbm}{table}\", display => $disp },";
            }
            elsif ( defined $blok->{rdbm} && $blok->{rdbm} ne '' && !ref( $blok->{rdbm} ) ) {
                $table_str .= " rdbm  => \"$blok->{rdbm}\",";
            }
            if ( ref( $blok->{extend} ) eq 'HASH' && $blok->{extend}{table} ) {
                my $join_col = $blok->{extend}{join} || 'id';
                $table_str .= 
                    " extend => { table => \"$blok->{extend}{table}\", join => \"$join_col\" },";
            }
            $blok->{option} and
              $table_str .= " option => \"$blok->{option}\",";
            $table_str .= " },\n";
        }
        $table_str .= "\t],\n";
    }

    if ($table_str) {
        my $schema_dir = $self->path('schema_dir') || ( $self->path('dbase_dir') ? $self->path('dbase_dir') . "/schema" : "schema" );
        open my $YZ, ">:encoding(UTF-8)", "$schema_dir/$table_path.table"
          or do {
            cluck "[DB_SCHEMA] Could not write schema $schema_dir/$table_path.table: $!\n";
            return;
          };
        print $YZ "{\n";
        print $YZ $table_str;
        print $YZ "}\n";
        close $YZ;
    }

    return 1;
}

1;
