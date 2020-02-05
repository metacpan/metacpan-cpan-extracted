package Data::ObjectStore;

use strict;
use warnings;

no warnings 'numeric';
no warnings 'uninitialized';
no warnings 'recursion';

use File::Path qw( make_path );
use Scalar::Util qw(weaken);
use Time::HiRes qw(time);
use vars qw($VERSION);

use Data::RecordStore;
use Data::ObjectStore::Cache;

$VERSION = '2.13';

our $DEBUG = 0;
our $UPGRADING;

use constant {
    DATA_PROVIDER => 0,
    DIRTY         => 1,
    WEAK          => 2,
    STOREINFO     => 3,
    OPTIONS       => 4,
    CACHE         => 5,
    
    ID       => 0,
    DATA     => 1,
    METADATA => 3,
    LEVEL    => 4,
    DIRTY_BIT => 5,  #for objs
};
my( @METAFIELDS ) = qw( created updated );

sub open_store {
    my( $cls, @options ) = @_;

    die "Data::ObjectStore->open_store requires at least one argument" if 0 == @options;
    
    if( 1 == @options ) {
        unshift @options, 'DATA_PROVIDER';
    }
    my( %options ) = @options;

    my $data_provider = $options{DATA_PROVIDER};
    if( ! ref( $data_provider ) ) {
        # the default record store Data::RecordStore
        $options{BASE_PATH} = "$data_provider/RECORDSTORE";
        $data_provider = Data::RecordStore->open_store( %options );
    }
    my $cache = $options{CACHE} ? ref( $options{CACHE} ) ? $options{CACHE} : Data::ObjectStore::Cache->new( $options{CACHE} ) : undef;
    my $store = bless [
        $data_provider,
        {}, #DIRTY CACHE
        {}, #WEAK CACHE
        undef,
        \%options,
        $cache,
      ], $cls;

    if( ! $UPGRADING ) {
        $store->[STOREINFO] = $store->_fetch_store_info_node;
        $store->load_root_container;
        if( $store->get_store_version < 1.2  ) {
            die "Unable to open store of version ".$store->get_store_version.". Please run upgrade_store.";
        }
        $store->save;
    }
    return $store;
} #open_store

sub data_store {
    return shift->[DATA_PROVIDER];
}

sub empty_cache {
    my( $self ) = @_;
    if( $self->[CACHE] ) {
        $self->[CACHE]->empty;
    }
}

# locks the given lock names
sub lock {
    my( $self, @locknames ) = @_;
    $self->[DATA_PROVIDER]->lock( @locknames );
}

# unlocks all locks
sub unlock {
    my $self = shift;
    $self->[DATA_PROVIDER]->unlock;
}

# quick purge is not careful with memory.
sub quick_purge {
    my $self = shift;
    my( %keep );
    my( @working ) = ( 1 );

    my $data_provider = $self->[DATA_PROVIDER];
    my $highest = $data_provider->entry_count;

    while( @working ) {
        my $try = shift @working;

        $keep{$try}++;

        my $obj = $self->_knot( $try );
        my $d = $obj->[DATA];
        my %placed;
        push @working, (
            grep { ! $keep{$_} && 0 == $placed{$_}++ }
            map { substr( $_, 1 ) }
            grep { /^r/ }
            (ref( $d ) eq 'ARRAY' ? @$d : values( %$d )  ));
    }

    my $pcount;
    for( my $i=1; $i<=$highest; $i++ ) {
        if( ! $keep{$i} ) {
            $data_provider->delete_record( $i );
            ++$pcount;
        }
    }
    
    return $pcount;
} #quick_purge


