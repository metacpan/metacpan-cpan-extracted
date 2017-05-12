package autodbTestObject;
use t::lib;
use strict;
use Carp;
# use Scalar::Util qw(looks_like_number reftype); # sigh. Test::Deep exports reftype, too
use Scalar::Util qw(looks_like_number refaddr);
use List::MoreUtils qw(uniq);
use DBI;
use Test::More;
# Test::Deep doesn't export cmp_details, deep_diag until recent version (0.104)
# so we import them "by hand"
use Test::Deep;
*cmp_details=\&Test::Deep::cmp_details;
*deep_diag=\&Test::Deep::deep_diag;
use Hash::AutoHash::Args;
use autodbUtil;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS %DEFAULTS);
# attributes
#   class being tested            -- computed from current_object if set
#   class2colls={class=>[colls]}
#   class2tables={class=>[tables]}-- computed from class2colls, coll2tables
#   class2transients={class=>[transient keys]}
#   coll2keys={coll=>[[basekeys],[llistkeys]]}
#   coll2basekeys={coll=>[basekeys]}
#   coll2listkeys={coll=>[listkeys]}
#     can set key info in coll2keys, or coll2xxxxkeys. whichever is easiest
#     if set in both, coll2xxxxkeys wins
#   coll2tables={coll=>[tables]} -- computed from coll2keys
#   tables=[tables]              -- computed from class2tables
#   correct_colls=[coll]         -- collections containing object
#                                -- often computed from class2colls
#   correct_tables=[tables]      -- computed from correct_colls, colls2tables
#   correct_diffs=number or {table=>diff}
#     if number, diff for each correct_tables
#     for 'multi' tests, diff is per object
#   default_diffs={table=>diff}  -- any table not mentioned has default of 1
#   labelprefix                  -- string prepended to every label
#   label                        -- sub to compute object-specific portion of label
#   new_args=>sub to construct objects. called w/ TestObject as arg
#     for test_put, these are objects tested.
#     for test_get, these are 'correct' objects
#   old_objects                  -- for put tests, objects already in db
#   put_type                     -- 'put', 'put-multi', 'put_objects', 'put_objects-multi'.
#                                -- 'put_objects' does it w/o args, 
#                                -- 'put_objects-multi' does it w/ args
#                                   default 'put'
#   get_args                     -- args to $autodb->get and find
#     can be a CODE ref or actual args
#   get_type                     -- 'get', 'find', 'find-getnext'. default 'get'
#   del_type                     -- 'del', 'del-multi'. default 'del'
#   object or objects            -- objects to test
#   correct_object or _objects   -- correct objects for retrieval test
#   actual_object or _objects    -- actual objects for retrieval test - synonym for objects
#   del_objects                  -- deleted objects. 
#                                   can be set by hand. updated by test_del
@AUTO_ATTRIBUTES=qw(class2colls class2transients coll2basekeys coll2listkeys default_diffs
		    old_objects del_objects
		    labelprefix 
		    new_args put_type get_args get_type del_type current_object);
@OTHER_ATTRIBUTES=qw(class label class2tables tables coll2keys coll2tables
		     correct_colls correct_tables correct_diffs 
		     object objects correct_object correct_objects);
%SYNONYMS=(last_object=>'current_object',actual_object=>'object',actual_objects=>'objects');
%DEFAULTS=
  (class2colls=>{},class2transients=>{},coll2keys=>{},coll2basekeys=>{},coll2listkeys=>{},
   default_diffs=>{},
   del_objects=>[],
   put_type=>'put',get_type=>'get',del_type=>'del'
   );
