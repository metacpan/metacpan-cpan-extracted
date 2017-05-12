package Apache2::Translation::MMapDB;

use 5.008008;
use strict;

use Class::Member::HASH -CLASS_MEMBERS=>qw/_db basekey filename root readonly/;
our @CLASS_MEMBERS;

use File::Spec;
use MMapDB qw/:error/;
use Apache2::Translation::_base;
use base 'Apache2::Translation::_base';

use warnings;
no warnings qw(uninitialized);
undef $^W;

our $VERSION = '0.02';

our $DB;

sub new {
  my $parent=shift;
  my $class=ref($parent) || $parent;
  my $I=bless {}=>$class;
  my $x=0;
  my %o=map {($x=!$x) ? lc($_) : $_} @_;

  if( ref($parent) ) {         # inherit first
    foreach my $m (@CLASS_MEMBERS) {
      $I->$m=$parent->$m;
    }
  }

  # then override with named parameters
  foreach my $m (@CLASS_MEMBERS) {
    $I->$m=$o{$m} if( exists $o{$m} );
  }

  if( defined $I->basekey ) {
    unless( ref($I->basekey) eq 'ARRAY' ) {
      if( length $I->basekey ) {
	my $k=$I->basekey;
	if ($k=~m!^\s*\[.+\]\s*$!) {
	  $I->basekey=eval "$k";
	  die $@ if $@;
	} else {
	  $I->basekey=["$k"];
	}
      } else {
	$I->basekey=[];
      }
    }
  } else {
    $I->basekey=[];
  }

  my $fn=$I->filename;
  unless( defined $fn ) {
    # inherit from $DB
    die "ERROR: at least a filename must be set" unless( defined $DB );
    $I->filename=$DB->filename;
    $I->readonly=$DB->readonly;
    $I->_db=$DB;
    return $I;
  }

  $I->filename=$fn=File::Spec->catfile( $I->root, $fn )
    if( length $I->root and length $fn and
	!File::Spec->file_name_is_absolute($fn) );

  if( $DB and
      $I->filename eq $DB->filename and
      !$I->readonly==!$DB->readonly ) {
    $I->_db=$DB;
  } else {
    $I->_db=MMapDB->new(filename=>$I->filename,
			readonly=>$I->readonly,
			($o{nolock} ? () : (lockfile=>$I->filename.'.lock')));
  }
  $DB=$I->_db;

  return $I;
}

sub start {
  $_[0]->_db->start;
}

sub stop {}

sub fetch {
  my ($I, $key, $uri, $with_notes)=@_;

  my $db=$I->_db;
  my @pos=$db->index_lookup($db->mainidx, @{$I->basekey}, 'actn', $key, $uri);

  if( $with_notes ) {
    my %notes=map {
      @{$db->data_record($_)}[1,2];
    } $db->index_lookup($db->mainidx, @{$I->basekey}, 'note', $key, $uri);
    return map {
      my $r=$db->data_record($_);
      # [block order, action, id, note]
      [unpack("N2", $r->[1]), @{$r}[2,3], $notes{$r->[1]}];
    } @pos;
  } else {
    return map {
      my $r=$db->data_record($_);
      # [block order, action, id]
      [unpack("N2", $r->[1]), @{$r}[2,3]];
    } @pos;
  }
}

sub can_notes {1}

# MMapDB uses btrees. hence, keys are already ordered
sub list_keys {
  my ($I)=@_;
  my $k=$I->basekey;
  my $db=$I->_db;
  my ($idx)=$db->index_lookup($db->mainidx, @$k, 'actn');
  return unless defined $idx;
  my @res;
  for( my $it=$db->index_iterator($idx); my ($key)=$it->(); ) {
    push @res, [$key];
  }
  return @res;
}

# MMapDB uses btrees. hence, keys are already ordered
sub list_keys_and_uris {
  my ($I, $key)=@_;

  my $k=$I->basekey;
  my $db=$I->_db;

  my @res;
  if( length $key ) {
    my ($idx)=$db->index_lookup($db->mainidx, @$k, 'actn', $key);
    return unless defined $idx;
    for( my $it=$db->index_iterator($idx); my ($subkey)=$it->(); ) {
      push @res, [$key, $subkey];
    }
  } else {
    my ($idx)=$db->index_lookup($db->mainidx, @$k, 'actn');
    return unless defined $idx;
    for( my $it=$db->index_iterator($idx); ($key, $idx)=$it->(); ) {
      for( my $jt=$db->index_iterator($idx); my ($subkey)=$jt->(); ) {
	push @res, [$key, $subkey];
      }
    }
  }
  return @res;
}

