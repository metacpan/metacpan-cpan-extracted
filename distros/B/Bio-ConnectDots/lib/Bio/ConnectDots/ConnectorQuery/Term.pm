package Bio::ConnectDots::ConnectorQuery::Term;
use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS %DEFAULTS);
use strict;
use Class::AutoClass;
use Bio::ConnectDots::Util;
@ISA = qw(Class::AutoClass);

@AUTO_ATTRIBUTES=qw(ct_alias column cs_alias labels label_ids termlist);
%SYNONYMS=();
@OTHER_ATTRIBUTES=qw();
%DEFAULTS=(termlist=>[]);
Class::AutoClass::declare(__PACKAGE__);

sub _init_self {
  my($self,$class,$args)=@_;
  return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
}

sub alias {			# returns either ct or cs alias, whichever is set
  my($self)=@_;
  my $ct_alias=$self->ct_alias;
  return $ct_alias if $ct_alias;
  my $cs_alias=$self->cs_alias;
  return $cs_alias if $cs_alias;
  undef;
}
# Be careful with the following delegated accessors: not valid until validation time
sub ct {
  my($self)=@_;
  my $ct_alias=$self->ct_alias;
  $ct_alias? $ct_alias->target_object: undef;
}
sub cs {
  my($self)=@_;
  my $ct=$self->ct;
  return $ct->column2cs->{$self->column} if $ct;
  my $cs_alias=$self->cs_alias;
#  my $version=
  return $cs_alias->target_object if $cs_alias;
  $self->throw("Malformed Term object".value_as_string($self).": Should have been caught ealier!");
}
sub ct_name {my $ct=$_[0]->ct; $ct? $ct->name: undef;}
sub ct_id {my $ct=$_[0]->ct; $ct? $ct->db_id: undef;}
sub cs_id {$_[0]->cs->db_id;}
sub cs_name {$_[0]->cs->name;}
sub alias_name {$_[0]->alias->alias_name;}
sub label2labelid {$_[0]->cs->label2labelid;}

sub normalize {
  my($self)=@_;
  my $termlist=$self->termlist;
  my($ct_alias,$column,$cs_alias,$labels)=$self->get(qw(ct_alias column cs_alias labels));
  # set components if unset, or check for equality
  if (@$termlist==3) {
    my $i=0;
    $self->throw("termlist and ct_alias are inconsistent: \$termlist=".$termlist->[$i].
		 ", \$ct_alias=$ct_alias") 
      if defined $ct_alias && $termlist->[$i++] ne $ct_alias;
    $self->throw("termlist and column are inconsistent: \$termlist=".$termlist->[$i].
		 ", \$column=$column") 
      if defined $column && $termlist->[$i++] ne $column;
    $self->throw("termlist and labels are inconsistent: \$termlist=".$termlist->[$i].
		 ", \$labels=$labels") 
      if defined $labels && $termlist->[$i++] ne $labels;
    my $i=0;
    defined $ct_alias or $self->ct_alias($termlist->[$i++]);
    defined $column or $self->column($termlist->[$i++]);
    defined $labels or $self->labels($termlist->[$i++]);
  } elsif (@$termlist==2) {		# cs_alias.labels
    my $i=0;
    $self->throw("termlist and cs_alias are inconsistent: \$termlist=".$termlist->[$i].
		 ", \$cs_alias=$cs_alias") 
      if defined $cs_alias && $termlist->[$i++] ne $cs_alias;
    $self->throw("termlist and labels are inconsistent: \$termlist=".$termlist->[$i].
		 ", \$labels=$labels") 
      if defined $labels && $termlist->[$i++] ne $labels;
    my $i=0;
    defined $cs_alias or $self->cs_alias($termlist->[$i++]);
    defined $labels or $self->labels($termlist->[$i++]);
  } elsif (@$termlist==1) {		# cs_alias.<labels=cs_alias>
    $self->throw("termlist and cs_alias are inconsistent: \$termlist=".$termlist->[0].
		 ", \$cs_alias=$cs_alias") 
      if defined $cs_alias && $termlist->[0] ne $cs_alias;
    $self->throw("termlist and labels are inconsistent: \$termlist=".$termlist->[0].
		 ", \$labels=$labels") 
      if defined $labels && $termlist->[0] ne $labels;
    defined $cs_alias or $self->cs_alias($termlist->[0]);
    defined $labels or $self->labels($termlist->[0]);
  } elsif (@$termlist>3) {
    $self->throw("Invalid termlist ".value_as_string($termlist).
		 ": must have 0-3 elements, not ".(@$termlist+0));
  }
  $self->throw("Invalid term ".$self->as_string.
	       ": must have ct_alias, column, and labels or cs_alias and labels") 
    unless ((($self->ct_alias && $self->column) || $self->cs_alias) && $self->labels && 
	    !($self->column && $self->cs_alias));
  $self->throw("Invalid term ".$self->as_string.": * can only appear as labels")
    if grep /\*/, ($self->ct_alias,$self->cs_alias);
  $self->throw("Invalid term ".$self->as_string.": lists can only appear as labels")
    if grep {'ARRAY' eq ref $_} ($self->ct_alias,$self->cs_alias);

  $labels=$self->labels;
  $self->throw("Invalid term ".$self->as_string.": no label!")
    if !$labels || ('ARRAY' eq ref $labels && !@$labels);
  $self->throw("Invalid term ".$self->as_string.": nested label lists are not supported")
    if 'ARRAY' eq ref $labels && grep {'ARRAY' eq ref $_} @$labels;

  $labels=[] if $labels eq '*';	# empty labels list means '*' hereafter
  $self->labels('ARRAY' eq ref $labels? $labels: [$labels]);
  $self->termlist([grep {defined $_} $self->get(qw(ct_alias column cs_alias labels))]);
  $self;
}

# replace alias names with Alias objects
# check column and lookup ConnectorSet
# check labels and lookup labelids
sub validate {
  my($self,$name2ct_alias,$name2cs_alias)=@_;
  my($ct_alias,$column,$cs_alias,$labels)=$self->get(qw(ct_alias column cs_alias labels));
  $self->ct_alias($name2ct_alias->{$ct_alias}) if $ct_alias;
  $self->cs_alias($name2cs_alias->{$cs_alias}) if $cs_alias;
  my $cs=$self->cs;		# DO NOT MOVE UP: cs method not valid until now!
  $self->throw("Invalid column ".$column." for ConntectorTable ".$self->ct_alias->target_name)
    if $ct_alias && !$cs;
  
  my $label_ids=[];
  my $label2labelid=$self->label2labelid;
  for my $label (@$labels) {
    my $label_id=$label2labelid->{$label};
    $self->throw("Invalid label $label for ConnectorSet ".$self->cs_name) unless $label_id;
    push(@$label_ids,$label_id);
  } 
  $self->label_ids($label_ids);
  $self;
}

sub as_string {
  my($self)=@_;
  join('.',map {value_as_string($_)} @{$self->termlist});
}

1;

