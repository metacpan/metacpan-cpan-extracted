package AmberDB::Base::Cache;

use 5.016;
use warnings;
use Carp qw(croak cluck);

our $VERSION = '5.25.1';

my $CREATED = '2026-08-11';

# ============================================================================
# AmberDB In-Memory (L1 Process) Object Cache & Staging Buffer Engine
# ============================================================================

# ----------------------------------------------------------------------------
# In-Memory L1 Object Cache ($self->{_cache})
# ----------------------------------------------------------------------------

# my $val = $adb->get_cache( $group, $key );
# my %grp = $adb->get_cache( $group );
# ------------------------------------------------
sub get_cache {
    my ( $self, $group, $key ) = @_;
    return unless defined $group && length $group;
    return unless $self->{_cache} && ref( $self->{_cache} ) eq 'HASH';

    my $val = defined $key ? $self->{_cache}{$group}{$key} : $self->{_cache}{$group};
    return unless defined $val;

    if ( wantarray && ref($val) eq 'ARRAY' ) {
        return @$val;
    }
    return $val;
}

# $adb->set_cache( $group, $key, @vals );
# $adb->set_cache( $group, $key );       # deletes key
# $adb->set_cache( $group );             # deletes entire group
# $adb->set_cache();                     # resets all cache
# ------------------------------------------------
sub set_cache {
    my ( $self, $group, $key, @vals ) = @_;

    # Reset all cache if called without arguments
    if ( !defined $group || $group eq '' ) {
        %{ $self->{_cache} } = () if $self->{_cache};
        return 1;
    }

    # If key is omitted, delete entire group / table
    if ( !defined $key || $key eq '' ) {
        delete $self->{_cache}{$group};
        return 1;
    }

    # If vals omitted, delete key
    if ( !@vals || !defined $vals[0] ) {
        delete $self->{_cache}{$group}{$key};
        if ( $key eq 'keys' || $key =~ /^keys_/ ) {
            delete $self->{_cache}{$group}{keys};
            delete $self->{_cache}{$group}{keys_desc};
            delete $self->{_cache}{$group}{keys_asc};
        }
        return 1;
    }

    my $store_val = ( @vals > 1 ) ? \@vals : $vals[0];
    return $self->{_cache}{$group}{$key} = $store_val;
}

# $adb->clear_cache( [$group], [$key] );
# ------------------------------------------------
sub clear_cache {
    my ( $self, $group, $key ) = @_;

    if ( !defined $group || $group eq '' ) {
        %{ $self->{_cache} } = () if $self->{_cache};
        return 1;
    }

    if ( !defined $key || $key eq '' ) {
        delete $self->{_cache}{$group};
        return 1;
    }

    delete $self->{_cache}{$group}{$key};
    if ( $key eq 'keys' || $key =~ /^keys_/ ) {
        delete $self->{_cache}{$group}{keys};
        delete $self->{_cache}{$group}{keys_desc};
        delete $self->{_cache}{$group}{keys_asc};
    }
    return 1;
}

# Backward compatibility aliases for in-memory caching
sub cache_read {
    my $self = shift;
    return $self->get_cache(@_);
}

sub cache_write {
    my $self = shift;
    return $self->set_cache(@_);
}

sub cache_delete {
    my $self = shift;
    return $self->clear_cache(@_);
}

# ============================================================================
# Persistent Disk Buffer Staging Operations ($dbase_dir/buffer/)
# ============================================================================

sub buffer_slot {
    my ( $self, $tableid ) = @_;

    my $dbase      = do { ( $tableid =~ /^([a-z0-9]+)_/ )[0] };
    my $dbase_info = $self->dbase_info($dbase);

    my $buffer_dir = $self->path('buffer_dir')
      || ( ( $self->path('dbase_dir') || "." ) . "/buffer" );

    my $prefix = '';
    if (
        $self->config('use_section')
        and ( ( $dbase_info && $dbase_info->{section} )
            or ( $self->table_info($tableid) && $self->table_info($tableid)->{section} ) )
    ) {
        $prefix = ( $self->config('section') // "center" ) . "-";
    }
    my $buffer_file = "${prefix}${tableid}.tmp";

    return ( $buffer_dir, $buffer_file );
}

sub buffer_read {
    my ( $self, $tableid ) = @_;

    my ( $buffer_dir, $buffer_file ) = $self->buffer_slot($tableid);
    return unless $buffer_dir && -d $buffer_dir;
    return unless -e "$buffer_dir/$buffer_file";

    my @lines;
    open my $TMP, "<", "$buffer_dir/$buffer_file"
      or do { cluck "[DB_BUFFER] $buffer_dir/$buffer_file can't open: $!\n"; return; };

    while ( my $line = <$TMP> ) {
        my @fields = $self->db_decode($line);
        push @lines, \@fields;
    }
    close $TMP;

    return @lines;
}

sub buffer_write {
    my ( $self, $tableid, @records ) = @_;

    $tableid or return;
    @records or return;

    my ( $buffer_dir, $buffer_file ) = $self->buffer_slot($tableid);
    return unless $buffer_dir && -d $buffer_dir;

    my $target_path = "$buffer_dir/$buffer_file";
    my $tmp_path    = "${target_path}.tmp.$$";

    open my $TMP, ">", $tmp_path
      or do { cluck "[DB_BUFFER] $tmp_path can't open: $!\n"; return; };

    foreach my $fields (@records) {
        $fields = [$fields] unless ref($fields) eq "ARRAY";
        my $encoded = $self->db_encode( @{$fields} );
        print $TMP "$encoded\n";
    }
    close $TMP;

    rename( $tmp_path, $target_path );
    return 1;
}

sub buffer_delete {
    my ( $self, $tableid ) = @_;

    my ( $buffer_dir, $buffer_file ) = $self->buffer_slot($tableid);
    return unless $buffer_dir && -d $buffer_dir;

    unlink("$buffer_dir/$buffer_file") if -e "$buffer_dir/$buffer_file";
    return 1;
}

1;

__END__

=head1 NAME

AmberDB::Base::Cache - In-memory (L1 process) object cache and persistent staging buffer engine

=head1 SYNOPSIS

  # 1. In-Memory L1 Object Cache:
  $adb->set_cache("catalog_product", "featured_items", @product_records);
  my @records = $adb->get_cache("catalog_product", "featured_items");
  $adb->clear_cache("catalog_product", "featured_items");

  # Aliases:
  # cache_read  -> get_cache
  # cache_write -> set_cache
  # cache_delete -> clear_cache

  # 2. Persistent Disk Buffer Staging (stored in dbase_dir/buffer/):
  $adb->buffer_write("export_job", @large_dataset_chunks);
  my @staged_data = $adb->buffer_read("export_job");
  $adb->buffer_delete("export_job");

=head1 DESCRIPTION

C<AmberDB::Base::Cache> provides in-memory process caching (L1) and temporary staging disk buffer
management under C<dbstore/buffer/>.

=cut