sub upgrade_store {
    my( $source_path, $dest_path ) = @_;

    die "upgrade_store destination '$dest_path' already has a store" if -e "$dest_path/RECORDSTORE";

    #
    # Fetch the info directly from the record store and examine it manually.
    #
    my $from_recstore = Data::RecordStore->open_store( "$source_path/RECORDSTORE" );

    my $info = $from_recstore->fetch( 1 );
    my( $vers ) = ( $info =~ /[ \`]ObjectStore_version\`v([^\`]*)/ );

    if( $vers >= 2 ) {
        die "Store already at version 2 or above. No upgrade needed\n";
    }


    # allows store to open old versions
    # prevents store from creating root objects when created
    $UPGRADING = 1;

    my $dest_store = Data::ObjectStore->open_store( "$dest_path" );
    my $source_store = Data::ObjectStore->open_store( "$source_path" );

    #
    # Clones all objects (that connect to the root) from the source
    # store to the destination store. For this upgrade, the only thing
    # that is missing is the object META data.
    #
    sub _transfer_obj {
      my( $source_store, $dest_store, $id, $i ) = @_;
      my $ind = '  'x$i;

      my $obj = $dest_store->fetch( $id );

      if( $obj ) {
          return  $obj;
      } # obj

      my $source_thing = $source_store->_knot( $id );

      my $clone = ref( $source_thing )->_reconstitute( $dest_store,
                                                       $id,
                                                       _thaw( $source_thing->_freezedry ),
                                                       {} );
      
      my $clone_thing = $dest_store->_knot( $clone );
      if( ref($clone_thing) !~ /^(ARRAY|HASH|Data::ObjectStore::Hash|Data::ObjectStore::Array)$/ ) {
          $clone_thing->[DIRTY_BIT] = 1;
      }
      my $odata = $clone_thing->[DATA];

      my $meta = $clone_thing->[METADATA];
      my $time = time;
      $meta->{created} = $time;
      $meta->{updated} = $time;

      $dest_store->save( $clone );

      my( @connections );
      if ( ref($odata) eq 'ARRAY' ) {
          for (0..$#$odata) {
              my $oid = $odata->[$_];
              if ( $oid > 0 ) {
                  $odata->[$_] = "r$oid";
                  if ( $oid != $id) {
                      push @connections, $oid;
                  }
              }
          }
      }
      else {
          for my $key (keys %$odata) {
              if ( $odata->{$key} > 0 ) {
                  my $oid = $odata->{$key};
                  $odata->{$key} = "r$oid";
                  if ( $oid != $id) {
                      push @connections, $oid;
                  }
              }
          }
      }
      $dest_store->save( $clone );

      for my $oid (@connections) {
          my $connect_obj = _transfer_obj( $source_store, $dest_store, $oid, 1 + $i );
          my $connect_thing = $dest_store->_knot( $connect_obj );
          $dest_store->save( $connect_obj );
      }

      $dest_store->fetch( $id );
    } #_transfer_obj

    my $info_node = _transfer_obj( $source_store, $dest_store, 1, 0 );
    $info_node->set_ObjectStore_version( $Data::RecordStore::VERSION );
    $dest_store->save( $info_node );

    $UPGRADING = 0;
} #upgrade_store

sub load_root_container {
    my $self = shift;
    my $info_node = $self->_fetch_store_info_node;
    my $root = $info_node->get_root;
    unless( $root ) {
        $root = $self->create_container;
        $info_node->set_root( $root );
        $self->save;
    }
    return $root;
} #load_root_container


sub info {
    my $node = shift->[STOREINFO];
    my $info = {
        map { $_ => $node->get($_)  }
        qw( db_version ObjectStore_version created_time last_update_time )
    };
    $info;
} #info


sub get_db_version {
    shift->info->{db_version};
}


sub get_store_version {
    shift->info->{ObjectStore_version};
}

sub get_created_time {
    shift->info->{created_time};
}

sub get_last_update_time {
    shift->info->{last_update_time};
}

sub create_container {
    # works with create_container( { my data } ) or create_container( 'myclass', { my data } )
    my( $self, $class, $data ) = @_;
    if( ref( $class ) ) {
        $data  = $class;
        $class = 'Data::ObjectStore::Container';
    }
    $class //= 'Data::ObjectStore::Container';

    if( $class !~ /^Data::ObjectStore::/ ) {
      my $clname = $class;
      $clname =~ s/::/\//g;
      require "$clname.pm";
    }

    my $id = $self->_new_id;

    my $time = time;
    my $obj = bless [ $id,
                      undef,
                      $self,
                      { created => $time,
                        updated => $time },
        ], $class;
    $self->_store_weak( $id, $obj );
    $self->_dirty( $id );

    for my $fld (keys %$data) {
        $obj->set( $fld, $data->{$fld} );
    }

    $obj->_init(); #called the first time the object is created.
    $obj->[DIRTY_BIT] = 1;
    $obj;
} #create_container

sub save {
    my( $self, $ref, $class_override ) = @_;
    if( ref( $ref ) ) {
        return $self->_save( $ref, $class_override );
    }
    my $node = $self->_fetch_store_info_node;
    my $now = time;

    unless( $self->[OPTIONS]{NO_TRANSACTIONS} ) {
        $self->[DATA_PROVIDER]->use_transaction;
    }

    my( @dirty ) = keys %{$self->[DIRTY]};
    
    for my $id ( @dirty ) { 
        my $obj = $self->[DIRTY]{$id};
        # assings id if none were given
        $self->_knot( $obj );
    } #each dirty

    ( @dirty ) = keys %{$self->[DIRTY]};
    for my $id ( @dirty ) {
        my $obj = delete $self->[DIRTY]{$id};
        $self->_save( $obj );
    } #each dirty

    $node->set_last_update_time( $now );
    $self->_save( $node );

    unless( $self->[OPTIONS]{NO_TRANSACTIONS} ) {
        $self->[DATA_PROVIDER]->commit_transaction;
    }
    $self->[DIRTY] = {};
    return 1;
} #save

sub _save {
    my( $self, $obj, $class_override ) = @_;
    my $thingy = $self->_knot( $obj );
    if( ref($thingy) !~ /^(ARRAY|HASH|Data::ObjectStore::Hash|Data::ObjectStore::Array)$/ ) {
        if( !$thingy->[DIRTY_BIT] ) {
            return;
        }
        $thingy->[DIRTY_BIT] = 0;
    }
    my $id = $thingy->[ID];
    delete $self->[DIRTY]{$id};   # need the upgrading cas?

    #
    # Save to the record store.
    #
    my $text_rep = $thingy->_freezedry;
    my( @meta ) = $class_override ? $class_override : ref( $thingy );
    for my $fld (@METAFIELDS) {
        my $val = $thingy->[METADATA]{$fld};
        push @meta, $val;
    }
    my $meta_string = join('|', @meta );
    $self->[DATA_PROVIDER]->stow( "$meta_string $text_rep", $id );
    
} #_save

sub existing_id {
    my( $self, $obj ) = @_;
    return undef unless ref($obj);
    my $tied = $self->_knot( $obj );
    return $tied ? $tied->[ID] : undef;
}

sub _has_dirty {
    my $self = shift;
    scalar( keys %{$self->[DIRTY]});
}

sub _knot {
    my( $self, $item ) = @_;
    my $r = ref( $item );
    if( $r ) {
      if( $r eq 'ARRAY' ) {
        return tied @$item;
      }
      elsif( $r eq 'HASH' ) {
        return tied %$item;
      }
      elsif( $r eq 'Data::ObjectStore::Array' ||
                 $r eq 'Data::ObjectStore::Hash' ||
                     $r->isa( 'Data::ObjectStore::Container' ) ) {
          return $item;
      }
      return undef;
    }
    if( $item > 0 ) {
      my $xout = $self->_xform_out( $item );
      my $zout = $self->_knot( $xout );
      return $zout;
    }
    return undef;
}

#
# The store info node records useful information about the store
#
sub _fetch_store_info_node {
    my( $self ) = @_;
    my $node = $self->fetch( 1 );
    unless( $node ) {
        my $first_id = $self->_new_id;
        my $now = time;
        $node = bless [ 1, {}, $self, { created => $now, updated => $now } ], 'Data::ObjectStore::Container';
        $self->_store_weak( 1, $node );
        $self->_dirty( 1 );
        $node->[DIRTY_BIT] = 1;
        $node->set_db_version( $Data::RecordStore::VERSION );
        $node->set_ObjectStore_version( $Data::ObjectStore::VERSION );
        $node->set_created_time( $now );
        $node->set_last_update_time( $now );
    }
    $node;
} #_fetch_store_info_node

sub _thaw {
    my( $dryfroze ) = @_;

    # so foo` or foo\\` but not foo\\\`
    # also this will never start with a `
    my $pieces = [ split /\`/, $dryfroze, -1 ];


    # check to see if any of the parts were split on escapes
    # like  mypart`foo`oo (should be translated to mypart\`foo\`oo
    if ( 0 < grep { /\\$/ } @$pieces ) {

        my $newparts = [];

        my $is_hanging = 0;
        my $working_part = '';

        for my $part (@$pieces) {

            # if the part ends in a hanging escape
            if ( $part =~ /(^|[^\\])((\\\\)+)?[\\]$/ ) {
                if ( $is_hanging ) {
                    $working_part .= "`$part";
                } else {
                    $working_part = $part;
                }
                $is_hanging = 1;
            } elsif ( $is_hanging ) {
                my $newpart = "$working_part`$part";
                $newpart =~ s/\\`/`/gs;
                $newpart =~ s/\\\\/\\/gs;
                push @$newparts, $newpart;
                $is_hanging = 0;
            } else {
                # normal part
                push @$newparts, $part;
            }
        }
        $pieces = $newparts;

    } #if there were escaped ` characters

    $pieces;
} #_thaw


sub fetch {
    my( $self, $id, $force ) = @_;
    my $ref = $self->[DIRTY]{$id} // $self->[WEAK]{$id};
    
    return $ref if $ref;

    my $stowed = $self->[DATA_PROVIDER]->fetch( $id );
    return undef unless $stowed;

    my $pos = index( $stowed, ' ' );
    die "Data::ObjectStore::_fetch : Malformed record '$stowed'" if $pos == -1;

    my $metastr = substr $stowed, 0, $pos;
    my( $class, @meta ) = split /\|/, $metastr;

    my $meta = {};
    for my $fldi (0..$#METAFIELDS) {
        my $fld = $METAFIELDS[$fldi];
        my $val = $meta[$fldi];
        $meta->{$fld} = $val;
    }

    my $dryfroze = substr $stowed, $pos + 1;

    if( $class !~ /^Data::ObjectStore::/ ) {
      my $clname = $class;
      $clname =~ s/::/\//g;

      eval {
          require "$clname.pm";
          unless( $class->can( '_reconstitute' ) ) {
              if( $force ) {
                  warn "Forcing '$class' to be 'Data::ObjectStore::Container'";
                  $class = 'Data::ObjectStore::Container';
              } else {
                  die "Object in the store was marked as '$class' but that is not a 'Data::ObjectStore::Container'";
              }
          }
      };
      if( $@ ) {
          if( $force ) {
              warn "Forcing '$class' to be 'Data::ObjectStore::Container'";
              $class = 'Data::ObjectStore::Container';
          } else {
              die $@;
          }
      }
    }

    my $pieces = _thaw( $dryfroze );

    my $ret = $class->_reconstitute( $self, $id, $pieces, $meta );
    $self->_store_weak( $id, $ret );
    return $ret;
} #_fetch

