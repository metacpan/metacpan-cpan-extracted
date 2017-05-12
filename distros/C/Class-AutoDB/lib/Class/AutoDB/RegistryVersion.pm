package Class::AutoDB::RegistryVersion;
use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS %DEFAULTS);
use strict;
# use Data::Dumper;
use Storable qw(dclone);
use Class::AutoClass;
# use Hash::AutoHash::Args;
use Class::AutoDB::Registration;
use Class::AutoDB::Collection;
@ISA = qw(Class::AutoClass);

# The guts of the Registry implementation.  Each Registry has two of these.
# RegistryVersion does not inherit from Serialize!!
# Instead, the versions are serialized as part of the overall registry.

@AUTO_ATTRIBUTES=qw(registry name2coll class2collnames _class2transients);
@OTHER_ATTRIBUTES=qw();
%SYNONYMS=();
%DEFAULTS=(name2coll=>{},class2collnames=>{},_class2transients=>{});
Class::AutoClass::declare(__PACKAGE__);

# NG 09-03-19: commented out _init_self -- stub not needed
# sub _init_self {
#   my($self,$class,$args)=@_;
#   return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
# }

# NG 11-01-07: added copy. needed to enable runtime schema changes
#              deep copies state, except for 'registry'
sub copy {
  my $self=shift;
  my $copy=new Class::AutoDB::RegistryVersion registry=>$self->registry;
  while(my($key,$value)=each %$self) {
    next if $key eq 'registry';
    $value=dclone($value);
    $copy->{$key}=$value;
  }
  $copy;
}

sub register {
  my $self=shift;
  my $registration=new Class::AutoDB::Registration(@_);
  my $name2coll=$self->name2coll || $self->name2coll({});
  # NG 09-11-12: AutoClass no longer defines class
  # NG 09-11-17: However, Registration does define class !!
  my $class=$registration->class;
  # my $class=ref $registration;
  my $collnames=$registration->collnames;
  my $transients=$registration->transients;
  if ($class) {
    my $class2collnames=$self->class2collnames || $self->class2collnames({});
    my $class2transients=$self->_class2transients || $self->_class2transients({});
    my $class_collnames=$class2collnames->{$class} || ($class2collnames->{$class}=[]);
    my $class_transients=$class2transients->{$class} || ($class2transients->{$class}=[]);
    push(@$class_collnames,@$collnames);
    push(@$class_transients,@$transients);
    for my $super ($class->ISA) {	# add in collections from superclasses. 
                                        # recursively, this includes all ancestors
      next unless UNIVERSAL::isa($super,'Class::AutoDB::Object');
      my $super_collnames=$class2collnames->{$super} || [];
      push(@$class_collnames,@$super_collnames);
      my $super_transients=$class2transients->{$super} || [];
      push(@$class_transients,@$super_transients);
    }
    # uniqify the names
    my %h; @h{@$class_collnames}=@$class_collnames; @$class_collnames=values %h;
           @h{@$class_transients}=@$class_transients; @$class_transients=values %h; # DM removed my %h
  }
  my %collname2keys=%{$registration->collections};
  while(my($collname,$keys)=each %collname2keys) {
    my $collection=$name2coll->{$collname} || 
      ($name2coll->{$collname}=new Class::AutoDB::Collection(-name=>$collname));
    $collection->register($keys);
  }
  $registration;
}
sub collections {
  my $self=shift;
  my $name2coll=$self->name2coll || $self->name2coll({});
  wantarray? values %$name2coll: [values %$name2coll];
}
sub collection {
  my $self=shift;
  my $name=!ref $_[0]? $_[0]: $_[0]->name;
  my $name2coll=$self->name2coll || $self->name2coll({});
  $name2coll->{$name};
}
sub class2collections {
  my($self,$class)=@_;
  # NG 11-01-05: make sure class already used, else class2collections not set
  #              code adapted from Oid::AUTOLOAD
  {no strict 'refs';
   unless (${$class.'::'}{AUTODB}) {
     eval "require $class" or die $@;
   }}
  my $collnames=$self->class2collnames->{$class} || [];
  my @collections=map {$self->collection($_)} @$collnames;
  wantarray? @collections: \@collections;
}
sub class2transients {
  my($self,$class)=@_;
  my $transients=$self->_class2transients->{$class} || [];
  wantarray? @$transients: $transients;
}
sub merge {
  my($self,$diff)=@_;
  my $name2coll=$self->name2coll || $self->name2coll({});
  my $new_collections=$diff->new_collections;
  for my $collection (@$new_collections) {
    my $name=$collection->name;
    $name2coll->{$name}=$collection; # easy case -- just add to registry
  }
  my $expanded_diffs=$diff->expanded_diffs;
  for my $diff (@$expanded_diffs) {
    my $collection=$diff->baseline;
    $collection->merge($diff);
  }
  # class2colls -- assume all changes are expansions of one sort or another
  my $class2collnames={};
  my $baseline_class2collnames=$self->class2collnames;
  # init to baseline
  @$class2collnames{keys %$baseline_class2collnames}=values %$baseline_class2collnames;
  my $other_class2collnames=$diff->other->class2collnames;
  while(my($class,$other_collnames)=each %$other_class2collnames) {
    my $baseline_collnames=$baseline_class2collnames->{$class} || [];
    my $collnames=uniq($baseline_collnames,$other_collnames); # combine and uniqify the names
    $class2collnames->{$class}=$collnames;
  }
  $self->class2collnames($class2collnames);
}
sub _flatten {map {'ARRAY' eq ref $_? @$_: $_} @_;}

# combine and uniquify two lists
sub uniq {
  my($list1,$list2)=@_;
  my %hash;
  @hash{@$list1}=@$list1 if $list1;
  @hash{@$list2}=@$list2 if $list2;
  [values %hash];
}

1;
