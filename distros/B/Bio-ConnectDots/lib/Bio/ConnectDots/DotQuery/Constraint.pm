package Bio::ConnectDots::DotQuery::Constraint;
use strict;
use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS %DEFAULTS);
use Class::AutoClass;
use Bio::ConnectDots::Util;
use Bio::ConnectDots::Parser;
use Bio::ConnectDots::DotQuery::Term;
@ISA = qw(Class::AutoClass);

@AUTO_ATTRIBUTES=qw(_term _op constants);
%SYNONYMS=();
@OTHER_ATTRIBUTES=qw(term op ct_alias cs_alias labels label_ids termlist);
%DEFAULTS=(_op=>'=');
Class::AutoClass::declare(__PACKAGE__);

# legal formats:
# 1) Old ConnectorTable format: ARRAY or HASH of 
#   column =>[label], [label constant] or [label op constant]
#    NOTE: Old ConnectorSet format NOT supported, because it conflicts with 
#    new ARRAY of output strings
# 2) single query string which may include multiple constraints AND'ed together
# 3) single Constraint object
# 4) ARRAY of (1) query strings and (2) Constraint objects

sub parse {
  my($class,$constraints)=@_;
  my $parsed=[];
  my $parser=new Bio::ConnectDots::Parser;
  # ARRAY is old form if even number of elements, element 0 is scalar, element 1 is ARRAY
  if (('ARRAY' eq ref $constraints) && @$constraints && 
      @$constraints%2==0 && !ref $constraints->[0] && 'ARRAY' eq ref $constraints->[1]) {
    my $hash;
    while(@$constraints) {
      my($column,$constraint)=(shift @$constraints,shift @$constraints);
      my $constraint_list=$hash->{$column} || ($hash->{$column}=[]);
      push(@$constraint_list,$constraint);
    }
    $constraints=$hash;
  }
  # HASH is always old form. Old form ARRAY turned into HASH in 'if' above
  # Note 'if' -- not 'elsif'
  if ('HASH' eq ref $constraints) {
    while (my($column,$constraint_list)=each %$constraints) {
      $constraint_list=[$constraint_list] unless 'ARRAY' eq ref $constraint_list->[0];
      for my $constraint (@$constraint_list) {
	my($labels,$op,$constant);
	$class->throw("Illegal constraint format ".value_as_string($constraint).
		     ": must have 1-3 elements") 
	  unless @$constraint && @$constraint<=3;
	($labels)=@$constraint if @$constraint==1;
	($labels,$constant)=@$constraint if @$constraint==2;
	($labels,$op,$constant)=@$constraint if @$constraint==3;
	$constant=$parser->parse_constant_value($constant); # handle constant lists
	push(@$parsed,
	     $class->new(-termlist=>[$column,$labels],-op=>$op,-constant=>$constant));
      }
    }
  } elsif (!ref $constraints) {           # string
    push(@$parsed,$class->parse_string($constraints,$parser));
  } elsif (UNIVERSAL::isa($constraints,__PACKAGE__)) {
    push(@$parsed,$constraints);
  } elsif ('ARRAY' eq ref $constraints) { # new form ARRAY
    for my $constraint (@$constraints) {
      if (!ref $ $constraint) { 
	push(@$parsed,$class->parse_string($constraint,$parser));
      } elsif (UNIVERSAL::isa($constraint,__PACKAGE__)) {
	push(@$parsed,$constraint);
      } else {
	$class->throw("llegal constraint format ".value_as_string($constraint).
		     ": must be string or Constraint object to appear in new ARRAY format");
      }
    }
  } else {
    $class->throw("Unrecognized constraint form ".value_as_string($constraints).
		 ": strange type! Not scalar, Constraint object, ARRAY, or HASH");
  }
  wantarray? @$parsed: $parsed
}
sub parse_string {
  my($class,$constraints,$parser)=@_;
  my $parsed=[];
  my $parsed_constraints=$parser->parse_constraints($constraints);
  if ($parsed_constraints) {
    for my $constraint (@$parsed_constraints) {
      my($term,$op,$constant)=@$constraint{qw(term op constant)};
      push(@$parsed, 
	   $class->new(-termlist=>$term,-op=>$op,-constants=>$constant));
    }
  }
  wantarray? @$parsed: $parsed;
}

sub normalize {
  my($self)=@_;
  $self->term->normalize;
  my $op=$self->op;
  my $constants=$self->constants;
  $op or $op=$constants? '=': 'EXISTS';

  if ('ARRAY' eq ref $constants) {
    $self->throw("Invalid constraint".$self->as_string.": nested list constants are not supported")
      if grep {'ARRAY' eq ref $_} @$constants;
    $self->throw("Invalid  constraint".$self->as_string.": empty list constants are not supported")
      unless @$constants;
    # normalize ops with list constants
    if ($op eq '=') {
      $self->op('IN');
    } elsif ($op eq "!=")  {
      $self->op('NOT IN');
    } elsif ($op=~/</) {	 # range op: just compare to end of range
      my $max=maxb(@$constants); # does numeric or alpha max as appropriate
	$self->constants([$max]);
    } elsif ($op=~/>/) {	   # range op: just compare to end of range
      my $min=minb(@$constants); # does numeric or alpha min as appropriate
      $self->constants([$min]);
    }
  } elsif (!ref $constants) {		# change single value to list
    $self->throw("Invalid  constraint".$self->as_string.": no constant provided")
      unless $op eq 'EXISTS' || defined $constants;
    $constants=$self->constants([$constants]);
  } else {
    $self->throw("Invalid constraint".$self->as_string.": strange type!");
  }
  $self;
}

sub term {
  my $self=shift @_;
  my $term=@_? $self->_term($_[0]): $self->_term;
  $term or $term=$self->_term(new Bio::ConnectDots::DotQuery::Term);
  $term;
}
sub op {
  my $self=shift @_;
  my $op=@_? $self->_op($_[0]): $self->_op;
  $op or $op='=';
  $op;
}
sub cs {$_[0]->term->cs;}
sub cs_id {$_[0]->term->cs_id;}
sub cs_name {$_[0]->term->cs_name;}
sub column {
  my $self=shift @_;
  my $column=@_? $self->term->column($_[0]): $self->term->column;
  $column;
}
sub labels {
  my $self=shift @_;
  my $labels=@_? $self->term->labels($_[0]): $self->term->labels;
  $labels;
}
sub label_ids {
  my $self=shift @_;
  my $label_ids=@_? $self->term->label_ids($_[0]): $self->term->label_ids;
  $label_ids;
}
sub termlist {
  my $self=shift @_;
  my $termlist=@_? $self->term->termlist($_[0]): $self->term->termlist;
  $termlist;
}
sub as_string {
  my($self)=@_;
  my $term=$self->term->as_string;
  my $op=$self->op;
  my $constants=value_as_string($self->constants);
  return "$term $op $constants";
}

1;