#
# Convert from reference, scalar or undef to value marker
#
sub _xform_in {
    my( $self, $val ) = @_;
    if( ref( $val ) ) {
        my $id = $self->_get_id( $val );
        return $id, "r$id";
    }
    return 0, (defined $val ? "v$val" : 'u');
}

#
# Convert from value marker to reference, scalar or undef
#
sub _xform_out {
    my( $self, $val ) = @_;

    return undef unless defined( $val ) && $val ne 'u';

    if( index($val,'v') == 0 ) {
        return substr( $val, 1 );
    }
    if( $val =~ /^r(\d+)/ ) {
        return $self->fetch( $1 );
    }
    return $self->fetch( $val );
}

sub _store_weak {
    my( $self, $id, $ref ) = @_;

    if( $self->[CACHE] ) {
        $self->[CACHE]->stow( $id, $ref );
    }
    
    $self->[WEAK]{$id} = $ref;

    weaken( $self->[WEAK]{$id} );

} #_store_weak

sub _dirty {
    my( $self, $id ) = @_;
    my $item = $self->[WEAK]{$id};
    $self->[DIRTY]{$id} = $item;
    $item = $self->_knot( $item );
    if( $item ) {
        $item->[METADATA]{updated} = time();
    }
} #_dirty


sub _new_id {
    my( $self ) = @_;
    my $newid = $self->[DATA_PROVIDER]->next_id;
    $newid;
} #_new_id

sub _meta {
    my( $self, $thingy ) = @_;
    return {
      created => $thingy->[METADATA]{created},
      updated => $thingy->[METADATA]{updated},
    };
} #_meta

sub last_updated {
  my( $self, $obj ) = @_;
  $obj = $self->_knot( $obj );
  return undef unless $obj;
  $self->_meta( $obj )->{updated};
}

sub created {
  my( $self, $obj ) = @_;
  $obj = $self->_knot( $obj );
  return undef unless $obj;
  $self->_meta( $obj )->{created};
}

# returns the id of the refernce, injesting it if
# necessary.
# used by tests
sub _get_id {
  my( $self, $ref ) = @_;

  my $class = ref( $ref );
  my $thingy;
  if ( $class eq 'ARRAY' ) {
    $thingy = tied @$ref;
    if ( ! $thingy ) {
      my $id = $self->_new_id;
      my( @items ) = @$ref;
      tie @$ref, 'Data::ObjectStore::Array', $self, $id, { created => time, updated => time}, 0, $Data::ObjectStore::Array::MAX_BLOCKS;
      my $tied = tied @$ref;

      $self->_store_weak( $id, $ref );
      $self->_dirty( $id );
      push @$ref, @items;
      return $id;
    }
    $ref = $thingy;
    $class = ref( $ref );
  }
  elsif ( $class eq 'HASH' ) {
    $thingy = tied %$ref;
    if ( ! $thingy ) {
      my $id = $self->_new_id;
      my( %items ) = %$ref;
      tie %$ref, 'Data::ObjectStore::Hash', $self, $id,  { created => time, updated => time};
      my $tied = tied %$ref;

      $self->_store_weak( $id, $ref );
      $self->_dirty( $id );
      for my $key (keys( %items) ) {
        $ref->{$key} = $items{$key};
      }
      return $id;
    }
    $ref = $thingy;
    $class = ref( $ref );
  }
  else {
    $thingy = $ref;
  }

  die "Data::ObjectStore::_get_id : Cannot ingest object that is not a hash, array or objectstore obj" unless ( $class eq 'Data::ObjectStore::Hash' || $class eq 'Data::ObjectStore::Array' || $ref->isa( 'Data::ObjectStore::Container' ) ); # new id is created upon create container for all Data::ObjectStore::Container instances.

  return $ref->[ID];

} #_get_id

# END PACKAGE Data::ObjectStore

# --------------------------------------------------------------------------------

package Data::ObjectStore::Array;


##################################################################################
# This module is used transparently by ObjectStore to link arrays into its graph #
# structure. This is not meant to be called explicitly or modified.              #
##################################################################################

use strict;
use warnings;
use warnings FATAL => 'all';
no  warnings 'numeric';
no  warnings 'recursion';

use Tie::Array;

$Data::ObjectStore::Array::MAX_BLOCKS = 1_000_000;


use constant {
    ID          => 0,
    DATA        => 1,
    DSTORE      => 2,
    METADATA    => 3,
    LEVEL       => 4,
    BLOCK_COUNT => 5,
    BLOCK_SIZE  => 6,
    ITEM_COUNT  => 7,
    UNDERNEATH  => 8,

    WEAK         => 2,
};

sub store {
    shift->[DSTORE];
}