# new_args=>sub{my($test)=@_}
sub _init_self {
  my($self,$class,$args)=@_;
  return unless $class eq __PACKAGE__;    # to prevent subclasses from re-running this
  # $self->_init_test;
}
sub _init_test {
  my $self=shift;
  # update any test-specific parameters. Test::Deep exports 'set'. sigh...
  $self->Class::AutoClass::set(@_); 
  # initialize various memoized attributes. deleting the key forces recompute
  delete $self->{coll2tables};
  delete $self->{tables};
  $self->current_object(undef);	# to avoid confusion before entering test loop
  $self->_old_counts;		# initialize old_counts
}
# test and put some objects.
# objects may be constructed here or passed in.
sub test_put {
  my $self=shift;
  my($package,$file,$line)=caller; # for fails
  if (@_==1 && looks_like_number($_[0])) { # arg is number of objects
    $self->objects($self->make_objects(shift));
  }
  $self->_init_test(@_);
  $self->object($self->make_object) unless defined $self->objects;
  my $put_type=$self->put_type;
  if ($put_type=~/multi|objects/) {
    $self->_test_put_multi($file,$line);
  } else {
    $self->_test_put_one($file,$line);
  }
}

# tests that put one object at at time
sub _test_put_one {
  my($self,$file,$line)=@_;
  my @objects=@{$self->objects};
  my %old_objects=map {refaddr($_)=>1} @{$self->old_objects||[]};
  my $put_type=$self->put_type;
  for my $object (@objects) {
    $self->current_object($object); # all class- and object-specific attrs use this
    my $class=$self->class;
    my %coll2keys=%{$self->coll2keys};
    my @correct_colls=@{$self->correct_colls};
    my @tables=@{$self->tables};
    my @correct_tables=@{$self->correct_tables};
    # my $correct_diffs=$self->correct_diffs;
    my $correct_diffs=$old_objects{refaddr $object}? {}: $self->correct_diffs;

    my $ok=1;
    my $label=$self->label."oid before put";
    $ok&&=($old_objects{refaddr $object}? 
	   _ok_oldoid($object,$label,$file,$line):
	   _ok_newoid($object,$label,$file,$line,@tables));
    # $ok&&=_ok_newoid($object,$label,$file,$line,@tables);
    # report_pass($ok,$label);
    # NG 09-12-20: changed 'put_type' semantics so 'put' is only choice here
    # if ($put_type eq 'put') {
    #   autodb->put($object);
    # } elsif ($put_type=~/^put[_-]{0,1}objects/) {
    # autodb->put_objects($object);
    # }
    autodb->put($object);
    remember_oids($object);
    # remember_oids($object) unless $old_objects{refaddr $object};
    next unless $ok;		# skip remaining tests once we have a fail
    my $label=$self->label."oid after put";
    $ok&&=_ok_oldoid($object,$label,$file,$line);
    # report_pass($ok,$label);
    for my $coll (@correct_colls) {
      my $label=$self->label."collection $coll";
      $ok&&=_ok_collection($object,$label,$coll,@{$coll2keys{$coll}},$file,$line);
      report_pass($ok,$label);
    }
    my $actual_diffs=$self->diff_counts(@tables);
    my $details;
    $ok and ($ok,$details)=cmp_details($actual_diffs,$correct_diffs);
    # report($ok,$self->label."table counts",$file,$line,$details);
    report_fail($ok,$self->label."table counts",$file,$line,$details);
    report_pass($ok,$self->label."done");
    # cmp_deeply($actual_diffs,$correct_diffs,$self->label."table counts");
    # report_pass($ok,$label);
    $old_objects{refaddr $object}=1;
  }
  $self->objects(undef);     # clear so won't retest these objects next time
  $self->old_objects(undef); # clear for next time
  scalar @objects;
}
# tests that put multiple objects at once
sub _test_put_multi {
  my($self,$file,$line)=@_;
  my @objects=@{$self->objects};
  my %old_objects=map {refaddr($_)=>1} @{$self->old_objects||[]};
  my $put_type=$self->put_type;
  # do all the before-put tests
  for my $object (@objects) {
    $self->current_object($object); # all class- and object-specific attrs use this
    my $class=$self->class;
    my %coll2keys=%{$self->coll2keys};
    my @correct_colls=@{$self->correct_colls};
    my @tables=@{$self->tables};
    my @correct_tables=@{$self->correct_tables};
    # my $correct_diffs=$self->correct_diffs;
    my $correct_diffs=$old_objects{refaddr $object}? {}: $self->correct_diffs;

    my $ok=1;
    my $label=$self->label."oid before put";
    $ok&&=($old_objects{refaddr $object}? 
	   _ok_oldoid($object,$label,$file,$line):
	   _ok_newoid($object,$label,$file,$line,@tables));
  }
  # now put 'em
  # NG 09-12-20: changed 'put_type' semantics. 'multi' means do it w/args
  if ($put_type=~/objects/) {
    if ($put_type=~/multi/) {
      autodb->put_objects(@objects);
    } else {
      autodb->put_objects;
    }
  } else {
    autodb->put(@objects);
  }
  remember_oids(@objects);
  # now do the per-object after-put tests (and accumulate final diffs)
  my $final_diffs={};
  for my $object (@objects) {
    $self->current_object($object); # all class- and object-specific attrs use this
    my $class=$self->class;
    my %coll2keys=%{$self->coll2keys};
    my @correct_colls=@{$self->correct_colls};
    my @tables=@{$self->tables};
    my @correct_tables=@{$self->correct_tables};
    my $correct_diffs=$old_objects{refaddr $object}? {}: $self->correct_diffs;

    # remember_oids($object) unless $old_objects{refaddr $object};
    my $ok=1;
    my $label=$self->label."oid after put";
    $ok&&=_ok_oldoid($object,$label,$file,$line);
    # report_pass($ok,$label);
    for my $coll (@correct_colls) {
      my $label=$self->label."collection $coll";
      $ok&&=_ok_collection($object,$label,$coll,@{$coll2keys{$coll}},$file,$line);
      report_pass($ok,$label);
    }
    # add correct_diffs to final diffs
    while(my($table,$diff)=each %$correct_diffs) {
      $final_diffs->{$table}+=$diff;
    }
  }
  # test final diffs
  $self->current_object(undef);
  my $actual_diffs=$self->diff_counts;
  my($ok,$details)=cmp_details($actual_diffs,$final_diffs);
  # report($ok,$self->label."table counts",$file,$line,$details);
  report_fail($ok,$self->label."table counts",$file,$line,$details);
  report_pass($ok,$self->label."done");
  # cmp_deeply($actual_diffs,$correct_diffs,$self->label."table counts");
  # report_pass($ok,$label);

  $self->objects(undef);     # clear so won't retest these objects next time
  $self->old_objects(undef); # clear for next time
  scalar @objects;
}