sub begin {
  my ($I)=@_;
  die "ERROR: read-only mode\n" if( $I->readonly );
  $I->_db->begin;
}

sub commit {
  my ($I)=@_;

  $I->_db->commit;
  return "0 but true";
}

sub rollback {
  my ($I)=@_;

  $I->_db->rollback;
  return "0 but true";
}

sub update {
  my $I=shift;
  my $old=shift;
  my $new=shift;

  return $I->insert($new) if $I->delete($old)>0;
  return "0 but true";
}

sub insert {
  my $I=shift;
  my $new=shift;

  die "ERROR: KEY must not contain spaces.\n" if( $new->[nKEY]=~/\s/ );
  die "ERROR: URI must not contain spaces.\n" if( $new->[nURI]=~/\s/ );

  $I->_db->insert([[@{$I->basekey}, 'actn', $new->[nKEY], $new->[nURI]],
		   pack("N2", @{$new}[nBLOCK, nORDER]), $new->[nACTION]]);
  if( length $new->[nNOTE] ) {
    $I->_db->insert([[@{$I->basekey}, 'note', $new->[nKEY], $new->[nURI]],
		     pack("N2", @{$new}[nBLOCK, nORDER]), $new->[nNOTE]]);
  }

  return 1;
}

sub delete {
  my $I=shift;
  my $old=shift;

  my $db=$I->_db;
  my $r=$db->data_record( $db->id_index_lookup($old->[oID]) );
  return "0 but true" unless( $r );

  my $ouri=pop @{$r->[0]};
  my $okey=pop @{$r->[0]};
  my $sort=pack('N2', @{$old}[oBLOCK, oORDER]);
  if( $okey eq $old->[oKEY] and
      $ouri eq $old->[oURI] and
      $sort eq $r->[1] ) {
    $db->delete_by_id($old->[oID]);

    # delete note if any
    foreach my $pos ($db->index_lookup($db->mainidx, @{$I->basekey},
				       'note', $okey, $ouri)) {
      $r=$db->data_record( $pos );
      if( $r->[1] eq $sort ) {
	$db->delete_by_id($r->[3]);
	last;
      } elsif($r->[1] gt $sort) {
	last;
      }
    }

    return 1;
  }

  return "0 but true" unless( $r );
}

sub clear {
  my ($I)=@_;

  my $db=$I->_db;
  # NOTE $it is our iterator not an MMapDB iterator
  for( my $it=$I->iterator; my $r=$it->(); ) {
    my $old=[];
    @{$old}[oKEY, oURI, oBLOCK, oORDER, oID]=
      @{$r}[nKEY, nURI, nBLOCK, nORDER, nID];
    $I->delete($old);
  }
  return "0 but true";
}

sub iterator {
  my ($I)=@_;

  my $db=$I->_db;
  my $basekey=$I->basekey;

  my ($idx)=$db->index_lookup($db->mainidx, @$basekey, 'actn');
  return sub{} unless defined $idx;

  my ($key, $uri);
  my $it=$db->index_iterator($idx);
  ($key, $idx)=$it->();
  my $jt=$db->index_iterator($idx);
  my @pos;
  ($uri, @pos)=$jt->();
  my %notes=map {
    @{$db->data_record($_)}[1,2];
  } $db->index_lookup($db->mainidx, @$basekey, 'note', $key, $uri);

  return sub {
    unless( @pos ) {
      ($uri, @pos)=$jt->();
      unless( @pos ) {
	($key, $idx)=$it->();
	return unless defined $idx;
	$jt=$db->index_iterator($idx);
	($uri, @pos)=$jt->();
      }
      %notes=map {
	@{$db->data_record($_)}[1,2];
      } $db->index_lookup($db->mainidx, @$basekey, 'note', $key, $uri);
    }
    my $r=$db->data_record(shift @pos);
    [$key, $uri, unpack("N2", $r->[1]), $r->[2], $notes{$r->[1]}, $r->[3]];
  };
}

1;
__END__
