package Ace::Object;
use strict;
use Carp qw(:DEFAULT cluck);

# $Id: Object.pm,v 1.60 2005/04/13 14:26:08 lstein Exp $

use overload 
    '""'       => 'name',
    '=='       => 'eq',
    '!='       => 'ne',
    'fallback' => 'TRUE';
use vars qw($AUTOLOAD $DEFAULT_WIDTH %MO $VERSION);
use Ace 1.50 qw(:DEFAULT rearrange);

# if set to 1, will conflate tags in XML output
use constant XML_COLLAPSE_TAGS => 1;
use constant XML_SUPPRESS_CONTENT=>1;
use constant XML_SUPPRESS_CLASS=>1;
use constant XML_SUPPRESS_VALUE=>0;
use constant XML_SUPPRESS_TIMESTAMPS=>0;

require AutoLoader;

$DEFAULT_WIDTH=25;  # column width for pretty-printing
$VERSION = '1.66';

# Pseudonyms and deprecated methods.
*isClass        =  \&isObject;
*pick           =  \&fetch;
*get            =  \&search;
*add            =  \&add_row;

sub AUTOLOAD {
    my($pack,$func_name) = $AUTOLOAD=~/(.+)::([^:]+)$/;
    my $self = $_[0];

    # This section works with Autoloader
    my $presumed_tag = $func_name =~ /^[A-Z]/ && $self->isObject;  # initial_cap 

    if ($presumed_tag) {
      croak "Invalid object tag \"$func_name\"" 
	if $self->db && $self->model && !$self->model->valid_tag($func_name);

      shift();  # get rid of the object
      my $no_dereference;
      if (defined($_[0])) {
	if ($_[0] eq '@') {
	  $no_dereference++;
	  shift();
	} elsif ($_[0] =~ /^\d+$/) {
	  $no_dereference++;
	}
      }

      $self = $self->fetch if !$no_dereference && 
	!$self->isRoot && $self->db;  # dereference, if need be
      croak "Null object tag \"$func_name\"" unless $self;

      return $self->search($func_name,@_) if wantarray;
      my ($obj) = @_ ? $self->search($func_name,@_) : $self->search($func_name,1);

      # these nasty heuristics simulate aql semantics.
      # undefined return
      return unless defined $obj;

      # don't dereference object if '@' symbol specified
      return $obj if $no_dereference;

      # don't dereference if an offset was explicitly specified
      return $obj if defined($_[0]) && $_[0] =~ /\d+/;

      # otherwise dereference if the current thing is an object or we are at a tag
      # and the thing to the right is an object.
      return $obj->fetch if $obj->isObject && !$obj->isRoot;  # always dereference objects

      # otherwise return the thing itself
      return $obj;
    } elsif ($func_name =~ /^[A-Z]/ && $self->isTag) {  # follow tag
      return $self->search($func_name);
    } else {
      $AutoLoader::AUTOLOAD = __PACKAGE__ . "::$func_name";
      goto &AutoLoader::AUTOLOAD;
    }
}

sub DESTROY {
  my $self = shift;

  return unless defined $self->{class};      # avoid working with temp objects from a search()
  return if caller() =~ /^(Cache\:\:|DB)/;  # prevent recursion in FileCache code
  my $db = $self->db or return;
  return if $self->{'.nocache'};
  return unless $self->isRoot;

  if ($self->_dirty) {
    warn "Destroy for ",overload::StrVal($self)," ",$self->class,':',$self->name if Ace->debug;
    $self->_dirty(0);
    $db->file_cache_store($self);
  }

  # remove our in-memory cache
  # shouldn't be necessary with weakref
  # $db->memory_cache_delete($self);
}

###################### object constructor #################
# IMPORTANT: The _clone subroutine will copy all instance variables that
# do NOT begin with a dot (.).  If you do not want an instance variable
# shared with cloned copies, proceed them with a dot!!!
#
sub new {
  my $pack = shift;
  my($class,$name,$db,$isRoot) = rearrange([qw/CLASS NAME/,[qw/DATABASE DB/],'ROOT'],@_);
  $pack = ref($pack) if ref($pack);
  my $self = bless { 'name'  =>  $name,
		     'class' =>  $class
		   },$pack;
  $self->db($db) if $self->isObject;
  $self->{'.root'}++ if defined $isRoot && $isRoot;
#  $self->_dirty(1)   if $isRoot;
  return $self
}