sub _freezedry {
    my $self = shift;
    my @items;
    my $stuff_count = $self->[BLOCK_COUNT] > $self->[ITEM_COUNT] ? $self->[ITEM_COUNT] : $self->[BLOCK_COUNT];
    if( $stuff_count > 0 ) {
        @items = map { if( defined($_) && $_=~ /[\\\`]/ ) { $_ =~ s/[\\]/\\\\/gs; s/`/\\`/gs; } defined($_) ? $_ : 'u' } map { $self->[DATA][$_] } (0..($stuff_count-1));
    }

    join( "`",
          $self->[LEVEL] || 0,
          $self->[BLOCK_COUNT],
          $self->[ITEM_COUNT] || 0,
          $self->[UNDERNEATH] || 0,
          @items,
        );
}

sub _reconstitute {
    my( $cls, $store, $id, $data, $meta ) = @_;
    my $arry = [];
    tie @$arry, $cls, $store, $id, $meta, @$data;
    return $arry;
}

sub TIEARRAY {
    my( $class, $obj_store, $id, $meta, $level, $block_count, $item_count, $underneath, @list ) = @_;
    $item_count //= 0;
    my $block_size  = $block_count ** $level;

    my $blocks = [@list];
#    $#$blocks = $block_count - 1;

    # once the array is tied, an additional data field will be added
    # so obj will be [ $id, $storage, $obj_store ]
#    die if $id == 1;
    my $obj = bless [
        $id,
        $blocks,
        $obj_store,
        $meta,
        $level,
        $block_count,
        $block_size,
        $item_count,
        $underneath,
        ], $class;

    return $obj;
} #TIEARRAY

sub FETCH {
    my( $self, $idx ) = @_;

    if( $idx >= $self->[ITEM_COUNT] ) {
        return undef;
    }

    if( $self->[LEVEL] == 0 ) {
        return $self->[DSTORE]->_xform_out( $self->[DATA][$idx] );
    }

    my $block = $self->_getblock( int( $idx / $self->[BLOCK_SIZE] ) );
    return $block->FETCH( $idx % $self->[BLOCK_SIZE] );

} #FETCH

sub FETCHSIZE {
    shift->[ITEM_COUNT];
}

sub _embiggen {
    my( $self, $size ) = @_;
    my $store = $self->[DSTORE];

    while( $size > $self->[BLOCK_SIZE] * $self->[BLOCK_COUNT] ) {

        #
        # before embiggen ...
        #   DATA = [ 1,2,3,4,5,6 ]
        # after embiggen
        #   newblock = []
        #   newblockid = 7
        #   DATA = [ 7 ]
        #

        #
        # need to tie a new block, not use _getblock
        # becaues we do squirrely things with its tied guts
        #
        my $newblock = [];
        my $newid = $store->_new_id;
        my $meta = { %{$self->[METADATA]} };
        $meta->{updated} = time;
        tie @$newblock, 'Data::ObjectStore::Array', $store, $newid, $meta, $self->[LEVEL], $self->[BLOCK_COUNT], $self->[ITEM_COUNT], 1;
        $store->_store_weak( $newid, $newblock );
        $store->_dirty( $newid );

        my $tied = tied @$newblock;

        $tied->[DATA] = [@{$self->[DATA]}];

        $self->[DATA] = [ "r$newid" ];

        $self->[BLOCK_SIZE] *= $self->[BLOCK_COUNT];
        $self->[LEVEL]++;
        $store->_dirty( $self->[ID] );
    }

} #_embiggen

#
# get a block at the given block index. Returns undef
# if there isn't one ther, or creates and returns
# one if passed do create
#
sub _getblock {
    my( $self, $block_idx ) = @_;

    my $block_id = $self->[DATA][$block_idx] // 'r0';
    $block_id = substr( $block_id, 1 );
    my $store = $self->[DSTORE];

    if( $block_id > 0 ) {
        my $block = $store->fetch( $block_id );
        return tied(@$block);
    }

    $block_id = $store->_new_id;
    my $block = [];
    my $level = $self->[LEVEL] - 1;
    my $meta = { %{$self->[METADATA]} };
    tie @$block, 'Data::ObjectStore::Array', $store, $block_id, $meta, $level, $self->[BLOCK_COUNT];

    my $tied = tied( @$block );

    $tied->[UNDERNEATH] = 1;
    if( $block_idx >= ($self->[BLOCK_COUNT] - 1 ) ) {
        $tied->[ITEM_COUNT] = $self->[BLOCK_SIZE];
    }

    $store->_store_weak( $block_id, $block );
    $store->_dirty( $block_id );
    $store->_dirty( $self->[ID] );
    $self->[DATA][$block_idx] = "r$block_id";
    return $tied;

} #_getblock

sub STORE {
    my( $self, $idx, $val ) = @_;

    if( $idx >= $self->[BLOCK_COUNT]*$self->[BLOCK_SIZE] ) {
        $self->_embiggen( $idx + 1 );
        $self->STORE( $idx, $val );
        return;
    }

    if( $idx >= $self->[ITEM_COUNT] ) {
        $self->_storesize( $idx + 1 );
        my $store = $self->[DSTORE];
        $store->_dirty( $self->[ID] );
    }

    if( $self->[LEVEL] == 0 ) {
        my( $xid, $xin ) = $self->[DSTORE]->_xform_in( $val );
        if( $xid > 0 && $xid < 3 ) {
            die "cannot store a root node in a list";
        }
        my $store = $self->[DSTORE];
        my $xold = $self->[DATA][$idx] // 0;
        if( $xold ne $xin ) {
            $self->[DATA][$idx] = $xin;
            $store->_dirty( $self->[ID] );
        }

        return;
    }

    my $block = $self->_getblock( int( $idx / $self->[BLOCK_SIZE] ) );
    $block->STORE( $idx % $self->[BLOCK_SIZE], $val );

} #STORE

sub _storesize {
    my( $self, $size ) = @_;
    $self->[ITEM_COUNT] = $size;
}

sub STORESIZE {
    my( $self, $size ) = @_;

    # fixes the size of the array if the array were to shrink
    my $current_oversize = $self->[ITEM_COUNT] - $size;
    if( $current_oversize > 0 ) {
        $self->SPLICE( $size, $current_oversize );
    } #if the array shrinks

    $self->_storesize( $size );

} #STORESIZE

sub EXISTS {
    my( $self, $idx ) = @_;
    if( $idx >= $self->[ITEM_COUNT] ) {
        return 0;
    }
    if( $self->[LEVEL] == 0 ) {
        return defined($self->[DATA][$idx]);
    }
    return $self->_getblock( int( $idx / $self->[BLOCK_SIZE] ) )->EXISTS( $idx % $self->[BLOCK_SIZE] );

} #EXISTS

sub DELETE {
    my( $self, $idx ) = @_;

    my $store = $self->[DSTORE];
    my $del = $self->FETCH( $idx );
    $self->STORE( $idx, undef );
    if( $idx == $self->[ITEM_COUNT] - 1 ) {
        $self->[ITEM_COUNT]--;
        while( $self->[ITEM_COUNT] > 0 && ! defined( $self->FETCH( $self->[ITEM_COUNT] - 1 ) ) ) {
            $self->[ITEM_COUNT]--;
        }

    }
    $store->_dirty( $self->[ID] );

    return $del;

} #DELETE

sub CLEAR {
    my $self = shift;
    if( $self->[ITEM_COUNT] > 0 ) {
        my $store = $self->[DSTORE];
        for( 0..$self->[ITEM_COUNT] ) {
            my $del = $self->FETCH( $_ );
        }
        $self->[ITEM_COUNT] = 0;
        $self->[DATA] = [];
        $self->[DSTORE]->_dirty( $self->[ID] );
    }
}
sub PUSH {
    my( $self, @vals ) = @_;
    return unless @vals;
    $self->SPLICE( $self->[ITEM_COUNT], 0, @vals );
}
sub POP {
    my $self = shift;
    my $idx = $self->[ITEM_COUNT] - 1;
    if( $idx < 0 ) {
        return undef;
    }
    my $pop = $self->FETCH( $idx );
    $self->STORE( $idx, undef );
    $self->[ITEM_COUNT]--;
    return $pop;
}
sub SHIFT {
    my( $self ) = @_;
    return undef unless $self->[ITEM_COUNT];
    my( $ret ) =  $self->SPLICE( 0, 1 );
    $ret;
}

sub UNSHIFT {
    my( $self, @vals ) = @_;
    return unless @vals;
    return $self->SPLICE( 0, 0, @vals );
}

sub SPLICE {
    my( $self, $offset, $remove_length, @vals ) = @_;

    # if no arguments given, clear the array
    if( ! defined( $offset ) ) {
        $offset = 0;
        $remove_length = $self->[ITEM_COUNT];
    }
    
    # if negative, the offset is from the end
    if( $offset < 0 ) {
        $offset = $self->[ITEM_COUNT] + $offset;
    }

    # if negative, remove everything except the abs($remove_length) at
    # the end of the list
    if( $remove_length < 0 ) {
        $remove_length = ($self->[ITEM_COUNT] - $offset) + $remove_length;
    }

    return () unless $remove_length || @vals;

    # check for removal past end
    if( $offset > ($self->[ITEM_COUNT] - 1) ) {
        $remove_length = 0;
        $offset = $self->[ITEM_COUNT];
    }
    if( $remove_length > ($self->[ITEM_COUNT] - $offset) ) {
        $remove_length = $self->[ITEM_COUNT] - $offset;
    }

    #
    # embiggen to delta size if this would grow. Also use the
    # calculated size as a check for correctness.
    #
    my $new_size = $self->[ITEM_COUNT];
    $new_size -= $remove_length;
    $new_size += @vals;

    if( $new_size > $self->[BLOCK_SIZE] * $self->[BLOCK_COUNT] ) {
        $self->_embiggen( $new_size );
    }

    my $store       = $self->[DSTORE];
    my $BLOCK_COUNT = $self->[BLOCK_COUNT];
    my $BLOCK_SIZE  = $self->[BLOCK_SIZE]; # embiggen may have changed this, so dont set this before the embiggen call

    if( $self->[LEVEL] == 0 ) {
        # lowest level, must fit in the size. The end recursion and easy case.
        my $blocks = $self->[DATA];
        my( @invals ) = ( map { ($store->_xform_in($_))[1] } @vals );
        for my $inval (@invals) {
            my( $inid ) = ( $inval =~ /^r(\d+)/ );

            if( $inid && $inid < 3 ) {
                die "cannot store a root node in a list";
            }
        }
        my @raw_return = splice @$blocks, $offset, $remove_length, @invals;
        my @ret;
        for my $rr (@raw_return) {
            push @ret, $store->_xform_out($rr);
        }
        $self->_storesize( $new_size );
        $store->_dirty( $self->[ID] );
        return @ret;
    } # LEVEL == 0 case

    my( @removed );
    while( @vals && $remove_length ) {
        #
        # harmony case. doesn't change the size. eats up vals and remove length
        # until one is zero
        #
        push @removed, $self->FETCH( $offset );
        $self->STORE( $offset++, shift @vals );
        $remove_length--;
    }

    if( $remove_length ) {

        for( my $idx=$offset; $idx<($offset+$remove_length); $idx++ ) {
            push @removed, $self->FETCH( $idx );
        }

        my $things_to_move = $self->[ITEM_COUNT] - ($offset+$remove_length);
        my $to_idx = $offset;
        my $from_idx = $to_idx + $remove_length;
        for( 1..$things_to_move ) {
            $self->STORE( $to_idx, $self->FETCH( $from_idx ) );
            $to_idx++;
            $from_idx++;
        }
    } # has things to remove

    if( @vals ) {
        #
        # while there are any in the insert list, grab all the items in the next block if any
        #    and append to the insert list, then splice in the insert list to the beginning of
        #    the block. There still may be items in the insert list, so repeat until it is done
        #

        my $block_idx = int( $offset / $BLOCK_SIZE );
        my $block_off = $offset % $BLOCK_SIZE;

        while( @vals && ($self->[ITEM_COUNT] > $block_idx*$BLOCK_SIZE+$block_off) ) {
            my $block = $self->_getblock( $block_idx );
            my $bubble_size = $block->FETCHSIZE - $block_off;
            if( $bubble_size > 0 ) {
                my @bubble = $block->SPLICE( $block_off, $bubble_size );
                push @vals, @bubble;
              }
            my $can_insert = @vals > ($BLOCK_SIZE-$block_off) ? ($BLOCK_SIZE-$block_off) : @vals;
            $block->SPLICE( $block_off, 0, splice( @vals, 0, $can_insert ) );
            $block_idx++;
            $block_off = 0;
        }
        while( @vals ) {
            my $block = $self->_getblock( $block_idx );
            my $remmy = $BLOCK_SIZE - $block_off;
            if( $remmy > @vals ) { $remmy = @vals; }

            $block->SPLICE( $block_off, $block->[ITEM_COUNT], splice( @vals, 0, $remmy) );
            $block_idx++;
            $block_off = 0;
        }

    } # has vals

    $self->_storesize( $new_size );

    return @removed;

} #SPLICE

sub EXTEND {
}

sub DESTROY {
    my $self = shift;
    delete $self->[DSTORE]->[WEAK]{$self->[ID]};
}

# END PACKAGE Data::ObjectStore::Array

# --------------------------------------------------------------------------------

package Data::ObjectStore::Hash;

##################################################################################
# This module is used transparently by ObjectStore to link hashes into its       #
# graph structure. This is not meant to  be called explicitly or modified.       #
##################################################################################

use strict;
use warnings;

no warnings 'uninitialized';
no warnings 'numeric';
no warnings 'recursion';

use Tie::Hash;

$Data::ObjectStore::Hash::BUCKET_SIZE = 29;
$Data::ObjectStore::Hash::MAX_SIZE = 1_062_599;

use constant {
    ID          => 0,
    DATA        => 1,
    DSTORE      => 2,
    METADATA    => 3,
    LEVEL       => 4,
    BUCKETS     => 5,
    SIZE        => 6,
    NEXT        => 7,
};

sub store {
    shift->[DSTORE];
}

sub _freezedry {
    my $self = shift;
    my $r = $self->[DATA];
    join( "`",
          $self->[LEVEL],
          $self->[BUCKETS],
          $self->[SIZE],
          map { if( $_=~ /[\\\`]/ ) { s/[\\]/\\\\/gs; s/`/\\`/gs; } $_ }
              $self->[LEVEL] ? @$r : %$r
        );
}

sub _reconstitute {
    my( $cls, $store, $id, $data, $meta ) = @_;
    my $hash = {};
    tie %$hash, $cls, $store, $id, $meta, @$data;

    return $hash;
}

sub TIEHASH {
    my( $class, $obj_store, $id, $meta, $level, $buckets, $size, @fetch_buckets ) = @_;
    $level //= 0;
    $size  ||= 0;
    unless( $buckets ) {
      $buckets = $Data::ObjectStore::Hash::BUCKET_SIZE;
    }
    bless [ $id,
            $level ? [@fetch_buckets] : {@fetch_buckets},
            $obj_store,
            $meta,
            $level,
            $buckets,
            $size,
            [undef,undef],
          ], $class;
} #TIEHASH

sub CLEAR {
    my $self = shift;
    if( $self->[SIZE] > 0 ) {
        $self->[SIZE] = 0;
        my $store = $self->[DSTORE];
        $store->_dirty( $self->[ID] );
        if( $self->[LEVEL] == 0 ) {
          %{$self->[DATA]} = ();
        } else {
          @{$self->[DATA]} = ();
        }
    }
} #CLEAR

sub DELETE {
    my( $self, $key ) = @_;

    return undef unless $self->EXISTS( $key );

    $self->[SIZE]--;

    my $data = $self->[DATA];
    my $store = $self->[DSTORE];

    if( $self->[LEVEL] == 0 ) {
        $store->_dirty( $self->[ID] );
        my $delin = delete $data->{$key};
        return $store->_xform_out( $delin );
    } else {
        my $hval = 0;
        foreach (split //,$key) {
            $hval = $hval*33 - ord($_);
        }
        $hval = $hval % $self->[BUCKETS];
        my $store = $self->[DSTORE];
        return $store->_knot( $store->fetch( substr($data->[$hval], 1 ) ))->DELETE( $key );
    }
} #DELETE


sub EXISTS {
    my( $self, $key ) = @_;

    if( $self->[LEVEL] == 0 ) {
        return exists $self->[DATA]{$key};
    } else {
        my $data = $self->[DATA];
        my $hval = 0;
        foreach (split //,$key) {
            $hval = $hval*33 - ord($_);
        }
        $hval = $hval % $self->[BUCKETS];
        my $hash_id = substr($data->[$hval],1);
        if( $hash_id > 0 ) {
            my $hash = $self->[DSTORE]->fetch( $hash_id );
            my $tied = tied %$hash;
            return $tied->EXISTS( $key );
        }

    }
    return 0;
} #EXISTS

sub FETCH {
    my( $self, $key ) = @_;
    my $data = $self->[DATA];

    if( $self->[LEVEL] == 0 ) {
        return $self->[DSTORE]->_xform_out( $data->{$key} );
    } else {
        my $hval = 0;
        foreach (split //,$key) {
            $hval = $hval*33 - ord($_);
        }
        $hval = $hval % $self->[BUCKETS];
        my $hash = $self->[DSTORE]->_knot(substr($data->[$hval],1));
        if( $hash ) {
          return $hash->FETCH( $key );
        }
    }
    return undef;
} #FETCH

sub STORE {
    my( $self, $key, $val ) = @_;
    my $data = $self->[DATA];

    my $store = $self->[DSTORE];
    my( $xid, $xin ) = $store->_xform_in( $val );
    if( $xid > 0 ) {
        if( $xid < 3 ) {
            $self->[SIZE]--;
            die "cannot store a root node in a hash";
        }
    }

    #
    # EMBIGGEN TEST
    #
    unless( $self->EXISTS( $key ) ) {
        $self->[SIZE]++;
    }

    
    if( $self->[LEVEL] == 0 ) {
        my $oldin = $data->{$key};
        if( $xin ne $oldin ) {
            $data->{$key} = $xin;
            $store->_dirty( $self->[ID] );

            if( $self->[SIZE] > $Data::ObjectStore::Hash::MAX_SIZE ) {

                # do the thing converting this to a deeper level
                $self->[LEVEL] = 1;
                my( @newhash );

                my( @newids ) = ( 0 ) x $Data::ObjectStore::Hash::BUCKET_SIZE;
                $self->[BUCKETS] = $Data::ObjectStore::Hash::BUCKET_SIZE;
                for my $key (keys %$data) {
                    my $hval = 0;
                    foreach (split //,$key) {
                        $hval = $hval*33 - ord($_);
                    }
                    $hval = $hval % $self->[BUCKETS];
                    my $hash = $newhash[$hval];
                    if( $hash ) {
                        my $tied = tied %$hash;
                        $tied->STORE( $key, $store->_xform_out($data->{$key}) );
                    } else {
                        $hash = {};
                        my $hash_id = $store->_new_id;
                        tie %$hash, 'Data::ObjectStore::Hash',
                            $store, $hash_id, {%{$self->[METADATA]}},
                            0, 0, 1, $key, $data->{$key};
                        $store->_store_weak( $hash_id, $hash );
                        $store->_dirty( $hash_id );
                        $newhash[$hval] = $hash;
                        $newids[$hval] = "r$hash_id";
                    }

                }
                $self->[DATA] = \@newids;
                $data = $self->[DATA];
                # here is the problem. this isnt in weak yet!
                # this is a weak reference problem and the problem is at NEXTKEY with
                # LEVEL 0 hashes that are loaded from LEVEL 1 hashes that are loaded from
                # LEVEL 2 hashes. The level 1 hash is loaded and dumped as needed, not keeping
                # the ephermal info (or is that sort of chained..hmm)
                $store->_dirty( $self->[ID] );

            } # EMBIGGEN CHECK
        }
    }
    else { #
        
        my $store = $self->[DSTORE];
        my $hval = 0;
        foreach (split //,$key) {
            $hval = $hval*33 - ord($_);
        }
        $hval = $hval % $self->[BUCKETS];
        my $hash_id = substr($data->[$hval],1);
        my $hash;
        # check if there is a subhash created here
        if( $hash_id > 0 ) {
            # subhash was already created, so store the new val in it
            $hash = $store->fetch( $hash_id );
            my $tied = tied %$hash;
            $tied->STORE( $key, $val );
        } else {
            # subhash not already created, so create then store the new val in it
            # really improbable case.
            $hash = {};
            $hash_id = $store->_new_id;

            tie %$hash, 'Data::ObjectStore::Hash', $store, $hash_id, {%{$self->[METADATA]}}, 0, 0, 1, $key, $xin;

            $store->_store_weak( $hash_id, $hash );
            $store->_dirty( $hash_id );
            $data->[$hval] = "r$hash_id";
        }
    }

} #STORE

sub FIRSTKEY {
    my $self = shift;

    my $data = $self->[DATA];
    if( $self->[LEVEL] == 0 ) {
        my $a = scalar keys %$data; #reset
        my( $k, $val ) = each %$data;
        return wantarray ? ( $k => $self->[DSTORE]->_xform_out( $val ) ) : $k;
    }
    $self->[NEXT] = [undef,undef];
    return $self->NEXTKEY;
}

sub NEXTKEY  {
    my $self = shift;
    my $data = $self->[DATA];
    my $lvl = $self->[LEVEL];
    if( $lvl == 0 ) {
        my( $k, $val ) = each %$data;
        return wantarray ? ( $k => $self->[DSTORE]->_xform_out($val) ) : $k;
    }
    else {
        my $store = $self->[DSTORE];

        my $at_start = ! defined( $self->[NEXT][0] );

        if( $at_start ) {
            $self->[NEXT][0] = 0;
            $self->[NEXT][1] = undef;
        }

        my $hash = $self->[NEXT][1];
        $at_start ||= ! $hash;
        unless( $hash ) {
            my $hash_id = substr( $data->[$self->[NEXT][0]], 1 );
            $hash = $store->fetch( $hash_id ) if $hash_id > 1;
        }

        if( $hash ) {
            my $tied = tied( %$hash );
            my( $k, $v ) = $at_start ? $tied->FIRSTKEY : $tied->NEXTKEY;
            if( defined( $k ) ) {
                $self->[NEXT][1] = $hash; #to keep the weak reference
                return wantarray ? ( $k => $v ) : $k;
            }
        }

        $self->[NEXT][1] = undef;
        $self->[NEXT][0]++;

        if( $self->[NEXT][0] > $#$data ) {
            $self->[NEXT][0] = undef;
            return undef;
        }
        # recursion case, the next bucket has been incremented
        return $self->NEXTKEY;
    }

} #NEXTKEY

sub DESTROY {
    my $self = shift;

    #remove all WEAK_REFS to the buckets
    undef $self->[DATA];

    delete $self->[DSTORE]->[Data::ObjectStore::WEAK]{$self->[ID]};
}

# END PACKAGE Data::ObjectStore::Hash

# --------------------------------------------------------------------------------


package Data::ObjectStore::Container;

use strict;
use warnings;
no  warnings 'uninitialized';
no  warnings 'numeric';

use constant {
    ID          => 0,
    DATA        => 1,
    DSTORE      => 2,
    METADATA    => 3,
    VOLATILE    => 4,
    DIRTY_BIT   => 5,
};

#
# The string version of the objectstore object is simply its id. This allows
# object ids to easily be stored as hash keys.
#
use overload
    '""' => sub { my $self = shift; $self->[ID] },
    eq   => sub { ref($_[1]) && $_[1]->[ID] == $_[0]->[ID] },
    ne   => sub { ! ref($_[1]) || $_[1]->[ID] != $_[0]->[ID] },
    '=='   => sub { ref($_[1]) && $_[1]->[ID] == $_[0]->[ID] },
    '!='   => sub { ! ref($_[1]) || $_[1]->[ID] != $_[0]->[ID] },
    fallback => 1;


sub set {
    my( $self, $fld, $val ) = @_;


    my $store = $self->[DSTORE];
    my( $inid, $inval ) = $store->_xform_in( $val );
    if( $self->[ID] > 2 && $inid > 0 && $inid < 3 ) {
        die "cannot store a root node in a container";
    }

    my $oldval = $self->[DATA]{$fld};

    if( ! defined $self->[DATA]{$fld} || $oldval ne $inval ) {
        $store->_dirty( $self->[ID] );
        $self->[DIRTY_BIT] = 1;
        if( ! defined $val ) {
            $self->[DATA]{$fld} = undef;
            return;
        }
    }

    $self->[DATA]{$fld} = $inval;
    return $store->_xform_out( $self->[DATA]{$fld} );
} #set

sub remove_field {
    my( $self, $fld ) = @_;
    $self->[DSTORE]->_dirty( $self->[ID] );
    $self->[DIRTY_BIT] = 1;
    delete $self->[DATA]{$fld};
}

sub fields {
    my $self = shift;
    return [keys %{$self->[DATA]}];
} #fields

sub get {
    my( $self, $fld, $default ) = @_;

    my $cur = $self->[DATA]{$fld};
    my $store = $self->[DSTORE];
    if( ( ! defined( $cur ) || $cur eq 'u' ) && defined( $default ) ) {
        my( $xid, $xin ) = $store->_xform_in( $default );
        if( ref( $default ) && $self->[ID] > 2 && $xid < 3 ) {
            die "cannot store a root node in a container";
        }
        $store->_dirty( $self->[ID] );
        $self->[DIRTY_BIT] = 1;
        $self->[DATA]{$fld} = $xin;
    }
    return $store->_xform_out( $self->[DATA]{$fld} );

} #get

sub clearvol {
    my( $self, $key ) = @_;
    delete $self->[VOLATILE]{$key};
}

sub clearvols {
    my( $self, @keys ) = @_;
    unless( @keys ) {
        @keys = @{$self->vol_fields};
    }
    for my $key (@keys) {
        delete $self->[VOLATILE]{$key};
    }
}

sub vol {
    my( $self, $key, $val ) = @_;
    if( defined( $val ) ) {
        $self->[VOLATILE]{$key} = $val;
    }
    return $self->[VOLATILE]{$key};
}

sub vol_fields {
    return [keys %{shift->[VOLATILE]}];
}

sub lock {
    shift->store->lock(@_);
}
sub unlock {
    shift->store->unlock;
}

sub store {
    return shift->[DSTORE];
}

#
# Defines get_foo, set_foo, add_to_foolist, remove_from_foolist where foo
# is any arbitrarily named field.
#
sub AUTOLOAD {
    my( $s, $arg ) = @_;
    my $func = our $AUTOLOAD;
    if( $func =~/:add_to_(.*)/ ) {
        my( $fld ) = $1;
        no strict 'refs';
        *$AUTOLOAD = sub {
            my( $self, @vals ) = @_;
            my $get = "get_$fld";
            my $arry = $self->$get([]); # init array if need be
            push( @$arry, @vals );
        };
        use strict 'refs';
        goto &$AUTOLOAD;
    } #add_to
    elsif( $func =~/:add_once_to_(.*)/ ) {
        my( $fld ) = $1;
        no strict 'refs';
        *$AUTOLOAD = sub {
            my( $self, @vals ) = @_;
            my $get = "get_$fld";
            my $arry = $self->$get([]); # init array if need be
            for my $val ( @vals ) {
                unless( grep { $val eq $_ } @$arry ) {
                    push @$arry, $val;
                }
            }
        };
        use strict 'refs';
        goto &$AUTOLOAD;
    } #add_once_to
    elsif( $func =~ /:remove_from_(.*)/ ) { #removes the first instance of the target thing from the list
        my $fld = $1;
        no strict 'refs';
        *$AUTOLOAD = sub {
            my( $self, @vals ) = @_;
            my $get = "get_$fld";
            my $arry = $self->$get([]); # init array if need be
            my( @ret );
          V:
            for my $val (@vals ) {
                for my $i (0..$#$arry) {
                    if( $arry->[$i] eq $val ) {
                        push @ret, splice @$arry, $i, 1;
                        next V;
                    }
                }
            }
            return @ret;
        };
        use strict 'refs';
        goto &$AUTOLOAD;
    }
    elsif( $func =~ /:remove_all_from_(.*)/ ) { #removes the first instance of the target thing from the list
        my $fld = $1;
        no strict 'refs';
        *$AUTOLOAD = sub {
            my( $self, @vals ) = @_;
            my $get = "get_$fld";
            my $arry = $self->$get([]); # init array if need be
            my @ret;
            for my $val (@vals) {
                for( my $i=0; $i<=@$arry; $i++ ) {
                    if( $arry->[$i] eq $val ) {
                        push @ret, splice @$arry, $i, 1;
                        $i--;
                    }
                }
            }
            return @ret;
        };
        use strict 'refs';
        goto &$AUTOLOAD;
    }
    elsif ( $func =~ /:set_(.*)/ ) {
        my $fld = $1;
        no strict 'refs';
        *$AUTOLOAD = sub {
            my( $self, $val ) = @_;
            $self->set( $fld, $val );
        };
        use strict 'refs';
        goto &$AUTOLOAD;
    }
    elsif( $func =~ /:get_(.*)/ ) {
        my $fld = $1;
        no strict 'refs';
        *$AUTOLOAD = sub {
            my( $self, $init_val ) = @_;
            $self->get( $fld, $init_val );
        };
        use strict 'refs';
        goto &$AUTOLOAD;
    }
    else {
        die "Data::ObjectStore::Container::$func : unknown function '$func'.";
    }

} #AUTOLOAD

# -----------------------
#
#     Overridable Methods
#
# -----------------------



sub _init {}


sub _load {}



# -----------------------
#
#     Private Methods
#
# -----------------------

sub _freezedry {
    my $self = shift;
    join( "`", map { if( defined($_) && $_=~ /[\\\`]/ ) { s/[\\]/\\\\/gs; s/`/\\`/gs; } defined($_) ? $_ : 'u' } %{$self->[DATA]} );
}

sub _reconstitute {
    my( $cls, $store, $id, $data, $meta ) = @_;
    my $obj = [$id,{@$data},$store, $meta, {}];
    if( $cls ne 'Data::ObjectStore::Container' ) {
      my $clname = $cls;
      $clname =~ s/::/\//g;

      require "$clname.pm";
    }

    bless $obj, $cls;

    $obj->_load;
    $obj;
}

sub DESTROY {
    my $self = shift;
    delete $self->[DSTORE][Data::ObjectStore::WEAK]{$self->[ID]};
}

# END PACKAGE Data::ObjectStore::Container

1;

__END__

=head1 NAME

Data::ObjectStore - store and lazy load perl objects, hashes and arrays in a rooted tree on-disc.

=head1 SYNOPSIS

 use Data::ObjectStore;

 my $store = Data::ObjectStore::open_store( '/path/to/data-directory' );

 # each store has a root to hang all other data structures from
 my $root = $store->load_root_container;

 # fetches the apps data from the root. If none exists, it uses the
 # default given {} as the app data structure
 my $apps = $root->get_apps({});

 my $newApp = $store->create_container( { name => "CoolNewApp" } );

 $apps->{CoolNewApp} = $newApp;

 my $users = $newApp->set_users_by_name( {} );
 my $admin = $store->create_container( { name => "Admin", isAdmin => 1 } );
 $users->{admin} = $admin;
 $newApp->add_to_users( $admin );

 $store->save; #new app with its admin user saved to store

 ... lots more users added

 #
 # big hashes and lists are chunked and not loaded all into RAM at once.
 #
 my $zillion_users = $newApp->get_users;
 my $zillion_users_by_name = $newApp->get_user_by_name;

 my $fred = $zillion_users_by_name->{fred};


=head1 DESCRIPTION

Data::ObjectStore preserves data structures on disc and provides them
on an add needed basis. Large hashes and arrays are not loaded in
memory all at once while still adhering to the normal perl hash and array
API. The data structures can contain any arraingment of hashes, arrays
and Data::ObjectStore::Container objects which may be subclassed.
Subclassing is described below.

The object database self vacuums; any entry that cannot trace back to the
root node is deleted and the storage space reclaimed.

Data::ObjectStore operates directly and instantly on the file system.
It is not a daemon or server and is not thread safe. It can be used
in a thread safe manner if its controlling program uses locking mechanisms.


=head1 METHODS

=head2 open_store( %options )

Starts up a persistance engine that stores data in the given directory and returns it.
Currently supported options :

=over 2

=item group

permissions group id for the data store on disc.

=back

=head2 data_store

Returns the Data::RecordStore implementaion. 

=head2 empty_cache

Empties the cache, if any.

=head2 fetch( id, force )

Returns the object indexed by that id.
Dies if the saved object's package
cannot be found. If force is given, it will not die
if the object's package can't be found, but the object
will be instantiated as a simple Data::ObjectStore::Container.

=head2 load_root_container()

Fetches the root node of the store,
a Data::ObjectStore::Container object.

=head2 create_container( optionalClass, { data } )

Returns a new Data::ObjectStore::Container container
object or a subclass, depending if the optional class
parameter is supplied. If provided with data, the object
is initialized with the data.

If the object is attached to the root or a container that
is ultimately attached to the root, it will be saved when
save is called.

=head2 save(optional_obj)

When called, this stores the optional_obj or all objects
that have been changed since the last time save was
called. Note that this deletes the objects that are not
connected to root.

=head2 existing_id( obj )

If the object already has an id in the store, this returns
that id. If it does not, it returns undef.

=head2 quick_purge

This is a memory intensive version of vaccuuming the store.
It maintains a hash of all the items to not purge in memory as it runs.
This shouldn't be run if the store is really really big.

=head2 upgrade_store( '/path/to/directory' )

This updagrades the object store to the current version. Back up the store
before applying.

=head2 info()

Returns a hash of info about this opened data store.
Updating the hash has no effect.

 * db_version
 * ObjectStore_version
 * created_time
 * last_update_time

=head2 get_db_version

Returns the version of Data::RecordStore that this was created under.

=head2 get_store_version

Returns the version of Data::ObjectStore that this was created under.

=head2 get_created_time

Returns when the store was created.

=head2 get_last_update_time

=head2 last_updated( obj )

Returns the timestamp the given object was last updated

=head2 created( obj )

Returns the timestamp the given object was created.

Returns the last time this store was updated.

=head2 lock( @names )

Adds an advisory (flock) lock for each of the unique names given.

=head2 unlock()

Unlocks all names locked by this thread

=head2 sync()

Asks the data provider to sync to persistance.

=head1 SUBCLASSING

Blessed objects must be a subclass of Data::ObjectStore::Container
in order to be able to be stored in the object store. _init and _load
can be useful to override.

 package Mad::Science::User;
 use Data::ObjectStore;
 use base 'Data::ObjectStore::Container';

 # called when an object is newly created
 sub _init {
   my $self = shift;
   $self->set_status( "NEWLY CREATED" );
   $self->set_experiments([]);
 }

 # called when the object is loaded from the store
 sub _load {
   my $self = shift;
   print "Loaded " . $self->get_name . " from store";
   if( @{$self->get_experiments} > 0 ) {
     $self->set_status( "DOING EXPERIMENTS" );
   }
 }

 sub evacuate {
   my $self = shift;
   $self->set_status( "HEADING FOR THE HILLS" );
 }



=head1 Data::ObjectStore::Container

 Persistant Perl container object.

=head2 SYNOPSIS

 $obj_A = $store->create_container;

 $obj_B = $store->create_container( {
                          myfoo  => "This foo is mine",
                          mylist => [ "A", "B", "C" ],
                          myhash => { peanut => "Butter" }
                                  } );

 $obj_C = $store->create_container( 'My::Subclass' );

 $obj_D = $store->create_container( 'My::Othersubclass', { initial => "DATA" } );

 #
 # get operations
 #
 print $obj_B->get_myfoo; # prints "this foo is mine"

 print $obj_B->get( "myfoo" ); # prints "this foo is mine"

 print $obj_B->get_myhash->{peanut}; # prints 'butter'

 $val = $obj_A->get_val; # $val is now undef

 $val = $obj_A->get_val("default"); # $val is now 'default'

 $val = $obj_A->get_Val("otherdefault"); # $val is still 'default'

 $val = $obj_A->set_arbitraryfield( "SOMEVALUE" ); # $val is 'SOMEVALUE'

 #
 # set operations
 #
 $obj_C->set( "MYSET", "MYVAL" );
 $val = $obj_C->get_MYSET; # $val is 'MYVAL'

 $obj_B->set_A( $obj_A );

 $root = $store->load_root_container;

 $root->set_B( $obj_B );

 #
 # list operations
 #
 $mylist = $obj_B->add_to_mylist( "D" ); #mylist now 'A','B','C','D'

 $newlist = $obj_B->add_to_newlist( 1, 2, 3, 3, 3 );
 print join(",", $newlist);  # prints 1,2,3,3,3

 $obj_B->remove_from_newlist( 3 );
 print join(",", $newlist);  # prints 1,2,3,3
 $obj_B->remove_all_from_newlist( 3 );
 print join(",", $newlist);  # prints 1,2

 # yes, the $newlist reference is changed when the object is operated on with list operations

=head2 DESCRIPTION

This is a container object that can be used to store key value data
where the keys are strings and the values can be hashes, arrays or
Data::ObjectStore::Container objects. Any instances that can trace a
reference path to the store's root node are reachable upon reload.

This class is designed to be overridden. Two methods are provided
for convenience. _init is run the first time the object is created.
_load is run each time the object is loaded from the data store.
These methods are no-ops in the base class.

=head2 METHODS

=head2 set( field, value )

Sets the field to the given value and returns the value.
The value may be a Data::ObjectStore::Container or subclass, or
a hash or array reference.

=head2 get( field, default_value )

Returns the value associated with the given field.
If the value is not defined and a default value is given,
this sets the value to the given default value and returns
it.

The value may be a Data::ObjectStore::Container or subclass, or
a hash or array reference.

=head2 fields

Returns a list reference of all the field names of the object.

=head2 remove_field( field )

Removes the field from the object.

=head2 vol( key, value )

This sets or gets a temporary (volatile) value attached to the object.

=head2 clearvol( key )

This unsets a temporary (volatile) value attached to the object.

=head2 store

Returns the Data::ObjectStore that created this object.

=head2 lock( @names )

Adds an advisory (flock) lock for each of the unique names given.
This may not be called twice in a row without an unlock in between.

=head2 unlock

Unlocks all names locked by this thread

=head2 _init

    This is called the first time an object is created. It is not
    called when the object is loaded from storage. This can be used
    to set up defaults. This is meant to be overridden.

=cut

=head2 _load

    This is called each time the object is loaded from the data store.
    This is meant to be overridden.


=head1 AUTHOR
       Eric Wolf        coyocanid@gmail.com

=head1 COPYRIGHT AND LICENSE

       Copyright (c) 2012 - 2020 Eric Wolf. All rights reserved.  This program is free software; you can redistribute it and/or modify it
       under the same terms as Perl itself.

=head1 VERSION
       Version 2.13  (Feb, 2020))

=cut