# test objects retrieved from database
# retrieval may be done here or 'actual' objects may be passed in
# 'correct' objects may be constructed here or passed in
# to match actual and correct objects, choices are
#   if objects have 'ids', they are used
#   else actual and correct lists must be supplied in matching order
sub test_get {
  my $self=shift;
  my($package,$file,$line)=caller; # for fails
  if (@_==1 && looks_like_number($_[0])) { # arg is number of objects
    $self->correct_objects($self->make_objects(shift));
  }
  $self->_init_test(@_);
  $self->correct_object($self->make_object) unless defined $self->correct_objects;
  my @correct_objects=@{$self->correct_objects};
  my @actual_objects=defined $self->actual_objects? @{$self->actual_objects}: ();
  my $get_type=$self->get_type;
  # query the database if no 'actual' objects yet
  @actual_objects or @actual_objects=$self->do_get;
  unless(@actual_objects==@correct_objects) {
    report_fail(0,$self->label.'number of objects');
    diag('   got: '.scalar @actual_objects);
    diag('expect: '.scalar @correct_objects);
    return 0;
  }
  my $ok=1;
  reach_fetch(@actual_objects);	# make sure reachable objects in-memory
  my @actual_reach=reach(@actual_objects);
  for my $object (@actual_reach) {
    $self->current_object($object); # all class- and object-specific attrs use this
    my $class=$self->class;
    my %coll2keys=%{$self->coll2keys};
    my @correct_colls=@{$self->correct_colls};
    my @tables=@{$self->tables};
    my @correct_tables=@{$self->correct_tables};

    # my $ok=1;
    my $label=$self->label."(via reach) oid";
    $ok&&=_ok_oldoid($object,$label,$file,$line);
    # report_pass($ok,$label);
    for my $coll (@correct_colls) {
      my $label=$self->label."(via reach) collection $coll";
      $ok&&=_ok_collection($object,$label,$coll,$self->remove_transients(@{$coll2keys{$coll}}),
			   $file,$line);
      # $ok&&=_ok_collection($object,$label,$coll,@{$coll2keys{$coll}},$file,$line);
      # report_pass($ok,$label);
    }
    # report_pass($ok,$self->label.'(via reach) oid and collections');
  }
  $self->current_object(undef); # all class- and object-specific attrs use this
  report_pass($ok,
	      $self->label.(scalar @actual_reach).' objects (via reach) oids and collections');
  # at this point we know that objects-oids-ids are 1:1:1. if we were
  #   willing to assume that all objects have ids, cmp_deeply (which
  #   doesn't check correct sharing of objects) would be strong enough
  #   to complete the job. instead, just to be safe, reach_mark marks
  #   every object with a key that distinguishes shared vs. separate
  #   objects. (I think this works...)
  # NG 09-12-24: abandoned reach_mark. it traverses hash keys in unpredictable order
  #              giving unpredictable results. this means we have to assume that all
  #              objects have id's
  # NG 09-12-21: having changed reach_mark to process all objects in one go, have to arrange
  #              for objects to be in same order
  #              sort the lists by id if all object can do it
#   if (@actual_objects==grep {UNIVERSAL::can($_,'id')} @actual_objects) {
#     @actual_objects=sort {$a->id <=> $b->id} @actual_objects;
#     @correct_objects=sort {$a->id <=> $b->id} @correct_objects;
#   }
#   my @actual_copies=reach_mark(@actual_objects);
#   my @correct_copies=reach_mark(@correct_objects);
#   my @actual_copies=map {reach_mark($_)} @actual_objects;
#   my @correct_copies=map {reach_mark($_)} @correct_objects;

  # sort the lists by id if all object can do it
  # NG 09-12-21: probably redundant with sort above, but can't hurt...
  # NG 09-12-24: sort above commented out.  but we are now assuming all objects have id's
  # if (@actual_copies==grep {UNIVERSAL::can($_,'id')} @actual_copies) {
  my @actual_copies=sort {$a->id <=> $b->id} @actual_objects;
  my @correct_copies=sort {$a->id <=> $b->id} @correct_objects;
  # }
  # at this point, the lists are in matching order
  for(my $i=0; $i<@correct_copies; $i++) {
    $self->current_object($correct_copies[$i]); # label, remove_transients use this
    $self->remove_transients;                   # remove transients from current_object
    my($ok,$details)=cmp_details($actual_copies[$i],$correct_copies[$i]);
    report($ok,$self->label."contents",$file,$line,$details);
  }
  $self->actual_objects(undef);		        # clear so won't retest these objects next time
  $self->correct_objects(undef);                # clear so won't retest these objects next time
  scalar @correct_objects;
}