######### construct object from serialized input, not usually called directly ########
sub newFromText {
  my ($pack,$text,$db) = @_;
  $pack = ref($pack) if ref($pack);

  my @array;
  foreach (split("\n",$text)) {
    next unless $_;
    # this is a hack to fix some txt fields with unescaped tabs
    # unfortunately it breaks other things
    s/\?txt\?([^?]*?)\t([^?]*?)\?/?txt?$1\\t$2?/g;  
    push(@array,[split("\t")]);
  }
  my $obj = $pack->_fromRaw(\@array,0,0,$#array,$db);
  $obj->_dirty(1);
  $obj;
}


################### name of the object #################
sub name {
    my $self = shift;
    $self->{'name'} = shift if  defined($_[0]);
    my $name = $self->_ace_format($self->{'class'},$self->{'name'});
    $name;
}

################### class of the object #################
sub class {
    my $self = shift;
    defined($_[0])
	? $self->{'class'} = shift
	: $self->{'class'};
}

################### name and class together #################
sub id {
  my $self = shift;
  return "$self->{class}:$self->{name}";
}

############## return true if two objects are equivalent ##################
# to be equivalent, they must have identical names, classes and databases #
# We handle comparisons between objects and numbers ourselves, and let    #
# Perl handle comparisons between objects and strings                     #
sub eq {
    my ($a,$b,$rev) = @_;
    unless (UNIVERSAL::isa($b,'Ace::Object')) {
	$a = $a->name + 0; # convert to numeric
	return $a == $b;  # do a numeric comparison
    }
    return 1 if ($a->name eq $b->name) 
      && ($a->class eq $b->class)
	&& ($a->db eq $b->db);
    return;
}

sub ne { 
    return !&eq;
}


############ returns true if this is a top-level object #######
sub isRoot {
  return exists shift()->{'.root'};
}

################### handle to ace database #################
sub db {
  my $self = shift;
  if (@_) {
    my $db = shift;
    $self->{db} = "$db";  # store string representation, not object
  }
  Ace->name2db($self->{db});
}

### Return a portion of the tree at the indicated tag path     ###
#### In a list context returns the column.  In an array context ###
#### returns a pointer to the subtree ####
#### Usually returns what is pointed to by the tag.  Will return
#### the parent object if you pass a true value as the second argument
sub at {
    my $self = shift;
    my($tag,$pos,$return_parent) = rearrange(['TAG','POS','PARENT'],@_);
    return $self->right unless $tag;
    $tag = lc $tag;

    # Removed a $` here to increase speed -- tim.cutts@incyte.com 2 Sep 1999

    if (!defined($pos) and $tag=~/(.*?)\[(\d+)\]$/) {
      $pos = $2;
      $tag = $1;
    }

    my $o = $self;
    my ($parent,$above,$left);
    my (@tags) = $self->_split_tags($tag);
    foreach $tag (@tags) {
      $tag=~s/$;/./g; # unprotect backslashed dots
      my $p = $o;
      ($o,$above,$left) = $o->_at($tag);
      return unless defined($o);
    }
    return $above || $left if $return_parent;
    return defined $pos ? $o->right($pos) : $o unless wantarray;
    return $o->col($pos);
}

### Flatten out part of the tree into an array ####
### along the row.  Will not follow object references.  ###
sub row {
  my $self = shift;
  my $pos = shift;
  my @r;
  my $o = defined $pos ? $self->right($pos) : $self;
  while (defined($o)) {
    push(@r,$o);
    $o = $o->right;
  }
  return @r;
}

### Flatten out part of the tree into an array ####
### along the column. Will not follow object references. ###
sub col {
  my $self = shift;
  my $pos = shift;
  $pos = 1 unless defined $pos;
  croak "Position must be positive" unless $pos >= 0;

  return ($self) unless $pos > 0;

  my @r;
  # This is for tag[1] semantics
  if ($pos == 1) {
    for (my $o=$self->right; defined($o); $o=$o->down) {
      push (@r,$o);
    }
  } else {
    # This is for tag[2] semantics
    for (my $o=$self->right; defined($o); $o=$o->down) {
      next unless defined(my $right = $o->right($pos-2));
      push (@r,$right->col);
    }
  }
  return @r;
}

#### Search for a tag, and return the column ####
#### Uses a breadth-first search (cols then rows) ####
sub search {
  my $self = shift;
  my $tag = shift unless $_[0]=~/^-/;
  my ($subtag,$pos,$filled) = rearrange(['SUBTAG','POS',['FILL','FILLED']],@_);
  my $lctag = lc $tag;

  # With caching, the old way of following ends up cloning the object
  # -- which we don't want.  So more-or-less emulate the earlier
  # behavior with an explicit get and fetch
  #  return $self->follow(-tag=>$tag,-filled=>$filled) if $filled;
  if ($filled) {
    my @node = $self->search($tag) or return;  # watch out for recursion!
    my @obj  = map {$_->fetch} @node;
    foreach (@obj) {$_->right if defined $_};  # trigger a fill
    return wantarray ? @obj : $obj[0];
  }

 TRY: {

    # look in our tag cache first
    if (exists $self->{'.PATHS'}) {

      # we've already cached the desired tree
      last TRY if exists $self->{'.PATHS'}{$lctag};
      
      # not cached, so try parents of tag
      my $m = $self->model;
      my @parents = $m->path($lctag) if $m;
      my $tree;
      foreach (@parents) {
	($tree = $self->{'.PATHS'}{lc $_}) && last;
      }
      if ($tree) {
	$self->{'.PATHS'}{$lctag} = $tree->search($tag);
	$self->_dirty(1);
	last TRY;
      }
    }

    # If the object hasn't been filled already, then we can use
    # acedb's query mechanism to fetch the subobject.  This is a
    # big win for large objects.  ...However, we have to disable
    # this feature if timestamps are active.
    unless ($self->filled) {
      my $subobject = $self->newFromText(
					 $self->db->show($self->class,$self->name,$tag),
					 $self->db
					);
      if ($subobject) {
	$subobject->{'.nocache'}++;
	$self->_attach_subtree($lctag => $subobject);
      } else {
	$self->{'.PATHS'}{$lctag} = undef;
      }
      $self->_dirty(1);
      last TRY;
    }
	
    my @col = $self->col;
    foreach (@col) {
      next unless $_->isTag;
      if (lc $_ eq $lctag) {
	$self->{'.PATHS'}{$lctag} = $_;
	$self->_dirty(1);
	last TRY;
      }
    }

    # if we get here, we didn't find it in the column,
    # so we call ourselves recursively to find it
    foreach (@col) {
      next unless $_->isTag;
      if (my $r = $_->search($tag)) {
	$self->{'.PATHS'}{$lctag} = $r;
	$self->_dirty(1);
	last TRY;
      }
    }

    # If we got here, we just didn't find it.  So tag the cache
    # as empty so that we don't try again
    $self->{'.PATHS'}{$lctag} = undef;
    $self->_dirty(1);
  }

  my $t = $self->{'.PATHS'}{$lctag};
  return unless $t;

  if (defined $subtag) {
    if ($subtag =~ /^\d+$/) {
      $pos = $subtag;
    } else {  # position on subtag and search again
      return $t->fetch->search($subtag,$pos) 
	if $t->isObject  || (defined($t->right) and $t->right->isObject);
      return $t->search($subtag,$pos);
    }
  }

  return defined $pos ? $t->right($pos) : $t  unless wantarray;

  # We do something verrrry interesting in an array context.
  # If no position is defined, we return the column to the right.
  # If a position is defined, we return everything $POS tags
  # to the right (so-called tag[2] system).
  return $t->col($pos);
}

# utility routine used in partial tree caching
sub _attach_subtree {
  my $self             = shift;
  my ($tag,$subobject) = @_;
  my $lctag = lc($tag);
  my $obj;
  if (lc($subobject->right) eq $lctag) { # new version of aceserver as of 11/30/98
    $obj = $subobject->right;
  } else { # old version of aceserver
    $obj = $self->new('tag',$tag,$self->db);
    $obj->{'.right'} = $subobject->right;
  }
  $self->{'.PATHS'}->{$lctag} = $obj;
}

sub _dirty {
  my $self = shift;
  $self->{'.dirty'} = shift if @_ && $self->isRoot;
  $self->{'.dirty'};
}

#### return true if tree is populated, without populating it #####
sub filled {
  my $self = shift;
  return exists($self->{'.right'}) || exists($self->{'.raw'});
}

#### return true if you can follow the object in the database (i.e. a class ###
sub isPickable {
    return shift->isObject;
}

#### Return a string representation of the object subject to Ace escaping rules ###
sub escape {
  my $self = shift;
  my $name = $self->name;
  my $needs_escaping = $name=~/[^\w.-]/ || $self->isClass;
  return $name unless $needs_escaping;
  $name=~s/\"/\\"/g; #escape quotes"
  return qq/"$name"/;
}

############### object on the right of the tree #############
sub right {
  my ($self,$pos) = @_;

  $self->_fill;
  $self->_parse;

  return $self->{'.right'} unless defined $pos;
  croak "Position must be positive" unless $pos >= 0;

  my $node = $self;
  while ($pos--) {
    defined($node = $node->right) || return;
  }
  $node;
}

################# object below on the tree #################
sub down {
  my ($self,$pos) = @_;
  $self->_parse;
  return $self->{'.down'} unless defined $pos;
  my $node = $self;
  while ($pos--) {
    defined($node = $node->down) || return;
  }
  $node;
}

#############################################
#  fetch current node from the database     #
sub fetch {
    my ($self,$tag) = @_;
    return $self->search($tag) if defined $tag;
    my $thing_to_pick = ($self->isTag and defined($self->right)) ? $self->right : $self;
    return $thing_to_pick unless $thing_to_pick->isObject;
    my $obj = $self->db->get($thing_to_pick->class,$thing_to_pick->name) if $self->db;
    return $obj;
}

#############################################
# follow a tag into the database, returning a
# list of followed objects.
sub follow {
    my $self = shift;
    my ($tag,$filled) =  rearrange(['TAG','FILLED'],@_);

    return unless $self->db;
    return $self->fetch() unless $tag;
    my $class = $self->class;
    my $name = Ace->freeprotect($self->name);
    my @options;
    if ($filled) {
      @options = $filled =~ /^[a-zA-Z]/ ? ('filltag' => $filled) : ('filled'=>1);
    }
    return $self->db->fetch(-query=>"find $class $name ; follow $tag",@options);
}

# returns true if the object has a Model, i.e, can be followed into
# the database.
sub isObject {
    my $self = shift;
    return _isObject($self->class);
    1;
}

# returns true if the object is a tag.
sub isTag {
    my $self = shift;
    return 1 if $self->class eq 'tag';
    return;
}

# return the most recent error message
sub error {
  $Ace::Error=~s/\0//g;  # get rid of nulls
  return $Ace::Error;
}

### Returns the object's model (as an Ace::Model object)
sub model {
  my $self = shift;
  return unless $self->db && $self->isObject;
  return $self->db->model($self->class);
}

### Return the class in which to bless all objects retrieved from
# database. Might want to override in other classes
sub factory {
  return __PACKAGE__;
}

#####################################################################
#####################################################################
############### mostly private functions from here down #############
#####################################################################
#####################################################################
# simple clone
sub clone {
  my $self = shift;
  return bless {%$self},ref $self;
}

# selective clone
sub _clone {
    my $self = shift;
    my $pack = ref($self);
    my @public_keys = grep {substr($_,0,1) ne '.'} keys %$self;
    my %newobj;
    @newobj{@public_keys} = @{$self}{@public_keys};

    # Turn into a toplevel object
    $newobj{'.root'}++;
    return bless \%newobj,$pack;
}

sub _fill {
    my $self = shift;
    return if $self->filled;
    return unless $self->db && $self->isObject;

    my $data = $self->db->pick($self->class,$self->name);
    return unless $data;

    # temporary object, don't cache it.
    my $new = $self->newFromText($data,$self->db);
    %{$self}=%{$new};

    $new->{'.nocache'}++; # this line prevents the thing from being cached

    $self->_dirty(1);
}

sub _parse {
  my $self = shift;
  return unless my $raw = $self->{'.raw'};
  my $ts = $self->db->timestamps;
  my $col = $self->{'.col'};
  my $current_obj = $self;
  my $current_row = $self->{'.start_row'};
  my $db = $self->db;
  my $changed;

  for (my $r=$current_row+1; $r<=$self->{'.end_row'}; $r++) {
    next unless $raw->[$r][$col] ne '';
    $changed++;

    my $obj_right = $self->_fromRaw($raw,$current_row,$col+1,$r-1,$db);

    # comment handling
    if ( defined($obj_right) ) {
      my ($t,$i);
      my $row = $current_row+1;
      while ($obj_right->isComment) {
	$current_obj->comment($obj_right)   if $obj_right->isComment;
	$t = $obj_right;
	last unless defined ($obj_right = $self->_fromRaw($raw,$row++,$col+1,$r-1,$db));
      }
    }
    $current_obj->{'.right'} = $obj_right;

    my ($class,$name,$timestamp) = Ace->split($raw->[$r][$col]);
    my $obj_down = $self->new($class,$name,$db);
    $obj_down->timestamp($timestamp) if $ts && $timestamp;

    # comments never occur at down pointers
    $current_obj = $current_obj->{'.down'} = $obj_down;
    $current_row = $r;
  }

  my $obj_right = $self->_fromRaw($raw,$current_row,$col+1,$self->{'.end_row'},$db);

  # comment handling
  if (defined($obj_right)) {
    my ($t,$i);
    my $row = $current_row + 1;
    while ($obj_right->isComment) {
      $current_obj->comment($obj_right)   if $obj_right->isComment;
      $t = $obj_right;
      last unless defined($obj_right = $self->_fromRaw($raw,$row++,$col+1,$self->{'.end_row'},$db));
    }
  }
  $current_obj->{'.right'} = $obj_right;
  $self->_dirty(1) if $changed;
  delete @{$self}{qw[.raw .start_row .end_row .col]};
}

sub _fromRaw {
  my $pack = shift;

  # this breaks inheritance...
  #  $pack = $pack->factory();

  my ($raw,$start_row,$col,$end_row,$db) = @_;
  $db = "$db" if ref $db;
  return unless defined $raw->[$start_row][$col];

  # HACK! Some LongText entries may begin with newlines. This is within the Acedb spec.
  # Let's purge text entries of leading space and format them appropriate.
  # This should probably be handled in Freesubs.xs / Ace::split
  my $temp = $raw->[$start_row][$col];
#  if ($temp =~ /^\?txt\?\s*\n*/) {
#    $temp =~ s/^\?txt\?(\s*\\n*)/\?txt\?/;
#    $temp .= '?';
#  }
  my ($class,$name,$ts) = Ace->split($temp);

  my $self = $pack->new($class,$name,$db,!($start_row || $col));
  @{$self}{qw(.raw .start_row .end_row .col db)} = ($raw,$start_row,$end_row,$col,$db);
  $self->{'.timestamp'} = $ts if defined $ts;
  return $self;
}


# Return partial ace subtree at indicated tag
sub _at {
    my ($self,$tag) = @_;
    my $pos=0;

    # Removed a $` here to increase speed -- tim.cutts@incyte.com 2 Sep 1999

    if ($tag=~/(.*?)\[(\d+)\]$/) {
      $pos=$2;
      $tag=$1;
    }
    my $p;
    my $o = $self->right;
    while ($o) {
	return ($o->right($pos),$p,$self) if (lc($o) eq lc($tag));
	$p = $o;
	$o = $o->down;
    }
    return;
}


# Used to munge special data types.  Right now dates are the
# only examples.
sub _ace_format {
  my $self = shift;
  my ($class,$name) = @_;
  return undef unless defined $class && defined $name;
  return $class eq 'date' ? $self->_to_ace_date($name) : $name;
}

# It's an object unless it is one of these things
sub _isObject {
    return unless defined $_[0];
    $_[0] !~ /^(float|int|date|tag|txt|peptide|dna|scalar|[Tt]ext|comment)$/;
}

# utility routine used to split a tag path into individual components
# allows components to contain dots.
sub _split_tags {
  my $self = shift;
  my $tag = shift;
  $tag =~ s/\\\./$;/g; # protect backslashed dots
  return map { (my $x=$_)=~s/$;/./g; $x } split(/\./,$tag);
}


1;

__END__

=head1 NAME

Ace::Object - Manipulate  Ace Data Objects

=head1 SYNOPSIS

    # open database connection and get an object
    use Ace;
    $db = Ace->connect(-host => 'beta.crbm.cnrs-mop.fr',
                       -port => 20000100);
    $sequence  = $db->fetch(Sequence => 'D12345');
    
    # Inspect the object
    $r    = $sequence->at('Visible.Overlap_Right');
    @row  = $sequence->row;
    @col  = $sequence->col;
    @tags = $sequence->tags;
    
    # Explore object substructure
    @more_tags = $sequence->at('Visible')->tags;
    @col       = $sequence->at("Visible.$more_tags[1]")->col;

    # Follow a pointer into database
    $r     = $sequence->at('Visible.Overlap_Right')->fetch;
    $next  = $r->at('Visible.Overlap_left')->fetch;

    # Classy way to do the same thing
    $r     = $sequence->Overlap_right;
    $next  = $sequence->Overlap_left;

    # Pretty-print object
    print $sequence->asString;
    print $sequence->asTabs;
    print $sequence->asHTML;

    # Update object
    $sequence->replace('Visible.Overlap_Right',$r,'M55555');
    $sequence->add('Visible.Homology','GR91198');
    $sequence->delete('Source.Clone','MBR122');
    $sequence->commit();

    # Rollback changes
    $sequence->rollback()

    # Get errors
    print $sequence->error;

=head1 DESCRIPTION

I<Ace::Object> is the base class for objects returned from ACEDB
databases. Currently there is only one type of I<Ace::Object>, but
this may change in the future to support more interesting
object-specific behaviors.

Using the I<Ace::Object> interface, you can explore the internal
structure of an I<Ace::Object>, retrieve its content, and convert it
into various types of text representation.  You can also fetch a
representation of any object as a GIF image.

If you have write access to the databases, add new data to an object,
replace existing data, or kill it entirely.  You can also create a new
object de novo and write it into the database.

For information on connecting to ACEDB databases and querying them,
see L<Ace>.

=head1 ACEDB::OBJECT METHODS

The structure of an Ace::Object is very similar to that of an Acedb
object.  It is a tree structure like this one (an Author object):

 Thierry-Mieg J->Full_name ->Jean Thierry-Mieg
                  |
                 Laboratory->FF
                  |
                 Address->Mail->CRBM duCNRS
                  |        |     |
                  |        |    BP 5051
                  |        |     |
                  |        |    34033 Montpellier
                  |        |     |
                  |        |    FRANCE
                  |        |
                  |       E_mail->mieg@kaa.cnrs-mop.fr
                  |        |
                  |       Phone ->33-67-613324
                  |        |
                  |       Fax   ->33-67-521559
                  |
                 Paper->The C. elegans sequencing project
                         |
                        Genome Project Database
                         |
                        Genome Sequencing
                         |
                         How to get ACEDB for your Sun
                         |
                        ACEDB is Hungry

Each object in the tree has two pointers, a "right" pointer to the
node on its right, and a "down" pointer to the node beneath it.  Right
pointers are used to store hierarchical relationships, such as
Address->Mail->E_mail, while down pointers are used to store lists,
such as the multiple papers written by the Author.

Each node in the tree has a type and a name.  Types include integers,
strings, text, floating point numbers, as well as specialized
biological types, such as "dna" and "peptide."  Another fundamental
type is "tag," which is a text identifier used to label portions of
the tree.  Examples of tags include "Paper" and "Laboratory" in the
example above.

In addition to these built-in types, there are constructed types known
as classes.  These types are specified by the data model.  In the
above example, "Thierry-Mieg J" is an object of the "Author" class,
and "Genome Project Database" is an object of the "Paper" class.  An
interesting feature of objects is that you can follow them into the
database, retrieving further information.  For example, after
retrieving the "Genome Project Database" Paper from the Author object,
you could fetch more information about it, either by following B<its>
right pointer, or by using one of the specialized navigation routines
described below.

=head2 new() method

    $object = new Ace::Object($class,$name,$database);
    $object = new Ace::Object(-class=>$class,
                              -name=>$name,
                              -db=>database);

You can create a new Ace::Object from scratch by calling the new()
routine with the object's class, its identifier and a handle to the
database to create it in.  The object won't actually be created in the
database until you add() one or more tags to it and commit() it (see
below).  If you do not provide a database handle, the object will be
created in memory only.

Arguments can be passed positionally, or as named parameters, as shown
above.

This routine is usually used internally.  See also add_row(),
add_tree(), delete() and replace() for ways to manipulate this object.

=head2 name() method

    $name = $object->name();

Return the name of the Ace::Object.  This happens automatically
whenever you use the object in a context that requires a string or a
number.  For example:

    $object = $db->fetch(Author,"Thierry-Mieg J");
    print "$object did not write 'Pride and Prejudice.'\n";

=head2 class() method

    $class = $object->class();

Return the class of the object.  The return value may be one of
"float," "int," "date," "tag," "txt," "dna," "peptide," and "scalar."
(The last is used internally by Perl to represent objects created
programatically prior to committing them to the database.)  The class
may also be a user-constructed type such as Sequence, Clone or
Author.  These user-constructed types usually have an initial capital
letter.

=head2 db() method

     $db = $object->db();

Return the database that the object is associated with.

=head2 isClass() method

     $bool = $object->isClass();

Returns true if the object is a class (can be fetched from the
database).

=head2 isTag() method

     $bool = $object->isTag();

Returns true if the object is a tag.

=head2 tags() method

     @tags = $object->tags();

Return all the top-level tags in the object as a list.  In the Author
example above, the returned list would be
('Full_name','Laboratory','Address','Paper').  

You can fetch tags more deeply nested in the structure by navigating
inwards using the methods listed below.

=head2 right() and down() methods

     $subtree = $object->right;
     $subtree = $object->right($position);	
     $subtree = $object->down;
     $subtree = $object->down($position);	

B<right()> and B<down()> provide a low-level way of traversing the
tree structure by following the tree's right and down pointers.
Called without any arguments, these two methods will move one step.
Called with a numeric argument >= 0 they will move the indicated
number of steps (zero indicates no movement).

     $full_name = $object->right->right;
     $full_name = $object->right(2);

     $city = $object->right->down->down->right->right->down->down;
     $city = $object->right->down(2)->right(2)->down(2);

If $object contains the "Thierry-Mieg J" Author object, then the first
series of accesses shown above retrieves the string "Jean
Thierry-Mieg" and the second retrieves "34033 Montpellier."  If the
right or bottom pointers are NULL, these methods will return undef.

In addition to being somewhat awkard, you will probably never need to
use these methods.  A simpler way to retrieve the same information
would be to use the at() method described in the next section.  

The right() and down() methods always walk through the tree of the
current object.  They do not follow object pointers into the database.
Use B<fetch()> (or the deprecated B<pick()> or B<follow()> methods)
instead.

=head2 at() method

    $subtree    = $object->at($tag_path);
    @values     = $object->at($tag_path);

at() is a simple way to fetch the portion of the tree that you are
interested in.  It takes a single argument, a simple tag or a path.  A
simple tag, such as "Full_name", must correspond to a tag in the
column immediately to the right of the root of the tree.  A path such
as "Address.Mail" is a dot-delimited path to the subtree.  Some
examples are given below.

    ($full_name)   = $object->at('Full_name');
    @address_lines = $object->at('Address.Mail');

The second line above is equivalent to:

    @address = $object->at('Address')->at('Mail');

Called without a tag name, at() just dereferences the object,
returning whatever is to the right of it, the same as
$object->right

If a path component already has a dot in it, you may escape the dot
with a backslash, as in:

    $s=$db->fetch('Sequence','M4');
    @homologies = $s->at('Homol.DNA_homol.yk192f7\.3';

This also demonstrates that path components don't necessarily have to
be tags, although in practice they usually are.

at() returns slightly different results depending on the context in
which it is called.  In a list context, it returns the column of
values to the B<right> of the tag.  However, in a scalar context, it
returns the subtree rooted at the tag.  To appreciate the difference,
consider these two cases:

    $name1   = $object->at('Full_name');
    ($name2) = $object->at('Full_name');

After these two statements run, $name1 will be the tag object named
"Full_name", and $name2 will be the text object "Jean Thierry-Mieg",
The relationship between the two is that $name1->right leads to
$name2.  This is a powerful and useful construct, but it can be a trap
for the unwary.  If this behavior drives you crazy, use this
construct:
  
    $name1   = $object->at('Full_name')->at();

For finer control over navigation, path components can include
optional indexes to indicate navigation to the right of the current
path component.  Here is the syntax:

    $object->at('tag1[index1].tag2[index2].tag3[index3]...');

Indexes are zero-based.  An index of [0] indicates no movement
relative to the current component, and is the same as not using an
index at all.  An index of [1] navigates one step to the right, [2]
moves two steps to the right, and so on.  Using the Thierry-Mieg
object as an example again, here are the results of various indexes:

    $object = $db->fetch(Author,"Thierry-Mieg J");
    $a = $object->at('Address[0]')   --> "Address"
    $a = $object->at('Address[1]')   --> "Mail"
    $a = $object->at('Address[2]')   --> "CRBM duCNRS"

In an array context, the last index in the path does something very
interesting.  It returns the entire column of data K steps to the
right of the path, where K is the index.  This is used to implement
so-called "tag[2]" syntax, and is very useful in some circumstances.
For example, here is a fragment of code to return the Thierry-Mieg
object's full address without having to refer to each of the
intervening "Mail", "E_Mail" and "Phone" tags explicitly.

   @address = $object->at('Address[2]');
   --> ('CRBM duCNRS','BP 5051','34033 Montpellier','FRANCE',
        'mieg@kaa.cnrs-mop.fr,'33-67-613324','33-67-521559')

Similarly, "tag[3]" will return the column of data three hops to the
right of the tag.  "tag[1]" is identical to "tag" (with no index), and
will return the column of data to the immediate right.  There is no
special behavior associated with using "tag[0]" in an array context;
it will always return the subtree rooted at the indicated tag.

Internal indices such as "Homol[2].BLASTN", do not have special
behavior in an array context.  They are always treated as if they were
called in a scalar context.

Also see B<col()> and B<get()>.

=head2 get() method

    $subtree    = $object->get($tag);
    @values     = $object->get($tag);
    @values     = $object->get($tag, $position);
    @values     = $object->get($tag => $subtag, $position);

The get() method will perform a breadth-first search through the
object (columns first, followed by rows) for the tag indicated by the
argument, returning the column of the portion of the subtree it points
to.  For example, this code fragment will return the value of the
"Fax" tag.

    ($fax_no) = $object->get('Fax');
         --> "33-67-521559"

The list versus scalar context semantics are the same as in at(), so
if you want to retrieve the scalar value pointed to by the indicated
tag, either use a list context as shown in the example, above, or a
dereference, as in:

     $fax_no = $object->get('Fax');
         --> "Fax"
     $fax_no = $object->get('Fax')->at;
         --> "33-67-521559"

An optional second argument to B<get()>, $position, allows you to
navigate the tree relative to the retrieved subtree.  Like the B<at()>
navigational indexes, $position must be a number greater than or equal
to zero.  In a scalar context, $position moves rightward through the
tree.  In an array context, $position implements "tag[2]" semantics.

For example:

     $fax_no = $object->get('Fax',0);
          --> "Fax"

     $fax_no = $object->get('Fax',1);
          --> "33-67-521559"

     $fax_no = $object->get('Fax',2);
          --> undef  # nothing beyond the fax number

     @address = $object->get('Address',2);
          --> ('CRBM duCNRS','BP 5051','34033 Montpellier','FRANCE',
               'mieg@kaa.cnrs-mop.fr,'33-67-613324','33-67-521559')

It is important to note that B<get()> only traverses tags.  It will
not traverse nodes that aren't tags, such as strings, integers or
objects.  This is in keeping with the behavior of the Ace query
language "show" command.

This restriction can lead to confusing results.  For example, consider
the following object:

 Clone: B0280  Position    Map            Sequence-III  Ends   Left   3569
                                                               Right  3585
                           Pmap           ctg377        -1040  -1024
               Positive    Positive_locus nhr-10
               Sequence    B0280
               Location    RW
               FingerPrint Gel_Number     0
                           Canonical_for  T20H1
                                          K10E5
                           Bands          1354          18


The following attempt to fetch the left and right positions of the
clone will fail, because the search for the "Left" and "Right" tags
cannot traverse "Sequence-III", which is an object, not a tag:

  my $left = $clone->get('Left');    # will NOT work
  my $right = $clone->get('Right');  # neither will this one

You must explicitly step over the non-tag node in order to make this
query work.  This syntax will work:

  my $left = $clone->get('Map',1)->get('Left');   # works
  my $left = $clone->get('Map',1)->get('Right');  # works

Or you might prefer to use the tag[2] syntax here:

  my($left,$right) = $clone->get('Map',1)->at('Ends[2]');

Although not frequently used, there is a form of get() which allows
you to stack subtags:

    $locus = $object->get('Positive'=>'Positive_locus');

Only on subtag is allowed.  You can follow this by a position if wish
to offset from the subtag.

    $locus = $object->get('Positive'=>'Positive_locus',1);

=head2 search() method

This is a deprecated synonym for get().

=head2 Autogenerated Access Methods

     $scalar = $object->Name_of_tag;
     $scalar = $object->Name_of_tag($position);
     @array  = $object->Name_of_tag;
     @array  = $object->Name_of_tag($position);
     @array  = $object->Name_of_tag($subtag=>$position);
     @array  = $object->Name_of_tag(-fill=>$tag);

The module attempts to autogenerate data access methods as needed.
For example, if you refer to a method named "Fax" (which doesn't
correspond to any of the built-in methods), then the code will call
the B<get()> method to find a tag named "Fax" and return its
contents.

Unlike get(), this method will B<always step into objects>.  This
means that:

   $map = $clone->Map;

will return the Sequence_Map object pointed to by the Clone's Map tag
and not simply a pointer to a portion of the Clone tree.  Therefore
autogenerated methods are functionally equivalent to the following:

   $map = $clone->get('Map')->fetch;

The scalar context semantics are also slightly different.  In a scalar
context, the autogenerated function will *always* move one step to the
right.

The list context semantics are identical to get().  If you want to
dereference all members of a multivalued tag, you have to do so manually:

  @papers = $author->Paper;
  foreach (@papers) { 
    my $paper = $_->fetch;
    print  $paper->asString;
  }

You can provide an optional positional index to rapidly navigate
through the tree or to obtain tag[2] behavior.  In the following
examples, the first two return the object's Fax number, and the third
returns all data two hops to the right of Address.

     $object   = $db->fetch(Author => 'Thierry-Mieg J');
     ($fax_no) = $object->Fax;
     $fax_no   = $object->Fax(1);
     @address  = $object->Address(2);

You may also position at a subtag, using this syntax:

     $representative = $object->Laboratory('Representative');

Both named tags and positions can be combined as follows:

     $lab_address = $object->Laboratory(Address=>2);

If you provide a -fill=>$tag argument, then the object fetch will
automatically fill the specified subtree, greatly improving
performance.  For example:

      $lab_address = $object->Laboratory(-filled=>'Address');

** NOTE: In a scalar context, if the node to the right of the tag is
** an object, the method will perform an implicit dereference of the
** object.  For example, in the case of:

    $lab = $author->Laboratory;

**NOTE: The object returned is the dereferenced Laboratory object, not
a node in the Author object.  You can control this by giving the
autogenerated method a numeric offset, such as Laboratory(0) or
Laboratory(1).  For backwards compatibility, Laboratory('@') is
equivalent to Laboratory(1).

The semantics of the autogenerated methods have changed subtly between
version 1.57 (the last stable release) and version 1.62.  In earlier
versions, calling an autogenerated method in a scalar context returned
the subtree rooted at the tag.  In the current version, an implicit
right() and dereference is performed.


=head2 fetch() method

    $new_object = $object->fetch;
    $new_object = $object->fetch($tag);

Follow object into the database, returning a new object.  This is
the best way to follow object references.  For example:

    $laboratory = $object->at('Laboratory')->fetch;
    print $laboratory->asString;

Because the previous example is a frequent idiom, the optional $tag
argument allows you to combine the two operations into a single one:

    $laboratory = $object->fetch('Laboratory');

=head2 follow() method

    @papers        = $object->follow('Paper');
    @filled_papers = $object->follow(-tag=>'Paper',-filled=>1);
    @filled_papers = $object->follow(-tag=>'Paper',-filled=>'Author');

The follow() method will follow a tag into the database, dereferencing
the column to its right and returning the objects resulting from this
operation.  Beware!  If you follow a tag that points to an object,
such as the Author "Paper" tag, you will get a list of all the Paper
objects.  If you follow a tag that points to a scalar, such as
"Full_name", you will get an empty string.  In a scalar context, this
method will return the number of objects that would have been
followed.

The full named-argument form of this call accepts the arguments
B<-tag> (mandatory) and B<-filled> (optional).  The former points to
the tag to follow.  The latter accepts a boolean argument or the name
of a subtag.  A numeric true argument will return completely "filled"
objects, increasing network and memory usage, but possibly boosting
performance if you have a high database access latency.
Alternatively, you may provide the name of a tag to follow, in which
case just the named portion of the subtree in the followed objects
will be filled (v.g.)

For backward compatability, if follow() is called without any
arguments, it will act like fetch().

=head2 pick() method

Deprecated method.  This has the same semantics as fetch(), which
should be used instead.

=head2 col() method

     @column = $object->col;
     @column = $object->col($position);


B<col()> flattens a portion of the tree by returning the column one
hop to the right of the current subtree. You can provide an additional
positional index to navigate through the tree using "tag[2]" behavior.
This example returns the author's mailing address:

  @mailing_address = $object->at('Address.Mail')->col();

This example returns the author's entire address including mail,
e-mail and phone:

  @address = $object->at('Address')->col(2);

It is equivalent to any of these calls:

  $object->at('Address[2]');
  $object->get('Address',2);
  $object->Address(2);

Use whatever syntax is most comfortable for you.

In a scalar context, B<col()> returns the number of items in the
column.

=head2 row() method

     @row=$object->row();
     @row=$object->row($position);

B<row()> will return the row of data to the right of the object.  The
first member of the list will be the object itself.  In the case of
the "Thierry-Mieg J" object, the example below will return the list
('Address','Mail','CRBM duCNRS').

     @row = $object->Address->row();

You can provide an optional position to move rightward one or more
places before retrieving the row.  This code fragment will return
('Mail','CRBM duCNRS'):

     @row = $object->Address->row(1);

In a scalar context, B<row()> returns the number of items in the row.

=head2 asString() method

    $object->asString;

asString() returns a pretty-printed ASCII representation of the object
tree.

=head2 asTable() method

    $object->asTable;

asTable() returns the object as a tab-delimited text table.

=head2 asAce() method

    $object->asAce;

asAce() returns the object as a tab-delimited text table in ".ace"
format.

=head2 asHTML() method

   $object->asHTML;
   $object->asHTML(\&tree_traversal_code);

asHTML() returns an HTML 3 table representing the object, suitable for
incorporation into a Web browser page.  The callback routine, if
provided, will have a chance to modify the object representation
before it is incorporated into the table, for example by turning it
into an HREF link.  The callback takes a single argument containing
the object, and must return a string-valued result.  It may also
return a list as its result, in which case the first member of the
list is the string representation of the object, and the second
member is a boolean indicating whether to prune the table at this
level.  For example, you can prune large repetitive lists.

Here's a complete example:

   sub process_cell {
     my $obj = shift;
     return "$obj" unless $obj->isObject || $obj->isTag;

     my @col = $obj->col;
     my $cnt = scalar(@col);
     return ("$obj -- $cnt members",1);  # prune
            if $cnt > 10                 # if subtree to big

     # tags are bold
     return "<B>$obj</B>" if $obj->isTag;  

     # objects are blue
     return qq{<FONT COLOR="blue">$obj</FONT>} if $obj->isObject; 
   }

   $object->asHTML(\&process_cell);

=head2 asXML() method

   $result = $object->asXML;

asXML() returns a well-formed XML representation of the object.  The
particular representation is still under discussion, so this feature
is primarily for demonstration.

=head2 asGIF() method

  ($gif,$boxes) = $object->asGIF();
  ($gif,$boxes) = $object->asGIF(-clicks=>[[$x1,$y1],[$x2,$y2]...]
	                         -dimensions=> [$width,$height],
				 -coords    => [$top,$bottom],
				 -display   => $display_type,
				 -view      => $view_type,
				 -getcoords => $true_or_false
	                         );

asGIF() returns the object as a GIF image.  The contents of the GIF
will be whatever xace would ordinarily display in graphics mode, and
will vary for different object classes.

You can optionally provide asGIF with a B<-clicks> argument to
simulate the action of a user clicking on the image.  The click
coordinates should be formatted as an array reference that contains a
series of two-element subarrays, each corresponding to the X and Y
coordinates of a single mouse click.  There is currently no way to
pass information about middle or right mouse clicks, dragging
operations, or keystrokes.  You may also specify a B<-dimensions> to
control the width and height of the returned GIF.  Since there is no
way of obtaining the preferred size of the image in advance, this is
not usually useful.

The optional B<-display> argument allows you to specify an alternate
display for the object.  For example, Clones can be displayed either
with the PMAP display or with the TREE display.  If not specified, the
default display is used.

The optional B<-view> argument allows you to specify an alternative
view for MAP objects only.  If not specified, you'll get the default
view.

The option B<-coords> argument allows you to provide the top and
bottom of the display for MAP objects only.  These coordinates are in
the map's native coordinate system (cM, bp).  By default, AceDB will
show most (but not necessarily all) of the map according to xace's
display rules.  If you call this method with the B<-getcoords>
argument and a true value, it will return a two-element array
containing the coordinates of the top and bottom of the map.

asGIF() returns a two-element array.  The first element is the GIF
data.  The second element is an array reference that indicates special 
areas of the image called "boxes."  Boxes are rectangular areas that
surround buttons, and certain displayed objects.  Using the contents
of the boxes array, you can turn the GIF image into a client-side
image map.  Unfortunately, not everything that is clickable is
represented as a box.  You still have to pass clicks on unknown image
areas back to the server for processing.

Each box in the array is a hash reference containing the following
keys:

    'coordinates'  => [$left,$top,$right,$bottom]
    'class'        => object class or "BUTTON"
    'name'         => object name, if any
    'comment'      => a text comment of some sort

I<coordinates> points to an array of points indicating the top-left and 
bottom-right corners of the rectangle.  I<class> indicates the class
of the object this rectangle surrounds.  It may be a database object,
or the special word "BUTTON" for one of the display action buttons.
I<name> indicates the name of the object or the button.  I<comment> is 
some piece of information about the object in question.  You can
display it in the status bar of the browser or in a popup window if
your browser provides that facility.

=head2 asDNA() and asPeptide() methods

    $dna = $object->asDNA();
    $peptide = $object->asPeptide();

If you are dealing with a sequence object of some sort, these methods
will return strings corresponding to the DNA or peptide sequence in
FASTA format.

=head2 add_row() method

    $result_code = $object->add_row($tag=>$value);    
    $result_code = $object->add_row($tag=>[list,of,values]);    
    $result_code = $object->add(-path=>$tag,
				-value=>$value);

add_row() updates the tree by adding data to the indicated tag path.  The
example given below adds the value "555-1212" to a new Address entry
named "Pager".  You may call add_row() a second time to add a new value
under this tag, creating multi-valued entries.

 $object->add_row('Address.Pager'=>'555-1212');

You may provide a list of values to add an entire row of data.  For
example:

 $sequence->add_row('Assembly_tags'=>['Finished Left',38949,38952,'AC3']);

Actually, the array reference is not entirely necessary, and if you
prefer you can use this more concise notation:

 $sequence->add_row('Assembly_tags','Finished Left',38949,38952,'AC3');

No check is done against the database model for the correct data type
or tag path.  The update isn't actually performed until you call
commit(), at which time a result code indicates whether the database
update was successful.

You may create objects that reference other objects this way:

    $lab = new Ace::Object('Laboratory','LM',$db);
    $lab->add_row('Full_name','The Laboratory of Medicine');
    $lab->add_row('City','Cincinatti');
    $lab->add_row('Country','USA');

    $author = new Ace::Object('Author','Smith J',$db);
    $author->add_row('Full_name','Joseph M. Smith');
    $author->add_row('Laboratory',$lab);

    $lab->commit();
    $author->commit();

The result code indicates whether the addition was syntactically
correct.  add_row() will fail if you attempt to add a duplicate entry
(that is, one with exactly the same tag and value).  In this case, use
replace() instead.  Currently there is no checking for an attempt to
add multiple values to a single-valued (UNIQUE) tag.  The error will
be detected and reported at commit() time however.

The add() method is an alias for add_row().

See also the Ace->new() method.

=head2 add_tree()

  $result_code = $object->add_tree($tag=>$ace_object);
  $result_code = $object->add_tree(-tag=>$tag,-tree=>$ace_object);

The add_tree() method will insert an entire Ace subtree into the object
to the right of the indicated tag.  This can be used to build up
complex Ace objects, or to copy portions of objects from one database
to another.  The first argument is a tag path, and the second is the
tree that you wish to insert.  As with add_row() the database will
only be updated when you call commit().

When inserting a subtree, you must be careful to remember that
everything to the *right* of the node that you are pointing at will be
inserted; not the node itself.  For example, given this Sequence
object:

  Sequence AC3
    DB_info     Database    EMBL
    Assembly_tags   Finished Left   1   4   AC3
                    Clone left end      1   4   AC3
                    Clone right end     5512    5515    K07C5
                                        38949   38952   AC3
                    Finished Right      38949   38952   AC3

If we use at('Assembly_tags') to fetch the subtree rooted on the
"Assembly_tags" tag, it is the tree to the right of this tag,
beginning with "Finished Left", that will be inserted.

Here is an example of copying the "Assembly_tags" subtree
from one database object to another:

 $remote = Ace->connect(-port=>200005)  || die "can't connect";
 $ac3 = $remote->fetch(Sequence=>'AC3') || die "can't get AC7";
 my $assembly = $ac3->at('Assembly_tags');

 $local = Ace->connect(-path=>'~acedb') || die "can't connect";
 $AC3copy = Ace::Object->new(Sequence=>'AC3copy',$local);
 $AC3copy->add_tree('Assembly_tags'=>$tags);
 $AC3copy->commit || warn $AC3copy->error;

Notice that this syntax will not work the way you think it should:

 $AC3copy->add_tree('Assembly_tags'=>$ac3->at('Assembly_tags'));

This is because call at() in an array context returns the column to
the right of the tag, not the tag itself.

Here's an example of building up a complex structure from scratch
using a combination of add() and add_tree():

 $newObj = Ace::Object->new(Sequence=>'A555',$local);
 my $assembly = Ace::Object->new(tag=>'Assembly_tags');
 $assembly->add('Finished Left'=>[10,20,'ABC']);
 $assembly->add('Clone right end'=>[1000,2000,'DEF']);
 $assembly->add('Clone right end'=>[8000,9876,'FRED']);
 $assembly->add('Finished Right'=>[1000,3000,'ETHEL']);
 $newObj->add_tree('Assembly_tags'=>$assembly);
 $newObj->commit || warn $newObj->error;

=head2 delete() method

    $result_code = $object->delete($tag_path,$value);
    $result_code = $object->delete(-path=>$tag_path,
                                   -value=>$value);

Delete the indicated tag and value from the object.  This example
deletes the address line "FRANCE" from the Author's mailing address:

    $object->delete('Address.Mail','FRANCE');

No actual database deletion occurs until you call commit().  The
delete() result code indicates whether the deletion was successful.
Currently it is always true, since the database model is not checked.
    
=head2 replace() method

    $result_code = $object->replace($tag_path,$oldvalue,$newvalue);
    $result_code = $object->replace(-path=>$tag_path,
				    -old=>$oldvalue,
				    -new=>$newvalue);

Replaces the indicated tag and value with the new value.  This example
changes the address line "FRANCE" to "LANGUEDOC" in the Author's
mailing address:

    $object->delete('Address.Mail','FRANCE','LANGUEDOC');

No actual database changes occur until you call commit().  The
delete() result code indicates whether the replace was successful.
Currently is true if the old value was identified.

=head2 commit() method

     $result_code = $object->commit;

Commits all add(), replace() and delete() operations to the database.
It can also be used to write a completely new object into the
database.  The result code indicates whether the object was
successfully written.  If an error occurred, further details can be
found in the Ace->error() error string.

=head2 rollback() method

    $object->rollback;

Discard all adds, deletions and replacements, returning the object to
the state it was in prior to the last commit().

rollback() works by deleting the object from Perl memory and fetching
the object anew from AceDB.  If someone has changed the object in the
database while you were working with it, you will see this version,
ot the one you originally fetched.

If you are creating an entirely new object, you I<must> add at least
one tag in order to enter the object into the database.

=head2 kill() method

    $result_code = $object->kill;

This will remove the object from the database immediately and
completely.  It does not wait for a commit(), and does not respond to
a rollback().  If successful, you will be left with an empty object
that contains just the class and object names.  Use with care!

In the case of failure, which commonly happens when the database is
not open for writing, this method will return undef.  A description of
the problem can be found by calling the error() method.

=head2 date_style() method

   $object->date_style('ace');

This is a convenience method that can be used to set the date format
for all objects returned by the database.  It is exactly equivalent to

   $object->db->date_style('ace');

Note that the text representation of the date will change for all
objects returned from this database, not just the current one.

=head2 isRoot() method

    print "Top level object" if $object->isRoot;

This method will return true if the object is a "top level" object,
that is the root of an object tree rather than a subtree.

=head2 model() method

    $model = $object->model;

This method will return the object's model as an Ace::Model object, or
undef if the object does not have a model. See L<Ace::Model> for
details.

=head2 timestamp() method

   $stamp = $object->timestamp;

The B<timestamp()> method will retrieve the modification time and date
from the object.  This works both with top level objects and with
subtrees.  Timestamp handling must be turned on in the database, or
B<timestamp()> will return undef.

The returned timestamp is actually a UserSession object which can be
printed and explored like any other object.  However, there is
currently no useful information in UserSession other than its name.

=head2 comment() method

   $comment = $object->comment;

This returns the comment attached to an object or object subtree, if
any.  Comments are I<Comment> objects and have the interesting
property that a single comment can refer to multiple objects.  If
there is no comment attached to the current subtree, this method will
return undef.

Currently you cannot create a new comment in AcePerl or edit an old
one.

=head2 error() method
    
    $error = $object->error;

Returns the error from the previous operation, if any.  As in
Ace::error(), this string will only have meaning if the previous
operation returned a result code indicating an error.

=head2 factory() method

WARNING - THIS IS DEFUNCT AND NO LONGER WORKS.  USE THE Ace->class() METHOD INSTEAD

    $package = $object->factory;

When a root Ace object instantiates its tree of tags and values, it
creates a hierarchical structure of Ace::Object objects.  The
factory() method determines what class to bless these subsidiary
objects into.  By default, they are Ace::Object objects, but you can
override this method in a child class in order to create more
specialized Ace::Object classes.  The method should return a string
corresponding to the package to bless the object into.  It receives
the current Ace::Object as its first argument.

=head2 debug() method

    $object->debug(1);

Change the debugging mode.  A zero turns off debugging messages.
Integer values produce debug messages on standard error.  Higher
integers produce progressively more verbose messages.  This actually
is just a front end to Ace->debug(), so the debugging level is global.

=head1 SEE ALSO

L<Ace>, L<Ace::Model>, L<Ace::Object>, L<Ace::Local>,
L<Ace::Sequence>,L<Ace::Sequence::Multi>

=head1 AUTHOR

Lincoln Stein <lstein@cshl.org> with extensive help from Jean
Thierry-Mieg <mieg@kaa.crbm.cnrs-mop.fr>

Copyright (c) 1997-1998, Lincoln D. Stein

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut


# AUTOLOADED METHODS GO HERE

### Return the pretty-printed HTML table representation ###
### may pass a code reference to add additional formatting to cells ###
sub asHTML {
    my $self = shift;
    my ($modify_code) = rearrange(['MODIFY'],@_);
    return unless defined($self->right);
    my $string = "<TABLE BORDER>\n<TR ALIGN=LEFT VALIGN=TOP><TH>$self</TH>";
    $modify_code = \&_default_makeHTML unless $modify_code;
    $self->right->_asHTML(\$string,1,2,$modify_code);
    $string .= "</TR>\n</TABLE>\n";
    return $string;
}

### Get the FASTA-format DNA/Peptide representation for this object ###
### (if appropriate) ###
sub asDNA {
  return shift()->_special_dump('dna');
}

sub asPeptide {
  return shift()->_special_dump('peptide');
}

sub _special_dump {
  my $self = shift;
  my $dump_format = shift;
  return unless $self->db->count($self->class,$self->name);
  my $result = $self->db->raw_query($dump_format);
  $result =~ s!^//.*!!ms;
  $result;
}

#### As tab-delimited table ####
sub asTable {
    my $self = shift;
    my $string = "$self\t";
    my $right = $self->right;
    $right->_asTable(\$string,1,2) if defined($right);
    return $string . "\n";
}

#### In "ace" format ####
sub asAce {
  my $self = shift;
  my $string = $self->isRoot ? join(' ',$self->class,':',$self->escape) . "\n" : '';
  $self->right->_asAce(\$string,0,[]);
  return "$string\n\n";
}

### Pretty-printed version ###
sub asString {
  my $self = shift;
  my $MAXWIDTH = shift || $DEFAULT_WIDTH;
  my $tabs = $self->asTable;
  return "$self" unless $tabs;
  my(@lines) = split("\n",$tabs);
  my($result,@max);
  foreach (@lines) {
    my(@fields) = split("\t");
    for (my $i=0;$i<@fields;$i++) {
      $max[$i] = length($fields[$i]) if
	!defined($max[$i]) or $max[$i] < length($fields[$i]);
    }
  }
  foreach (@max) { $_ = $MAXWIDTH if $_ > $MAXWIDTH; } # crunch long lines
  my $format1 = join(' ',map { "^"."<"x $max[$_] } (0..$#max)) . "\n";
  my $format2 =   ' ' . join('  ',map { "^"."<"x ($max[$_]-1) } (0..$#max)) . "~~\n";
  $^A = '';
  foreach (@lines) {
    my @data = split("\t");
    push(@data,('')x(@max-@data));
    formline ($format1,@data);
    formline ($format2,@data);
  }
  return ($result = $^A,$^A='')[0];
}

# run a series of GIF commands and return the Gif and the semi-parsed
# "boxes" structure.  Commands is typically a series of mouseclicks
# ($gif,$boxes) = $aceObject->asGif(-clicks=>[[$x1,$y1],[$x2,$y2]...],
#                                   -dimensions=>[$x,$y]);
sub asGif {
  my $self = shift;
  my ($clicks,$dimensions,$display,$view,$coords,$getcoords) = rearrange(['CLICKS',
									  ['DIMENSIONS','DIM'],
									  'DISPLAY',
									  'VIEW',
									  'COORDS',
									  'GETCOORDS',
									  ],@_);
  $display = "-D $display" if $display;
  $view    = "-view $view" if $view;
  my $c;
  if ($coords) {
    $c    =  ref($coords) ? "-coords @$coords" : "-coords $coords";
  }
  my @commands;
  if ($view || $c || $self->class =~ /Map/i) {
      @commands = "gif map \"@{[$self->name]}\" $view $c";
  } else {
      @commands = "gif display $display $view @{[$self->class]} \"@{[$self->name]}\"";
  }
  push(@commands,"Dimensions @$dimensions") if ref($dimensions);
  push(@commands,map { "mouseclick @{$_}" } @$clicks) if ref($clicks);

  if ($getcoords) { # just want the coordinates
    my ($start,$stop);
    my $data = $self->db->raw_query(join(' ; ',@commands));    
    return unless $data =~ /\"[^\"]+\" ([\d.-]+) ([\d.-]+)/;
    ($start,$stop) = ($1,$2);
    return ($start,$stop);
  }

  push(@commands,"gifdump -");

  # do the query
  my $data = $self->db->raw_query(join(' ; ',@commands));

  # A $' has been removed here to improve speed -- tim.cutts@incyte.com 2 Sep 1999

  # did this query succeed?
  my ($bytes, $trim);
  return unless ($bytes, $trim) = $data=~m!^// (\d+) bytes\n\0*(.+)!sm;

  my $gif = substr($trim,0,$bytes);

  # now process the boxes
  my @b;
  my @boxes = split("\n",substr($trim,$bytes));
  foreach (@boxes) {
    last if m!^//!;
    chomp;
    my ($left,$top,$right,$bottom,$class,$name,$comments) = 
      m/^\s*\d*\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\w+):"(.+)"\s*(.*)/;
    next unless defined $left;
    $comments=~s/\s+$//; # sometimes there's extra white space at the end
    my $box = {'coordinates'=>[$left,$top,$right,$bottom],
	       'class'=>$class,
	       'name' =>$name,
	       'comment'=>$comments};
    push (@b,$box);
  }
  return ($gif,\@b);
}

############## timestamp and comment information ############
sub timestamp {
    my $self = shift;
    return $self->{'.timestamp'} = $_[0] if defined $_[0];
    if ($self->db && !$self->{'.timestamp'}) {
      $self->_fill;
      $self->_parse;
    }
    return $self->{'.timestamp'} if $self->{'.timestamp'};
    return unless defined $self->right;
    return $self->{'.timestamp'} = $self->right->timestamp;
}

sub comment {
    my $self = shift;
    return $self->{'.comment'} = $_[0] if defined $_[0];
    if ($self->db && !$self->{'.comment'}) {
      $self->_fill;
      $self->_parse;
    }
    return $self->{'.comment'};
}

### Return list of all the tags in the object ###
sub tags {
    my $self = shift;
    my $current = $self->right;
    my @tags;
    while (defined($current)) {
	push(@tags,$current);
	$current = $current->down;
    }
    return @tags;
}

################# kill an object ################
# Removes the object from the database immediately.
sub kill {
  my $self = shift;
  return unless my $db = $self->db;
  return 1 unless $db->count($self->class,$self->name);
  my $result = $db->raw_query("kill");
  if (defined($result) and $result=~/write access/im) {  # this keeps changing
    $Ace::Error = "Write access denied";
    return;
  }
  # uncache cached values and clear the object out
  # as best we can
  delete @{$self}{qw[.PATHS .right .raw .down]};
  1;
}

# sub isTimestamp {
#   my $self = shift;
#   return 1 if $self->class eq 'UserSession';
#   return;
# }

sub isComment {
  my $self = shift;
  return 1 if $self->class eq 'Comment';
  return;
}

################# add a new row #############
#  Only changes local copy until you perform commit() #
#  returns true if this is a valid thing to do #
sub add_row {
  my $self = shift;
  my($tag,@newvalue) = rearrange([['TAG','PATH'],'VALUE'],@_);

  # flatten array refs into array
  my @values = map { ref($_) && ref($_) eq 'ARRAY' ? @$_ : $_ } @newvalue;

  # make sure that this entry doesn't already exist
  unless ($tag =~ /\./) {
    my $model = $self->model;
    my @intermediate_tags = $model->path($tag);
    $tag = join '.',@intermediate_tags,$tag;
  }
  my $row = join(".",($tag,map { (my $x = $_) =~s/\./\\./g; $x } @values));
  return if $self->at($row);  # an identical row already exists in the object

  # If we get here then we need to turn @values into an array of Ace::Objects
  # for insertion.  Also need to link them together into a row.
  my $previous;
  foreach (@values) {
    if (ref($_) && $_->isa('Ace::Object')) {
      $_ = $_->_clone;
    } else {
      $_ = $self->new('scalar',$_);
    }
    $previous->{'.right'} = $_ if defined $previous;
    $previous = $_;
    $_->{'.right'} = undef; # make sure it doesn't automatically expand!
  }

  # position at the indicated tag (creating it if necessary)
  my (@tags) = $self->_split_tags($tag);
  my $p = $self;
  foreach (@tags) {
    $p = $p->_insert($_);
  }
  if ($p->{'.right'}) {
    $p = $p->{'.right'};
    while (1) { 
      last unless $p->{'.down'};
      $p = $p->{'.down'};
    }
    $p->{'.down'} = $values[0];
  } else {
    $p->{'.right'} = $values[0];
  }

  push(@{$self->{'.update'}},join(' ',map { Ace->freeprotect($_) } (@tags,@values)));
  delete $self->{'.PATHS'}; # uncache cached values
  $self->_dirty(1);
  1;
}

# Use this method to add an entire subobject to the right of the tag.
# The tree may come from another database.
sub add_tree {
  my $self = shift;
  my($tag,$value,@rest) = rearrange([['TAG','PATH'],['VALUE','TREE']],@_);
  croak "Value must be an Ace::Object" unless ref($value) && $value->isa('Ace::Object');

  unless ($tag =~ /\./) {
    my $model = $self->model;
    my @intermediate_tags = $model->path($tag);
    $tag = join '.',@intermediate_tags,$tag;
  }

  # position at the indicated tag, creating it if necessary
  my (@tags) = $self->_split_tags($tag);
  my $p = $self;
  foreach (@tags) {
    $p = $p->_insert($_);
  }
  # Copy the subtree too
  if ($p->{'.right'}) {
    $p = $p->{'.right'};
    while (1) { 
      last unless $p->{'.down'};
      $p = $p->{'.down'};
    }
    $p->{'.down'} = $value->{'.right'};
  } else {
    $p->{'.right'} = $value->{'.right'};
  }
  push(@{$self->{'.update'}},map { join(' ',@tags,$_) } split("\n",$value->asAce));
  delete $self->{'.PATHS'}; # uncache cached values
  $self->_dirty(1);
  1;
}

################# delete a portion of the tree #############
# Only changes local copy until you perform commit() #
#  returns true if this is a valid thing to do.
sub delete {
  my $self = shift;
  my($tag,$oldvalue,@rest) = rearrange([['TAG','PATH'],['VALUE','OLDVALUE','OLD']],@_);

  # flatten array refs into array
  my @values;
  @values = map { ref($_) && ref($_) eq 'ARRAY' ? @$_ : $_ } ($oldvalue,@rest) 
    if defined($oldvalue);

  unless ($tag =~ /\./) {
    my $model = $self->model;
    my @intermediate_tags = $model->path($tag);
    $tag = join '.',@intermediate_tags,$tag;
  }

  my $row = join(".",($tag,map { (my $x = $_) =~s/\./\\./g; $x } @values));
  my $subtree = $self->at($row,undef,1);  # returns the parent

  if (@values
      && defined($subtree->{'.right'})
      && "$subtree->{'.right'}" eq $oldvalue) {
    $subtree->{'.right'} = $subtree->{'.right'}->down;
  } else {
    $subtree->{'.down'} = $subtree->{'.down'}->{'.down'}
  }

  push(@{$self->{'.update'}},join(' ','-D',
				 map { Ace->freeprotect($_) } ($self->_split_tags($tag),@values)));
  delete $self->{'.PATHS'}; # uncache cached values
  $self->_dirty(0);
  $self->db->file_cache_delete($self);
  1;
}


################# delete a portion of the tree #############
# Only changes local copy until you perform commit() #
#  returns true if this is a valid thing to do #
sub replace {
  my $self = shift;
  my($tag,$oldvalue,$newvalue,@rest) = rearrange([['TAG','PATH'],
						  ['OLDVALUE','OLD'],
						  ['NEWVALUE','NEW']],@_);
    $self->delete($tag,$oldvalue);
    $self->add($tag,$newvalue,@rest);
    delete $self->{'.PATHS'}; # uncache cached values
    1;
}

# commit changes from local copy to database copy
sub commit {
  my $self = shift;
  return unless my $db = $self->db;
  
  my ($retval,@cmd);
  my $name = $self->{'name'};
  return unless defined $name;
  
  $name =~ s/([^a-zA-Z0-9_-])/\\$1/g;
  return 1 unless exists $self->{'.update'} && $self->{'.update'};

  $Ace::Error = '';
  my $result = '';

  # bad design alert: the following breaks encapsulation
  if ($db->db->can('write')) { # new way for socket server
    my $cmd = join "\n","$self->{'class'} : $name",@{$self->{'.update'}};
    warn $cmd if $self->debug;
    $result = $db->raw_query($cmd,0,'parse');  # sets Ace::Error for us
  } else {   # old way for RPC server and local
    my $cmd = join('; ',"$self->{'class'} : $name",
		   @{$self->{'.update'}});
    warn $cmd if $self->debug;
    $result = $db->raw_query("parse = $cmd");
  }

  if (defined($result) and $result=~/write( or admin)? access/im) {  # this keeps changing
    $Ace::Error = "Write access denied";
  } elsif (defined($result) and $result =~ /sorry|parse error/mi) {
    $Ace::Error = $result;
  }
  return if $Ace::Error;
  undef $self->{'.update'};
  # this will force a fresh retrieval of the object
  # and synchronize our in-memory copy with the db
  delete $self->{'.right'};
  delete $self->{'.PATHS'};
  return 1;
}

# undo changes
sub rollback {
    my $self = shift;
    undef $self->{'.update'};
    # this will force object to be reloaded from database
    # next time it is needed.
    delete $self->{'.right'};
    delete $self->{'.PATHS'};
    1;
}

sub debug {
    my $self = shift;
    Ace->debug(@_);
}

### Get or set the date style (actually calls through to the database object) ###
sub date_style {
  my $self = shift;
  return unless $self->db;
  return $self->db->date_style(@_);
}

sub _asHTML {
  my($self,$out,$position,$level,$morph_code) = @_;
  do {
    $$out .= "<TR ALIGN=LEFT VALIGN=TOP>" unless $position;
    $$out .= "<TD></TD>" x ($level-$position-1);
    my ($cell,$prune,$did_it_myself) = $morph_code->($self);
    $$out .= $did_it_myself ? $cell : "<TD>$cell</TD>";
    if ($self->comment) {
      my ($cell,$p,$d) = $morph_code->($self->comment);
      $$out .= $d ? $cell : "<TD>$cell</TD>";
      $$out .= "</TR>\n" . "<TD></TD>" x $level unless $self->down && !defined($self->right);
    }
    $level = $self->right->_asHTML($out,$level,$level+1,$morph_code) if defined($self->right) && !$prune;
    $$out .= "</TR>\n" if defined($self = $self->down);
    $position = 0;
  } while defined $self;
  return --$level;
}


# This function is overly long because it is optimized to prevent parsing
# parts of the tree that haven't previously been parsed.
sub _asTable {
    my($self,$out,$position,$level) = @_;
    do {
      if ($self->{'.raw'}) {  # we still have raw data, so we can optimize
	my ($a,$start,$end) = @{$self}{ qw(.col .start_row .end_row) };
	my @to_append = map { join("\t",@{$_}[$a..$#{$_}]) } @{$self->{'.raw'}}[$start..$end];
	my $new_row;
	foreach (@to_append) {
	  # hack alert
	  s/(\?.*?[^\\]\?.*?[^\\]\?)\S*/$self->_ace_format(Ace->split($1))/eg;
	  if ($new_row++) {
	    $$out .= "\n";
	    $$out .= "\t" x ($level-1) 
	  }
	  $$out .= $_;
	}
	return $level-1;
      }

      $$out .= "\t" x ($level-$position-1);
      $$out .= $self->name . "\t";
      if ($self->comment) {
	$$out .= $self->comment;
	$$out .= "\n" . "\t" x $level unless $self->down && !defined($self->right);
      }
      $level = $self->right->_asTable($out,$level,$level+1)
	if defined $self->right;
      $$out .= "\n" if defined($self = $self->down);
      $position = 0;
    } while defined $self;
    return --$level;
}

# This is the default code that will be called during construction of
# the HTML table.  It returns a two-member list consisting of the modified
# entry and (optionally) a true value if we are to prune here.  The returned string
# will be placed inside a <TD></TD> tag.  There's nothing you can do about that.
sub _default_makeHTML {
  my $self = shift;
  my ($string,$prune) = ("$self",0);
  return ($string,$prune) unless $self->isObject || $self->isTag;

  if ($self->isTag) {
    $string = "<B>$self</B>";
  } elsif ($self->isComment) {
    $string = "<I>$self</I>";
  }  else {
    $string = qq{<FONT COLOR="blue">$self</FONT>} ;
  }
  return ($string,$prune);
}

# Insert a new tag or value.
# Local only. Will not affect the database.
# Returns the inserted tag, or the preexisting
# tag, if already there.
sub _insert {
    my ($self,$tag) = @_;
    my $p = $self->{'.right'};
    return $self->{'.right'} = $self->new('tag',$tag)
	unless $p;
    while ($p) {
	return $p if "$p" eq $tag;
	last unless $p->{'.down'};
	$p = $p->{'.down'};
    }
    # if we get here, then we didn't find it, so
    # insert at the bottom
    return $p->{'.down'} = $self->new('tag',$tag);
}

# This is unsatisfactory because it duplicates much of the code
# of asTable.
sub _asAce {
  my($self,$out,$level,$tags) = @_;

  # ugly optimization for speed
  if ($self->{'.raw'}){
    my ($a,$start,$end) = @{$self}{qw(.col .start_row .end_row)};
    my (@last);
    foreach (@{$self->{'.raw'}}[$start..$end]){
      my $j=1;
      $$out .= join("\t",@$tags) . "\t" if ($level==0) && (@$tags);
      my (@to_modify) = @{$_}[$a..$#{$_}];
      foreach (@to_modify) {
	my ($class,$name) =Ace->split($_);
	if (defined($name)) {
	  $name = $self->_ace_format($class,$name);
	  if (_isObject($class) || $name=~/[^\w.-]/) {
	    $name=~s/"/\\"/g; #escape quotes with slashes
	    $name = qq/\"$name\"/;
	  } 
	} else {
	  $name = $last[$j] if $name eq '';
	}
	$_ = $last[$j++] = $name;  
	$$out .= "$_\t";
      }
      $$out .= "\n";
      $level = 0;
    }
    chop($$out);
    return;
  }
  
  $$out .= join("\t",@$tags) . "\t" if ($level==0) && (@$tags);
  $$out .= $self->escape . "\t";
  if (defined $self->right) {
    push(@$tags,$self->escape);
    $self->right->_asAce($out,$level+1,$tags);
    pop(@$tags);
  }
  if ($self->down) {
    $$out .= "\n";
    $self->down->_asAce($out,0,$tags);
  }
}

sub _to_ace_date {
  my $self = shift;
  my $string = shift;
  return $string unless lc($self->date_style) eq 'ace';
  %MO = (Jan=>1,Feb=>2,Mar=>3,
	 Apr=>4,May=>5,Jun=>6,
	 Jul=>7,Aug=>8,Sep=>9,
	 Oct=>10,Nov=>11,Dec=>12) unless %MO;
  my ($day,$mo,$yr) = split(" ",$string);
  return "$yr-$MO{$mo}-$day";
}

### Return an XML syntax representation  ###
### Consider this feature experimental   ###
sub asXML {
    my $self = shift;
    return unless defined($self->right);

    my ($do_content,$do_class,$do_value,$do_timestamps) = rearrange([qw(CONTENT CLASS VALUE TIMESTAMPS)],@_);
    $do_content    = 0 unless defined $do_content;
    $do_class      = 1 unless defined $do_class;
    $do_value      = 1 unless defined $do_value;
    $do_timestamps = 1 unless (defined $do_timestamps && !$do_timestamps) || !$self->db->timestamps;
    my %options = (content    => $do_content,
		   class      => $do_class,
		   value      => $do_value,
		   timestamps => $do_timestamps);
    my $name = $self->escapeXML($self->name);
    my $class = $self->class;
    my $string = '';
    $self->_asXML(\$string,0,0,'',0,\%options);
    return $string;
}

sub _asXML {
  my($self,$out,$position,$level,$current_tag,$tag_level,$opts) = @_;

  do {
    my $name = $self->escapeXML($self->name);
    my $class = $self->class;
    my ($tagname,$attributes,$content) = ('','',''); # prevent uninitialized variable warnings
    my $tab = "    " x ($level-$position); # four spaces
    $current_tag ||= $class;
    $content = $name if $opts->{content};

    if ($self->isTag) {
      $current_tag = $tagname = $name;
      $tag_level = 0;
    } else {
      $tagname = $tag_level > 0 ? sprintf "%s-%d",$current_tag,$tag_level + 1 : $current_tag;
      $class = "#$class" unless $self->isObject;
      $attributes .= qq( class="$class") if $opts->{class};
      $attributes .= qq( value="$name")  if $opts->{value};
    }

    if (my $c = $self->comment) {
      $c = $self->escapeXML($c);
      $attributes .= qq( comment="$c");
    }

    if ($opts->{timestamps} && (my $timestamp = $self->timestamp)) {
      $timestamp = $self->escapeXML($timestamp);
      $attributes .= qq( timestamp="$timestamp");
    }

    $tagname = $self->_xmlNumber($tagname) if $tagname =~ /^\d/;
    
    unless (defined $self->right) { # lone tag
      $$out .= $self->isTag || !$opts->{content} ? qq($tab<$tagname$attributes />\n) 
	                                         : qq($tab<$tagname$attributes>$content</$tagname>\n);
    } elsif ($self->isTag) { # most tags are implicit in the XML tag names
      if (!XML_COLLAPSE_TAGS or $self->right->isTag) {
	$$out .= qq($tab<$tagname$attributes>\n);
	$level = $self->right->_asXML($out,$position,$level+1,$current_tag,$tag_level + !XML_COLLAPSE_TAGS,$opts);
	$$out .= qq($tab</$tagname>\n);
      } else {
	$level = $self->right->_asXML($out,$position+1,$level+1,$current_tag,$tag_level,$opts);
      }
    } else {
      $$out .=  qq($tab<$tagname$attributes>$content\n);
      $level = $self->right->_asXML($out,$position,$level+1,$current_tag,$tag_level+1,$opts);
      $$out  .= qq($tab</$tagname>\n);
    }

    $self = $self->down;
  } while defined $self;

  return --$level;
}

sub escapeXML {
  my ($self,$string) = @_;
  $string =~ s/&/&amp;/g;
  $string =~ s/\"/&quot;/g;
  $string =~ s/</&lt;/g;
  $string =~ s/>/&gt;/g;
  return $string;
}

sub _xmlNumber {
  my $self = shift;
  my $tag  = shift;
  $tag =~ s/^(\d)/
        $1 eq '0' ? 'zero'
      : $1 eq '1' ? 'one'
      : $1 eq '2' ? 'two'
      : $1 eq '3' ? 'three'
      : $1 eq '4' ? 'four'
      : $1 eq '5' ? 'five'
      : $1 eq '6' ? 'six'
      : $1 eq '7' ? 'seven'
      : $1 eq '8' ? 'eight'
      : $1 eq '9' ? 'nine'
      : $1/ex;
  $tag;
}
