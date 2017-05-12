package Apache2::Translation::File;

use 5.008008;
use strict;

use Fcntl qw/:DEFAULT :flock/;
use Class::Member::HASH -CLASS_MEMBERS=>qw/configfile notesdir
					   root
					   _cache timestamp/;
our @CLASS_MEMBERS;

use File::Spec;
use Apache2::Translation::_base;
use base 'Apache2::Translation::_base';

use warnings;
no warnings qw(uninitialized);
undef $^W;

our $VERSION = '0.06';

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

  $I->_cache={};

  return $I;
}

sub _in {
  my ($sym)=@_;

  if( @{*$sym} ) {
    local $"="  ";
    return shift @{*$sym};
  } else {
    return if( ${*$sym} );
    my $l=<$sym>;
    if( defined $l ) {
      return $l;
    } else {
      ${*$sym}=1;
      return;
    }
  }
}

sub _unin {
  my $sym=shift;
  push @{*$sym}, @_;
}

sub start {
  my $I=shift;
  my $time;
  my $fname;
  if( ref($I->configfile) ) {
    $time=1;
  } else {
    $fname=$I->configfile;
    if( length $I->root ) {
      unless( File::Spec->file_name_is_absolute($fname) ) {
	$fname=File::Spec->catfile( $I->root, $fname );
      }
    }
    $time=(stat $fname)[9];
  }

  if( $time!=$I->timestamp ) {
    $I->timestamp=$time;
    %{$I->_cache}=();
    my $f;
    if( ref($I->configfile) ) {
      $f=$I->configfile;
    } else {
      open $f, $fname or do {
	warn( "ERROR: Cannot open translation provider config file: ".
	      $fname.": $!\n" );
	return;
      };
      flock $f, LOCK_SH or die "ERROR: Cannot flock $fname: $!\n";
    }

    my $l;
    my $cache=$I->_cache;
    while( defined( $l=_in $f ) ) {
      if( $l=~s!^>>>\s*!! ) {	# new key line found
	chomp $l;
	my @l=split /\s+/, $l, 5;
	if( @l==5 ) {
	  my $k=join("\0",@l[1,2]);

	  my $a='';
	  while( defined( $l=_in $f ) ) {
	    next if( $l=~/^#/ );	# comment
	    if( $l=~m!^>>>! ) {		# new key line found
	      _unin $f, $l;
	      last;
	    } else {
	      $a.=$l;
	    }
	  }
	  chomp $a;

	  # cache element:
	  # [block, order, action, id, key, uri]
	  if( exists $cache->{$k} ) {
	    push @{$cache->{$k}}, [@l[3..4],$a,@l[0..2]];
	  } else {
	    $cache->{$k}=[[@l[3..4],$a,@l[0..2]]]
	  }
	}
      }
    }
    close $f;
    foreach my $list (values %{$I->_cache}) {
      @$list=sort {$a->[BLOCK] <=> $b->[BLOCK] or
		   $a->[ORDER] <=> $b->[ORDER]} @$list;
    }
  }
}

sub stop {}

sub _getnote {
  my ($I, $id)=@_;

  my $dname=$I->notesdir;
  if( defined $dname and length $I->root ) {
    unless( File::Spec->file_name_is_absolute($dname) ) {
      $dname=File::Spec->catdir( $I->root, $dname );
    }
  }

  my $content;
  my $f=undef;
  open $f, File::Spec->catfile( $dname, $id ) and $content=<$f>;
  close $f;
  return $content;
}

sub fetch {
  my $I=shift;
  my ($key, $uri, $with_notes)=@_;

  # cache element:
  # [block, order, action, id, note]
  if( $with_notes and length $I->notesdir ) {
    # return element:
    # [block order, action, id, notes]
    local $/;
    return map {[@{$_}[BLOCK,ORDER,ACTION,ID], $I->_getnote($_->[ID])]}
               @{$I->_cache->{join "\0", $key, $uri} || []};
  } else {
    # return element:
    # [block order, action, id]
    return map {[@{$_}[BLOCK,ORDER,ACTION,ID]]}
           @{$I->_cache->{join "\0", $key, $uri} || []};
  }
}

sub can_notes {defined $_[0]->notesdir;}

sub list_keys {
  my $I=shift;

  my %h;
  foreach my $v (values %{$I->_cache}) {
    $h{$v->[0]->[4]}=1;
  }

  return map {[$_]} sort keys %h;
}

sub list_keys_and_uris {
  my $I=shift;

  if( @_ and length $_[0] ) {
    return sort {$a->[1] cmp $b->[1]}
           map {my @l=split "\0", $_, 2; $l[0] eq $_[0] ? [@l] : ()}
           keys %{$I->_cache};
  } else {
    return sort {$a->[0] cmp $b->[0] or $a->[1] cmp $b->[1]}
           map {[@{$_->[0]}[4,5]]} values %{$I->_cache};
  }
}

sub begin {}

sub commit {
  my $I=shift;

  return "0 but true" if( ref $I->configfile );

  my $fname=$I->configfile;
  if( length $I->root ) {
    unless( File::Spec->file_name_is_absolute($fname) ) {
      $fname=File::Spec->catfile( $I->root, $fname );
    }
  }

  my $dname=$I->notesdir;
  if( defined $dname and length $I->root ) {
    unless( File::Spec->file_name_is_absolute($dname) ) {
      $dname=File::Spec->catdir( $I->root, $dname );
    }
  }

  my ($w_id, $w_key, $w_uri, $w_blk, $w_ord)=((3)x5);
  foreach my $v (values %{$I->_cache}) {
    foreach my $el (@{$v}) {
      $w_id =length($el->[3]) if( length($el->[3])>$w_id );
      $w_key=length($el->[4]) if( length($el->[4])>$w_id );
      $w_uri=length($el->[5]) if( length($el->[5])>$w_id );
      $w_blk=length($el->[0]) if( length($el->[0])>$w_id );
      $w_ord=length($el->[1]) if( length($el->[1])>$w_id );
    }
  }

  sysopen my($fh), $fname, O_RDWR | O_CREAT or do {
    die "ERROR: Cannot open $fname: $!\n";
  };
  flock $fh, LOCK_EX or die "ERROR: Cannot flock $fname: $!\n";
  my $oldtime=(stat $fname)[9];

  truncate $fh, 0 or
    do {close $fh; die "ERROR: Cannot truncate to $fname: $!\n"};

  my $fmt=">>> %@{[$w_id-1]}s %-${w_key}s %-${w_uri}s %${w_blk}s %${w_ord}s\n";
  printf $fh '#'.$fmt, qw/id key uri blk ord/ or
    do {close $fh; die "ERROR: Cannot write to $fname: $!\n"};
  print $fh "# action\n" or
    do {close $fh; die "ERROR: Cannot write to $fname: $!\n"};

  $fmt=("##################################################################\n".
	">>> %${w_id}s %-${w_key}s %-${w_uri}s %${w_blk}s %${w_ord}s\n%s\n");
  # this sort-thing is not really necessary. It's just to have the saved
  # config file in a particular order for human readability.
  foreach my $v (map {$I->_cache->{$_}} sort keys %{$I->_cache}) {
    foreach my $el (sort {$a->[0] <=> $b->[0] or $a->[1] <=> $b->[1]} @{$v}) {
      printf $fh $fmt, @{$el}[3..5,0..2] or
	do {close $fh; die "ERROR: Cannot write to $fname: $!\n"};
      if( defined $dname and length $el->[6] ) {
	my $notesf=undef;
	if( open $notesf, '>'.File::Spec->catfile($dname, $el->[3]) ) {
	  print $notesf $el->[6];
	  close $notesf;
	} else {
	  warn "WARNING: Cannot open ".File::Spec->catfile($dname, $el->[3]).": $!\n";
	}
      }
      $#{$el}=5;
    }
  }

  select( (select( $fh ), $|=1)[0] );  # flush buffer

  my $time=time;
  $time=$oldtime+1 if( $time<=$oldtime );

  utime( $time, $time, $fname );
  $I->timestamp=$time;

  if( defined $dname ) {
    opendir my($d), $dname;
    if( $d ) {
      my %h=map {($_->[3]=>1)} map {@$_} values %{$I->_cache};
      while( my $el=readdir $d ) {
	unlink File::Spec->catfile($dname, $el) if( $el=~/^\d+$/ and !exists $h{$el} );
      }
      closedir $d;
    }
  }

  close $fh or die "ERROR: Cannot write to $fname: $!\n";

  return "0 but true";
}

sub rollback {
  my $I=shift;			# reread table
  $I->timestamp=0;
  $I->start;
}

sub update {
  my $I=shift;
  my $old=shift;
  my $new=shift;

  my $list=$I->_cache->{join "\0", @{$old}[0,1]};
  return "0 but true" unless( $list );

  if( $old->[oKEY] eq $new->[oKEY] and
      $old->[oURI] eq $new->[oURI] ) {
    # KEY and URI have not changed
    for( my $i=0; $i<@{$list}; $i++ ) {
      if( $list->[$i]->[ID]    == $old->[oID]    and # id
	  $list->[$i]->[BLOCK] == $old->[oBLOCK] and # block
	  $list->[$i]->[ORDER] == $old->[oORDER] ) { # order
	@{$list->[$i]}[BLOCK,ORDER,ACTION,NOTE]
	  = @{$new}[nBLOCK,nORDER,nACTION,nNOTE];
	@{$list}=sort {$a->[BLOCK] <=> $b->[BLOCK] or
		       $a->[ORDER] <=> $b->[ORDER]} @{$list};
	return 1;
      }
    }
  } else {
    die "ERROR: KEY must not contain spaces.\n" if( $new->[0]=~/\s/ );
    die "ERROR: URI must not contain spaces.\n" if( $new->[1]=~/\s/ );

    for( my $i=0; $i<@{$list}; $i++ ) {
      if( $list->[$i]->[ID]    == $old->[oID]    and # id
	  $list->[$i]->[BLOCK] == $old->[oBLOCK] and # block
	  $list->[$i]->[ORDER] == $old->[oORDER] ) { # order
	my ($el)=splice @{$list}, $i, 1;
	delete $I->_cache->{join "\0", @{$old}[oKEY,oURI]} unless( @{$list} );
	@{$el}[KEY,URI,BLOCK,ORDER,ACTION,NOTE]
	  = @{$new}[nKEY,nURI,nBLOCK,nORDER,nACTION,nNOTE];
	my $k=join("\0",@{$new}[nKEY,nURI]);
	if( exists $I->_cache->{$k} ) {
	  push @{$I->_cache->{$k}}, $el;
	  $I->_cache->{$k}=[sort {$a->[BLOCK] <=> $b->[BLOCK] or
				  $a->[ORDER] <=> $b->[ORDER]}
			    @{$I->_cache->{$k}}];
	} else {
	  $I->_cache->{$k}=[$el]
	}
	return 1;
      }
    }
  }
  return "0 but true";
}

sub insert {
  my $I=shift;
  my $new=shift;

  die "ERROR: KEY must not contain spaces.\n" if( $new->[0]=~/\s/ );
  die "ERROR: URI must not contain spaces.\n" if( $new->[1]=~/\s/ );

  my $newid=0;
  foreach my $v (values %{$I->_cache}) {
    foreach my $el (@{$v}) {
      $newid=$el->[3] if( $el->[3]>$newid );
    }
  }
  $newid++;

  my $newel=[];
  @{$newel}[BLOCK,ORDER,ACTION,KEY,URI,NOTE,ID]=
    (@{$new}[nBLOCK,nORDER,nACTION,nKEY,nURI,nNOTE], $newid);

  my $k=join("\0",@{$new}[nKEY,nURI]);
  if( exists $I->_cache->{$k} ) {
    push @{$I->_cache->{$k}}, $newel;
    $I->_cache->{$k}=[sort {$a->[BLOCK] <=> $b->[BLOCK] or
			    $a->[ORDER] <=> $b->[ORDER]}
		      @{$I->_cache->{$k}}];
  } else {
    $I->_cache->{$k}=[$newel];
  }

  return 1;
}

sub delete {
  my $I=shift;
  my $old=shift;

  my $list=$I->_cache->{join "\0", @{$old}[oKEY,oURI]};
  return "0 but true" unless( $list );

  for( my $i=0; $i<@{$list}; $i++ ) {
    if( $list->[$i]->[ID]    == $old->[oID]    and # id
	$list->[$i]->[BLOCK] == $old->[oBLOCK] and # block
	$list->[$i]->[ORDER] == $old->[oORDER] ) { # order
      splice @{$list}, $i, 1;
      delete $I->_cache->{join "\0", @{$old}[oKEY,oURI]} unless( @{$list} );
      return 1;
    }
  }
  return "0 but true";
}

sub clear {
  my ($I)=@_;

  %{$I->_cache}=();

  return "0 but true";
}

sub iterator {
  my ($I)=@_;

  my $c;
  $c=[0, sort {$a->[0]->[KEY] cmp $b->[0]->[KEY] or
	       $a->[0]->[URI] cmp $b->[0]->[URI]} values %{$I->_cache}];

  return sub {
    my $i=$c->[0]++;
    my $arr=$c->[1];

    unless( $i<=$#{$arr} ) {
      return unless( @{$c}>2 );	# end of data

      $c=[0, @{$c}[2..$#{$c}]];
      $i=$c->[0]++;
      $arr=$c->[1];
    }

    my $new=[];
    @{$new}[nBLOCK,nORDER,nACTION,nKEY,nURI,nID]=
      @{$arr->[$i]}[BLOCK,ORDER,ACTION,KEY,URI,ID];
    $new->[nNOTE]=$I->_getnote($new->[nID]);
    return $new;
  };
}

1;
__END__
