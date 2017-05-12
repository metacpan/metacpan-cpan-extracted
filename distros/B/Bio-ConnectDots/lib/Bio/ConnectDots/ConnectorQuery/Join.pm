package Bio::ConnectDots::ConnectorQuery::Join;
use strict;
use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS %DEFAULTS);
use Class::AutoClass;
use Bio::ConnectDots::Util;
use Bio::ConnectDots::Parser;
use Bio::ConnectDots::ConnectorQuery::Term;
@ISA = qw(Class::AutoClass);

@AUTO_ATTRIBUTES=qw(_term0 _term1);
%SYNONYMS=();
@OTHER_ATTRIBUTES=qw(term0 ct_alias0 cs_alias0 labels0 termlist0
		     term1 ct_alias1 cs_alias1 labels1 termlist1);
%DEFAULTS=();
Class::AutoClass::declare(__PACKAGE__);

sub _init_self {
  my($self,$class,$args)=@_;
  return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
  $self->term0 or $self->term0(new Bio::ConnectDots::ConnectorQuery::Term);
  $self->term1 or $self->term1(new Bio::ConnectDots::ConnectorQuery::Term);
}

# legal formats:
# 1) old form -- ARRAY of [ConnectorSet, label, ConnectorSet, label]
# 2) single query string which may include multiple joins AND'ed together
# 3) single Join object
# 4) ARRAY of (1) query strings and (2) Join objects

sub parse {
  my($class,$joins)=@_;
  my $parsed=[];
  my $parser=new Bio::ConnectDots::Parser;
  # ARRAY is old form if element 0 is ARRAY
  if ('ARRAY' eq ref $joins && @$joins && 'ARRAY' eq ref $joins->[0]) {
    for my $join (@$joins) {
      my($cs_alias0,$labels0,$cs_alias1,$labels1)=@$join;
      push(@$parsed,
	   $class->new(-cs_alias0=>$cs_alias0,-labels0=>$labels0,-cs_alias1=>$cs_alias1,-labels1=>$labels1));
    }
  } elsif (!ref $joins) {           # string
    push(@$parsed,$class->parse_string($joins,$parser));
  } elsif (UNIVERSAL::isa($joins,__PACKAGE__)) {
    push(@$parsed,$joins);
  } elsif ('ARRAY' eq ref $joins) { # new form ARRAY
    for my $join (@$joins) {
      if (!ref $join) { 
	push(@$parsed,$class->parse_string($join,$parser));
      } elsif (UNIVERSAL::isa($join,__PACKAGE__)) {
	push(@$parsed,$join);
      } else {
	$class->throw("llegal join format ".value_as_string($join).
		     ": must be string or Join object to appear in new ARRAY format");
      }
    }
  } else {
    $class->throw("Unrecognized join form ".value_as_string($joins).
		 ": strange type! Not scalar, Join object, ARRAY, or HASH");
  }
  wantarray? @$parsed: $parsed;
}
sub parse_string {
  my($class,$joins,$parser)=@_;
  $parser or $parser=new Bio::ConnectDots::Parser;
  my $parsed=[];
  my $parsed_joins=$parser->parse_joins($joins);
  if ($parsed_joins) {
    for my $join (@$parsed_joins) {
      my($term0,$term1)=@$join{qw(term0 term1)};
      push(@$parsed, 
	   $class->new(-termlist0=>$term0,-termlist1=>$term1));
    }
  }
  wantarray? @$parsed: $parsed;
}

sub normalize {
  my($self)=@_;
  my($term0,$term1)=$self->terms;
  $self->term0->normalize if $term0;
  $self->term1->normalize if $term1;
  $self;
}
sub validate {
  my($self,$name2ct_alias,$name2cs_alias)=@_;
  my($term0,$term1)=$self->terms;
  $term0->validate($name2ct_alias,$name2cs_alias);
  $term1->validate($name2ct_alias,$name2cs_alias);
  # make sure the labels meet at a common DotSet
  my($labels0,$labels1)=$self->labels;
  my($cs0,$cs1)=$self->css;
  my @dotsets0=@{$self->labels0}? # empty label set means '*'
    map {$cs0->label2dotset->{$_}} @$labels0: $term0->cs->dotsets;
  my @dotsets1=@{$self->labels1}? # empty label set means '*'
    map {$cs1->label2dotset->{$_}} @$labels1: $term1->cs->dotsets;
  my(%dotsets0,%dotsets1);
  @dotsets0{@dotsets0}=@dotsets0;
  @dotsets1{@dotsets1}=@dotsets1;
  
  if (@$labels0) {
    for my $label (@$labels0) {
      my $dotset=$cs0->label2dotset->{$label};
      $self->throw("Label $label in Term ".$term0->as_string.
		   " matches no label in Term ".$term1->as_string)
	unless $dotsets1{$dotset};
    }
  }
  if (@$labels1) {
    for my $label (@$labels1) {
      my $dotset=$cs1->label2dotset->{$label};
      $self->throw("Label $label in Term ".$term1->as_string.
		   " matches no label in Term ".$term0->as_string)
	unless $dotsets0{$dotset};
    }
  }
  $self;
}

