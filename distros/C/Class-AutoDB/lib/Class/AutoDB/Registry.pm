package Class::AutoDB::Registry;
use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS %DEFAULTS);
use strict;
use Text::Abbrev;
use Class::AutoClass;
# use Hash::AutoHash::Args;
use Class::AutoDB::RegistryVersion;
use Class::AutoDB::RegistryDiff;
use Class::AutoDB::Registration;
use Class::AutoDB::Collection;
use Class::AutoDB::Serialize;
@ISA = qw(Class::AutoClass Class::AutoDB::Serialize);

# NG 09-12-19: changes for cleanup of user-object namespace
my $GLOBALS=Class::AutoDB::Globals->instance();
my $REGISTRY_OID=$GLOBALS->registry_oid;

# NG 11-01-07: name2coll seems to be unused. all 'coll' methods delegate to current
# @AUTO_ATTRIBUTES=qw(autodb name2coll current saved diff);
@AUTO_ATTRIBUTES=qw(autodb current saved diff);
@OTHER_ATTRIBUTES=qw(oid);
%SYNONYMS=();
%DEFAULTS=();
Class::AutoClass::declare(__PACKAGE__);

sub _init_self {
  my($self,$class,$args)=@_;
  return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
  $self->get;			# get or initialize saved version. also inits current version
}
sub oid {$REGISTRY_OID}		# do it this way so oid is set when Serialize
                                # constructor called
sub register {
  my $self=shift;
  $self->current->register(@_);
}
sub collections {
  my $self=shift;
  $self->current->collections;
}
sub collection {
  my $self=shift;
  $self->current->collection(@_);
}
sub class2collections {
  my $self=shift;
  $self->current->class2collections(@_);
}
sub class2transients {
  my $self=shift;
  $self->current->class2transients(@_);
}

sub merge {
  my($self)=@_;
  my $current=$self->current;
  my $saved=$self->saved;
  my $diff=new Class::AutoDB::RegistryDiff(-baseline=>$saved,-other=>$current);
  $self->diff($diff);		# hang onto this since it's expensive to compute
  $saved->merge($diff);
}

my @WHATS=qw(create drop alter);
my %WHATS=abbrev @WHATS;

sub schema {
  my($self,$what,$index_flag)=@_;
  $what or $what='create';
  $index_flag = defined $index_flag ? $index_flag : 1; # indexing is default operation
  $what=$WHATS{lc($what)} || $self->throw("Invalid \$what for schema: $what. Should be one of: @WHATS");
  my @sql;
  if ($what eq 'create') {	# create current collections
    push(@sql,map {$_->drop} $self->saved->collections); # drop existing collections first
    push(@sql,map {$_->create($index_flag)} $self->current->collections); # then create new ones
  } elsif ($what eq 'drop') {	# drop current & saved collections
    push(@sql,map {$_->drop} $self->saved->collections);
    push(@sql,map {$_->drop} $self->current->collections);
  } else {			# it's alter
    my $diff=$self->diff;
    my $new_collections=$diff->new_collections;
    push(@sql,map {$_->create} @$new_collections);
    my $expanded=$diff->expanded_diffs;
    for my $diff (@$expanded) {
      my $collection=$diff->other;
      push(@sql,$collection->alter($diff));
    }
  }
  wantarray? @sql: \@sql;
}
sub get {			# retrieve saved registry
  my($self)=@_;
  # save transient state across fetch
  my $autodb=$self->autodb;
  my $current=$self->current;
  # !! fetch overwrites entire object !!
  Class::AutoDB::Serialize::really_fetch($REGISTRY_OID,$self) if $autodb && $autodb->exists;
  # initialize saved if necessary
  $self->saved or $self->saved(new Class::AutoDB::RegistryVersion(-registry=>$self));
  # restore transient state. initialize current if necessary
  $self->autodb($autodb);
  $self->current($current || new Class::AutoDB::RegistryVersion(-registry=>$self));
}
sub put {			# store saved registry
  my($self)=@_;
  # save and clear transient state. TODO: use 'transients' when implemented
  my $autodb=$self->autodb;
  my $current=$self->current;
  my $diff=$self->diff;
  $self->autodb(undef);
  $self->current(undef);
  $self->diff(undef);
  $self->store;			# Class::AutoDB::Serialize::store
  # restore transient state
  $self->autodb($autodb);
  $self->current($current);
  $self->diff($diff);
}

sub _flatten {map {'ARRAY' eq ref $_? @$_: $_} @_;}

1;
