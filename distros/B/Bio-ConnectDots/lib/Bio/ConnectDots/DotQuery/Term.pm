package Bio::ConnectDots::DotQuery::Term;
use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS %DEFAULTS);
use strict;
use Class::AutoClass;
use Bio::ConnectDots::Util;
@ISA = qw(Class::AutoClass);

@AUTO_ATTRIBUTES=qw(column cs labels label_ids termlist);
%SYNONYMS=();
@OTHER_ATTRIBUTES=qw();
%DEFAULTS=(termlist=>[]);
Class::AutoClass::declare(__PACKAGE__);

sub _init_self {
  my($self,$class,$args)=@_;
  return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
}

# Be careful with the following delegated accessors: not valid until validation time
sub cs_id {$_[0]->cs->db_id;}
sub cs_name {$_[0]->cs->name;}

sub normalize {
  my($self)=@_;
  my $termlist=$self->termlist;
  my($column,$cs,$labels)=$self->get(qw(column cs labels));
  # set components if unset, or check for equality
  if (@$termlist==2) {		# column.labels
    my $i=0;
    $self->throw("termlist and column are inconsistent: \$termlist=".$termlist->[$i].
		 ", \$column=$column") 
      if defined $column && $termlist->[$i++] ne $column;
    $self->throw("termlist and labels are inconsistent: \$termlist=".$termlist->[$i].
		 ", \$labels=$labels") 
      if defined $labels && $termlist->[$i++] ne $labels;
    my $i=0;
    defined $column or $self->column($termlist->[$i++]);
    defined $labels or $self->labels($termlist->[$i++]);
  }  elsif (@$termlist==1) {		# labels
    $self->throw("termlist and labels are inconsistent: \$termlist=".$termlist->[0].
		 ", \$labels=$labels") 
      if defined $labels && $termlist->[0] ne $labels;
    defined $labels or $self->labels($termlist->[0]);
  } elsif (@$termlist>2) {
    $self->throw("Invalid termlist ".value_as_string($termlist).
		 ": must have 0-2 elements, not ".(@$termlist+0));
  }
  $self->throw("Invalid term ".$self->as_string.": * can only appear as labels")
    if '*' eq $self->column;
  $self->throw("Invalid term ".$self->as_string.": lists can only appear as labels")
    if 'ARRAY' eq ref $self->column;

  $labels=$self->labels;
  $self->throw("Invalid term ".$self->as_string.": no label!")
    if !$labels || ('ARRAY' eq ref $labels && !@$labels);
  $self->throw("Invalid term ".$self->as_string.": nested label lists are not supported")
    if 'ARRAY' eq ref $labels && grep {'ARRAY' eq ref $_} @$labels;

  $labels=[] if $labels eq '*';	# empty labels list means '*' hereafter
  $self->labels('ARRAY' eq ref $labels? $labels: [$labels]);
  $self->termlist([grep {defined $_} $self->get(qw(column labels))]);
  $self;
}

# Does validation needed for both ConnectorSet and ConnectorTable inputs
# check labels and lookup label_ids
sub validate {
  my($self,$cs)=@_;
  my $labels=$self->labels;
  $self->cs($cs);
  my $label_ids=[];
  my $label2labelid=$cs->label2labelid;
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