#####################################
# NG 10-09-08: added del test
# delete and test some objects.
sub test_del {
  my $self=shift;
  my($package,$file,$line)=caller; # for fails
  $self->_init_test(@_);
  my @objects=@{$self->objects};
  my %del_objects=map {refaddr($_)=>1} @{$self->del_objects||[]};
  my $del_type=$self->del_type;
  # do all the before-del tests
  for my $object (@objects) {
    $self->current_object($object); # all class- and object-specific attrs use this
    my $class=$self->class;
    my %coll2keys=%{$self->coll2keys};
    my @correct_colls=@{$self->correct_colls};
    my @tables=@{$self->tables};
    my @correct_tables=@{$self->correct_tables};
    my $correct_diffs=$del_objects{refaddr $object}? {}: $self->correct_diffs;

    my $ok=1;
    my $label=$self->label."oid before del";
    $ok&&=($del_objects{refaddr $object}?
	   _ok_deloid($object,$label,$file,$line,@correct_tables): 1);
  }
  if ($del_type=~/multi/) {
    autodb->del(@objects);
  } else {
    map {autodb->del($_)} @objects;
  }
  # now do the per-object after-del tests (and accumulate final diffs)
  my $final_diffs={};
  for my $object (@objects) {
    $self->current_object($object); # all class- and object-specific attrs use this
    my $class=$self->class;
    my %coll2keys=%{$self->coll2keys};
    my @correct_colls=@{$self->correct_colls};
    my @tables=@{$self->tables};
    my @correct_tables=@{$self->correct_tables};
    my $correct_diffs= $del_objects{refaddr $object}? {}: $self->correct_diffs;

    my $ok=1;
    my $label=$self->label."oid after del";
    $ok&&=_ok_deloid($object,$label,$file,$line,@correct_tables);
    # add correct_diffs to final diffs
    while(my($table,$diff)=each %$correct_diffs) {
      $final_diffs->{$table}-=$diff;
    }
  }
  # test final diffs
  $self->current_object(undef);
  my $actual_diffs=$self->diff_counts;
  my($ok,$details)=cmp_details($actual_diffs,$final_diffs);
  # report($ok,$self->label."table counts",$file,$line,$details);
  report_fail($ok,$self->label."table counts",$file,$line,$details);
  report_pass($ok,$self->label);
  # cmp_deeply($actual_diffs,$correct_diffs,$self->label."table counts");
  # report_pass($ok,$label);

  $self->objects(undef);     # clear so won't retest these objects next time
  push(@{$self->del_objects},@objects); # update for next time
  scalar @objects;
}