sub terms {
  my $self=shift @_;
  if (@_) {
    my($term0,$term1)='ARRAY' eq ref $_[0]? @$_[0]: @_;
    $self->term0($term0);
    $self->term1($term1);
  } 
  my @terms=($self->term0,$self->term1);
  wantarray? @terms: \@terms;
}
sub reverse {
  my($self)=@_;
  $self->terms(reverse $self->terms);
  $self;
}
sub ct_aliases {
  my $self=shift @_;
  if (@_) {
    my($ct_alias0,$ct_alias1)='ARRAY' eq ref $_[0]? @$_[0]: @_;
    $self->ct_alias0($ct_alias0);
    $self->ct_alias1($ct_alias1);
  } 
  my @ct_aliases=($self->ct_alias0,$self->ct_alias1);
  wantarray? @ct_aliases: \@ct_aliases;
}
sub cs_aliases {
  my $self=shift @_;
  if (@_) {
    my($cs_alias0,$cs_alias1)='ARRAY' eq ref $_[0]? @$_[0]: @_;
    $self->cs_alias0($cs_alias0);
    $self->cs_alias1($cs_alias1);
  } 
  my @cs_aliases=($self->cs_alias0,$self->cs_alias1);
  wantarray? @cs_aliases: \@cs_aliases;
}
sub aliases {			# returns either ct or cs alias, whichever is set
  my($self)=@_;
  my @aliases=($self->alias0,$self->alias1);
  wantarray? @aliases: \@aliases;
}
sub cts {			# be careful -- not valid until validation time
  my($self)=@_;
  my @cts=($self->ct0,$self->ct1);
  wantarray? @cts: \@cts;
}
sub css {			# be careful -- not valid until validation time
  my($self)=@_;
  my @css=($self->cs0,$self->cs1);
  wantarray? @css: \@css;
}
sub cs_ids {			# be careful -- not valid until validation time
  my($self)=@_;
  my @cs_ids=($self->cs_id0,$self->cs_id1);
  wantarray? @cs_ids: \@cs_ids;
}
sub label_ids {			# be careful -- not valid until validation time
  my($self)=@_;
  my @label_ids=($self->label_ids0,$self->label_ids1);
  wantarray? @label_ids: \@label_ids;
}
sub labels {
  my $self=shift @_;
  if (@_) {
    my($labels0,$labels1)='ARRAY' eq ref $_[0]? @$_[0]: @_;
    $self->labels0($labels0);
    $self->labels1($labels1);
  } 
  my @labels=($self->labels0,$self->labels1);
  wantarray? @labels: \@labels;
}
sub termlists {
  my $self=shift @_;
  if (@_) {
    my($termlist0,$termlist1)='ARRAY' eq ref $_[0]? @$_[0]: @_;
    $self->termlist0($termlist0);
    $self->termlist1($termlist1);
  } 
  my @termlists=($self->termlist0,$self->termlist1);
  wantarray? @termlists: \@termlists;
}

sub term0 {
  my $self=shift @_;
  my $term=@_? $self->_term0($_[0]): $self->_term0;
  $term or $term=$self->_term0(new Bio::ConnectDots::ConnectorQuery::Term);
  $term;
}
sub ct_alias0 {
  my $self=shift @_;
  my $ct_alias=@_? $self->term0->ct_alias($_[0]): $self->term0->ct_alias;
  $ct_alias;
}
sub cs_alias0 {
  my $self=shift @_;
  my $cs_alias=@_? $self->term0->cs_alias($_[0]): $self->term0->cs_alias;
  $cs_alias;
}
sub alias0 {			# returns either ct or cs alias, whichever is set
  my($self)=@_;
  $self->term0->alias;
}
sub ct0 {			# be careful -- not valid until validation time
  my($self)=@_;
  $self->term0->ct;
}
sub cs0 {			# be careful -- not valid until validation time
  my($self)=@_;
  $self->term0->cs;
}
sub cs_id0 {			# be careful -- not valid until validation time
  my($self)=@_;
  $self->term0->cs_id;
}
sub label_ids0 {		# be careful -- not valid until validation time
  my($self)=@_;
  $self->term0->label_ids;
}
sub labels0 {
  my $self=shift @_;
  my $labels=@_? $self->term0->labels($_[0]): $self->term0->labels;
  $labels;
}
sub termlist0 {
  my $self=shift @_;
  my $termlist=@_? $self->term0->termlist($_[0]): $self->term0->termlist;
  $termlist;
}
sub term1 {
  my $self=shift @_;
  my $term=@_? $self->_term1($_[0]): $self->_term1;
  $term or $term=$self->_term1(new Bio::ConnectDots::ConnectorQuery::Term);
  $term;
}
sub ct_alias1 {
  my $self=shift @_;
  my $ct_alias=@_? $self->term1->ct_alias($_[0]): $self->term1->ct_alias;
  $ct_alias;
}
sub cs_alias1 {
  my $self=shift @_;
  my $cs_alias=@_? $self->term1->cs_alias($_[0]): $self->term1->cs_alias;
  $cs_alias;
}
sub alias1 {			# returns either ct or cs alias, whichever is set
  my($self)=@_;
  $self->term1->alias;
}
sub ct1 {			# be careful -- not valid until validation time
  my($self)=@_;
  $self->term1->ct;
}
sub cs1 {			# be careful -- not valid until validation time
  my($self)=@_;
  $self->term1->cs;
}
sub cs_id1 {			# be careful -- not valid until validation time
  my($self)=@_;
  $self->term1->cs_id;
}
sub label_ids1 {		# be careful -- not valid until validation time
  my($self)=@_;
  $self->term1->label_ids;
}
sub labels1 {
  my $self=shift @_;
  my $labels=@_? $self->term1->labels($_[0]): $self->term1->labels;
  $labels;
}
sub termlist1 {
  my $self=shift @_;
  my $termlist=@_? $self->term1->termlist($_[0]): $self->term1->termlist;
  $termlist;
}

sub as_string {
  my($self)=@_;
  my $term0=$self->term0->as_string;
  my $term1=$self->term1->as_string;
  return "$term0 = $term1";
}

1;