sub do_get {
  my $self=shift;
  my $get_args=@_? shift: $self->get_args;
  my $get_type=@_? shift: $self->get_type;
  my $correct_count=@_? shift: scalar @{$self->correct_objects};
  confess 'need to query database but get_args not set' unless $get_args;
  my(@actual_objects,$actual_count);
  if ('CODE' eq ref $get_args) {
    my %get_args=&$get_args($self);
    $get_args=\%get_args;
  }
  if ($get_type eq 'get') {
    @actual_objects=autodb->get($get_args);
    $actual_count=autodb->count($get_args);
  } elsif ($get_type=~/^find([_-]{0,1}get){0,1}$/) {
    my $cursor=autodb->find($get_args);
    @actual_objects=$cursor->get;
    $actual_count=$cursor->count;
  } elsif ($get_type=~/^find[_-]{0,1}get[_-]{0,1}next$/) {
    my $cursor=autodb->find($get_args);
    while (my $object=$cursor->get_next) {
      push(@actual_objects,$object);
    } 
    $actual_count=$cursor->count;
  } else {
    confess "invalid get_type $get_type";
  }
  # is($actual_count,scalar @correct_objects,$self->label.'count');
  unless($actual_count==$correct_count) {
    report_fail(0,$self->label.'count');
    diag("   got: $actual_count");
    diag("expect: $correct_count");
  }
  wantarray? @actual_objects: \@actual_objects;
}
# args are objects. last arg can be put_type
sub do_put {
  my $self=shift;
  my $put_type=!ref $_[$#_]? pop: $self->put_type;
  my @objects=@_;
  if ($put_type=~/multi|objects/) {
    if ($put_type=~/objects/) {
      if ($put_type=~/multi/) {
	autodb->put_objects(@objects);
      } else {
	autodb->put_objects;
      }
    } else {
      autodb->put(@objects);
    }
  } else {
    map {autodb->put($_)} @objects;
  }
}
sub make_object {
  my $self=shift;
  my $objects=$self->make_objects(1);
  # caller now responsible for saving in $self
  # $self->object($objects->[0]);
  $objects->[0];
}
sub make_objects {
  my $self=shift;
  my $n=@_? shift: 1;
  my $class=$self->class;
  my $new_args=$self->new_args;	              # sub
  confess 'need to make objects but new_args not set' unless $new_args; 
  confess 'need to make objects but new_args not CODE ref' unless 'CODE' eq ref $new_args; 
  my @objects=map {my %new_args=&$new_args($self); new $class %new_args;} (1..$n);
  # caller now responsible for saving in $self
  # $self->objects(\@objects);
  \@objects;
}
sub label {
  my $self=shift;
  my $label= @_? $self->{label}=$_[0]: ($self->{label});
  my @label=($self->labelprefix);
  if ('CODE' eq ref $label) {
    push(@label,&$label($self));
  } elsif ($label ne '') {	# empty string means 'no label'
    my $object=$self->current_object;
    push(@label,$label,(UNIVERSAL::can($object,'id')? $object->id: ()));
  }
  @label=map {s/^\s+|\s+$//g; $_} grep {length $_} @label; # strip leading and trailing whitespace
  $label=join(' ',@label).' ';
}
# compute from current_object if set, else use stored value if any
sub class {
  my $self=shift;
  $self->{class}=$_[0] if @_;
  my $ref=ref $self->current_object;
  $ref=$self->current_object->{_CLASS} if UNIVERSAL::isa($ref,'Class::AutoDB::Oid');
  $ref || $self->{class};
}

sub correct_colls {
  my $self=shift;
  if (@_) {
    (@_==1 && 'ARRAY' eq ref $_[0])? $self->{correct_colls}=$_[0]: 
      ($self->{correct_colls}=[@_]);
  }
  my $correct_colls=$self->{correct_colls};
  return $correct_colls if defined $correct_colls;
  # usual case. computed from class2colls
  # NOT memoized since can change as objects are processed 
  my $class=$self->class;
  $self->class2colls->{$class};
}
sub correct_tables {
  my $self=shift;
  if (@_) {
    (@_==1 && 'ARRAY' eq ref $_[0])? $self->{correct_tables}=$_[0]:
      ($self->{correct_tables}=[@_]);
  }
  my $correct_tables=$self->{correct_tables};
  return $correct_tables if defined $correct_tables;
  # usual case. computed from correct_colls which in turn is computed from class2colls
  # NOT memoized since can change as objects are processed 
  my $correct_colls=$self->correct_colls;
  return undef unless defined $correct_colls;
  my $coll2keys=$self->coll2keys;
  my @correct_tables=qw(_AutoDB);	        # everyone needs _AutoDB
  for my $coll (@$correct_colls) {
    my $pair=$coll2keys->{$coll};
    my @tables=($coll,map {$coll.'_'.$_} @{$pair->[1]});
    push(@correct_tables,@tables);
  }
  \@correct_tables;
  # wantarray? @$correct_tables: $correct_tables;
}
sub coll2keys {
  my $self=shift;
  if (@_) {
    (@_==1 && 'HASH' eq ref $_[0])? $self->{coll2keys}=$_[0]: 
      ($self->{coll2keys}={@_});
  }
  my $coll2keys=$self->{coll2keys};
  if (my $coll2basekeys=$self->coll2basekeys) {
    while(my($coll,$basekeys)=each %$coll2basekeys) {
      my $pair=$coll2keys->{$coll} || ($coll2keys->{$coll}=[[],[]]);
      $pair->[0]=$basekeys;
    }
    $self->coll2basekeys(undef); # so won't compute again
  }
  if (my $coll2listkeys=$self->coll2listkeys) {
    while(my($coll,$listkeys)=each %$coll2listkeys) {
      my $pair=$coll2keys->{$coll} || ($coll2keys->{$coll}=[[],[]]);
      $pair->[1]=$listkeys;
    }
    $self->coll2listkeys(undef); # so won't compute again
  }
  $coll2keys;
  # wantarray? %$coll2keys: $coll2keys;
}
sub coll2tables {
  my $self=shift;
  if (@_) {
    (@_==1 && 'HASH' eq ref $_[0])? $self->{coll2tables}=$_[0]: 
      ($self->{coll2tables}={@_});
  }
  my $coll2tables=$self->{coll2tables};
  return $coll2tables if defined $coll2tables;
  # else recompute it
  my $coll2keys=$self->coll2keys;
  my %coll2tables;
  while(my($coll,$pair)=each %$coll2keys) {
    my @tables=($coll,map {$coll.'_'.$_} @{$pair->[1]});
    $coll2tables{$coll}=\@tables;
  }
  $self->{coll2tables}=\%coll2tables;
  # wantarray? %$coll2tables: $coll2tables;
}
sub class2tables {
  my $self=shift;
  if (@_) {
    (@_==1 && 'HASH' eq ref $_[0])? $self->{class2tables}=$_[0]: 
      ($self->{class2tables}={@_});
  }
  my $class2tables=$self->{class2tables};
  return $class2tables if defined $class2tables;
  # else recompute it
  my $class2colls=$self->class2colls;
  my $coll2tables=$self->coll2tables;
  my %class2tables;
  while(my($class,$colls)=each %$class2colls) {
    my @tables;
    for my $coll (@$colls) {
      my $tables=$coll2tables->{$coll};
      push(@tables,@$tables);
    }
    $class2tables{$class}=\@tables;
  }
  $self->{class2tables}=\%class2tables;
}

# all tables
sub tables {
  my $self=shift;
  if (@_) {
    (@_==1 && 'ARRAY' eq ref $_[0])? $self->{tables}=$_[0]: ($self->{tables}={@_});
  }
  my $tables=$self->{tables};
  return $tables if defined $tables;
  # else recompute it
  my @tables=uniq(qw(_AutoDB),map {@$_} values %{$self->coll2tables});
  $self->{tables}=\@tables;
}
sub correct_diffs {
  my $self=shift;
  return $self->{correct_diffs}=$_[0] if @_;
  # my $correct_diffs=@_? $self->{correct_diffs}=$_[0]: ($self->{correct_diffs});
  my $correct_diffs=$self->{correct_diffs};
  if (ref $correct_diffs) { 	# make sure _AutoDB is there
    $correct_diffs->{_AutoDB}=1 unless defined $correct_diffs->{_AutoDB}
  } elsif (my $correct_tables=$self->correct_tables) { # need correct_tables for this form
    my $diff=defined $correct_diffs? $correct_diffs: 1;	# hang onto old value
    $correct_diffs={};
    my @correct_tables=@{$self->correct_tables};
    my $default_diffs=$self->default_diffs;
    # NG 10-09-09: use defaults for any tables mentioned in default_diffs
    @$correct_diffs{@correct_tables}=
      map {defined $default_diffs->{$_}? $default_diffs->{$_}: $diff} @correct_tables;
    # $self->correct_diffs($correct_diffs);
  } else { 			# minimal default
    $correct_diffs={_AutoDB=>1};
  }
  $correct_diffs;
}
sub object {
  my $self=shift;
  $self->objects([@_]) if @_;
  $self->objects->[0];
}
sub objects {
  my $self=shift;
  if (@_) {
    (@_==1 && 'ARRAY' eq ref $_[0])? $self->{objects}=$_[0]:
      (!defined $_[0]? $self->{objects}=undef: ($self->{objects}=[@_]));
    # (@_==1 && looks_like_number($_[0])? $self->make_objects($_[0]):
    # ($self->{objects}=[@_]));
  }
  $self->{objects};
}
sub correct_object {
  my $self=shift;
  $self->correct_objects([@_]) if @_;
  $self->correct_objects->[0];
}
sub correct_objects {
  my $self=shift;
  if (@_) {
    (@_==1 && 'ARRAY' eq ref $_[0])? $self->{correct_objects}=$_[0]:
      (!defined $_[0]? $self->{correct_objects}=undef: ($self->{correct_objects}=[@_]));
    # (@_==1 && looks_like_number($_[0])? $self->make_correct_objects($_[0]):
    # ($self->{correct_objects}=[@_]));
  }
  $self->{correct_objects};
}
# sub clear_objects {
#   my $self=shift;
#   $self->objects([]);
##  $self->object(undef);
# }
sub old_counts {
  my $self=shift;
  my @tables=@_? @_: @{$self->tables};
  my $old_counts=$self->{old_counts} || ($self->_old_counts(@tables));
  # $old_counts=norm_counts(map {$_=>$old_counts->{$_}} @tables);
  $old_counts;
}
sub update_counts {
  my($self,$new_counts)=@_;
  my $old_counts=$self->old_counts;
  my @tables=keys %$new_counts;
  @$old_counts{@tables}=@$new_counts{@tables};
}
sub diff_counts {
  my $self=shift;
  my @tables=@_? @_: @{$self->tables};
  my $old_counts=$self->old_counts(@tables);
  my $new_counts=actual_counts(@tables);
  my $diff_counts={};
  map {$diff_counts->{$_}=$new_counts->{$_}-$old_counts->{$_}} @tables;
  # update old_counts for next time
  $self->update_counts($new_counts);
  $diff_counts=norm_counts($diff_counts);
  # $diff_counts;
}
# sub _coll2keys {
#   my $self=shift;
#   my $coll2keys=$self->coll2keys;
#   if (my $coll2basekeys=$self->coll2basekeys) {
#     while(my($coll,$basekeys)=each %$coll2basekeys) {
#       my $pair=$coll2keys->{$coll} || ($coll2keys->{$coll}=[[],[]]);
#       $pair->[0]=$basekeys;
#     }
#     $self->coll2basekeys(undef); # so won't compute again
#   }
#   if (my $coll2listkeys=$self->coll2listkeys) {
#     while(my($coll,$listkeys)=each %$coll2listkeys) {
#       my $pair=$coll2keys->{$coll} || ($coll2keys->{$coll}=[[],[]]);
#       $pair->[1]=$listkeys;
#     }
#     $self->coll2listkeys(undef); # so won't compute again
#   }
#   # wantarray? %$coll2keys: $coll2keys;
# }
# sub _coll2tables {
#   my $self=shift;
#   delete $self->{coll2tables};	# delete the key so
#   $self->coll2tables;		# this call will recompute
#   my $coll2keys=$self->coll2keys;
#   my $coll2tables=$self->coll2tables;
#   my $tables=$self->tables([qw(_AutoDB)]);
#   my @tables;
#   while(my($coll,$pair)=each %$coll2keys) {
#     my @tables=($coll,map {$coll.'_'.$_} @{$pair->[1]});
#     $coll2tables->{$coll}=\@tables;
#     push(@$tables,@tables);
#   }
#   # wantarray? %$coll2tables: $coll2tables;
# }
# sub _correct_tables {
#   my $self=shift;
#   my @correct_colls=@{$self->correct_colls};
#   my $coll2keys=$self->coll2keys;
#   my $correct_tables=$self->correct_tables([qw(_AutoDB)]);
#   for my $coll (@correct_colls) {
#     my $pair=$coll2keys->{$coll};
#     my @tables=($coll,map {$coll.'_'.$_} @{$pair->[1]});
#     push(@$correct_tables,@tables);
#   }
#   # wantarray? @$correct_tables: $correct_tables;
# }
sub _old_counts {
  my $self=shift;
  my @tables=@_? @_: @{$self->tables};
  my $old_counts=norm_counts(actual_counts(@tables));
  $self->{old_counts}=$old_counts;
  # $old_counts;
}
# remove transients from current_object or arg. arg can be object or pair of keys array
sub remove_transients {
  my $self=shift;
  if (!@_ || Scalar::Util::blessed($_[0])) { # processing object if no arg or arg is blessed
    my $object=@_? shift: $self->current_object;
    my $class=ref $object;
    my $transients=$self->class2transients->{$class} || [];
    for my $key (@$transients) {
      delete $object->{$key}
    }
    return $object;
  } else {			            # processing key list

    my($basekeys,$listkeys)=@_>1? @_: @{$_[0]};
    my $transients=$self->class2transients->{$self->class};
    if ($transients && @$transients) {
      my %transients=map {$_=>$_} @$transients;
      # don't clobber args!!
      my @basekeys=grep {!$transients{$_}} @$basekeys;
      my @listkeys=grep {!$transients{$_}} @$listkeys;
      $basekeys=\@basekeys;
      $listkeys=\@listkeys;
    }
    wantarray? ($basekeys,$listkeys): [$basekeys,$listkeys];
  }
}
1;
